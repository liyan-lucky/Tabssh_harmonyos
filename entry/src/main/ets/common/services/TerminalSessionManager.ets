import { ConnectionProfile } from '../models/ConnectionProfile';
import { HostKeyDetails, TerminalTab } from '../models/TerminalModels';
import { NativeSshCore, NativeJsonResult } from '../native/NativeSshCore';

class TerminalSessionManagerImpl {
  private tabs: TerminalTab[] = [];

  createTab(profile: ConnectionProfile): TerminalTab {
    const sessionId: string = NativeSshCore.createSession(profile);
    const tab: TerminalTab = {
      id: 'tab-' + new Date().getTime().toString(),
      title: profile.name,
      profileId: profile.id,
      sessionId: sessionId,
      channelId: '',
      connected: false,
      statusCode: 0,
      statusMessage: '正在连接并校验 HostKey…',
      pendingHostKey: '',
      hostKeyAlgorithm: '',
      buffer: '',
      cols: 80,
      rows: 24
    };
    this.tabs.push(tab);
    return tab;
  }

  async connectTab(tabId: string): Promise<TerminalTab | undefined> {
    const initialTab: TerminalTab | undefined = this.getTab(tabId);
    if (initialTab === undefined) {
      return undefined;
    }
    const sessionId: string = initialTab.sessionId;
    const connectResult: NativeJsonResult = await NativeSshCore.connect(sessionId);
    const tab: TerminalTab | undefined = this.getTab(tabId);
    if (tab === undefined || tab.sessionId !== sessionId) {
      return undefined;
    }
    const hostKey: HostKeyDetails = this.parseHostKey(connectResult.data);
    tab.statusCode = connectResult.code;
    tab.statusMessage = connectResult.message;
    tab.pendingHostKey = hostKey.fingerprint;
    tab.hostKeyAlgorithm = hostKey.algorithm;
    if (!connectResult.ok) {
      return tab;
    }
    const channelId: string = await NativeSshCore.openShell(sessionId);
    const current: TerminalTab | undefined = this.getTab(tabId);
    if (current === undefined || current.sessionId !== sessionId) {
      return undefined;
    }
    if (channelId.length === 0) {
      current.statusCode = -1;
      current.statusMessage = 'shell / PTY 打开失败';
      return current;
    }
    current.channelId = channelId;
    current.connected = true;
    current.statusCode = 0;
    current.statusMessage = 'SSH authenticated and PTY opened';
    current.pendingHostKey = '';
    current.buffer += NativeSshCore.read(channelId).data;
    return current;
  }

  private parseHostKey(raw: string): HostKeyDetails {
    if (raw.length === 0) {
      return { fingerprint: '', algorithm: '' };
    }
    try {
      return JSON.parse(raw) as HostKeyDetails;
    } catch (error) {
      return { fingerprint: '', algorithm: '' };
    }
  }

  async confirmHostKey(tabId: string, fingerprint: string): Promise<TerminalTab | undefined> {
    const tab: TerminalTab | undefined = this.getTab(tabId);
    if (tab === undefined) {
      return undefined;
    }
    const confirmation: NativeJsonResult = NativeSshCore.confirmHostKey(tab.sessionId, fingerprint);
    if (!confirmation.ok) {
      tab.statusCode = confirmation.code;
      tab.statusMessage = confirmation.message;
      return tab;
    }
    tab.statusMessage = 'HostKey 已确认，正在认证并打开 PTY…';
    return await this.connectTab(tabId);
  }

  listTabs(): TerminalTab[] {
    return this.tabs;
  }

  getTab(tabId: string): TerminalTab | undefined {
    return this.tabs.find((item: TerminalTab) => item.id === tabId);
  }

  write(tabId: string, command: string): TerminalTab | undefined {
    return this.writeRaw(tabId, command + '\n');
  }

  writeRaw(tabId: string, data: string): TerminalTab | undefined {
    const tab: TerminalTab | undefined = this.getTab(tabId);
    if (tab === undefined) {
      return undefined;
    }
    if (!tab.connected || tab.channelId.length === 0) {
      return tab;
    }
    NativeSshCore.write(tab.channelId, data);
    const readResult: NativeJsonResult = NativeSshCore.read(tab.channelId);
    tab.buffer += readResult.data;
    return tab;
  }

  poll(tabId: string): TerminalTab | undefined {
    const tab: TerminalTab | undefined = this.getTab(tabId);
    if (tab === undefined || !tab.connected || tab.channelId.length === 0) {
      return tab;
    }
    const readResult: NativeJsonResult = NativeSshCore.read(tab.channelId);
    if (readResult.ok && readResult.data.length > 0) {
      tab.buffer += readResult.data;
    }
    return tab;
  }

  resize(tabId: string, cols: number, rows: number): void {
    const tab: TerminalTab | undefined = this.getTab(tabId);
    if (tab === undefined) {
      return;
    }
    tab.cols = cols;
    tab.rows = rows;
    NativeSshCore.resize(tab.channelId, cols, rows);
  }

  close(tabId: string): void {
    const tab: TerminalTab | undefined = this.getTab(tabId);
    if (tab !== undefined) {
      if (tab.channelId.length > 0) {
        NativeSshCore.closeChannel(tab.channelId);
      }
      NativeSshCore.disconnect(tab.sessionId);
    }
    this.tabs = this.tabs.filter((item: TerminalTab) => item.id !== tabId);
  }

  closeAll(): void {
    const tabIds: string[] = this.tabs.map((item: TerminalTab) => item.id);
    tabIds.forEach((tabId: string) => this.close(tabId));
  }
}

export const TerminalSessionManager: TerminalSessionManagerImpl = new TerminalSessionManagerImpl();
