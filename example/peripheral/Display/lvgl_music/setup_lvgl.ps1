# LVGL Music Player 快速集成脚本
# 用于将LVGL 9.5 Music Demo自动集成到Ameba RTOS项目

param(
    [string]$LVGLSource = "C:\lvgl\lvgl-9.5",
    [string]$AmebaProject = "C:\RTL\ameba-rtos",
    [switch]$SkipCopy = $false,
    [switch]$Help = $false
)

if ($Help) {
    Write-Host @"
LVGL Music Player 快速集成脚本

用法: .\setup_lvgl.ps1 [选项]

选项:
    -LVGLSource <路径>    LVGL源码路径 (默认: C:\lvgl\lvgl-9.5)
    -AmebaProject <路径>  Ameba RTOS项目路径 (默认: C:\RTL\ameba-rtos)
    -SkipCopy             跳过文件复制（仅创建配置）
    -Help                 显示此帮助信息

示例:
    .\setup_lvgl.ps1
    .\setup_lvgl.ps1 -LVGLSource "D:\lvgl-9.5"
"@
    exit 0
}

Write-Host @"
================================================
   LVGL 9.5 Music Player 集成脚本
   目标: Ameba RTOS + ST7701S显示屏
================================================
"@ -ForegroundColor Cyan

$ErrorActionPreference = "Stop"

# 检查LVGL源码路径
if (-not (Test-Path $LVGLSource)) {
    Write-Error "错误: LVGL源码路径不存在: $LVGLSource"
    Write-Host "请下载LVGL 9.5或使用 -LVGLSource 参数指定正确路径"
    exit 1
}

Write-Host "[1/6] 验证LVGL源码..." -ForegroundColor Green
$LVGLFiles = @(
    "$LVGLSource\lvgl.h",
    "$LVGLSource\src",
    "$LVGLSource\demos\music\lv_demo_music.c"
)

$MissingFiles = @()
foreach ($file in $LVGLFiles) {
    if (-not (Test-Path $file)) {
        $MissingFiles += $file
    }
}

if ($MissingFiles.Count -gt 0) {
    Write-Error "LVGL源码不完整，缺少文件:`n$($MissingFiles -join "`n")"
    exit 1
}
Write-Host "  ✓ LVGL源码验证通过" -ForegroundColor Green

# 创建目录结构
Write-Host "`n[2/6] 创建目录结构..." -ForegroundColor Green
$Dirs = @(
    "$AmebaProject\component\ui\lvgl\src",
    "$AmebaProject\component\ui\lvgl\port",
    "$AmebaProject\component\ui\lvgl\demos\music\assets\png"
)

foreach ($dir in $Dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}
Write-Host "  ✓ 目录结构创建完成" -ForegroundColor Green

if (-not $SkipCopy) {
    # 复制LVGL核心文件
    Write-Host "`n[3/6] 复制LVGL核心文件..." -ForegroundColor Green
    
    # 复制核心头文件
    Copy-Item "$LVGLSource\lvgl.h" "$AmebaProject\component\ui\lvgl\" -Force
    Copy-Item "$LVGLSource\lv_conf_template.h" "$AmebaProject\component\ui\lvgl\" -Force -ErrorAction SilentlyContinue
    
    # 复制源码目录
    Copy-Item "$LVGLSource\src\*" "$AmebaProject\component\ui\lvgl\src\" -Recurse -Force
    
    # 复制demo程序
    Copy-Item "$LVGLSource\demos\lv_demos.h" "$AmebaProject\component\ui\lvgl\demos\" -Force -ErrorAction SilentlyContinue
    Copy-Item "$LVGLSource\demos\lv_demos.c" "$AmebaProject\component\ui\lvgl\demos\" -Force -ErrorAction SilentlyContinue
    
    # 复制music demo
    Copy-Item "$LVGLSource\demos\music\*.c" "$AmebaProject\component\ui\lvgl\demos\music\" -Force
    Copy-Item "$LVGLSource\demos\music\*.h" "$AmebaProject\component\ui\lvgl\demos\music\" -Force
    Copy-Item "$LVGLSource\demos\music\assets\*.c" "$AmebaProject\component\ui\lvgl\demos\music\assets\" -Recurse -Force
    
    Write-Host "  ✓ LVGL核心文件复制完成" -ForegroundColor Green
    
    # 统计复制文件数量
    $CopiedFiles = (Get-ChildItem -Path "$AmebaProject\component\ui\lvgl" -Recurse -File).Count
    Write-Host "  已复制 $CopiedFiles 个文件" -ForegroundColor Gray
}

# 验证配置文件
Write-Host "`n[4/6] 验证配置文件..." -ForegroundColor Green
$ConfigFiles = @(
    "$AmebaProject\component\ui\lvgl\lv_conf.h",
    "$AmebaProject\component\ui\lvgl\port\lv_port_disp.h",
    "$AmebaProject\component\ui\lvgl\port\lv_port_disp.c",
    "$AmebaProject\component\ui\lvgl\CMakeLists.txt"
)

$MissingConfigs = @()
foreach ($file in $ConfigFiles) {
    if (-not (Test-Path $file)) {
        $MissingConfigs += $file
    }
}

if ($MissingConfigs.Count -gt 0) {
    Write-Warning "缺少配置文件: $($MissingConfigs -join ', ')"
    Write-Host "请手动创建或在之前步骤中已创建"
} else {
    Write-Host "  ✓ 配置文件验证通过" -ForegroundColor Green
}

# 验证示例程序
Write-Host "`n[5/6] 验证示例程序..." -ForegroundColor Green
$ExampleFiles = @(
    "$AmebaProject\example\peripheral\Display\lvgl_music\main.c",
    "$AmebaProject\example\peripheral\Display\lvgl_music\CMakeLists.txt",
    "$AmebaProject\example\peripheral\Display\lvgl_music\README.md"
)

$MissingExamples = @()
foreach ($file in $ExampleFiles) {
    if (-not (Test-Path $file)) {
        $MissingExamples += $file
    }
}

if ($MissingExamples.Count -gt 0) {
    Write-Warning "缺少示例文件: $($MissingExamples -join ', ')"
} else {
    Write-Host "  ✓ 示例程序验证通过" -ForegroundColor Green
}

# 下一步指引
Write-Host "`n[6/6] 后续步骤..." -ForegroundColor Green
Write-Host @"
接下来需要手动完成的步骤:

1. 编辑项目主CMakeLists.txt
   在适当位置添加:
   add_subdirectory(component/ui/lvgl)

2. 配置项目构建目标
   python ameba.py soc RTL8730E

3. 编译项目
   python ameba.py build

4. 烧录并运行
   python ameba.py flash -p COM3 -b 1500000

"@ -ForegroundColor Yellow

Write-Host @"
================================================
   集成完成! 
================================================
配置文件位置:
  - LVGL配置: $AmebaProject\component\ui\lvgl\lv_conf.h
  - 显示驱动: $AmebaProject\component\ui\lvgl\port\
  - 示例程序: $AmebaProject\example\peripheral\Display\lvgl_music\
  - 集成文档: $AmebaProject\example\peripheral\Display\lvgl_music\README.md

如需帮助，请参考README.md文档
"@ -ForegroundColor Cyan

exit 0