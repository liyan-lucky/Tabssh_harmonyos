import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { NativeJsonResult, NativeSshCore } from '../common/native/NativeSshCore';
import { SftpEntry, TerminalTab } from '../common/models/TerminalModels';
import { TerminalSessionManager } from '../common/services/TerminalSessionManager';
import { createIconColorFilter } from '../common/IconUtils';
import { LANG_ZH, THEME_LIGHT } from '../common/AppSettings';
import { AppTheme } from '../common/AppTheme';
import { I18n } from '../common/I18n';

@Entry
@Component
struct SftpPage {
  @State entries: SftpEntry[] = [];
  @State currentPath: string = '/';
  @State status: string = '';
  @State tabId: string = '';
  @State uploadName: string = 'upload.bin';
  @State folderName: string = 'new-folder';
  @State textFileName: string = 'roundtrip.txt';
  @State textContent: string = 'OpenTabSsh SFTP verification';
  @State selectedPath: string = '';
  @State selectedName: string = '';
  @State selectedType: string = '';
  @State renameName: string = '';
  @State modeText: string = '644';
  @State busy: boolean = false;
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

  private textPrimary(): string {
    return AppTheme.textPrimary(this.themeMode);
  }

  private textSecond(): string {
    return AppTheme.textSecond(this.themeMode);
  }

  aboutToAppear(): void {
    if (this.status.length === 0) {
      this.status = this.t('sftp.needSession');
    }
    const params = router.getParams() as Record<string, string>;
    if (params !== undefined && params['tabId'] !== undefined) {
      this.tabId = params['tabId'];
    }
    this.loadList('/');
  }

  onPageShow(): void {
    this.busy = false;
  }

  private activeTab(): TerminalTab | undefined {
    if (this.tabId.length > 0) {
      const exact: TerminalTab | undefined = TerminalSessionManager.getTab(this.tabId);
      if (exact !== undefined) {
        return exact;
      }
    }
    return TerminalSessionManager.listTabs().find((tab: TerminalTab) => tab.connected);
  }

  private validName(name: string): boolean {
    const trimmed: string = name.trim();
    return trimmed.length > 0 && trimmed !== '.' && trimmed !== '..' && trimmed.indexOf('/') < 0 &&
      trimmed.indexOf('\\') < 0;
  }

  private childPath(name: string): string {
    return (this.currentPath === '/' ? '/' : this.currentPath + '/') + name.trim();
  }

  private clearSelection(): void {
    this.selectedPath = '';
    this.selectedName = '';
    this.selectedType = '';
    this.renameName = '';
  }

  private async applyResult(result: NativeJsonResult, successMessage: string): Promise<void> {
    if (!result.ok) {
      this.status = this.t('sftp.operationFailedPrefix') + result.message;
      return;
    }
    this.clearSelection();
    await this.loadList(this.currentPath);
    this.status = successMessage;
  }

  async loadList(path: string): Promise<void> {
    const active: TerminalTab | undefined = this.activeTab();
    if (active === undefined) {
      this.status = this.t('sftp.authFirst');
      return;
    }
    this.currentPath = path;
    this.status = this.t('sftp.reading');
    try {
      this.entries = await NativeSshCore.sftpList(active.sessionId, path);
      this.status = NativeSshCore.version().indexOf('mock') >= 0 ? this.t('sftp.mockDisabled') : this.t('sftp.realDirectory');
    } catch (error) {
      this.entries = [];
      this.status = this.t('sftp.readFailed');
    }
  }

  async upload(): Promise<void> {
    const active: TerminalTab | undefined = this.activeTab();
    if (active === undefined || this.busy) return;
    if (!this.validName(this.uploadName)) {
      this.status = this.t('sftp.invalidUploadName');
      return;
    }
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    let cachePath: string = '';
    this.busy = true;
    try {
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
      const options: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      const selectedUris: Array<string> = await documentPicker.select(options);
      if (selectedUris.length === 0) return;
      cachePath = context.cacheDir + '/sftp_upload_' + Date.now().toString();
      const source: fs.File = fs.openSync(selectedUris[0], fs.OpenMode.READ_ONLY);
      try {
        await fs.copyFile(source.fd, cachePath);
      } finally {
        fs.closeSync(source);
      }
      this.status = this.t('sftp.uploading');
      const result: NativeJsonResult = await NativeSshCore.sftpUpload(active.sessionId, cachePath,
        this.childPath(this.uploadName));
      await this.applyResult(result, this.t('sftp.uploadDone'));
    } catch (error) {
      this.status = this.t('sftp.uploadFailed');
    } finally {
      if (cachePath.length > 0 && fs.accessSync(cachePath)) {
        fs.unlinkSync(cachePath);
      }
      this.busy = false;
    }
  }

