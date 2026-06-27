# 功能进度

## 已实现（Mock 基线）

- HarmonyOS Stage 模型、`com.open.tabssh`、arm64-v8a/x86_64 配置。
- 首页、连接编辑、连接分组、终端、SFTP、端口转发、设置、关于页面。
- Native N-API 接口与内存 Mock session/channel/forward。
- 内存连接配置仓库；示例配置不含密码。
- 统一文档、路径、清理、备份、审计和发布脚本规范。
- 单次静态基线审计 29/29；Mock unsigned HAP 构建成功并确认双 ABI native entries。
- Web/Android/Desktop 三份上游源码已在 `99_Temp\tabssh_reference` 建立浅克隆参考。
- Mock fallback 新契约已完成 x86_64 模拟器覆盖安装和冷启动验证；证据见 `BUILD_TEST.md`。
- `.github/workflows/online-build.yml` 已收敛为纯 GitHub `ubuntu-latest` 的最小线上 HAP 格式构建入口，并已参考 `rustdesk_harmonyos` 的 Linux 成功结构重写：基础 SDK 初始化、full SDK 安装、full hvigor 替换、SDK 环境变量设置、Hvigor 构建、HAP zip 格式校验、双 ABI `libentry.so` 检查和 artifact 上传。该 workflow 当前只验证 Mock unsigned HAP 格式，静态审计、Real HAP、push/PR 自动触发后续验证通过后再逐步加回。
- `scripts/run_local_checks.ps1` 已作为本地拉取后一键检查入口：默认串联 `git diff --check`、全局静态审计、连接分组专项审计、终端解析器测试、Mock 构建和验包；可选 `-WithRealCore` 与 `-BuildDependencies` 执行真实 HAP 与三方依赖路径。
- `scripts/install_and_smoke.ps1` 已作为安装/冷启动冒烟入口：安装 `99_Temp` 中的 HAP、启动 `com.open.tabssh`、采集 bundle/PID/hilog/faultlogger 线索，并输出无凭据摘要；该脚本只做安装启动检查，不标记 SSH 功能完成。
- `scripts/audit_project.ps1` 已增加连接分组基础审计项；`scripts/audit_connection_groups.ps1` 已增加专项审计，并接入一键检查，覆盖分组页面、路由、仓库接口、改名、换色、排序、折叠和文档同步。

## 已编码、待真实构建与端到端验证

