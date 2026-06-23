declare namespace nativeSsh {
  function version(): string;
  function createSession(profileJson: string): string;
  function connect(sessionId: string): Promise<string>;
  function confirmHostKey(sessionId: string, fingerprint: string): string;
  function openShell(sessionId: string): Promise<string>;
  function write(channelId: string, data: string): Promise<string>;
  function read(channelId: string): Promise<string>;
  function resize(channelId: string, cols: number, rows: number): Promise<string>;
  function closeChannel(channelId: string): Promise<string>;
  function disconnect(sessionId: string): Promise<string>;
  function sftpList(sessionId: string, path: string): Promise<string>;
  function sftpUpload(sessionId: string, localPath: string, remotePath: string): Promise<string>;
  function sftpDownload(sessionId: string, remotePath: string, localPath: string): Promise<string>;
  function sftpMkdir(sessionId: string, path: string): Promise<string>;
  function sftpRemove(sessionId: string, path: string, directory: number): Promise<string>;
  function sftpRename(sessionId: string, sourcePath: string, destinationPath: string): Promise<string>;
  function sftpChmod(sessionId: string, path: string, mode: number): Promise<string>;
  function addLocalForward(sessionId: string, localPort: number, remoteHost: string, remotePort: number): string;
  function addRemoteForward(sessionId: string, remotePort: number, localHost: string, localPort: number): string;
  function addDynamicForward(sessionId: string, localPort: number): string;
  function removeForward(forwardId: string): string;
}

export default nativeSsh;
