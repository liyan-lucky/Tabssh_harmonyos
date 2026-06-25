# Android TabSSH 到 HarmonyOS OpenTabSsh 映射

> 2026-06-25：本文是目标映射，不代表全部实现。当前完成度以 `AGENT_HANDOFF.md` 和 `PROGRESS.md` 为准；构建测试路径以 `WORKSPACE_PATHS.md` 为准。

| Android 组件 | HarmonyOS 方案 |
|---|---|
| MainActivity | `pages/Index.ets` |
| ConnectionEditActivity | `pages/ConnectionEditPage.ets` |
| TabTerminalActivity | `pages/TerminalPage.ets` + `TerminalSessionManager.ets` |
| SFTPActivity | `pages/SftpPage.ets` |
| PortForwardingActivity | `pages/PortForwardPage.ets` |
| SettingsActivity | `pages/SettingsPage.ets` |
| SSHConnection / JSch | `entry/src/main/cpp/native_ssh_*` + libssh2 |
| SSHSessionManager | `TerminalSessionManager.ets` + native session map |
| TermuxBridge / TerminalEmulator | ArkTS VT 单元格解析器与 Span 样式渲染；复杂 TUI/IME/设备验收仍缺 |
| Room DB | 后续换成 RDB Store |
| Android Keystore | 后续换成 HUKS / ASSET |
| WorkManager | 后续换成 HarmonyOS 后台任务能力 |
| AppWidgetProvider | 后续换成 FormExtensionAbility |

## Android `0c455b8b...` 全功能验收矩阵

状态含义：`字段骨架` 只表示 ArkTS 模型已有配置字段；`编码中` 只表示已有源码；`待验证` 表示必须取得真实 HAP/设备/流量证据；`未开始` 表示当前仓库没有可验收实现。页面、函数名、字段名或 Mock 返回不构成功能完成。

