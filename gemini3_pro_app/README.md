# Gemini 3 Pro 图像生成器 - 安卓APP

基于 Flutter 开发的 Gemini 3 Pro 图像生成器安卓应用，专为小米14等现代安卓设备优化。

## ✨ 功能特性

### 核心功能
- 🎨 **AI图像生成** - 使用 Gemini 3 Pro API 生成高质量图像
- 🖼️ **参考图片** - 支持最多4张参考图片，支持相册选择和拍照
- 📝 **提示词输入** - 多行文本输入，支持清空操作
- ⚙️ **参数配置** - 完整的生成参数控制

### 高级特性
- 📐 **宽高比自定义** - 支持预设比例或自定义宽高输入
- 🎯 **参数可空值** - 宽高比、图像尺寸等参数支持留空（使用自动设置）
- 🎲 **随机种子** - 支持固定种子或随机生成
- 💾 **自动保存** - 生成结果自动保存到本地
- 📋 **日志系统** - 实时显示操作日志

### 小米14适配
- ✅ 120Hz 高刷新率支持
- ✅ 刘海屏/挖孔屏适配
- ✅ 高分辨率屏幕优化 (1200x2670)
- ✅ 骁龙8 Gen3 性能优化

## 🏗️ 项目结构

```
gemini3_pro_app/
├── lib/
│   ├── core/                    # 核心层
│   │   ├── constants/           # 常量定义
│   │   ├── theme/              # 主题配置
│   │   └── utils/              # 工具类
│   ├── data/                    # 数据层
│   │   ├── models/             # 数据模型
│   │   │   ├── generation_request.dart
│   │   │   └── settings_model.dart
│   │   ├── repositories/       # 数据仓库
│   │   │   └── settings_repository.dart
│   │   └── services/           # API服务
│   │       └── gemini_api_service.dart
│   ├── presentation/            # 表现层
│   │   ├── bloc/               # BLoC状态管理
│   │   │   ├── generation_bloc.dart
│   │   │   └── settings_bloc.dart
│   │   ├── pages/              # 页面
│   │   │   ├── home_page.dart
│   │   │   └── settings_page.dart
│   │   └── widgets/            # 组件
│   │       ├── prompt_input_widget.dart
│   │       ├── reference_images_widget.dart
│   │       ├── params_config_widget.dart
│   │       ├── api_config_widget.dart
│   │       ├── generation_button_widget.dart
│   │       ├── logs_widget.dart
│   │       └── results_widget.dart
│   ├── app.dart                 # 应用配置
│   └── main.dart               # 入口文件
├── android/                     # 安卓配置
│   └── app/
│       ├── build.gradle        # 构建配置
│       └── src/main/
│           ├── AndroidManifest.xml
│           └── kotlin/.../MainActivity.kt
└── pubspec.yaml                # 依赖配置
```

## 🚀 快速开始

### 环境要求
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android SDK >= 21
- Kotlin >= 1.9.0

### 安装步骤

1. **克隆项目**
```bash
cd gemini3_pro_app
```

2. **安装依赖**
```bash
flutter pub get
```

3. **配置API**
   - 打开应用
   - 进入设置页面
   - 配置API地址和API Key

4. **运行应用**
```bash
# 调试模式
flutter run

# 发布模式
flutter run --release
```

### 构建APK

```bash
# 构建发布版APK
flutter build apk --release

# 构建应用Bundle (用于Google Play)
flutter build appbundle --release

# 构建指定ABI的APK
flutter build apk --release --target-platform=android-arm64
```

构建后的APK位于：`build/app/outputs/flutter-apk/app-release.apk`

## 📱 使用指南

### 基本流程

1. **输入提示词**
   - 在提示词输入框中描述你想要的图像
   - 例如："一只可爱的橘猫坐在窗台上，阳光照射"

2. **添加参考图片** (可选)
   - 点击"+"按钮从相册选择或拍照
   - 最多支持4张参考图片
   - 点击缩略图上的X可移除

