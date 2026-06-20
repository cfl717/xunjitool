import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import hilog from '@ohos.hilog';
import window from '@ohos.window';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'EntryAbility', 'onCreate');
  }
  onDestroy() { hilog.info(0x0000, 'EntryAbility', 'onDestroy'); }
  onWindowStageCreate(windowStage: window.WindowStage) {
    hilog.info(0x0000, 'EntryAbility', 'onWindowStageCreate');
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) { hilog.error(0x0000, 'EntryAbility', 'Failed'); return; }
      hilog.info(0x0000, 'EntryAbility', 'Succeeded');
    });
  }
  onWindowStageDestroy() { hilog.info(0x0000, 'EntryAbility', 'onWindowStageDestroy'); }
  onForeground() { hilog.info(0x0000, 'EntryAbility', 'onForeground'); }
  onBackground() { hilog.info(0x0000, 'EntryAbility', 'onBackground'); }
}
