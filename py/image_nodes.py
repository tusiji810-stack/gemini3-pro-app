# ComfyUI_HouLai_ToolBox/py/prompt_nodes.py

import random
import re

class HouLaiRandomPrompts:
    # import random
import re

class HouLaiRandomPrompts:
    def __init__(self):
        pass

    @classmethod
    def INPUT_TYPES(s):
        return {
            "required": {
                "text": ("STRING", {"multiline": True, "default": "", "placeholder": "在此粘贴您的提示词库..."}), 
                "extract_count": ("INT", {"default": 9, "min": 1, "max": 100, "step": 1, "display": "number"}), 
                "seed": ("INT", {"default": 0, "min": 0, "max": 0xffffffffffffffff}), 
                "filter_mode": (["No Change (不处理)", 
                                 "Trim & Remove Empty (去空行空格)", 
                                 "Remove Index (去序号 1. ->)",
                                 "Shuffle Only (仅打乱全量输出)"],), 
            },
        }

    RETURN_TYPES = ("STRING", "STRING",) 
    RETURN_NAMES = ("list_output", "combo_text_output",) 
    OUTPUT_IS_LIST = (True, False,) # 第一个输出是列表，触发Batch功能
    FUNCTION = "process_prompts"
    CATEGORY = "后来/Prompt"  # 在菜单中会显示为“后来”分类

    def process_prompts(self, text, extract_count, seed, filter_mode):
        # 1. 基础分割
        if not text:
             return ([""], "")
             
        lines = text.split('\n')
        
        # 2. 文本清洗逻辑
        cleaned_lines = []
        for line in lines:
            if filter_mode == "No Change (不处理)":
                cleaned_lines.append(line)
            else:
                # 去除首尾空格
                temp_line = line.strip()
                
                # 如果是去序号模式 (例如 "1. 姿势" -> "姿势")
                if "Remove Index" in filter_mode:
                    # 正则：匹配行首的数字加点或顿号
                    temp_line = re.sub(r'^\d+[\.\、\s]*', '', temp_line)
                
                # 只有非空行才加入
                if temp_line:
                    cleaned_lines.append(temp_line)

        # 3. 随机抽取逻辑
        if not cleaned_lines:
            return ([""], "") 

        random.seed(seed)
        
        # 如果是“仅打乱”模式
        if filter_mode == "Shuffle Only (仅打乱全量输出)":
            selected_lines = list(cleaned_lines)
            random.shuffle(selected_lines)
        else:
            # 正常抽取模式
            if len(cleaned_lines) < extract_count:
                # 数量不够，循环补齐
                selected_lines = []
                while len(selected_lines) < extract_count:
                    selected_lines.extend(cleaned_lines)
                selected_lines = selected_lines[:extract_count]
                random.shuffle(selected_lines)
            else:
                # 数量够，随机采样（不重复）
                selected_lines = random.sample(cleaned_lines, extract_count)

        # 4. 准备输出
        # list_output: 传递给模型的列表
        # combo_text_output: 把结果拼起来方便预览
        combo_text = "\n".join(selected_lines)

        return (selected_lines, combo_text)

# 节点注册映射
NODE_CLASS_MAPPINGS = {
    "HouLaiRandomPrompts": HouLaiRandomPrompts
}

# 这里的名字决定了您在界面上看到的节点名称
NODE_DISPLAY_NAME_MAPPINGS = {
    "HouLaiRandomPrompts": "后来_随机提示词抽取 (Random Batch)"
}
    
    CATEGORY = "后来/Prompt"  # 保持分类统一