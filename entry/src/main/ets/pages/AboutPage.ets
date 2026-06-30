import router from '@ohos.router';
import { NativeSshCore } from '../common/native/NativeSshCore';
import { createIconColorFilter } from '../common/IconUtils';
import { LANG_ZH, THEME_LIGHT } from '../common/AppSettings';
import { AppTheme } from '../common/AppTheme';
import { I18n } from '../common/I18n';
import { APP_VERSION_CODE, APP_VERSION_NAME, BUILD_TIME } from '../common/BuildInfo';

@Entry
@Component
struct AboutPage {
  @State nativeVersion: string = '';
  @StorageProp('avoidStatusBarHeight') avoidStatusBarHeight: number = 0;
  @StorageProp('avoidNavigationBarHeight') avoidNavigationBarHeight: number = 0;
  @StorageLink('appThemeMode') themeMode: string = THEME_LIGHT;
  @StorageLink('appLanguage') language: string = LANG_ZH;

  aboutToAppear(): void {
    this.nativeVersion = NativeSshCore.version();
  }

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

  @Builder
  InfoRow(title: string, value: string) {
    Row() {
      Text(title)
        .fontSize(13)
        .fontColor(this.textSecond())
        .layoutWeight(1)
      Text(value)
        .fontSize(13)
        .fontColor(this.textPrimary())
        .maxLines(2)
        .textAlign(TextAlign.End)
    }
    .width('100%')
  }

  build() {
    Column() {
      Row() {
        Image($rawfile('ft_back.svg')).width(24).height(24).margin({ left: 10, right: 10 })
          .colorFilter(createIconColorFilter(this.textPrimary())).onClick(() => router.back())
        Text(this.t('about.title')).fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.textPrimary())
          .layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(44)
      }
      .width('100%').height(64).padding({ left: 14, right: 14, top: 8 })

      Column({ space: 8 }) {
        Text('OpenTabSsh').fontSize(28).fontWeight(FontWeight.Bold).fontColor(this.textPrimary())
        Text(this.t('about.subtitle')).fontSize(15).fontColor(this.textSecond())
        this.InfoRow(this.t('about.appVersion'), APP_VERSION_NAME + ' (' + APP_VERSION_CODE.toString() + ')')
        this.InfoRow(this.t('about.buildTime'), BUILD_TIME)
        this.InfoRow(this.t('about.nativeCore'), this.nativeVersion)
      }
      .width('92%').padding(20).backgroundColor(this.cardBg()).borderRadius(18).margin({ top: 12 })

      Column({ space: 10 }) {
        Text(this.t('about.goalTitle')).fontSize(17).fontWeight(FontWeight.Bold).fontColor(this.textPrimary()).width('100%')
        Text(this.t('about.goalBody'))
          .fontSize(14).fontColor(this.textSecond()).width('100%')
        Text(this.t('about.pending'))
          .fontSize(13).fontColor('#D97706').width('100%')
      }
      .width('92%').padding(18).backgroundColor(this.cardBg()).borderRadius(18).margin({ top: 12 })
      Blank()
    }
    .width('100%').height('100%').alignItems(HorizontalAlign.Center).backgroundColor(this.pageBg())
    .padding({ top: this.avoidStatusBarHeight, bottom: this.avoidNavigationBarHeight })
  }
}
