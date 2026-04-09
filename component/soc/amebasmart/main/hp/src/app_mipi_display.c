/**
 * @file app_mipi_display.c
 * MIPI DSI Display Driver for ST7701S (480x800)
 * Runs on KM4 core - MIPI DSI registers are only accessible from KM4
 */

#include "ameba_soc.h"
#include <string.h>

enum {
    MIPI_DSI_DCS_SHORT_WRITE = 0x05,
    MIPI_DSI_DCS_SHORT_WRITE_PARAM = 0x15,
    MIPI_DSI_DCS_LONG_WRITE = 0x39,
};

static const char *const TAG = "MIPI_DISP";

#define LCDC_TEST_IMG_BUF_X     480
#define LCDC_TEST_IMG_BUF_Y     800
#define LCDC_IMG_BUF_ALIGNED64B(x)   (((x) & ~0x3F) + 0x40)
#define LCDC_IMG_BUF_SIZE        LCDC_IMG_BUF_ALIGNED64B(LCDC_TEST_IMG_BUF_X * LCDC_TEST_IMG_BUF_Y * 4)

#define DDR_FRAME_BUFFER_OFFSET  (10 << 20)
#define DDR_FRAME_BUFFER_ADDR     (DDR_BASE + DDR_FRAME_BUFFER_OFFSET)

#define RGB565_RED     0xF800
#define RGB565_GREEN   0x07E0
#define RGB565_BLUE    0x001F
#define RGB565_CYAN    0x07FF    // Green=63, Blue=31
#define RGB565_WHITE   0xFFFF
#define RGB565_BLACK   0x0000

#define REGFLAG_DELAY            0xFC
#define REGFLAG_END_OF_TABLE     0xFD

#define MIPI_DSI_RTNI    2
#define MIPI_DSI_HSA      4
#define MIPI_DSI_HBP     30
#define MIPI_DSI_HFP     30
#define MIPI_DSI_VSA      5
#define MIPI_DSI_VBP     20
#define MIPI_DSI_VFP     15
#define MIPI_FRAME_RATE  60
#define Mhz              1000000UL

typedef struct {
    u8 cmd;
    u8 count;
    u8 para_list[128];
} LCM_setting_table_t;

typedef struct MIPI_Irq {
    u32 IrqNum;
    u32 IrqData;
    u32 IrqPriority;
} MIPI_IRQInfo;

typedef struct LCDC_Irq {
    u32 IrqNum;
    u32 IrqData;
    u32 IrqPriority;
} LCDC_IRQInfo;

static LCDC_InitTypeDef LCDC_InitStruct;
static MIPI_InitTypeDef MIPI_InitStruct_g;
static u32 MIPI_HACT_g = LCDC_TEST_IMG_BUF_X;
static u32 MIPI_VACT_g = LCDC_TEST_IMG_BUF_Y;
static u32 vo_freq;
static volatile u32 ST7701S_Init_Done_g = 0;
static volatile u32 ST7701S_Send_cmd_g = 1;
static u32 First_Flag_g = 1;

static MIPI_IRQInfo MipiIrqInfo = {
    .IrqNum = MIPI_DSI_IRQ,
    .IrqPriority = INT_PRI_MIDDLE,
    .IrqData = (u32)MIPI,
};

