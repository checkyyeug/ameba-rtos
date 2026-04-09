# Music Player编译助手脚本
# 运行此脚本来编译示例

param(
    [string]$Action = "build",
    [string]$SOC = "RTL8730E",
    [switch]$Clean = $false,
    [switch]$Verbose = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  LVGL Music Player 编译助手" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"

# 步骤1: 检查环境
Write-Host "`n[步骤1] 检查编译环境" -ForegroundColor Green

if (-not (Test-Path "ameba.py")) {
    Write-Host "错误: 未找到ameba.py，请在项目根目录运行此脚本" -ForegroundColor Red
    exit 1
}
Write-Host "  ✓ 找到构建脚本" -ForegroundColor Green

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "错误: 未找到Python，请先安装Python 3.x" -ForegroundColor Red
    exit 1
}
Write-Host "  ✓ Python已安装" -ForegroundColor Green

# 步骤2: 验证文件
Write-Host "`n[步骤2] 验证LVGL文件" -ForegroundColor Green

$LvglFiles = @(
    "component\ui\lvgl\lvgl.h",
    "component\ui\lvgl\lv_conf.h",
    "component\ui\lvgl\src\core\lv_obj.c",
    "component\ui\lvgl\port\lv_port_disp.c"
)

$AllFilesExist = $true
foreach ($file in $LvglFiles) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ 缺少: $file" -ForegroundColor Red
        $AllFilesExist = $false
    }
}

if (-not $AllFilesExist) {
    Write-Host "`n错误: LVGL文件不完整，请先运行setup_lvgl.ps1" -ForegroundColor Red
    exit 1
}

# 统计文件
$LvglCount = (Get-ChildItem -Path "component\ui\lvgl" -Recurse -File -ErrorAction SilentlyContinue).Count
Write-Host "  文件总数: $LvglCount" -ForegroundColor Gray

# 步骤3: 选择SOC
Write-Host "`n[步骤3] 配置目标芯片" -ForegroundColor Green
Write-Host "  目标: $SOC" -ForegroundColor Green

try {
    $result = python ameba.py soc $SOC 2>&1
    Write-Host "  ✓ SOC已选择: $SOC" -ForegroundColor Green
} catch {
    Write-Host "  ! SOC选择失败: $_" -ForegroundColor Yellow
}

# 步骤4: 清理（可选）
if ($Clean) {
    Write-Host "`n[步骤4] 清理旧的编译产物" -ForegroundColor Green
    try {
        python ameba.py clean $SOC 2>&1 | Out-Null
        Write-Host "  ✓ 清理完成" -ForegroundColor Green
    } catch {
        Write-Host "  ! 清理失败，继续..." -ForegroundColor Yellow
    }
}

# 步骤5: 开始编译
Write-Host "`n[步骤5] 开始编译" -ForegroundColor Green
Write-Host "  这可能需要几分钟..." -ForegroundColor Gray

$BuildStart = Get-Date
$BuildArgs = @("ameba.py", "build")

if ($Verbose) {
    $output = & python @BuildArgs 2>&1 | ForEach-Object { Write-Host $_ }
} else {
    try {
        $output = & python @BuildArgs 2>&1
        Write-Host "  ✓ 编译命令已执行" -ForegroundColor Green
        
        # 检查编译是否成功
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ 编译成功！" -ForegroundColor Green
        } else {
            Write-Host "  ✗ 编译失败" -ForegroundColor Red
            Write-Host "  请查看下面的错误信息" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ✗ 编译出错: $_" -ForegroundColor Red
    }
}

$BuildEnd = Get-Date
$BuildDuration = $BuildEnd - $BuildStart

# 步骤6: 检查结果
Write-Host "`n[步骤6] 检查编译结果" -ForegroundColor Green

$BuildDir = "build_$SOC"
if (Test-Path $BuildDir) {
    Write-Host "  ✓ 找到编译目录: $BuildDir" -ForegroundColor Green
    
    # 查找固件
    $BinFiles = Get-ChildItem -Path $BuildDir -Recurse -Filter "*.bin" -ErrorAction SilentlyContinue
    if ($BinFiles) {
        Write-Host "  ✓ 找到固件文件:" -ForegroundColor Green
        $BinFiles | Select-Object -First 5 | ForEach-Object {
            Write-Host "    $($_.Name) ($([math]::Round($_.Length/1KB, 1)) KB)" -ForegroundColor Gray
        }
    }
    
    # 查找LVGL相关文件
    $LvglObjFiles = Get-ChildItem -Path $BuildDir -Recurse -Filter "*lvgl*.o" -ErrorAction SilentlyContinue
    if ($LvglObjFiles) {
        Write-Host "  ✓ 找到LVGL对象文件: $($LvglObjFiles.Count) 个" -ForegroundColor Green
    }
    
    # 检查编译日志
    $LogFile = Join-Path $BuildDir "CMakeFiles\CMakeOutput.log"
    if (Test-Path $LogFile) {
        $Log = Get-Content $LogFile -ErrorAction SilentlyContinue
        $LvglMentions = $Log | Select-String -Pattern "LVGL|lvgl" -ErrorAction SilentlyContinue
        if ($LvglMentions) {
            Write-Host "  ✓ 编译日志中找到LVGL引用: $($LvglMentions.Count) 处" -ForegroundColor Green
        }
    }
} else {
    Write-Host "  ! 未找到编译目录: $BuildDir" -ForegroundColor Yellow
    Write-Host "    编译可能失败或未开始" -ForegroundColor Yellow
}

# 编译总结
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  编译总结" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SOC: $SOC" -ForegroundColor Gray
Write-Host "编译耗时: $($BuildDuration.TotalSeconds) 秒" -ForegroundColor Gray
Write-Host "编译目录: $BuildDir" -ForegroundColor Gray
Write-Host "持续时间: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray

Write-Host "`n下一步操作:" -ForegroundColor Yellow
Write-Host "  1. 如果编译成功:" -ForegroundColor White
Write-Host "     python ameba.py flash -p COM3 -b 1500000" -ForegroundColor Gray
Write-Host "  2. 如果编译失败:" -ForegroundColor White
Write-Host "     查看 COMPILE_GUIDE.md 获取故障排除" -ForegroundColor Gray
Write-Host "  3. 查看详细日志:" -ForegroundColor White
Write-Host "     Get-Content build_$SOC\CMakeFiles\CMakeOutput.log | more" -ForegroundColor Gray

Write-Host "`n文档参考:" -ForegroundColor Yellow
Write-Host "  - 编译指南: example\peripheral\Display\lvgl_music\COMPILE_GUIDE.md" -ForegroundColor Gray
Write-Host "  - 集成说明: example\peripheral\Display\lvgl_music\INTEGRATION.md" -ForegroundColor Gray
Write-Host "  - 快速开始: example\peripheral\Display\lvgl_music\QUICKSTART.md" -ForegroundColor Gray

Write-Host ""