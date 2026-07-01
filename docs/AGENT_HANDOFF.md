# 当前任务交接入口

> 更新时间：2026-07-01。当前所有已完成的项目改动已经应用到 `main`，PR #1 已 merged/closed。后续默认直接在 `main` 上继续开发和更新文档。

## 当前事实

项目根为 `%VSCODE_ROOT%\10_Tabssh_harmonyos`，GitHub 目标为 `https://github.com/liyan-lucky/Tabssh_harmonyos.git`，默认分支 `main`。实际应用 Bundle 为 `com.open.tabssh`，版本 `0.1.0 / 1`，Native 模块为 `libentry.so`，ABI 配置为 arm64-v8a 与 x86_64。

默认无三方库的构建仍是 `native_ssh_mock.cpp`。固定版本 libssh2/OpenSSL/zlib 双架构静态库与 manifest 已构建，真实 Core HAP 已完成双 ABI 验包并在 x86_64 模拟器加载；HostKey/密码认证/PTY/命令/SFTP 列目已有外部服务器证据，SFTP 写操作已有隔离回环端证据；2026-07-01 默认 hdc 目标报告为 `x86_64` / `emulator`，又完成用户提供局域网测试主机的 HostKey 确认、密码认证、PTY 打开、命令输出和连接次数回写验证。RDB-backed 连接仓库、访问日志摘要、访问日志导出/筛选、连接历史、连接导入导出、搜索高亮、批量操作、工作台主机管理入口、已保存主机独立页、连接页最近历史、资料变更刷新令牌、工具箱入口、首批纯 ArkTS 工具、纯 HarmonyOS 网络工具子集、浅色/深色主题和中英双语主壳已编码并随 HAP 构建/安装/冷启动通过；关于、终端设置、连接历史、访问日志、连接分组、连接导入导出、连接编辑、终端、SFTP 和端口转发页已接主题/双语；新增分组和分组变更摘要已通过基础强停重启回显；所有已注册 ArkUI 页面已接全屏避让并通过单台 x86_64 多页抽样。最新 Real HAP SHA256 为 `10A1398261F2BF13502AE156FA02C94EAC9443459B76BF4A08E2C823041BC5E1`，大小 `13,219,896` bytes，构建时间 `2026-07-01 09:09:25 +08:00`，已验证工作台主机管理卡片直达已保存主机列表、右侧添加按钮保留原新增主机流程、卡片下方不再显示新增主机/已保存主机/连接历史三行入口且不内联主机目标详情、`SavedHostsPage` 独立页面的标题/搜索/编辑/连接按钮、连接页最近 10 条历史摘要、资料变更单调刷新令牌、第四 Tab 改为“设置”并展开系统设置项、设置 Tab 工具箱入口、连接页不再显示 logo 下方 SSH 横幅、顶部 Logo/标题区 RustDesk 风格半透明紧凑渐变且默认首屏加高一倍、底部 Tab 半透明 Thin blur 胶囊、关于页版本/构建时间、工具箱 JSON/Encoding 面板输出、工具箱网络拓扑、端口扫描、公网 IP HTTP 200 输出、受控子网发现输出、HTTP 下载样本测速、HTTP POST 上传测速、单项 TCP 连通性、ICMP 等价验收、Nginx 摘要/同输入变量展开/include 检出、QR Version 2-L 矩阵输出、设置页 English/Dark 即时刷新、设置 Tab 系统语言跟随点击与强停重启回显、连接历史、连接分组、导入导出、访问日志、终端设置和关于页 English/Dark 层级；最新信息架构证据为 `layout_20260701_091135_home_host_management_single_entry.json`、`layout_20260701_091206_saved_hosts_from_host_management.json` 和 `layout_20260701_091227_add_from_host_management.json`；最新 x86_64 SSH 证据为 `screenshot_20260701_044250_ssh_after_hostkey.jpeg` 和 `screenshot_20260701_044430_ssh_whoami.jpeg`，最新工具箱 ICMP 等价证据为 `screenshot_20260701_045540_toolbox_icmp_equivalent_result.jpeg`；最新首页默认首屏顶栏证据为 `layout_20260701_033648_home_header_double_height.json` 和 `screenshot_20260701_033648_home_header_double_height.jpeg`；最新工具箱上传/Nginx/QR 矩阵证据为 `layout_20260630_223018_toolbox_upload_result.json`、`layout_20260630_223018_toolbox_nginx_expanded_result.json`、`layout_20260630_223018_toolbox_qr_matrix_result.json` 和 `screenshot_20260630_223018_toolbox_qr_matrix_result.jpeg`。完整 xterm、三类转发、HUKS/ASSET、私钥认证、arm64 真机、完整连接管理点击矩阵、导入导出真实文件回读/样本落库、二维码图片保存/美化、IP 详情路由/地址族设备点击、多网卡枚举、外部 Nginx include 文件导入/展开和主题/语言多页面点击矩阵仍未完成。禁止把源码存在、加载成功、Mock 行为或函数返回写成真实 SSH 已完成。