static const LCM_setting_table_t ST7701S_init_cmd_g[] = {
    {0x11, 0, {0x00}},
    {REGFLAG_DELAY, 120, {}},
    {0xFF, 5, {0x77, 0x01, 0x00, 0x00, 0x10}},
    {0xC0, 2, {0x63, 0x00}},
    {0xC1, 2, {0x0C, 0x02}},
    {0xC2, 2, {0x31, 0x08}},
    {0xCC, 1, {0x10}},
    {0xB0, 16, {0x40, 0x02, 0x87, 0x0E, 0x15, 0x0A, 0x03, 0x0A, 0x0A, 0x18, 0x08, 0x16, 0x13, 0x07, 0x09, 0x19}},
    {0xB1, 16, {0x40, 0x01, 0x86, 0x0D, 0x13, 0x09, 0x03, 0x0A, 0x09, 0x1C, 0x09, 0x15, 0x13, 0x91, 0x16, 0x19}},
    {0xFF, 5, {0x77, 0x01, 0x00, 0x00, 0x11}},
    {0xB0, 1, {0x4D}},
    {0xB1, 1, {0x64}},
    {0xB2, 1, {0x07}},
    {0xB3, 1, {0x80}},
    {0xB5, 1, {0x47}},
    {0xB7, 1, {0x85}},
    {0xB8, 1, {0x21}},
    {0xB9, 1, {0x10}},
    {0xC1, 1, {0x78}},
    {0xC2, 1, {0x78}},
    {0xD0, 1, {0x88}},
    {REGFLAG_DELAY, 100, {}},
    {0xE0, 3, {0x00, 0x84, 0x02}},
    {0xE1, 11, {0x06, 0x00, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00, 0x20, 0x20}},
    {0xE2, 13, {0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}},
    {0xE3, 4, {0x00, 0x00, 0x33, 0x33}},
    {0xE4, 2, {0x44, 0x44}},
    {0xE5, 16, {0x09, 0x31, 0xBE, 0xA0, 0x0B, 0x31, 0xBE, 0xA0, 0x05, 0x31, 0xBE, 0xA0, 0x07, 0x31, 0xBE, 0xA0}},
    {0xE6, 4, {0x00, 0x00, 0x33, 0x33}},
    {0xE7, 2, {0x44, 0x44}},
    {0xE8, 16, {0x08, 0x31, 0xBE, 0xA0, 0x0A, 0x31, 0xBE, 0xA0, 0x04, 0x31, 0xBE, 0xA0, 0x06, 0x31, 0xBE, 0xA0}},
    {0xEA, 16, {0x10, 0x00, 0x10, 0x00, 0x10, 0x00, 0x10, 0x00, 0x10, 0x00, 0x10, 0x00, 0x10, 0x00, 0x10, 0x00}},
    {0xEB, 7, {0x02, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00}},
    {0xEC, 2, {0x02, 0x00}},
    {0xED, 16, {0xF5, 0x47, 0x6F, 0x0B, 0x8F, 0x9F, 0xFF, 0xFF, 0xFF, 0xFF, 0xF9, 0xF8, 0xB0, 0xF6, 0x74, 0x5F}},
    {0xEF, 12, {0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04}},
    {0xFF, 5, {0x77, 0x01, 0x00, 0x00, 0x00}},
    {0x29, 0, {0x00}},
    {REGFLAG_END_OF_TABLE, 0x00, {}},
};

static void Mipi_LCM_Set_Reset_Pin(u8 Newstatus)
{
    u32 pin_name = _PA_14;
    Pinmux_Swdoff();
    Pinmux_Config(pin_name, PINMUX_FUNCTION_GPIO);
    GPIO_InitTypeDef ResetPin;
    ResetPin.GPIO_Pin = pin_name;
    ResetPin.GPIO_PuPd = GPIO_PuPd_NOPULL;
    ResetPin.GPIO_Mode = GPIO_Mode_OUT;
    GPIO_Init(&ResetPin);
    GPIO_WriteBit(pin_name, Newstatus ?1 : 0);
}

static void MIPI_InitStruct_Config(MIPI_InitTypeDef *MIPI_InitStruct)
{
    u32 vtotal, htotal_bits, bit_per_pixel, overhead_cycles, overhead_bits, total_bits;
    u32 T_LPX = 5;
    u32 T_HS_PREP = 6;
    u32 T_HS_TRAIL = 8;
    u32 T_HS_EXIT = 7;
    u32 T_HS_ZERO = 10;

    MIPI_InitStruct->MIPI_VideoDataFormat = MIPI_VIDEO_DATA_FORMAT_RGB565;
    bit_per_pixel = 16;

    MIPI_InitStruct->MIPI_LaneNum = 2;
    MIPI_InitStruct->MIPI_FrameRate = MIPI_FRAME_RATE;
    MIPI_InitStruct->MIPI_HSA = MIPI_DSI_HSA * bit_per_pixel / 8;
    MIPI_InitStruct->MIPI_HBP = (MIPI_DSI_HSA + MIPI_DSI_HBP) * bit_per_pixel / 8;
    MIPI_InitStruct->MIPI_HACT = MIPI_HACT_g;
    MIPI_InitStruct->MIPI_HFP = MIPI_DSI_HFP * bit_per_pixel / 8;
    MIPI_InitStruct->MIPI_VSA = MIPI_DSI_VSA;
    MIPI_InitStruct->MIPI_VBP = MIPI_DSI_VBP;
    MIPI_InitStruct->MIPI_VACT = MIPI_VACT_g;
    MIPI_InitStruct->MIPI_VFP = MIPI_DSI_VFP;

    vtotal = MIPI_InitStruct->MIPI_VSA + MIPI_InitStruct->MIPI_VBP + MIPI_InitStruct->MIPI_VACT + MIPI_InitStruct->MIPI_VFP;
    htotal_bits = (MIPI_DSI_HSA + MIPI_DSI_HBP + MIPI_InitStruct->MIPI_HACT + MIPI_DSI_HFP) * bit_per_pixel;
    overhead_cycles = T_LPX + T_HS_PREP + T_HS_ZERO + T_HS_TRAIL + T_HS_EXIT;
    overhead_bits = overhead_cycles * MIPI_InitStruct->MIPI_LaneNum * 8;
    total_bits = htotal_bits + overhead_bits;

    MIPI_InitStruct->MIPI_VideDataLaneFreq = MIPI_InitStruct->MIPI_FrameRate * total_bits * vtotal / MIPI_InitStruct->MIPI_LaneNum / Mhz + 20;
    MIPI_InitStruct->MIPI_LineTime = (MIPI_InitStruct->MIPI_VideDataLaneFreq * Mhz) / 8 / MIPI_InitStruct->MIPI_FrameRate / vtotal;
    MIPI_InitStruct->MIPI_BllpLen = MIPI_InitStruct->MIPI_LineTime / 2;

    RTK_LOGI(TAG, "DataLaneFreq: %d, LineTime: %d\n", MIPI_InitStruct->MIPI_VideDataLaneFreq, MIPI_InitStruct->MIPI_LineTime);
}

