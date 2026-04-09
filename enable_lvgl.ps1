# 使用 PowerShell 快速启用 LVGL Music Player Demo

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  LVGL Music Player Demo 启用脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 配置文件路径
$configFile = "build_RTL8730E\menuconfig\.config"

# 检查文件是否存在
if (-not (Test-Path $configFile)) {
    Write-Host "[错误] 配置文件不存在: $configFile" -ForegroundColor Red
    Write-Host "请先运行构建: python ameba.py build" -ForegroundColor Yellow
    exit 1
}

Write-Host "[步骤1] 备份配置文件..." -ForegroundColor Yellow
$backupFile = "$configFile.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item $configFile $backupFile
Write-Host "已备份到: $backupFile" -ForegroundColor Green

Write-Host ""
Write-Host "[步骤2] 修改配置..." -ForegroundColor Yellow

# 读取配置
$content = Get-Content $configFile

# 替换 LVGL 配置
$updated = $content -replace '# CONFIG_LVGL is not set', 'CONFIG_LVGL=y'

# 找到 LVGL 配置块的位置
$lvglIndex = 0
for ($i = 0; $i -lt $updated.Count; $i++) {
    if ($updated[$i] -match '# LVGL Graphics Library') {
        $lvglIndex = $i
        break
    }
}

# 在 LVGL 配置后添加详细配置
$lvglConfig = @(
    'CONFIG_LVGL_V9_5=y',
    'CONFIG_LVGL_COLOR_DEPTH=16',
    'CONFIG_LVGL_MEMORY_SIZE=131072',
    'CONFIG_LVGL_USE_OS=2',
    'CONFIG_LVGL_DISPLAY_DRIVER="ST7701S"',
    'CONFIG_LVGL_DISPLAY_WIDTH=480',
    'CONFIG_LVGL_DISPLAY_HEIGHT=800',
    'CONFIG_LVGL_DOUBLE_BUFFER=y',
    'CONFIG_LVGL_DEMO_MUSIC=y',
    'CONFIG_LVGL_DEMO_MUSIC_AUTO_PLAY=y',
    'CONFIG_LVGL_USE_LOG=y'
)

# 插入配置
$newContent = @()
$inserted = $false
for ($i = 0; $i -lt $updated.Count; $i++) {
    $newContent += $updated[$i]
    if ($updated[$i] -match 'CONFIG_LVGL=y' -and -not $inserted) {
        $newContent += $lvglConfig
        $inserted = $true
    }
}

# 保存配置
$newContent | Set-Content $configFile

Write-Host "配置已更新！" -ForegroundColor Green
Write-Host ""
Write-Host "[步骤3] 验证配置..." -ForegroundColor Yellow

# 显示 LVGL 相关配置
$lvglLines = Get-Content $configFile | Where-Object { $_ -match 'CONFIG_LVGL' }
Write-Host "LVGL 配置项:" -ForegroundColor Cyan
$lvglLines | ForEach-Object { Write-Host "  $_" -ForegroundColor White }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "配置完成！接下来执行:" -ForegroundColor Green
Write-Host "  python ameba.py build" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""