import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { AUDIT_CONFIG_CHANGE } from '../common/models/ConnectionAuditLog';
import { ConnectionGroup } from '../common/models/ConnectionGroup';
import { ConnectionProfile } from '../common/models/ConnectionProfile';
import { createIconColorFilter } from '../common/IconUtils';
import {
  ConnectionImportExportService,
  ConnectionImportPreview
} from '../common/services/ConnectionImportExportService';
import { ConnectionImportResult, ProfileRepository } from '../common/storage/ProfileRepository';
import { LANG_ZH, THEME_LIGHT } from '../common/AppSettings';
import { AppTheme } from '../common/AppTheme';
import { I18n } from '../common/I18n';

@Entry
@Component
struct ConnectionImportExportPage {
  @State profileCount: number = 0;
  @State groupCount: number = 0;
  @State busy: boolean = false;
  @State statusText: string = '';
  @State pendingFormat: string = '';
  @State pendingProfileCount: number = 0;
  @State pendingGroupCount: number = 0;
  @State pendingWarnings: string[] = [];
  @StorageProp('avoidStatusBarHeight') avoidStatusBarHeight: number = 0;
  @StorageProp('avoidNavigationBarHeight') avoidNavigationBarHeight: number = 0;
  @StorageLink('appThemeMode') themeMode: string = THEME_LIGHT;
  @StorageLink('appLanguage') language: string = LANG_ZH;

  private pendingProfiles: ConnectionProfile[] = [];
  private pendingGroups: ConnectionGroup[] = [];
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

  private textPrimary(): string {
    return AppTheme.textPrimary(this.themeMode);
  }

