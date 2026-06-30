# 已知问题与风险

## P0：真实 SSH 端到端尚未通过

源码 checkout 没有生成的三方静态库时，CMake 明确编译 `native_ssh_mock.cpp`。固定三方库和真实 Core 双 ABI HAP 已完成构建、链接、验包和 x86_64 冷启动，密码认证/PTY/SFTP 已有端到端证据；私钥、arm64 真机和端口转发仍阻塞生产使用。端口转发 UI 已禁用 Mock 成功提示。

2026-06-22 首次真实连接暴露同步 N-API 主线程卡死，系统以 `APP_INPUT_BLOCK` 终止进程。现有网络与 SFTP 操作均已迁移到后台 async work，x86_64 模拟器没有新增 faultlogger 记录；用户取消正在进行的 native async work 仍需实现。

read/write/resize/close/disconnect 现也已迁移到 async work，并在外部 Windows OpenSSH 完成命令、SFTP、关闭和再次连接回归；已知旧 appfreeze 没有复现。尚未实现用户取消正在进行的 native async work，极端慢服务器下的任务终止仍是风险。

三类转发 worker 已编码但尚无 HAP/设备流量证据。重点风险是同一 libssh2 session 上终端、SFTP 与多个转发 channel 的并发、公网 sshd 是否允许 remote forward、SOCKS5 半关闭、端口占用和断开竞态；必须以真实 TCP 回显/哈希、监听地址和断开后端口释放分别验收。

重连退避和 HarmonyOS `NetConnection` 网络状态观察器已编码，但尚未经过 Hvigor/HAP 与设备验证。需验证权限/API 兼容、用户关闭、HostKey 变化、认证失败、正常 EOF、前后台切换、网络回调丢失兜底和断网恢复不会产生重连风暴或资源泄漏。

2026-06-22 SFTP 系统文档选择器的“保存”界面在当前 x86_64 自动化模拟器上出现 Promise 未返回且界面未显示；已通过应用私有缓存中的受限文本上传→下载回读完成核心数据校验，但系统保存选择器还需真机手工验证和取消/超时处理。

## P0：凭据与 HostKey 安全

密码、私钥和口令不能进入源码或普通首选项。HostKey 首次信任/变更警告已编码；私钥文件可导入应用私有目录并删除，但长期凭据仍需 HUKS/ASSET 安全存储。初始源码中的示例密码已移除。

## P1：线上 Linux HAP 构建仍待首次跑通

2026-06-26 曾把线上构建误按自托管 Windows runner 设计，导致 workflow 长时间处于已列队状态。经验总结：纯 GitHub 在线构建必须使用 GitHub 托管 Linux runner，不能依赖自托管 runner 标签。

2026-06-26 当前 `.github/workflows/online-build.yml` 已改为参考 `rustdesk_harmonyos` 成功结构：基础 SDK 初始化、full SDK 安装、full hvigor 替换、环境变量设置、Hvigor 构建、HAP zip 检查和双 ABI `libentry.so` 检查。该流程尚未在本仓库取得成功 run 证据；失败时优先查看 full SDK 安装、full hvigor 替换、SDK 定位和 Hvigor 构建四段日志。

2026-06-26 线上构建现在只验证 Mock unsigned HAP 格式，不自动跑静态审计、不构建 Real HAP、不响应 push/PR。经验总结：必须先让最小 Linux HAP 格式构建通过，再逐步加回 PowerShell/静态审计、分组专项审计、安装冒烟、Real HAP 和 push/PR 自动检查，避免一次失败无法定位原因。

## P1：文档与配置曾不一致

旧 README 写 `io.github.opentabssh`，实际 `build-profile.json5` 与 `AppScope/app.json5` 均为 `com.open.tabssh`；现已统一，以构建配置为准。

2026-06-25 经验规则：每轮新增或修改脚本、Native、ArkTS 页面、资源、构建流程后，必须同步更新至少一个状态文档。最低要求：新增文件写入 `docs/FILES.md` 或 `scripts/README.md`；新增测试流程写入 `docs/PULL_TEST_GUIDE.md` 或 `docs/BUILD_TEST.md`；发现风险写入本文件；完成/待验状态写入 `docs/PROGRESS.md`。不能只改代码不更新文档。

2026-06-25 经验补充：`docs/BUILD_TEST.md` 含旧 HAP 哈希、失败栈和设备验证结论，不能为了加入新入口而覆盖成短摘要。构建测试文档只能追加或补充；若误压缩历史，必须从 Git 历史恢复旧证据并记录修复过程。

