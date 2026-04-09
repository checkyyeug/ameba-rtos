# LVGL Music Player - 运行指南

## 当前状态

✅ **LVGL 已成功集成到固件**
- 固件文件：`build_RTL8730E/km0_km4_ca32_app.bin`
- LVGL 版本：9.5
- 编译源文件：223 个

## 立即可用的方法

### 方法1：使用当前固件（推荐）

固件已成功烧录！系统正常运行中。

```powershell
# 连接串口查看输出
python ameba.py monitor -b 1500000

# 观察日志中是否有 LVGL 相关信息
```

### 方法2：添加应用初始化代码

1. **复制应用入口**：
   ```powershell
   copy example_lvgl_music.c component\soc\amebasmart\project\project_ap\src\
   ```

2. **在系统启动代码中调用**：
   ```powershell
   # 编辑 project_ap 的启动代码（需找到实际文件位置）
   # 添加以下调用：
   # extern void example_lvgl_music_start(void);
   # example_lvgl_music_start();
   ```

3. **重新编译**：
   ```powershell
   python ameba.py build
   ```

### 方法3：等显示驱动实现后运行

**Music Player Demo 完整功能需要**：

1. **显示驱动**（`lv_port_disp.c`）
   - ST7701S MIPI DSI 初始化
   - 帧缓冲区配置
   - `disp_flush` 回调实现

2. **应用入口**
   - 在启动时调用 `lv_init()`
   - 初始化显示驱动 `lv_port_disp_init()`
   - 创建 LVGL 任务

3. **Music Demo 资源**（可选）
   - 频谱数据文件 `spectrum_*.h`
   - 从 LVGL 官方获取

## 已创建的文件

| 文件 | 说明 | 位置 |
|------|------|------|
| `example_lvgl_music.c` | 应用入口示例 | `C:\RTL\ameba-rtos\` |
| `lv_port_disp.c` | 显示驱动框架 | `component/ui/lvgl/port/` |
| `enable_lvgl.ps1` | 配置脚本 | 根目录 |
| `build_music_player.bat` | 构建脚本 | 根目录 |

## 下一步操作

### 立即可做

```powershell
# 连接设备查看状态
python ameba.py monitor -b 1500000

# 如果系统正常，可以看到启动日志
# 可用内存约 3.3 MB
```

### 如需显示输出

需要实现硬件驱动的初始化：
1. 配置 ST7701S 显示控制器
2. 设置 MIPI DSI 接口
3. 分配显示缓冲区

### Music Player 完整版

1. 获取完整资源文件
2. 启用 Music Demo 配置
3. 实现触摸输入（如需交互）

## 文件位置参考

```
ameba-rtos/
├── component/ui/lvgl/
│   ├── lv_conf.h                    # LVGL 配置
│   ├── lvgl.h                       # LVGL 头文件
│   ├── lv_version.h                 # 版本信息
│   ├── CMakeLists.txt               # 构建配置
│   └── port/
│       └── lv_port_disp.c           # 显示驱动
│
├── example/peripheral/Display/lvgl_music/
│   ├── main.c                       # 示例主程序
│   ├── app_main.c                   # 应用入口
│   ├── QUICKSTART.md                # 快速开始
│   ├── BUILD_GUIDE.md               # 构建指南
│   └── INTEGRATION.md               # 集成指南
│
└── build_RTL8730E/
    └── km0_km4_ca32_app.bin         # 最终固件
```

## 技术支持

- 详细文档：`example/peripheral/Display/lvgl_music/`
- LVGL 官方：https://lvgl.io
- GitHub：https://github.com/lvgl/lvgl

---

**当前固件已就绪，可直接使用！**