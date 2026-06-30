import router from '@ohos.router';
import { ConnectionProfile } from '../common/models/ConnectionProfile';
import { ProfileRepository } from '../common/storage/ProfileRepository';
import { TerminalTab } from '../common/models/TerminalModels';
import { TerminalSessionManager } from '../common/services/TerminalSessionManager';
import { createIconColorFilter } from '../common/IconUtils';
import { NativeSshCore } from '../common/native/NativeSshCore';
import { TerminalEmulator, TerminalRenderLine, TerminalRenderRun } from '../common/terminal/TerminalEmulator';
import connection from '@ohos.net.connection';
import { BusinessError } from '@ohos.base';
import { LANG_EN, LANG_ZH, THEME_LIGHT } from '../common/AppSettings';
import { AppTheme } from '../common/AppTheme';
import { I18n } from '../common/I18n';

@Entry
@Component
struct TerminalPage {
  @State tabId: string = '';
  @State title: string = '';
  @State terminalText: string = '';
  @State terminalLines: TerminalRenderLine[] = [];
  @State command: string = '';
  @State status: string = '';
  @StorageProp('avoidStatusBarHeight') avoidStatusBarHeight: number = 0;
  @StorageProp('avoidNavigationBarHeight') avoidNavigationBarHeight: number = 0;
  @StorageLink('appThemeMode') themeMode: string = THEME_LIGHT;
  @StorageLink('appLanguage') language: string = LANG_ZH;
  private activeProfile: ConnectionProfile | undefined = undefined;
  private emulator: TerminalEmulator = new TerminalEmulator(80, 24);
  private consumedLength: number = 0;
  private pollTimer: number = -1;
  private pollInFlight: boolean = false;
  private writeInFlight: boolean = false;
  private responseInFlight: boolean = false;
  private pendingResponses: string = '';
  private resizeInFlight: boolean = false;
  private pendingColumns: number = 80;
  private pendingRows: number = 24;
  private preserveSessionOnNavigation: boolean = false;
  private reconnectTimer: number = -1;
  private reconnectInFlight: boolean = false;
  private intentionalClose: boolean = false;
  private networkAvailable: boolean = true;
  private networkObserver: connection.NetConnection | undefined = undefined;
  private networkPollTimer: number = -1;

  private t(key: string): string {
    return I18n.t(this.language, key);
  }

  private textPrimary(): string {
    return AppTheme.textPrimary(this.themeMode);
  }

  private headerBg(): string {
    return AppTheme.isDark(this.themeMode) ? '#111827' : '#FFFFFF';
  }

  private shellBg(): string {
    return AppTheme.isDark(this.themeMode) ? '#020617' : '#07111F';
  }

  private controlBg(): string {
    return AppTheme.isDark(this.themeMode) ? '#111827' : '#162033';
  }

  private displayTitle(): string {
    return this.title.length > 0 ? this.title : this.t('terminal.title');
  }

  private reconnectMessage(delayMilliseconds: number, attempt: number): string {
    const seconds: string = (delayMilliseconds / 1000).toString();
    if (this.language === LANG_EN) {
      return this.t('terminal.reconnectInPrefix') + attempt.toString() +
        this.t('terminal.reconnectInMiddle') + seconds + this.t('terminal.reconnectInSuffix');
    }
    return this.t('terminal.reconnectInPrefix') + seconds + this.t('terminal.reconnectInMiddle') +
      attempt.toString() + this.t('terminal.reconnectInSuffix');
  }

