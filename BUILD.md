# 训记助手 — 构建与安装指南

## 方式一：使用 DevEco Studio（推荐）

### 前提
- 安装 [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/)（华为官方 IDE）
- 安装 HarmonyOS SDK（DevEco Studio 启动后自动引导安装）

### 构建步骤

1. **打开项目**
   - 启动 DevEco Studio
   - `File → Open →` 选择本项目目录（`训记助手/`）

2. **等待依赖自动加载**
   - DevEco Studio 会自动下载 `oh_modules` 依赖
   - 底部状态栏会显示进度

3. **构建安装包**
   - **生成 HAP（调试包）**: `Build → Build HAP(s)`
   - **生成 APP（正式包）**: `Build → Build APP(s)`
   - 输出位置: `build/outputs/default/`

4. **安装到设备**

   **方法 A — DevEco Studio 直接运行:**
   - 连接鸿蒙设备（USB 或远程模拟器）
   - 点击工具栏 ▶️ 按钮

   **方法 B — hdc 命令行:**
```bash
   # 查看连接的设备
   hdc list targets

   # 安装 HAP
   hdc install build/outputs/default/entry-default-unsigned.hap

   # 安装 APP 包
   hdc app install build/outputs/default/entry-default-unsigned.app
```

## 方式二：一键脚本

如果有 DevEco Studio 已安装的 node 环境，也可以用脚本：

```bash
bash build.sh
```

根据提示选择构建类型即可。

## 数据准备

训练数据已内置在 `entry/src/main/resources/rawfile/training_data.json`（共 410 天 / 479 条记录）。

如需更新数据，可将最新的 `historical_trains.json` 或 `recent_month_trains.json` 放回 rawfile 目录。
