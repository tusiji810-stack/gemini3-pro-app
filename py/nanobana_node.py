import requests
import time
import base64
import io
import json
import numpy as np
from PIL import Image
import torch

class NanoBananaScheduler:
    def __init__(self):
        pass

    @classmethod
    def INPUT_TYPES(s):
        return {
            "required": {
                "middleware_url": ("STRING", {"default": "http://127.0.0.1:8001"}),
                "api_key": ("STRING", {"default": "", "multiline": False}),
                "prompt": ("STRING", {"multiline": True, "default": "one cat\ntwo dogs", "dynamicPrompts": True}),
                
                # === 官方全套参数 ===
                "mode": (["text2img", "img2img"], {"default": "text2img"}),
                "model": (["nano-banana-2", "nano-banana-2-2k", "nano-banana-2-4k"], {"default": "nano-banana-2"}),
                "aspect_ratio": (["auto", "16:9", "4:3", "4:5", "3:2", "1:1", "2:3", "3:4", "5:4", "9:16", "21:9"], {"default": "auto"}),
                "image_size": (["1K", "2K", "4K"], {"default": "2K"}),
                "seed": ("INT", {"default": 0, "min": 0, "max": 2147483647}),
            },
            "optional": {
                # === 8 个图片接口 ===
                "image1": ("IMAGE",),
                "image2": ("IMAGE",),
                "image3": ("IMAGE",),
                "image4": ("IMAGE",),
                "image5": ("IMAGE",),
                "image6": ("IMAGE",),
                "image7": ("IMAGE",),
                "image8": ("IMAGE",),
            }
        }

    # === 无输出接口，发完即止 ===
    RETURN_TYPES = ()
    RETURN_NAMES = ()
    OUTPUT_NODE = True
    FUNCTION = "process"
    CATEGORY = "NanoBanana"

    def process(self, middleware_url, api_key, prompt, mode, model, aspect_ratio, image_size, seed, **kwargs):
        # 1. 收集图片 (image1 ~ image8)
        collected_images = []
        for i in range(1, 9):
            key = f"image{i}"
            if key in kwargs and kwargs[key] is not None:
                img_tensor = kwargs[key][0]
                i = 255. * img_tensor.cpu().numpy()
                img_pil = Image.fromarray(np.clip(i, 0, 255).astype(np.uint8))
                buffered = io.BytesIO()
                img_pil.save(buffered, format="PNG")
                img_str = base64.b64encode(buffered.getvalue()).decode("utf-8")
                collected_images.append(f"data:image/png;base64,{img_str}")

        # 2. 拆分 Prompt (实现批量)
        # 过滤空行，确保每一行都是一个独立的任务
        prompt_list = [p.strip() for p in prompt.split('\n') if p.strip()]
        if not prompt_list: prompt_list = [""]

        print(f"🚀 [NanoBanana] 准备发射 {len(prompt_list)} 个任务...")

        # 3. 构造批量 Manifest
        batch_id = f"NB_{int(time.time())}"
        manifest_items = []
        
        for idx, p_text in enumerate(prompt_list):
            manifest_items.append({
                "tid": f"{batch_id}_T{idx}",
                "prompt": p_text,
                "image_uris": collected_images, # 共享参考图
                "api_key": api_key,
                
                # 透传参数
                "mode": mode,
                "model": model,
                "aspect_ratio": aspect_ratio,
                "image_size": image_size,
                "seed": seed + idx if seed > 0 else 0, # 种子递增
                
                "slot": {"image_index": idx, "prompt_index": idx, "copy_index": 0}
            })

        payload = {
            "batch_id": batch_id,
            "frontend": {"order_id": batch_id, "callback_url": ""},
            "nanobana_config": {},
            "manifest": manifest_items
        }

        # 4. 发射指令 (Fire and Forget)
        ui_msg = ""
        try:
            url = f"{middleware_url.rstrip('/')}/api/v1/dispatch"
            
            # 这里是关键：中间件现在是秒回的，所以这里的 timeout 即使是 5秒都够用了
            res = requests.post(url, json=payload, timeout=30, proxies={"http": None, "https": None})
            
            if res.status_code == 200:
                print(f"✅ [NanoBanana] 发射成功！Batch ID: {batch_id}")
                ui_msg = f"✅ 已发送 {len(prompt_list)} 个任务到后台。\nBatch ID: {batch_id}\n请在 archive 文件夹查看结果。"
            else:
                print(f"❌ [NanoBanana] 发射失败: {res.status_code}")
                ui_msg = f"❌ 服务器报错: {res.text}"

        except Exception as e:
            print(f"❌ [NanoBanana] 连接错误: {e}")
            ui_msg = f"❌ 无法连接中间件: {e}"

        # 任务立即结束，ComfyUI 变绿
        return {"ui": {"text": ui_msg}}