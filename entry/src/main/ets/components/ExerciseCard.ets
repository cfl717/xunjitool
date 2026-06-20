/**
 * 单个动作卡片组件
 * 展示一个动作的所有组
 */

import { Exercise } from '../models/TrainingRecord';
import { ExerciseSetRow } from './ExerciseSetRow';
import { estimateOneRm } from '../utils/EpleyFormula';

@Component
export struct ExerciseCard {
  private exercise: Exercise = { number: 0, name: '', sets: [], totalSets: 0 };

  build() {
    Column() {
      // 动作名称栏
      Row() {
        Text(`${this.exercise.number}. ${this.exercise.name}`)
          .fontSize(15)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)

        Text(`${this.exercise.totalSets}组`)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .margin({ left: 8 })
      }
      .width('100%')
      .padding({ bottom: 8 })
      .alignItems(VerticalAlign.Center)

      // 表头
      Row() {
        Text('#').width(30).textAlign(TextAlign.Center)
        Text('重量').width(70).textAlign(TextAlign.Center)
        Text('次数').width(70).textAlign(TextAlign.Center)
        Text('耗时').layoutWeight(1).textAlign(TextAlign.End)
        Text('').width(50)
      }
      .fontSize(11)
      .fontColor($r('app.color.text_secondary'))
      .padding({ vertical: 4, horizontal: 8 })

      // 组列表
      ForEach(this.exercise.sets, (set: ExerciseSet, index: number) => {
        ExerciseSetRow({
          set: set,
          isBest: isBestSet(set, this.exercise.sets)
        })
        Divider()
          .height(0.5)
          .color('rgba(255,255,255,0.06)')
      }, (set: ExerciseSet) => `${set.setNumber}`)
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(10)
    .margin({ bottom: 8 })
  }
}

/** 判断一组是否为该动作的最佳组（最高1RM估算） */
function isBestSet(set: ExerciseSet, allSets: ExerciseSet[]): boolean {
  if (set.weight <= 0 || set.reps <= 0) return false;
  const thisRm = estimateOneRm(set.weight, set.reps);
  for (const s of allSets) {
    if (s.weight > 0 && s.reps > 0) {
      if (estimateOneRm(s.weight, s.reps) > thisRm) {
        return false;
      }
    }
  }
  return true;
}
