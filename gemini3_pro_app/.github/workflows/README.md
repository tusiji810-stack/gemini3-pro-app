# GitHub Actions 云编译说明

## 自动构建流程

本项目已配置 GitHub Actions，每次推送代码到 `main` 或 `master` 分支时，会自动：

1. ✅ 安装 Java 17
2. ✅ 安装 Flutter 3.16.0
3. ✅ 获取依赖 (`flutter pub get`)
4. ✅ 代码分析 (`flutter analyze`)
5. ✅ 运行测试 (`flutter test`)
6. ✅ 构建 APK (`flutter build apk --release`)
7. ✅ 构建 AAB (`flutter build appbundle --release`)
8. ✅ 上传到 Artifacts
9. ✅ 自动创建 Release

## 使用方法

### 方式1：推送到 GitHub 自动触发

```bash
# 1. 在 GitHub 创建新仓库 (例如: gemini3-pro-app)

# 2. 初始化本地仓库
cd gemini3_pro_app
git init
git add .
git commit -m "Initial commit"

# 3. 关联远程仓库
git remote add origin https://github.com/你的用户名/gemini3-pro-app.git

# 4. 推送代码
git push -u origin main
```

推送后，前往 GitHub 仓库的 `Actions` 标签页查看构建进度。

### 方式2：手动触发构建

1. 打开 GitHub 仓库页面
2. 点击 `Actions` 标签
3. 选择 `Build Android APK` 工作流
4. 点击 `Run workflow` 按钮

## 下载APK

构建完成后，可以通过以下方式获取APK：

### 方式1：Artifacts 下载
- 进入 `Actions` → 选择最新构建 → `Artifacts` 部分
- 下载 `release-apk` 文件

### 方式2：Release 页面
- 进入仓库的 `Releases` 页面
- 下载最新版本的 `app-release.apk`

## 构建配置

工作流配置文件：`.github/workflows/build.yml`

可修改的参数：
- `FLUTTER_VERSION`: Flutter 版本号
- `java-version`: Java 版本

## 常见问题

### Q: 构建失败怎么办？
A: 点击失败的构建，查看 `Build APK` 步骤的日志，根据错误信息修复代码。

### Q: 如何跳过测试？
A: 注释掉 `.github/workflows/build.yml` 中的 `- name: Run tests` 步骤。

### Q: 只想构建APK不构建AAB？
A: 删除 `Build AppBundle` 和 `Upload AppBundle` 步骤。

## 构建时间

- 首次构建：约 5-8 分钟（需要下载Flutter SDK）
- 后续构建：约 3-5 分钟（使用缓存）