当前首页连接页已保持现有卡片、芯片和悬浮胶囊底栏风格；搜索、命中高亮、收藏筛选、排序芯片、分组筛选芯片、收藏切换、批量选择/收藏/移组/删除等完整保存主机管理能力已移入 `SavedHostsPage`。连接页 logo 下方的 SSH/二进制横幅已移除，保存列表位置改为最近 10 条连接历史摘要。工作台右上角现在进入工具箱，不再进入设置；工作台主机管理卡片左侧点击进入 `SavedHostsPage`，右侧添加按钮仍进入 `ConnectionEditPage`，卡片下方不再显示三个主机选项行，也不显示具体主机目标信息。第四个 Tab 已改为“设置”，设置项直接展开，工具箱入口位于“设置 / 工具 / 工具箱”。工具箱首批纯 ArkTS / 纯 HarmonyOS 工具包括 JSON、Base64/Hash、文本统计、颜色转换、单位换算、系统/存储/IP 基础信息、访问审计跳转、默认网络/DNS/网关/路由/地址族摘要、公网 IP、受控子网发现、TCP 连通性探测、ICMP 等价验收、端口扫描、HTTP 下载/上传测速、Nginx 配置摘要/同输入变量展开/include 检出和 QR Version 2-L 矩阵。`EntryAbility` 已开启全屏布局、透明系统栏、窗口隐私保护和避让区写入，顶部 Logo/标题区采用半透明紧凑渐变过渡，底部 Tab 区采用半透明 Thin blur 胶囊。2026-07-01 已取得本地 Mock/Real HAP 编译/验包、x86_64 模拟器安装/冷启动、x86_64 hdc SSH HostKey/密码/PTY/命令输出、访问日志点击、基础新增分组/日志跨重启、连接历史空状态、已保存主机独立页入口、导入导出 picker 入口、工具箱 JSON/Encoding 面板输出、工具箱网络拓扑、端口扫描、公网 IP、受控子网发现、HTTP 下载样本测速、HTTP POST 上传测速、单项 TCP 连通性、ICMP 等价验收、Nginx 摘要/同输入变量展开/include 检出、QR Version 2-L 矩阵输出、设置 Tab 展开/滚动、设置 Tab 系统语言跟随点击与强停重启、关于页版本构建时间、首页顶部紧凑渐变截图和多页全屏 UI hierarchy 抽样；保存主机独立页批量操作逐项点击、工具箱剩余网络能力、导入导出文件内容验收和多设备全屏避让矩阵仍待补。

`ConnectionGroupPage.ets` 已新增并注册到 `main_pages.json`，可承载分组列表、新建分组、改名、换色、上移/下移、折叠/展开、空分组处理和每组主机数。该页面沿用现有卡片风格，已接 RDB-backed 仓库；首页工作台与连接页入口、连接页按组筛选已编码，新增分组已完成设备点击和重启回显验证。非空分组迁移、改名/换色/折叠/删除空组/筛选生效和完整设备点击证据仍待补。

线上构建现在有三个手动 workflow：`.github/workflows/test-harmonyos-sdk-token.yml` 预检 `HARMONYOS_SDK_TOKEN` 与私有 SDK release 资产；`.github/workflows/build-harmonyos.yml` 用私有 SDK release 构建 HAP、刷新 BuildInfo、上传 HAP/SHA256/包清单并可选创建 Release；`.github/workflows/cleanup-releases.yml` 仅用于明确需要时手动清理 Release、标签和旧 workflow run。旧 `.github/workflows/online-build.yml` 已由远端提交移除；上述 workflow 均不响应 push/PR，仍缺本仓库线上成功 run 证据。

`docs/BUILD_READY.md` 已记录当前 `main` 可以进入本地和线上最小 HAP 构建测试。`docs/PULL_TEST_GUIDE.md` 已改为直接拉取 `main`。`docs/GIT_PUBLISH.md` 已记录用户允许直接操作 `main`。后续如需继续对齐 Android 版，应优先补：RDB 跨重启点击证据与 schema migration、连接页批量/高亮点击证据、访问日志跨重启/真实连接回显、多设备全屏避让矩阵、私钥认证、端口转发真实流量、终端复杂 TUI 设备证据、SFTP 大文件/取消/恢复和 arm64 真机验收。

## 当前必须补的新证据

