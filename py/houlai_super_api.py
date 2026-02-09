import requests
import json
import time
import base64
import torch
import numpy as np
from PIL import Image
from io import BytesIO
import urllib3

# 禁用 SSL 警告 (因为我们要开启忽略证书模式)
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# === 核心辅助功能 ===

def tensor2base64(image):
    """将ComfyUI的图片转换为API需要的Base64格式"""
    if image is None:
        return None
    # 确保处理的是单张图片
    if len(image.shape) > 3:
        image = image[0]
    
    # 转换: Tensor(0-1) -> Numpy(0-255) -> PIL
    i = 255. * image.cpu().numpy()
    img = Image.fromarray(np.clip(i, 0, 255).astype(np.uint8))
    
    # 转字节流
    buffered = BytesIO()
    img.save(buffered, format="JPEG", quality=95)
    img_str = base64.b64encode(buffered.getvalue()).decode("utf-8")
    
    # 必须带上前缀
    return f"data:image/jpeg;base64,{img_str}"

def load_image_from_url(url):
    """下载图片并转为ComfyUI格式 (增强版)"""
    try:
        print(f"⬇️ 下载图片中: {url}")
        # 增加 headers 伪装
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        }
        # verify=False 忽略证书错误
        response = requests.get(url, headers=headers, timeout=60, verify=False)
        response.raise_for_status()
        img = Image.open(BytesIO(response.content))
        img = img.convert("RGB")
        img = np.array(img).astype(np.float32) / 255.0
        return torch.from_numpy(img)[None,]
    except Exception as e:
        print(f"❌ 图片下载失败: {e}")
        return None

def get_blank_image(width=512, height=512):
    """【安全气囊】生成一张全黑图片，防止ComfyUI崩溃"""
    return torch.zeros((1, height, width, 3), dtype=torch.float32)

# === 节点主类 ===

