"""
ComfyUI_Ecommerce_LLM_Agent - 核心节点实现

本文件包含两个核心节点:
1. Universal_LLM_Config: 通用LLM配置节点
2. Ecommerce_Skill_Router: 电商技能路由节点

功能说明:
- 支持多模态LLM (豆包/GPT-4o/DeepSeek等)
- 支持图片+文本输入
- YAML技能库动态加载
- 生成适配Flux/Qwen的提示词
"""

# ============================================
# 依赖检查与导入
# ============================================
import sys
import importlib.util

# 检查必要的依赖库是否已安装
def check_dependencies():
    """检查并报告依赖库的安装状态"""
    required_packages = {
        "openai": "openai>=1.0.0",
        "yaml": "PyYAML>=6.0",
        "PIL": "Pillow>=9.0.0",
        "requests": "requests>=2.28.0",
    }
    
    missing = []
    for module, package in required_packages.items():
        if importlib.util.find_spec(module) is None:
            missing.append(package)
    
    if missing:
        print("=" * 60)
        print("[ComfyUI_Ecommerce_LLM_Agent] 错误: 缺少必要的依赖库!")
        print("请运行以下命令安装:")
        print(f"  pip install {' '.join(missing)}")
        print("或:")
        print("  pip install -r requirements.txt")
        print("=" * 60)
        return False
    return True

# 执行依赖检查
DEPS_OK = check_dependencies()

# 标准库导入
import os
import io
import base64
import traceback
from typing import List, Dict, Any, Optional, Tuple
from pathlib import Path

# 第三方库导入 (在依赖检查通过后)
if DEPS_OK:
    import yaml
    from PIL import Image as PILImage
    from openai import OpenAI
    import torch
    import numpy as np

# ============================================
# 全局常量定义
# ============================================
# 插件根目录路径（py目录的父目录，即项目根目录）
PLUGIN_ROOT = Path(__file__).parent.parent.absolute()

# 技能文件夹路径
SKILLS_DIR = PLUGIN_ROOT / "skills"

# 图片处理常量
MAX_IMAGES = 4  # 最多处理4张图片
MAX_IMAGE_SIZE = 2048  # 图片最大尺寸

# 默认LLM配置
DEFAULT_BASE_URL = "https://ark.cn-beijing.volces.com/api/v3"
DEFAULT_MODEL = "ep-xxx...-xxx"
DEFAULT_SYSTEM_PROMPT = "你是一个专业的电商视觉内容生成助手。"

# ============================================
# 工具函数
# ============================================

# 全局缓存技能列表
_SKILLS_CACHE = None
_CUSTOM_SKILLS_DIR = None

def scan_skills_directory(force_refresh: bool = False, custom_path: str = "") -> List[str]:
    """
    扫描技能目录下的所有YAML文件，返回技能选项列表
    
    Args:
        force_refresh: 是否强制刷新缓存
        custom_path: 自定义技能文件夹路径
    
    Returns:
        List[str]: 格式为 "文件名 - Key名" 的技能选项列表
    """
    global _SKILLS_CACHE, _CUSTOM_SKILLS_DIR
    
    # 确定使用的技能目录
    if custom_path and custom_path.strip():
        skills_dir = Path(custom_path.strip())
        _CUSTOM_SKILLS_DIR = skills_dir
    elif _CUSTOM_SKILLS_DIR:
        skills_dir = _CUSTOM_SKILLS_DIR
    else:
        skills_dir = SKILLS_DIR
    
    # 使用缓存（除非强制刷新）
    if not force_refresh and _SKILLS_CACHE is not None:
        return _SKILLS_CACHE
    
    skills = []
    
    # 确保技能目录存在
    if not skills_dir.exists():
        print(f"[Ecommerce_Skill_Router] 警告: 技能目录不存在: {skills_dir}")
        return ["未找到技能文件"]
    
    # 遍历所有yaml文件
    for yaml_file in sorted(skills_dir.glob("*.yaml")):
        try:
            with open(yaml_file, 'r', encoding='utf-8') as f:
                data = yaml.safe_load(f)
                
            if data and isinstance(data, dict):
                for key in data.keys():
                    # 格式: "文件名(不含扩展名) - Key名"
                    display_name = f"{yaml_file.stem} - {key}"
                    skills.append(display_name)
        except Exception as e:
            print(f"[Ecommerce_Skill_Router] 解析文件失败 {yaml_file}: {e}")
            continue
    
    if not skills:
        _SKILLS_CACHE = ["未找到有效技能"]
    else:
        _SKILLS_CACHE = skills
    
    return _SKILLS_CACHE


