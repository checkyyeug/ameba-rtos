# LVGL Music Player 快速开始指南

## 移植完成清单 ✅

### 已创建的文件

```
ameba-rtos/
├── component/ui/lvgl/
│   ├── lv_conf.h                    ✅ LVGL配置（480x800，128KB内存）
│   ├── CMakeLists.txt              ✅ LVGL构建配置
│   └── port/
│       ├── lv_port_disp.h          ✅ 显示驱动头文件
│       └── lv_port_disp.c          ✅ ST7701S MIPI DSI驱动实现
│
└── example/peripheral/Display/lvgl_music/
    ├── main.c                       ✅ Music Player示例程序
    ├── CMakeLists.txt              ✅ 示例构建配置
    ├── README.md                    ✅ 详细移植文档
    └── setup_lvgl.ps1               ✅ 自动化集成脚本
```

## 快速开始步骤

### 方式一：使用自动化脚本（推荐）

```powershell
# 在PowerShell中运行（以管理员身份）
cd C:\RTL\ameba-rtos\example\peripheral\Display\lvgl_music

# 执行自动化脚本
.\setup_lvgl.ps1

# 或指定自定义LVGL路径
.\setup_lvgl.ps1 -LVGLSource "C:\lvgl\lvgl-9.5"
```

脚本会自动：
1. ✓ 验证LVGL源码
2. ✓ 创建目录结构
3. ✓ 复制LVGL核心文件（~2500文件）
4. ✓ 复制Music Demo及资源
5. ✓ 验证配置文件
6. ✓ 提供后续步骤指引

### 方式二：手动操作

#### 步骤1: 复制LVGL核心文件

```powershell
# 复制LVGL源码
Copy-Item "C:\lvgl\lvgl-9.5\lvgl.h" "C:\RTL\ameba-rtos\component\ui\lvgl\"
Copy-Item "C:\lvgl\lvgl-9.5\src" "C:\RTL\ameba-rtos\component\ui\lvgl\" -Recurse

# 复制Music Demo
Copy-Item "C:\lvgl\lvgl-9.5\demos\music" "C:\RTL\ameba-rtos\component\ui\lvgl\demos\" -Recurse
Copy-Item "C:\lvgl\lvgl-9.5\demos\lv_demos.*" "C:\RTL\ameba-rtos\component\ui\lvgl\demos\"
```

#### 步骤2: 配置项目构建

编辑项目根目录的 `CMakeLists.txt`，添加：

```cmake
# 在适当位置添加LVGL组件
add_subdirectory(component/ui/lvgl)
```

或者编辑 `.github/workflows/ameba_build_config.json`，添加LVGL示例。

#### 步骤3: 编译和运行

```powershell
# 配置环境
.\env.bat

# 选择目标芯片
python ameba.py soc RTL8730E

# 配置项目（可选，如需自定义配置）
python ameba.py menuconfig

# 编译
python ameba.py build

# 烧录
python ameba.py flash -p COM3 -b 1500000

# 串口监控
python ameba.py monitor -p COM3 -b 1500000
```

## 核心文件说明

### 1. lv_conf.h - LVGL配置文件

已针对ST7701S 480x800显示屏优化：
```c
#define LV_COLOR_DEPTH 16              // RGB565格式
#define LV_MEM_SIZE (128 * 1024U)      // 128KB内存
#define LV_USE_OS LV_OS_FREERTOS      // FreeRTOS支持
#define LV_USE_DEMO_MUSIC 1           // 启用Music Demo
#define LV_DEF_REFR_PERIOD 33          // 33ms刷新周期
```

### 2. lv_port_disp.c - 显示驱动

关键功能：
- ✓ ST7701S MIPI DSI初始化
- ✓ LCDC显示控制器配置
- ✓ 480x800分辨率支持
- ✓ 双缓冲渲染
- ✓ 自动帧同步

### 3. main.c - 示例程序

程序流程：
1. 初始化LVGL
2. 初始化显示驱动
3. 启动Music Demo
4. 主循环处理LVGL任务

## 性能参数

| 参数 | 配置值 | 说明 |
|------|--------|------|
| 显示分辨率 | 480×800 | ST7701S规格 |
| 颜色深度 | 16-bit | RGB565 |
| 内存需求 | 128KB | LVGL堆内存 |
| 渲染缓冲 | 19KB×2 | 双缓冲 |
| 帧率 | 30 FPS | 典型值 |
| Flash占用 | ~300KB | LVGL+Demo |

## 常见问题

### Q1: 编译错误 "lvgl.h not found"
**A**: 确认已复制LVGL源码，检查CMakeLists.txt包含路径配置

### Q2: 显示花屏或颜色异常
**A**: 检查`LV_COLOR_DEPTH`为16，确认MIPI DSI时序配置

### Q3: 内存不足
**A**: 适当减小`LV_MEM_SIZE`，关闭不需要的字体

### Q4: 找不到LVGL源码
**A**: 确认LVGL路径正确，或使用 `-LVGLSource` 参数指定

## 下一步

- ✅ **添加触摸屏支持** - 创建 `lv_port_indev.c`
- ✅ **自定义主题** - 修改 `lv_conf.h` 中的颜色配置
- ✅ **添加更多Demo** - Widgets, Benchmark等
- ✅ **优化性能** - 启用硬件加速，调整缓冲区大小

## 参考链接

- 📖 详细移植文档: `example/peripheral/Display/lvgl_music/README.md`
- 🎨 LVGL官方文档: https://docs.lvgl.io/9.5/
- 🔧 Ameba SDK文档: https://aiot.realmcu.com/zh/latest/rtos/index.html
- 💬 技术支持: https://forum.real-aiot.com/

---
**创建时间**: 2026-04-09
**LVGL版本**: 9.5
**目标平台**: RTL8730E/RTL8726E/RTL8721Dx
**显示屏**: ST7701S MIPI DSI (480×800)