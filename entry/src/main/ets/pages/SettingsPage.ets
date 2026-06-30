import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { createIconColorFilter } from '../common/IconUtils';
import { AppTheme } from '../common/AppTheme';
import {
  AppSettingsRepository,
  LANG_EN,
  LANG_ZH,
  THEME_DARK,
  THEME_LIGHT
} from '../common/AppSettings';
import { I18n } from '../common/I18n';

@Entry
@Component
struct SettingsPage {
  @State autoSave: boolean = true;
  @State autoCompress: boolean = false;
  @StorageProp('avoidStatusBarHeight') avoidStatusBarHeight: number = 0;
  @StorageProp('avoidNavigationBarHeight') avoidNavigationBarHeight: number = 0;
  @StorageLink('appThemeMode') themeMode: string = THEME_LIGHT;
  @StorageLink('appLanguage') language: string = LANG_ZH;

  private readonly accentColor: string = '#0A84FF';

  private t(key: string): string {
    return I18n.t(this.language, key);
  }

  private textPrimary(): string {
    return AppTheme.textPrimary(this.themeMode);
  }

  private textSecond(): string {
    return AppTheme.textSecond(this.themeMode);
  }

  private pageBg(): string {
    return AppTheme.pageBg(this.themeMode);
  }

  private cardBg(): string {
    return AppTheme.cardBg(this.themeMode);
  }

  private elevatedBg(): string {
    return AppTheme.elevatedBg(this.themeMode);
  }

  private lineColor(): string {
    return AppTheme.line(this.themeMode);
  }

  private chipBg(): string {
    return AppTheme.chipBg(this.themeMode);
  }

  private iconSoftBg(): string {
    return AppTheme.iconSoftBg(this.themeMode);
  }

  private toast(message: string): void {
    promptAction.showToast({ message: message, duration: 1800 });
  }

  private setThemeMode(mode: string): void {
    this.themeMode = mode;
    AppSettingsRepository.setThemeMode(mode);
    this.toast(this.t('settings.themeToast'));
  }

  private setLanguage(language: string): void {
    this.language = language;
    AppSettingsRepository.setLanguage(language);
    this.toast(I18n.t(language, 'settings.languageToast'));
  }

