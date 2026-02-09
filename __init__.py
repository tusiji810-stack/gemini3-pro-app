# 1. 统一导入所有节点文件
from .py.prompt_nodes import HouLaiRandomPrompts
from .py.houlai_switch import HouLai_8_Way_Image_Switch
from .py.houlai_text_switch import HouLai_8_Way_Text_Switch
from .py.recolor_node import HouLai_Recolor_Batch_V3
from .py.houlai_data_gate import HouLai_Data_Gate
from .py.houlai_super_api import HouLaiSuperCloudGen
from .py.houlai_llm_agent import Universal_LLM_Config, Ecommerce_Skill_Router
from .py.nanobana_node import NanoBananaScheduler
# 新增：Gemini 3 Pro 节点 (假设文件名为 houlai_gemini.py)
from .py.houlai_gemini import HouLai_Gemini3_Pro_Generate

# 2. 统一注册节点类 (合并到一个字典中)
NODE_CLASS_MAPPINGS = {
    "HouLaiRandomPrompts": HouLaiRandomPrompts,
    "HouLai_8_Way_Image_Switch": HouLai_8_Way_Image_Switch,
    "HouLai_8_Way_Text_Switch": HouLai_8_Way_Text_Switch,
    "HouLai_Recolor_Batch_V3": HouLai_Recolor_Batch_V3,
    "HouLai_Data_Gate": HouLai_Data_Gate,
    "HouLaiSuperCloudGen": HouLaiSuperCloudGen,
    "Universal_LLM_Config": Universal_LLM_Config,
    "Ecommerce_Skill_Router": Ecommerce_Skill_Router,
    "NanoBananaScheduler": NanoBananaScheduler,
    "HouLai_Gemini3_Pro": HouLai_Gemini3_Pro_Generate, # 新增注册
}

# 3. 统一注册显示名称 (ComfyUI 菜单中看到的中文名)
NODE_DISPLAY_NAME_MAPPINGS = {
    "HouLaiRandomPrompts": "✨ 后来_随机提示词抽取 (Random Batch)",
    "HouLai_8_Way_Image_Switch": "🔀 后来_8路图片分流器 (Image Switch)",
    "HouLai_8_Way_Text_Switch": "🔀 后来_8路文本分流器 (Text Switch)",
    "HouLai_Recolor_Batch_V3": "🎨 后来_批量质感改色 V3 (Recolor)",
    "HouLai_Data_Gate": "🛑 后来_万能数据闸门 (Data Gate)",
    "HouLaiSuperCloudGen": "☁️ 后来_全能云端绘图 (Super Cloud Gen)",
    "Universal_LLM_Config": "🤖 后来_通用LLM配置 (LLM Config)",
    "Ecommerce_Skill_Router": "🛒 后来_电商技能路由 (Skill Router)",
    "NanoBananaScheduler": "🚀 后来_NanoBanana云端调度器 (NanoBanana)",
    "HouLai_Gemini3_Pro": "💎 后来_Gemini3 Pro生成 (Gemini Preview)", # 新增菜单名
}

# 4. 导出
__all__ = ["NODE_CLASS_MAPPINGS", "NODE_DISPLAY_NAME_MAPPINGS"]