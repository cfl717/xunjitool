/**
 * 1RM 横向柱状条组件
 * 用于展示三大项或所有动作的1RM对比
 */

@Component
export struct OneRmBar {
  private exerciseName: string = '';
  private oneRm: number = 0;
  private maxOneRm: number = 0;
  private barColor: ResourceColor = $r('app.color.primary');

  build() {
    Row() {
      // 动作名
      Text(this.exerciseName)
        .fontSize(14)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Medium)
        .width('25%')

      // 柱状条背景
      Stack() {
        // 背景条
        Row()
          .width('100%')
          .height(20)
          .backgroundColor('rgba(255,255,255,0.08)')
          .borderRadius(10)

        // 填充条
        Row()
          .width(this.maxOneRm > 0 ? `${(this.oneRm / this.maxOneRm) * 100}%` : '0%')
          .height(20)
          .backgroundColor(this.barColor)
          .borderRadius(10)
          .animation({ duration: 800, curve: Curve.FastOutSlowIn })
      }
      .layoutWeight(1)
      .height(20)

      // 1RM数值
      Text(`${this.oneRm} kg`)
        .fontSize(14)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .width('22%')
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .padding({ vertical: 6, horizontal: 4 })
    .alignItems(VerticalAlign.Center)
  }
}
