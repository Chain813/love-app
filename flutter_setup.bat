@echo off
echo ========================================
echo 虫米 App - Flutter 环境配置脚本
echo ========================================
echo.

REM 检查 Flutter 是否已安装
where flutter >nul 2>nul
if %errorlevel% equ 0 (
    echo Flutter 已安装在系统 PATH 中
    flutter --version
    goto :run_pub_get
)

REM 检查 E:\flutter 是否存在
if exist "E:\flutter\bin\flutter.bat" (
    echo 找到 Flutter SDK: E:\flutter
    set PATH=E:\flutter\bin;%PATH%
    goto :run_pub_get
)

REM 检查 C:\flutter 是否存在
if exist "C:\flutter\bin\flutter.bat" (
    echo 找到 Flutter SDK: C:\flutter
    set PATH=C:\flutter\bin;%PATH%
    goto :run_pub_get
)

echo.
echo 错误：未找到 Flutter SDK
echo.
echo 请按以下步骤安装 Flutter：
echo 1. 下载 Flutter SDK: https://docs.flutter.dev/get-started/install/windows
echo 2. 解压到 E:\flutter 或 C:\flutter
echo 3. 将 Flutter 的 bin 目录添加到系统 PATH
echo 4. 重新运行此脚本
echo.
pause
exit /b 1

:run_pub_get
echo.
echo 正在安装依赖...
cd /d "%~dp0"
flutter pub get

if %errorlevel% neq 0 (
    echo.
    echo 依赖安装失败，请检查网络连接
    pause
    exit /b 1
)

echo.
echo ========================================
echo 依赖安装完成！
echo ========================================
echo.
echo 运行以下命令启动应用：
echo   flutter run
echo.
echo 或者运行测试：
echo   flutter test
echo.
pause
