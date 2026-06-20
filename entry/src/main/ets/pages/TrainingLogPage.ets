/**
 * 训练日志页
 * 日历热力图 + 选中日期的训练详情列表
 */

import { viewModel, LoadState } from '../viewmodel/TrainingViewModel';
import { TrainingRecord } from '../models/TrainingRecord';
import { CalendarHeatmap } from '../components/CalendarHeatmap';
import { TrainingSessionCard } from '../components/TrainingSessionCard';
import { groupRecordsByDate } from '../services/StatisticsEngine';

@Component
export struct TrainingLogPage {
  @State loadState: LoadState = viewModel.loadState;
  @State selectedDate: string = '';
  @State todayRecords: TrainingRecord[] = [];
  @State currentMonth: number = new Date().getMonth() + 1;
  @State currentYear: number = new Date().getFullYear();

  // 日期 → 训练次数 映射
  @State dateTrainingCount: Record<string, number> = {};

  aboutToAppear(): void {
    this.loadState = viewModel.loadState;
    this.rebuildDateMap();
    this.selectToday();
  }

  rebuildDateMap(): void {
    const map: Record<string, number> = {};
    for (const r of viewModel.allRecords) {
      map[r.date] = (map[r.date] || 0) + 1;
    }
    this.dateTrainingCount = map;
  }

  selectToday(): void {
    const now = new Date();
    const today = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
    this.selectDate(today);
  }

  selectDate(dateStr: string): void {
    this.selectedDate = dateStr;
    this.todayRecords = viewModel.allRecords.filter(r => r.date === dateStr);
  }

  build() {
    Column() {
      // 页面标题
      Text('训练日志')
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
            // 日历热力图
            CalendarHeatmap({
              year: this.currentYear,
              month: this.currentMonth,
              trainingData: this.dateTrainingCount
            })

            // 月份切换
            Row() {
              Text('◀')
                .fontSize(16)
                .fontColor($r('app.color.primary'))
                .onClick(() => this.changeMonth(-1))

              Text(`${this.currentYear}年${this.currentMonth}月`)
                .fontSize(14)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .textAlign(TextAlign.Center)

              Text('▶')
                .fontSize(16)
                .fontColor($r('app.color.primary'))
                .onClick(() => this.changeMonth(1))
            }
            .width('100%')
            .padding({ vertical: 12 })
            .alignItems(VerticalAlign.Center)

            // 选中日期
            if (this.selectedDate) {
              Row() {
                Text(this.formatDateDisplay(this.selectedDate))
                  .fontSize(15)
                  .fontColor(Color.White)
                  .fontWeight(FontWeight.Medium)

                Text(`${this.todayRecords.length} 条记录`)
                  .fontSize(12)
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ left: 8 })
              }
              .width('100%')
              .margin({ bottom: 8 })
            }

            // 当天的训练记录列表
            if (this.todayRecords.length > 0) {
              ForEach(this.todayRecords, (record: TrainingRecord) => {
                TrainingSessionCard({ record: record, expanded: false })
              }, (record: TrainingRecord) => record.id)
            } else if (this.selectedDate) {
              Text('该日无训练记录')
                .fontSize(13)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding(20)
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

  changeMonth(delta: number): void {
    this.currentMonth += delta;
    if (this.currentMonth > 12) {
      this.currentMonth = 1;
      this.currentYear++;
    } else if (this.currentMonth < 1) {
      this.currentMonth = 12;
      this.currentYear--;
    }
  }

  formatDateDisplay(dateStr: string): string {
    const parts = dateStr.split('-');
    return `${parts[0]}年${parts[1]}月${parts[2]}日`;
  }

  @Builder
  buildLoading() {
    Column() {
      LoadingProgress()
        .color($r('app.color.primary'))
        .width(40).height(40)
      Text('加载中...')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 12 })
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildEmpty() {
    Column() {
      Text('📋')
        .fontSize(48)
      Text('暂无训练日志')
        .fontSize(16)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 12 })
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }
}
