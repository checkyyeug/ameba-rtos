# LVGL Music Player Example
# Demonstrates LVGL 9.5 Music Player on ST7701S display

# Example name
set(EXAMPLE_NAME "example_lvgl_music")

# Source files
set(EXAMPLE_SRCS
    main.c
)

# Build executable
add_executable(${EXAMPLE_NAME} ${EXAMPLE_SRCS})

# Include directories
target_include_directories(${EXAMPLE_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${PROJECT_SOURCE_DIR}/component/ui/lvgl
    ${PROJECT_SOURCE_DIR}/component/ui/lvgl/src
    ${PROJECT_SOURCE_DIR}/component/ui/lvgl/port
    ${PROJECT_SOURCE_DIR}/component/ui/lvgl/demos
    ${PROJECT_SOURCE_DIR}/component/ui/lvgl/demos/music
    ${PROJECT_SOURCE_DIR}/component/soc/amebasmart/fwlib/include
    ${PROJECT_SOURCE_DIR}/component/soc/common/include
    ${PROJECT_SOURCE_DIR}/component/os/freertos
)

# Link libraries
target_link_libraries(${EXAMPLE_NAME} PRIVATE
    lvgl
)

# Set C standard
set_target_properties(${EXAMPLE_NAME} PROPERTIES
    C_STANDARD 99
    C_STANDARD_REQUIRED ON
    OUTPUT_NAME "lvgl_music_demo"
)

# Output directory
set_target_properties(${EXAMPLE_NAME} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/examples"
)

##########################################################################################