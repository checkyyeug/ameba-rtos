# LVGL Sources list with Music Demo spectrum files
# Auto-generated for LVGL 9.5 with Music Player Demo

$sourceFiles = Get-Content "lvgl_sources.txt"

# Add spectrum files
$sourceFiles += "demos/music/assets/spectrum_1.c"
$sourceFiles += "demos/music/assets/spectrum_2.c"
$sourceFiles += "demos/music/assets/spectrum_3.c"

# Generate CMakeLists.txt
$cmakeContent = @"
##########################################################################################
## LVGL Component for Ameba RTOS
## Target: ST7701S MIPI DSI Display (480x800)
## Version: LVGL 9.5 with Music Player Demo
## Auto-generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

# LVGL Sources (total: $($sourceFiles.Count) files)
ameba_list_append(private_sources
"@

# Add source files
foreach ($src in $sourceFiles) {
    $cmakeContent += "    $src`n"
}

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
    -Wno-unused-function
    -Wno-unused-variable
    -O2
)

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
$cmakeContent | Out-File -FilePath "component\ui\lvgl\CMakeLists.txt" -Encoding UTF8 -NoNewline

Write-Host "CMakeLists.txt updated with $($sourceFiles.Count) sources" -ForegroundColor Green