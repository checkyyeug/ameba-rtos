@echo off
REM ========================================
REM  LVGL Music Player Demo 构建脚本
REM ========================================

echo.
echo ========================================
echo   Building LVGL Music Player Demo
echo ========================================
echo.

REM 设置示例应用路径
set APP_PATH=example\peripheral\Display\lvgl_music

echo [步骤1] 配置项目
echo 应用程序: %APP_PATH%
echo.

REM 配置项目
python ameba.py menuconfig -f configs_lvgl.conf
if %ERRORLEVEL% NEQ 0 (
    echo 配置失败！
    pause
    exit /b 1
)

echo.
echo [步骤2] 编译项目
echo.

REM 编译项目（指定应用程序）
python ameba.py build -a %APP_PATH%
if %ERRORLEVEL% NEQ 0 (
    echo 编译失败！
    pause
    exit /b 1
)

echo.
echo [步骤3] 查看编译结果
echo.

REM 显示固件信息
dir build_RTL8730E\km0_km4_ca32_app.bin

echo.
echo ========================================
echo   构建完成！
echo ========================================
echo.
echo 接下来执行：
echo   python ameba.py flash -p COM10 -b 1500000 -m nand
echo   python ameba.py monitor -b 1500000
echo.
pause