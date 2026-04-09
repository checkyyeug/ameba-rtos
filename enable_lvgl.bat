@echo off
REM ========================================
REM 启用 LVGL Music Player Demo
REM ========================================

echo.
echo ========================================
echo   LVGL Music Player Demo 配置脚本
echo ========================================
echo.

REM 方法1: 手动编辑配置文件
echo [方法1] 手动编辑配置文件
echo.
echo 编辑文件: build_RTL8730E\menuconfig\.config
echo 找到: # CONFIG_LVGL is not set
echo 改为: CONFIG_LVGL=y
echo.
echo 添加以下配置:
echo   CONFIG_LVGL_V9_5=y
echo   CONFIG_LVGL_COLOR_DEPTH=16
echo   CONFIG_LVGL_MEMORY_SIZE=131072
echo   CONFIG_LVGL_USE_OS=2
echo   CONFIG_LVGL_DISPLAY_DRIVER="ST7701S"
echo   CONFIG_LVGL_DISPLAY_WIDTH=480
echo   CONFIG_LVGL_DISPLAY_HEIGHT=800
echo   CONFIG_LVGL_DOUBLE_BUFFER=y
echo   CONFIG_LVGL_DEMO_MUSIC=y
echo   CONFIG_LVGL_DEMO_MUSIC_AUTO_PLAY=y
echo.

pause

REM 方法2: 使用 menuconfig
echo.
echo [方法2] 使用 menuconfig（推荐）
echo.
echo 步骤:
echo   1. 运行: python ameba.py menuconfig
echo   2. 导航到: CONFIG APPLICATION
echo   3. 选择: LVGL Graphics Library
echo   4. 按 Y 启用: [*] Enable LVGL Graphics Library
echo   5. 按 Enter 进入子菜单配置参数
echo   6. 按 S 保存，按 Q 退出
echo.

pause

REM 方法3: 直接编译（简便方法）
echo.
echo [方法3] 直接修改配置后编译
echo.
pause

REM 创建配置脚本
echo 正在修改配置文件...

powershell -Command "$configFile = 'build_RTL8730E\menuconfig\.config'; $content = Get-Content $configFile; $updated = $content -replace '# CONFIG_LVGL is not set', 'CONFIG_LVGL=y'; $updated += @'
CONFIG_LVGL_V9_5=y
CONFIG_LVGL_COLOR_DEPTH=16
CONFIG_LVGL_MEMORY_SIZE=131072
CONFIG_LVGL_USE_OS=2
CONFIG_LVGL_DISPLAY_DRIVER=\"ST7701S\"
CONFIG_LVGL_DISPLAY_WIDTH=480
CONFIG_LVGL_DISPLAY_HEIGHT=800
CONFIG_LVGL_DOUBLE_BUFFER=y
CONFIG_LVGL_DEMO_MUSIC=y
CONFIG_LVGL_DEMO_MUSIC_AUTO_PLAY=y
CONFIG_LVGL_USE_LOG=y
'@; $updated | Set-Content $configFile; Write-Host '配置文件已更新！' -ForegroundColor Green"

echo.
echo 配置完成！现在可以运行：
echo   python ameba.py build
echo.

pause