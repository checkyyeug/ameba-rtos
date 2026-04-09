<#
.SYNOPSIS
    自动生成 LVGL CMakeLists.txt 的源文件列表

.DESCRIPTION
    扫描 LVGL 源码目录，生成符合 LVGL 9.5 目录结构的 CMakeLists.txt
#>

$LVGL_DIR = "C:\RTL\ameba-rtos\component\ui\lvgl"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  LVGL CMakeLists.txt 生成工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 收集所有源文件
function Get-SourceFiles {
    param($Path, $Prefix)
    
    $files = @()
    if (Test-Path $Path) {
        $cFiles = Get-ChildItem -Path $Path -Filter "*.c" -File | ForEach-Object { "$Prefix/$_" }
        $files += $cFiles
    }
    return $files
}

Write-Host "[步骤1] 扫描 LVGL 源文件..." -ForegroundColor Yellow

$allSources = @()

# Core
$allSources += Get-SourceFiles -Path "$LVGL_DIR\src\core" -Prefix "src/core"
Write-Host "  Core: $(($allSources | Where-Object { $_ -match 'src/core' }).Count) files" -ForegroundColor Gray

# Display
$allSources += Get-SourceFiles -Path "$LVGL_DIR\src\display" -Prefix "src/display"
Write-Host "  Display: $(($allSources | Where-Object { $_ -match 'src/display' }).Count) files" -ForegroundColor Gray

# Indev
$allSources += Get-SourceFiles -Path "$LVGL_DIR\src\indev" -Prefix "src/indev"
Write-Host "  Indev: $(($allSources | Where-Object { $_ -match 'src/indev' }).Count) files" -ForegroundColor Gray

# Draw
$allSources += Get-SourceFiles -Path "$LVGL_DIR\src\draw" -Prefix "src/draw"
Write-Host "  Draw: $(($allSources | Where-Object { $_ -match 'src/draw' }).Count) files" -ForegroundColor Gray

# Font
$allSources += Get-SourceFiles -Path "$LVGL_DIR\src\font" -Prefix "src/font"
Write-Host "  Font: $(($allSources | Where-Object { $_ -match 'src/font' }).Count) files" -ForegroundColor Gray

# Misc
$allSources += Get-SourceFiles -Path "$LVGL_DIR\src\misc" -Prefix "src/misc"
Write-Host "  Misc: $(($allSources | Where-Object { $_ -match 'src/misc' }).Count) files" -ForegroundColor Gray

# Stdlib
$allSources += Get-SourceFiles -Path "$LVGL_DIR\src\stdlib" -Prefix "src/stdlib"
$allSources += Get-SourceFiles -Path "$LVGL_DIR\src\stdlib\builtin" -Prefix "src/stdlib/builtin"
Write-Host "  Stdlib: $(($allSources | Where-Object { $_ -match 'src/stdlib' }).Count) files" -ForegroundColor Gray

# Themes
$allSources += Get-SourceFiles -Path "$LVGL_DIR\src\themes\default" -Prefix "src/themes/default"
Write-Host "  Themes: $(($allSources | Where-Object { $_ -match 'src/themes' }).Count) files" -ForegroundColor Gray

# OSAL
$allSources += Get-SourceFiles -Path "$LVGL_DIR\src\osal" -Prefix "src/osal"
Write-Host "  OSAL: $(($allSources | Where-Object { $_ -match 'src/osal' }).Count) files" -ForegroundColor Gray

# Tick
$allSources += Get-SourceFiles -Path "$LVGL_DIR\src\tick" -Prefix "src/tick"
Write-Host "  Tick: $(($allSources | Where-Object { $_ -match 'src/tick' }).Count) files" -ForegroundColor Gray

# Widgets
$widgetDirs = Get-ChildItem -Path "$LVGL_DIR\src\widgets" -Directory | Select-Object -ExpandProperty Name
foreach ($dir in $widgetDirs) {
    $allSources += Get-SourceFiles -Path "$LVGL_DIR\src\widgets\$dir" -Prefix "src/widgets/$dir"
}
Write-Host "  Widgets: $(($allSources | Where-Object { $_ -match 'src/widgets' }).Count) files" -ForegroundColor Gray

# Drivers
$allSources += Get-SourceFiles -Path "$LVGL_DIR\src\drivers" -Prefix "src/drivers"
Write-Host "  Drivers: $(($allSources | Where-Object { $_ -match 'src/drivers' }).Count) files" -ForegroundColor Gray

# Port - Display Driver
$allSources += "port/lv_port_disp.c"
Write-Host "  Port: 1 file" -ForegroundColor Gray

# Demos
$allSources += "demos/lv_demos.c"
# Music Demo
$allSources += "demos/music/lv_demo_music.c"
$allSources += "demos/music/lv_demo_music_main.c"
$allSources += "demos/music/lv_demo_music_list.c"

# Music Demo Assets
$musicAssets = Get-ChildItem -Path "$LVGL_DIR\demos\music\assets" -Filter "*.c" -File | ForEach-Object { "demos/music/assets/$($_.Name)" }
$allSources += $musicAssets

Write-Host "  Demos: $(($allSources | Where-Object { $_ -match 'demos' }).Count) files" -ForegroundColor Gray

Write-Host ""
Write-Host "[步骤2] 生成源文件列表..." -ForegroundColor Yellow

$sourceList = $allSources -join "`n    "

Write-Host "总共 $($allSources.Count) 个源文件" -ForegroundColor Green
Write-Host ""

# 保存到文件
$outputFile = "lvgl_sources.txt"
$allSources | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "[完成] 源文件列表已保存到: $outputFile" -ForegroundColor Green
Write-Host ""

# 显示前10个文件
Write-Host "前10个源文件:" -ForegroundColor Cyan
$allSources | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor White }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "使用以下命令查看完整列表:" -ForegroundColor Yellow
Write-Host "  Get-Content $outputFile" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan