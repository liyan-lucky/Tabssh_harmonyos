import router from '@ohos.router';
import { ConnectionProfile } from '../common/models/ConnectionProfile';
import { ProfileRepository } from '../common/storage/ProfileRepository';
import { createIconColorFilter } from '../common/IconUtils';
import { LANG_ZH, THEME_LIGHT } from '../common/AppSettings';
import { AppTheme } from '../common/AppTheme';
import { I18n } from '../common/I18n';

@Entry
@Component
struct ConnectionHistoryPage {
  @State profiles: ConnectionProfile[] = [];
  @StorageProp('avoidStatusBarHeight') avoidStatusBarHeight: number = 0;
  @StorageProp('avoidNavigationBarHeight') avoidNavigationBarHeight: number = 0;
  @StorageLink('appThemeMode') themeMode: string = THEME_LIGHT;
  @StorageLink('appLanguage') language: string = LANG_ZH;

  private readonly accentColor: string = '#0A84FF';

  private t(key: string): string {
    return I18n.t(this.language, key);
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

  private textPrimary(): string {
    return AppTheme.textPrimary(this.themeMode);
  }

  private textSecond(): string {
    return AppTheme.textSecond(this.themeMode);
  }

  private textMuted(): string {
    return AppTheme.textMuted(this.themeMode);
  }

  private lineColor(): string {
    return AppTheme.line(this.themeMode);
  }

  private iconSoftBg(): string {
    return AppTheme.iconSoftBg(this.themeMode);
  }

  aboutToAppear(): void {
    this.reload();
  }

  onPageShow(): void {
    this.reload();
  }

  private reload(): void {
    this.profiles = ProfileRepository.list()
      .filter((profile: ConnectionProfile) => profile.lastConnectedAt > 0 || profile.lastErrorMessage.length > 0)
      .sort((left: ConnectionProfile, right: ConnectionProfile) => {
        return right.lastConnectedAt - left.lastConnectedAt ||
          right.connectionCount - left.connectionCount ||
          left.name.localeCompare(right.name);
      })
      .slice(0, 500);
  }

  private connectedProfiles(): number {
    return this.profiles.filter((profile: ConnectionProfile) => profile.connectionCount > 0).length;
  }

  private failedProfiles(): number {
    return this.profiles.filter((profile: ConnectionProfile) => profile.lastErrorMessage.length > 0).length;
  }

  private formatTarget(profile: ConnectionProfile): string {
    const user: string = profile.username.length > 0 ? profile.username + '@' : '';
    return user + profile.host + ':' + profile.port.toString();
  }

  private formatTime(timestamp: number): string {
    if (timestamp <= 0) {
      return this.t('history.noSuccess');
    }
    const date: Date = new Date(timestamp);
    return date.getFullYear().toString() + '-' + this.pad(date.getMonth() + 1) + '-' + this.pad(date.getDate()) +
      ' ' + this.pad(date.getHours()) + ':' + this.pad(date.getMinutes());
  }

  private pad(value: number): string {
    return value < 10 ? '0' + value.toString() : value.toString();
  }

  private openTerminal(profile: ConnectionProfile): void {
    router.pushUrl({ url: 'pages/TerminalPage', params: { profileId: profile.id } });
  }

  @Builder
  Header() {
    Row() {
      Image($rawfile('ft_back.svg'))
        .width(22)
        .height(22)
        .colorFilter(createIconColorFilter(this.textPrimary()))
        .onClick(() => router.back())
      Column({ space: 2 }) {
        Text(this.t('history.title'))
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary())
        Text(this.t('history.subtitle'))
          .fontSize(12)
          .fontColor(this.textSecond())
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })
      Text(this.t('common.refresh'))
        .fontSize(13)
        .fontColor(this.accentColor)
        .padding({ left: 10, right: 10, top: 7, bottom: 7 })
        .backgroundColor(this.iconSoftBg())
        .borderRadius(11)
        .onClick(() => this.reload())
    }
    .width('100%')
    .height(68)
    .padding({ left: 20, right: 20, top: 8 })
  }

  @Builder
  SummaryCard() {
    Column({ space: 12 }) {
      Row() {
        this.SummaryMetric(this.t('history.hosts'), this.profiles.length.toString(), '#0A84FF')
        this.SummaryMetric(this.t('history.successHosts'), this.connectedProfiles().toString(), '#16A34A')
        this.SummaryMetric(this.t('history.failureRecords'), this.failedProfiles().toString(), '#DC2626')
      }
      .width('100%')
      Text(this.t('history.privacy'))
        .fontSize(12)
        .fontColor(this.textSecond())
        .lineHeight(18)
        .width('100%')
    }
    .width('92%')
    .padding(16)
    .backgroundColor(this.cardBg())
    .borderRadius(18)
    .shadow({ radius: 8, color: AppTheme.shadow(this.themeMode), offsetY: 2 })
    .margin({ top: 8, bottom: 12 })
  }

  @Builder
  SummaryMetric(label: string, value: string, color: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(11)
        .fontColor(this.textSecond())
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  HistoryRow(profile: ConnectionProfile, index: number) {
    Column() {
      Row() {
        Row() {
          Image($rawfile('settings_timer.svg'))
            .width(20)
            .height(20)
            .colorFilter(createIconColorFilter(profile.connectionCount > 0 ? this.accentColor : '#DC2626'))
        }
        .width(38)
        .height(38)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.elevatedBg())
        .borderRadius(12)
        .margin({ right: 10 })
        Column({ space: 4 }) {
          Row() {
            Text(profile.name)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.textPrimary())
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(profile.connectionCount.toString() + this.t('common.times'))
              .fontSize(11)
              .fontColor(this.textSecond())
          }
          .width('100%')
          Text(this.formatTarget(profile))
            .fontSize(12)
            .fontColor(this.textSecond())
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.formatTime(profile.lastConnectedAt))
            .fontSize(12)
            .fontColor(this.textMuted())
          if (profile.lastErrorMessage.length > 0) {
            Text(this.t('history.lastFailure') + profile.lastErrorMessage)
              .fontSize(12)
              .fontColor('#DC2626')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 12, bottom: 12 })
      .onClick(() => this.openTerminal(profile))

      if (index < this.profiles.length - 1) {
        Divider()
          .color(this.lineColor())
          .margin({ left: 60 })
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column() {
          this.SummaryCard()
          if (this.profiles.length === 0) {
            Row() {
              Text(this.t('history.empty'))
                .fontSize(14)
                .fontColor(this.textSecond())
            }
            .width('92%')
            .height(72)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.cardBg())
            .borderRadius(16)
          } else {
            Column() {
              ForEach(this.profiles, (profile: ConnectionProfile, index: number) => {
                this.HistoryRow(profile, index)
              }, (profile: ConnectionProfile) => profile.id)
            }
            .width('92%')
            .backgroundColor(this.cardBg())
            .borderRadius(16)
            .clip(true)
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.avoidStatusBarHeight, bottom: this.avoidNavigationBarHeight })
    .backgroundColor(this.pageBg())
  }
}
