/**
 * 主页 — Tab 导航
 * 初始化VM后显示4个Tab页
 */

import { DashboardPage } from './DashboardPage';
import { TrainingLogPage } from './TrainingLogPage';
import { ExerciseProgressPage } from './ExerciseProgressPage';
import { AICoachPage } from './AICoachPage';
import { viewModel } from '../viewmodel/TrainingViewModel';
import { initPreferences } from '../services/PreferencesStorage';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  @State isReady: boolean = false;

  private controller: TabsController = new TabsController();

  aboutToAppear(): void {
    this.initApp();
  }

  async initApp(): Promise<void> {
    try {
      const context = getContext(this) as any;
      await initPreferences(context);
      await viewModel.initialize(context);
    } catch (err) {
      console.error('Index initApp failed', JSON.stringify(err));
    }
    this.isReady = true;
  }

  build() {
    Stack() {
      if (this.isReady) {
        // 主界面
        Column() {
          Tabs({
            barPosition: BarPosition.End,
            index: this.currentIndex,
            controller: this.controller
          }) {
            TabContent() {
              DashboardPage()
            }
            .tabBar(this.buildTabBar($r('app.string.tab_dashboard'), 0))

            TabContent() {
              TrainingLogPage()
            }
            .tabBar(this.buildTabBar($r('app.string.tab_log'), 1))

            TabContent() {
              ExerciseProgressPage()
            }
            .tabBar(this.buildTabBar($r('app.string.tab_progress'), 2))

            TabContent() {
              AICoachPage()
            }
            .tabBar(this.buildTabBar($r('app.string.tab_ai'), 3))
          }
          .vertical(false)
          .scrollable(true)
          .barWidth('100%')
          .barHeight(56)
          .animationDuration(300)
          .onChange((index: number) => {
            this.currentIndex = index;
          })
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.background'))
      } else {
        // 加载中
        Column() {
          LoadingProgress()
            .color($r('app.color.primary'))
            .width(48)
            .height(48)
          Text('训记助手')
            .fontSize(20)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 24 })
          Text('加载训练数据...')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 8 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor($r('app.color.background'))
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildTabBar(label: Resource, index: number) {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor(this.currentIndex === index
          ? $r('app.color.primary')
          : $r('app.color.text_secondary'))
        .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Regular)
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
  }
}
