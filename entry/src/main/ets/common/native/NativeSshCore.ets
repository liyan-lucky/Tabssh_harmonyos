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

  static async connect(sessionId: string): Promise<NativeJsonResult> {
    return parseResult(await nativeSsh.connect(sessionId));
  }

  static confirmHostKey(sessionId: string, fingerprint: string): NativeJsonResult {
    return parseResult(nativeSsh.confirmHostKey(sessionId, fingerprint));
  }

  static async openShell(sessionId: string): Promise<string> {
    return await nativeSsh.openShell(sessionId);
  }

  static async write(channelId: string, text: string): Promise<NativeJsonResult> {
    return parseResult(await nativeSsh.write(channelId, text));
  }

  static async read(channelId: string): Promise<NativeJsonResult> {
    return parseResult(await nativeSsh.read(channelId));
  }

  static async resize(channelId: string, cols: number, rows: number): Promise<NativeJsonResult> {
    return parseResult(await nativeSsh.resize(channelId, cols, rows));
  }

  static async closeChannel(channelId: string): Promise<NativeJsonResult> {
    return parseResult(await nativeSsh.closeChannel(channelId));
  }

  static async disconnect(sessionId: string): Promise<NativeJsonResult> {
    return parseResult(await nativeSsh.disconnect(sessionId));
  }

  static async sftpList(sessionId: string, path: string): Promise<SftpEntry[]> {
    const result: NativeJsonResult = parseResult(await nativeSsh.sftpList(sessionId, path));
    if (!result.ok) {
      throw new Error(result.message);
    }
    if (result.data.length === 0) {
      return [];
    }
    return JSON.parse(result.data) as SftpEntry[];
  }

  static async sftpUpload(sessionId: string, localPath: string, remotePath: string): Promise<NativeJsonResult> {
    return parseResult(await nativeSsh.sftpUpload(sessionId, localPath, remotePath));
  }

  static async sftpDownload(sessionId: string, remotePath: string, localPath: string): Promise<NativeJsonResult> {
    return parseResult(await nativeSsh.sftpDownload(sessionId, remotePath, localPath));
  }

  static async sftpMkdir(sessionId: string, path: string): Promise<NativeJsonResult> {
    return parseResult(await nativeSsh.sftpMkdir(sessionId, path));
  }

  static async sftpRemove(sessionId: string, path: string, directory: boolean): Promise<NativeJsonResult> {
    return parseResult(await nativeSsh.sftpRemove(sessionId, path, directory ? 1 : 0));
  }

  static async sftpRename(sessionId: string, sourcePath: string,
    destinationPath: string): Promise<NativeJsonResult> {
    return parseResult(await nativeSsh.sftpRename(sessionId, sourcePath, destinationPath));
  }

  static async sftpChmod(sessionId: string, path: string, mode: number): Promise<NativeJsonResult> {
    return parseResult(await nativeSsh.sftpChmod(sessionId, path, mode));
  }

  static async addLocalForward(sessionId: string, localPort: number, remoteHost: string,
    remotePort: number): Promise<string> {
    return await nativeSsh.addLocalForward(sessionId, localPort, remoteHost, remotePort);
  }

  static async addRemoteForward(sessionId: string, remotePort: number, localHost: string,
    localPort: number): Promise<string> {
    return await nativeSsh.addRemoteForward(sessionId, remotePort, localHost, localPort);
  }

  static async addDynamicForward(sessionId: string, localPort: number): Promise<string> {
    return await nativeSsh.addDynamicForward(sessionId, localPort);
  }

  static async removeForward(forwardId: string): Promise<NativeJsonResult> {
    return parseResult(await nativeSsh.removeForward(forwardId));
  }
}
