# LVGL Music Player 移植指南 - Ameba RTOS

## 概述

本文档介绍如何将LVGL 9.5 Music Player Demo移植到Realtek Ameba RTOS平台，支持ST7701S MIPI DSI显示屏（480x800）。

## 系统要求

- **项目**: ameba-rtos
- **目标芯片**: RTL8730E / RTL8726E / RTL8721Dx 等
- **显示屏**: ST7701S MIPI DSI (480x800)
- **LVGL版本**: 9.5
- **RTOS**: FreeRTOS

## 移植步骤

### 步骤1: 复制LVGL核心库

```powershell
# 方式A: 直接复制整个LVGL源码
Copy-Item -Path "C:\lvgl\lvgl-9.5\src" -Destination "C:\RTL\ameba-rtos\component\ui\lvgl\src" -Recurse

# 复制LVGL头文件
Copy-Item -Path "C:\lvgl\lvgl-9.5\lvgl.h" -Destination "C:\RTL\ameba-rtos\component\ui\lvgl\"
Copy-Item -Path "C:\lvgl\lvgl_conf.h" -Destination "C:\RTL\ameba-rtos\component\ui\lvgl\" -ErrorAction SilentlyContinue

# 方式B: 创建符号链接（节省磁盘空间）
# New-Item -ItemType SymbolicLink -Path "C:\RTL\ameba-rtos\component\ui\lvgl\src" -Target "C:\lvgl\lvgl-9.5\src"
```

### 步骤2: 复制Music Demo资源

```powershell
# 创建demo目录
New-Item -ItemType Directory -Path "C:\RTL\ameba-rtos\component\ui\lvgl\demos\music" -Force

# 复制music demo源码
Copy-Item -Path "C:\lvgl\lvgl-9.5\demos\music\*" -Destination "C:\RTL\ameba-rtos\component\ui\lvgl\demos\music\" -Recurse

# 复制demos公共文件
Copy-Item -Path "C:\lvgl\lvgl-9.5\demos\lv_demos.h" -Destination "C:\RTL\ameba-rtos\component\ui\lvgl\demos\"
Copy-Item -Path "C:\lvgl\lvgl-9.5\demos\lv_demos.c" -Destination "C:\RTL\ameba-rtos\component\ui\lvgl\demos\"
```

### 步骤3: 配置文件已创建

以下文件已在 `component/ui/lvgl/` 创建:
- ✅ `lv_conf.h` - LVGL配置（已配置480x800分辨率，128KB内存）
- ✅ `port/lv_port_disp.h` - 显示驱动头文件
- ✅ `port/lv_port_disp.c` - ST7701S显示驱动实现

### 步骤4: 创建示例程序

示例程序已创建在: `example/peripheral/Display/lvgl_music/main.c`

### 步骤5: 配置CMake

已创建以下CMake配置文件:
- ✅ `component/ui/lvgl/CMakeLists.txt` - LVGL组件构建配置
- ✅ `example/peripheral/Display/lvgl_music/CMakeLists.txt` - 示例程序构建配置

### 步骤6: 修改项目构建配置

编辑 `project_path/CMakeLists.txt` 或相关配置文件，添加：

```cmake
# 添加LVGL组件
add_subdirectory(component/ui/lvgl)

# 在示例配置中启用LVGL Music示例
set(EXAMPLEDIR "example/peripheral/Display/lvgl_music")
```

### 步骤7: 编译项目

```powershell
# Windows环境
.\env.bat

# 配置目标芯片（例如RTL8730E）
python ameba.py soc RTL8730E

# 编译
python ameba.py build
```

### 步骤8: 烧录运行

```powershell
# 烧录固件
python ameba.py flash -p COM3 -b 1500000

# 串口监控
python amebe.py monitor -p COM3 -b 1500000
```

## 关键配置说明

### lv_conf.h 重要配置