3. **配置参数** (可选)
   - **宽高比**: 选择预设比例或勾选"自定义宽高"输入具体数值
   - **图像尺寸**: 选择1K/2K/4K/8K或留空自动
   - **随机种子**: 输入固定值或使用随机按钮

4. **生成图像**
   - 点击底部"开始生成"按钮
   - 等待生成完成

5. **查看结果**
   - 点击生成的图片查看大图
   - 点击下载按钮保存单张图片
   - 点击"保存全部"保存所有图片

### 参数说明

| 参数 | 说明 | 可选值 |
|------|------|--------|
| 宽高比 | 图像宽高比例 | 自动/1:1/16:9/9:16/4:3/自定义 |
| 宽度 | 自定义宽度(像素) | 任意数字，留空为自动 |
| 高度 | 自定义高度(像素) | 任意数字，留空为自动 |
| 图像尺寸 | 图像质量等级 | 自动/1K/2K/4K/8K |
| 随机种子 | 生成随机性控制 | 0为随机，或固定数值 |

## ⚙️ API配置

### 默认API地址
```
https://aigc002.com/v1beta/models/gemini-3-pro-image-preview:generateContent
```

### 配置说明
1. 点击右上角设置图标
2. 展开"API配置"卡片
3. 输入API Key
4. 点击"保存配置"

## 🔧 技术架构

### 状态管理
使用 **BLoC (Business Logic Component)** 模式：
- `GenerationBloc`: 处理图像生成流程
- `SettingsBloc`: 处理应用设置

### 网络层
- **Dio**: HTTP客户端，支持超时、拦截器、进度监控

### 本地存储
- **SharedPreferences**: 轻量级配置存储
- **PathProvider**: 文件路径管理

### 图片处理
- **image_picker**: 相册/相机选择
- **photo_view**: 图片预览和缩放
- **image**: 图片解码和处理

## 🎨 UI设计

### 设计原则
- **Material Design 3**: 现代Material设计风格
- **小米14适配**: 针对高刷新率和高分辨率屏幕优化
- **深色模式**: 支持浅色/深色主题切换

### 主要页面

#### 主页面
```
┌─────────────────────────────────────┐
│  Gemini 3 Pro              [⚙️]     │  ← 标题栏
├─────────────────────────────────────┤
│  💬 提示词                          │  ← 输入区域
│  [在此输入图像描述...]              │
├─────────────────────────────────────┤
│  📷 参考图片 (0/4)                  │  ← 图片选择器
│  [图1] [图2] [图3] [图4] [+]       │
├─────────────────────────────────────┤
│  ⚙️ 生成参数 ▼                     │  ← 可折叠卡片
│  宽高比: [1:1 ▼] [自定义宽高 ☑]   │
│  宽: [___] 高: [___]               │
│  尺寸: [自动 ▼]  Seed: [0] [🎲]   │
├─────────────────────────────────────┤
│  🔑 API配置 ▼                      │  ← 可折叠卡片
├─────────────────────────────────────┤
│  📋 日志                            │  ← 日志区域
│  [信息] 开始生成...                │
├─────────────────────────────────────┤
│  [        🎨 开始生成        ]      │  ← 底部按钮
└─────────────────────────────────────┘
```

## 🐛 常见问题

### Q: 应用无法连接到API
A: 请检查：
1. 设备网络连接是否正常
2. API地址是否正确
3. API Key是否有效

### Q: 图片生成失败
A: 可能原因：
- API Key无效或过期
- 提示词包含敏感内容
- 服务器繁忙，请稍后重试

### Q: 参考图片无法添加
A: 请检查：
1. 是否授予了存储权限
2. 图片格式是否支持 (JPG/PNG)
3. 图片大小是否过大

### Q: 生成图片无法保存
A: 请检查：
1. 是否授予了存储权限
2. 设备存储空间是否充足

## 📄 开源协议

本项目采用 MIT 协议开源。

## 🙏 致谢

- [Flutter](https://flutter.dev) - UI框架
- [Gemini API](https://ai.google.dev) - AI图像生成
- [Bloc](https://bloclibrary.dev) - 状态管理

---

**专为小米14优化 | Flutter跨平台开发**
