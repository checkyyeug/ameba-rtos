# 修复编译环境脚本

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  修复Ameba编译环境" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 错误1: ccache不可用
Write-Host "`n[错误1] ccache不可用" -ForegroundColor Red
Write-Host "  原因: ccache未安装或不在PATH中" -ForegroundColor Gray

# 错误2: make不可用
Write-Host "`n[错误2] make不可用" -ForegroundColor Red
Write-Host "  原因: make工具未安装" -ForegroundColor Gray

Write-Host "`n[修复方案]" -ForegroundColor Green

Write-Host "`n方案A: 禁用ccache（推荐）" -ForegroundColor Yellow
Write-Host "  步骤:" -ForegroundColor Gray
Write-Host "  1. 编辑项目CMake配置" -ForegroundColor Gray
Write-Host "  2. 或设置环境变量" -ForegroundColor Gray

# 检查env.bat
Write-Host "`n检查环境脚本..." -ForegroundColor Cyan
if (Test-Path "env.bat") {
    Write-Host "  ✓ 找到 env.bat" -ForegroundColor Green
    
    # 检查是否有ccache配置
    $envContent = Get-Content "env.bat" -ErrorAction SilentlyContinue
    $hasCcache = $envContent | Select-String "ccache" -Quiet
    
    if ($hasCcache) {
        Write-Host "  ! env.bat中配置了ccache" -ForegroundColor Yellow
        Write-Host "    需要修改或注释掉ccache配置" -ForegroundColor Gray
        
        # 尝试自动修复
        Write-Host "`n  自动修复env.bat..." -ForegroundColor Yellow
        
        # 备份
        Copy-Item "env.bat" "env.bat.backup" -Force
        Write-Host "  ✓ 已备份到 env.bat.backup" -ForegroundColor Green
        
        # 注释ccache行
        $newContent = $envContent | ForEach-Object {
            if ($_ -match "ccache" -and $_ -notmatch "REM" -and $_ -notmatch "::" -and $_ -notmatch "#") {
                "REM $_  (disabled by build script)"
            } else {
                $_
            }
        }
        
        $newContent | Out-File "env_fixed.bat" -Encoding ASCII
        Write-Host "  ✓ 创建修复版: env_fixed.bat" -ForegroundColor Green
        
        $executeFix = Read-Host "是否使用修复版编译？(Y/N)"
        if ($executeFix -eq 'Y' -or $executeFix -eq 'y') {
            Copy-Item "env_fixed.bat" "env.bat" -Force
            Write-Host "  ✓ 已替换env.bat" -ForegroundColor Green
        }
    }
}

Write-Host "`n方案B: 安装缺失工具" -ForegroundColor Yellow
Write-Host "  使用Chocolatey安装（需要管理员权限）:" -ForegroundColor Gray
Write-Host "  choco install make ccache -y" -ForegroundColor White

Write-Host "`n方案C: 手动修复cmake配置" -ForegroundColor Yellow
Write-Host "  查找项目中的CMake配置:" -ForegroundColor Gray

# 查找CMake配置文件
$cmakeFiles = @(
    "cmake\ameba.cmake",
    "cmake\common.cmake",
    "CMakeLists.txt"
)

foreach ($file in $cmakeFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -ErrorAction SilentlyContinue
        if ($content | Select-String "ccache" -Quiet) {
            Write-Host "  找到ccache配置: $file" -ForegroundColor Gray
        }
    }
}

Write-Host "`n[推荐操作]" -ForegroundColor Green
Write-Host "  1. 运行env.bat后重试" -ForegroundColor White
Write-Host "     .\env.bat" -ForegroundColor Gray
Write-Host "     python ameba.py build" -ForegroundColor Gray

Write-Host "`n  2. 或使用修复版（如果支持）" -ForegroundColor White

Write-Host "`n[立即修复]" -ForegroundColor Green

$choice = Read-Host "选择修复方式 (A=禁用ccache并重试, B=跳过并查看文档, C=取消)"

switch ($choice) {
    'A' {
        Write-Host "`n方案A: 禁用ccache并重试" -ForegroundColor Yellow
        
        # 方法1: 设置环境变量
        $env:CCACHE_DISABLE = "1"
        $env:CCACHE_CPP2 = ""
        Write-Host "  ✓ 已设置 CCACHE_DISABLE=1" -ForegroundColor Green
        
        # 方法2: 尝试修改（如果可能）
        if (Test-Path "cmake\ameba.cmake") {
            $cmakeContent = Get-Content "cmake\ameba.cmake" -Raw
            if ($cmakeContent -match "ccache") {
                Write-Host "  ! cmake配置中有ccache引用" -ForegroundColor Yellow
                Write-Host "  建议手动注释ccache配置" -ForegroundColor Gray
            }
        }
        
        # 清理并重试
        Write-Host "`n  清理编译缓存..." -ForegroundColor Yellow
        python ameba.py clean RTL8730E 2>&1 | Out-Null
        
        Write-Host "  开始编译..." -ForegroundColor Yellow
        python ameba.py build
    }
    
    'B' {
        Write-Host "`n方案B: 查看详细文档" -ForegroundColor Yellow
        Write-Host "  文档位置:" -ForegroundColor Gray
        Write-Host "    example\peripheral\Display\lvgl_music\COMPILE_GUIDE.md" -ForegroundColor White
        Write-Host "    example\peripheral\Display\lvgl_music\NO_MENUCONFIG_SOLUTION.md" -ForegroundColor White
        
        Write-Host "`n  关键步骤:" -ForegroundColor Gray
        Write-Host "    1. 检查Toolchain路径: C:\rtk-toolchain" -ForegroundColor White
        Write-Host "    2. 确保ccache在PATH或禁用" -ForegroundColor White
        Write-Host "    3. 确保make可用（或跳过ATF编译）" -ForegroundColor White
    }
    
    'C' {
        Write-Host "`n已取消" -ForegroundColor Yellow
    }
    
    default {
        Write-Host "`n已取消" -ForegroundColor Yellow
    }
}

Write-Host "`n[系统检查]" -ForegroundColor Green
Write-Host "Toolchain路径:" -ForegroundColor Cyan
Test-Path "C:\rtk-toolchain" | ForEach-Object {
    if ($_) { Write-Host "  ✓ 找到" -ForegroundColor Green }
    else { Write-Host "  ✗ 未找到" -ForegroundColor Red }
}

Write-Host "`n推荐操作:" -ForegroundColor Yellow
Write-Host "  1. 检查env.bat配置" -ForegroundColor White
Write-Host "  2. 查看 README.md 环境配置章节" -ForegroundColor White
Write-Host "  3. 联系项目维护者获取更多帮助" -ForegroundColor White

Write-Host ""