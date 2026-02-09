@echo off
chcp 65001 >nul
cls
color 0A

:: ============================================
echo.
echo    ============================================
echo       Gemini 3 Pro - 一键云编译部署工具
echo    ============================================
echo.
echo    本工具将帮助您：
echo    1. 检查环境
echo    2. 初始化Git仓库  
echo    3. 推送代码到GitHub
echo    4. 触发自动构建
echo.
echo    ============================================
echo.
pause
cls

:: ============================================
:: 步骤1：检查Git
:: ============================================
echo [步骤 1/5] 检查Git环境...
git --version >nul 2>&1
if errorlevel 1 (
    color 0C
    echo [错误] Git未安装！
    echo.
    echo 请下载安装Git：
    echo https://git-scm.com/download/win
    echo.
    echo 安装时选择：Use Git from the Windows Command Prompt
    echo.
    pause
    exit /b 1
)
echo [✓] Git已安装
git --version
echo.

:: ============================================
:: 步骤2：配置Git用户信息（如果没有）
:: ============================================
echo [步骤 2/5] 检查Git配置...
git config user.name >nul 2>&1
if errorlevel 1 (
    echo.
    echo [提示] 首次使用Git，需要配置用户信息
    set /p GIT_NAME="请输入您的姓名（用于Git提交）: "
    set /p GIT_EMAIL="请输入您的邮箱: "
    git config user.name "%GIT_NAME%"
    git config user.email "%GIT_EMAIL%"
    echo [✓] Git配置完成
) else (
    echo [✓] Git配置已存在
)
echo.

:: ============================================
:: 步骤3：初始化Git仓库
:: ============================================
echo [步骤 3/5] 初始化Git仓库...
if not exist .git (
    git init
    echo [✓] Git仓库初始化完成
) else (
    echo [✓] Git仓库已存在
)
echo.

:: ============================================
:: 步骤4：添加文件并提交
:: ============================================
echo [步骤 4/5] 准备提交代码...
echo 正在添加文件...
git add .
echo [✓] 文件已添加到暂存区
echo.

echo 正在提交...
git commit -m "Initial commit: Gemini 3 Pro App for Android

Features:
- AI image generation using Gemini 3 Pro API
- Support for 4 reference images
- Customizable aspect ratio and dimensions
- Optional parameters (nullable)
- Optimized for Xiaomi 14 (120Hz, high-res)
- Material 3 design with dark mode support"
if errorlevel 1 (
    echo [注意] 没有新的更改需要提交，或已提交过
) else (
    echo [✓] 代码已提交
)
echo.

:: ============================================
:: 步骤5：推送到GitHub
:: ============================================
echo [步骤 5/5] 推送到GitHub...
echo.
echo ============================================
echo  重要提示
echo ============================================
echo.
echo 在继续之前，请确保您已经完成以下操作：
echo.
echo 1. 在GitHub创建了仓库，名称为：gemini3-pro-app
echo    地址：https://github.com/new
echo.
echo 2. 获取您的GitHub用户名
echo.
set /p GITHUB_USER="请输入您的GitHub用户名: "
echo.

echo 正在设置远程仓库...
git remote remove origin 2>nul
git remote add origin https://github.com/%GITHUB_USER%/gemini3-pro-app.git

:: 检查是否已经推送过
git branch -r >nul 2>&1
if %errorlevel% == 0 (
    echo [✓] 远程仓库已配置
    echo.
    echo 正在推送代码...
    git push origin main
    if errorlevel 1 (
        git push origin master
    )
) else (
    echo.
    echo 首次推送，选择分支名称：
    echo 1. main (推荐)
    echo 2. master
    set /p BRANCH_CHOICE="请选择 (1或2): "
    
    if "%BRANCH_CHOICE%"=="2" (
        git branch -M master
        git push -u origin master
    ) else (
        git branch -M main
        git push -u origin main
    )
)

if errorlevel 1 (
    color 0C
    echo.
    echo [错误] 推送失败！
    echo.
    echo 可能的原因：
    echo 1. 仓库不存在 - 请先创建 https://github.com/new
    echo 2. 网络问题 - 请检查网络连接
    echo 3. 需要身份验证 - 请按提示输入用户名和密码/Token
    echo.
    echo 如果您启用了两步验证，需要使用Personal Access Token代替密码
    echo 创建Token：https://github.com/settings/tokens
    echo.
    pause
    exit /b 1
)

echo.
color 0A
echo ============================================
echo    [✓] 推送成功！
echo ============================================
echo.
echo 下一步：
echo.
echo 1. 打开GitHub仓库页面：
echo    https://github.com/%GITHUB_USER%/gemini3-pro-app
echo.
echo 2. 点击 "Actions" 标签页查看构建进度
echo.
echo 3. 等待约5-8分钟，构建完成后：
echo    - 点击最新的工作流运行记录
echo    - 页面底部 "Artifacts" 下载 release-apk
echo    - 或在 "Releases" 页面下载
echo.
echo ============================================
echo.

:: 打开浏览器
echo 是否打开GitHub仓库页面？
set /p OPEN_BROWSER="打开浏览器？(Y/N): "
if /I "%OPEN_BROWSER%"=="Y" (
    start https://github.com/%GITHUB_USER%/gemini3-pro-app
)

echo.
pause
