export const AUTH_PASSWORD: string = 'password';
export const AUTH_PRIVATE_KEY: string = 'privateKey';

export const IP_MODE_AUTO: string = 'auto';
export const IP_MODE_IPV4: string = 'ipv4';
export const IP_MODE_IPV6: string = 'ipv6';

export const PROXY_NONE: string = 'none';
export const PROXY_HTTP: string = 'http';
export const PROXY_SOCKS4: string = 'socks4';
export const PROXY_SOCKS5: string = 'socks5';

export const MULTIPLEXER_OFF: string = 'OFF';
export const MULTIPLEXER_TMUX: string = 'TMUX';
export const MULTIPLEXER_SCREEN: string = 'SCREEN';
export const MULTIPLEXER_ZELLIJ: string = 'ZELLIJ';

export interface ConnectionProfile {
  id: string;
  name: string;
  host: string;
  port: number;
  username: string;
  authType: string;
  password: string;
  privateKeyPath: string;
  privateKeyPassphrase: string;
  hostKeyFingerprint: string;
  hostKeyAlgorithm: string;
  hostKeyTrustedAt: number;
  jumpHostId: string;
  proxyType: string;
  proxyHost: string;
  proxyPort: number;
  proxyUsername: string;
  proxyAuthType: string;
  proxyKeyId: string;
  terminalType: string;
  encoding: string;
  keepAliveSeconds: number;
  timeoutMilliseconds: number;
  connectTimeoutMilliseconds: number;
  readTimeoutMilliseconds: number;
  serverAliveIntervalSeconds: number;
  ipMode: string;
  compression: boolean;
  agentForwarding: boolean;
  x11Forwarding: boolean;
  moshMode: boolean;
  requestTty: boolean;
  remoteCommand: string;
  sendEnv: string[];
  postConnectScript: string;
  multiplexerMode: string;
  multiplexerSessionName: string;
  colorTag: string;
  groupId: string;
  sortOrder: number;
  favorite: boolean;
  lastConnectedAt: number;
  connectionCount: number;
  lastErrorMessage: string;
  remarks: string;
  createdAt: number;
  modifiedAt: number;
  syncVersion: number;
  syncDeviceId: string;
}

export function createEmptyConnectionProfile(): ConnectionProfile {
  const now: number = new Date().getTime();
  return {
    id: 'profile-' + now.toString(),
    name: '新 SSH 连接',
    host: '192.168.1.1',
    port: 22,
    username: 'root',
    authType: AUTH_PASSWORD,
    password: '',
    privateKeyPath: '',
    privateKeyPassphrase: '',
    hostKeyFingerprint: '',
    hostKeyAlgorithm: '',
    hostKeyTrustedAt: 0,
    jumpHostId: '',
    proxyType: PROXY_NONE,
    proxyHost: '',
    proxyPort: 0,
    proxyUsername: '',
    proxyAuthType: AUTH_PASSWORD,
    proxyKeyId: '',
    terminalType: 'xterm-256color',
    encoding: 'UTF-8',
    keepAliveSeconds: 60,
    timeoutMilliseconds: 15000,
    connectTimeoutMilliseconds: 15000,
    readTimeoutMilliseconds: 30000,
    serverAliveIntervalSeconds: 60,
    ipMode: IP_MODE_AUTO,
    compression: false,
    agentForwarding: false,
    x11Forwarding: false,
    moshMode: false,
    requestTty: true,
    remoteCommand: '',
    sendEnv: [],
    postConnectScript: '',
    multiplexerMode: MULTIPLEXER_OFF,
    multiplexerSessionName: '',
    colorTag: '#38BDF8',
    groupId: '',
    sortOrder: 0,
    favorite: false,
    lastConnectedAt: 0,
    connectionCount: 0,
    lastErrorMessage: '',
    remarks: '',
    createdAt: now,
    modifiedAt: now,
    syncVersion: 0,
    syncDeviceId: ''
  };
}

export function normalizeConnectionProfile(profile: ConnectionProfile): ConnectionProfile {
  const base: ConnectionProfile = createEmptyConnectionProfile();
  const merged: ConnectionProfile = Object.assign(base, profile) as ConnectionProfile;
  merged.password = profile.password ?? '';
  merged.privateKeyPassphrase = profile.privateKeyPassphrase ?? '';
  merged.sendEnv = Array.isArray(profile.sendEnv) ? profile.sendEnv : [];
  merged.modifiedAt = merged.modifiedAt > 0 ? merged.modifiedAt : new Date().getTime();
  return merged;
}

export function cloneProfile(profile: ConnectionProfile): ConnectionProfile {
  return normalizeConnectionProfile(JSON.parse(JSON.stringify(profile)) as ConnectionProfile);
}
