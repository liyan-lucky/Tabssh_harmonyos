# 真实 SSH MVP 路线图

> 目标：先把 OpenTabSsh 从 Mock 骨架推进到可连接真实 Linux/OpenWrt 的最小可用 SSH 客户端。本文是执行清单，不代表功能已完成。完成状态以 `PROGRESS.md` 的端到端证据为准。

## 0. 当前边界

- 默认 Native Core 仍是 `native_ssh_mock.cpp`，保证干净仓库无需三方库即可构建。
- 真实 Core 只能在 `OPEN_TAB_SSH_ENABLE_LIBSSH2=ON` 且 `third_party/` 中存在对应 ABI 的 `libssh2/OpenSSL/zlib` 后启用。
- 禁止把 Mock 的 `ok=true` 当作真实 SSH、SFTP 或转发完成证据。
- 密码、私钥、私钥口令、token 和服务器凭据只允许存在测试运行内存，不得写入源码、日志、文档、截图、备份说明或提交说明。

## 1. MVP 范围

MVP 只覆盖：

1. `createSession(profileJson)`：解析连接配置并创建 native session。
2. `connect(sessionId)`：建立 TCP socket，完成 libssh2 handshake，支持 password 认证。
3. `openShell(sessionId)`：打开 shell channel，申请 PTY，默认 `xterm-256color`。
4. `write(channelId, data)`：写入终端输入。
5. `read(channelId)`：非阻塞读取终端输出。
6. `resize(channelId, cols, rows)`：调整 PTY 窗口。
7. `closeChannel(channelId)`：关闭 shell channel。
8. `disconnect(sessionId)`：断开 session、关闭 socket、释放 libssh2 资源。

暂不纳入 MVP：私钥登录、SFTP、端口转发、ProxyJump、Mosh、X11、云/虚拟化、VNC、多端同步。

## 2. 连接配置 MVP 字段

`profileJson` MVP 至少需要：

```json
{
  "id": "uuid-or-local-id",
  "name": "OpenWrt",
  "host": "192.168.1.1",
  "port": 22,
  "username": "root",
  "authType": "password",
  "password": "runtime-only",
  "terminalType": "xterm-256color",
  "encoding": "UTF-8",
  "connectTimeout": 15,
  "readTimeout": 30,
  "serverAliveInterval": 60,
  "ipMode": "auto"
}
```

要求：

- `password` 只能由 UI 在连接时注入 runtime JSON，不得持久化到普通配置文件。
- 后续接入 HUKS/ASSET 后，保存的只能是加密引用或安全存储别名。
- `authType` 先只允许 `password`，其他值返回明确错误。

## 3. Native 结果约定

所有真实 Core 函数继续返回当前 `NativeResult` JSON：

```json
{
  "ok": false,
  "code": 1001,
  "message": "connect timeout",
  "data": ""
}
```

建议错误码：

| code | 含义 |
|---:|---|
| 0 | 成功 |
| 400 | 参数错误 / JSON 字段缺失 |
| 401 | 认证失败 |
| 403 | HostKey 变更或未信任 |
| 404 | session/channel/forward 不存在 |
| 408 | 连接或读取超时 |
| 500 | libssh2/socket 内部错误 |
| 501 | 当前功能未实现 |

## 4. HostKey MVP

第一版必须返回 HostKey 指纹信息，但允许 UI 先用最小确认弹窗：

- 首次连接：返回 fingerprint、algorithm、host、port，由 UI 提示用户信任。
- 已信任：继续连接。
- 指纹变化：必须阻断连接，提示可能 MITM，除非用户显式更新信任。

真实 known_hosts 存储后续放到 HarmonyOS RDB + HUKS/ASSET 保护策略中；在此之前不得把 HostKey 信任状态伪装成已完成。

## 5. libssh2 Core 实现顺序

1. 建立 socket 工具：DNS/IP 解析、IPv4/IPv6 auto 选择、connect timeout、close。
2. `libssh2_init` / `libssh2_session_init` / `libssh2_session_handshake`。
3. non-blocking 模式与 `WaitSocket` 循环。
4. password auth：`libssh2_userauth_password`。
5. shell channel：`libssh2_channel_open_session`、`libssh2_channel_request_pty_ex`、`libssh2_channel_shell`。
6. read/write：处理 `LIBSSH2_ERROR_EAGAIN`、短写、EOF、超时。
7. resize：`libssh2_channel_request_pty_size_ex`。
8. 释放顺序：channel close/free → session disconnect/free → socket close → `libssh2_exit`。
9. 所有 session/channel 放入线程安全 map，断开时清理所属 channel。

## 6. 端到端验收

每个 ABI 至少验证：

| 场景 | 命令 / 操作 | 通过标准 |
|---|---|---|
| password 登录 | 连接 OpenWrt/Linux | 能进入 shell |
| 基础输出 | `whoami` | 返回真实远端用户 |
| 当前目录 | `pwd` | 返回真实远端路径 |
| 目录列表 | `ls -la` | 返回真实远端文件 |
| 交互程序 | `top` 或 `htop` | 有持续输出，退出后不崩溃 |
| resize | 横竖屏/调整列行 | 远端 `stty size` 可变化 |
| 断开 | UI 断开连接 | native map、channel、socket 清理 |
| 错误密码 | 输入错误密码 | 返回认证失败，不崩溃 |
| 错误主机 | 连接不可达 IP | 超时返回，不阻塞 UI |

验收设备：

- arm64 HarmonyOS 真机。
- x86_64 模拟器或等价测试环境。

## 7. Android 原版对照但不盲目照搬

Android 原版的核心能力包括多标签 SSH、完整终端模拟、SFTP、端口转发、HostKey、安全存储、后台服务、云/虚拟化/VNC 等。HarmonyOS 版必须按 MVP 分阶段补齐，禁止一次性堆高级入口导致核心 SSH 不可用。

优先级：

1. 真实 SSH shell。
2. HostKey + 安全存储。
3. 终端渲染。
4. RDB 连接持久化。
5. SFTP。
6. 端口转发。
7. ProxyJump / tmux / snippets / 后台保活。
8. 云、虚拟化、VNC、同步。
