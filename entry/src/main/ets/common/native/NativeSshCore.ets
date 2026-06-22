import nativeSsh from 'libentry.so';
import { ConnectionProfile } from '../models/ConnectionProfile';
import { SftpEntry } from '../models/TerminalModels';

export interface NativeJsonResult {
  ok: boolean;
  code: number;
  message: string;
  data: string;
}

function parseResult(raw: string): NativeJsonResult {
  try {
    return JSON.parse(raw) as NativeJsonResult;
  } catch (error) {
    return {
      ok: false,
      code: -1,
      message: 'Native 返回值不是 JSON: ' + raw,
      data: ''
    };
  }
}

export class NativeSshCore {
  static version(): string {
    return nativeSsh.version();
  }

  static createSession(profile: ConnectionProfile): string {
    return nativeSsh.createSession(JSON.stringify(profile));
  }

  static connect(sessionId: string): NativeJsonResult {
    return parseResult(nativeSsh.connect(sessionId));
  }

  static openShell(sessionId: string): string {
    return nativeSsh.openShell(sessionId);
  }

  static write(channelId: string, text: string): NativeJsonResult {
    return parseResult(nativeSsh.write(channelId, text));
  }

  static read(channelId: string): NativeJsonResult {
    return parseResult(nativeSsh.read(channelId));
  }

  static resize(channelId: string, cols: number, rows: number): NativeJsonResult {
    return parseResult(nativeSsh.resize(channelId, cols, rows));
  }

  static closeChannel(channelId: string): NativeJsonResult {
    return parseResult(nativeSsh.closeChannel(channelId));
  }

  static disconnect(sessionId: string): NativeJsonResult {
    return parseResult(nativeSsh.disconnect(sessionId));
  }

  static sftpList(sessionId: string, path: string): SftpEntry[] {
    const result: NativeJsonResult = parseResult(nativeSsh.sftpList(sessionId, path));
    if (!result.ok || result.data.length === 0) {
      return [];
    }
    return JSON.parse(result.data) as SftpEntry[];
  }

  static addLocalForward(sessionId: string, localPort: number, remoteHost: string, remotePort: number): string {
    return nativeSsh.addLocalForward(sessionId, localPort, remoteHost, remotePort);
  }

  static addRemoteForward(sessionId: string, remotePort: number, localHost: string, localPort: number): string {
    return nativeSsh.addRemoteForward(sessionId, remotePort, localHost, localPort);
  }

  static addDynamicForward(sessionId: string, localPort: number): string {
    return nativeSsh.addDynamicForward(sessionId, localPort);
  }

  static removeForward(forwardId: string): NativeJsonResult {
    return parseResult(nativeSsh.removeForward(forwardId));
  }
}
