# 训记助手 - 鸿蒙手机应用开发计划

## Context
基于现有的 Python 训练数据脚本（fetch_trains.py 等）和 JSON 训练数据，开发一个鸿蒙原生应用，实现训练数据的展示、分析和 DeepSeek AI 集成，自动生成训练提升周期计划。

## 项目结构
```
/Users/chefeilun/训记/训记助手/
├── AppScope/app.json5
├── entry/src/main/
│   ├── ets/
│   │   ├── entryability/EntryAbility.ets
│   │   ├── pages/
│   │   │   ├── Index.ets                    # Tab 导航主页
│   │   │   ├── DashboardPage.ets            # 首页仪表盘
│   │   │   ├── TrainingLogPage.ets          # 训练日志（日历+列表）
│   │   │   ├── ExerciseProgressPage.ets     # 动作进展图表
│   │   │   └── AICoachPage.ets              # AI 教练对话
│   │   ├── models/
│   │   │   ├── TrainingRecord.ets           # 核心数据模型
│   │   │   ├── DashboardStats.ets           # 仪表盘统计模型
│   │   │   └── AiConversation.ets           # AI 对话模型
│   │   ├── services/
│   │   │   ├── DataParser.ets               # 核心：CSV记录解析器
│   │   │   ├── DataLoader.ets               # JSON数据加载
│   │   │   ├── TrainsApiService.ets         # 训记API接口
│   │   │   ├── DeepSeekService.ets          # DeepSeek AI集成
│   │   │   ├── StatisticsEngine.ets         # 1RM/PR/周量统计
│   │   │   └── PreferencesStorage.ets       # 本地缓存
│   │   ├── viewmodel/
│   │   │   └── TrainingViewModel.ets        # 全局状态管理
│   │   ├── components/                      # UI组件
│   │   │   ├── CalendarHeatmap.ets
│   │   │   ├── StatCard.ets
│   │   │   ├── TrainingSessionCard.ets
│   │   │   ├── ExerciseCard.ets
│   │   │   ├── ExerciseSetRow.ets
│   │   │   ├── ProgressChart.ets
│   │   │   ├── OneRmBar.ets
│   │   │   ├── ChatBubble.ets
│   │   │   └── PromptChip.ets
│   │   └── utils/
│   │       ├── UnitConverter.ets
│   │       ├── DateUtils.ets
│   │       ├── EpleyFormula.ets
│   │       └── Constants.ets
│   ├── resources/base/
│   │   ├── element/{string,color}.json
│   │   ├── profile/main_pages.json
│   │   └── media/*.svg
│   └── resources/rawfile/
│       └── training_data.json               # 内置训练数据
└── [build-profile.json5, hvigorfile.ts, oh-package.json5, module.json5]
```

## 核心数据流
```
rawfile JSON → DataLoader → DataParser (解析CSV字符串) → TrainingViewModel (@Observed单例)
    ├── DashboardPage: stats cards, 1RM bar, PR list
    ├── TrainingLogPage: 日历热力图 + 训练详情列表
    ├── ExerciseProgressPage: 动作选择 + Canvas折线图
    └── AICoachPage: DeepSeek 对话 + 预设Prompt
        ↓ 可选刷新
TrainsApiService.fetchDay(today) → merge → TrainingViewModel
```

## 关键技术决策

### 1. 数据解析（最核心）
训练记录是CSV字符串，分4种类型：
- **Type A**: 力量训练 `YYMMDD,id:...,训练名,train_time:...,N.动作名,N组,重量,次数次,time:Xs,...`
- **Type B**: 有氧 `...,1.有氧训练,距离,热量kcal,心率bpm,time:Xs`
- **Type C**: Apple Health `...,1.苹果健康训练,热量kcal,time:Xs`
- **Type D**: 最小记录（缺train_time等字段）

解析策略：先检测类型 → 提取头部字段 → 定位第一个 `N.动作名` 标记 → 分离元数据和备注 → 逐组解析 → 统一归一化为kg

### 2. DeepSeek集成
- API: `https://api.deepseek.com/chat/completions`
- 模型: `deepseek-chat`，开启 streaming
- System Prompt 动态构建，注入近4周训练数据和1RM估算
- 5个预设Prompt：周度分析、进展回顾、生成计划、弱点识别、恢复建议

### 3. 状态管理
MVVM模式：`TrainingViewModel` 单例存储所有解析后数据，各页面通过 `@State` 获取派生数据

### 4. 性能优化
- 479+条记录首次解析使用后台解析，结果缓存在 Preferences
- 列表使用 `LazyForEach` 虚拟滚动
- 图表数据预计算，Canvas 绑制

## 实施顺序（10个阶段）
1. 项目骨架：项目结构、EntryAbility、Tab导航、配置文件
2. 数据模型：所有 interfaces/enums
3. 核心解析器：DataParser（处理所有边界情况）
4. 数据加载：DataLoader + Preferences + TrainingViewModel
5. 仪表盘页：StatsCard + StatisticsEngine + OneRmBar
6. 训练日志页：日历热力图 + 训练卡片 + 展开详情
7. 动作进展页：动作选择器 + Canvas折线图
8. AI 教练页：Chat UI + DeepSeek 流式对话
9. API 刷新：训记API集成 + 数据合并
10. 打磨：动画、错误状态、空状态、暗色模式

## 验证方式
项目需在 DevEco Studio 中打开，构建并运行在鸿蒙模拟器或真机上。验证：
- 首页仪表盘正确展示总训练次数/天数、三大项1RM、连续训练天数
- 训练日志页日历热力图显示正确，点击日期可展开训练详情
- 动作进展页切换动作后图表正确展示重量/1RM趋势
- AI教练页可输入 DeepSeek API Key 并正常对话