## P1：Android 对齐字段骨架风险

2026-06-25 新增/扩展了 `ConnectionProfile`、`ConnectionGroup`、`ProfileFilter` 和仓库分组/排序/统计接口。2026-06-29 已接入 HarmonyOS `relationalStore` RDB，保存分组、主机配置、收藏、排序、HostKey 元数据和统计字段，但仍只是向 Android 连接配置模型靠拢的承载层，不代表代理、跳板、SSH config、Mosh、X11、同步或连接统计 UI 已完成。经验总结：新增字段后必须验证旧 profile 通过 `normalizeConnectionProfile()` 兼容；Native 只应读取明确支持的字段，不能因为字段存在就改变真实连接行为。

## P1：RDB 持久化仍缺跨重启交互证据

2026-06-29 `ProfileRepository` 已使用 `relationalStore` 创建 `connection_groups` 与 `connection_profiles`，并在写入前清空 `password` 和 `privateKeyPassphrase`。Mock/Real HAP 编译、安装和冷启动通过，说明 RDB 初始化未阻塞启动；同日新增分组与对应“分组变更 / 新增分组”摘要已在强停重启后回显。但尚未完成改名、换色、折叠、收藏、统计、旧内存对象迁移、异常损坏数据恢复和未来 schema version 迁移验证。经验总结：RDB 代码存在和单项重启回显不等于 Android Room 级数据层完成，凭据长期保存仍必须走 HUKS/ASSET。

## P1：首页筛选 UI 仍缺逐项点击验证

2026-06-25 首页连接页新增搜索输入、收藏筛选、排序芯片、收藏切换和连接统计展示，并尽量保持现有卡片、芯片和底部胶囊导航风格。2026-06-29 已继续补搜索命中高亮、批量模式、批量收藏/取消收藏、批量移组和批量删除，并通过本地全量检查、Mock/Real HAP 构建/验包、x86_64 模拟器 Real HAP 安装/冷启动和首屏层级冒烟；工作台也已改为直接显示保存主机，不再通过“主机列表”动作切到连接 Tab。仍必须补搜索、收藏、排序、分组筛选、批量操作、工作台列表新增/编辑/删除后的刷新和返回刷新逐项点击。经验总结：HAP 编译通过不等于交互完成；旧点击证据也不能外推到新筛选逻辑、批量删除路径或工作台主机列表刷新。

## P1：工具箱页网络类工具仍未全量完成

2026-06-29 新增 `ToolboxPage` 并从工作台右上角接入，工作台右上角不再打开系统设置；2026-06-30 第四 Tab 已改为“设置”，工具箱入口迁移为“设置 / 工具 / 工具箱”。页面使用已登记 ProIcons rawfile 资产展示本机信息、搜索、全部/网络/系统/开发分类和工具卡片，并通过 Mock/Real HAP 构建、安装和页面层级抽样。同日已补首批纯 ArkTS 工具能力：JSON 格式化/压缩、Base64 编解码、FNV-1a 快速校验、文本统计、颜色转换、单位换算、系统/存储/IP 基础信息和访问审计跳转，并在 Real HAP 上取得 JSON 与 Encoding 工具面板输出证据。随后继续使用纯 HarmonyOS API 接入默认网络/DNS/网关摘要、TCP 连通性探测、端口扫描、HTTP 下载样本测速、Nginx 配置摘要和 QR 负载摘要；最新 Real HAP 已取得网络拓扑默认网络输出和 `127.0.0.1 22,80,443` 端口扫描结果。仍缺 HTTP 下载测速、单项 TCP 连通性、Nginx 摘要和 QR 负载摘要的设备点击证据，也未实现主动子网发现、上传测速、特权 ICMP、二维码图片矩阵/美化、公网 IP、更多网卡字段和复杂 Nginx include/变量展开。经验总结：网络工具能返回基础结果不等于 Android 工具箱全功能完成，必须按真实 API/结果逐项验收。

## P1：主题与多语言仍未全局覆盖

2026-06-29 新增 `AppSettings`、`AppTheme` 和 `I18n`，设置页支持浅色/深色主题和中文/English 切换，偏好通过 HarmonyOS `preferences` 持久化，并用 `AppStorage` 驱动页面刷新。此前曾因 `@StorageProp` 只单向读取导致设置页英文局部不刷新，已改为 `@StorageLink` 并在设置动作中同步本地状态。2026-06-30 最新 Real HAP 已把主题/语言覆盖扩展到首页、设置 Tab、设置页、工具箱、关于、终端设置、连接历史、连接分组、导入导出、访问日志、连接编辑、终端、SFTP 和端口转发；全局审计 108/108。当前风险转为系统语言跟随、跨重启偏好保持、切换即时刷新、多页面点击矩阵、更多 service/audit 动态文案和无障碍/高对比验收。经验总结：主题/语言偏好存在不等于全局无障碍或国际化完成。