static void MipiDsi_ST7701S_isr(void)
{
    MIPI_TypeDef *MIPIx = MIPI;
    u32 reg_val, reg_val2, reg_dphy_err;

    reg_val = MIPI_DSI_INTS_Get(MIPIx);
    MIPI_DSI_INTS_Clr(MIPIx, reg_val);
    reg_val2 = MIPI_DSI_INTS_ACPU_Get(MIPIx);
    MIPI_DSI_INTS_ACPU_Clr(MIPIx, reg_val2);

    if (reg_val & MIPI_BIT_CMD_TXDONE) {
        reg_val &= ~MIPI_BIT_CMD_TXDONE;
        ST7701S_Send_cmd_g = 1;
    }

    if (reg_val & MIPI_BIT_ERROR) {
        reg_dphy_err = MIPIx->MIPI_DPHY_ERR;
        MIPIx->MIPI_DPHY_ERR = reg_dphy_err;
        if (First_Flag_g != 1) {
            RTK_LOGE(TAG, "LPTX Error: 0x%lx, DPHY Error: 0x%lx\n", reg_val, reg_dphy_err);
        }
        if (MIPIx->MIPI_CONTENTION_DETECTOR_AND_STOPSTATE_DT & MIPI_MASK_DETECT_ENABLE) {
            MIPIx->MIPI_CONTENTION_DETECTOR_AND_STOPSTATE_DT &= ~MIPI_MASK_DETECT_ENABLE;
            MIPIx->MIPI_DPHY_ERR = reg_dphy_err;
            MIPI_DSI_INTS_Clr(MIPIx, MIPI_BIT_ERROR);
            if (First_Flag_g != 1) {
                RTK_LOGE(TAG, "LPTX Error CLR: 0x%lx, DPHY: 0x%lx\n", MIPIx->MIPI_INTS, MIPIx->MIPI_DPHY_ERR);
            }
        }
        if (MIPIx->MIPI_DPHY_ERR == reg_dphy_err) {
            RTK_LOGE(TAG, "LPTX Still Error\n");
            MIPI_DSI_INT_Config(MIPIx, ENABLE, DISABLE, FALSE);
        }
        reg_val &= ~MIPI_BIT_ERROR;
    }

    if (reg_val) {
        RTK_LOGE(TAG, "LPTX Error Occur: 0x%lx\n", reg_val);
    }
}

static void MipiDsi_ST7701S_Send_DCS(MIPI_TypeDef *MIPIx, u8 cmd, u8 payload_len, const u8 *para_list)
{
    u32 word0, word1, addr, idx;
    u8 cmd_addr[128];

    if (payload_len == 0) {
        MIPI_DSI_CMD_Send(MIPIx, MIPI_DSI_DCS_SHORT_WRITE, cmd, 0);
        return;
    } else if (payload_len == 1) {
        MIPI_DSI_CMD_Send(MIPIx, MIPI_DSI_DCS_SHORT_WRITE_PARAM, cmd, para_list[0]);
        return;
    }

    cmd_addr[0] = cmd;
    for (idx = 0; idx < payload_len; idx++) {
        cmd_addr[idx + 1] = para_list[idx];
    }
    payload_len = payload_len + 1;

    for (addr = 0; addr < (u32)(payload_len + 7) / 8; addr++) {
        idx = addr * 8;
        word0 = (cmd_addr[idx + 3] << 24) + (cmd_addr[idx + 2] << 16) + (cmd_addr[idx + 1] << 8) + cmd_addr[idx + 0];
        word1 = (cmd_addr[idx + 7] << 24) + (cmd_addr[idx + 6] << 16) + (cmd_addr[idx + 5] << 8) + cmd_addr[idx + 4];
        MIPI_DSI_CMD_LongPkt_MemQWordRW(MIPIx, addr, &word0, &word1, FALSE);
    }
    MIPI_DSI_CMD_Send(MIPIx, MIPI_DSI_DCS_LONG_WRITE, payload_len, 0);
}

