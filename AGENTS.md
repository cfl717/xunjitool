# 训记助手 — HarmonyOS 健身训练助手 App

## Project
HarmonyOS ArkTS 应用，使用 ArkUI 框架。4 Tab 页面：仪表盘、训练日志、动作进展、AI 教练。MVVM 架构（ViewModel 单例模式）。
- 入口: `entry/src/main/ets/entryability/EntryAbility.ets` → `pages/Index.ets`
- 构建工具: `@ohos/hvigor` 6.24.2 + Hvigor Plugin 6.24.2
- SDK: HarmonyOS API 24 (6.1.1) — `hwsdk.dir=/Applications/DevEco-Studio.app/Contents/sdk/`
- 签名: 自动生成调试证书，已配置在 `build-profile.json5`

## Commands
```bash
# 构建（CLI）
cd /Users/chefeilun/xunji/xunjitool
export JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home
export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk/
export PATH=$JAVA_HOME/bin:$PATH
node node_modules/@ohos/hvigor/bin/hvigor.js --no-daemon assembleHap

# 或使用项目根目录的 hvigorw 脚本
./hvigorw --no-daemon assembleHap

# 安装到设备
hdc install -r entry/build/default/outputs/default/entry-default-signed.hap

# 完整重装
hdc uninstall com.cfl.xunjitool && hdc install entry/build/default/outputs/default/entry-default-signed.hap

# hdc 路径
HDC=/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc
```

## Architecture

```
pages/
├── Index.ets              # @Entry 主页面, 4 Tab 容器
├── DashboardPage.ets      # 首页: 统计卡片 + 连续天数
├── TrainingLogPage.ets    # 训练日志: 按日期列出训练记录
├── ExerciseProgressPage.ets # 动作进展: 选择动作 + 柱状图
└── AICoachPage.ets        # AI 教练: 聊天 + 训练计划库

components/                # 可复用 UI 组件
├── CalendarHeatmap.ets    # 日历热力图
├── ChatBubble.ets         # AI 聊天气泡（含 Markdown 渲染）
├── MarkdownContent.ets    # Markdown 渲染组件（标题/列表/代码/引用/表格）
├── ExerciseCard.ets       # 动作卡片（含组列表）
├── ExerciseSetRow.ets     # 单组数据显示
├── OneRmBar.ets           # 1RM 对比条
├── ProgressChart.ets      # 1RM 趋势折线图 (Canvas)
├── PromptChip.ets         # AI 预设提示词按钮
├── StatCard.ets           # 统计卡片
└── TrainingSessionCard.ets # 训练会话卡片（可展开）

models/                    # 数据模型
├── TrainingRecord.ets     # 训练记录核心模型
├── DashboardStats.ets     # 仪表盘统计
├── AiConversation.ets     # AI 对话 + DeepSeek 配置
├── MarkdownTypes.ets      # Markdown 块/行内类型

services/                  # 业务逻辑
├── DataLoader.ets         # 本地数据加载（rawfile + cache）
├── DataParser.ets         # CSV 数据解析
├── DeepSeekService.ets    # DeepSeek API 调用 + 日志
├── PreferencesStorage.ets # 持久化存储
├── StatisticsEngine.ets   # 统计计算
├── TrainsApiService.ets   # 训记 Open API 接口

utils/                     # 工具函数
├── Constants.ets          # 常量 + 模型列表
├── DateUtils.ets          # 日期工具
├── EpleyFormula.ets       # 1RM 计算公式
├── MarkdownParser.ets     # Markdown 解析器
├── UnitConverter.ets      # 单位转换

viewmodel/
└── TrainingViewModel.ets  # MVVM 单例, 核心数据状态
```

关键数据流: `loadFromRawFile()` → `viewModel.initialize()` → pages 通过 getter 读取 `viewModel.allRecords / dashboardStats / exerciseNames`

## Conventions
- **语言**: 全中文（UI 文本、注释、错误信息）。变量名用英文缩写（如 R=records, S=stats, N=names, D=dirty）。
- **数据流**: ViewModel 单例模式 (`export const viewModel = new VM()`)，page 通过 `viewModel.*` getter 读取数据。
- **ArkTS 限制**:
  - 不要用 `Canvas`/`CanvasRenderingContext2D`（Mate 80 上不兼容）
  - 不要用 `@Builder` 嵌套 `ForEach` + `onClick`（事件可能不响应），改用独立方法或直接 `build()` 内 `onClick`
  - 不要在 `@Builder` 内用 `const`/`let` 声明
  - 对象字面量必须有显式接口类型（`interface CP { date: string; value: number; }`）
  - 避免多层 `Scroll` 嵌套
  - SSE 流式 Promise 永不 resolve（`setTimeout` 不可用），改用非流式请求
- **响应式**: 外部对象属性不会触发 ArkTS 重渲染。页面需用 `@State` 变量 + `aboutToAppear()` 同步数据。
- **错误处理**: API 调用失败不阻断主流程，降级到本地数据或内置样本数据。异步异常用 `.catch()` 静默处理。

## Notes
- **闪退排查**: 先回退到最简版本（纯 Text + Row，无 ForEach 嵌套、无 `@Builder`）验证基础功能，再逐步加复杂 UI 定位崩溃点。不要用 `Map.keys()` 迭代器、`Array.from()`。
- **构建环境**: 确保 `JAVA_HOME` 指向 DevEco Studio 内置 JDK (`/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home`)，`DEVECO_SDK_HOME` 指向 SDK 根目录。
- **安装**: 优先用 `hdc install -r` 增量安装，不丢失缓存数据。需要全新安装时先 `uninstall`。
