import router from '@ohos.router';
import { ConnectionProfile } from '../common/models/ConnectionProfile';
import { ProfileRepository } from '../common/storage/ProfileRepository';
import { TerminalTab } from '../common/models/TerminalModels';
import { TerminalSessionManager } from '../common/services/TerminalSessionManager';
import { NativeSshCore } from '../common/native/NativeSshCore';
import { TerminalEmulator } from '../common/terminal/TerminalEmulator';

@Entry
@Component
struct TerminalPage {
  @State tabId: string = '';
  @State title: string = '终端';
  @State terminalText: string = '';
  @State command: string = '';
  @State status: string = '未连接';
  private activeProfile: ConnectionProfile | undefined = undefined;
  private emulator: TerminalEmulator = new TerminalEmulator(80, 24);
  private consumedLength: number = 0;
  private pollTimer: number = -1;
  private pollInFlight: boolean = false;
  private writeInFlight: boolean = false;
  private preserveSessionOnNavigation: boolean = false;

  aboutToAppear(): void {
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
    }
    if (tab.connected) {
      this.status = NativeSshCore.version().indexOf('mock') >= 0 ? 'Mock 已连接（非真实 SSH）' : 'SSH 已认证 / PTY 已打开';
    } else {
      this.status = '未连接 [' + tab.statusCode.toString() + '] ' + tab.statusMessage;
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
    if (this.preserveSessionOnNavigation) {
      this.preserveSessionOnNavigation = false;
      return;
    }
    if (this.tabId.length > 0) {
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
        if (updated.connected && this.activeProfile !== undefined) {
          this.activeProfile.hostKeyFingerprint = acceptedFingerprint;
          ProfileRepository.save(this.activeProfile);
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
      const updated: TerminalTab | undefined = await TerminalSessionManager.write(requestedTabId, command);
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

  closeAndBack(): void {
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
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#111827')

      Scroll() {
        Text(this.terminalText)
          .fontFamily('monospace')
          .fontSize(14)
          .fontColor('#D1FAE5')
          .width('100%')
          .padding(12)
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor('#020617')

      Row() {
        Button('Ctrl-C').onClick(() => this.sendControl('\u0003'))
        Button('Ctrl-D').onClick(() => this.sendControl('\u0004')).margin({ left: 4 })
        Button('Esc').onClick(() => this.sendControl('\u001b')).margin({ left: 4 })
        Button('Tab').onClick(() => this.sendControl('\t')).margin({ left: 4 })
        Button('↑').onClick(() => this.sendControl('\u001b[A')).margin({ left: 4 })
        Button('↓').onClick(() => this.sendControl('\u001b[B')).margin({ left: 4 })
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 6 })
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
