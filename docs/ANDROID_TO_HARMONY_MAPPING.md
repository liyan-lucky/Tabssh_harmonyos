# Android TabSSH 到 HarmonyOS OpenTabSsh 映射

> 2026-06-26：本文是目标映射，不代表全部实现。当前完成度以 `AGENT_HANDOFF.md` 和 `PROGRESS.md` 为准；构建测试路径以 `WORKSPACE_PATHS.md` 为准。

| Android 组件 | HarmonyOS 方案 |
|---|---|
| MainActivity | `pages/Index.ets` |
| ConnectionEditActivity | `pages/ConnectionEditPage.ets` |
| Connection group management | `pages/ConnectionGroupPage.ets` + `ConnectionGroup.ets` + `ProfileRepository.ets` |
| TabTerminalActivity | `pages/TerminalPage.ets` + `TerminalSessionManager.ets` |
| SFTPActivity | `pages/SftpPage.ets` |
| PortForwardingActivity | `pages/PortForwardPage.ets` |
| SettingsActivity | `pages/SettingsPage.ets` |
| AuditLogViewerActivity | `pages/AuditLogPage.ets` + `ConnectionAuditLog.ets` + RDB `connection_audit_logs` |
| ConnectionHistoryActivity | `pages/ConnectionHistoryPage.ets` + RDB profile 统计字段 |
| ImportExportActivity | `pages/ConnectionImportExportPage.ets` + `ConnectionImportExportService.ets` + `ProfileRepository.importConnections()` |
| Toolbox / utility screens | `pages/ToolboxPage.ets` + 已登记 ProIcons rawfile；当前为纯 ArkTS / 纯 HarmonyOS 工具页，网络能力部分已接入 |
| SSHConnection / JSch | `entry/src/main/cpp/native_ssh_*` + libssh2 |
| SSHSessionManager | `TerminalSessionManager.ets` + native session map |
| TermuxBridge / TerminalEmulator | ArkTS VT 单元格解析器与 Span 样式渲染；复杂 TUI/IME/设备验收仍缺 |
| Room DB | HarmonyOS `relationalStore` RDB-backed repository；新增分组与分组变更摘要已通过基础跨重启回显，仍待完整点击矩阵和 schema migration |
| Android Keystore | 后续换成 HUKS / ASSET |
| WorkManager | 后续换成 HarmonyOS 后台任务能力 |
| AppWidgetProvider | 后续换成 FormExtensionAbility |

