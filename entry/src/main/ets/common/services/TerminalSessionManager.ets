import { ConnectionProfile } from '../models/ConnectionProfile';
import { HostKeyDetails, TerminalTab } from '../models/TerminalModels';
import { NativeSshCore, NativeJsonResult } from '../native/NativeSshCore';
import { PortForwardManager } from './PortForwardManager';
import { ProfileRepository } from '../storage/ProfileRepository';

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
      everConnected: false,
      reconnectAttempt: 0,
      reconnecting: false,
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
    current.everConnected = true;
    current.reconnectAttempt = 0;
    current.reconnecting = false;
    current.statusCode = 0;
    current.statusMessage = 'SSH authenticated and PTY opened';
    current.pendingHostKey = '';
    const initialRead: NativeJsonResult = await NativeSshCore.read(channelId);
    this.applyReadResult(current, initialRead);
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
      this.markConnectionLost(current, writeResult.message);
      return current;
    }
    const readResult: NativeJsonResult = await NativeSshCore.read(channelId);
    const afterRead: TerminalTab | undefined = this.getTab(tabId);
    if (afterRead !== undefined && afterRead.channelId === channelId) {
      this.applyReadResult(afterRead, readResult);
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
    if (current !== undefined && current.channelId === channelId) {
      this.applyReadResult(current, readResult);
    }
    return current;
  }

  async reconnectTab(tabId: string): Promise<TerminalTab | undefined> {
    const tab: TerminalTab | undefined = this.getTab(tabId);
    if (tab === undefined || tab.reconnecting) return tab;
    const profile: ConnectionProfile | undefined = ProfileRepository.get(tab.profileId);
    if (profile === undefined) {
      tab.statusCode = 1005;
      tab.statusMessage = '重连配置已不存在';
      return tab;
    }
    tab.reconnecting = true;
    tab.connected = false;
    tab.statusMessage = '正在重新建立 SSH、HostKey 与 PTY…';
    const oldChannelId: string = tab.channelId;
    const oldSessionId: string = tab.sessionId;
    tab.channelId = '';
    if (oldChannelId.length > 0) {
      try {
        await NativeSshCore.closeChannel(oldChannelId);
      } catch (error) {
      }
    }
    try {
      await NativeSshCore.disconnect(oldSessionId);
    } catch (error) {
    }
    PortForwardManager.forgetSession(oldSessionId);
    const current: TerminalTab | undefined = this.getTab(tabId);
    if (current === undefined) return undefined;
    current.sessionId = NativeSshCore.createSession(profile);
    current.pendingHostKey = '';
    current.hostKeyAlgorithm = '';
    try {
      const updated: TerminalTab | undefined = await this.connectTab(tabId);
      if (updated !== undefined && !updated.connected) updated.reconnecting = false;
      return updated;
    } catch (error) {
      const afterError: TerminalTab | undefined = this.getTab(tabId);
      if (afterError !== undefined) {
        afterError.reconnecting = false;
        afterError.statusCode = 1007;
        afterError.statusMessage = '重连任务异常';
      }
      return afterError;
    }
  }

  private markConnectionLost(tab: TerminalTab, message: string): void {
    tab.connected = false;
    tab.reconnecting = false;
    tab.statusCode = 1007;
    tab.statusMessage = message.length > 0 ? '连接已中断：' + message : '连接已中断';
  }

  private applyReadResult(tab: TerminalTab, result: NativeJsonResult): void {
    if (result.data.length > 0) tab.buffer += result.data;
    if (!result.ok) {
      this.markConnectionLost(tab, result.message);
    } else if (result.message === 'eof') {
      tab.connected = false;
      tab.channelId = '';
      tab.reconnecting = false;
      tab.statusCode = result.code === 0 ? 1008 : 1007;
      tab.statusMessage = result.code === 0 ? '远端 shell 已正常结束' : '远端 shell 异常结束';
    }
  }

  async resize(tabId: string, cols: number, rows: number): Promise<void> {
    const tab: TerminalTab | undefined = this.getTab(tabId);
    if (tab === undefined || !tab.connected || tab.channelId.length === 0) {
      return;
    }
    const channelId: string = tab.channelId;
    const result: NativeJsonResult = await NativeSshCore.resize(channelId, cols, rows);
    const current: TerminalTab | undefined = this.getTab(tabId);
    if (current === undefined || current.channelId !== channelId) return;
    if (!result.ok) throw new Error(result.message);
    current.cols = cols;
    current.rows = rows;
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
    PortForwardManager.forgetSession(sessionId);
  }

  async closeAll(): Promise<void> {
    const tabIds: string[] = this.tabs.map((item: TerminalTab) => item.id);
    for (let index: number = 0; index < tabIds.length; index++) {
      await this.close(tabIds[index]);
    }
  }
}

export const TerminalSessionManager: TerminalSessionManagerImpl = new TerminalSessionManagerImpl();