- GitHub Actions `测试 HarmonyOS SDK Token` 和 `构建并发布 HarmonyOS HAP` 的运行结果。
- 线上 artifact 中的 unsigned HAP、SHA256、HAP 文件列表和 `version.env`。
- 线上 Linux 构建日志中 SDK Token 权限、SDK release 下载、SDK 定位、Hvigor 构建、HAP 包校验和 Release 参数六段关键结论。
- 工具箱剩余网络类工具能力：网络拓扑、默认网络信息、端口扫描、公网 IP、受控子网发现、HTTP 下载样本测速、HTTP POST 上传测速、单项 TCP 连通性、ICMP 等价验收、Nginx 摘要/同输入变量展开/include 检出和 QR Version 2-L 矩阵已有 Real HAP 输出；仍需补二维码图片保存/美化、IP 详情路由/地址族设备点击、多网卡枚举和外部 Nginx include 文件导入/展开。
- 主题/语言全局覆盖：关于、终端设置、连接历史、访问日志、连接分组、连接导入导出、连接编辑、终端、SFTP 和端口转发页已迁移；系统语言跟随已在设置 Tab 完成点击和强停重启回显；仍需补多页面切换即时刷新、无障碍/高对比和部分 service/audit 动态文案。
- 已保存主机独立页在新增/编辑/删除/收藏/批量操作后的刷新和连接按钮点击证据。
- 首页连接筛选 UI 的搜索/收藏/排序/分组筛选逐项点击和返回刷新证据。
- 连接历史真实数据、点击行进入终端和跨重启统计回显证据。
- 连接导入导出真实文件写入/回读、真实 OpenSSH/JSON 样本导入落库、重复导入去重、IdentityFile 警告、跨重启回显、加密 ZIP/QR/同步证据。
- 连接页批量模式和搜索高亮逐项点击证据。
- 访问日志页的真实连接认证结果写入、批量操作日志重启回显、清空、导出文件写入/回读和隐私字段审计证据；分组变更摘要基础跨重启、导出选择器唤起和筛选空状态已通过。
- 全屏避让在横竖屏、手势导航、导航栏、挖孔、软键盘和终端长会话下的布局证据；单台 x86_64 多页抽样已通过。
- 首页分组入口/分组筛选与连接分组页的改名、折叠/展开、空分组处理、非空迁移和筛选生效证据；分组新增与重启回显已通过基础验证。
- 最新 ProIcons 资源包的逐页图标渲染证据；本轮只证明 HAP 编译安装和首屏入口文本可见。
- 最新终端 Span 渲染、复制、视口 resize、复杂 TUI 和性能证据。
- 三类端口转发真实 HAP 的逐字节流量证据。
- SFTP 大文件、取消和中断恢复证据。
- arm64 真机真实 SSH 端到端证据。

## 第一执行序列

1. 完整读取本文件，再按 `docs/README.md` 顺序阅读。
2. 执行 `git status --short --branch` 和完整 diff，确认当前在 `main`。
3. 若目标是验证线上构建，先确认仓库已配置 `HARMONYOS_SDK_TOKEN`。
4. 运行 GitHub Actions：先跑 `测试 HarmonyOS SDK Token`，再跑 `构建并发布 HarmonyOS HAP`。
5. 若线上构建失败，优先看 SDK Token 权限、SDK release 下载、SDK 定位、Hvigor 构建、HAP 包校验和 Release 上传日志，不要先加回自动审计或安装冒烟。
6. 本地仍按需执行 `scripts/run_local_checks.ps1`；如时间紧，先执行 `scripts/run_local_checks.ps1 -SkipMockBuild`。
7. 默认检查通过后，执行 Mock HAP 构建/验包；具备三方依赖时再执行真实 Core HAP 构建/验包。
8. 安装 HAP 后优先验证：首页工作台主机管理卡片点击进入 `SavedHostsPage` 且不泄露主机详情、卡片下方无三个主机选项行、右侧添加按钮仍进入新增主机、连接 Tab 最近 10 条历史、右上工具箱入口、设置 Tab 工具箱入口、工具箱网络拓扑/端口扫描/测速/连通性/Nginx/QR 工具、设置 Tab 主题/语言切换、连接分组页路由编译、导入导出页 picker 与真实文件回读、顶部/底部半透明玻璃层、Terminal/SFTP/PortForward/Settings/About 路由。
9. 每次重要修改和最终发布前各运行一次完整审计、构建、安装与相关功能检查，并立即同步所有相关文档。

## 安全与清理规则

- 密码、私钥、私钥口令、token 和服务器凭据只允许存在测试运行内存，禁止写入源码、日志、文档、截图、备份说明或提交说明。
- HarmonyOS SDK 包地址只记录变量名，禁止把真实链接写入文档、日志摘要或提交说明。
- `%VSCODE_ROOT%\99_Temp` 是多项目共享目录，只能使用 `docs/WORKSPACE_PATHS.md` 列明且明确归属本项目的可再生目录。
- 不在仓库根保留 `.hvigor`、`.cxx`、build、崩溃转储、IDE/AI 工具缓存或散落日志。
- 应用图标只能使用 ProIcons 官网或 `docs/PROICONS_ICONS.md` 登记的 ProIcons 资产，优先彩色配色版本，禁止新增自绘 SVG、Emoji 或字符图标。

## 文档同步规则

每轮修改代码、脚本、资源、构建流程或测试流程后，必须同步更新相关文档。新增文件写入 `docs/FILES.md`，测试路径写入 `docs/PULL_TEST_GUIDE.md` 或 `docs/BUILD_TEST.md`，风险写入 `docs/ISSUES.md`，状态变化写入 `docs/PROGRESS.md`。`docs/BUILD_TEST.md` 只能追加或补充，不能覆盖历史 HAP 哈希、故障栈和设备证据。
