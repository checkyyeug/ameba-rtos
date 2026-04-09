/**
 * @file main.c
 * LVGL Music Player Demo for Ameba RTOS
 */

#include "ameba_soc.h"
#include "lvgl.h"
#include "lv_port_disp.h"
#include "lv_demo_music.h"

static const char *const TAG = "LVGL_MUSIC";

static void vLvglTask(void *pvParameters)
{
    (void)pvParameters;
    
    RTK_LOGI(TAG, "LVGL initializing...\n");
    
    lv_init();
    
    RTK_LOGI(TAG, "Display driver initializing...\n");
    lv_port_disp_init();
    
    RTK_LOGI(TAG, "Starting Music Player Demo...\n");
    lv_demo_music();
    
    RTK_LOGI(TAG, "Music Player Demo started!\n");
    
    uint32_t last_tick = xTaskGetTickCount();
    
    while (1) {
        uint32_t current_tick = xTaskGetTickCount();
        uint32_t elapsed = (current_tick - last_tick) * portTICK_PERIOD_MS;
        
        if (elapsed >= 1) {
            last_tick = current_tick;
            lv_tick_inc(elapsed);
        }
        
        lv_timer_handler();
        
        vTaskDelay(pdMS_TO_TICK(1));
    }
}

void main(void)
{
    RTK_LOGI(TAG, "\n\n");
    RTK_LOGI(TAG, "========================================\n");
    RTK_LOGI(TAG, "  Ameba RTOS - LVGL Music Player Demo  \n");
    RTK_LOGI(TAG, "  Display: ST7701S 480x800 MIPI DSI   \n");
    RTK_LOGI(TAG, "  LVGL Version: 9.5                    \n");
    RTK_LOGI(TAG, "========================================\n");
    RTK_LOGI(TAG, "\n");
    
    BaseType_t xReturned;
    TaskHandle_t xHandle = NULL;
    
    xReturned = xTaskCreate(
        vLvglTask,
        "LVGL_Task",
        4096,
        NULL,
        tskIDLE_PRIORITY + 2,
        &xHandle
    );
    
    if (xReturned != pdPASS) {
        RTK_LOGE(TAG, "Failed to create LVGL task\n");
        return;
    }
    
    vTaskStartScheduler();
    
    for (;;) {}
}