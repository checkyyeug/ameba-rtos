# LVGL编译测试脚本
# 测试编译LVGL示例

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  LVGL编译测试" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`n[测试1] 验证配置文件" -ForegroundColor Green
if (Test-Path "build_RTL8730E\menuconfig\.config") {
    Write-Host "  ✓ 配置文件存在" -ForegroundColor Green
    $ConfigContent = Get-Content "build_RTL8730E\menuconfig\.config" -ErrorAction SilentlyContinue
    $LVGLConfig = $ConfigContent | Select-String "LVGL" -ErrorAction SilentlyContinue
    if ($LVGLConfig) {
        Write-Host "  ✓ 找到LVGL配置:" -ForegroundColor Green
        $LVGLConfig | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    } else {
        Write-Host "  ! 未找到LVGL配置（这是正常的）" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ✗ 配置文件不存在" -ForegroundColor Red
}

Write-Host "`n[测试2] 验证LVGL文件" -ForegroundColor Green
$CriticalFiles = @(
    "component\ui\lvgl\lvgl.h",
    "component\ui\lvgl\lv_conf.h",
    "component\ui\lvgl\src\core\lv_obj.c",
    "component\ui\lvgl\CMakeLists.txt"
)

$AllExist = $true
foreach ($file in $CriticalFiles) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file 不存在" -ForegroundColor Red
        $AllExist = $false
    }
}

Write-Host "`n[测试3] 尝试编译" -ForegroundColor Green
Write-Host "  执行: python ameba.py build" -ForegroundColor Gray
Write-Host "  请等待..." -ForegroundColor Gray

try {
    $BuildStart = Get-Date
    $BuildOutput = & python ameba.py build 2>&1 | Out-String
    $BuildEnd = Get-Date
    $BuildDuration = $BuildEnd - $BuildStart
    
    Write-Host "`n  编译耗时: $($BuildDuration.TotalSeconds) 秒" -ForegroundColor Gray
    
    # 检查编译结果
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ 编译成功！" -ForegroundColor Green
        $BuildSuccess = $true
    } else {
        Write-Host "  ✗ 编译失败" -ForegroundColor Red
        $BuildSuccess = $false
    }
    
    # 查找LVGL相关信息
    Write-Host "`n[编译日志分析]" -ForegroundColor Green
    
    if ($BuildOutput -match "LVGL|lvgl") {
        Write-Host "  ✓ 编译日志中包含LVGL" -ForegroundColor Green
        $BuildOutput -split "`n" | 
            Select-String "LVGL|lvgl" | 
            Select-Object -First 5 | 
            ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    } else {
        Write-Host "  ! 编译日志中未找到LVGL" -ForegroundColor Yellow
    }
    
    # 检查错误
    if ($BuildOutput -match "error:|Error:|ERROR:") {
        Write-Host "`n  发现错误:" -ForegroundColor Red
        $BuildOutput -split "`n" | 
            Select-String "error:|Error:|ERROR:" | 
            Select-Object -First 10 | 
            ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    }
    
} catch {
    Write-Host "  ✗ 编译执行失败: $_" -ForegroundColor Red
}

Write-Host "`n[测试4] 检查编译产物" -ForegroundColor Green
if (Test-Path "build_RTL8730E") {
    $BinFiles = Get-ChildItem -Path "build_RTL8730E" -Recurse -Filter "*.bin" -ErrorAction SilentlyContinue
    if ($BinFiles) {
        Write-Host "  ✓ 找到固件文件:" -ForegroundColor Green
        $BinFiles | Select-Object -First 3 | ForEach-Object {
            Write-Host "    $($_.Name) ($([math]::Round($_.Length/1KB, 1)) KB)" -ForegroundColor Gray
        }
    }
    
    $LvglObjs = Get-ChildItem -Path "build_RTL8730E" -Recurse -Filter "*lvgl*.o" -ErrorAction SilentlyContinue
    if ($LvglObjs) {
        Write-Host "  ✓ 找到LVGL对象文件: $($LvglObjs.Count) 个" -ForegroundColor Green
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  测试总结" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($BuildSuccess) {
    Write-Host "`n恭喜！编译可能成功！" -ForegroundColor Green
    Write-Host "下一步:" -ForegroundColor Yellow
    Write-Host "  1. 查看固件位置" -ForegroundColor White
    Write-Host "     Get-ChildItem build_RTL8730E -Recurse -Filter *.bin | Select FullName" -ForegroundColor Gray
    Write-Host "`n  2. 烧录固件" -ForegroundColor White
    Write-Host "     python ameba.py flash -p COM3 -b 1500000" -ForegroundColor Gray
    Write-Host "`n  3. 串口监控" -ForegroundColor White
    Write-Host "     python ameba.py monitor -p COM3 -b 1500000" -ForegroundColor Gray
} else {
    Write-Host "`n编译遇到问题，建议：" -ForegroundColor Yellow
    Write-Host "  1. 查看编译错误" -ForegroundColor White
    Write-Host "     Get-Content build_RTL8730E\CMakeFiles\CMakeOutput.log | more" -ForegroundColor Gray
    Write-Host "`n  2. 查看详细方案" -ForegroundColor White
    Write-Host "     type example\peripheral\Display\lvgl_music\NO_MENUCONFIG_SOLUTION.md | more" -ForegroundColor Gray
    Write-Host "`n  3. 检查CMakeLists" -ForegroundColor White
    Write-Host "     Get-Content component\ui\lvgl\CMakeLists.txt | more" -ForegroundColor Gray
}

Write-Host ""