import { viewModel, LoadState } from '../viewmodel/TrainingViewModel';
import { StatCard } from '../components/StatCard';
import { OneRmBar } from '../components/OneRmBar';
import { formatDuration } from '../utils/DateUtils';
import { ExercisePR } from '../models/DashboardStats';

@Component
export struct DashboardPage {
  @State loadState: LoadState = viewModel.loadState;

  aboutToAppear(): void { this.loadState = viewModel.loadState; }

  getMaxRm(): number {
    const prs = viewModel.dashboardStats.bigThreePRs;
    if (prs.length === 0) return 1;
    let max = 1;
    for (const p of prs) { if (p.estimatedOneRm > max) max = p.estimatedOneRm; }
    return max;
  }

  build() {
    Column() {
      Text('训练仪表盘').fontSize(22).fontColor(Color.White).fontWeight(FontWeight.Bold).width('100%').padding({ top: 16, bottom: 8, left: 20 })
      if (this.loadState === LoadState.LOADING) { this.buildLoading() }
      else if (this.loadState === LoadState.EMPTY) { this.buildEmpty() }
      else if (this.loadState === LoadState.ERROR) { this.buildError() }
      else { this.buildDashboard() }
    }.width('100%').height('100%').backgroundColor($r('app.color.background'))
  }

  @Builder
  buildLoading() {
    Column() {
      LoadingProgress().color($r('app.color.primary')).width(40).height(40)
      Text('加载训练数据...').fontSize(14).fontColor($r('app.color.text_secondary')).margin({ top: 16 })
    }.width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildEmpty() {
    Column() {
      Text('🏋️').fontSize(48)
      Text('暂无训练数据').fontSize(16).fontColor($r('app.color.text_secondary')).margin({ top: 12 })
      Text('请先同步训练数据到 training_data.json').fontSize(13).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
    }.width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildError() {
    Column() {
      Text('⚠️').fontSize(48)
      Text('加载失败').fontSize(16).fontColor($r('app.color.accent_red')).margin({ top: 12 })
      Text(viewModel.loadError).fontSize(13).fontColor($r('app.color.text_secondary')).margin({ top: 4 }).textAlign(TextAlign.Center).padding({ left: 32, right: 32 })
    }.width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildDashboard() {
    Scroll() {
      Column() {
        Column() {
          Row() {
            StatCard({ label: '总训练天数', value: '' + viewModel.dashboardStats.totalTrainingDays, unit: '天', icon: '📅' }).width('48%')
            StatCard({ label: '总训练次数', value: '' + viewModel.dashboardStats.totalSessions, unit: '次', icon: '💪' }).width('48%')
          }.width('100%').justifyContent(FlexAlign.SpaceBetween).margin({ bottom: 12 })
          Row() {
            StatCard({ label: '总组数', value: '' + viewModel.dashboardStats.totalSets, unit: '组', icon: '📊' }).width('48%')
            StatCard({ label: '总训练时长', value: '' + Math.round(viewModel.dashboardStats.totalDurationMinutes / 60) + 'h', unit: '', icon: '⏱️' }).width('48%')
          }.width('100%').justifyContent(FlexAlign.SpaceBetween)
        }.width('100%')

        Divider().height(0.5).color('rgba(255,255,255,0.06)').margin({ top: 16, bottom: 16 })

        Column() {
          Text('三大项 1RM').fontSize(16).fontColor(Color.White).fontWeight(FontWeight.Bold).width('100%').margin({ bottom: 12 })
          if (viewModel.dashboardStats.bigThreePRs.length === 0) {
            Text('暂无三大项训练数据').fontSize(13).fontColor($r('app.color.text_secondary')).width('100%').textAlign(TextAlign.Center).padding(16)
          } else {
            ForEach(viewModel.dashboardStats.bigThreePRs, (pr: ExercisePR) => {
              OneRmBar({ exerciseName: pr.exerciseName, oneRm: pr.estimatedOneRm, maxOneRm: this.getMaxRm(), barColor: getBigThreeColor(pr.exerciseName) })
            }, (pr: ExercisePR) => pr.exerciseName)
            ForEach(viewModel.dashboardStats.bigThreePRs, (pr: ExercisePR) => {
              Row() {
                Text(pr.date).fontSize(11).fontColor($r('app.color.text_secondary'))
                Text(pr.weight + 'kg × ' + pr.reps + '次').fontSize(11).fontColor($r('app.color.text_secondary'))
              }.width('100%').justifyContent(FlexAlign.SpaceBetween).padding({ left: 8, top: 2 })
            }, (pr: ExercisePR) => pr.exerciseName + '_d')
          }
        }.width('100%').padding(16).backgroundColor($r('app.color.card_background')).borderRadius(12).margin({ bottom: 16 })

        Row() {
          Text('🔥').fontSize(28)
          Column() {
            Text('' + viewModel.dashboardStats.streakDays).fontSize(36).fontColor($r('app.color.accent_orange')).fontWeight(FontWeight.Bold)
            Text('连续训练天数').fontSize(13).fontColor($r('app.color.text_secondary'))
          }.margin({ left: 16 }).alignItems(HorizontalAlign.Start)
        }.width('100%').padding(20).backgroundColor($r('app.color.card_background')).borderRadius(12).alignItems(VerticalAlign.Center).justifyContent(FlexAlign.Start)
      }.padding(16).width('100%')
    }.scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off)
  }
}

function getBigThreeColor(name: string): ResourceColor {
  if (name === '深蹲') return '#FF6C63FF';
  if (name === '杠铃卧推') return '#FF4CAF50';
  if (name === '硬拉') return '#FFFF9800';
  return $r('app.color.primary');
}
