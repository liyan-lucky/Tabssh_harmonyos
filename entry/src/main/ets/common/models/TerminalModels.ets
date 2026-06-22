export interface TerminalTab {
  id: string;
  title: string;
  profileId: string;
  sessionId: string;
  channelId: string;
  connected: boolean;
  buffer: string;
  cols: number;
  rows: number;
}

export interface PortForwardRule {
  id: string;
  type: string;
  sessionId: string;
  localHost: string;
  localPort: number;
  remoteHost: string;
  remotePort: number;
  running: boolean;
}

export interface SftpEntry {
  name: string;
  path: string;
  type: string;
  size: number;
  modifiedTime: string;
}
