/**
 * @file lvgl_test_minimal.c
 * LVGL 最小测试程序 - 只显示一个文字标签
 */

#include "ameba_soc.h"
#include "lvgl.h"

// 简单显示驱动（内存显示，无硬件）
static lv_display_t *disp = NULL;
static uint8_t buf[480 * 50 * 2];  // 小缓冲区

static void disp_flush(lv_display_t *disp, const lv_area_t *area, uint8_t *px_map)
{
    // 最小实现：直接完成
    lv_display_flush_ready(disp);
}

int lvgl_test_init(void)
{
    // 初始化 LVGL
    lv_init();
    
    // 创建显示
    disp = lv_display_create(480, 800);
    if(!disp) {
        return -1;
    }
    
    // 设置缓冲区
    lv_display_set_buffers(disp, buf, NULL, sizeof(buf), LV_DISPLAY_RENDER_MODE_PARTIAL);
    lv_display_set_flush_cb(disp, disp_flush);
    
    // 创建简单UI - 一个文字标签
    lv_obj_t *label = lv_label_create(lv_screen_active());
    lv_label_set_text(label, "LVGL OK!");
    lv_obj_center(label);
    
    return 0;
}

void lvgl_task(void *arg)
{
    RTK_LOGI("LVGL_TEST", "Starting LVGL minimal test...\n");
    
    if(lvgl_test_init() != 0) {
        RTK_LOGE("LVGL_TEST", "LVGL init failed!\n");
        return;
    }
    
    RTK_LOGI("LVGL_TEST", "LVGL initialized!\n");
    RTK_LOGI("LVGL_TEST", "If display connected, you should see 'LVGL OK!'\n");
    
    while(1) {
        lv_task_handler();
        vTaskDelay(pdMS_TO_TICK(5));
    }
}