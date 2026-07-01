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
   - RDB Store 替换内存仓库。（已编码 JSON row 方案，新增分组与分组变更摘要已通过基础跨重启回显，仍待完整点击矩阵和迁移策略）
   - 分组、收藏、搜索、排序。
   - 连接统计：lastConnectedAt、connectionCount、lastErrorMessage。
   - 批量编辑和删除。（已编码，待设备逐项点击验收）
   - 审计/访问日志。（摘要日志已编码，分组变更摘要已通过基础跨重启回显，导出保存选择器和事件筛选空状态已验证，仍待真实认证事件、导出文件回读和完整命令审计）

2. SSH config / 高级连接
   - remoteCommand。（OpenSSH config 导入/导出已读写该字段，Native 使用仍待补）
   - sendEnv。（OpenSSH config 导入/导出已读写该字段，Native 使用仍待补）
   - requestTty。（OpenSSH config 导入/导出已读写该字段）
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

7. 主题、语言和工具箱
   - 浅色/深色主题。（主壳、工作台、设置 Tab、设置页、工具箱和部分二级页已编码，仍待全局覆盖）
   - 中文/English 双语。（主壳、工作台、设置 Tab、设置页、工具箱和部分二级页已编码，仍待全局覆盖）
   - 工具箱入口和分类。（入口、首批纯 ArkTS 开发/系统小工具和纯 HarmonyOS 网络工具子集已编码，剩余网络能力和逐项设备证据待补）

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
   - 导入/导出。（已实现 OpenSSH config 与脱敏 JSON 连接备份的纯 HarmonyOS picker 路径；加密 ZIP、云同步、真实文件回读和冲突合并待补）
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
- 在首页工作台与连接页接入 `ConnectionGroupPage` 入口，并在连接页加入全部分组/分组名筛选芯片；2026-06-29 已取得 Mock HAP 编译、安装、冷启动和首屏入口可见性证据。
- `ProfileRepository` 接入 HarmonyOS `relationalStore` RDB，保存分组、主机配置、收藏、排序、HostKey 元数据和连接统计；密码与私钥口令写库前清空。新增分组与分组变更摘要已通过基础跨重启回显，当前待完整设备点击、收藏/统计跨重启和 schema 迁移验证。
- 首页连接页新增搜索命中高亮、批量模式、批量收藏/取消收藏、批量移组和批量删除；当前已通过 Mock/Real HAP 编译与 Real HAP 安装/首屏可见性检查，仍待设备逐项点击和跨重启回归。
- `EntryAbility` 开启全屏布局、透明系统栏、窗口隐私保护和避让区写入，所有已注册 ArkUI 页面根容器使用避让区 padding；当前已通过 x86_64 多页无凭据抽样，仍待横竖屏、手势导航、挖孔、软键盘和终端长会话矩阵。
- 新增 `AuditLogPage`、`ConnectionAuditLog` 和 RDB `connection_audit_logs` 摘要表；首页“访问日志”入口已通过 HAP 点击进入和页面层级验证，分组变更摘要已通过基础跨重启回显，summary-only JSON 导出可唤起系统保存选择器，事件筛选芯片已通过设备层级验证。当前仅记录认证结果、批量操作和分组变更摘要，完整 Android 审计日志仍待补。
- 新增 `ConnectionHistoryPage`，对齐 Android `ConnectionHistoryActivity` 的只读历史视图；当前基于 RDB profile 统计字段聚合历史主机、成功主机和失败记录，工作台入口与空状态已通过 Real HAP 页面层级验证，真实成功/失败行和点击进入终端仍待补。
- 新增 `ConnectionImportExportPage` 与 `ConnectionImportExportService`，对齐 Android `ImportExportActivity` 的安全核心路径；当前支持 OpenSSH config 导入/导出和脱敏 JSON 连接备份导入/导出，工作台入口、新页面首屏、JSON 导出保存选择器和 OpenSSH 导入选择器已通过 Real HAP 页面层级验证。导入采用非覆盖合并和主机/端口/用户去重；加密 ZIP、云同步、QR 配对、真实文件写入/回读和导入样本落库仍待补。
- 工作台右上角入口已从系统设置改为工具箱，工作台主机管理卡片左侧点击进入 `SavedHostsPage` 已保存主机列表，右侧“添加”按钮保留原新增主机流程；卡片下方不再显示新增主机、已保存主机和连接历史三行入口，也不直接显示 RDB 保存主机的名称、地址、用户、端口、状态或连接按钮。完整保存主机列表和批量管理已移入 `SavedHostsPage` 独立页面，连接页原保存列表改为最近 10 条连接历史摘要。第四个底部 Tab 已改为“设置”，并从“设置 / 工具 / 工具箱”接入同一 `ToolboxPage`。2026-07-01 已为资料变更补 `profileRefreshToken` 刷新令牌，避免新增/编辑/删除或真实连接统计变更后必须手动切 Tab 才刷新；连接页 logo 下方 SSH 横幅已移除。工具箱页当前提供本机信息、搜索、网络/系统/开发分类，并已实现 JSON 格式化/压缩、Base64 编解码、FNV-1a 快速校验、文本统计、颜色转换、单位换算、系统/存储/IP 基础信息、公网 IP、受控子网发现、访问审计跳转、默认网络/DNS/网关/路由/地址族摘要、TCP 连通性探测、ICMP 等价验收、端口扫描、HTTP 下载/上传测速、Nginx 配置摘要/同输入变量展开/include 检出和 QR Version 2-L 矩阵、二维码预览和 SVG 保存选择器；网络拓扑、端口扫描、公网 IP、受控子网发现、HTTP 下载/上传测速、连通性、ICMP 等价验收、Nginx 同输入变量/include 摘要、QR 矩阵、二维码预览和 SVG 保存选择器已有 Real HAP 设备输出。二维码 SVG 真实目标写入/回读、PNG/相册保存、扫码兼容性和进一步美化、IP 详情路由/地址族设备点击、多网卡枚举和外部 Nginx include 文件导入/展开仍待补。
- 新增 `AppSettings`、`AppTheme` 与 `I18n`，设置 Tab 可切换浅色/深色、中文/English 和系统语言跟随，偏好通过 HarmonyOS preferences 持久化。当前已覆盖首页主壳、工作台、设置 Tab、设置页、工具箱、关于、终端设置、连接历史、访问日志、连接分组、连接导入导出、连接编辑、终端、SFTP 和端口转发页；系统语言跟随已完成设置 Tab 点击和强停重启回显，仍需无障碍/高对比和完整切换矩阵。顶部 Logo/标题区已改为半透明渐变过渡，底部 Tab 保留半透明 Thin blur 胶囊，`BuildInfo.ets` 与构建脚本已接入关于页版本/构建时间展示。

