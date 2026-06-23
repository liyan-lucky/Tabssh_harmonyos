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
    const initialRead: NativeJsonResult = await NativeSshCore.read(channelId);
    current.buffer += initialRead.data;
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

  async write(tabId: string, command: string): Promise<TerminalTab | undefined> {
    return await this.writeRaw(tabId, command + '\r');
  }

  async writeRaw(tabId: string, data: string): Promise<TerminalTab | undefined> {
    const tab: TerminalTab | undefined = this.getTab(tabId);
    if (tab === undefined) {
      return undefined;
    }
    if (!tab.connected || tab.channelId.length === 0) {
      return tab;
    }
    const channelId: string = tab.channelId;
    const writeResult: NativeJsonResult = await NativeSshCore.write(channelId, data);
    const current: TerminalTab | undefined = this.getTab(tabId);
    if (current === undefined || current.channelId !== channelId) {
      return undefined;
    }
    if (!writeResult.ok) {
      current.statusCode = writeResult.code;
      current.statusMessage = writeResult.message;
      return current;
    }
    const readResult: NativeJsonResult = await NativeSshCore.read(channelId);
    const afterRead: TerminalTab | undefined = this.getTab(tabId);
    if (afterRead !== undefined && afterRead.channelId === channelId && readResult.data.length > 0) {
      afterRead.buffer += readResult.data;
    }
    return afterRead;
  }

  async poll(tabId: string): Promise<TerminalTab | undefined> {
    const tab: TerminalTab | undefined = this.getTab(tabId);
    if (tab === undefined || !tab.connected || tab.channelId.length === 0) {
      return tab;
    }
    const channelId: string = tab.channelId;
    const readResult: NativeJsonResult = await NativeSshCore.read(channelId);
    const current: TerminalTab | undefined = this.getTab(tabId);
    if (current !== undefined && current.channelId === channelId && readResult.ok && readResult.data.length > 0) {
      current.buffer += readResult.data;
    }
    return current;
  }

  async resize(tabId: string, cols: number, rows: number): Promise<void> {
    const tab: TerminalTab | undefined = this.getTab(tabId);
    if (tab === undefined) {
      return;
    }
    tab.cols = cols;
    tab.rows = rows;
    await NativeSshCore.resize(tab.channelId, cols, rows);
  }

  async close(tabId: string): Promise<void> {
    const tab: TerminalTab | undefined = this.getTab(tabId);
    if (tab === undefined) {
      return;
    }
    const channelId: string = tab.channelId;
    const sessionId: string = tab.sessionId;
    tab.connected = false;
    this.tabs = this.tabs.filter((item: TerminalTab) => item.id !== tabId);
    if (channelId.length > 0) {
      try {
        await NativeSshCore.closeChannel(channelId);
      } catch (error) {
      }
    }
    try {
      await NativeSshCore.disconnect(sessionId);
    } catch (error) {
    }
  }

  async closeAll(): Promise<void> {
    const tabIds: string[] = this.tabs.map((item: TerminalTab) => item.id);
    for (let index: number = 0; index < tabIds.length; index++) {
      await this.close(tabIds[index]);
    }
  }
}

export const TerminalSessionManager: TerminalSessionManagerImpl = new TerminalSessionManagerImpl();