## P1：连接历史仍缺真实数据验收

2026-06-29 新增 `ConnectionHistoryPage`，对齐 Android `ConnectionHistoryActivity` 的只读历史列表，不新增历史表，直接使用 RDB profile 统计字段。最新 Real HAP 已验证工作台入口和空状态；但尚未完成真实连接成功后历史行、失败摘要行、点击历史行进入终端、重启后统计回显和大列表性能验证。经验总结：空状态和路由通过不等于连接历史功能完整。

## P1：连接导入导出仍缺真实文件验收

2026-06-29 新增 `ConnectionImportExportPage` 与 `ConnectionImportExportService`，对齐 Android `ImportExportActivity` 的安全核心路径：OpenSSH config 导入/导出、脱敏 JSON 连接备份导入/导出。导出会清空密码、私钥文件、私钥口令和命令输出；导入采用非覆盖合并并按主机/端口/用户去重。最新 Real HAP 已验证工作台入口、新页面首屏、JSON 导出保存选择器和 OpenSSH 导入选择器。但尚未完成真实保存目标写入/回读、真实 OpenSSH/JSON 样本导入落库、跨重启回显、重复导入去重、IdentityFile 警告、加密 ZIP、QR 配对和冲突合并。经验总结：picker 能唤起不等于导入导出功能完整，尤其不能把未加密的脱敏 JSON 写成 Android 加密备份完成。

## P1：访问日志仍只是本地摘要

2026-06-29 新增 `ConnectionAuditLog`、RDB `connection_audit_logs` 表和 `AuditLogPage`，从首页工作台“访问日志”入口可进入页面，并能展示连接认证、批量操作和分组变更摘要。当前设计故意不记录命令输出、密码、私钥口令或服务器地址，避免在完整隐私策略前扩大敏感落库面。同日分组变更摘要已通过强停重启回显；对齐 Android Export 后，页面可唤起系统保存选择器导出 summary-only JSON；对齐 Filter 后，事件筛选芯片和无匹配空状态已通过设备层级验证。尚未完成真实连接成功/失败写入复测、批量操作日志重启复测、日志清空、导出文件写入/回读、保留策略、MDM/syslog 和 Android 完整审计日志对齐。经验总结：摘要日志可用于本地排障，不等于合规审计功能完成。

## P1：全屏避让仍缺多设备矩阵

2026-06-29 `EntryAbility` 已开启全屏布局、透明系统栏、窗口隐私保护，并把系统/挖孔/手势避让区写入页面 padding。所有已注册 ArkUI 页面已接入 `avoidStatusBarHeight` / `avoidNavigationBarHeight`，`audit_project.ps1` 也会逐页检查；最新 Real HAP 已抽样验证首页、设置 Tab、设置页、工具箱、终端设置、关于、连接页、连接编辑、SFTP 和端口转发页面。2026-06-30 底部 Tab 胶囊导航已修复主题色不随模式变化和位置过低的问题；顶部 Logo/标题区按 RustDesk HarmonyOS 文档改为半透明渐变过渡，并把 `contentTopInset()` 与 `headerOverlayHeight()` 分离，避免标题区压住第一张卡片。此前空白 overlay 阻断设置 Tab 滚动的问题已修复。但还没有横竖屏、不同导航模式、挖孔设备、Terminal 真实长会话、SFTP 长列表底部滚动和软键盘场景的矩阵证据。经验总结：顶部不能用整块高不透明毛玻璃，也不能让内容起点和标题控件争同一块空间；单一模拟器多页可见不等于全屏布局完成。

## P1：连接分组页仍缺完整设备点击验证

2026-06-26 新增 `ConnectionGroupPage` 并注册路由，页面使用仓库提供分组列表、新建分组、改名、换色、上移/下移、折叠/展开、空分组处理和每组主机数。2026-06-29 已从首页工作台与连接页接入分组管理入口，并在连接页增加分组筛选芯片；同轮 Mock/Real HAP 编译、安装、冷启动、页面跳转、新建分组和新增分组跨重启回显已通过。但仍缺改名、换色、折叠/展开、删除空组、返回刷新、筛选生效和非空分组迁移的设备点击证据。经验总结：入口可见和单项新建回显不等于 Android 连接管理已完成。

