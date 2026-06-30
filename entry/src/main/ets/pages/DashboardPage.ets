import { viewModel } from '../viewmodel/TrainingViewModel';
import { ExercisePR } from '../models/DashboardStats';
import { MAJOR_LIFTS } from '../models/TrainingRecord';
import { ProgressChart } from '../components/ProgressChart';
import { OneRmBar } from '../components/OneRmBar';
import { Storage } from '../services/PreferencesStorage';

interface ChartPoint { date: string; value: number; }

@Component
export struct DashboardPage {
  @State showSettingsDialog: boolean = false;
  @State xunjiTokenInput: string = '';
  @State isSyncing: boolean = false;
  @State syncHint: string = '';
  @State statsSessions: number = 0;
  @State statsDays: number = 0;

  aboutToAppear(): void {
    this.refreshStats();
  }

  refreshStats(): void {
    const stats = viewModel.dashboardStats;
    this.statsSessions = stats.totalSessions;
    this.statsDays = stats.totalTrainingDays;
  }

  build() {
    Column() {
      Row() {
        Text('训练仪表盘').fontSize(22).fontColor(Color.White).fontWeight(FontWeight.Bold).layoutWeight(1)
        Text('⚙️').fontSize(20).onClick(() => { this.openSettings(); })
      }.width('100%').padding({ top: 16, bottom: 8, left: 20, right: 20 })

      if (viewModel.allRecords.length === 0) {
        Column() {
          Text('暂无训练数据').fontSize(16).fontColor($r('app.color.text_secondary'))
          Text('配置训记 API Key 后可同步云端训练记录').fontSize(12).fontColor('rgba(255,255,255,0.35)').margin({ top: 8 })
          Button('配置同步').fontSize(14).fontColor(Color.White).backgroundColor($r('app.color.primary'))
            .borderRadius(20).height(40).margin({ top: 16 })
            .onClick(() => { this.openSettings(); })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column() {
            if (!viewModel.xunjiTokenConfigured) {
              Row() {
                Text('未配置训记 API Key，数据仅来自本地').fontSize(11).fontColor($r('app.color.accent_orange')).layoutWeight(1)
                Text('去配置').fontSize(11).fontColor($r('app.color.primary'))
                  .onClick(() => { this.openSettings(); })
              }.width('100%').padding(10).backgroundColor('rgba(255,152,0,0.12)').borderRadius(10).margin({ bottom: 12 })
            } else if (viewModel.lastSyncDate) {
              Text('上次同步：' + viewModel.lastSyncDate).fontSize(11).fontColor($r('app.color.text_secondary'))
                .width('100%').margin({ bottom: 12 })
            }

            Row() {
              this.card('📅', '' + this.statsDays, '训练天数')
              this.card('💪', '' + this.statsSessions, '训练次数')
            }.width('100%').margin({ bottom: 12 })
            Row() {
              this.card('📊', '' + viewModel.dashboardStats.totalSets, '总组数')
              this.card('⏱️', Math.round(viewModel.dashboardStats.totalDurationMinutes / 60) + 'h', '总时长')
            }.width('100%').margin({ bottom: 16 })
            Row() {
              this.card('🏋️', this.formatVolume(viewModel.dashboardStats.totalVolume), '累计容量')
              this.card('🏆', '' + viewModel.dashboardStats.allPRs.length, 'PR动作')
            }.width('100%').margin({ bottom: 16 })

            Divider().height(0.5).color('rgba(255,255,255,0.1)').margin({ bottom: 16 })
            Text('🔥 连续训练 ' + viewModel.dashboardStats.streakDays + ' 天').fontSize(18)
              .fontColor($r('app.color.accent_orange')).fontWeight(FontWeight.Bold).margin({ bottom: 16 })

            ProgressChart({
              dataPoints: this.getWeeklyVolumePoints(),
              title: '近 4 周训练容量',
              unit: 'kg',
              accentColor: '#FF9800'
            }).margin({ bottom: 16 })

            if (viewModel.dashboardStats.allPRs.length > 0) {
              Column() {
                Row() {
                  Text('动作 PR 排行').fontSize(15).fontColor(Color.White).fontWeight(FontWeight.Medium).layoutWeight(1)
                  Text('估算 1RM').fontSize(11).fontColor($r('app.color.text_secondary'))
                }.width('100%').margin({ bottom: 8 })
                ForEach(this.getTopPrs(), (pr: ExercisePR) => {
                  OneRmBar({
                    exerciseName: pr.exerciseName,
                    oneRm: pr.estimatedOneRm,
                    maxOneRm: this.getMaxPr()
                  })
                }, (pr: ExercisePR) => pr.exerciseName)
              }.width('100%').padding(12).backgroundColor($r('app.color.card_background')).borderRadius(12)
            }
          }.width('100%').padding(16)
        }.layoutWeight(1)
      }

      if (this.showSettingsDialog) { this.buildSettingsDialog(); }
    }.width('100%').height('100%').backgroundColor($r('app.color.background'))
  }

