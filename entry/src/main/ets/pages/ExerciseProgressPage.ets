/**
 * 动作进展页
 * 动作选择 + Canvas 折线图展示重量/1RM趋势
 */

import { viewModel, LoadState } from '../viewmodel/TrainingViewModel';
import { ProgressChart } from '../components/ProgressChart';
import { estimateOneRm } from '../utils/EpleyFormula';

@Component
export struct ExerciseProgressPage {
  @State loadState: LoadState = viewModel.loadState;
  @State selectedExercise: string = '';
  @State exerciseNames: string[] = [];
  @State chartTypeIndex: number = 0; // 0: 1RM, 1: 最大重量, 2: 训练量

  private chartTypes: string[] = ['1RM趋势', '最大重量', '训练量'];

  aboutToAppear(): void {
    this.loadState = viewModel.loadState;
    this.exerciseNames = viewModel.exerciseNames;
    if (this.exerciseNames.length > 0 && !this.selectedExercise) {
      this.selectedExercise = this.exerciseNames[0];
    }
  }

  build() {
    Column() {
      // 页面标题
      Text('动作进展')
        .fontSize(22)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ top: 16, bottom: 8, left: 20 })

      if (this.loadState === LoadState.LOADING) {
        this.buildLoading()
      } else if (this.loadState === LoadState.EMPTY) {
        this.buildEmpty()
      } else {
        Scroll() {
          Column() {
            // 动作选择器
            this.buildExercisePicker()

            // 图表类型切换
            this.buildChartTypeSelector()

            // 进展图表
            if (this.selectedExercise) {
              ProgressChart({
                dataPoints: this.getChartData(),
                title: `${this.selectedExercise} - ${this.chartTypes[this.chartTypeIndex]}`,
                unit: 'kg',
                lineColor: $r('app.color.primary')
              })
            }

            // 统计汇总
            if (this.selectedExercise) {
              this.buildExerciseStats()
            }
          }
          .padding(16)
          .width('100%')
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildExercisePicker() {
    Column() {
      Text('选择动作')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ bottom: 8 })

      // 使用 Scroll + Row 实现水平滚动选择
      Scroll() {
        Row() {
          ForEach(this.exerciseNames, (name: string) => {
            Text(name)
              .fontSize(13)
              .fontColor(name === this.selectedExercise ? Color.White : $r('app.color.text_secondary'))
              .fontWeight(name === this.selectedExercise ? FontWeight.Medium : FontWeight.Regular)
              .padding({ left: 14, right: 14, top: 8, bottom: 8 })
              .backgroundColor(name === this.selectedExercise
                ? $r('app.color.primary')
                : $r('app.color.card_background'))
              .borderRadius(20)
              .margin({ right: 8 })
              .onClick(() => {
                this.selectedExercise = name;
              })
          }, (name: string) => name)
        }
        .padding({ horizontal: 4 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .height(40)
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  @Builder
  buildChartTypeSelector() {
    Row() {
      ForEach(this.chartTypes, (type: string, index: number) => {
        Text(type)
          .fontSize(12)
          .fontColor(index === this.chartTypeIndex ? Color.White : $r('app.color.text_secondary'))
          .fontWeight(index === this.chartTypeIndex ? FontWeight.Medium : FontWeight.Regular)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(index === this.chartTypeIndex
            ? 'rgba(108,99,255,0.3)'
            : 'transparent')
          .borderRadius(16)
          .border({
            width: 1,
            color: index === this.chartTypeIndex
              ? $r('app.color.primary')
              : 'rgba(255,255,255,0.1)'
          })
          .margin({ right: 8 })
          .onClick(() => {
            this.chartTypeIndex = index;
          })
      }, (type: string, idx: number) => `${idx}`)
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  @Builder
  buildExerciseStats() {
    const history = viewModel.getExerciseHistory(this.selectedExercise);
    if (history.length === 0) return;

    const maxWeight = Math.max(...history.map(h => h.maxWeight));
    const maxRm = Math.max(...history.map(h => h.maxOneRm));
    const totalVolume = history.reduce((sum, h) => sum + h.totalVolume, 0);
    const sessionCount = history.length;

    Column() {
      Text('统计汇总')
        .fontSize(14)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 10 })

      Row() {
        StatItem('训练次数', `${sessionCount}`, '次')
        StatItem('最大重量', `${maxWeight}`, 'kg')
        StatItem('最高1RM', `${maxRm}`, 'kg')
        StatItem('总训练量', `${totalVolume >= 1000 ? (totalVolume / 1000).toFixed(1) : totalVolume}`, totalVolume >= 1000 ? '吨' : 'kg')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .margin({ top: 12 })
  }

  /** 获取图表数据 */
  getChartData(): { date: string; value: number }[] {
    const history = viewModel.getExerciseHistory(this.selectedExercise);
    if (history.length === 0) return [];

    switch (this.chartTypeIndex) {
      case 0: // 1RM趋势
        return history.map(h => ({ date: h.date, value: h.maxOneRm }));
      case 1: // 最大重量
        return history.map(h => ({ date: h.date, value: h.maxWeight }));
      case 2: // 训练量
        return history.map(h => ({ date: h.date, value: Math.round(h.totalVolume / 100) }));
      default:
        return [];
    }
  }

  @Builder
  buildLoading() {
    Column() {
      LoadingProgress().color($r('app.color.primary')).width(40).height(40)
      Text('加载中...').fontSize(14).fontColor($r('app.color.text_secondary')).margin({ top: 12 })
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildEmpty() {
    Column() {
      Text('📈').fontSize(48)
      Text('暂无训练数据').fontSize(16).fontColor($r('app.color.text_secondary')).margin({ top: 12 })
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }
}

@Component
struct StatItem {
  private label: string = '';
  private value: string = '';
  private unit: string = '';

  build() {
    Column() {
      Text(this.value)
        .fontSize(20)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)

      Text(this.unit)
        .fontSize(11)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 2 })

      Text(this.label)
        .fontSize(11)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Center)
  }
}