  async downloadSelected(): Promise<void> {
    const active: TerminalTab | undefined = this.activeTab();
    if (active === undefined || this.busy || this.selectedType !== 'file') return;
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    let cachePath: string = '';
    this.busy = true;
    try {
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
      const options: picker.DocumentSaveOptions = new picker.DocumentSaveOptions();
      options.newFileNames = [this.selectedName];
      const destinationUris: Array<string> = await documentPicker.save(options);
      if (destinationUris.length === 0) return;
      cachePath = context.cacheDir + '/sftp_download_' + Date.now().toString();
      this.status = this.t('sftp.downloading');
      const result: NativeJsonResult = await NativeSshCore.sftpDownload(active.sessionId, this.selectedPath, cachePath);
      if (!result.ok) {
        this.status = this.t('sftp.downloadFailedPrefix') + result.message;
        return;
      }
      const destination: fs.File = fs.openSync(destinationUris[0], fs.OpenMode.WRITE_ONLY);
      try {
        await fs.copyFile(cachePath, destination.fd);
      } finally {
        fs.closeSync(destination);
      }
      this.status = this.t('sftp.downloadDone');
    } catch (error) {
      this.status = this.t('sftp.downloadFailed');
    } finally {
      if (cachePath.length > 0 && fs.accessSync(cachePath)) {
        fs.unlinkSync(cachePath);
      }
      this.busy = false;
    }
  }

  async createDirectory(): Promise<void> {
    const active: TerminalTab | undefined = this.activeTab();
    if (active === undefined || this.busy) return;
    if (!this.validName(this.folderName)) {
      this.status = this.t('sftp.invalidFolder');
      return;
    }
    this.busy = true;
    try {
      const result: NativeJsonResult = await NativeSshCore.sftpMkdir(active.sessionId, this.childPath(this.folderName));
      await this.applyResult(result, this.t('sftp.folderCreated'));
    } finally {
      this.busy = false;
    }
  }

