# LVGL Sources list (for use in CMakeLists.txt)
# This file contains all LVGL 9.5 source files with correct paths

$sourceFiles = Get-Content "lvgl_sources.txt"

# Generate CMakeLists.txt
$cmakeContent = @"
##########################################################################################
## LVGL Component for Ameba RTOS
## Target: ST7701S MIPI DSI Display (480x800)
## Version: LVGL 9.5 with Music Player Demo
## Auto-generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

# Public includes and definitions
set(public_includes)
set(public_definitions)
set(public_libraries)

#----------------------------------------#
# Component public part, user config begin

# LVGL header files
ameba_list_append(public_includes
    `${CMAKE_CURRENT_SOURCE_DIR}
    `${CMAKE_CURRENT_SOURCE_DIR}/src
    `${CMAKE_CURRENT_SOURCE_DIR}/port
)

# LVGL configuration
ameba_list_append(public_definitions
    LV_CONF_PATH="`${CMAKE_CURRENT_SOURCE_DIR}/lv_conf.h"
    LV_CONF_SKIP
)

# Component public part, user config end
#----------------------------------------#

# Apply global configuration
ameba_global_include(`${public_includes})
ameba_global_define(`${public_definitions})
ameba_global_library(`${public_libraries})

##########################################################################################
## Private part - LVGL Library

set(private_sources)
set(private_includes)
set(private_definitions)
set(private_compile_options)

#----------------------------------------#
# Component private part, user config begin

# LVGL Sources (auto-generated - $(($sourceFiles.Count)) files)
ameba_list_append(private_sources
"@

# 添加源文件
$cmakeContent += $sourceFiles | ForEach-Object { "    $_" }
$cmakeContent += @"

)

# Private includes
ameba_list_append(private_includes
    `${CMAKE_CURRENT_SOURCE_DIR}/src
    `${CMAKE_CURRENT_SOURCE_DIR}/port
    `${CMAKE_CURRENT_SOURCE_DIR}/demos
    `${CMAKE_CURRENT_SOURCE_DIR}/demos/music
)

# Private definitions
ameba_list_append(private_definitions
    LV_CONF_PATH="`${CMAKE_CURRENT_SOURCE_DIR}/lv_conf.h"
)

# Private compile options
ameba_list_append(private_compile_options
    -Wall
    -Wextra
    -Wno-unused-parameter
    -Wno-format
    -O2
)

# Component private part, user config end
#----------------------------------------#

# Build LVGL as internal library
ameba_add_internal_library(lvgl
    p_SOURCES
        `${private_sources}
    p_INCLUDES
        `${private_includes}
    p_DEFINITIONS
        `${private_definitions}
    p_COMPILE_OPTIONS
        `${private_compile_options}
)

##########################################################################################
"@

# Save to file
$cmakeContent | Out-File -FilePath "C:\RTL\ameba-rtos\component\ui\lvgl\CMakeLists.txt" -Encoding UTF8 -NoNewline

Write-Host "CMakeLists.txt 已更新！" -ForegroundColor Green
Write-Host "总共 $($sourceFiles.Count) 个源文件" -ForegroundColor Cyan
Write-Host ""
Write-Host "前5个源文件:" -ForegroundColor Yellow
$sourceFiles | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" -ForegroundColor White }