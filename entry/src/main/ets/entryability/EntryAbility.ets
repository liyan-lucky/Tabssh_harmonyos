import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { TerminalSessionManager } from '../common/services/TerminalSessionManager';
import { ProfileRepository } from '../common/storage/ProfileRepository';

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.getMainWindow()
      .then((mainWindow: window.Window) => mainWindow.setWindowPrivacyMode(true))
      .catch(() => {});
    windowStage.loadContent('pages/Index');
  }

  onBackground(): void {
    TerminalSessionManager.closeAll();
    ProfileRepository.clearSensitiveFields();
  }
}
