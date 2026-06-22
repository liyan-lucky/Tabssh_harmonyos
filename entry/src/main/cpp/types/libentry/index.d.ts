declare namespace nativeSsh {
  function version(): string;
  function createSession(profileJson: string): string;
  function connect(sessionId: string): Promise<string>;
  function confirmHostKey(sessionId: string, fingerprint: string): string;
  function openShell(sessionId: string): Promise<string>;
  function write(channelId: string, data: string): string;
  function read(channelId: string): string;
  function resize(channelId: string, cols: number, rows: number): string;
  function closeChannel(channelId: string): string;
  function disconnect(sessionId: string): string;
  function sftpList(sessionId: string, path: string): Promise<string>;
  function addLocalForward(sessionId: string, localPort: number, remoteHost: string, remotePort: number): string;
  function addRemoteForward(sessionId: string, remotePort: number, localHost: string, localPort: number): string;
  function addDynamicForward(sessionId: string, localPort: number): string;
  function removeForward(forwardId: string): string;
}

export default nativeSsh;
