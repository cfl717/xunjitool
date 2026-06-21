import { viewModel } from '../viewmodel/TrainingViewModel';
import { ProgressChart } from '../components/ProgressChart';

interface DP { date: string; value: number; }

@Component
export struct ExerciseProgressPage {
  @State idx: number = 0;
  @State ct: number = 0;
  private types: string[] = ['1RM', '重量', '容量'];

  getData(): DP[] {
    const name = viewModel.exerciseNames.length > this.idx ? viewModel.exerciseNames[this.idx] : '';
    if (!name) return [];
    const h = viewModel.getExerciseHistory(name);
    const r: DP[] = [];
    for (const x of h) {
      if (this.ct === 0) r.push({ date: x.date, value: x.maxOneRm });
      else if (this.ct === 1) r.push({ date: x.date, value: x.maxWeight });
      else r.push({ date: x.date, value: Math.round(x.totalVolume) });
    }
    return r;
  }

  getMax(): number {
    let m = 0;
    for (const d of this.getData()) if (d.value > m) m = d.value;
    return m || 1;
  }

  build() {
    Column() {
      Text('动作进展').fontSize(22).fontColor(Color.White).fontWeight(FontWeight.Bold)
        .width('100%').padding({ top: 16, bottom: 8, left: 16, right: 16 })

      if (viewModel.exerciseNames.length === 0) {
        Column() {
          Text('暂无动作数据').fontSize(16).fontColor($r('app.color.text_secondary'))
          Text('同步或记录训练后即可查看趋势').fontSize(12).fontColor('rgba(255,255,255,0.35)').margin({ top: 8 })
        }.layoutWeight(1).justifyContent(FlexAlign.Center).width('100%')
      } else {
        Scroll() {
          Column() {
            Row() {
              Text('‹').fontSize(28).fontColor(this.idx > 0 ? Color.White : 'rgba(255,255,255,0.25)')
                .width(44).height(44).textAlign(TextAlign.Center).backgroundColor($r('app.color.card_background')).borderRadius(22)
                .onClick(() => { if (this.idx > 0) this.idx--; })
              Column() {
                Text(viewModel.exerciseNames.length > this.idx ? viewModel.exerciseNames[this.idx] : '无')
                  .fontSize(17).fontColor(Color.White).fontWeight(FontWeight.Bold).maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis }).textAlign(TextAlign.Center)
                Text((this.idx + 1) + ' / ' + viewModel.exerciseNames.length)
                  .fontSize(11).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
              }.layoutWeight(1).alignItems(HorizontalAlign.Center)
              Text('›').fontSize(28).fontColor(this.idx < viewModel.exerciseNames.length - 1 ? Color.White : 'rgba(255,255,255,0.25)')
                .width(44).height(44).textAlign(TextAlign.Center).backgroundColor($r('app.color.card_background')).borderRadius(22)
                .onClick(() => { if (this.idx < viewModel.exerciseNames.length - 1) this.idx++; })
            }.width('100%').alignItems(VerticalAlign.Center).margin({ bottom: 14 })

            Row() {
              ForEach(this.types, (t: string, i: number) => {
                Text(t).fontSize(13).fontColor(this.ct === i ? Color.White : $r('app.color.text_secondary'))
                  .fontWeight(this.ct === i ? FontWeight.Bold : FontWeight.Regular)
                  .backgroundColor(this.ct === i ? $r('app.color.primary') : $r('app.color.card_background'))
                  .borderRadius(16).padding({ left: 16, right: 16, top: 8, bottom: 8 }).margin({ right: 8 })
                  .onClick(() => { this.ct = i; })
              }, (t: string, i: number) => 't' + i)
            }.width('100%').margin({ bottom: 14 })

            ProgressChart({
              dataPoints: this.getData(),
              title: this.getChartTitle(),
              unit: this.getUnit(),
              accentColor: this.getAccentColor()
            }).margin({ bottom: 12 })

            Row() {
              this.summaryCard('最佳', this.formatValue(this.getBestValue()), $r('app.color.accent_green'))
              this.summaryCard('平均', this.formatValue(this.getAverageValue()), $r('app.color.primary'))
              this.summaryCard('记录', this.getData().length + ' 次', $r('app.color.accent_orange'))
            }.width('100%').margin({ bottom: 12 })

            Column() {
              Text('最近记录').fontSize(15).fontColor(Color.White).fontWeight(FontWeight.Medium)
                .width('100%').margin({ bottom: 8 })
              ForEach(this.getRecentData(), (d: DP) => {
                Row() {
                  Text(d.date.slice(5)).fontSize(12).fontColor($r('app.color.text_secondary')).width(54)
                  Stack({ alignContent: Alignment.Start }) {
                    Row().width('100%').height(10).backgroundColor('rgba(255,255,255,0.07)').borderRadius(5)
                    Row().width(this.getBarWidth(d.value)).height(10).backgroundColor(this.getAccentColor()).borderRadius(5)
                  }.layoutWeight(1).height(10)
                  Text(this.formatValue(d.value)).fontSize(12).fontColor(Color.White).fontWeight(FontWeight.Medium)
                    .width(72).textAlign(TextAlign.End).margin({ left: 8 })
                }.width('100%').padding({ top: 7, bottom: 7 })
              }, (d: DP, i: number) => d.date + i)
            }.width('100%').padding(12).backgroundColor($r('app.color.card_background')).borderRadius(12)
          }.padding({ left: 16, right: 16, bottom: 24 })
        }.layoutWeight(1)
      }
    }.width('100%').height('100%').backgroundColor($r('app.color.background'))
  }

  @Builder summaryCard(label: string, value: string, color: ResourceColor) {
    Column() {
      Text(value).fontSize(16).fontColor(Color.White).fontWeight(FontWeight.Bold).maxLines(1)
      Text(label).fontSize(11).fontColor(color).margin({ top: 4 })
    }.layoutWeight(1).padding(12).alignItems(HorizontalAlign.Center)
      .backgroundColor($r('app.color.card_background')).borderRadius(12).margin({ right: 8 })
  }

  private getRecentData(): DP[] {
    const data = this.getData();
    if (data.length <= 6) return data;
    return data.slice(data.length - 6);
  }

  private getChartTitle(): string {
    return this.types[this.ct] + '趋势';
  }

  private getUnit(): string {
    return 'kg';
  }

  private getAccentColor(): string {
    if (this.ct === 1) return '#4CAF50';
    if (this.ct === 2) return '#FF9800';
    return '#6C63FF';
  }

  private getBestValue(): number {
    let best = 0;
    for (const d of this.getData()) if (d.value > best) best = d.value;
    return best;
  }

  private getAverageValue(): number {
    const data = this.getData();
    if (data.length === 0) return 0;
    let total = 0;
    for (const d of data) total += d.value;
    return Math.round(total / data.length);
  }

  private getBarWidth(value: number): string {
    const max = this.getMax();
    if (max <= 0 || value <= 0) return '0%';
    return Math.max(4, Math.min(100, value / max * 100)) + '%';
  }

  private formatValue(value: number): string {
    if (value >= 1000) return Math.round(value / 100) / 10 + 'k kg';
    return Math.round(value) + ' kg';
  }
}