## Android `9937640a...` 全功能验收矩阵

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
| SSH config | Import、RemoteCommand、SendEnv、RequestTTY、ProxyJump | OpenSSH config 导入/导出已编码并通过 Real HAP picker 入口验证，支持 Host/HostName/User/Port/RequestTTY/SendEnv/RemoteCommand 等常用字段；ProxyJump、Native 完整使用和真实导入落库回显待补 |
| 会话增强 | post-connect、tmux/screen/zellij、录制/回放、宏、片段 | postConnectScript、multiplexerMode、multiplexerSessionName 字段骨架；自动 attach/create、录制、宏、片段未开始 |
| X11/Mosh | Termux:X11/XServer、Mosh roaming | x11Forwarding、moshMode 字段骨架；协议实现未开始 |
| 凭据安全 | HUKS/ASSET、AES-256-GCM、生物识别、自动锁、内存擦除 | profile JSON/口令擦除源码编码中；安全存储与生物识别未开始 |
| 隐私防护 | 截图保护、剪贴板自动清除、零遥测 | 窗口隐私保护与全屏避让已编码并通过 x86_64 多页无凭据抽样；剪贴板清理/零遥测审计、多设备避让矩阵待补 |
| 主题/可访问性 | 22 主题、自定义/WCAG、字体、TalkBack、高对比、键盘导航、四语言 | 浅色/深色、中文/English 和系统语言跟随偏好已编码并通过 settings preferences 驱动首页主壳、工作台、设置 Tab、设置页、工具箱、关于、终端设置、连接历史、访问日志、连接分组、连接导入导出、连接编辑、终端、SFTP 和端口转发页刷新；系统语言跟随已完成设置 Tab 点击和强停重启回显；顶部 Logo/标题区已改为半透明渐变过渡，底部 Tab 为半透明 Thin blur 胶囊；完整主题包、四语言、字体/高对比/无障碍和完整切换矩阵未完成 |
| 连接管理 | RDB、分组、收藏、搜索、8 种排序、统计、日志、批量编辑 | RDB-backed 仓库已支持分组、收藏、搜索、8 类排序、连接成功/失败统计和本地审计摘要；首页已接搜索/命中高亮/收藏/排序/分组筛选/批量操作 UI、分组管理入口、访问日志入口和连接历史入口；分组页已注册并支持新建/折叠/删除空分组；访问日志页已注册并能显示连接认证、批量操作和分组变更摘要，可唤起系统保存选择器导出 summary-only JSON，并支持事件筛选芯片；连接历史页已注册并能展示空状态；2026-06-29 已通过 Mock/Real HAP 编译、Real HAP 安装冷启动、访问日志点击、连接历史点击、基础新增分组和分组变更摘要跨重启回显、多页全屏 UI hierarchy 抽样；完整命令审计、导出文件回读、连接历史真实数据、批量/高亮逐项点击、统计页和完整 Room 级迁移未完成 |
| 工具箱/开发工具 | 网络拓扑、测速、IP、端口扫描、JSON、编码、二维码、取色、文本、单位转换 | `ToolboxPage` 已注册并能从工作台右上角和设置 Tab 进入；JSON 格式化/压缩、Base64 编解码、FNV-1a 快速校验、文本统计、颜色转换、单位换算、系统/存储/IP 基础信息、公网 IP、访问审计跳转、默认网络/DNS/网关摘要、TCP 连通性探测、端口扫描、HTTP 下载样本测速、Nginx 配置摘要和 QR 负载摘要已编码；JSON、Encoding、网络拓扑、端口扫描和公网 IP 已取得 Real HAP 页面层级输出证据；主动子网发现、上传测速、特权 ICMP、二维码图片矩阵、更多网卡字段和复杂 Nginx include/变量展开未完成 |
| 监控/通知 | TCP 探测、CPU/内存/磁盘阈值、恢复通知、冷却时间 | 占位页；未开始 |
| 备份/同步 | 加密 ZIP、SAF 云盘、PBKDF2、三方合并/冲突 UI | 脱敏 JSON 连接备份导入/导出已编码并通过 Real HAP picker 入口验证，不包含密码、私钥文件、私钥口令或命令输出；加密 ZIP、云同步、冲突合并、真实文件回读和导入样本落库待补 |
| 自动化/服务卡片 | Tasker、Intent/deep link、Widget/FormExtension | 未开始 |
| 多主机 Dashboard | 独立分组、CPU/内存/磁盘并排指标 | 未开始 |
| Proxmox | REST、VM/LXC 电源、termproxy、VNC fallback、统计 | 未开始 |
| XCP-ng/XO | XML-RPC/REST/WebSocket、状态、快照、备份、自动探测 | 未开始 |
| VMware | ESXi/vCenter 自动探测、VM 电源管理 | 未开始 |
| QEMU/libvirt | virsh、电源、SSH 隧道 VNC、ProxyJump fallback | 未开始 |
| 8 家云厂商 | DO/Hetzner/Linode/Vultr/AWS/GCP/Azure/OCI、状态/电源/SSH | 未开始 |
| VNC RFB | Tight/ZRLE/CopyRect/Hextile/CoRRE/RRE、Fence、resize、DES auth、键盘 | 未开始 |

## 本轮对齐新增字段、RDB 能力、批量/高亮与 UI

