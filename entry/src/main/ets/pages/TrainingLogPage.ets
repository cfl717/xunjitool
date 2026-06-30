import { viewModel } from '../viewmodel/TrainingViewModel';
import { TrainingRecord } from '../models/TrainingRecord';
import { CalendarHeatmap } from '../components/CalendarHeatmap';
import { TrainingSessionCard } from '../components/TrainingSessionCard';

@Component
export struct TrainingLogPage {
  @State year: number = new Date().getFullYear();
  @State month: number = new Date().getMonth() + 1;
  @State selectedDate: string = '';

  aboutToAppear(): void {
    if (viewModel.allRecords.length > 0) {
      const sorted = viewModel.allRecords.slice().sort((a: TrainingRecord, b: TrainingRecord) => b.date.localeCompare(a.date));
      this.selectedDate = sorted[0].date;
      const parts = this.selectedDate.split('-');
      this.year = parseInt(parts[0]);
      this.month = parseInt(parts[1]);
    }
  }

  buildDateCount(): Record<string, number> {
    const m: Record<string, number> = {};
    for (const r of viewModel.allRecords) m[r.date] = (m[r.date] || 0) + 1;
    return m;
  }

  getSelectedRecords(): TrainingRecord[] {
    if (!this.selectedDate) return [];
    const result: TrainingRecord[] = [];
    for (const r of viewModel.allRecords) {
      if (r.date === this.selectedDate) result.push(r);
    }
    return result;
  }

  prevMonth(): void {
    if (this.month === 1) { this.month = 12; this.year--; }
    else { this.month--; }
  }

  nextMonth(): void {
    if (this.month === 12) { this.month = 1; this.year++; }
    else { this.month++; }
  }

  build() {
    Column() {
      Text('训练日志').fontSize(22).fontColor(Color.White).fontWeight(FontWeight.Bold)
        .width('100%').padding({ top: 16, bottom: 8, left: 20 })

      if (viewModel.allRecords.length === 0) {
        Text('暂无训练').fontSize(16).fontColor($r('app.color.text_secondary'))
          .width('100%').textAlign(TextAlign.Center).padding({ top: 40 })
      } else {
        Scroll() {
          Column() {
            Row() {
              Text('‹').fontSize(28).fontColor(Color.White).width(44).height(44).textAlign(TextAlign.Center)
                .backgroundColor($r('app.color.card_background')).borderRadius(22)
                .onClick(() => { this.prevMonth(); })
              Text(this.year + '年' + this.month + '月').fontSize(16).fontColor(Color.White).fontWeight(FontWeight.Bold)
                .layoutWeight(1).textAlign(TextAlign.Center)
              Text('›').fontSize(28).fontColor(Color.White).width(44).height(44).textAlign(TextAlign.Center)
                .backgroundColor($r('app.color.card_background')).borderRadius(22)
                .onClick(() => { this.nextMonth(); })
            }.width('100%').margin({ bottom: 12 }).alignItems(VerticalAlign.Center)

            CalendarHeatmap({
              year: this.year,
              month: this.month,
              trainingData: this.buildDateCount(),
              selectedDate: this.selectedDate,
              onDaySelect: (date: string) => { this.selectedDate = date; }
            })

            if (this.selectedDate) {
              Row() {
                Text(this.selectedDate).fontSize(15).fontColor(Color.White).fontWeight(FontWeight.Medium)
                Text(this.getSelectedRecords().length + ' 次训练').fontSize(12).fontColor($r('app.color.text_secondary')).margin({ left: 8 })
              }.width('100%').margin({ top: 16, bottom: 8 })

              if (this.getSelectedRecords().length > 0) {
                ForEach(this.getSelectedRecords(), (r: TrainingRecord) => {
                  TrainingSessionCard({ record: r })
                }, (r: TrainingRecord) => r.id)
              }
            }
          }.padding(16).width('100%')
        }.layoutWeight(1)
      }
    }.width('100%').height('100%').backgroundColor($r('app.color.background'))
  }
}
