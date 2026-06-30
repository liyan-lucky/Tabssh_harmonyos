import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import display from '@ohos.display';
import { TerminalSessionManager } from '../common/services/TerminalSessionManager';
import { ProfileRepository } from '../common/storage/ProfileRepository';
import { AppSettingsRepository, THEME_DARK } from '../common/AppSettings';

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    AppSettingsRepository.initialize(this.context);
    AppStorage.setOrCreate<number>('profileRefreshToken', new Date().getTime());
    windowStage.getMainWindow()
      .then((mainWindow: window.Window) => this.configureMainWindow(mainWindow))
      .catch(() => {});
    ProfileRepository.initialize(this.context)
      .then(() => windowStage.loadContent('pages/Index'))
      .catch(() => windowStage.loadContent('pages/Index'));
  }

  onBackground(): void {
    TerminalSessionManager.closeAll();
    ProfileRepository.clearSensitiveFields();
  }

  private configureMainWindow(mainWindow: window.Window): void {
    const isDark: boolean = AppSettingsRepository.currentThemeMode() === THEME_DARK;
    const barContentColor: string = isDark ? '#F8FAFC' : '#111827';
    mainWindow.setWindowPrivacyMode(true).catch(() => {});
    mainWindow.setWindowLayoutFullScreen(true).catch(() => {});
    mainWindow.setWindowSystemBarEnable(['status', 'navigation']).catch(() => {});
    mainWindow.setWindowSystemBarProperties({
      statusBarColor: '#00000000',
      navigationBarColor: '#00000000',
      statusBarContentColor: barContentColor,
      navigationBarContentColor: barContentColor,
      isStatusBarLightIcon: isDark,
      isNavigationBarLightIcon: isDark
    }).catch(() => {});
    this.updateAvoidAreas(mainWindow);
    mainWindow.on('windowRectChange', () => this.updateAvoidAreas(mainWindow));
  }

  private updateAvoidAreas(mainWindow: window.Window): void {
    try {
      const systemArea: window.AvoidArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const cutoutArea: window.AvoidArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT);
      const gestureArea: window.AvoidArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM_GESTURE);
      const density: number = this.displayDensity();
      const topPx: number = Math.max(systemArea.topRect.height, cutoutArea.topRect.height);
      const bottomPx: number = Math.max(systemArea.bottomRect.height, gestureArea.bottomRect.height);
      AppStorage.setOrCreate<number>('avoidStatusBarHeight', Math.ceil(topPx / density));
      AppStorage.setOrCreate<number>('avoidNavigationBarHeight', Math.ceil(bottomPx / density));
    } catch (error) {
      AppStorage.setOrCreate<number>('avoidStatusBarHeight', 0);
      AppStorage.setOrCreate<number>('avoidNavigationBarHeight', 0);
    }
  }

  private displayDensity(): number {
    try {
      const currentDisplay: display.Display = display.getDefaultDisplaySync();
      if (currentDisplay.densityPixels > 0) {
        return currentDisplay.densityPixels;
      }
    } catch (error) {
    }
    return 1;
  }
}