class HouLaiSuperCloudGen:
    """
    后来 - 全能云端绘图 (网络增强版)
    解决 SSLEOFError 和连接中断问题
    """
    
    def __init__(self):
        pass

    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                # 1. 基础配置
                "api_url": ("STRING", {"default": "https://api.apimart.ai/v1/images/generations"}),
                "api_token": ("STRING", {"default": "", "multiline": False, "placeholder": "Bearer Token (不带Bearer前缀)"}),
                "model": ("STRING", {"default": "gemini-3-pro-image-preview"}),
                
                # 2. 绘图参数
                "prompt": ("STRING", {"multiline": True, "default": "A bamboo forest path under moonlight", "rows": 5}),
                "aspect_ratio": (["1:1", "16:9", "9:16", "4:3", "3:4", "3:2", "2:3", "21:9", "2:3", "4:5", "5:4"], {"default": "1:1"}),
                "resolution": (["1K", "2K", "4K"], {"default": "1K"}),
                
                # 3. 运行控制
                "seed": ("INT", {"default": 0, "min": 0, "max": 0xffffffffffffffff}),
                "timeout_seconds": ("INT", {"default": 120, "min": 10, "max": 600, "step": 10, "label": "超时(秒)"}),
                "enable_blocking": ("BOOLEAN", {"default": True, "label_on": "开启:等待结果", "label_off": "关闭:仅提交(返回黑图)"}),
            },
            "optional": {
                "image_1": ("IMAGE",),
                "image_2": ("IMAGE",),
                "image_3": ("IMAGE",),
                "image_4": ("IMAGE",),
            }
        }

    RETURN_TYPES = ("IMAGE", "STRING", "STRING")
    RETURN_NAMES = ("image", "image_url", "raw_response")
    FUNCTION = "run_cloud_gen"
    CATEGORY = "后来/API工具"

    def run_cloud_gen(self, api_url, api_token, model, prompt, aspect_ratio, resolution, seed, 
                     timeout_seconds, enable_blocking, 
                     image_1=None, image_2=None, image_3=None, image_4=None):

        print(f"\n⚡ [后来API] 启动任务: {model}")
        blank_img = get_blank_image()

        # -------------------------------------------
        # 1. 准备请求头 (增强伪装)
        # -------------------------------------------
        headers = {
            "Authorization": f"Bearer {api_token.strip()}",
            "Content-Type": "application/json",
            # 伪装成 Chrome 浏览器
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            # 强制短连接，防止复用断掉的通道
            "Connection": "close"
        }

        image_urls_list = []
        for i, img in enumerate([image_1, image_2, image_3, image_4]):
            if img is not None:
                print(f"  - 处理参考图 {i+1}...")
                try:
                    b64 = tensor2base64(img)
                    if b64: image_urls_list.append(b64)
                except Exception as e:
                    print(f"  ❌ 参考图 {i+1} 转换失败: {e}")

        # -------------------------------------------
        # 2. 构建 Payload
        # -------------------------------------------
        payload = {
            "model": model,
            "prompt": prompt,
            "size": aspect_ratio,
            "n": 1,
            "resolution": resolution
        }
        
        if image_urls_list:
            payload["image_urls"] = image_urls_list
            print(f"  - 已打包 {len(image_urls_list)} 张参考图")

        # -------------------------------------------
        # 3. 提交任务 (增强网络稳定性)
        # -------------------------------------------
        task_id = None
        try:
            print(f"  - 正在提交到: {api_url}")
            # verify=False 关键！忽略代理证书错误
            response = requests.post(api_url, headers=headers, json=payload, timeout=30, verify=False)
            
            if response.status_code != 200:
                err_msg = f"API请求错误 [{response.status_code}]: {response.text}"
                print(f"❌ {err_msg}")
                return (blank_img, "", json.dumps({"error": err_msg}))
            
            resp_json = response.json()
            
            # 解析 Task ID
            if "data" in resp_json and isinstance(resp_json["data"], list) and len(resp_json["data"]) > 0:
                task_id = resp_json["data"][0].get("task_id")
            elif "data" in resp_json and isinstance(resp_json["data"], dict):
                task_id = resp_json["data"].get("task_id")
            
            if not task_id:
                print(f"❌ 未找到 Task ID，原始响应: {resp_json}")
                return (blank_img, "", json.dumps(resp_json))

            print(f"✅ 任务提交成功! ID: {task_id}")

            if not enable_blocking:
                msg = f"任务已提交(ID:{task_id})，未开启等待模式。"
                return (blank_img, msg, json.dumps(resp_json))

        except Exception as e:
            err_msg = f"提交异常: {str(e)}"
            print(f"❌ {err_msg}")
            return (blank_img, "", json.dumps({"error": err_msg}))

        # -------------------------------------------
        # 4. 轮询等待 (增强重试机制)
        # -------------------------------------------
        base_url = "https://api.apimart.ai/v1/tasks" 
        if "apimart.ai" not in api_url and "/images/generations" in api_url:
             base_url = api_url.replace("/images/generations", "/tasks")
        
        poll_url = f"{base_url}/{task_id}"
        
        print(f"⏳ 开始轮询结果: {poll_url}")
        start_time = time.time()
        
        # 连续失败计数器
        fail_count = 0
        
        while True:
            elapsed = time.time() - start_time
            if elapsed > timeout_seconds:
                print(f"❌ 等待超时 ({timeout_seconds}s)")
                return (blank_img, "", json.dumps({"status": "timeout"}))

            try:
                # verify=False 再次使用
                poll_res = requests.get(poll_url, headers=headers, timeout=10, verify=False)
                
                # 只要连接通了，重置失败计数
                fail_count = 0
                
                if poll_res.status_code == 200:
                    poll_data = poll_res.json()
                    
                    status = "unknown"
                    img_url = None
                    item = {}
                    
                    if "data" in poll_data:
                        if isinstance(poll_data["data"], list) and len(poll_data["data"]) > 0:
                            item = poll_data["data"][0]
                        elif isinstance(poll_data["data"], dict):
                            item = poll_data["data"]
                    
                    status = item.get("status", "unknown")
                    print(f"  ... 状态: {status} ({int(elapsed)}s)")
                    
                    if status in ["succeeded", "success", "completed"]:
                        img_url = item.get("url") or item.get("image_url")
                        if not img_url and "results" in item:
                            if isinstance(item["results"], list) and len(item["results"]) > 0:
                                img_url = item["results"][0].get("url")
                        
                        if img_url:
                            print(f"🎉 成功! 图片地址: {img_url}")
                            final_img = load_image_from_url(img_url)
                            if final_img is not None:
                                return (final_img, img_url, json.dumps(poll_data))
                            else:
                                return (blank_img, img_url, "Download Failed")
                    elif status in ["failed", "error"]:
                        return (blank_img, "", json.dumps(poll_data))
                
            except Exception as e:
                fail_count += 1
                print(f"⚠️ 网络波动 ({fail_count}): {str(e)[:100]}...") # 只打印前100个字符避免刷屏
                
                # 如果连续失败超过10次，可能网络真断了，但我们继续重试直到超时
                if fail_count > 20:
                    print("❌ 连续网络错误次数过多，请检查代理设置。")
                    return (blank_img, "", "Network Error")
            
            # 稍微延长轮询时间，给网络一点喘息
            time.sleep(3)