```c
// 显示分辨率
#define DISP_HOR_RES 480
#define DISP_VER_RES 800

// 颜色深度 - RGB565
#define LV_COLOR_DEPTH 16

// 内存配置 - 128KB推荐用于Music Demo
#define LV_MEM_SIZE (128 * 1024U)

// 启用FreeRTOS支持
#define LV_USE_OS LV_OS_FREERTOS

// 启用Music Demo
#define LV_USE_DEMO_MUSIC 1
#define LV_DEMO_MUSIC_AUTO_PLAY 1

// 字体配置（Music Demo必需）
#define LV_FONT_MONTSERRAT_12 1
#define LV_FONT_MONTSERRAT_14 1
#define LV_FONT_MONTSERRAT_16 1
#define LV_FONT_MONTSERRAT_22 1
#define LV_FONT_MONTSERRAT_24 1
```

### 显示接口配置

显示驱动会自动初始化：
- MIPI DSI接口
- ST7701S驱动IC
- LCDC显示控制器
- 双缓冲渲染

## 文件结构

```
ameba-rtos/
├── component/ui/lvgl/
│   ├── lv_conf.h              # LVGL配置文件
│   ├── lvgl.h                 # LVGL主头文件（从lvgl-9.5复制）
│   ├── src/                   # LVGL源码（从lvgl-9.5复制）
│   ├── port/                  # 移植接口
│   │   ├── lv_port_disp.h     # 显示驱动头文件
│   │   └── lv_port_disp.c     # ST7701S显示驱动
│   ├── demos/                 # Demo程序
│   │   ├── lv_demos.h
│   │   ├── lv_demos.c
│   │   └── music/             # Music Demo
│   │       ├── lv_demo_music.c
│   │       ├── lv_demo_music.h
│   │       └── assets/        # 资源文件
│   └── CMakeLists.txt         # 构建配置
├── example/peripheral/Display/lvgl_music/
│   ├── main.c                 # 示例主程序
│   ├── CMakeLists.txt        # 示例构建配置
│   └── README.md              # 本文档
```

## 调试说明

### 常见问题

**1. 显示花屏或颜色错误**
- 检查`LV_COLOR_DEPTH`配置是否为16（RGB565）
- 确认MIPI DSI时序参数匹配ST7701S规格
- 验证显示缓冲内存对齐（64字节）

**2. 内存不足**
- 增大`LV_MEM_SIZE`配置
- 减小渲染缓冲区大小
- 关闭不必要的字体

**3. 显示不刷新**
- 检查`disp_flush()`函数是否正确调用`lv_display_flush_ready()`
- 确认`DCache_CleanInvalidate()`正确清除缓存
- 查看LCDC中断是否正常触发

**4. 编译错误：找不到lvgl.h**
- 确认LVGL源码已复制到正确位置
- 检查CMakeLists.txt中的include路径配置

### 日志输出

启用了`LV_USE_LOG`，可通过串口查看：
- WARN级别日志会输出到串口
- 初始化成功会输出："LVGL display driver initialized"

## 性能优化建议

1. **双缓冲渲染** - 已默认启用，减少撕裂
2. **部分刷新** - 只刷新变化区域
3. **内存优化** - 使用外部SDRAM存储图片资源
4. **DMA加速** - LCDC硬件DMA自动传输帧数据

## 资源占用估算

- **Flash**: ~300KB (LVGL核心 + fonts + assets)
- **RAM**: ~150KB
  - LVGL堆: 128KB
  - 渲染缓冲: 19KB (480*800/10 * 2次)
  - 显示缓冲: 可用SDRAM

## 下一步扩展

- 添加触摸屏输入驱动 (`lv_port_indev.c`)
- 添加更多LVGL demo (widgets, benchmark等)
- 自定义Music Player界面
- 集成音频播放功能

## 参考资料

- LVGL官方文档: https://docs.lvgl.io/9.5/
- Ameba RTOS SDK文档: https://aiot.realmcu.com/zh/latest/rtos/index.html
- ST7701S数据手册: Refer to display vendor
- MIPI DSI规范: MIPI Alliance

## 技术支持

如遇问题，可通过以下途径寻求帮助：
1. 查看项目Issues: https://github.com/Ameba-AIoT/ameba-rtos/issues
2. LVGL论坛: https://forum.lvgl.io
3. Real-AIOT论坛: https://forum.real-aiot.com/