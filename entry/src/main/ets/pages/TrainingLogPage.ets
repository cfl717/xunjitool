import { viewModel } from '../viewmodel/TrainingViewModel';
import { TrainingRecord } from '../models/TrainingRecord';
import { CalendarHeatmap } from '../components/CalendarHeatmap';
import { TrainingSessionCard } from '../components/TrainingSessionCard';
import { groupRecordsByDate } from '../services/StatisticsEngine';

@Component
export struct TrainingLogPage {
  @State year: number = new Date().getFullYear();
  @State month: number = new Date().getMonth() + 1;
  @State selectedDate: string = '';

  aboutToAppear(): void {
    if (this.selectedDate !== '') {
      return;
    }
    if (viewModel.allRecords.length > 0) {
      const sorted = viewModel.allRecords.slice().sort((a: TrainingRecord, b: TrainingRecord) => b.date.localeCompare(a.date));
      this.selectedDate = sorted[0].date;
      const parts = this.selectedDate.split('-');
      this.year = parseInt(parts[0]);
      this.month = parseInt(parts[1]);
    } else {
      const today = new Date();
      this.year = today.getFullYear();
      this.month = today.getMonth() + 1;
      this.selectedDate = this.formatDateStr(this.year, this.month, today.getDate());
    }
  }

  build() {
    Column() {
      Text('训练日志').fontSize(22).fontColor(Color.White).fontWeight(FontWeight.Bold)
        .width('100%').padding({ top: 16, bottom: 8, left: 20 })

      if (viewModel.allRecords.length === 0) {
        Column() {
          Text('暂无训练日志').fontSize(16).fontColor($r('app.color.text_secondary'))
          Text('同步或记录训练后即可按日历查看').fontSize(12).fontColor('rgba(255,255,255,0.35)').margin({ top: 8 })
        }.layoutWeight(1).justifyContent(FlexAlign.Center).width('100%')
      } else {
        Scroll() {
          Column() {
            Row() {
              Text('‹').fontSize(28).fontColor(Color.White)
                .width(44).height(44).textAlign(TextAlign.Center)
                .backgroundColor($r('app.color.card_background')).borderRadius(22)
                .onClick(() => { this.prevMonth(); })
              Column() {
                Text(this.year + '年' + this.month + '月').fontSize(17).fontColor(Color.White).fontWeight(FontWeight.Bold)
                Text('本月训练 ' + this.getMonthTrainingDays() + ' 天')
                  .fontSize(12).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
              }.layoutWeight(1).alignItems(HorizontalAlign.Center)
              Text('›').fontSize(28).fontColor(Color.White)
                .width(44).height(44).textAlign(TextAlign.Center)
                .backgroundColor($r('app.color.card_background')).borderRadius(22)
                .onClick(() => { this.nextMonth(); })
            }.width('100%').margin({ bottom: 12 }).alignItems(VerticalAlign.Center)

            CalendarHeatmap({
              year: this.year,
              month: this.month,
              trainingData: this.buildTrainingData(),
              selectedDate: this.selectedDate,
              onDaySelect: (date: string) => { this.selectedDate = date; }
            })

            Column() {
              Text(this.formatSelectedLabel()).fontSize(15).fontColor(Color.White).fontWeight(FontWeight.Medium)
                .width('100%').margin({ bottom: 8 })
              if (this.getSelectedRecords().length === 0) {
                Text('该日无训练记录').fontSize(14).fontColor($r('app.color.text_secondary'))
                  .width('100%').textAlign(TextAlign.Center).padding({ top: 16, bottom: 16 })
              } else {
                ForEach(this.getSelectedRecords(), (r: TrainingRecord) => {
                  TrainingSessionCard({ record: r })
                }, (r: TrainingRecord) => r.id)
              }
            }.width('100%').margin({ top: 16 })
          }.padding(16).width('100%')
        }.layoutWeight(1)
      }
    }.width('100%').height('100%').backgroundColor($r('app.color.background'))
  }

  buildTrainingData(): Record<string, number> {
    const data: Record<string, number> = {};
    for (const r of viewModel.allRecords) {
      data[r.date] = (data[r.date] || 0) + 1;
    }
    return data;
  }

  getSelectedRecords(): TrainingRecord[] {
    if (!this.selectedDate) {
      return [];
    }
    const grouped = groupRecordsByDate(viewModel.allRecords);
    const records = grouped.get(this.selectedDate);
    return records ? records : [];
  }

  getMonthTrainingDays(): number {
    const prefix = this.year + '-' + String(this.month).padStart(2, '0');
    const dates = new Set<string>();
    for (const r of viewModel.allRecords) {
      if (r.date.startsWith(prefix)) {
        dates.add(r.date);
      }
    }
    return dates.size;
  }

  formatSelectedLabel(): string {
    if (!this.selectedDate) {
      return '选择日期查看训练';
    }
    const count = this.getSelectedRecords().length;
    return this.selectedDate + ' · ' + count + ' 次训练';
  }

  formatDateStr(y: number, m: number, d: number): string {
    return y + '-' + String(m).padStart(2, '0') + '-' + String(d).padStart(2, '0');
  }

  prevMonth(): void {
    if (this.month === 1) {
      this.month = 12;
      this.year--;
    } else {
      this.month--;
    }
  }

  nextMonth(): void {
    if (this.month === 12) {
      this.month = 1;
      this.year++;
    } else {
      this.month++;
    }
  }
}
