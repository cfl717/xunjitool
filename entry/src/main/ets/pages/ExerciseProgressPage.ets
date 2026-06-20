import { viewModel, LoadState } from '../viewmodel/TrainingViewModel';
import { ProgressChart } from '../components/ProgressChart';

interface ChartPoint { date: string; value: number; }
interface HistoryStats { count: number; maxWeight: number; maxOneRm: number; totalVolume: number; }

@Component
export struct ExerciseProgressPage {
  @State selectedExercise: string = '';
  @State exerciseNames: string[] = [];
  @State chartTypeIndex: number = 0;
  @State historyStats: HistoryStats | null = null;
  private chartTypes: string[] = ['1RM趋势', '最大重量', '训练量'];

  aboutToAppear(): void {
    this.exerciseNames = viewModel.exerciseNames;
    if (this.exerciseNames.length > 0 && !this.selectedExercise) { this.selectedExercise = this.exerciseNames[0]; }
    this.updateStats();
  }

  updateStats(): void {
    this.historyStats = this.getHistoryStats();
  }

  build() {
    Column() {
      Text('动作进展').fontSize(22).fontColor(Color.White).fontWeight(FontWeight.Bold).width('100%').padding({ top: 16, bottom: 8, left: 20 })
      if (viewModel.loadState === LoadState.LOADING) { this.buildLoading(); }
      else if (viewModel.loadState === LoadState.EMPTY) { this.buildEmpty(); }
      else { this.buildContent(); }
    }.width('100%').height('100%').backgroundColor($r('app.color.background'))
  }

  @Builder buildLoading() {
    Column() { LoadingProgress().color($r('app.color.primary')).width(40).height(40); Text('加载中...').fontSize(14).fontColor($r('app.color.text_secondary')).margin({ top: 12 }) }.width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }

  @Builder buildEmpty() {
    Column() { Text('📈').fontSize(48); Text('暂无训练数据').fontSize(16).fontColor($r('app.color.text_secondary')).margin({ top: 12 }) }.width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }

  @Builder buildContent() {
    Scroll() {
      Column() {
        Column() {
          Text('选择动作').fontSize(13).fontColor($r('app.color.text_secondary')).width('100%').margin({ bottom: 8 })
          Scroll() {
            Row() {
              ForEach(this.exerciseNames, (n: string) => {
                Text(n).fontSize(13).fontColor(n === this.selectedExercise ? Color.White : $r('app.color.text_secondary'))
                  .fontWeight(n === this.selectedExercise ? FontWeight.Medium : FontWeight.Regular)
                  .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                  .backgroundColor(n === this.selectedExercise ? $r('app.color.primary') : $r('app.color.card_background'))
                  .borderRadius(20).margin({ right: 8 }).onClick(() => { this.selectedExercise = n; this.updateStats(); })
              }, (n: string) => n)
            }.padding({ left: 4, right: 4 })
          }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).height(40)
        }.width('100%').margin({ bottom: 16 })

        Row() {
          ForEach(this.chartTypes, (t: string, i: number) => {
            Text(t).fontSize(12).fontColor(i === this.chartTypeIndex ? Color.White : $r('app.color.text_secondary'))
              .fontWeight(i === this.chartTypeIndex ? FontWeight.Medium : FontWeight.Regular)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .backgroundColor(i === this.chartTypeIndex ? 'rgba(108,99,255,0.3)' : 'transparent')
              .borderRadius(16).border({ width: 1, color: i === this.chartTypeIndex ? $r('app.color.primary') : 'rgba(255,255,255,0.1)' })
              .margin({ right: 8 }).onClick(() => { this.chartTypeIndex = i; })
          }, (t: string, i: number) => '' + i)
        }.width('100%').margin({ bottom: 16 })

        if (this.selectedExercise) {
          ProgressChart({ dataPoints: this.getChartData(), title: this.selectedExercise + ' - ' + this.chartTypes[this.chartTypeIndex], unit: 'kg' })
        }
        if (this.selectedExercise && this.historyStats) { this.buildStats(this.historyStats); }
      }.padding(16).width('100%')
    }.scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off)
  }

  getChartData(): ChartPoint[] {
    const h = viewModel.getExerciseHistory(this.selectedExercise);
    if (h.length === 0) return [];
    if (this.chartTypeIndex === 0) return h.map((x): ChartPoint => ({ date: x.date, value: x.maxOneRm }));
    if (this.chartTypeIndex === 1) return h.map((x): ChartPoint => ({ date: x.date, value: x.maxWeight }));
    return h.map((x): ChartPoint => ({ date: x.date, value: Math.round(x.totalVolume / 100) }));
  }

  getHistoryStats(): HistoryStats | null {
    const h = viewModel.getExerciseHistory(this.selectedExercise);
    if (h.length === 0) return null;
    let mw = 0, mr = 0, tv = 0;
    for (const x of h) { if (x.maxWeight > mw) mw = x.maxWeight; if (x.maxOneRm > mr) mr = x.maxOneRm; tv += x.totalVolume; }
    return { count: h.length, maxWeight: mw, maxOneRm: mr, totalVolume: tv };
  }

  @Builder buildStats(s: HistoryStats) {
    Column() {
      Text('统计汇总').fontSize(14).fontColor(Color.White).fontWeight(FontWeight.Medium).width('100%').margin({ bottom: 10 })
      Row() {
        Column() { Text('' + s.count).fontSize(20).fontColor(Color.White).fontWeight(FontWeight.Bold); Text('次').fontSize(11).fontColor($r('app.color.text_secondary')).margin({ top: 2 }); Text('训练次数').fontSize(11).fontColor($r('app.color.text_secondary')).margin({ top: 4 }) }.alignItems(HorizontalAlign.Center)
        Column() { Text('' + s.maxWeight).fontSize(20).fontColor(Color.White).fontWeight(FontWeight.Bold); Text('kg').fontSize(11).fontColor($r('app.color.text_secondary')).margin({ top: 2 }); Text('最大重量').fontSize(11).fontColor($r('app.color.text_secondary')).margin({ top: 4 }) }.alignItems(HorizontalAlign.Center)
        Column() { Text('' + s.maxOneRm).fontSize(20).fontColor(Color.White).fontWeight(FontWeight.Bold); Text('kg').fontSize(11).fontColor($r('app.color.text_secondary')).margin({ top: 2 }); Text('最高1RM').fontSize(11).fontColor($r('app.color.text_secondary')).margin({ top: 4 }) }.alignItems(HorizontalAlign.Center)
        Column() { Text(s.totalVolume >= 1000 ? (s.totalVolume / 1000).toFixed(1) : '' + s.totalVolume).fontSize(20).fontColor(Color.White).fontWeight(FontWeight.Bold); Text(s.totalVolume >= 1000 ? '吨' : 'kg').fontSize(11).fontColor($r('app.color.text_secondary')).margin({ top: 2 }); Text('总训练量').fontSize(11).fontColor($r('app.color.text_secondary')).margin({ top: 4 }) }.alignItems(HorizontalAlign.Center)
      }.width('100%').justifyContent(FlexAlign.SpaceBetween)
    }.width('100%').padding(12).backgroundColor($r('app.color.card_background')).borderRadius(12).margin({ top: 12 })
  }
}
