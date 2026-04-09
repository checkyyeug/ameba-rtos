# Music Player 示例编译指南

## 快速编译步骤

### 方式A: 直接编译（最简单）

```powershell
# 1. 确保在项目根目录
cd C:\RTL\ameba-rtos

# 2. 设置环境（如果需要）
.\env.bat

# 3. 选择目标芯片（已选择RTL8730E，可跳过）
python ameba.py soc RTL8730E

# 4. 尝试编译
python ameba.py build
```

**注意：** 由于示例还未添加到构建配置，直接编译可能不会包含LVGL示例。

---

### 方式B: 配置后编译（推荐）

#### 步骤1: 使用menuconfig配置

```powershell
# 运行menuconfig
python ameba.py menuconfig
```

**在菜单中查找并启用：**

1. 进入 `Component Configuration`
2. 查找 `UI` 或 `Graphics` 选项
3. 启用 `LVGL Support`
4. 在LVGL选项中启用 `Music Player Demo`

**如果找不到LVGL选项：**
- 表示项目需要手动配置
- 继续阅读"方式C"

---

### 方式C: 手动配置编译（完整流程）

#### 选项1: 创建配置文件

**创建配置片段：** `project/configs/ lvgl_music.conf`

```conf
# LVGL Configuration
CONFIG_LVGL=y
CONFIG_LVGL_VERSION="9.5"
CONFIG_LVGL_DISPLAY_ST7701S=y

# Enable Music Demo
CONFIG_LVGL_DEMO_MUSIC=y
CONFIG_LVGL_DEMO_MUSIC_AUTO_PLAY=y

# Display Configuration  
CONFIG_DISPLAY_DRIVER=y
CONFIG_MIPI_DSI=y
CONFIG_LCDC=y

# Memory Configuration
CONFIG_LVGL_MEM_SIZE=131072
```

**应用配置：**
```powershell
python ameba.py menuconfig -f project/configs/lvgl_music.conf
```

---

#### 选项2: 修改现有示例

**找到类似示例作为参考：**
```powershell
# 查找Display相关示例
Get-ChildItem -Path "example\peripheral\Display" -Recurse -Depth 1 | 
    Where-Object { $_.PSIsContainer -and $_.Name -ne "lvgl_music" } |
    Select-Object Name, FullName
```

**修改参考示例的构建文件：**
- 复制现有display示例的CMakeLists.txt
- 修改为LVGL配置

---

### 方式D: 最小测试（验证编译）

如果完整示例难以配置，先测试LVGL库编译：

#### 创建最小测试程序

**文件：** `test_lvgl_static.c`

```c
#include "lvgl.h"

int main(void) {
    lv_init();
    
    // 静态变量测试，避免链接问题
    static lv_color_t buf[480 * 50];
    
    lv_display_t *disp = lv_display_create(480, 800);
    lv_display_set_buffers(disp, buf, NULL, sizeof(buf), LV_DISPLAY_RENDER_MODE_PARTIAL);
    
    // 简单测试
    lv_obj_t *btn = lv_btn_create(lv_scr_act());
    
    return 0;
}
```

**编译命令（概念）：**
```powershell
# 编译LVGL库
cd component/ui/lvgl
# [根据项目构建方式]

# 或使用项目构建工具测试
python ameba.py build --component lvgl
```

---

## 完整编译流程（推荐）

### Step 1: 配置SOC和项目

```powershell
# 查看当前配置
python ameba.py show
# 输出: Current SoC: RTL8730E

# 查看可用SOC
python ameba.py list

# 选择SOC（如果需要切换）
python ameba.py soc RTL8730E
```

---

### Step 2: 配置示例路径

**方法A：修改示例CMakeLists.txt**

检查并编辑：`example/peripheral/Display/lvgl_music/CMakeLists.txt`

确保包含正确的路径：
```cmake
# 包含LVGL头文件
target_include_directories(${EXAMPLE_NAME} PRIVATE
    ${PROJECT_SOURCE_DIR}/component/ui/lvgl
    ${PROJECT_SOURCE_DIR}/component/ui/lvgl/src
    # ... 其他路径
)
```

**方法B：检查构建配置**

```powershell
# 查看项目构建配置
Get-Content "project_path.txt" -ErrorAction SilentlyContinue
Get-Content "soc_info.json"
```

---

### Step 3: 配置环境变量

```powershell
# Windows环境
.\env.bat

# 验证环境
echo $env:AMEBA_PATH
python --version
cmake --version
```

---

### Step 4: 运行menuconfig（可选）

```powershell
# 运行配置菜单
python ameba.py menuconfig

# 配置路径（示例）：
# -> Components
#    -> UI
#       -> [*] LVGL Support
#          -> [*] Music Player Demo
```

---

### Step 5: 编译

```powershell
# 完整编译
python ameba.py build

# 查看编译输出
# 如果成功，会在 build_RTL8730E/ 目录生成固件
```

---

### Step 6: 检查编译结果