- 线上 Linux HAP workflow 尚未取得本仓库成功 run 证据；下一步必须先跑 `TabSSH Linux HAP format build`，确认 artifact、SHA256 和 HAP 文件列表，再决定是否加回审计或 Real HAP。
- 固定 libssh2 `1.11.1`、OpenSSL `3.5.7 LTS`、zlib `1.3.2` 的双架构依赖已构建并生成 SHA/commit manifest；真实 HAP 已通过双 ABI marker/machine 验证和 x86_64 加载冷启动。
- 真实 Core 的非阻塞握手、HostKey SHA256 阻断/确认、密码/私钥认证、PTY shell、读写/resize、SFTP 列目录和断开清理源码。
- CMake 根据 stage 中经过清单校验的静态库自动切换真实 Core；源码 checkout 继续明确回退 Mock。
- ArkTS 首次 HostKey/变更警告流程；凭据仅保留在运行内存，Mock 不再保存 profile JSON。
- Android 对齐字段骨架已扩展到 `ConnectionProfile`：HostKey 元数据、代理认证、IPv4/IPv6 模式、压缩、agent/X11/Mosh、RemoteCommand、SendEnv、RequestTTY、多路复用、分组/收藏/排序/统计、同步元数据等。字段仅代表可承载配置，未接 UI/Native/RDB 的功能不能标记完成。
- 新增 `ConnectionGroup`、`ProfileFilter` 与内存仓库分组/过滤/排序接口，用于对齐 Android 的连接管理基础；当前仍未接 RDB 或持久化。
- `ConnectionGroupPage` 已注册页面路由，用现有浅蓝背景、白色圆角卡片和 ProIcons 风格展示分组列表、新建分组、改名、换色、上移/下移、折叠/展开、空分组移除和每组主机数。当前首页入口未接入，且尚未 HAP 编译/设备点击验证。
- 首页连接页已保持现有浅蓝背景、白色圆角卡片、蓝色芯片和悬浮胶囊底栏风格，接入连接搜索、收藏筛选、排序芯片、收藏切换、连接次数/上次失败提示。该 UI 仍需 HAP 编译和设备渲染验证。
- 会话管理已把认证成功写入内存统计 `lastConnectedAt/connectionCount`，把认证失败、HostKey 确认失败、异常中断和重连异常写入 `lastErrorMessage`；退出应用后仍会丢失，未完成 Android Room/RDB 级统计。
- 私钥通过系统文档选择器复制到应用私有 `filesDir/ssh_keys`，不记录原文件 URI 或内容，并提供应用内删除入口；真实包已在 x86_64 模拟器覆盖安装，端到端认证待验。
- 模拟器已验证系统文档选择器 UI 可打开；同时发现并修复连接编辑返回后的列表刷新问题。
- 首次真实连接发现同步 N-API 导致 `APP_INPUT_BLOCK`；`connect`、`openShell`、`sftpList` 已迁移为 async work / Promise 并完成 Mock/真实双架构构建，尚待安装回归。
- 上述异步真实 HAP 已成功覆盖安装到 x86_64 模拟器；HostKey/认证/PTY/SFTP 和无 appfreeze 回归仍待取证。
- x86_64 模拟器已通过本机隔离测试端的真实 SSH 流量回归：异步握手保持 UI 响应，HostKey 首次/变化阻断、密码认证、PTY、命令读写、ANSI 渲染和真实 SFTP 根目录列表均通过，无新增 faultlogger 记录。
- 外部 IPv6 Windows OpenSSH 已进一步通过 ECDSA HostKey、密码认证、PTY、CR 命令提交/真实输出、SFTP 列表、异步关闭和无重复 HostKey 提示的再次连接；无新增 faultlogger 记录。
- 底部主菜单已参照 RustDesk HarmonyOS 改为安全区内的半透明模糊悬浮胶囊；旧自绘底栏 SVG 已替换为 ProIcons 的 tune/network/monitor/person 资产。旧版本的点击切换证据仍有效，最新 ProIcons 资源包待本轮重新构建安装后更新证据。
- 四张参考图对应的连接入口页、设备监控空状态、我的/设置页和系统设置二级页已实现；主要菜单行统一降为 54–62 vp，模拟器逐页 UI hierarchy 验证通过。
- 真实 SFTP 已增加异步上传、下载、建目录、删除、重命名和 chmod；回环内存测试端完成上传→下载逐字节校验、目录、改名、`0644`与清理证据。
- SFTP 数据泵已把网络超时从“整次传输总时限”改为每次成功读写后续期的“空闲时限”，下载结束增加本地 flush 校验；系统 URI 与应用缓存之间改用异步 `fs.copyFile`，避免大文件同步复制阻塞 ArkUI。仍缺真实大文件、取消和中断恢复证据。
- 三类转发已编码：本地 `-L` 与动态 `-D` 只监听 `127.0.0.1`，动态转发实现无认证 SOCKS5 CONNECT（IPv4/IPv6/域名），远程 `-R` 请求服务器回环监听；多连接 worker、异步 N-API、显式移除和 session 断开前清理已接入。当前通过 arm64 与 x86_64 OHOS Clang `-fsyntax-only`，仍需真实构建与三类逐字节流量证据。
- 终端已编码 libssh2 keepalive、断线检测和网络感知自动重连：仅曾成功连接的 tab 参与，初始失败/认证失败/HostKey 待确认/正常 shell 退出不自动重试；退避为 5 秒起步、指数增长、5 分钟封顶，支持“立即重连”，离线时暂停，系统 `netAvailable` 恢复时立即重试，并有 5 分钟 `hasDefaultNet` 兜底轮询。重建 session/PTY 前先释放旧 channel、forward 和 session；keepalive 与 native 改动通过双 ABI语法检查，仍缺 HAP 编译及设备断网/恢复证据。
- 有界 2,000 行历史的 VT 单元格解析器已编码：常用光标/擦除/插删/滚动区、SGR 16/256/RGB 色、粗体/暗色/斜体/下划线/反色/隐藏/删除线、备用屏、OSC 标题、DSR/DA 回复、application cursor、bracketed paste、组合字符和 CJK/Emoji 双宽字符；TerminalPage 已接入样式 `Span`、复制、横向控制键和视口驱动的 PTY resize。独立内存测试全部通过，但最新 UI 尚未经过 HAP 编译/设备复杂 TUI 回归，不能称完整 xterm。
- 启动、导航、页面入口、文件类型、返回/刷新和方向键图标已统一为 `docs/PROICONS_ICONS.md` 登记的 ProIcons SVG；源码不再使用 Emoji/Unicode 字符充当图标。

以上 SSH 密码认证、PTY/命令与 SFTP 列目已有真实外部服务器证据；SFTP 写操作已有隔离回环端证据。私钥认证、三类转发、大文件/中断恢复和 arm64 真机仍不能标记完成。

## 未实现（发布阻塞）

- 私钥认证、外部服务器与 arm64 真机端到端证据；HUKS/ASSET 安全存储。
- 连接管理仍未完成：RDB 持久化、首页分组入口、批量编辑、搜索结果高亮、统计页和设备端筛选/分组渲染证据均待实现。
- 终端剩余兼容：完整键盘/IME 逐键输入、选择与搜索、鼠标协议、更多 DEC/xterm 边界、vim/tmux/htop/nano 和设备端性能/渲染回归。
- SFTP 大文件、中断恢复、外部服务器写操作及系统文件保存选择器的稳定回归。
- local/remote/dynamic forwarding 的真实 HAP 与逐字节流量链路证据；源码实现不能替代验收。
- 代理/跳板机、多标签复用、后台保持。
- 异步操作的用户取消、重连/错误恢复设备证据和更完整的压力清理。
- arm64 真机与 x86_64 模拟器真实 SSH 端到端验收。
- 独立 HarmonyOS 签名配置与 signed HAP 安装验证。