  aboutToAppear(): void {
    if (this.status.length === 0) {
      this.status = this.t('terminal.notConnected');
    }
    this.startNetworkMonitoring();
    if (this.tabId.length > 0) {
      const existing: TerminalTab | undefined = TerminalSessionManager.getTab(this.tabId);
      if (existing !== undefined) {
        this.updateFromTab(existing);
        this.startPolling();
        return;
      }
    }
    const params = router.getParams() as Record<string, string>;
    let profile: ConnectionProfile | undefined = undefined;
    if (params !== undefined && params['profileId'] !== undefined) {
      profile = ProfileRepository.get(params['profileId']);
    }
    if (profile === undefined) {
      const list: ConnectionProfile[] = ProfileRepository.list();
      if (list.length > 0) {
        profile = list[0];
      }
    }
    if (profile !== undefined) {
      this.activeProfile = profile;
      const tab: TerminalTab = TerminalSessionManager.createTab(profile);
      this.tabId = tab.id;
      this.title = tab.title;
      this.terminalText = tab.buffer;
      this.updateFromTab(tab);
      this.startPolling();
      this.finishInitialConnection(tab.id);
    } else {
      this.terminalText = this.t('terminal.noProfile');
    }
  }

  async finishInitialConnection(tabId: string): Promise<void> {
    try {
      const updated: TerminalTab | undefined = await TerminalSessionManager.connectTab(tabId);
      if (updated === undefined) {
        return;
      }
      this.updateFromTab(updated);
      if (!updated.connected && (updated.statusCode === 1001 || updated.statusCode === 1002) &&
        updated.pendingHostKey.length > 0) {
        this.showHostKeyConfirmation(updated);
      }
    } catch (error) {
      this.status = this.t('terminal.connectTaskError');
    }
  }

  startPolling(): void {
    if (this.pollTimer < 0) {
      this.pollTimer = setInterval(() => this.pollOutput(), 120);
    }
  }

  updateFromTab(tab: TerminalTab): void {
    if (tab.buffer.length > this.consumedLength) {
      this.emulator.consume(tab.buffer.substring(this.consumedLength));
      this.consumedLength = tab.buffer.length;
      this.terminalText = this.emulator.render();
      this.terminalLines = this.emulator.renderLines();
      const terminalTitle: string = this.emulator.getTitle();
      this.title = terminalTitle.length > 0 ? terminalTitle : tab.title;
      const responses: string = this.emulator.drainResponses();
      if (responses.length > 0) {
        this.pendingResponses += responses;
        this.flushEmulatorResponses();
      }
    }
    if (tab.connected) {
      this.cancelReconnectTimer();
      tab.reconnectAttempt = 0;
      this.status = NativeSshCore.version().indexOf('mock') >= 0 ? this.t('terminal.mockConnected') : this.t('terminal.sshReady');
      this.flushTerminalResize();
    } else {
      this.status = this.t('terminal.disconnectedPrefix') + ' [' + tab.statusCode.toString() + '] ' + tab.statusMessage;
      this.scheduleReconnect(tab);
    }
  }

  private retryable(tab: TerminalTab): boolean {
    if (!tab.everConnected || this.intentionalClose || tab.connected || tab.reconnecting) return false;
    return tab.statusCode !== 1001 && tab.statusCode !== 1002 && tab.statusCode !== 1003 &&
      tab.statusCode !== 1005 && tab.statusCode !== 1008;
  }

