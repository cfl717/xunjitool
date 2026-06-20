/**
 * 单组数据行组件
 * 展示一组训练的详情
 */

import { ExerciseSet } from '../models/TrainingRecord';

@Component
export struct ExerciseSetRow {
  private set: ExerciseSet = { setNumber: 0, weight: 0, reps: 0, durationSeconds: 0, rawWeight: '', rawReps: '' };
  private isBest: boolean = false;

  build() {
    Row() {
      // 组序号
      Text(`${this.set.setNumber}`)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .width(30)
        .textAlign(TextAlign.Center)

      // 重量
      Text(this.set.weight > 0 ? `${this.set.weight} kg` : '-')
        .fontSize(14)
        .fontColor(Color.White)
        .fontWeight(this.isBest ? FontWeight.Bold : FontWeight.Regular)
        .width(70)
        .textAlign(TextAlign.Center)

      // 次数
      Text(`${this.set.reps} 次`)
        .fontSize(14)
        .fontColor(Color.White)
        .fontWeight(this.isBest ? FontWeight.Bold : FontWeight.Regular)
        .width(70)
        .textAlign(TextAlign.Center)

      // 耗时
      Text(this.set.durationSeconds > 0 ? `${this.set.durationSeconds}s` : '-')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .layoutWeight(1)
        .textAlign(TextAlign.End)

      // PR标记
      if (this.isBest) {
        Text('PR')
          .fontSize(10)
          .fontColor($r('app.color.accent_orange'))
          .fontWeight(FontWeight.Bold)
          .padding({ left: 4, right: 4, top: 2, bottom: 2 })
          .backgroundColor('rgba(255,152,0,0.15)')
          .borderRadius(4)
          .margin({ left: 6 })
      }
    }
    .width('100%')
    .padding({ vertical: 6, horizontal: 8 })
    .alignItems(VerticalAlign.Center)
  }
}
