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

@Entry
@Component
struct TerminalPage {
  @State tabId: string = '';
  @State title: string = '终端';
  @State terminalText: string = '';
  @State terminalLines: TerminalRenderLine[] = [];
  @State command: string = '';
  @State status: string = '未连接';
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

  aboutToAppear(): void {
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
      this.terminalText = '没有连接配置，请先返回首页新建连接。';
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
      this.status = '连接任务异常，已安全停止';
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
      this.status = NativeSshCore.version().indexOf('mock') >= 0 ? 'Mock 已连接（非真实 SSH）' : 'SSH 已认证 / PTY 已打开';
      this.flushTerminalResize();
    } else {
      this.status = '未连接 [' + tab.statusCode.toString() + '] ' + tab.statusMessage;
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
      this.status = '网络不可用，已暂停重连；网络恢复后立即重试';
      return;
    }
    const attempt: number = tab.reconnectAttempt + 1;
    tab.reconnectAttempt = attempt;
    const exponent: number = Math.min(attempt - 1, 6);
    const delayMilliseconds: number = Math.min(5000 * Math.pow(2, exponent), 300000);
    this.status = '连接中断，' + (delayMilliseconds / 1000).toString() + ' 秒后第 ' + attempt.toString() + ' 次重连';
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
      this.status = '网络不可用，等待恢复后重连';
      return;
    }
    const requestedTabId: string = this.tabId;
    const tab: TerminalTab | undefined = TerminalSessionManager.getTab(requestedTabId);
    if (tab === undefined || !this.retryable(tab)) return;
    this.reconnectInFlight = true;
    this.status = '正在重连并重新校验 HostKey…';
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
        current.statusMessage = '重连任务异常';
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
        this.status = '网络不可用，已暂停重连；网络恢复后立即重试';
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
        this.status = '终端读取异常';
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
      title: changed ? '警告：服务器 HostKey 已变化' : '首次连接：确认 HostKey',
      message: (changed ? '这可能表示服务器重装，也可能是中间人攻击。仅在你通过可信渠道核对后继续。\n\n' :
        '认证前必须核对服务器指纹。\n\n') + tab.hostKeyAlgorithm + '\n' + tab.pendingHostKey,
      primaryButton: {
        value: '取消连接',
        action: () => {
          this.intentionalClose = true;
          this.cancelReconnectTimer();
          TerminalSessionManager.close(tab.id);
          this.status = '已取消：HostKey 未确认';
        }
      },
      secondaryButton: {
        value: changed ? '我已核对，替换' : '我已核对，信任',
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
      this.status = 'HostKey 确认后的认证任务异常';
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
      this.status = '终端写入异常';
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
      this.status = '控制键发送异常';
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
      this.status = '终端协议回复发送异常';
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
      if (this.tabId === requestedTabId) this.status = 'PTY 尺寸同步异常';
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
        Button('关闭').onClick(() => this.closeAndBack())
        Column() {
          Text(this.title)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Text(this.status)
            .fontSize(12)
            .fontColor('#38BDF8')
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
        .layoutWeight(1)
        Button('SFTP')
          .enabled(this.tabId.length > 0)
          .onClick(() => this.openSftp())
        if (this.canReconnectNow()) {
          Button('立即重连').margin({ left: 6 }).onClick(() => this.reconnectNow())
        }
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#111827')

      Scroll() {
        this.terminalOutput()
      }
      .layoutWeight(1)
      .width('100%')
      .padding(12)
      .backgroundColor('#020617')
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
      .backgroundColor('#111827')

      Row() {
        TextInput({ text: this.command, placeholder: '输入命令，例如 ls -la' })
          .layoutWeight(1)
          .onChange((value: string) => this.command = value)
          .onSubmit(() => this.sendCommand())
        Button('发送')
          .margin({ left: 8 })
          .onClick(() => this.sendCommand())
      }
      .padding(10)
      .backgroundColor('#111827')
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#020617')
  }
}
