/**
 * 首页仪表盘
 * 展示训练总览统计、三大项1RM、连续训练天数
 */

import { viewModel, LoadState } from '../viewmodel/TrainingViewModel';
import { StatCard } from '../components/StatCard';
import { OneRmBar } from '../components/OneRmBar';
import { formatDuration } from '../utils/DateUtils';
import { BIG_THREE_EXERCISES } from '../models/TrainingRecord';
import { ExercisePR } from '../models/DashboardStats';

@Component
export struct DashboardPage {
  @State loadState: LoadState = viewModel.loadState;

  aboutToAppear(): void {
    this.loadState = viewModel.loadState;
  }

  build() {
    Column() {
      // 页面标题
      Text('训练仪表盘')
        .fontSize(22)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ top: 16, bottom: 8, left: 20 })

      if (this.loadState === LoadState.LOADING) {
        this.buildLoadingState()
      } else if (this.loadState === LoadState.EMPTY) {
        this.buildEmptyState()
      } else if (this.loadState === LoadState.ERROR) {
        this.buildErrorState()
      } else {
        this.buildDashboard()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildLoadingState() {
    Column() {
      LoadingProgress()
        .color($r('app.color.primary'))
        .width(40)
        .height(40)

      Text('加载训练数据...')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildEmptyState() {
    Column() {
      Text('🏋️')
        .fontSize(48)

      Text('暂无训练数据')
        .fontSize(16)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 12 })

      Text('请先同步训练数据到 training_data.json')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildErrorState() {
    Column() {
      Text('⚠️')
        .fontSize(48)

      Text('加载失败')
        .fontSize(16)
        .fontColor($r('app.color.accent_red'))
        .margin({ top: 12 })

      Text(viewModel.loadError)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 4 })
        .textAlign(TextAlign.Center)
        .padding({ horizontal: 32 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildDashboard() {
    Scroll() {
      Column() {
        // 统计卡片网格
        this.buildStatsGrid()

        // 分隔
        Divider()
          .height(0.5)
          .color('rgba(255,255,255,0.06)')
          .margin({ vertical: 16 })

        // 三大项1RM
        this.buildBigThreeSection()

        // 连续训练天数
        this.buildStreakSection()
      }
      .padding(16)
      .width('100%')
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
  }

  @Builder
  buildStatsGrid() {
    // 使用 Grid 或 Row 实现 2x2 网格
    Column() {
      // 第一行
      Row() {
        StatCard({
          label: '总训练天数',
          value: `${viewModel.dashboardStats.totalTrainingDays}`,
          unit: '天',
          icon: '📅',
          accentColor: $r('app.color.primary')
        })
        .width('48%')

        StatCard({
          label: '总训练次数',
          value: `${viewModel.dashboardStats.totalSessions}`,
          unit: '次',
          icon: '💪',
          accentColor: $r('app.color.accent_green')
        })
        .width('48%')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 12 })

      // 第二行
      Row() {
        StatCard({
          label: '总组数',
          value: `${viewModel.dashboardStats.totalSets}`,
          unit: '组',
          icon: '📊',
          accentColor: $r('app.color.accent_orange')
        })
        .width('48%')

        StatCard({
          label: '总训练时长',
          value: formatDuration(viewModel.dashboardStats.totalDurationMinutes).replace('分', '').replace('时', 'h '),
          unit: formatDuration(viewModel.dashboardStats.totalDurationMinutes).includes('时') ? '时' : '分',
          icon: '⏱️',
          accentColor: $r('app.color.primary_dark')
        })
        .width('48%')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
  }

  @Builder
  buildBigThreeSection() {
    Column() {
      Text('三大项 1RM')
        .fontSize(16)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 12 })

      if (viewModel.dashboardStats.bigThreePRs.length === 0) {
        Text('暂无三大项训练数据')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding(16)
      } else {
        const maxOneRm = Math.max(...viewModel.dashboardStats.bigThreePRs.map(p => p.estimatedOneRm), 1);
        ForEach(viewModel.dashboardStats.bigThreePRs, (pr: ExercisePR) => {
          OneRmBar({
            exerciseName: pr.exerciseName,
            oneRm: pr.estimatedOneRm,
            maxOneRm: maxOneRm,
            barColor: getBigThreeColor(pr.exerciseName)
          })
        }, (pr: ExercisePR) => pr.exerciseName)

        // 1RM数值详情
        ForEach(viewModel.dashboardStats.bigThreePRs, (pr: ExercisePR) => {
          Row() {
            Text(`${pr.date}`)
              .fontSize(11)
              .fontColor($r('app.color.text_secondary'))

            Text(`${pr.weight}kg × ${pr.reps}次`)
              .fontSize(11)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ left: 8, top: 2 })
        }, (pr: ExercisePR) => `${pr.exerciseName}_detail`)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .margin({ bottom: 16 })
  }

  @Builder
  buildStreakSection() {
    Row() {
      Text('🔥')
        .fontSize(28)

      Column() {
        Text(`${viewModel.dashboardStats.streakDays}`)
          .fontSize(36)
          .fontColor($r('app.color.accent_orange'))
          .fontWeight(FontWeight.Bold)

        Text('连续训练天数')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
      }
      .margin({ left: 16 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(20)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Start)
  }
}

function getBigThreeColor(name: string): ResourceColor {
  switch (name) {
    case '深蹲': return '#FF6C63FF'
    case '杠铃卧推': return '#FF4CAF50'
    case '硬拉': return '#FFFF9800'
    default: return $r('app.color.primary')
  }
}
