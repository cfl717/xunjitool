/**
 * 训练会话卡片组件
 * 展示一次完整训练课的信息
 */

import { TrainingRecord, TrainingType } from '../models/TrainingRecord';
import { ExerciseCard } from './ExerciseCard';
import { formatDuration } from '../utils/DateUtils';

@Component
export struct TrainingSessionCard {
  private record: TrainingRecord = {
    date: '', rawDate: '', id: '', name: '',
    startTime: 0, endTime: 0, durationMinutes: 0,
    type: TrainingType.STRENGTH, exercises: [], notes: '', raw: ''
  };
  private expanded: boolean = false;

  build() {
    Column() {
      // 训练概要（可点击展开）
      Row() {
        // 训练名
        Column() {
          Text(this.record.name)
            .fontSize(15)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Row() {
            // 类型标签
            Text(this.getTypeLabel())
              .fontSize(10)
              .fontColor(this.getTypeColor())
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .backgroundColor(this.getTypeBgColor())
              .borderRadius(4)

            // 时长
            Text(formatDuration(this.record.durationMinutes))
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .margin({ left: 8 })

            // 动作数
            if (this.record.exercises && this.record.exercises.length > 0) {
              Text(`${this.record.exercises.length}个动作`)
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .margin({ left: 8 })
            }
          }
          .margin({ top: 4 })
          .alignItems(VerticalAlign.Center)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 展开箭头
        Text(this.expanded ? '▲' : '▼')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .margin({ left: 8 })
      }
      .width('100%')
      .padding(12)
      .onClick(() => {
        this.expanded = !this.expanded;
      })

      // 展开详情
      if (this.expanded) {
        Divider()
          .height(0.5)
          .color('rgba(255,255,255,0.08)')
          .margin({ horizontal: 12 })

        // 动作列表
        if (this.record.exercises && this.record.exercises.length > 0) {
          ForEach(this.record.exercises, (exercise: Exercise) => {
            ExerciseCard({ exercise: exercise })
          }, (exercise: Exercise) => `${exercise.number}`)
        }

        // 有氧/健康信息
        if (this.record.type === TrainingType.CARDIO || this.record.type === TrainingType.APPLE_HEALTH) {
          Column() {
            if (this.record.distance) {
              DetailRow('距离', `${this.record.distance >= 1000
                ? (this.record.distance / 1000).toFixed(2)
                : this.record.distance} ${this.record.distance >= 1000 ? 'km' : 'm'}`)
            }
            if (this.record.calories) {
              DetailRow('热量', `${this.record.calories} kcal`)
            }
            if (this.record.avgHeartRate) {
              DetailRow('心率', `${this.record.avgHeartRate} bpm`)
            }
          }
          .padding(12)
        }
      }
    }
    .width('100%')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .margin({ bottom: 8 })
  }

  getTypeLabel(): string {
    switch (this.record.type) {
      case TrainingType.STRENGTH: return '力量'
      case TrainingType.CARDIO: return '有氧'
      case TrainingType.APPLE_HEALTH: return '健康'
      case TrainingType.MINIMAL: return '记录'
      default: return ''
    }
  }

  getTypeColor(): ResourceColor {
    switch (this.record.type) {
      case TrainingType.STRENGTH: return $r('app.color.primary')
      case TrainingType.CARDIO: return $r('app.color.accent_green')
      case TrainingType.APPLE_HEALTH: return $r('app.color.accent_orange')
      default: return $r('app.color.text_secondary')
    }
  }

  getTypeBgColor(): ResourceColor {
    switch (this.record.type) {
      case TrainingType.STRENGTH: return 'rgba(108,99,255,0.15)'
      case TrainingType.CARDIO: return 'rgba(76,175,80,0.15)'
      case TrainingType.APPLE_HEALTH: return 'rgba(255,152,0,0.15)'
      default: return 'rgba(176,176,195,0.15)'
    }
  }
}

@Component
struct DetailRow {
  private label: string = '';
  private value: string = '';

  build() {
    Row() {
      Text(this.label)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))

      Text(this.value)
        .fontSize(14)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .padding({ vertical: 4 })
    .justifyContent(FlexAlign.SpaceBetween)
  }
}
