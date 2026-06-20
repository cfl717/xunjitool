/**
 * 统计卡片组件
 * 用于仪表盘展示各类统计数据
 */

@Component
export struct StatCard {
  private label: string = '';
  private value: string = '';
  private unit: string = '';
  private icon: string = '';
  private accentColor: ResourceColor = $r('app.color.primary');

  build() {
    Column() {
      // 图标
      if (this.icon) {
        Text(this.icon)
          .fontSize(24)
          .margin({ bottom: 4 })
      }

      // 数值
      Text(this.value)
        .fontSize(28)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)

      // 单位
      if (this.unit) {
        Text(this.unit)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 2 })
      }

      // 标签
      Text(this.label)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 6 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
