/**
 * @file app_lvgl_music.c
 * LVGL Music Player Demo Application Entry
 * 
 * This file initializes LVGL and starts the Music Player Demo
 */

#include "ameba_soc.h"
#include "FreeRTOS.h"
#include "task.h"
#include "lvgl.h"
#include "lv_demo_music.h"
#include "lv_port_disp.h"

#ifdef CONFIG_LVGL

static const char *const TAG = "LVGL_APP";
static TaskHandle_t lvgl_task_handle = NULL;

/**
 * LVGL Task - Main loop for LVGL
 */
static void lvgl_main_task(void *arg)
{
    (void)arg;
    uint32_t last_tick = 0;
    uint32_t current_tick = 0;
    
    RTK_LOGI(TAG, "\n");
    RTK_LOGI(TAG, "========================================\n");
    RTK_LOGI(TAG, "  LVGL Music Player Demo\n");
    RTK_LOGI(TAG, "  LVGL Version: %d.%d.%d\n", 
             LVGL_VERSION_MAJOR, LVGL_VERSION_MINOR, LVGL_VERSION_PATCH);
    RTK_LOGI(TAG, "  Display: ST7701S 480x800 (rotated to 800x480) MIPI DSI\n");
    RTK_LOGI(TAG, "========================================\n");
    RTK_LOGI(TAG, "\n");
    
    // 延迟等待系统稳定
    vTaskDelay(pdMS_TO_TICKS(2000));
    
    // 初始化 LVGL
    RTK_LOGI(TAG, "Initializing LVGL...\n");
    lv_init();
    RTK_LOGI(TAG, "LVGL initialized successfully\n");
    
    // 初始化显示驱动
    RTK_LOGI(TAG, "Initializing display driver...\n");
    lv_port_disp_init();
    RTK_LOGI(TAG, "Display driver initialized\n");
    
    // 启动 Music Demo
    RTK_LOGI(TAG, "Starting Music Player Demo...\n");
    lv_demo_music();
    RTK_LOGI(TAG, "Music Player Demo started!\n");
    
    // LVGL 主循环
    while (1) {
        current_tick = xTaskGetTickCount();
        uint32_t elapsed = current_tick - last_tick;
        
        if (elapsed > 0) {
            lv_tick_inc(elapsed);
            last_tick = current_tick;
        }
        
        lv_task_handler();
        vTaskDelay(pdMS_TO_TICKS(5));  // 5ms tick
    }
}

/**
 * Application initialization function
 * Call this from main after system init
 */
void app_lvgl_music_start(void)
{
    BaseType_t ret;
    
    RTK_LOGI(TAG, "\n");
    RTK_LOGI(TAG, "Creating LVGL Music Player task...\n");
    
    ret = xTaskCreate(
        lvgl_main_task,
        "LVGL_Music",
        8192,      // 堆栈大小 8KB
        NULL,
        tskIDLE_PRIORITY + 3,  // 中高优先级
        &lvgl_task_handle
    );
    
    if (ret == pdPASS) {
        RTK_LOGI(TAG, "LVGL task created successfully\n");
        RTK_LOGI(TAG, "Task handle: 0x%08X\n", (uint32_t)lvgl_task_handle);
    } else {
        RTK_LOGE(TAG, "Failed to create LVGL task!\n");
    }
}

#endif /* CONFIG_LVGL */