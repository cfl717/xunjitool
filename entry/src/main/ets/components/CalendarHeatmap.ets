/**
 * 日历热力图组件
 * 显示一个月的训练日分布，用颜色深浅表示训练强度
 */

@Component
export struct CalendarHeatmap {
  /** 年份 */
  private year: number = 2025;
  /** 月份 (1-12) */
  private month: number = 1;
  /** 训练数据: date → 训练次数 */
  private trainingData: Record<string, number> = {};

  build() {
    Column() {
      // 月份标题
      Text(`${this.year}年${this.month}月`)
        .fontSize(15)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 8 })

      // 星期表头
      Row() {
        ForEach(['一', '二', '三', '四', '五', '六', '日'], (day: string) => {
          Text(day)
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
            .width(this.getCellWidth())
            .textAlign(TextAlign.Center)
        }, (day: string) => day)
      }
      .width('100%')
      .margin({ bottom: 4 })

      // 日期网格
      Column() {
        ForEach(this.buildWeeks(), (week: (number | null)[]) => {
          Row() {
            ForEach(week, (day: number | null) => {
              if (day !== null) {
                const dateStr = this.formatDate(day);
                const count = this.trainingData[dateStr] || 0;
                Text(`${day}`)
                  .fontSize(12)
                  .fontColor(count > 0 ? Color.White : $r('app.color.text_secondary'))
                  .width(this.getCellWidth())
                  .height(this.getCellWidth())
                  .textAlign(TextAlign.Center)
                  .backgroundColor(this.getHeatColor(count))
                  .borderRadius(6)
              } else {
                // 空白占位
                Text('')
                  .width(this.getCellWidth())
                  .height(this.getCellWidth())
              }
            }, (day: number | null, index: number) => `${index}-${day}`)
          }
          .width('100%')
          .margin({ bottom: 4 })
          .alignItems(VerticalAlign.Center)
        }, (week: (number | null)[], index: number) => `week-${index}`)
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
  }

  getCellWidth(): string {
    return `${(100 - 6) / 7}%`
  }

  /** 构建周数组（按月） */
  buildWeeks(): (number | null)[][] {
    const firstDay = new Date(this.year, this.month - 1, 1);
    const lastDay = new Date(this.year, this.month, 0);
    const totalDays = lastDay.getDate();

    // 0=Sun, 1=Mon, ... 6=Sat → 我们需要周一=0
    let startDow = firstDay.getDay() - 1;
    if (startDow < 0) startDow = 6; // 周日变为6

    const weeks: (number | null)[][] = [];
    let currentWeek: (number | null)[] = [];

    // 填充月首空白
    for (let i = 0; i < startDow; i++) {
      currentWeek.push(null);
    }

    // 填充日期
    for (let day = 1; day <= totalDays; day++) {
      currentWeek.push(day);
      if (currentWeek.length === 7) {
        weeks.push(currentWeek);
        currentWeek = [];
      }
    }

    // 填充月末空白
    if (currentWeek.length > 0) {
      while (currentWeek.length < 7) {
        currentWeek.push(null);
      }
      weeks.push(currentWeek);
    }

    return weeks;
  }

  formatDate(day: number): string {
    const m = String(this.month).padStart(2, '0');
    const d = String(day).padStart(2, '0');
    return `${this.year}-${m}-${d}`;
  }

  getHeatColor(count: number): ResourceColor {
    if (count === 0) return 'rgba(255,255,255,0.04)';
    if (count === 1) return 'rgba(108,99,255,0.3)';
    if (count === 2) return 'rgba(108,99,255,0.5)';
    if (count === 3) return 'rgba(108,99,255,0.7)';
    return 'rgba(108,99,255,0.9)';
  }
}