```powershell
# 查看编译产物
Get-ChildItem -Path "build_RTL8730E" -Recurse -File | 
    Where-Object { $_.Name -like "*lvgl*" -or $_.Name -like "*.bin" } |
    Select-Object Name, Length, FullName

# 查看编译日志中的LVGL相关信息
Select-String -Path "build_RTL8730E\CMakeFiles\CMakeOutput.log" -Pattern "LVGL|lvgl" -ErrorAction SilentlyContinue
```

---

## 故障排除

### 问题1: 找不到LVGL头文件

**错误信息：**
```
fatal error: lvgl.h: No such file or directory
```

**解决方案：**
```powershell
# 1. 确认LVGL源码已复制
Test-Path "component\ui\lvgl\lvgl.h"
# 应返回 True

# 2. 检查CMakeLists.txt包含路径
Get-Content "component\ui\lvgl\CMakeLists.txt" | Select-String "include"

# 3. 手动添加到全局包含（如果需要）
# 编辑项目的全局CMakeLists.txt，添加：
# include_directories(component/ui/lvgl)
# include_directories(component/ui/lvgl/src)
```

---

### 问题2: 链接错误 - 找不到lvgl库

**错误信息：**
```
undefined reference to 'lv_init'
```

**解决方案：**
```powershell
# 1. 检查LVGL库构建配置
Get-Content "component\ui\lvgl\CMakeLists.txt" | Select-String "library"

# 2. 确保组件被包含
# 在项目主CMakeLists.txt或配置中添加：
# add_subdirectory(component/ui)

# 3. 检查库文件是否存在（编译后）
Get-ChildItem -Path "build_RTL8730E" -Recurse -Filter "*lvgl*" -ErrorAction SilentlyContinue
```

---

### 问题3: 编译时未包含示例

**现象：** 编译成功但没有看到Music Player示例

**解决方案：**

**选项A：修改示例Lists配置**

编辑：`example/CMakeLists.txt`（如果存在）

```cmake
# 添加示例
if(CONFIG_LVGL_DEMO_MUSIC)
    ameba_add_subdirectory(peripheral/Display/lvgl_music)
endif()
```

**选项B：使用固定路径**

在项目配置中硬编码：
```cmake
# 在项目主CMakeLists.txt中
set(EXAMPLEDIR "peripheral/Display/lvgl_music")
ameba_add_subdirectory(example/${EXAMPLEDIR})
```

---

### 问题4: 内存不足

**错误信息：**
```
region RAM overflowed
```

**解决方案：**
```powershell
# 调整LVGL内存配置
# 编辑 component/ui/lvgl/lv_conf.h
# 减小内存堆：
# #define LV_MEM_SIZE (64 * 1024U)  # 从128KB改为64KB
```

---

## 编译选项说明

### Debug编译
```powershell
# 调试模式
python ameba.py build -DDEBUG=1

# 查看详细编译信息
python ameba.py build -debug
```

### Release编译
```powershell
# 发布模式（默认）
python ameba.py build
```

### 清理编译
```powershell
# 清理构建产物
python ameba.py clean RTL8730E

# 完全清理
python ameba.py cleansoc RTL8730E
```

---

## 验证编译成功

### 编译产物检查

```powershell
# 1. 查找生成的固件
Get-ChildItem -Path "build_RTL8730E" -Recurse |
    Where-Object { $_.Name -like "*.bin" -or $_.Name -like "*.axf" } |
    Select-Object Name, Length, FullName

# 2. 查找LVGL相关对象文件
Get-ChildItem -Path "build_RTL8730E" -Recurse |
    Where-Object { $_.Name -like "*lvgl*.o" -or $_.Name -like "*lvgl*.a" } |
    Select-Object Name

# 3. 检查编译日志
if (Test-Path "build_RTL8730E\CMakeFiles\CMakeOutput.log") {
    $Log = Get-Content "build_RTL8730E\CMakeFiles\CMakeOutput.log"
    Write-Host "编译日志前20行:"
    $Log | Select-Object -First 20
}
```

---

## 下一步：烧录运行

### 查看烧录命令

```powershell
# 查看烧录帮助
python ameba.py flash -h

# 烧录固件（示例）
python ameba.py flash -p COM3 -b 1500000

# 串口监控
python ameba.py monitor -p COM3 -b 1500000
```

---

## 进阶配置

### 自定义编译选项

创建：`build_config.txt`

```
# 自定义配置
SOC=RTL8730E
EXAMPLE=peripheral/Display/lvgl_music
BUILD_TYPE=Release
VERBOSE=1
```

使用配置编译（如果支持）：
```powershell
python ameba.py build --config build_config.txt
```

---

## 获取帮助

### 项目帮助
```powershell
python ameba.py help

# 特定命令帮助
python ameba.py build -h
python ameba.py menuconfig -h
```

### 文档参考
- 构建系统: `README.md`
- 示例配置: `INTEGRATION.md`
- 故障排除: `BUILD_GUIDE.md`