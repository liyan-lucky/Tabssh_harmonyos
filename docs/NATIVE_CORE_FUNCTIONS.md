# Native C++ SSH Core 函数表

> 2026-06-22：当前表描述 Mock 接口契约，不等于真实网络功能已实现。真实完成状态以 `PROGRESS.md` 为准，安全和资源清理要求见 `CORE.md`。

ArkTS 通过：

```ts
import nativeSsh from 'libentry.so';
```

调用 native 函数。

## 当前 N-API 函数

| 函数 | 入参 | 返回 | 说明 |
|---|---|---|---|
| `version()` | 无 | `string` | 返回 native core 版本 |
| `createSession(profileJson)` | 连接配置 JSON | `sessionId` | 创建 SSH session 对象 |
| `connect(sessionId)` | sessionId | JSON string | 连接服务器 |
| `openShell(sessionId)` | sessionId | `channelId` | 打开 shell/PTY channel |
| `write(channelId, data)` | channelId + 文本 | JSON string | 写入终端输入 |
| `read(channelId)` | channelId | JSON string | 读取终端输出 |
| `resize(channelId, cols, rows)` | 终端列/行 | JSON string | 调整 PTY 大小 |
| `closeChannel(channelId)` | channelId | JSON string | 关闭当前 tab 的 channel |
| `disconnect(sessionId)` | sessionId | JSON string | 断开 session |
| `sftpList(sessionId, path)` | sessionId + 路径 | JSON string | SFTP 列目录 |
| `addLocalForward(sessionId, localPort, remoteHost, remotePort)` | 本地转发参数 | `forwardId` | 本地端口转发 |
| `addRemoteForward(sessionId, remotePort, localHost, localPort)` | 远程转发参数 | `forwardId` | 远程端口转发 |
| `addDynamicForward(sessionId, localPort)` | SOCKS 本地端口 | `forwardId` | 动态 SOCKS 转发 |
| `removeForward(forwardId)` | forwardId | JSON string | 移除转发 |

## JSON 返回格式

```json
{
  "ok": true,
  "code": 0,
  "message": "read",
  "data": "terminal output"
}
```

## 对应 Android TabSSH 功能

| Android TabSSH 功能 | OpenTabSsh native 函数 |
|---|---|
| SSHSessionManager.createConnection | `createSession` + `connect` |
| SSHConnection.openShellChannel | `openShell` |
| TermuxBridge input/output | `write` + `read` |
| resizePtyOf | `resize` |
| closeChannel | `closeChannel` |
| disconnect | `disconnect` |
| SFTPManager list/upload/download | `sftpList`，后续补 upload/download |
| PortForwardingManager | `addLocalForward` / `addRemoteForward` / `addDynamicForward` |
| HostKeyVerifier | 后续在 `connect` 前后返回 fingerprint/changed 状态 |
