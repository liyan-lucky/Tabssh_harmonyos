import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import {
  AUDIT_BULK_ACTION,
  AUDIT_CONFIG_CHANGE,
  AUDIT_CONNECT_FAILURE,
  AUDIT_CONNECT_SUCCESS,
  AUDIT_GROUP_CHANGE,
  ConnectionAuditLog
} from '../common/models/ConnectionAuditLog';
import { createIconColorFilter } from '../common/IconUtils';
import { ProfileRepository } from '../common/storage/ProfileRepository';
import { LANG_ZH, THEME_LIGHT } from '../common/AppSettings';
import { AppTheme } from '../common/AppTheme';
import { I18n } from '../common/I18n';

interface AuditExportRow {
  createdAt: number;
  eventType: string;
  status: string;
  profileName: string;
  message: string;
}

interface AuditExportDocument {
  formatVersion: number;
  exportedAt: number;
  policy: string;
  logs: AuditExportRow[];
}

interface AuditFilterOption {
  titleKey: string;
  value: string;
}

@Entry
@Component
struct AuditLogPage {
  // audit-summary-no-command-output-or-credentials
  @State logs: ConnectionAuditLog[] = [];
  @State exporting: boolean = false;
  @State selectedFilter: string = 'all';
  @StorageProp('avoidStatusBarHeight') avoidStatusBarHeight: number = 0;
  @StorageProp('avoidNavigationBarHeight') avoidNavigationBarHeight: number = 0;
  @StorageLink('appThemeMode') themeMode: string = THEME_LIGHT;
  @StorageLink('appLanguage') language: string = LANG_ZH;

  private readonly accentColor: string = '#0A84FF';
  private readonly filterOptions: AuditFilterOption[] = [
    { titleKey: 'audit.filterAll', value: 'all' },
    { titleKey: 'audit.filterSuccess', value: AUDIT_CONNECT_SUCCESS },
    { titleKey: 'audit.filterFailure', value: AUDIT_CONNECT_FAILURE },
    { titleKey: 'audit.filterGroup', value: AUDIT_GROUP_CHANGE },
    { titleKey: 'audit.filterBulk', value: AUDIT_BULK_ACTION },
    { titleKey: 'audit.filterConfig', value: AUDIT_CONFIG_CHANGE }
  ];

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

  private chipBg(): string {
    return AppTheme.chipBg(this.themeMode);
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
    this.logs = ProfileRepository.listAuditLogs(120);
  }

  private filteredLogs(): ConnectionAuditLog[] {
    if (this.selectedFilter === 'all') {
      return this.logs;
    }
    return this.logs.filter((log: ConnectionAuditLog) => log.eventType === this.selectedFilter);
  }

  private toast(message: string): void {
    promptAction.showToast({ message: message, duration: 1800 });
  }

  private clearLogs(): void {
    ProfileRepository.clearAuditLogs();
    this.reload();
    this.toast(this.t('audit.cleared'));
  }

  private buildExportPayload(): string {
    const rows: AuditExportRow[] = this.logs.map((log: ConnectionAuditLog): AuditExportRow => {
      return {
        createdAt: log.createdAt,
        eventType: log.eventType,
        status: log.status,
        profileName: log.profileName,
        message: log.message
      };
    });
    const document: AuditExportDocument = {
      formatVersion: 1,
      exportedAt: Date.now(),
      policy: 'summary-only: no command output, credentials, private key passphrases, or server address',
      logs: rows
    };
    return JSON.stringify(document, null, 2);
  }

  private exportFileName(): string {
    const date: Date = new Date();
    return 'opentabssh-audit-' + date.getFullYear().toString() + this.pad(date.getMonth() + 1) +
      this.pad(date.getDate()) + '-' + this.pad(date.getHours()) + this.pad(date.getMinutes()) + '.json';
  }

