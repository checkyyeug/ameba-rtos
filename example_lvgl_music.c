/**
 * @file example_lvgl_music.c
 * Example application entry for LVGL Music Player
 * 
 * Place this file in: component/soc/amebasmart/project/project_ap/src/
 * Or create the src directory and add to build system.
 */

#include "ameba_soc.h"
#include "lvgl.h"
#include "lv_port_disp.h"

#ifdef CONFIG_LVGL

static const char *const TAG = "LVGL_APP";
static TaskHandle_t lvgl_task_handle = NULL;

static void lvgl_main_task(void *arg)
{
    RTK_LOGI(TAG, "========================================\n");
    RTK_LOGI(TAG, "  LVGL Music Player Starting...\n");
    RTK_LOGI(TAG, "========================================\n");
    
    // 延迟等待系统稳定
    vTaskDelay(pdMS_TO_TICK(2000));
    
    // 初始化 LVGL
    RTK_LOGI(TAG, "Initializing LVGL...\n");
    lv_init();
    
    // 初始化显示驱动
    RTK_LOGI(TAG, "Initializing display driver...\n");
    lv_port_disp_init();
    
    RTK_LOGI(TAG, "LVGL initialized successfully!\n");
    RTK_LOGI(TAG, "Display: ST7701S 480x800 MIPI DSI\n");
    
    // 主循环
    while (1) {
        lv_task_handler();
        vTaskDelay(pdMS_TO_TICK(5));
    }
}

// 应用初始化函数
// 在系统启动后调用此函数
void example_lvgl_music_start(void)
{
    BaseType_t ret;
    
    RTK_LOGI(TAG, "\n");
    RTK_LOGI(TAG, "Creating LVGL application task...\n");
    
    ret = xTaskCreate(
        lvgl_main_task,
        "LVGL_Main",
        8192,      // 堆栈大小
        NULL,
        tskIDLE_PRIORITY + 3,
        &lvgl_task_handle
    );
    
    if (ret == pdPASS) {
        RTK_LOGI(TAG, "LVGL task created successfully\n");
    } else {
        RTK_LOGE(TAG, "Failed to create LVGL task!\n");
    }
}

#endif /* CONFIG_LVGL */

/*
 * 集成说明：
 * 
 * 在系统初始化代码中调用：
 * 
 * 1. 找到应用初始化位置（project_ap 的 main.c 或类似文件）
 * 2. 添加声明：
 *    extern void example_lvgl_music_start(void);
 * 3. 在系统初始化后调用：
 *    #ifdef CONFIG_LVGL
 *    example_lvgl_music_start();
 *    #endif
 * 
 * 或者在 app_main() 函数中添加调用。
 */