`entry/src/main/ets/common/models/ConnectionProfile.ets` 已增加 Android Profile 常见能力所需字段：

- HostKey：`hostKeyAlgorithm`、`hostKeyTrustedAt`
- 代理：`proxyUsername`、`proxyAuthType`、`proxyKeyId`
- 网络：`ipMode`、`compression`、`connectTimeoutMilliseconds`、`readTimeoutMilliseconds`、`serverAliveIntervalSeconds`
- 会话：`remoteCommand`、`sendEnv`、`requestTty`、`agentForwarding`、`x11Forwarding`、`moshMode`
- 多路复用：`multiplexerMode`、`multiplexerSessionName`
- 管理：`groupId`、`sortOrder`、`favorite`、`lastConnectedAt`、`connectionCount`、`lastErrorMessage`、`remarks`
- 同步：`createdAt`、`modifiedAt`、`syncVersion`、`syncDeviceId`

`ConnectionGroup.ets` 和 `ProfileRepository.ets` 已增加默认分组、过滤、排序、RDB 持久化、连接成功/失败统计、本地审计摘要和非覆盖导入合并入口。`ConnectionAuditLog.ets` 与 `AuditLogPage.ets` 提供连接认证、批量操作和分组变更摘要日志、summary-only JSON 导出和事件筛选；`ConnectionHistoryPage.ets` 使用 profile 统计字段提供只读连接历史空状态和列表框架；`ConnectionImportExportService.ets` 与 `ConnectionImportExportPage.ets` 提供 OpenSSH config 和脱敏 JSON 连接备份导入/导出。为避免敏感信息扩大落库，当前不导出或记录命令输出、密码、私钥文件、私钥口令；访问日志也不记录服务器地址。`Index.ets` 已保持现有 UI 样式接入搜索、命中高亮、收藏筛选、分组筛选、排序芯片、分组管理入口、访问日志入口、连接历史入口、导入导出入口、工作台内联已保存主机列表、工作台工具箱入口、设置 Tab 展开、顶部半透明渐变、底部半透明胶囊、收藏切换、批量选择、批量收藏/取消收藏、批量移组、批量删除和统计展示。`ToolboxPage.ets` 已新增并注册页面路由，提供工具箱页面、首批纯 ArkTS 小工具和纯 HarmonyOS 网络工具子集；`AppSettings.ets`、`AppTheme.ets` 与 `I18n.ets` 提供浅色/深色、中文/English 和系统语言跟随偏好，并已覆盖主壳、设置 Tab、工具箱、关于、终端设置、连接历史、访问日志、连接分组、连接导入导出、连接编辑、终端、SFTP 和端口转发等页面；`BuildInfo.ets` 与构建脚本提供关于页版本/构建时间。`ConnectionGroupPage.ets` 已新增并注册页面路由，支持分组列表、新建分组、折叠/展开、删除空分组和每组主机数。本轮已取得 Mock/Real HAP 编译、Real HAP 安装、访问日志点击、导出选择器唤起、访问日志筛选空状态、连接历史点击、导入导出页点击、导入/导出 picker 唤起、工具箱入口、JSON/Encoding 工具面板输出、工具箱网络拓扑和端口扫描输出、设置 Tab 展开/滚动、设置 Tab 系统语言跟随点击与强停重启回显、关于页版本构建时间、主题/语言源码覆盖、冷启动、基础新增分组与分组变更摘要跨重启回显、多页全屏 UI hierarchy 抽样和首页顶部渐变最终截图；但仍未取得完整设备点击、导入样本落库回显、导出文件内容回读、HTTP 测速/连通性/Nginx/QR 工具逐项设备点击、完整主题/语言切换矩阵和 schema migration 验收。字段/UI/RDB 未完成这些验收前，不能把对应 Android 功能标记为完成。

只有矩阵行的全部子项在目标 HarmonyOS API 上取得端到端证据，才可把该行标成完成。
