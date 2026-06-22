export const AUTH_PASSWORD: string = 'password';
export const AUTH_PRIVATE_KEY: string = 'privateKey';

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
  jumpHostId: string;
  proxyType: string;
  proxyHost: string;
  proxyPort: number;
  terminalType: string;
  encoding: string;
  keepAliveSeconds: number;
  timeoutMilliseconds: number;
  postConnectScript: string;
  multiplexerMode: string;
  colorTag: string;
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
    jumpHostId: '',
    proxyType: 'none',
    proxyHost: '',
    proxyPort: 0,
    terminalType: 'xterm-256color',
    encoding: 'UTF-8',
    keepAliveSeconds: 60,
    timeoutMilliseconds: 15000,
    postConnectScript: '',
    multiplexerMode: 'OFF',
    colorTag: '#38BDF8'
  };
}

export function cloneProfile(profile: ConnectionProfile): ConnectionProfile {
  return JSON.parse(JSON.stringify(profile)) as ConnectionProfile;
}
