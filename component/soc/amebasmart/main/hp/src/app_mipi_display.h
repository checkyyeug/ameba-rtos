#ifndef _APP_MIPI_DISPLAY_H_
#define _APP_MIPI_DISPLAY_H_

#include "ameba_soc.h"

#define MIPI_DISPLAY_WIDTH    480
#define MIPI_DISPLAY_HEIGHT   800

#define MIPI_DISPLAY_FB_OFFSET   (10 << 20)
#define MIPI_DISPLAY_FB_ADDR     (DDR_BASE + MIPI_DISPLAY_FB_OFFSET)

#define RGB565_RED     0xF800
#define RGB565_GREEN   0x07E0
#define RGB565_BLUE    0x001F
#define RGB565_CYAN    0x07FF
#define RGB565_WHITE   0xFFFF
#define RGB565_BLACK   0x0000

void mipi_display_init(void);
u32 *mipi_display_get_frame_buffer(void);
void mipi_display_clear(u16 color);

#endif