static void MipiDsi_ST7701S_Send_Cmd(MIPI_TypeDef *MIPIx, const LCM_setting_table_t *table)
{
    static u8 send_cmd_idx_s = 0;
    u32 payload_len;
    u8 cmd, send_flag = FALSE;
    const u8 *cmd_addr;

    while (1) {
        cmd = table[send_cmd_idx_s].cmd;
        switch (cmd) {
        case REGFLAG_DELAY:
            DelayMs(table[send_cmd_idx_s].count);
            break;
        case REGFLAG_END_OF_TABLE:
            send_cmd_idx_s = 0;
            RTK_LOGI(TAG, "ST7701S Init Done\n");
            ST7701S_Init_Done_g = 1;
            First_Flag_g = 0;
            return;
        default:
            if (send_flag) {
                return;
            }
            cmd_addr = table[send_cmd_idx_s].para_list;
            payload_len = table[send_cmd_idx_s].count;
            MipiDsi_ST7701S_Send_DCS(MIPIx, cmd, payload_len, cmd_addr);
            send_flag = TRUE;
        }
        send_cmd_idx_s++;
    }
}

static void MipiDsi_ST7701S_push_table(MIPI_TypeDef *MIPIx, MIPI_InitTypeDef *MIPI_InitStruct, const LCM_setting_table_t *table)
{
    MIPI_DSI_TO1_Set(MIPIx, DISABLE, 0);
    MIPI_DSI_TO2_Set(MIPIx, ENABLE, 0x7FFFFFFF);
    MIPI_DSI_TO3_Set(MIPIx, DISABLE, 0);

    InterruptDis(MipiIrqInfo.IrqNum);
    InterruptUnRegister(MipiIrqInfo.IrqNum);
    InterruptRegister((IRQ_FUN)MipiDsi_ST7701S_isr, MipiIrqInfo.IrqNum, (u32)MipiIrqInfo.IrqData, MipiIrqInfo.IrqPriority);
    InterruptEn(MipiIrqInfo.IrqNum, MipiIrqInfo.IrqPriority);
    MIPI_DSI_INT_Config(MIPIx, DISABLE, ENABLE, FALSE);

    MIPI_DSI_init(MIPIx, MIPI_InitStruct);

    ST7701S_Init_Done_g = FALSE;
    ST7701S_Send_cmd_g = TRUE;

    while (1) {
        if (ST7701S_Send_cmd_g) {
            ST7701S_Send_cmd_g = 0;
            if (!ST7701S_Init_Done_g) {
                MipiDsi_ST7701S_Send_Cmd(MIPIx, table);
                rtos_time_delay_ms(1);
            } else {
                break;
            }
        }
    }
}

static void MipiDsi_ST7701S_lcm_init(void)
{
    MIPI_TypeDef *MIPIx = MIPI;
    MIPI_InitTypeDef *MIPI_InitStruct = &MIPI_InitStruct_g;

    MIPI_StructInit(MIPI_InitStruct);
    MIPI_InitStruct_Config(MIPI_InitStruct);
    MIPI_Init(MIPIx, MIPI_InitStruct);

    Mipi_LCM_Set_Reset_Pin(1);
    DelayMs(10);
    Mipi_LCM_Set_Reset_Pin(0);
    DelayMs(10);
    Mipi_LCM_Set_Reset_Pin(1);
    DelayMs(120);

    MipiDsi_ST7701S_push_table(MIPIx, MIPI_InitStruct, ST7701S_init_cmd_g);
    MIPI_DSI_INT_Config(MIPIx, DISABLE, DISABLE, FALSE);
}

static void LcdcEnable(void)
{
    LCDC_TypeDef *pLCDC = LCDC;
    LCDC_Cmd(pLCDC, ENABLE);
    while(!LCDC_CheckLCDCReady(pLCDC));
    RTK_LOGI(TAG, "MIPI Switch video mode!\n");
    MIPI_DSI_Mode_Switch(MIPI, ENABLE);
}