  private async exportLogs(): Promise<void> {
    if (this.exporting) {
      return;
    }
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    const cachePath: string = context.cacheDir + '/' + this.exportFileName();
    const payload: string = this.buildExportPayload();
    this.exporting = true;
    try {
      const output: fs.File = fs.openSync(cachePath,
        fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      try {
        fs.writeSync(output.fd, payload);
      } finally {
        fs.closeSync(output);
      }

      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
      const options: picker.DocumentSaveOptions = new picker.DocumentSaveOptions();
      options.newFileNames = [this.exportFileName()];
      const destinationUris: Array<string> = await documentPicker.save(options);
      if (destinationUris.length === 0) {
        this.toast(this.t('audit.cancelExport'));
        return;
      }
      const destination: fs.File = fs.openSync(destinationUris[0], fs.OpenMode.WRITE_ONLY);
      try {
        await fs.copyFile(cachePath, destination.fd);
      } finally {
        fs.closeSync(destination);
      }
      if (!await this.verifySavedText(destinationUris[0], payload, cachePath + '.verify')) {
        this.toast(this.t('audit.verifyFailed'));
        return;
      }
      this.toast(this.t('audit.exported'));
    } catch (error) {
      this.toast(this.t('audit.exportFailed'));
    } finally {
      if (fs.accessSync(cachePath)) {
        fs.unlinkSync(cachePath);
      }
      this.exporting = false;
    }
  }

  private async verifySavedText(uri: string, expected: string, verifyPath: string): Promise<boolean> {
    const source: fs.File = fs.openSync(uri, fs.OpenMode.READ_ONLY);
    try {
      await fs.copyFile(source.fd, verifyPath);
    } finally {
      fs.closeSync(source);
    }
    try {
      const actual: string = fs.readTextSync(verifyPath);
      return actual === expected;
    } finally {
      if (fs.accessSync(verifyPath)) {
        fs.unlinkSync(verifyPath);
      }
    }
  }

  private eventLabel(eventType: string): string {
    if (eventType === AUDIT_CONNECT_SUCCESS) {
      return this.t('audit.eventSuccess');
    }
    if (eventType === AUDIT_CONNECT_FAILURE) {
      return this.t('audit.eventFailure');
    }
    if (eventType === AUDIT_BULK_ACTION) {
      return this.t('audit.eventBulk');
    }
    if (eventType === AUDIT_GROUP_CHANGE) {
      return this.t('audit.eventGroup');
    }
    if (eventType === AUDIT_CONFIG_CHANGE) {
      return this.t('audit.eventConfig');
    }
    return eventType;
  }

  private statusColor(status: string): string {
    if (status === 'success') {
      return '#16A34A';
    }
    if (status === 'failure') {
      return '#DC2626';
    }
    return this.accentColor;
  }

  private formatTime(timestamp: number): string {
    const date: Date = new Date(timestamp);
    return this.pad(date.getMonth() + 1) + '-' + this.pad(date.getDate()) + ' ' +
      this.pad(date.getHours()) + ':' + this.pad(date.getMinutes());
  }

  private pad(value: number): string {
    return value < 10 ? '0' + value.toString() : value.toString();
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
        Text(this.t('audit.title'))
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary())
        Text(this.t('audit.subtitle'))
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
        .margin({ right: 8 })
        .onClick(() => this.reload())
      Text(this.exporting ? this.t('audit.exporting') : this.t('audit.export'))
        .fontSize(13)
        .fontColor(this.accentColor)
        .padding({ left: 10, right: 10, top: 7, bottom: 7 })
        .backgroundColor(this.iconSoftBg())
        .borderRadius(11)
        .margin({ right: 8 })
        .onClick(() => this.exportLogs())
      Text(this.t('audit.clear'))
        .fontSize(13)
        .fontColor('#DC2626')
        .padding({ left: 10, right: 10, top: 7, bottom: 7 })
        .backgroundColor('#FEF2F2')
        .borderRadius(11)
        .onClick(() => this.clearLogs())
    }
    .width('100%')
    .height(68)
    .padding({ left: 20, right: 20, top: 8 })
  }

  @Builder
  FilterChip(option: AuditFilterOption) {
    Text(this.t(option.titleKey))
      .fontSize(12)
      .fontColor(this.selectedFilter === option.value ? Color.White : this.textSecond())
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .backgroundColor(this.selectedFilter === option.value ? this.accentColor : this.chipBg())
      .borderRadius(10)
      .margin({ right: 8, bottom: 8 })
      .onClick(() => this.selectedFilter = option.value)
  }

  @Builder
  LogRow(log: ConnectionAuditLog, index: number) {
    Column() {
      Row() {
        Row() {
          Image($rawfile('settings_timer.svg'))
            .width(20)
            .height(20)
            .colorFilter(createIconColorFilter(this.statusColor(log.status)))
        }
        .width(38)
        .height(38)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.elevatedBg())
        .borderRadius(12)
        .margin({ right: 10 })

        Column({ space: 4 }) {
          Row() {
            Text(this.eventLabel(log.eventType))
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.textPrimary())
              .layoutWeight(1)
            Text(this.formatTime(log.createdAt))
              .fontSize(11)
              .fontColor(this.textSecond())
          }
          .width('100%')
          Text(log.profileName)
            .fontSize(12)
            .fontColor(this.textSecond())
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (log.message.length > 0) {
            Text(log.message)
              .fontSize(12)
              .fontColor(this.textMuted())
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 12, bottom: 12 })

      if (index < this.filteredLogs().length - 1) {
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
          Column({ space: 5 }) {
            Text(this.t('audit.scopeTitle'))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.textPrimary())
              .width('100%')
            Text(this.t('audit.scopeBody'))
              .fontSize(13)
              .fontColor(this.textSecond())
              .lineHeight(19)
              .width('100%')
          }
          .width('92%')
          .padding(16)
          .backgroundColor(this.cardBg())
          .borderRadius(18)
          .shadow({ radius: 8, color: AppTheme.shadow(this.themeMode), offsetY: 2 })
          .margin({ top: 8, bottom: 12 })

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.filterOptions, (option: AuditFilterOption) => {
              this.FilterChip(option)
            }, (option: AuditFilterOption) => option.value)
          }
          .width('92%')
          .margin({ bottom: 8 })

          if (this.filteredLogs().length === 0) {
            Row() {
              Text(this.logs.length === 0 ? this.t('audit.empty') : this.t('audit.emptyFilter'))
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
              ForEach(this.filteredLogs(), (log: ConnectionAuditLog, index: number) => {
                this.LogRow(log, index)
              }, (log: ConnectionAuditLog) => log.id)
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
