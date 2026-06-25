# Android TabSSH 对齐路线图

> 本文用于把 Android 版能力拆成 HarmonyOS 可执行阶段。每项只有同时完成源码、UI/Native 接入、构建、设备/流量证据和文档更新，才可标记完成。

## P0：SSH 客户端核心闭环

目标：先让 HarmonyOS 版成为可用 SSH 客户端，而不是功能目录。

1. 真实 Core 构建闭环
   - `build_native_dependencies.ps1`
   - `build_real_hap.ps1`
   - `verify_real_hap.ps1`
   - `install_and_smoke.ps1`
   - arm64 真机与 x86_64 模拟器均要有 HAP 哈希、PID、hilog/faultlogger 摘要。

2. HostKey / 认证
   - TOFU 首次确认。
   - HostKey 变化阻断。
   - password 成功/失败。
   - private key 成功/失败。
   - keyboard-interactive 后续再做，不阻塞首个真实可用版。

3. Shell / PTY
   - `whoami`、`pwd`、`ls -la`、`stty size`。
   - CR/LF 在 Linux、OpenWrt、Windows OpenSSH 的差异。
   - resize 后远端尺寸同步。
   - 正常 `exit` 不误触发重连。

4. 终端基础兼容
   - ANSI/SGR、滚动、复制、CJK/Emoji。
   - vim、tmux、htop、nano 冒烟。
   - 复杂 TUI 性能和虚拟化策略。

5. SFTP 基础
   - list、进入目录、返回上级。
   - 上传、下载、重命名、chmod、删除。
   - 小文件 SHA256 和大文件空闲超时。

6. 端口转发基础
   - local `-L` 字节回显。
   - dynamic `-D` SOCKS5 IPv4/IPv6/域名。
   - remote `-R` 服务器回环监听。
   - 移除规则和 session 断开释放端口。

## P1：Android 常用体验对齐

1. 连接管理
   - RDB Store 替换内存仓库。
   - 分组、收藏、搜索、排序。
   - 连接统计：lastConnectedAt、connectionCount、lastErrorMessage。
   - 批量编辑和删除。

2. SSH config / 高级连接
   - remoteCommand。
   - sendEnv。
   - requestTty。
   - ipMode IPv4/IPv6/auto。
   - compression。
   - agentForwarding。

3. 代理和跳板
   - HTTP/SOCKS4/SOCKS5 proxy。
   - ProxyJump 单跳。
   - ProxyJump 多跳。

4. 多标签
   - 多 tab 切换。
   - tab 状态点。
   - OSC title 显示。
   - 共享 session 多 channel 或独立 session 策略。

5. 自定义键盘
   - Ctrl/Alt/Esc/Tab/方向键。
   - F1–F12。
   - 可重排工具栏。
   - 硬件键盘修饰键。

6. 安全与隐私
   - HUKS/ASSET 凭据存储。
   - 生物识别解锁。
   - 自动锁。
   - 剪贴板自动清理。
   - 防截图策略验证。

## P2：增强能力

1. 会话增强
   - tmux/screen/zellij 自动 attach/create。
   - post-connect script。
   - snippets。
   - macros。
   - session recording。

2. SFTP 高级功能
   - 进度条。
   - 取消。
   - 失败恢复。
   - 远程编辑。
   - 大文件哈希和断点策略。

3. 监控和通知
   - TCP 探测。
   - 在线/离线变化。
   - CPU/内存/磁盘阈值。
   - 通知冷却时间。

4. 备份/同步
   - 加密 ZIP。
   - PBKDF2 / AES-GCM。
   - 导入/导出。
   - 冲突合并 UI。

## P3：Android 版高级生态

1. FormExtension / Widget。
2. Deep link / 自动化入口。
3. Proxmox / XCP-ng / VMware / libvirt。
4. 云厂商 DO/Hetzner/Linode/Vultr/AWS/GCP/Azure/OCI。
5. VNC RFB。
6. Mosh / X11。

## 当前本轮已做

- 扩展 `ConnectionProfile` 模型，使其能承载 Android 常见字段。
- 新增 `normalizeConnectionProfile()`，让旧内存对象自动补齐新字段。
- 更新 `ANDROID_TO_HARMONY_MAPPING.md`，明确字段骨架不等于功能完成。

## 下一轮建议

优先做 P1 的连接管理基础：

1. 新增 `ConnectionGroup`、`ProfileSortMode`、`ProfileFilter` 模型。
2. 在内存仓库先实现分组、收藏、搜索、排序。
3. 更新首页 UI 只做轻量入口，不接 RDB。
4. 取得 Mock HAP 编译证据后，再推进 RDB Store。

## 验收规则

- 字段骨架：只算“可承载配置”。
- UI 接入：只算“用户可编辑配置”。
- Native 接入：只算“参数传到 Core”。
- 设备证据：只算“功能通过”。
- 文档同步：每轮必须更新 `FILES / PROGRESS / ISSUES / BUILD_TEST` 中相关项。
