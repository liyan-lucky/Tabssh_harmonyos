import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { createIconColorFilter } from '../common/IconUtils';
import { LANG_ZH, THEME_LIGHT } from '../common/AppSettings';
import { AppTheme } from '../common/AppTheme';
import { I18n } from '../common/I18n';

@Entry
@Component
struct TerminalSettingsPage {
  @State fontSizeMode: string = 'medium';
  @StorageProp('avoidStatusBarHeight') avoidStatusBarHeight: number = 0;
  @StorageProp('avoidNavigationBarHeight') avoidNavigationBarHeight: number = 0;
  @StorageLink('appThemeMode') themeMode: string = THEME_LIGHT;
  @StorageLink('appLanguage') language: string = LANG_ZH;

  private t(key: string): string {
    return I18n.t(this.language, key);
  }

  private pageBg(): string {
    return AppTheme.pageBg(this.themeMode);
  }

  private cardBg(): string {
    return AppTheme.cardBg(this.themeMode);
  }

  private textPrimary(): string {
    return AppTheme.textPrimary(this.themeMode);
  }

  private textSecond(): string {
    return AppTheme.textSecond(this.themeMode);
  }

  private lineColor(): string {
    return AppTheme.line(this.themeMode);
  }

  private fontSizeLabel(): string {
    return this.fontSizeMode === 'medium' ? this.t('common.medium') : this.t('common.small');
  }

  private toast(message: string): void {
    promptAction.showToast({ message: message, duration: 1800 });
  }

  @Builder
  OptionRow(icon: Resource, title: string, value: string, color: string, action: () => void,
    showDivider: boolean = true) {
    Column() {
      Row() {
        Row() {
          Image(icon).width(21).height(21).colorFilter(createIconColorFilter('#FFFFFF'))
        }
          .width(36).height(36).justifyContent(FlexAlign.Center).backgroundColor(color).borderRadius(10).margin({ right: 12 })
        Text(title).fontSize(16).fontColor(this.textPrimary()).layoutWeight(1)
        Text(value).fontSize(13).fontColor(this.textSecond()).margin({ right: 8 })
        Image($rawfile('ft_up.svg')).width(18).height(18).rotate({ angle: 90 })
          .colorFilter(createIconColorFilter('#94A3B8'))
      }
      .width('100%').height(54).padding({ left: 14, right: 14 }).onClick(action)
      if (showDivider) { Divider().color(this.lineColor()).margin({ left: 62 }) }
    }
  }

  build() {
    Column() {
      Row() {
        Image($rawfile('ft_back.svg')).width(24).height(24).margin({ left: 10, right: 10 })
          .colorFilter(createIconColorFilter(this.textPrimary())).onClick(() => router.back())
        Text(this.t('terminalSettings.title')).fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.textPrimary())
          .layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(44)
      }
      .width('100%').height(64).padding({ left: 14, right: 14, top: 8 })

      Column() {
        this.OptionRow($rawfile('settings_display.svg'), this.t('terminalSettings.font'), 'Monospace', '#0A84FF',
          () => this.toast(this.t('terminalSettings.fontPickerPending')))
        this.OptionRow($rawfile('settings_palette.svg'), this.t('terminalSettings.theme'), this.t('terminalSettings.dark'), '#6554D9',
          () => this.toast(this.t('terminalSettings.currentTheme')))
        this.OptionRow($rawfile('settings_tune.svg'), this.t('terminalSettings.fontSize'), this.fontSizeLabel(), '#20B8E6', () => {
          this.fontSizeMode = this.fontSizeMode === 'medium' ? 'small' : 'medium';
        })
        this.OptionRow($rawfile('settings_terminal.svg'), this.t('terminalSettings.keyboard'), this.t('terminalSettings.keyboardValue'), '#FF9F0A',
          () => this.toast(this.t('terminalSettings.keyboardEnabled')), false)
      }
      .width('92%')
      .backgroundColor(this.cardBg())
      .borderRadius(18)
      .clip(true)
      .margin({ top: 10 })

      Text(this.t('terminalSettings.hint'))
        .fontSize(12).fontColor(this.textSecond()).width('88%').margin({ top: 10 })
      Blank()
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.avoidStatusBarHeight, bottom: this.avoidNavigationBarHeight })
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.pageBg())
  }
}
