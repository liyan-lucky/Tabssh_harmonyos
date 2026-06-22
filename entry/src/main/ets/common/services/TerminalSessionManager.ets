import { ConnectionProfile } from '../models/ConnectionProfile';
import { TerminalTab } from '../models/TerminalModels';
import { NativeSshCore, NativeJsonResult } from '../native/NativeSshCore';

class TerminalSessionManagerImpl {
  private tabs: TerminalTab[] = [];

  createTab(profile: ConnectionProfile): TerminalTab {
    const sessionId: string = NativeSshCore.createSession(profile);
    const connectResult: NativeJsonResult = NativeSshCore.connect(sessionId);
    const channelId: string = NativeSshCore.openShell(sessionId);
    const initial: NativeJsonResult = NativeSshCore.read(channelId);
    const tab: TerminalTab = {
      id: 'tab-' + new Date().getTime().toString(),
      title: profile.name,
      profileId: profile.id,
      sessionId: sessionId,
      channelId: channelId,
      connected: connectResult.ok,
      buffer: initial.data,
      cols: 80,
      rows: 24
    };
    this.tabs.push(tab);
    return tab;
  }

  listTabs(): TerminalTab[] {
    return this.tabs;
  }

  getTab(tabId: string): TerminalTab | undefined {
    return this.tabs.find((item: TerminalTab) => item.id === tabId);
  }

  write(tabId: string, command: string): TerminalTab | undefined {
    const tab: TerminalTab | undefined = this.getTab(tabId);
    if (tab === undefined) {
      return undefined;
    }
    NativeSshCore.write(tab.channelId, command + '\n');
    const readResult: NativeJsonResult = NativeSshCore.read(tab.channelId);
    tab.buffer += readResult.data;
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
      NativeSshCore.closeChannel(tab.channelId);
      NativeSshCore.disconnect(tab.sessionId);
    }
    this.tabs = this.tabs.filter((item: TerminalTab) => item.id !== tabId);
  }
}

export const TerminalSessionManager: TerminalSessionManagerImpl = new TerminalSessionManagerImpl();