static void LcdcInitConfig(void)
{
    LCDC_StructInit(&LCDC_InitStruct);
    LCDC_InitStruct.LCDC_ImageWidth = LCDC_TEST_IMG_BUF_X;
    LCDC_InitStruct.LCDC_ImageHeight = LCDC_TEST_IMG_BUF_Y;
    LCDC_InitStruct.LCDC_BgColorRed = 0;
    LCDC_InitStruct.LCDC_BgColorGreen = 0;
    LCDC_InitStruct.LCDC_BgColorBlue = 0;

    for (u8 idx = 0; idx < LCDC_LAYER_MAX_NUM; idx++) {
        LCDC_InitStruct.layerx[idx].LCDC_LayerEn = ENABLE;
        LCDC_InitStruct.layerx[idx].LCDC_LayerImgFormat = LCDC_LAYER_IMG_FORMAT_RGB565;
        LCDC_InitStruct.layerx[idx].LCDC_LayerImgBaseAddr = (u32)DDR_FRAME_BUFFER_ADDR;
        LCDC_InitStruct.layerx[idx].LCDC_LayerHorizontalStart = 1;
        LCDC_InitStruct.layerx[idx].LCDC_LayerHorizontalStop = LCDC_TEST_IMG_BUF_X;
        LCDC_InitStruct.layerx[idx].LCDC_LayerVerticalStart = 1;
        LCDC_InitStruct.layerx[idx].LCDC_LayerVerticalStop = LCDC_TEST_IMG_BUF_Y;
    }

    LCDC_Init(LCDC, &LCDC_InitStruct);
}

u32 *mipi_display_get_frame_buffer(void)
{
    return (u32 *)DDR_FRAME_BUFFER_ADDR;
}

void mipi_display_clear(u16 color)
{
    u16 *fb = (u16 *)DDR_FRAME_BUFFER_ADDR;
    u32 total_pixels = LCDC_TEST_IMG_BUF_X * LCDC_TEST_IMG_BUF_Y;
    
    for (u32 i = 0; i < total_pixels; i++) {
        fb[i] = color;
    }
    DCache_CleanInvalidate((u32)DDR_FRAME_BUFFER_ADDR, LCDC_IMG_BUF_SIZE);
}

void mipi_display_init(void)
{
    u32 totaly = MIPI_DSI_VSA + MIPI_DSI_VBP + MIPI_DSI_VFP + LCDC_TEST_IMG_BUF_Y;
    u32 totalx = MIPI_DSI_HSA + MIPI_DSI_HBP + MIPI_DSI_HFP + LCDC_TEST_IMG_BUF_X;
    vo_freq = totaly * totalx * MIPI_FRAME_RATE / Mhz + 4;
    
    RTK_LOGI(TAG, "vo_freq: %lu\n", vo_freq);
    
    u32 PLLDiv = PLL_GET_NPLL_DIVN_SDM(PLL_BASE->PLL_NPPLL_CTRL1) + 2;
    u32 PLL_CLK = XTAL_ClkGet() * PLLDiv;
    u32 mipi_ckd = PLL_CLK / vo_freq - 1;
    HAL_WRITE32(SYSTEM_CTRL_BASE_LP, REG_LSYS_CKD_GRP0, 
        (HAL_READ32(SYSTEM_CTRL_BASE_LP, REG_LSYS_CKD_GRP0) & ~LSYS_MASK_CKD_MIPI) | LSYS_CKD_MIPI(mipi_ckd));
    HAL_WRITE32(SYSTEM_CTRL_BASE_LP, REG_LSYS_CKD_GRP0, 
        (HAL_READ32(SYSTEM_CTRL_BASE_LP, REG_LSYS_CKD_GRP0) & ~LSYS_MASK_CKD_HPERI) | LSYS_CKD_HPERI(3));

    RCC_PeriphClockCmd(APBPeriph_NULL, APBPeriph_HPERI_CLOCK, ENABLE);
    RCC_PeriphClockCmd(APBPeriph_LCDC, APBPeriph_LCDCMIPI_CLOCK, ENABLE);

    MipiDsi_ST7701S_lcm_init();
    LcdcInitConfig();
    
    mipi_display_clear(RGB565_CYAN);
    
    LCDC_DMAModeConfig(LCDC, LCDC_LAYER_BURSTSIZE_4X64BYTES);
    LCDC_DMADebugConfig(LCDC, LCDC_DMA_OUT_DISABLE, NULL);
    
    LcdcEnable();
    
    RTK_LOGI(TAG, "Display initialized - Frame buffer at 0x%08X\n", DDR_FRAME_BUFFER_ADDR);
}