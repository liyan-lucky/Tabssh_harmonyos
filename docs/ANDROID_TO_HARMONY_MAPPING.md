# Android TabSSH 到 HarmonyOS OpenTabSsh 映射

> 2026-06-22：本文是目标映射，不代表全部实现。当前完成度以 `AGENT_HANDOFF.md` 和 `PROGRESS.md` 为准；构建测试路径以 `WORKSPACE_PATHS.md` 为准。

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
| TermuxBridge / TerminalEmulator | 后续自研 ANSI/VT 解析和终端渲染 |
| Room DB | 后续换成 RDB Store |
| Android Keystore | 后续换成 HUKS / ASSET |
| WorkManager | 后续换成 HarmonyOS 后台任务能力 |
| AppWidgetProvider | 后续换成 FormExtensionAbility |

## Android `0c455b8b...` 全功能验收矩阵

状态含义：`编码中` 只表示已有源码，`待验证` 表示必须取得真实 HAP/设备/流量证据，`未开始` 表示当前仓库没有可验收实现。页面、函数名或 Mock 返回不构成功能完成。

| Android 能力组 | HarmonyOS 对齐范围 | 当前状态 |
|---|---|---|
| 多标签/共享 SSH session | 多 channel、标签切换、OSC 标题、状态点、后台会话 | 基础单页 manager；未开始完整对齐 |
| 密码/私钥/keyboard-interactive | RSA/ECDSA/Ed25519/DSA、OpenSSH/PEM/PKCS#8/PuTTY、导入/生成 | 密码/文件私钥 libssh2 源码编码中；其余未开始 |
| HostKey 安全 | SHA256 TOFU、变更阻断、可信核对、known_hosts | 阻断/确认 UI 与 native 源码编码中；待真实验证和持久化 |
| Shell/PTY | 非阻塞读写、resize、keepalive、IPv4/IPv6、超时/取消 | libssh2 源码编码中；待真实构建与双设备验证 |
| 终端模拟器 | VT100/ANSI/xterm-256、颜色、选择复制、滚动、搜索、OSC、vim/tmux | 基础无颜色网格/轮询已做 Mock 冒烟；完整兼容未开始 |
| 自定义键盘/硬件键盘 | 1–5 行、重排、Ctrl/Alt、AltGr、修饰键编码、F1–F12 | 六个基础键入口；其余未开始 |
| SFTP | 浏览、上传/下载进度、编辑、chmod、删除、重命名、哈希 | 真实列目录源码编码中；写操作/UI/哈希未开始 |
| 端口转发 | local、remote、dynamic SOCKS5、生命周期、真实流量 | UI 禁止 Mock 成功；真实 worker 未开始 |
| 代理/跳板 | ProxyHTTP/SOCKS4/SOCKS5、ProxyJump、多跳 | 未开始 |
| SSH config | Import、RemoteCommand、SendEnv、RequestTTY、ProxyJump | 未开始 |
| 会话增强 | post-connect、tmux/screen/zellij、录制/回放、宏、片段 | 字段骨架；其余未开始 |
| X11/Mosh | Termux:X11/XServer、Mosh roaming | 未开始 |
| 凭据安全 | HUKS/ASSET、AES-256-GCM、生物识别、自动锁、内存擦除 | profile JSON/口令擦除源码编码中；安全存储与生物识别未开始 |
| 隐私防护 | 截图保护、剪贴板自动清除、零遥测 | 未开始 |
| 主题/可访问性 | 22 主题、自定义/WCAG、字体、TalkBack、高对比、键盘导航、四语言 | 未开始 |
| 连接管理 | RDB、分组、收藏、搜索、8 种排序、统计、日志、批量编辑 | 内存示例仓库；其余未开始 |
| 监控/通知 | TCP 探测、CPU/内存/磁盘阈值、恢复通知、冷却时间 | 占位页；未开始 |
| 备份/同步 | 加密 ZIP、SAF 云盘、PBKDF2、三方合并/冲突 UI | 未开始 |
| 自动化/服务卡片 | Tasker、Intent/deep link、Widget/FormExtension | 未开始 |
| 多主机 Dashboard | 独立分组、CPU/内存/磁盘并排指标 | 未开始 |
| Proxmox | REST、VM/LXC 电源、termproxy、VNC fallback、统计 | 未开始 |
| XCP-ng/XO | XML-RPC/REST/WebSocket、状态、快照、备份、自动探测 | 未开始 |
| VMware | ESXi/vCenter 自动探测、VM 电源管理 | 未开始 |
| QEMU/libvirt | virsh、电源、SSH 隧道 VNC、ProxyJump fallback | 未开始 |
| 8 家云厂商 | DO/Hetzner/Linode/Vultr/AWS/GCP/Azure/OCI、状态/电源/SSH | 未开始 |
| VNC RFB | Tight/ZRLE/CopyRect/Hextile/CoRRE/RRE、Fence、resize、DES auth、键盘 | 未开始 |

只有矩阵行的全部子项在目标 HarmonyOS API 上取得端到端证据，才可把该行标成完成。
