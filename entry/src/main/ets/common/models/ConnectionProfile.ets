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
  const merged: ConnectionProfile = createEmptyConnectionProfile();

  merged.id = profile.id.length > 0 ? profile.id : merged.id;
  merged.name = profile.name.length > 0 ? profile.name : merged.name;
  merged.host = profile.host.length > 0 ? profile.host : merged.host;
  merged.port = profile.port > 0 ? profile.port : merged.port;
  merged.username = profile.username.length > 0 ? profile.username : merged.username;
  merged.authType = profile.authType.length > 0 ? profile.authType : AUTH_PASSWORD;
  merged.password = profile.password;
  merged.privateKeyPath = profile.privateKeyPath;
  merged.privateKeyPassphrase = profile.privateKeyPassphrase;
  merged.hostKeyFingerprint = profile.hostKeyFingerprint;
  merged.hostKeyAlgorithm = profile.hostKeyAlgorithm;
  merged.hostKeyTrustedAt = profile.hostKeyTrustedAt;
  merged.jumpHostId = profile.jumpHostId;
  merged.proxyType = profile.proxyType.length > 0 ? profile.proxyType : PROXY_NONE;
  merged.proxyHost = profile.proxyHost;
  merged.proxyPort = profile.proxyPort;
  merged.proxyUsername = profile.proxyUsername;
  merged.proxyAuthType = profile.proxyAuthType.length > 0 ? profile.proxyAuthType : AUTH_PASSWORD;
  merged.proxyKeyId = profile.proxyKeyId;
  merged.terminalType = profile.terminalType.length > 0 ? profile.terminalType : merged.terminalType;
  merged.encoding = profile.encoding.length > 0 ? profile.encoding : merged.encoding;
  merged.keepAliveSeconds = profile.keepAliveSeconds > 0 ? profile.keepAliveSeconds : merged.keepAliveSeconds;
  merged.timeoutMilliseconds = profile.timeoutMilliseconds > 0 ? profile.timeoutMilliseconds : merged.timeoutMilliseconds;
  merged.connectTimeoutMilliseconds = profile.connectTimeoutMilliseconds > 0 ? profile.connectTimeoutMilliseconds : merged.connectTimeoutMilliseconds;
  merged.readTimeoutMilliseconds = profile.readTimeoutMilliseconds > 0 ? profile.readTimeoutMilliseconds : merged.readTimeoutMilliseconds;
  merged.serverAliveIntervalSeconds = profile.serverAliveIntervalSeconds > 0 ? profile.serverAliveIntervalSeconds : merged.serverAliveIntervalSeconds;
  merged.ipMode = profile.ipMode.length > 0 ? profile.ipMode : IP_MODE_AUTO;
  merged.compression = profile.compression;
  merged.agentForwarding = profile.agentForwarding;
  merged.x11Forwarding = profile.x11Forwarding;
  merged.moshMode = profile.moshMode;
  merged.requestTty = profile.requestTty;
  merged.remoteCommand = profile.remoteCommand;
  merged.sendEnv = Array.isArray(profile.sendEnv) ? profile.sendEnv : [];
  merged.postConnectScript = profile.postConnectScript;
  merged.multiplexerMode = profile.multiplexerMode.length > 0 ? profile.multiplexerMode : MULTIPLEXER_OFF;
  merged.multiplexerSessionName = profile.multiplexerSessionName;
  merged.colorTag = profile.colorTag.length > 0 ? profile.colorTag : merged.colorTag;
  merged.groupId = profile.groupId;
  merged.sortOrder = profile.sortOrder;
  merged.favorite = profile.favorite;
  merged.lastConnectedAt = profile.lastConnectedAt;
  merged.connectionCount = profile.connectionCount;
  merged.lastErrorMessage = profile.lastErrorMessage;
  merged.remarks = profile.remarks;
  merged.createdAt = profile.createdAt > 0 ? profile.createdAt : merged.createdAt;
  merged.modifiedAt = profile.modifiedAt > 0 ? profile.modifiedAt : new Date().getTime();
  merged.syncVersion = profile.syncVersion;
  merged.syncDeviceId = profile.syncDeviceId;

  return merged;
}

export function cloneProfile(profile: ConnectionProfile): ConnectionProfile {
  return normalizeConnectionProfile(JSON.parse(JSON.stringify(profile)) as ConnectionProfile);
}