## 下一轮建议

优先继续 P1 的连接管理基础：

1. 取得完整设备点击和跨重启证据，覆盖首页分组入口、分组筛选、改名、折叠/展开、收藏、批量选择/移组/删除、搜索高亮、真实连接访问日志回显、连接历史真实行、统计和返回刷新；分组新增与分组变更摘要跨重启已完成基础验证。
2. 补 RDB schema version / migration 记录，明确 JSON row 方案到规范化表结构的升级边界。
3. 补全屏避让多设备矩阵，确认顶部标题、滚动区域、半透明顶部/底部玻璃层和底部胶囊导航不被系统栏遮挡，且空白 overlay 不阻断滚动。
4. 补齐工具箱剩余真实工具能力，优先使用纯 HarmonyOS API 继续完善二维码 SVG 真实目标写入/回读、PNG/相册保存、扫码兼容性和进一步美化、IP 详情路由/地址族设备点击、多网卡枚举和外部 Nginx include 文件导入/展开；ICMP 目前以普通应用可用的默认网络、DNS 解析和 TCP connect 做等价验收，只有 HarmonyOS API 无法实现时才考虑三方库。
5. 验证主题/语言完整矩阵：系统语言跟随已完成设置 Tab 点击和强停重启回显，下一步补多页面切换即时刷新、无障碍/高对比和动态文案。
6. RDB 与批量/高亮/访问日志点击验证通过后继续推进统计页、导出文件回读、导入样本落库、加密备份和同步。

## 验收规则

- 字段骨架：只算“可承载配置”。
- UI 接入：只算“用户可编辑配置”。
- Native 接入：只算“参数传到 Core”。
- 设备证据：只算“功能通过”。
- 文档同步：每轮必须更新 `FILES / PROGRESS / ISSUES / BUILD_TEST` 中相关项。