  private scheduleReconnect(tab: TerminalTab): void {
    if (!this.retryable(tab) || this.reconnectTimer >= 0 || this.reconnectInFlight) return;
    if (!this.networkAvailable) {
      this.status = this.t('terminal.networkPaused');
      return;
    }
    const attempt: number = tab.reconnectAttempt + 1;
    tab.reconnectAttempt = attempt;
    const exponent: number = Math.min(attempt - 1, 6);
    const delayMilliseconds: number = Math.min(5000 * Math.pow(2, exponent), 300000);
    this.status = this.reconnectMessage(delayMilliseconds, attempt);
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = -1;
      this.performReconnect();
    }, delayMilliseconds);
  }

  private cancelReconnectTimer(): void {
    if (this.reconnectTimer >= 0) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = -1;
    }
  }

  private async performReconnect(): Promise<void> {
    if (this.intentionalClose || this.reconnectInFlight || this.tabId.length === 0) return;
    if (!this.networkAvailable) {
      this.status = this.t('terminal.networkWait');
      return;
    }
    const requestedTabId: string = this.tabId;
    const tab: TerminalTab | undefined = TerminalSessionManager.getTab(requestedTabId);
    if (tab === undefined || !this.retryable(tab)) return;
    this.reconnectInFlight = true;
    this.status = this.t('terminal.reconnectChecking');
    try {
      const updated: TerminalTab | undefined = await TerminalSessionManager.reconnectTab(requestedTabId);
      if (updated === undefined || this.tabId !== requestedTabId || this.intentionalClose) return;
      this.updateFromTab(updated);
      if (!updated.connected && (updated.statusCode === 1001 || updated.statusCode === 1002) &&
        updated.pendingHostKey.length > 0) {
        this.showHostKeyConfirmation(updated);
      }
    } catch (error) {
      const current: TerminalTab | undefined = TerminalSessionManager.getTab(requestedTabId);
      if (current !== undefined) {
        current.reconnecting = false;
        current.statusCode = 1007;
        current.statusMessage = this.t('terminal.reconnectTaskError');
        this.updateFromTab(current);
      }
    } finally {
      this.reconnectInFlight = false;
      const current: TerminalTab | undefined = TerminalSessionManager.getTab(requestedTabId);
      if (current !== undefined && !current.connected) this.scheduleReconnect(current);
    }
  }

  private reconnectNow(): void {
    const tab: TerminalTab | undefined = TerminalSessionManager.getTab(this.tabId);
    if (tab === undefined || !tab.everConnected || tab.statusCode === 1008) return;
    this.cancelReconnectTimer();
    tab.reconnectAttempt = 0;
    tab.reconnecting = false;
    this.performReconnect();
  }

  private canReconnectNow(): boolean {
    const tab: TerminalTab | undefined = TerminalSessionManager.getTab(this.tabId);
    return tab !== undefined && this.retryable(tab);
  }

  private startNetworkMonitoring(): void {
    if (this.networkObserver === undefined) {
      const observer: connection.NetConnection = connection.createNetConnection();
      observer.on('netAvailable', (_handle: connection.NetHandle) => {
        this.setNetworkAvailability(true);
      });
      observer.on('netLost', (_handle: connection.NetHandle) => {
        this.refreshNetworkAvailability();
      });
      observer.on('netUnavailable', () => {
        this.setNetworkAvailability(false);
      });
      observer.register((_error: BusinessError) => {
        this.refreshNetworkAvailability();
      });
      this.networkObserver = observer;
    }
    this.refreshNetworkAvailability();
    if (this.networkPollTimer < 0) {
      this.networkPollTimer = setInterval(() => this.refreshNetworkAvailability(), 300000);
    }
  }

  private stopNetworkMonitoring(): void {
    if (this.networkPollTimer >= 0) {
      clearInterval(this.networkPollTimer);
      this.networkPollTimer = -1;
    }
    const observer: connection.NetConnection | undefined = this.networkObserver;
    this.networkObserver = undefined;
    if (observer !== undefined) {
      observer.unregister((_error: BusinessError) => {
      });
    }
  }

  private async refreshNetworkAvailability(): Promise<void> {
    try {
      this.setNetworkAvailability(await connection.hasDefaultNet());
    } catch (error) {
      this.networkAvailable = true;
    }
  }

  private setNetworkAvailability(available: boolean): void {
    const restored: boolean = !this.networkAvailable && available;
    this.networkAvailable = available;
    const tab: TerminalTab | undefined = TerminalSessionManager.getTab(this.tabId);
    if (!available) {
      this.cancelReconnectTimer();
      if (tab !== undefined && this.retryable(tab)) {
        this.status = this.t('terminal.networkPaused');
      }
      return;
    }
    if (restored && tab !== undefined && this.retryable(tab)) {
      this.cancelReconnectTimer();
      tab.reconnectAttempt = 0;
      this.performReconnect();
    }
  }

  async pollOutput(): Promise<void> {
    if (this.tabId.length === 0 || this.pollInFlight) {
      return;
    }
    const requestedTabId: string = this.tabId;
    this.pollInFlight = true;
    try {
      const updated: TerminalTab | undefined = await TerminalSessionManager.poll(requestedTabId);
      if (updated !== undefined && this.tabId === requestedTabId) {
        this.updateFromTab(updated);
      }
    } catch (error) {
      if (this.tabId === requestedTabId) {
        this.status = this.t('terminal.readError');
      }
    } finally {
      this.pollInFlight = false;
    }
  }

  aboutToDisappear(): void {
    if (this.pollTimer >= 0) {
      clearInterval(this.pollTimer);
      this.pollTimer = -1;
    }
    this.cancelReconnectTimer();
    this.stopNetworkMonitoring();
    if (this.preserveSessionOnNavigation) {
      this.preserveSessionOnNavigation = false;
      return;
    }
    if (this.tabId.length > 0) {
      this.intentionalClose = true;
      TerminalSessionManager.close(this.tabId);
      this.tabId = '';
    }
  }

  openSftp(): void {
    if (this.tabId.length === 0) {
      return;
    }
    this.preserveSessionOnNavigation = true;
    router.pushUrl({ url: 'pages/SftpPage', params: { tabId: this.tabId } });
  }

  showHostKeyConfirmation(tab: TerminalTab): void {
    const changed: boolean = tab.statusCode === 1002;
    AlertDialog.show({
      title: changed ? this.t('terminal.hostKeyChangedTitle') : this.t('terminal.hostKeyFirstTitle'),
      message: (changed ? this.t('terminal.hostKeyChangedMessage') + '\n\n' :
        this.t('terminal.hostKeyFirstMessage') + '\n\n') + tab.hostKeyAlgorithm + '\n' + tab.pendingHostKey,
      primaryButton: {
        value: this.t('terminal.cancelConnection'),
        action: () => {
          this.intentionalClose = true;
          this.cancelReconnectTimer();
          TerminalSessionManager.close(tab.id);
          this.status = this.t('terminal.canceledHostKey');
        }
      },
      secondaryButton: {
        value: changed ? this.t('terminal.trustReplace') : this.t('terminal.trust'),
        fontColor: changed ? '#EF4444' : '#38BDF8',
        action: () => {
          this.acceptHostKey(tab);
        }
      }
    });
  }

  async acceptHostKey(tab: TerminalTab): Promise<void> {
    const acceptedFingerprint: string = tab.pendingHostKey;
    try {
      const updated: TerminalTab | undefined = await TerminalSessionManager.confirmHostKey(tab.id,
        acceptedFingerprint);
      if (updated !== undefined) {
        this.updateFromTab(updated);
        if (updated.connected) {
          const profile: ConnectionProfile | undefined = ProfileRepository.get(updated.profileId);
          if (profile !== undefined) {
            profile.hostKeyFingerprint = acceptedFingerprint;
            ProfileRepository.save(profile);
          }
        }
      }
    } catch (error) {
      this.status = this.t('terminal.hostKeyConfirmError');
    }
  }

  async sendCommand(): Promise<void> {
    if (this.command.trim().length === 0 || this.writeInFlight) {
      return;
    }
    const command: string = this.command;
    const requestedTabId: string = this.tabId;
    this.command = '';
    this.writeInFlight = true;
    try {
      const updated: TerminalTab | undefined = this.emulator.isBracketedPasteEnabled() ?
        await TerminalSessionManager.writeRaw(requestedTabId, '\u001b[200~' + command + '\u001b[201~\r') :
        await TerminalSessionManager.write(requestedTabId, command);
      if (updated !== undefined && this.tabId === requestedTabId) {
        this.updateFromTab(updated);
      }
    } catch (error) {
      this.status = this.t('terminal.writeError');
    } finally {
      this.writeInFlight = false;
    }
  }

  async sendControl(sequence: string): Promise<void> {
    if (this.writeInFlight) {
      return;
    }
    const requestedTabId: string = this.tabId;
    this.writeInFlight = true;
    try {
      const updated: TerminalTab | undefined = await TerminalSessionManager.writeRaw(requestedTabId, sequence);
      if (updated !== undefined && this.tabId === requestedTabId) {
        this.updateFromTab(updated);
      }
    } catch (error) {
      this.status = this.t('terminal.controlError');
    } finally {
      this.writeInFlight = false;
    }
  }

  private async flushEmulatorResponses(): Promise<void> {
    if (this.responseInFlight || this.pendingResponses.length === 0 || this.tabId.length === 0) return;
    const requestedTabId: string = this.tabId;
    const responses: string = this.pendingResponses;
    this.pendingResponses = '';
    this.responseInFlight = true;
    try {
      const updated: TerminalTab | undefined = await TerminalSessionManager.writeRaw(requestedTabId, responses);
      if (updated !== undefined && this.tabId === requestedTabId) this.updateFromTab(updated);
    } catch (error) {
      this.status = this.t('terminal.responseError');
    } finally {
      this.responseInFlight = false;
      if (this.pendingResponses.length > 0) this.flushEmulatorResponses();
    }
  }

  private sendCursorKey(key: string): void {
    const prefix: string = this.emulator.isApplicationCursorKeysEnabled() ? '\u001bO' : '\u001b[';
    this.sendControl(prefix + key);
  }

  private updateTerminalSize(width: number, height: number): void {
    if (width <= 0 || height <= 0) return;
    const columns: number = Math.max(20, Math.min(300, Math.floor(width / 8.4)));
    const rows: number = Math.max(5, Math.min(120, Math.floor(height / 19.6)));
    if (columns === this.pendingColumns && rows === this.pendingRows) return;
    this.pendingColumns = columns;
    this.pendingRows = rows;
    this.emulator.resize(columns, rows);
    this.terminalText = this.emulator.render();
    this.terminalLines = this.emulator.renderLines();
    this.flushTerminalResize();
  }

  private async flushTerminalResize(): Promise<void> {
    if (this.resizeInFlight || this.tabId.length === 0) return;
    const tab: TerminalTab | undefined = TerminalSessionManager.getTab(this.tabId);
    if (tab === undefined || !tab.connected ||
      (tab.cols === this.pendingColumns && tab.rows === this.pendingRows)) return;
    const requestedTabId: string = this.tabId;
    const columns: number = this.pendingColumns;
    const rows: number = this.pendingRows;
    let succeeded: boolean = false;
    this.resizeInFlight = true;
    try {
      await TerminalSessionManager.resize(requestedTabId, columns, rows);
      succeeded = true;
    } catch (error) {
      if (this.tabId === requestedTabId) this.status = this.t('terminal.resizeError');
    } finally {
      this.resizeInFlight = false;
      const current: TerminalTab | undefined = TerminalSessionManager.getTab(requestedTabId);
      if (succeeded && current !== undefined &&
        (current.cols !== this.pendingColumns || current.rows !== this.pendingRows)) {
        this.flushTerminalResize();
      }
    }
  }

  @Builder
  terminalOutput() {
    if (this.terminalLines.length === 0) {
      Text(this.terminalText)
        .fontFamily('monospace')
        .fontSize(14)
        .fontColor('#D1FAE5')
        .copyOption(CopyOptions.LocalDevice)
    } else {
      Text() {
        ForEach(this.terminalLines, (line: TerminalRenderLine, lineIndex: number) => {
          ForEach(line.runs, (run: TerminalRenderRun) => {
            Span(run.text)
              .fontColor(run.foreground)
              .fontWeight(run.bold ? FontWeight.Bold : FontWeight.Normal)
              .fontStyle(run.italic ? FontStyle.Italic : FontStyle.Normal)
              .decoration({
                type: run.underline ? TextDecorationType.Underline :
                  (run.strikeThrough ? TextDecorationType.LineThrough : TextDecorationType.None)
              })
              .textBackgroundStyle({ color: run.background })
              .opacity(run.dim ? 0.68 : 1.0)
          })
          if (lineIndex < this.terminalLines.length - 1) {
            Span('\n')
          }
        })
      }
      .fontFamily('monospace')
      .fontSize(14)
      .copyOption(CopyOptions.LocalDevice)
    }
  }

  closeAndBack(): void {
    this.intentionalClose = true;
    this.cancelReconnectTimer();
    if (this.tabId.length > 0) {
      TerminalSessionManager.close(this.tabId);
      this.tabId = '';
    }
    router.back();
  }

  build() {
    Column() {
      Row() {
        Button(this.t('common.close')).onClick(() => this.closeAndBack())
        Column() {
          Text(this.displayTitle())
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textPrimary())
          Text(this.status)
            .fontSize(12)
            .fontColor('#38BDF8')
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
        .layoutWeight(1)
        Button(this.t('terminal.sftp'))
          .enabled(this.tabId.length > 0)
          .onClick(() => this.openSftp())
        if (this.canReconnectNow()) {
          Button(this.t('terminal.reconnectNow')).margin({ left: 6 }).onClick(() => this.reconnectNow())
        }
      }
      .width('100%')
      .padding(12)
      .backgroundColor(this.headerBg())

      Scroll() {
        this.terminalOutput()
      }
      .layoutWeight(1)
      .width('100%')
      .padding(12)
      .backgroundColor(this.shellBg())
      .onAreaChange((_oldValue, newValue) => {
        this.updateTerminalSize(Number(newValue.width), Number(newValue.height));
      })

      Scroll() {
        Row() {
          Button('Ctrl-C').onClick(() => this.sendControl('\u0003'))
          Button('Ctrl-D').onClick(() => this.sendControl('\u0004')).margin({ left: 4 })
          Button('Esc').onClick(() => this.sendControl('\u001b')).margin({ left: 4 })
          Button('Tab').onClick(() => this.sendControl('\t')).margin({ left: 4 })
          Button('Home').onClick(() => this.sendCursorKey('H')).margin({ left: 4 })
          Button() {
            Image($rawfile('ft_up.svg')).width(18).height(18).rotate({ angle: -90 })
              .colorFilter(createIconColorFilter('#FFFFFF'))
          }
          .onClick(() => this.sendCursorKey('D')).margin({ left: 4 })
          Button() {
            Image($rawfile('ft_up.svg')).width(18).height(18).colorFilter(createIconColorFilter('#FFFFFF'))
          }
          .onClick(() => this.sendCursorKey('A')).margin({ left: 4 })
          Button() {
            Image($rawfile('ft_up.svg')).width(18).height(18).rotate({ angle: 180 })
              .colorFilter(createIconColorFilter('#FFFFFF'))
          }
          .onClick(() => this.sendCursorKey('B')).margin({ left: 4 })
          Button() {
            Image($rawfile('ft_up.svg')).width(18).height(18).rotate({ angle: 90 })
              .colorFilter(createIconColorFilter('#FFFFFF'))
          }
          .onClick(() => this.sendCursorKey('C')).margin({ left: 4 })
          Button('End').onClick(() => this.sendCursorKey('F')).margin({ left: 4 })
        }
        .padding({ left: 10, right: 10, top: 6 })
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .backgroundColor(this.controlBg())

      Row() {
        TextInput({ text: this.command, placeholder: this.t('terminal.inputPlaceholder') })
          .layoutWeight(1)
          .onChange((value: string) => this.command = value)
          .onSubmit(() => this.sendCommand())
        Button(this.t('common.send'))
          .margin({ left: 8 })
          .onClick(() => this.sendCommand())
      }
      .padding(10)
      .backgroundColor(this.controlBg())
    }
    .height('100%')
    .width('100%')
    .padding({ top: this.avoidStatusBarHeight, bottom: this.avoidNavigationBarHeight })
    .backgroundColor(this.shellBg())
  }
}