## P1：仓库内生成产物

初始目录含 build、`.cxx`、Hvigor/IDE/AI 缓存和崩溃转储。首次提交前按 `WORKSPACE_PATHS.md` 清理，后续只能在 `99_Temp` stage 构建。

2026-06-23 受限执行环境曾只允许写项目根，无法创建/替换 `99_Temp` stage。仓库内既有的 `entry/build` 与 `entry/.cxx` 已通过新增的 `scripts/clean_project.ps1 -BuildOnly` 安全清理，静态审计恢复为 45/45。2026-06-29 当前远程电脑已可写 `E:\Visual_Studio_Code\99_Temp`，本轮 Mock HAP 构建、验包和 x86_64 模拟器安装已通过；后续仍不得把 stage 产物提交到仓库。

2026-06-29 Real 构建前曾因 stage 内 ArkTS 编译缓存深路径导致 PowerShell `Remove-Item` 清理失败。`stage_project_for_build.ps1` 已增加三次重试和空目录镜像兜底，并限制清理目标必须位于 `99_Temp` 下；后续如果同类问题复现，先检查 stage 目录是否残留旧 `entry/build` 深路径缓存，而不是手工删除整个共享 `99_Temp`。

## P1：安装/冷启动冒烟不能替代功能验收

2026-06-25 新增 `scripts/install_and_smoke.ps1`，用于安装 HAP、启动 `com.open.tabssh`、记录 bundle dump/PID、过滤 hilog/faultlogger 基础异常线索。该脚本只证明 HAP 能安装和冷启动，不能证明 SSH、SFTP、端口转发、重连、签名或发布质量。经验总结：安装冒烟摘要可以提交结论，但原始 hilog 可能包含设备隐私、路径或服务器线索，提交前必须脱敏；不要把 `install_and_smoke.ps1` 的 PASS 当作真实 SSH 通过。

## P1：本地一键检查的边界

2026-06-25 新增 `scripts/run_local_checks.ps1`，用于串联 `git diff --check`、静态审计、终端解析器测试、Mock 构建/验包和可选真实 HAP 构建/验包。它减少人工漏跑脚本，但仍不能替代设备端操作、真实服务器流量、SFTP 哈希、转发逐字节验证和长时间重连压力测试。经验总结：一键脚本失败时优先看 `99_Temp\tabssh_harmonyos_logs\local_checks\summary_*.md`，只贴无敏感信息片段。

## P1：ProIcons 资源验证

ProIcons SVG 必须保持标准 XML 且不得含重复属性；浏览器可显示不代表 HarmonyOS 资源编译器一定接受。新增或替换图标必须从 ProIcons 官网或已登记提取记录获取，优先彩色配色资产，禁止自建 SVG。`scripts/audit_project.ps1` 已阻止旧自绘 `tab_*.svg` 和已知 Emoji/字符图标，完整映射见 `PROICONS_ICONS.md`。当前工具箱页复用既有已登记 ProIcons rawfile 资源，没有新增自绘 SVG；已使用中的 SVG 已通过 XML 解析，并随 2026-06-29 Mock/Real HAP 编译安装通过。逐页图标渲染仍需设备复查，尤其是深色主题下的色彩和对比度。

## P1：终端渲染仍缺设备编译与性能证据

终端样式渲染使用 ArkUI `Text`/`Span` 动态 runs；解析器内存测试不能替代 ArkUI DSL 编译和设备性能测试。恢复 `99_Temp` 写权限后要先构建，再以长彩色输出、CJK/Emoji、vim/tmux/htop/nano、备用屏进退、复制和窗口 resize 回归；若单个 `Text` 的 2,000 行样式 runs 出现卡顿，应改为可视区域虚拟化，而不是缩短历史后声称兼容。

## P1：签名尚未配置

当前基线产物是 unsigned HAP，已验证双 ABI 包内容但不能作为安装/发布证据。后续应为 `com.open.tabssh` 配置独立签名材料，存放在 `99_Temp` 的项目专属目录并保持 Git 忽略；不得复用或提交其他项目的签名口令。

用户曾通过 DevEco Studio 构建，但当前仓库配置没有可提交的签名项；这属于正确状态。首次提交扫描未发现证书、私钥或签名口令，未来也必须保持如此。

2026-06-22 x86_64 模拟器接受并安装了 `appProvisionType=debug / appSignType=none` 的 Mock fallback HAP；这不改变正式发布需要独立签名的要求，也不能外推到 arm64 真机。
