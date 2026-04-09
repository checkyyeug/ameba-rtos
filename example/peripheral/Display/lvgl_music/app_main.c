/**
 * @file main.c
 * LVGL Music Player Example Application
 */

#include "ameba_soc.h"
#include "lvgl.h"
#include "lv_port_disp.h"

static const char *const TAG = "LVGL_APP";

// LVGL 任务
static void lvgl_task(void *arg)
{
    RTK_LOGI(TAG, "LVGL Task started\n");
    
    // 等待系统稳定
    vTaskDelay(pdMS_TO_TICK(1000));
    
    // 初始化 LVGL
    RTK_LOGI(TAG, "Initializing LVGL...\n");
    lv_init();
    
    // 初始化显示驱动
    RTK_LOGI(TAG, "Initializing display driver...\n");
    lv_port_disp_init();
    
    RTK_LOGI(TAG, "LVGL initialized successfully!\n");
    RTK_LOGI(TAG, "You should see display output now.\n");
    
    // LVGL 主循环
    while (1) {
        lv_task_handler();
        vTaskDelay(pdMS_TO_TICK(5));  // 5ms tick
    }
}

// 应用入口
void app_main(void)
{
    RTK_LOGI(TAG, "\n");
    RTK_LOGI(TAG, "========================================\n");
    RTK_LOGI(TAG, "  LVGL Music Player Application\n");
    RTK_LOGI(TAG, "  LVGL Version: 9.5\n");
    RTK_LOGI(TAG, "  Display: ST7701S 480x800\n");
    RTK_LOGI(TAG, "========================================\n");
    RTK_LOGI(TAG, "\n");
    
    // 创建 LVGL 任务
    BaseType_t xReturned = xTaskCreate(
        lvgl_task,
        "LVGL_Task",
        4096,  // 堆栈大小
        NULL,
        tskIDLE_PRIORITY + 1,
        NULL
    );
    
    if (xReturned != pdPASS) {
        RTK_LOGE(TAG, "Failed to create LVGL task!\n");
        return;
    }
    
    RTK_LOGI(TAG, "LVGL task created\n");
}

// 应用程序入口（由系统调用）
void app_start(void)
{
    app_main();
}