  private textSecond(): string {
    return AppTheme.textSecond(this.themeMode);
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

  private currentStatusText(): string {
    return this.statusText.length > 0 ? this.statusText : this.t('import.statusIdle');
  }

  aboutToAppear(): void {
    this.reloadCounts();
  }

  onPageShow(): void {
    this.reloadCounts();
  }

  private reloadCounts(): void {
    this.profileCount = ProfileRepository.list().length;
    this.groupCount = ProfileRepository.listGroups().length;
  }

  private toast(message: string): void {
    promptAction.showToast({ message: message, duration: 1800 });
  }

  private backupFileName(): string {
    return 'opentabssh-connections-' + this.timestampSlug() + '.json';
  }

  private sshConfigFileName(): string {
    return 'opentabssh-ssh-config-' + this.timestampSlug() + '.txt';
  }

  private timestampSlug(): string {
    const date: Date = new Date();
    return date.getFullYear().toString() + this.pad(date.getMonth() + 1) + this.pad(date.getDate()) + '-' +
      this.pad(date.getHours()) + this.pad(date.getMinutes());
  }

  private pad(value: number): string {
    return value < 10 ? '0' + value.toString() : value.toString();
  }

  private visibleWarnings(): string[] {
    return this.pendingWarnings.slice(0, 4);
  }

  private async exportBackupJson(): Promise<void> {
    const content: string = ConnectionImportExportService.buildBackupJson(
      ProfileRepository.listGroups(),
      ProfileRepository.list()
    );
    await this.saveTextFile(this.backupFileName(), content, this.t('import.backupExported'), this.t('import.auditExportJson'));
  }

  private async exportOpenSshConfig(): Promise<void> {
    const content: string = ConnectionImportExportService.buildOpenSshConfig(
      ProfileRepository.listGroups(),
      ProfileRepository.list()
    );
    await this.saveTextFile(this.sshConfigFileName(), content, this.t('import.sshExported'), this.t('import.auditExportSsh'));
  }

  private async importBackupJson(): Promise<void> {
    await this.importTextFile(this.t('import.exportJson'), (text: string): ConnectionImportPreview => {
      return ConnectionImportExportService.parseBackupJson(text);
    });
  }

  private async importOpenSshConfig(): Promise<void> {
    await this.importTextFile('OpenSSH config', (text: string): ConnectionImportPreview => {
      return ConnectionImportExportService.parseOpenSshConfig(text);
    });
  }

  private async importTextFile(label: string, parser: (text: string) => ConnectionImportPreview): Promise<void> {
    if (this.busy) {
      return;
    }
    this.busy = true;
    try {
      const text: string = await this.readSelectedText(label);
      if (text.length === 0) {
        this.toast(this.t('import.cancelImport'));
        return;
      }
      const preview: ConnectionImportPreview = parser(text);
      this.pendingProfiles = preview.profiles;
      this.pendingGroups = preview.groups;
      this.pendingFormat = preview.format;
      this.pendingProfileCount = preview.profiles.length;
      this.pendingGroupCount = preview.groups.length;
      this.pendingWarnings = preview.warnings;
      this.statusText = this.t('import.parsedPrefix') + preview.format + this.t('import.parsedSuffix');
      if (preview.profiles.length === 0) {
        this.toast(this.t('import.noHosts'));
      }
    } catch (error) {
      this.statusText = label + this.t('import.parseFailed');
      this.toast(label + this.t('import.importFailed'));
    } finally {
      this.busy = false;
    }
  }

  private confirmImport(): void {
    if (this.pendingProfiles.length === 0) {
      this.toast(this.t('import.noPending'));
      return;
    }
    const result: ConnectionImportResult = ProfileRepository.importConnections(
      this.pendingGroups,
      this.pendingProfiles,
      this.pendingFormat
    );
    this.statusText = this.t('import.donePrefix') + result.importedProfiles.toString() +
      this.t('import.doneMiddleSkip') + result.skippedProfiles.toString() +
      this.t('import.doneMiddleGroup') + result.importedGroups.toString() + this.t('import.doneSuffix');
    this.pendingProfiles = [];
    this.pendingGroups = [];
    this.pendingFormat = '';
    this.pendingProfileCount = 0;
    this.pendingGroupCount = 0;
    this.pendingWarnings = result.warnings;
    this.reloadCounts();
    this.toast(this.t('import.doneToast'));
  }

  private clearPending(): void {
    this.pendingProfiles = [];
    this.pendingGroups = [];
    this.pendingFormat = '';
    this.pendingProfileCount = 0;
    this.pendingGroupCount = 0;
    this.pendingWarnings = [];
    this.statusText = this.t('import.pendingCanceled');
  }

  private async saveTextFile(fileName: string, content: string, successMessage: string, auditMessage: string): Promise<void> {
    if (this.busy) {
      return;
    }
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    const cachePath: string = context.cacheDir + '/' + fileName;
    this.busy = true;
    try {
      const output: fs.File = fs.openSync(cachePath,
        fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      try {
        fs.writeSync(output.fd, content);
      } finally {
        fs.closeSync(output);
      }

      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
      const options: picker.DocumentSaveOptions = new picker.DocumentSaveOptions();
      options.newFileNames = [fileName];
      const destinationUris: Array<string> = await documentPicker.save(options);
      if (destinationUris.length === 0) {
        this.toast(this.t('import.exportCanceled'));
        return;
      }
      const destination: fs.File = fs.openSync(destinationUris[0], fs.OpenMode.WRITE_ONLY);
      try {
        await fs.copyFile(cachePath, destination.fd);
      } finally {
        fs.closeSync(destination);
      }
      if (!await this.verifySavedText(destinationUris[0], content, cachePath + '.verify')) {
        this.statusText = this.t('import.exportVerifyFailed');
        this.toast(this.t('import.exportVerifyToast'));
        return;
      }
      ProfileRepository.recordAuditLog(AUDIT_CONFIG_CHANGE, 'success', '', this.t('import.title'), auditMessage);
      this.statusText = successMessage + this.t('import.exportVerifiedSuffix');
      this.toast(successMessage + this.t('import.exportVerifiedToastSuffix'));
    } catch (error) {
      this.statusText = this.t('import.exportFailed');
      this.toast(this.t('import.exportFailedToast'));
    } finally {
      if (fs.accessSync(cachePath)) {
        fs.unlinkSync(cachePath);
      }
      this.busy = false;
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

  private async readSelectedText(label: string): Promise<string> {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
    const options: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
    options.maxSelectNumber = 1;
    const selectedUris: Array<string> = await documentPicker.select(options);
    if (selectedUris.length === 0) {
      return '';
    }
    const cachePath: string = context.cacheDir + '/opentabssh-import-' + label.replace(/\s+/g, '-') + '-' +
      new Date().getTime().toString() + '.txt';
    const source: fs.File = fs.openSync(selectedUris[0], fs.OpenMode.READ_ONLY);
    try {
      await fs.copyFile(source.fd, cachePath);
    } finally {
      fs.closeSync(source);
    }
    try {
      return fs.readTextSync(cachePath);
    } finally {
      if (fs.accessSync(cachePath)) {
        fs.unlinkSync(cachePath);
      }
    }
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
        Text(this.t('import.title'))
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary())
        Text(this.t('import.subtitle'))
          .fontSize(12)
          .fontColor(this.textSecond())
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })
      Text(this.busy ? this.t('import.busy') : this.t('common.refresh'))
        .fontSize(13)
        .fontColor(this.accentColor)
        .padding({ left: 10, right: 10, top: 7, bottom: 7 })
        .backgroundColor(this.iconSoftBg())
        .borderRadius(11)
        .onClick(() => this.reloadCounts())
    }
    .width('100%')
    .height(68)
    .padding({ left: 20, right: 20, top: 8 })
  }

