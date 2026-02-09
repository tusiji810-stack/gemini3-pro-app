@echo off
chcp 65001
cls
echo ============================================
echo    Gemini 3 Pro - GitHub 上传助手
echo ============================================
echo.

if not exist .git (
    echo [1/4] 正在初始化 Git 仓库...
    git init
    if errorlevel 1 (
        echo [错误] Git 未安装，请先安装 Git
        pause
        exit /b 1
    )
) else (
    echo [1/4] Git 仓库已初始化
)

echo.
echo [2/4] 添加文件到暂存区...
git add .

echo.
echo [3/4] 提交更改...
git commit -m "Initial commit - Gemini 3 Pro App"

echo.
echo ============================================
echo    下一步操作
echo ============================================
echo.
echo 1. 在浏览器中打开 GitHub 创建新仓库：
echo    https://github.com/new
echo.
echo 2. 仓库名称填写：gemini3-pro-app
echo.
echo 3. 复制仓库地址后，运行以下命令：
echo.
echo    git remote add origin https://github.com/你的用户名/gemini3-pro-app.git
echo    git push -u origin main
echo.
echo ============================================
echo.
pause
