import requests
import json
import base64
import torch
import numpy as np
from PIL import Image
from io import BytesIO
import comfy.utils
import os

# 尝试导入辅助函数，如果合并到工具箱中可能需要调整引用路径
try:
    from .utils import tensor2pil, pil2tensor, get_config, save_config
except ImportError:
    # 如果作为独立文件运行，提供基础实现
    def tensor2pil(image):
        return [Image.fromarray(np.clip(255. * image.cpu().numpy().squeeze(), 0, 255).astype(np.uint8))]

    def pil2tensor(image):
        return torch.from_numpy(np.array(image).astype(np.float32) / 255.0).unsqueeze(0)

    def get_config():
        return {}

    def save_config(config):
        pass

class HouLai_Gemini3_Pro_Generate:
    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                "prompt": ("STRING", {"multiline": True, "default": "Describe the image you want to generate"}),
                "aspect_ratio": (["9:16", "16:9", "1:1", "4:3", "3:4"], {"default": "9:16"}),
                "image_size": (["1K"], {"default": "1K"}), # API文档主要提及1K [cite: 3]
            },
            "optional": {
                "image_input": ("IMAGE",), # 开放式图片输入端口，对应API中的 inline_data [cite: 2]
                "apikey": ("STRING", {"default": "", "multiline": False}),
                "seed": ("INT", {"default": 0, "min": 0, "max": 2147483647})
            }
        }

    RETURN_TYPES = ("IMAGE", "STRING")
    RETURN_NAMES = ("image", "response_log")
    FUNCTION = "generate_content"
    CATEGORY = "HouLai_ToolBox/Google" # 适配您的工具箱分类

    def __init__(self):
        self.timeout = 600

    def get_headers(self, api_key):
        return {
            "Content-Type": "application/json",
            # 部分中转站可能需要 Authorization 头，保留以防万一 [cite: 3]
            "Authorization": f"Bearer {api_key}" 
        }

    def image_to_base64(self, image_tensor):
        """Convert tensor to base64 string for inline_data"""
        if image_tensor is None:
            return None
        pil_image = tensor2pil(image_tensor)[0]
        buffered = BytesIO()
        pil_image.save(buffered, format="JPEG") # API文档示例使用 image/jpeg [cite: 2]
        return base64.b64encode(buffered.getvalue()).decode('utf-8')

    def generate_content(self, prompt, aspect_ratio="9:16", image_size="1K", image_input=None, apikey="", seed=0):
        # 1. API Key 处理逻辑 (沿用同步插件风格) [cite: 12]
        current_api_key = apikey
        if current_api_key.strip():
            config = get_config()
            config['api_key'] = current_api_key
            save_config(config)
        else:
            current_api_key = get_config().get('api_key', '')
        
        if not current_api_key:
            return (torch.zeros((1, 1024, 1024, 3)), "Error: API Key is missing.")

        # 2. 构建 Payload 
        # URL 结构参考文档: key={{YOUR_API_KEY}} [cite: 1]
        url = f"https://aigc002.com/v1beta/models/gemini-3-pro-image-preview:generateContent?key={current_api_key}"
        
        # 构建 parts 部分
        parts = [{"text": prompt}]
        
        # 处理图片输入 (开放式端口逻辑)
        if image_input is not None:
            base64_img = self.image_to_base64(image_input)
            if base64_img:
                parts.append({
                    "inline_data": {
                        "mime_type": "image/jpeg",
                        "data": base64_img
                    }
                })

        payload_dict = {
            "contents": [
                {
                    "role": "user",
                    "parts": parts
                }
            ],
            "generationConfig": {
                "responseModalities": ["TEXT", "IMAGE"], # [cite: 3]
                "imageConfig": {
                    "aspectRatio": aspect_ratio,
                    "imageSize": image_size
                }
            }
        }

        # 3. 发送请求
        try:
            pbar = comfy.utils.ProgressBar(100)
            pbar.update_absolute(30)
            
            headers = self.get_headers(current_api_key)
            response = requests.post(url, headers=headers, json=payload_dict, timeout=self.timeout)
            
            pbar.update_absolute(70)

            if response.status_code != 200:
                error_msg = f"API Error {response.status_code}: {response.text}"
                print(error_msg)
                return (torch.zeros((1, 1024, 1024, 3)), error_msg)

            result = response.json()
            
            # 4. 解析响应
            # Gemini 通常在 candidates -> content -> parts 中返回图像
            # 这里的解析逻辑针对标准 Gemini 格式进行了适配
            generated_tensors = []
            log_info = f"Status: {response.status_code}\n"
            
            if "candidates" in result:
                for candidate in result["candidates"]:
                    if "content" in candidate and "parts" in candidate["content"]:
                        for part in candidate["content"]["parts"]:
                            # 处理 Base64 图像
                            if "inline_data" in part or "inlineData" in part:
                                img_data_entry = part.get("inline_data") or part.get("inlineData")
                                img_bytes = base64.b64decode(img_data_entry["data"])
                                img = Image.open(BytesIO(img_bytes))
                                generated_tensors.append(pil2tensor(img))
                                log_info += "Image decoded from Base64.\n"
                            # 处理文本响应
                            if "text" in part:
                                log_info += f"Text Response: {part['text']}\n"
            
            # 备用解析：如果 API 返回结构不同（参考文档中只print了text，未展示具体返回结构，这里做兼容处理）
            if not generated_tensors and "data" in result:
                 # 尝试处理类似 Nano Banana 的返回结构 [cite: 32]
                 pass 

            pbar.update_absolute(100)

            if generated_tensors:
                final_image = torch.cat(generated_tensors, dim=0)
                return (final_image, log_info)
            else:
                return (torch.zeros((1, 1024, 1024, 3)), f"No image found in response. Raw: {str(result)}")

        except Exception as e:
            error_msg = f"Exception: {str(e)}"
            print(error_msg)
            import traceback
            traceback.print_exc()
            return (torch.zeros((1, 1024, 1024, 3)), error_msg)

# 节点映射
NODE_CLASS_MAPPINGS = {
    "HouLai_Gemini3_Pro": HouLai_Gemini3_Pro_Generate
}

NODE_DISPLAY_NAME_MAPPINGS = {
    "HouLai_Gemini3_Pro": "HouLai Gemini 3 Pro (Preview)"
}