  @Builder
  ActionRow(icon: Resource, title: string, subtitle: string, color: string, action: () => void,
    showDivider: boolean = true) {
    Column() {
      Row() {
        Row() {
          Image(icon)
            .width(21)
            .height(21)
            .colorFilter(createIconColorFilter('#FFFFFF'))
        }
        .width(38)
        .height(38)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(color)
        .borderRadius(10)
        .margin({ right: 12 })
        Column({ space: 2 }) {
          Text(title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.textPrimary())
          Text(subtitle)
            .fontSize(12)
            .fontColor(this.textSecond())
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Image($rawfile('ft_up.svg'))
          .width(18)
          .height(18)
          .rotate({ angle: 90 })
          .colorFilter(createIconColorFilter('#94A3B8'))
      }
      .width('100%')
      .height(72)
      .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      .onClick(action)
      if (showDivider) {
        Divider().color(this.lineColor()).margin({ left: 64 })
      }
    }
    .width('100%')
  }

  @Builder
  SummaryCard() {
    Column({ space: 10 }) {
      Row() {
        this.Metric(this.t('import.metricHosts'), this.profileCount.toString())
        this.Metric(this.t('import.metricGroups'), this.groupCount.toString())
      }
      .width('100%')
      Text(this.t('import.summary'))
        .fontSize(12)
        .fontColor(this.textSecond())
        .lineHeight(18)
        .width('100%')
      Text(this.currentStatusText())
        .fontSize(12)
        .fontColor(this.accentColor)
        .width('100%')
    }
    .width('92%')
    .padding(14)
    .backgroundColor(this.cardBg())
    .borderRadius(16)
    .margin({ top: 8, bottom: 12 })
  }

  @Builder
  Metric(title: string, value: string) {
    Column({ space: 3 }) {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary())
      Text(title)
        .fontSize(12)
        .fontColor(this.textSecond())
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  PendingCard() {
    Column({ space: 10 }) {
      Text(this.t('import.preview'))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textPrimary())
        .width('100%')
      Text(this.pendingFormat + ' · ' + this.pendingProfileCount.toString() + this.t('import.previewHostUnit') +
        ' · ' + this.pendingGroupCount.toString() + this.t('import.previewGroupUnit'))
        .fontSize(13)
        .fontColor(this.textSecond())
        .width('100%')
      if (this.pendingWarnings.length > 0) {
        ForEach(this.visibleWarnings(), (warning: string) => {
          Text(warning)
            .fontSize(12)
            .fontColor('#B45309')
            .width('100%')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }, (warning: string) => warning)
      }
      Row({ space: 8 }) {
        Text(this.t('import.confirm'))
          .fontSize(13)
          .fontColor(Color.White)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor(this.accentColor)
          .borderRadius(11)
          .onClick(() => this.confirmImport())
        Text(this.t('groups.cancel'))
          .fontSize(13)
          .fontColor(this.textSecond())
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor(this.chipBg())
          .borderRadius(11)
          .onClick(() => this.clearPending())
      }
      .width('100%')
    }
    .width('92%')
    .padding(14)
    .backgroundColor(this.cardBg())
    .borderRadius(16)
    .margin({ bottom: 12 })
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column() {
          this.SummaryCard()

          Column() {
            this.ActionRow($rawfile('settings_update.svg'), this.t('import.exportSsh'),
              this.t('import.exportSshSub'), '#0A84FF', () => this.exportOpenSshConfig())
            this.ActionRow($rawfile('settings_folder.svg'), this.t('import.importSsh'),
              this.t('import.importSshSub'), '#2EA8E5', () => this.importOpenSshConfig())
            this.ActionRow($rawfile('ft_file.svg'), this.t('import.exportJson'),
              this.t('import.exportJsonSub'), '#22C55E', () => this.exportBackupJson())
            this.ActionRow($rawfile('settings_server.svg'), this.t('import.importJson'),
              this.t('import.importJsonSub'), '#FF9F0A', () => this.importBackupJson(), false)
          }
          .width('92%')
          .backgroundColor(this.cardBg())
          .borderRadius(16)
          .clip(true)
          .margin({ bottom: 12 })

          if (this.pendingProfileCount > 0 || this.pendingGroupCount > 0) {
            this.PendingCard()
          }

          if (this.pendingWarnings.length > 4) {
            Text(this.t('import.moreWarningsPrefix') + (this.pendingWarnings.length - 4).toString() +
              this.t('import.moreWarningsSuffix'))
              .fontSize(12)
              .fontColor(this.textSecond())
              .width('88%')
              .margin({ bottom: 20 })
          } else {
            Blank().height(20)
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