  @Builder
  Header() {
    Row() {
      Image($rawfile('ft_back.svg'))
        .width(24)
        .height(24)
        .colorFilter(createIconColorFilter(this.textPrimary()))
        .margin({ left: 10, right: 10 })
        .onClick(() => router.back())
      Text(this.t('settings.title'))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary())
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Blank().width(44)
    }
    .width('100%')
    .height(64)
    .padding({ left: 14, right: 14, top: 8 })
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppTheme.textMuted(this.themeMode))
      .width('92%')
      .margin({ top: 16, bottom: 8 })
  }

  @Builder
  IconBox(icon: Resource, color: string) {
    Row() {
      Image(icon)
        .width(21)
        .height(21)
        .colorFilter(createIconColorFilter('#FFFFFF'))
    }
    .width(36)
    .height(36)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(color)
    .borderRadius(10)
    .margin({ right: 12 })
  }

  @Builder
  SegmentButton(title: string, selected: boolean, width: number, action: () => void) {
    Text(title)
      .fontSize(12)
      .fontWeight(selected ? FontWeight.Medium : FontWeight.Regular)
      .fontColor(selected ? Color.White : this.textSecond())
      .width(width)
      .height(32)
      .textAlign(TextAlign.Center)
      .backgroundColor(selected ? this.accentColor : this.chipBg())
      .borderRadius(10)
      .onClick(action)
  }

  @Builder
  ThemeModeRow(showDivider: boolean = true) {
    Column() {
      Row() {
        this.IconBox($rawfile('settings_palette.svg'), '#20B8E6')
        Column({ space: 1 }) {
          Text(this.t('settings.theme'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.textPrimary())
          Text(this.themeMode === THEME_DARK ? this.t('common.dark') : this.t('common.light'))
            .fontSize(12)
            .fontColor(this.textSecond())
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Row({ space: 8 }) {
          this.SegmentButton(this.t('common.light'), this.themeMode !== THEME_DARK, 64,
            () => this.setThemeMode(THEME_LIGHT))
          this.SegmentButton(this.t('common.dark'), this.themeMode === THEME_DARK, 64,
            () => this.setThemeMode(THEME_DARK))
        }
      }
      .width('100%')
      .height(64)
      .padding({ left: 14, right: 12 })
      if (showDivider) {
        Divider().color(this.lineColor()).margin({ left: 62 })
      }
    }
  }

  @Builder
  LanguageRow(showDivider: boolean = true) {
    Column() {
      Row() {
        this.IconBox($rawfile('settings_language.svg'), '#1598E8')
        Column({ space: 1 }) {
          Text(this.t('settings.language'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.textPrimary())
          Text(this.language === LANG_EN ? this.t('common.english') : this.t('common.chinese'))
            .fontSize(12)
            .fontColor(this.textSecond())
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Row({ space: 8 }) {
          this.SegmentButton('中文', this.language !== LANG_EN, 58, () => this.setLanguage(LANG_ZH))
          this.SegmentButton('EN', this.language === LANG_EN, 58, () => this.setLanguage(LANG_EN))
        }
      }
      .width('100%')
      .height(64)
      .padding({ left: 14, right: 12 })
      if (showDivider) {
        Divider().color(this.lineColor()).margin({ left: 62 })
      }
    }
  }

  @Builder
  ValueRow(icon: Resource, title: string, value: string, color: string, action: () => void,
    showDivider: boolean = true) {
    Column() {
      Row() {
        this.IconBox(icon, color)
        Column({ space: 1 }) {
          Text(title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.textPrimary())
          if (value.length > 0) {
            Text(value)
              .fontSize(12)
              .fontColor(this.textSecond())
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Image($rawfile('ft_up.svg'))
          .width(18)
          .height(18)
          .rotate({ angle: 90 })
          .colorFilter(createIconColorFilter(AppTheme.textMuted(this.themeMode)))
      }
      .width('100%')
      .height(58)
      .padding({ left: 14, right: 14 })
      .onClick(action)
      if (showDivider) {
        Divider().color(this.lineColor()).margin({ left: 62 })
      }
    }
  }

  @Builder
  ToggleRow(icon: Resource, title: string, enabled: boolean, color: string, action: (value: boolean) => void,
    showDivider: boolean = true) {
    Column() {
      Row() {
        this.IconBox(icon, color)
        Column({ space: 1 }) {
          Text(title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.textPrimary())
          Text(enabled ? this.t('common.enabled') : this.t('common.disabled'))
            .fontSize(12)
            .fontColor(this.textSecond())
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: enabled })
          .selectedColor(this.accentColor)
          .switchPointColor(Color.White)
          .onChange(action)
      }
      .width('100%')
      .height(58)
      .padding({ left: 14, right: 10 })
      if (showDivider) {
        Divider().color(this.lineColor()).margin({ left: 62 })
      }
    }
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column() {
          this.SectionTitle(this.t('settings.appearance'))
          Column() {
            this.LanguageRow()
            this.ThemeModeRow()
            this.ValueRow($rawfile('settings_display.svg'), this.t('settings.fontSize'), this.t('settings.fontMedium'), '#7356E8',
              () => this.toast(this.t('settings.fontMedium')), false)
          }
          .width('92%')
          .backgroundColor(this.cardBg())
          .borderRadius(18)
          .clip(true)

          this.SectionTitle(this.t('settings.files'))
          Column() {
            this.ToggleRow($rawfile('settings_folder.svg'), this.t('settings.autoSave'), this.autoSave, '#6554D9',
              (value: boolean) => this.autoSave = value)
            this.ToggleRow($rawfile('settings_update.svg'), this.t('settings.autoCompress'), this.autoCompress, '#FF9F0A',
              (value: boolean) => this.autoCompress = value)
            this.ValueRow($rawfile('ft_file.svg'), this.t('settings.maxFile'), '100 MB', '#0A84FF',
              () => this.toast('100 MB'), false)
          }
          .width('92%')
          .backgroundColor(this.cardBg())
          .borderRadius(18)
          .clip(true)

          Text(this.t('settings.filesHint'))
            .fontSize(12)
            .fontColor(this.textSecond())
            .width('88%')
            .margin({ top: 8 })

          this.SectionTitle(this.t('settings.storage'))
          Column() {
            this.ValueRow($rawfile('settings_update.svg'), this.t('settings.importExport'), this.t('settings.importExportSub'), '#22C55E',
              () => router.pushUrl({ url: 'pages/ConnectionImportExportPage' }))
            this.ValueRow($rawfile('ft_delete.svg'), this.t('settings.clearCache'), this.t('settings.clearCacheSub'), '#FF2965',
              () => this.toast(this.t('settings.clearCacheSub')))
            this.ValueRow($rawfile('settings_server.svg'), this.t('settings.storageSpace'), this.t('settings.storageSpaceSub'), '#32B4DE',
              () => this.toast(this.t('settings.storageSpaceSub')), false)
          }
          .width('92%')
          .backgroundColor(this.cardBg())
          .borderRadius(18)
          .clip(true)
          .margin({ bottom: 24 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
      .backgroundColor(this.pageBg())
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.avoidStatusBarHeight, bottom: this.avoidNavigationBarHeight })
    .backgroundColor(this.pageBg())
  }
}