  async createTextAndVerify(): Promise<void> {
    const active: TerminalTab | undefined = this.activeTab();
    if (active === undefined || this.busy) return;
    if (!this.validName(this.textFileName) || this.textContent.length === 0 || this.textContent.length > 4096) {
      this.status = this.t('sftp.invalidText');
      return;
    }
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    const token: string = Date.now().toString();
    const sourcePath: string = context.cacheDir + '/sftp_text_source_' + token;
    const verifyPath: string = context.cacheDir + '/sftp_text_verify_' + token;
    this.busy = true;
    try {
      const source: fs.File = fs.openSync(sourcePath,
        fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      try {
        fs.writeSync(source.fd, this.textContent);
      } finally {
        fs.closeSync(source);
      }
      this.status = this.t('sftp.verifying');
      const remotePath: string = this.childPath(this.textFileName);
      const uploadResult: NativeJsonResult = await NativeSshCore.sftpUpload(active.sessionId, sourcePath, remotePath);
      if (!uploadResult.ok) {
        this.status = this.t('sftp.textCreateFailedPrefix') + uploadResult.message;
        return;
      }
      const downloadResult: NativeJsonResult = await NativeSshCore.sftpDownload(active.sessionId, remotePath, verifyPath);
      if (!downloadResult.ok) {
        this.status = this.t('sftp.textReadFailedPrefix') + downloadResult.message;
        return;
      }
      const received: string = fs.readTextSync(verifyPath);
      if (received !== this.textContent) {
        this.status = this.t('sftp.textMismatch');
        return;
      }
      await this.loadList(this.currentPath);
      this.status = this.t('sftp.textVerified');
    } catch (error) {
      this.status = this.t('sftp.textException');
    } finally {
      if (fs.accessSync(sourcePath)) fs.unlinkSync(sourcePath);
      if (fs.accessSync(verifyPath)) fs.unlinkSync(verifyPath);
      this.busy = false;
    }
  }

  async renameSelected(): Promise<void> {
    const active: TerminalTab | undefined = this.activeTab();
    if (active === undefined || this.busy || this.selectedPath.length === 0) return;
    if (!this.validName(this.renameName)) {
      this.status = this.t('sftp.invalidRename');
      return;
    }
    this.busy = true;
    try {
      const result: NativeJsonResult = await NativeSshCore.sftpRename(active.sessionId, this.selectedPath,
        this.childPath(this.renameName));
      await this.applyResult(result, this.t('sftp.renamed'));
    } finally {
      this.busy = false;
    }
  }

  async removeSelected(): Promise<void> {
    const active: TerminalTab | undefined = this.activeTab();
    if (active === undefined || this.busy || this.selectedPath.length === 0) return;
    const choice = await promptAction.showDialog({
      title: this.t('sftp.confirmDelete'),
      message: this.t('sftp.confirmDeleteMessage'),
      buttons: [{ text: this.t('common.delete'), color: '#D92D20' }, { text: this.t('common.cancel'), color: '#64748B' }]
    });
    if (choice.index !== 0) return;
    this.busy = true;
    try {
      const result: NativeJsonResult = await NativeSshCore.sftpRemove(active.sessionId, this.selectedPath,
        this.selectedType === 'dir');
      await this.applyResult(result, this.t('sftp.deletedRemote'));
    } finally {
      this.busy = false;
    }
  }

  async chmodSelected(): Promise<void> {
    const active: TerminalTab | undefined = this.activeTab();
    if (active === undefined || this.busy || this.selectedPath.length === 0) return;
    if (!/^[0-7]{3,4}$/.test(this.modeText)) {
      this.status = this.t('sftp.invalidMode');
      return;
    }
    this.busy = true;
    try {
      const result: NativeJsonResult = await NativeSshCore.sftpChmod(active.sessionId, this.selectedPath,
        parseInt(this.modeText, 8));
      await this.applyResult(result, this.t('sftp.chmodDone'));
    } finally {
      this.busy = false;
    }
  }

  private selectEntry(entry: SftpEntry): void {
    this.selectedPath = entry.path;
    this.selectedName = entry.name;
    this.selectedType = entry.type;
    this.renameName = entry.name;
  }

  build() {
    Column() {
      Row() {
        Image($rawfile('ft_back.svg')).width(24).height(24).margin({ left: 10, right: 10 })
          .colorFilter(createIconColorFilter(this.textPrimary())).onClick(() => router.back())
        Text(this.t('sftp.title')).fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.textPrimary())
          .layoutWeight(1).textAlign(TextAlign.Center)
        Image($rawfile('refresh.svg')).width(24).height(24).margin({ left: 10, right: 10 })
          .colorFilter(createIconColorFilter(this.accentColor))
          .onClick(() => this.loadList(this.currentPath))
      }
      .width('100%').height(64).padding({ left: 14, right: 14, top: 8 })

      Text(this.status)
        .fontColor(this.textSecond()).fontSize(12).width('92%').maxLines(2)

      Row({ space: 8 }) {
        Button(this.t('sftp.parent')).height(36).fontSize(13).enabled(this.currentPath !== '/' && !this.busy)
          .onClick(() => {
            const cut: number = this.currentPath.lastIndexOf('/');
            this.loadList(cut <= 0 ? '/' : this.currentPath.substring(0, cut));
          })
        Text(this.currentPath).fontColor(this.accentColor).fontSize(13).layoutWeight(1).maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('92%').height(42)

      Row({ space: 8 }) {
        TextInput({ text: this.uploadName, placeholder: this.t('sftp.uploadName') })
          .height(40).fontSize(13).layoutWeight(1).onChange((value: string) => this.uploadName = value)
        Button(this.t('sftp.chooseUpload')).height(40).fontSize(13).enabled(!this.busy).onClick(() => this.upload())
      }
      .width('92%').margin({ bottom: 8 })

      Row({ space: 8 }) {
        TextInput({ text: this.folderName, placeholder: this.t('sftp.folderName') })
          .height(40).fontSize(13).layoutWeight(1).onChange((value: string) => this.folderName = value)
        Button(this.t('sftp.mkdir')).height(40).fontSize(13).enabled(!this.busy).onClick(() => this.createDirectory())
      }
      .width('92%').margin({ bottom: 8 })

      Row({ space: 8 }) {
        TextInput({ text: this.textFileName, placeholder: this.t('sftp.textFileName') })
          .height(40).fontSize(13).width(220).onChange((value: string) => this.textFileName = value)
        TextInput({ text: this.textContent, placeholder: this.t('sftp.textContent') })
          .height(40).fontSize(13).layoutWeight(1).onChange((value: string) => this.textContent = value)
        Button(this.t('sftp.createVerify')).height(40).fontSize(12).enabled(!this.busy)
          .onClick(() => this.createTextAndVerify())
      }
      .width('92%').margin({ bottom: 8 })

      if (this.selectedPath.length > 0) {
        Column({ space: 7 }) {
          Text(this.t('sftp.selected') + this.selectedName).fontSize(13).fontColor(this.textPrimary()).width('100%').maxLines(1)
          Row({ space: 7 }) {
            TextInput({ text: this.renameName, placeholder: this.t('sftp.newName') }).height(36).fontSize(12).layoutWeight(1)
              .onChange((value: string) => this.renameName = value)
            Button(this.t('sftp.rename')).height(36).fontSize(12).enabled(!this.busy).onClick(() => this.renameSelected())
            if (this.selectedType === 'file') {
              Button(this.t('sftp.download')).height(36).fontSize(12).enabled(!this.busy).onClick(() => this.downloadSelected())
            }
          }
          Row({ space: 7 }) {
            TextInput({ text: this.modeText, placeholder: '644' }).height(36).fontSize(12).width(88)
              .type(InputType.Number).onChange((value: string) => this.modeText = value)
            Button(this.t('sftp.mode')).height(36).fontSize(12).enabled(!this.busy).onClick(() => this.chmodSelected())
            Button(this.t('common.delete')).height(36).fontSize(12).enabled(!this.busy).backgroundColor('#D92D20')
              .onClick(() => this.removeSelected())
            Blank()
            Button(this.t('sftp.cancelSelect')).height(36).fontSize(12).onClick(() => this.clearSelection())
          }
        }
        .width('92%').padding(10).backgroundColor(this.cardBg()).borderRadius(14).margin({ bottom: 8 })
      }

      List() {
        ForEach(this.entries, (entry: SftpEntry) => {
          ListItem() {
            Row() {
              Image(entry.type === 'dir' ? $rawfile('ft_folder.svg') : $rawfile('ft_file.svg'))
                .width(22).height(22).colorFilter(createIconColorFilter(this.accentColor))
              Column({ space: 2 }) {
                Text(entry.name).fontColor(this.textPrimary()).fontSize(15).maxLines(1)
                Text(entry.size.toString() + this.t('sftp.bytes')).fontColor(this.textSecond()).fontSize(11)
              }
              .margin({ left: 10 }).alignItems(HorizontalAlign.Start).layoutWeight(1)
              Image(entry.type === 'dir' ? $rawfile('ft_up.svg') : $rawfile('settings_tune.svg'))
                .width(19).height(19).rotate({ angle: entry.type === 'dir' ? 90 : 0 })
                .colorFilter(createIconColorFilter('#94A3B8')).margin({ left: 9, right: 10 })
                .onClick(() => this.selectEntry(entry))
            }
            .padding(10).width('100%').backgroundColor(this.cardBg()).borderRadius(12)
            .onClick(() => {
              if (entry.type === 'dir') {
                this.clearSelection();
                this.loadList(entry.path);
              } else {
                this.selectEntry(entry);
              }
            })
          }
          .margin({ left: 16, right: 16, bottom: 8 })
        }, (entry: SftpEntry) => entry.path)
      }
      .layoutWeight(1).width('100%')
    }
    .width('100%').height('100%').alignItems(HorizontalAlign.Center).backgroundColor(this.pageBg())
    .padding({ top: this.avoidStatusBarHeight, bottom: this.avoidNavigationBarHeight })
  }
}