  @Builder
  buildSettingsDialog() {
    Column() {
      Column() {
        Text('训记数据同步').fontSize(16).fontColor(Color.White).fontWeight(FontWeight.Bold).width('100%').margin({ bottom: 8 })
        Text('在训记 App 中复制 Open API Key，粘贴到下方以同步最近 14 天训练数据。')
          .fontSize(11).fontColor($r('app.color.text_secondary')).width('100%').margin({ bottom: 12 })

        TextInput({ placeholder: 'xjllm_...', text: this.xunjiTokenInput })
          .height(44).fontSize(14).backgroundColor($r('app.color.card_background')).borderRadius(10).padding({ left: 12 })
          .type(InputType.Password).onChange((v: string) => { this.xunjiTokenInput = v; })

        Row() {
          Text(viewModel.xunjiTokenConfigured ? '● 已配置 Key' : '○ 未配置 Key')
            .fontSize(11).fontColor(viewModel.xunjiTokenConfigured ? $r('app.color.accent_green') : $r('app.color.text_secondary'))
          Blank()
          if (viewModel.lastSyncDate) {
            Text('上次同步 ' + viewModel.lastSyncDate).fontSize(11).fontColor($r('app.color.text_secondary'))
          }
        }.width('100%').margin({ top: 8, bottom: 8 })

        if (this.syncHint) {
          Text(this.syncHint).fontSize(11).fontColor($r('app.color.text_secondary')).width('100%').margin({ bottom: 8 })
        }
        if (viewModel.syncError) {
          Text(viewModel.syncError).fontSize(11).fontColor($r('app.color.accent_red')).width('100%').margin({ bottom: 8 })
        }

        Row() {
          Button('取消').backgroundColor('rgba(255,255,255,0.1)').borderRadius(20).height(40)
            .onClick(() => { this.showSettingsDialog = false; })
          Button(this.isSyncing ? '同步中...' : '立即同步')
            .backgroundColor('rgba(255,255,255,0.12)').fontColor(Color.White).borderRadius(20).height(40).margin({ left: 8 })
            .enabled(!this.isSyncing && viewModel.xunjiTokenConfigured)
            .onClick(() => { this.syncNow(false); })
          Button('保存').backgroundColor($r('app.color.primary')).borderRadius(20).height(40).margin({ left: 8 })
            .enabled(!this.isSyncing)
            .onClick(() => { this.saveTokenAndSync(); })
        }.width('100%')
      }.padding(24).backgroundColor($r('app.color.surface')).borderRadius(16).width('90%')
        .onClick(() => {})
    }.width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      .backgroundColor('rgba(0,0,0,0.6)').onClick(() => { this.showSettingsDialog = false; })
  }

  @Builder card(icon: string, value: string, label: string) {
    Column() {
      Text(icon).fontSize(24)
      Text(value).fontSize(20).fontColor(Color.White).fontWeight(FontWeight.Bold).margin({ top: 4 })
      Text(label).fontSize(12).fontColor($r('app.color.text_secondary')).margin({ top: 2 })
    }.alignItems(HorizontalAlign.Center).layoutWeight(1).padding(12)
      .backgroundColor($r('app.color.card_background')).borderRadius(12).margin({ right: 6 })
  }

  async openSettings(): Promise<void> {
    this.xunjiTokenInput = await Storage.getXunjiToken();
    this.syncHint = '';
    this.showSettingsDialog = true;
  }

  async saveTokenAndSync(): Promise<void> {
    const token = this.xunjiTokenInput.trim();
    if (!token) {
      this.syncHint = '请输入训记 API Key';
      return;
    }
    await viewModel.updateXunjiToken(token);
    this.syncHint = 'Key 已保存';
    await this.syncNow(true);
  }

  async syncNow(closeOnDone: boolean): Promise<void> {
    if (this.isSyncing) return;
    this.isSyncing = true;
    this.syncHint = '正在同步最近 14 天数据...';
    viewModel.syncError = '';
    const added = await viewModel.syncFromApi();
    this.isSyncing = false;
    this.refreshStats();
    if (viewModel.syncError) {
      this.syncHint = viewModel.syncError;
    } else if (added > 0) {
      this.syncHint = '同步完成，合并 ' + added + ' 条记录';
    } else {
      this.syncHint = '同步完成，暂无新记录';
    }
    if (closeOnDone && !viewModel.syncError) {
      this.showSettingsDialog = false;
    }
  }

  private getWeeklyVolumePoints(): ChartPoint[] {
    const weeks = viewModel.dashboardStats.recentWeeklyVolumes;
    const points: ChartPoint[] = [];
    for (let i = weeks.length - 1; i >= 0; i--) {
      points.push({ date: weeks[i].weekStart, value: weeks[i].totalVolume });
    }
    return points;
  }

  private getTopPrs(): ExercisePR[] {
    const keyLifts: ExercisePR[] = [];
    for (const pr of viewModel.dashboardStats.allPRs) {
      for (const name of MAJOR_LIFTS) {
        if (pr.exerciseName === name) {
          keyLifts.push(pr);
          break;
        }
      }
    }
    // 按 1RM 从高到低排序
    keyLifts.sort((a, b) => b.estimatedOneRm - a.estimatedOneRm);
    return keyLifts;
  }

  private getMaxPr(): number {
    const prs = this.getTopPrs();
    let max = 0;
    for (const pr of prs) if (pr.estimatedOneRm > max) max = pr.estimatedOneRm;
    return max || 1;
  }

  private formatVolume(value: number): string {
    if (value >= 1000) return Math.round(value / 100) / 10 + 't';
    return value + 'kg';
  }
}
