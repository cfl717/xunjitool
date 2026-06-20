@Component
export struct CalendarHeatmap {
  year: number = 2025;
  month: number = 1;
  trainingData: Record<string, number> = {};

  build() {
    Column() {
      Text(this.year + '年' + this.month + '月').fontSize(15).fontColor(Color.White).fontWeight(FontWeight.Medium).width('100%').margin({ bottom: 8 })
      Row() {
        ForEach(['一', '二', '三', '四', '五', '六', '日'], (day: string) => {
          Text(day).fontSize(11).fontColor($r('app.color.text_secondary')).width(this.getCellWidth()).textAlign(TextAlign.Center)
        }, (day: string) => day)
      }.width('100%').margin({ bottom: 4 })
      Column() {
        ForEach(this.buildWeeks(), (week: (number | null)[]) => {
          Row() {
            ForEach(week, (day: number | null) => {
              this.buildDayCell(day)
            }, (day: number | null, idx: number) => '' + idx + '-' + day)
          }.width('100%').margin({ bottom: 4 }).alignItems(VerticalAlign.Center)
        }, (week: (number | null)[], idx: number) => 'w' + idx)
      }
    }.width('100%').padding(12).backgroundColor($r('app.color.card_background')).borderRadius(12)
  }

  @Builder buildDayCell(day: number | null) {
    if (day !== null) {
      Text('' + day).fontSize(12)
        .fontColor((this.trainingData[this.formatDate(day)] || 0) > 0 ? Color.White : $r('app.color.text_secondary'))
        .width(this.getCellWidth()).height(this.getCellWidth())
        .textAlign(TextAlign.Center).backgroundColor(this.getHeatColor(this.trainingData[this.formatDate(day)] || 0)).borderRadius(6)
    } else {
      Text('').width(this.getCellWidth()).height(this.getCellWidth())
    }
  }

  getCellWidth(): string { return ((100 - 6) / 7) + '%'; }

  buildWeeks(): (number | null)[][] {
    const firstDay = new Date(this.year, this.month - 1, 1);
    const lastDay = new Date(this.year, this.month, 0);
    const totalDays = lastDay.getDate();
    let startDow = firstDay.getDay() - 1;
    if (startDow < 0) startDow = 6;
    const weeks: (number | null)[][] = [];
    let current: (number | null)[] = [];
    for (let i = 0; i < startDow; i++) current.push(null);
    for (let d = 1; d <= totalDays; d++) {
      current.push(d);
      if (current.length === 7) { weeks.push(current); current = []; }
    }
    if (current.length > 0) {
      while (current.length < 7) current.push(null);
      weeks.push(current);
    }
    return weeks;
  }

  formatDate(day: number): string {
    return this.year + '-' + String(this.month).padStart(2, '0') + '-' + String(day).padStart(2, '0');
  }

  getHeatColor(count: number): ResourceColor {
    if (count === 0) return 'rgba(255,255,255,0.04)';
    if (count === 1) return 'rgba(108,99,255,0.3)';
    if (count === 2) return 'rgba(108,99,255,0.5)';
    if (count === 3) return 'rgba(108,99,255,0.7)';
    return 'rgba(108,99,255,0.9)';
  }
}