def search_skill_by_keyword(keyword: str) -> Optional[str]:
    """
    根据关键词搜索匹配的技能
    
    Args:
        keyword: 搜索关键词
    
    Returns:
        Optional[str]: 匹配的技能名称，未找到返回None
    """
    if not keyword or not keyword.strip():
        return None
    
    keyword = keyword.strip().lower()
    skills = scan_skills_directory()
    
    # 精确匹配
    for skill in skills:
        if keyword in skill.lower():
            print(f"[Skill Search] 找到匹配: {skill}")
            return skill
    
    return None


def load_skill_template(skill_selection: str, custom_path: str = "") -> Optional[str]:
    """
    根据选择加载对应的技能模板
    
    Args:
        skill_selection: 格式为 "文件名 - Key名"
        custom_path: 自定义技能文件夹路径
    
    Returns:
        Optional[str]: 模板字符串，失败返回None
    """
    global _CUSTOM_SKILLS_DIR
    
    try:
        # 确定使用的技能目录
        if custom_path and custom_path.strip():
            skills_dir = Path(custom_path.strip())
        elif _CUSTOM_SKILLS_DIR:
            skills_dir = _CUSTOM_SKILLS_DIR
        else:
            skills_dir = SKILLS_DIR
        
        # 解析选择字符串
        parts = skill_selection.split(" - ", 1)
        if len(parts) != 2:
            return None
        
        filename, key = parts
        yaml_path = skills_dir / f"{filename}.yaml"
        
        if not yaml_path.exists():
            return None
        
        with open(yaml_path, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
        
        if key in data and "template" in data[key]:
            return data[key]["template"]
        
        return None
    except Exception as e:
        print(f"[Ecommerce_Skill_Router] 加载模板失败: {e}")
        return None


def tensor_to_pil(image_tensor: torch.Tensor) -> PILImage.Image:
    """
    将ComfyUI的Tensor图像转换为PIL Image
    
    Args:
        image_tensor: ComfyUI图像张量 [B, H, W, C] 或 [H, W, C]
    
    Returns:
        PILImage.Image: PIL图像对象
    """
    # 处理batch维度
    if len(image_tensor.shape) == 4:
        # [B, H, W, C] -> 取第一张
        image_tensor = image_tensor[0]
    
    # [H, W, C] -> 转换为numpy
    if isinstance(image_tensor, torch.Tensor):
        image_np = image_tensor.cpu().numpy()
    else:
        image_np = np.array(image_tensor)
    
    # 确保值范围在0-255
    if image_np.max() <= 1.0:
        image_np = (image_np * 255).astype(np.uint8)
    else:
        image_np = image_np.astype(np.uint8)
    
    # 创建PIL图像
    pil_image = PILImage.fromarray(image_np)
    
    # 限制最大尺寸
    if max(pil_image.size) > MAX_IMAGE_SIZE:
        pil_image.thumbnail((MAX_IMAGE_SIZE, MAX_IMAGE_SIZE), PILImage.Resampling.LANCZOS)
    
    return pil_image


def pil_to_base64(pil_image: PILImage.Image, format: str = "PNG") -> str:
    """
    将PIL Image转换为Base64编码的字符串
    
    Args:
        pil_image: PIL图像对象
        format: 图像格式 (PNG/JPEG)
    
    Returns:
        str: Base64编码的图像数据
    """
    buffered = io.BytesIO()
    
    # 如果是RGBA格式且目标格式是JPEG，需要转换
    if format == "JPEG" and pil_image.mode in ("RGBA", "P"):
        pil_image = pil_image.convert("RGB")
    
    pil_image.save(buffered, format=format)
    img_str = base64.b64encode(buffered.getvalue()).decode('utf-8')
    return img_str


def create_vision_message(pil_images: List[PILImage.Image], text_prompt: str) -> List[Dict[str, Any]]:
    """
    创建符合OpenAI Vision格式的消息
    
    Args:
        pil_images: PIL图像列表
        text_prompt: 文本提示词
    
    Returns:
        List[Dict]: OpenAI格式的消息列表
    """
    content = []
    
    # 添加图片内容
    for pil_img in pil_images:
        base64_image = pil_to_base64(pil_img, "PNG")
        content.append({
            "type": "image_url",
            "image_url": {
                "url": f"data:image/png;base64,{base64_image}"
            }
        })
    
    # 添加文本内容
    content.append({
        "type": "text",
        "text": text_prompt
    })
    
    return [{"role": "user", "content": content}]


# ============================================
# 节点A: 通用LLM配置节点
# ============================================
class Universal_LLM_Config:
    """
    通用LLM配置节点
    
    功能: 生成通用的LLM客户端配置，不绑定特定厂商
    支持: 豆包、GPT-4o、DeepSeek、OpenAI等兼容OpenAI SDK的服务
    """
    
    # ========================================
    # 节点元数据
    # ========================================
    CATEGORY = "Ecommerce_LLM_Agent"
    FUNCTION = "create_config"
    RETURN_TYPES = ("LLM_CONFIG",)  # 自定义输出类型
    RETURN_NAMES = ("llm_config",)
    OUTPUT_NODE = False
    
    # ========================================
    # 输入定义
    # ========================================
    @classmethod
    def INPUT_TYPES(cls) -> Dict[str, Any]:
        return {
            "required": {
                # API基础URL
                "base_url": ("STRING", {
                    "default": DEFAULT_BASE_URL,
                    "placeholder": "https://api.openai.com/v1 或豆包地址",
                    "tooltip": "LLM API的基础URL，支持豆包、OpenAI、DeepSeek等"
                }),
                # API密钥 (隐藏显示)
                "api_key": ("STRING", {
                    "default": "",
                    "password": True,  # ComfyUI中mask显示
                    "tooltip": "您的API密钥，将被安全处理"
                }),
                # 模型名称
                "model_name": ("STRING", {
                    "default": DEFAULT_MODEL,
                    "tooltip": "模型ID，如gpt-4o、ep-xxx等"
                }),
                # 系统提示词
                "system_prompt": ("STRING", {
                    "default": DEFAULT_SYSTEM_PROMPT,
                    "multiline": True,
                    "lines": 4,
                    "tooltip": "系统级提示词，定义AI助手的角色和行为"
                }),
            }
        }
    
    # ========================================
    # 核心处理函数
    # ========================================
    def create_config(self, base_url: str, api_key: str, 
                      model_name: str, system_prompt: str) -> Tuple[Dict[str, Any]]:
        """
        创建LLM配置对象
        
        Args:
            base_url: API基础URL
            api_key: API密钥
            model_name: 模型名称
            system_prompt: 系统提示词
        
        Returns:
            Tuple[Dict]: 包含配置字典的元组
        """
        config = {
            "base_url": base_url,
            "api_key": api_key,
            "model_name": model_name,
            "system_prompt": system_prompt,
        }
        
        print(f"[Universal_LLM_Config] 配置已创建: {model_name} @ {base_url}")
        return (config,)


# ============================================
# 节点B: 电商技能路由节点 (已优化批量输出逻辑)
# ============================================
class Ecommerce_Skill_Router:
    CATEGORY = "Ecommerce_LLM_Agent"
    FUNCTION = "process"
    
    # 修改1：定义返回类型为字符串，并匹配你截图中的名称
    RETURN_TYPES = ("STRING", "STRING")
    RETURN_NAMES = ("batch_prompts", "formatted_summary")
    
    # 修改2：关键！告知 ComfyUI 第一个输出是列表(List)，用于触发下游批量任务
    OUTPUT_IS_LIST = (True, False) 
    
    OUTPUT_NODE = False

    @classmethod
    def INPUT_TYPES(cls) -> Dict[str, Any]:
        skill_options = scan_skills_directory()
        return {
            "required": {
                "使用技能": ("BOOLEAN", {"default": True, "tooltip": "开启后使用技能模板，关闭后使用自定义模板"}),
                "技能选择": (skill_options, {"tooltip": "选择预设的电商技能模板"}),
                "LLM配置": ("LLM_CONFIG", {"tooltip": "连接Universal_LLM_Config节点的输出"}),
                "输出模式": (["分批输出", "合并输出"], {"default": "分批输出"}),
                "生图数量": ("INT", {"default": 4, "min": 1, "max": 20, "tooltip": "需要生成的图片数量"}),
            },
            "optional": {
                "自定义技能目录": ("STRING", {"default": "", "placeholder": "留空使用默认目录"}),
                "关键词搜索": ("STRING", {"default": "", "placeholder": "输入关键词自动匹配技能"}),
                "刷新技能列表": ("BOOLEAN", {"default": False, "tooltip": "勾选后重新扫描skills目录"}),
                "图片1": ("IMAGE", {}),
                "图片2": ("IMAGE", {}),
                "图片3": ("IMAGE", {}),
                "图片4": ("IMAGE", {}),
                "产品名称": ("STRING", {"default": "", "placeholder": "产品名称（可选）"}),
                "目标人群": ("STRING", {"default": "", "placeholder": "目标人群（可选）"}),
                "产品参数": ("STRING", {"default": "", "multiline": True, "placeholder": "产品参数（可选）"}),
                "卖点": ("STRING", {"default": "", "multiline": True, "placeholder": "卖点（可选）"}),
                "平台": ("STRING", {"default": "", "placeholder": "平台（可选）"}),
                "语言": ("STRING", {"default": "", "placeholder": "语言（可选，如：中文/English）"}),
                "自定义模板": ("STRING", {"default": "", "multiline": True, "placeholder": "自定义模板（可选）"}),
            }
        }

    def process(self, 使用技能: bool, 技能选择: str, LLM配置: Dict[str, Any],
                输出模式: str, 生图数量: int,
                自定义技能目录: str = "",
                关键词搜索: str = "",
                刷新技能列表: bool = False,
                图片1: Optional[torch.Tensor] = None,
                图片2: Optional[torch.Tensor] = None,
                图片3: Optional[torch.Tensor] = None,
                图片4: Optional[torch.Tensor] = None,
                产品名称: str = "", 目标人群: str = "",
                产品参数: str = "", 卖点: str = "",
                平台: str = "", 语言: str = "",
                自定义模板: str = "") -> Tuple[List[str], str]:
        
        if not DEPS_OK:
            return (["依赖缺失"], "请安装必要的Python库")

        try:
            # 处理刷新请求
            if 刷新技能列表:
                scan_skills_directory(force_refresh=True, custom_path=自定义技能目录)
                print("[Ecommerce_Skill_Router] 技能列表已刷新")
            
            # 处理关键词搜索
            final_skill = 技能选择
            if 关键词搜索 and 关键词搜索.strip():
                matched = search_skill_by_keyword(关键词搜索)
                if matched:
                    final_skill = matched
                    print(f"[Ecommerce_Skill_Router] 使用关键词匹配的技能: {final_skill}")
                else:
                    print(f"[Ecommerce_Skill_Router] 未找到匹配'{关键词搜索}'的技能，使用默认选择")
            
            # 1. 构建产品信息上下文
            context_parts = []
            if 产品名称:
                context_parts.append(f"产品名称: {产品名称}")
            if 目标人群:
                context_parts.append(f"目标人群: {目标人群}")
            if 产品参数:
                context_parts.append(f"产品参数: {产品参数}")
            if 卖点:
                context_parts.append(f"卖点: {卖点}")
            if 平台:
                context_parts.append(f"平台: {平台}")
            if 语言:
                context_parts.append(f"语言: {语言}")
            
            product_context = "\n".join(context_parts) if context_parts else "请根据图片内容进行分析"
            
            # 2. 加载模板逻辑：根据"使用技能"开关决定
            if 使用技能:
                template = load_skill_template(final_skill, 自定义技能目录)
                if not template:
                    return (["技能模板加载失败"], "请检查技能选择或使用自定义模板")
            else:
                if not 自定义模板 or not 自定义模板.strip():
                    return (["请提供自定义模板内容"], "关闭技能后必须填写自定义模板")
                template = 自定义模板.strip()
            
            # 3. 构建最终提示词，明确告知LLM生成指定数量的提示词
            final_prompt = template.format(
                platform=平台 or "电商平台",
                selling_points=product_context,
                batch_count=生图数量
            )
            final_prompt += f"\n\n请严格生成{生图数量}行独立的提示词，每行一个完整的prompt。"

            # 2. 处理图片逻辑 (支持4个独立输入)
            pil_images = []
            for img_tensor in [图片1, 图片2, 图片3, 图片4]:
                if img_tensor is not None:
                    pil_images.append(tensor_to_pil(img_tensor))

            # 3. 调用 LLM
            response_text = self._call_llm(LLM配置, final_prompt, pil_images)
            
            if response_text is None:
                return (["API调用失败"], "请检查网络或API Key")

            # 4. 修改输出逻辑：将文本按行切分为列表
            # 过滤掉空行，确保每一行都是一个独立的 Prompt
            lines = [line.strip() for line in response_text.split('\n') if line.strip()]
            
            # 完整的原始文本作为总结输出
            formatted_summary = response_text.strip()

            print(f"[Ecommerce_Skill_Router] 成功生成 {len(lines)} 条独立提示词")
            
            # 修改3：返回 (列表, 字符串)
            return (lines, formatted_summary)

        except Exception as e:
            traceback.print_exc()
            return ([f"错误: {str(e)}"], str(e))

    # _call_llm 函数保持不变...
    # ========================================
    # LLM API调用函数
    # ========================================
    def _call_llm(self, llm_config: Dict[str, Any], 
                  prompt: str, 
                  images: List[PILImage.Image]) -> Optional[str]:
        """
        调用LLM API获取响应
        
        Args:
            llm_config: LLM配置
            prompt: 文本提示词
            images: PIL图像列表
        
        Returns:
            Optional[str]: LLM响应文本，失败返回None
        """
        try:
            # 创建OpenAI客户端
            client = OpenAI(
                base_url=llm_config["base_url"],
                api_key=llm_config["api_key"],
            )
            
            # 构建消息
            messages = []
            
            # 添加系统提示词
            if llm_config.get("system_prompt"):
                messages.append({
                    "role": "system",
                    "content": llm_config["system_prompt"]
                })
            
            # 添加用户消息 (文本+图片)
            if images:
                # 多模态消息
                content = []
                
                # 添加图片
                for pil_img in images:
                    base64_img = pil_to_base64(pil_img, "PNG")
                    content.append({
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/png;base64,{base64_img}",
                            "detail": "high"
                        }
                    })
                
                # 添加文本
                content.append({
                    "type": "text",
                    "text": prompt
                })
                
                messages.append({
                    "role": "user",
                    "content": content
                })
            else:
                # 纯文本消息
                messages.append({
                    "role": "user",
                    "content": prompt
                })
            
            print(f"[Ecommerce_Skill_Router] 调用模型: {llm_config['model_name']}")
            
            # 发送请求
            response = client.chat.completions.create(
                model=llm_config["model_name"],
                messages=messages,
                temperature=0.7,
                max_tokens=2048,
            )
            
            # 提取响应文本
            result = response.choices[0].message.content
            
            print(f"[Ecommerce_Skill_Router] API调用成功，响应长度: {len(result)} 字符")
            return result
            
        except Exception as e:
            print("=" * 60)
            print("[Ecommerce_Skill_Router] LLM API调用失败:")
            traceback.print_exc()
            print("=" * 60)
            return None


# ============================================
# 节点映射 (供ComfyUI加载使用)
# ============================================
NODE_CLASS_MAPPINGS = {
    "Universal_LLM_Config": Universal_LLM_Config,
    "Ecommerce_Skill_Router": Ecommerce_Skill_Router,
}

NODE_DISPLAY_NAME_MAPPINGS = {
    "Universal_LLM_Config": "🤖 通用LLM配置",
    "Ecommerce_Skill_Router": "🛒 电商技能路由",
}
