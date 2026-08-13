import { UIAbility, AbilityConstant, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

export default class EntryAbility extends UIAbility {
  onCreate(_want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    // The app deliberately has no network initialization or third-party SDK startup.
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (error: BusinessError<void> | undefined) => {
      if (error?.code) {
        console.error(`月迹页面加载失败: ${error.code}`);
      }
    });
  }
}