| Android 能力组 | HarmonyOS 对齐范围 | 当前状态 |
|---|---|---|
| 多标签/共享 SSH session | 多 channel、标签切换、OSC 标题、状态点、后台会话 | 基础单页 manager；未开始完整对齐 |
| 密码/私钥/keyboard-interactive | RSA/ECDSA/Ed25519/DSA、OpenSSH/PEM/PKCS#8/PuTTY、导入/生成 | 密码/文件私钥 libssh2 源码编码中；其余未开始 |
| HostKey 安全 | SHA256 TOFU、变更阻断、可信核对、known_hosts | 指纹、算法、信任时间字段骨架；阻断/确认 UI 与 native 源码编码中；待真实验证和持久化 |
| Shell/PTY | 非阻塞读写、resize、keepalive、IPv4/IPv6、超时/取消 | `ipMode`、connect/read/serverAlive timeout 字段骨架；libssh2 源码编码中；待真实构建与双设备验证 |
| 终端模拟器 | VT100/ANSI/xterm-256、颜色、选择复制、滚动、搜索、OSC、vim/tmux | SGR 16/256/RGB、样式 Span、备用屏、OSC、宽字符、复制、滚动历史和 PTY resize 已编码并通过内存测试；搜索、完整键盘/IME、鼠标协议及复杂 TUI 设备回归未完成 |
| 自定义键盘/硬件键盘 | 1–5 行、重排、Ctrl/Alt、AltGr、修饰键编码、F1–F12 | 六个基础键入口；其余未开始 |
| SFTP | 浏览、上传/下载进度、编辑、chmod、删除、重命名、哈希 | list 与写操作源码/UI 已编码，回环小文件证据已有；大文件/取消/外部写操作待验 |
| 端口转发 | local、remote、dynamic SOCKS5、生命周期、真实流量 | 三类真实 worker、异步 N-API、Mock 拒绝和断开清理已编码；待双架构构建与逐字节流量验收 |
| 代理/跳板 | ProxyHTTP/SOCKS4/SOCKS5、ProxyJump、多跳 | proxyType/proxyHost/proxyPort/proxyUsername/proxyAuthType/proxyKeyId 与 jumpHostId 字段骨架；协议实现未开始 |
| SSH config | Import、RemoteCommand、SendEnv、RequestTTY、ProxyJump | remoteCommand、sendEnv、requestTty、jumpHostId 字段骨架；导入解析和 Native 使用未开始 |
| 会话增强 | post-connect、tmux/screen/zellij、录制/回放、宏、片段 | postConnectScript、multiplexerMode、multiplexerSessionName 字段骨架；自动 attach/create、录制、宏、片段未开始 |
| X11/Mosh | Termux:X11/XServer、Mosh roaming | x11Forwarding、moshMode 字段骨架；协议实现未开始 |
| 凭据安全 | HUKS/ASSET、AES-256-GCM、生物识别、自动锁、内存擦除 | profile JSON/口令擦除源码编码中；安全存储与生物识别未开始 |
| 隐私防护 | 截图保护、剪贴板自动清除、零遥测 | 窗口隐私保护曾编码；剪贴板清理/零遥测审计待补 |
| 主题/可访问性 | 22 主题、自定义/WCAG、字体、TalkBack、高对比、键盘导航、四语言 | 未开始 |
| 连接管理 | RDB、分组、收藏、搜索、8 种排序、统计、日志、批量编辑 | 模型与内存仓库已支持分组、收藏字段、搜索过滤、8 类排序和连接成功/失败统计；首页筛选 UI、RDB、日志和批量编辑未完成 |
| 监控/通知 | TCP 探测、CPU/内存/磁盘阈值、恢复通知、冷却时间 | 占位页；未开始 |
| 备份/同步 | 加密 ZIP、SAF 云盘、PBKDF2、三方合并/冲突 UI | syncVersion、syncDeviceId 字段骨架；加密备份/同步未开始 |
| 自动化/服务卡片 | Tasker、Intent/deep link、Widget/FormExtension | 未开始 |
| 多主机 Dashboard | 独立分组、CPU/内存/磁盘并排指标 | 未开始 |
| Proxmox | REST、VM/LXC 电源、termproxy、VNC fallback、统计 | 未开始 |
| XCP-ng/XO | XML-RPC/REST/WebSocket、状态、快照、备份、自动探测 | 未开始 |
| VMware | ESXi/vCenter 自动探测、VM 电源管理 | 未开始 |
| QEMU/libvirt | virsh、电源、SSH 隧道 VNC、ProxyJump fallback | 未开始 |
| 8 家云厂商 | DO/Hetzner/Linode/Vultr/AWS/GCP/Azure/OCI、状态/电源/SSH | 未开始 |
| VNC RFB | Tight/ZRLE/CopyRect/Hextile/CoRRE/RRE、Fence、resize、DES auth、键盘 | 未开始 |

## 本轮对齐新增字段与内存能力

`entry/src/main/ets/common/models/ConnectionProfile.ets` 已增加 Android Profile 常见能力所需字段：

- HostKey：`hostKeyAlgorithm`、`hostKeyTrustedAt`
- 代理：`proxyUsername`、`proxyAuthType`、`proxyKeyId`
- 网络：`ipMode`、`compression`、`connectTimeoutMilliseconds`、`readTimeoutMilliseconds`、`serverAliveIntervalSeconds`
- 会话：`remoteCommand`、`sendEnv`、`requestTty`、`agentForwarding`、`x11Forwarding`、`moshMode`
- 多路复用：`multiplexerMode`、`multiplexerSessionName`
- 管理：`groupId`、`sortOrder`、`favorite`、`lastConnectedAt`、`connectionCount`、`lastErrorMessage`、`remarks`
- 同步：`createdAt`、`modifiedAt`、`syncVersion`、`syncDeviceId`

`ConnectionGroup.ets` 和 `ProfileRepository.ets` 已增加默认分组、过滤、排序和连接成功/失败统计入口。当前仍是内存数据，应用退出即丢失；字段未接 UI、Native、RDB 和真实验收前，不能把对应 Android 功能标记为完成。

只有矩阵行的全部子项在目标 HarmonyOS API 上取得端到端证据，才可把该行标成完成。
