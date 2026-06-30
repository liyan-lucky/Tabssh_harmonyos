# 当前任务交接入口

> 更新时间：2026-06-30。当前所有已完成的项目改动已经应用到 `main`，PR #1 已 merged/closed。后续默认直接在 `main` 上继续开发和更新文档。

## 当前事实

项目根为 `%VSCODE_ROOT%\10_Tabssh_harmonyos`，GitHub 目标为 `https://github.com/liyan-lucky/Tabssh_harmonyos.git`，默认分支 `main`。实际应用 Bundle 为 `com.open.tabssh`，版本 `0.1.0 / 1`，Native 模块为 `libentry.so`，ABI 配置为 arm64-v8a 与 x86_64。

默认无三方库的构建仍是 `native_ssh_mock.cpp`。固定版本 libssh2/OpenSSL/zlib 双架构静态库与 manifest 已构建，真实 Core HAP 已完成双 ABI 验包并在 x86_64 模拟器加载；HostKey/密码认证/PTY/命令/SFTP 列目已有外部服务器证据，SFTP 写操作已有隔离回环端证据。RDB-backed 连接仓库、访问日志摘要、访问日志导出/筛选、连接历史、连接导入导出、搜索高亮、批量操作、工作台内联主机列表、工具箱入口、首批纯 ArkTS 工具、纯 HarmonyOS 网络工具子集、浅色/深色主题和中英双语主壳已编码并随 HAP 构建/安装/冷启动通过；关于、终端设置、连接历史、访问日志、连接分组、连接导入导出、连接编辑、终端、SFTP 和端口转发页已接主题/双语；新增分组和分组变更摘要已通过基础强停重启回显；所有已注册 ArkUI 页面已接全屏避让并通过单台 x86_64 多页抽样。最新 Real HAP SHA256 为 `34A2CA50560F1BAE9662888216B2E287DC078B8E386A8E7659B954E753FC406C`，已验证工作台保存主机直显、第四 Tab 改为“设置”并展开系统设置项、设置 Tab 工具箱入口、顶部 Logo/标题区 RustDesk 风格半透明渐变、底部 Tab 半透明 Thin blur 胶囊、关于页版本/构建时间、工具箱 JSON/Encoding 面板输出、工具箱网络拓扑和端口扫描输出、设置页 English/Dark 即时刷新、连接历史、连接分组、导入导出、访问日志、终端设置和关于页 English/Dark 层级；最终首页截图为 `screenshot_20260630_074325_home_theme_gradient_final.jpeg`。完整 xterm、三类转发、HUKS/ASSET、私钥认证、arm64 真机、完整连接管理点击矩阵、导入导出真实文件回读/样本落库、工具箱剩余网络能力、系统语言跟随和主题/语言多页面点击矩阵仍未完成。禁止把源码存在、加载成功、Mock 行为或函数返回写成真实 SSH 已完成。

当前首页连接页已保持现有卡片、芯片和悬浮胶囊底栏风格，接入搜索、命中高亮、收藏筛选、排序芯片、分组筛选芯片、分组管理入口、访问日志入口、连接历史入口、导入导出入口、收藏切换、批量选择/收藏/移组/删除、连接次数和上次失败提示。工作台右上角现在进入工具箱，不再进入设置；工作台主机列表直接读取 `ProfileRepository.list()` 展示已保存主机和连接按钮，不再用“主机列表”动作切换到连接 Tab；第四个 Tab 已改为“设置”，设置项直接展开，工具箱入口位于“设置 / 工具 / 工具箱”。工具箱首批纯 ArkTS / 纯 HarmonyOS 工具包括 JSON、Base64/Hash、文本统计、颜色转换、单位换算、系统/存储/IP 基础信息、访问审计跳转、默认网络/DNS/网关摘要、TCP 连通性探测、端口扫描、HTTP 下载样本测速、Nginx 配置摘要和 QR 负载摘要。`EntryAbility` 已开启全屏布局、透明系统栏、窗口隐私保护和避让区写入，顶部 Logo/标题区采用半透明渐变过渡，底部 Tab 区采用半透明 Thin blur 胶囊。2026-06-30 已取得本地 Mock/Real HAP 编译/验包、x86_64 模拟器安装/冷启动、访问日志点击、基础新增分组/日志跨重启、连接历史空状态、导入导出 picker 入口、工具箱 JSON/Encoding 面板输出、工具箱网络拓扑和端口扫描输出、设置 Tab 展开/滚动、关于页版本构建时间、首页顶部渐变最终截图和多页全屏 UI hierarchy 抽样；搜索/收藏/排序/分组筛选/批量操作逐项点击、工具箱 HTTP 测速/连通性/Nginx/QR 点击证据、工具箱剩余网络能力、真实连接日志、导入导出文件内容验收和多设备全屏避让矩阵仍待补。

`ConnectionGroupPage.ets` 已新增并注册到 `main_pages.json`，可承载分组列表、新建分组、改名、换色、上移/下移、折叠/展开、空分组处理和每组主机数。该页面沿用现有卡片风格，已接 RDB-backed 仓库；首页工作台与连接页入口、连接页按组筛选已编码，新增分组已完成设备点击和重启回显验证。非空分组迁移、改名/换色/折叠/删除空组/筛选生效和完整设备点击证据仍待补。

线上构建现在有四个手动 workflow：`.github/workflows/test-harmonyos-sdk-token.yml` 预检 `HARMONYOS_SDK_TOKEN` 与私有 SDK release 资产；`.github/workflows/online-build.yml` 在 GitHub `ubuntu-latest` 上做 HarmonyOS/OpenHarmony 与 arm64-v8a/x86_64 的 4-package unsigned HAP 格式验证；`.github/workflows/build-harmonyos.yml` 用私有 SDK release 构建 HAP、刷新 BuildInfo、上传 HAP/SHA256/包清单并可选创建 Release；`.github/workflows/cleanup-releases.yml` 仅用于明确需要时手动清理 Release、标签和旧 workflow run。上述 workflow 均不响应 push/PR，仍缺本仓库线上成功 run 证据。

`docs/BUILD_READY.md` 已记录当前 `main` 可以进入本地和线上最小 HAP 构建测试。`docs/PULL_TEST_GUIDE.md` 已改为直接拉取 `main`。`docs/GIT_PUBLISH.md` 已记录用户允许直接操作 `main`。后续如需继续对齐 Android 版，应优先补：RDB 跨重启点击证据与 schema migration、连接页批量/高亮点击证据、访问日志跨重启/真实连接回显、多设备全屏避让矩阵、私钥认证、端口转发真实流量、终端复杂 TUI 设备证据、SFTP 大文件/取消/恢复和 arm64 真机验收。

## 当前必须补的新证据

- GitHub Actions `测试 HarmonyOS SDK Token`、`TabSSH Linux HAP 4-package build` 和 `构建并发布 HarmonyOS HAP` 的运行结果。
- 线上 artifact 中的 unsigned HAP、SHA256、HAP 文件列表和 `version.env`。
- 线上 Linux 构建日志中 SDK Token 权限、SDK release 下载、SDK 定位、Hvigor 构建、HAP 包校验和 Release 参数六段关键结论。
- 工具箱剩余网络类工具能力：网络拓扑、默认网络信息和端口扫描已有 Real HAP 输出；仍需补 HTTP 下载测速、单项 TCP 连通性、Nginx 摘要和 QR 负载摘要的逐项点击证据，以及主动子网发现、上传测速、特权 ICMP、二维码图片矩阵/美化、公网 IP、更多网卡字段和复杂 Nginx include/变量展开。
- 主题/语言全局覆盖：关于、终端设置、连接历史、访问日志、连接分组、连接导入导出、连接编辑、终端、SFTP 和端口转发页已迁移；仍需补系统语言跟随、跨重启偏好保持、多页面切换即时刷新、无障碍/高对比和部分 service/audit 动态文案。
- 工作台内联主机列表在新增/编辑/删除主机后的刷新和连接按钮点击证据。
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
3. 若目标是验证线上构建，先确认仓库已配置 `HARMONYOS_SDK_TOKEN`；若运行 4-package 格式验证，还需配置 `HARMONYOS_SDK_URL` 和 `HARMONYOS_FULL_URL`。
4. 运行 GitHub Actions：先跑 `测试 HarmonyOS SDK Token`，再跑 `TabSSH Linux HAP 4-package build` 或 `构建并发布 HarmonyOS HAP`。
5. 若线上构建失败，优先看 SDK Token 权限、SDK release 下载、SDK 定位、Hvigor 构建、HAP 包校验和 Release 上传日志，不要先加回自动审计或安装冒烟。
6. 本地仍按需执行 `scripts/run_local_checks.ps1`；如时间紧，先执行 `scripts/run_local_checks.ps1 -SkipMockBuild`。
7. 默认检查通过后，执行 Mock HAP 构建/验包；具备三方依赖时再执行真实 Core HAP 构建/验包。
8. 安装 HAP 后优先验证：首页工作台保存主机直显和右上工具箱入口、设置 Tab 工具箱入口、工具箱网络拓扑/端口扫描/测速/连通性/Nginx/QR 工具、设置 Tab 主题/语言切换、首页连接筛选 UI、连接分组页路由编译、导入导出页 picker 与真实文件回读、顶部/底部半透明玻璃层、Terminal/SFTP/PortForward/Settings/About 路由。
9. 每次重要修改和最终发布前各运行一次完整审计、构建、安装与相关功能检查，并立即同步所有相关文档。

## 安全与清理规则

- 密码、私钥、私钥口令、token 和服务器凭据只允许存在测试运行内存，禁止写入源码、日志、文档、截图、备份说明或提交说明。
- HarmonyOS SDK 包地址只记录变量名，禁止把真实链接写入文档、日志摘要或提交说明。
- `%VSCODE_ROOT%\99_Temp` 是多项目共享目录，只能使用 `docs/WORKSPACE_PATHS.md` 列明且明确归属本项目的可再生目录。
- 不在仓库根保留 `.hvigor`、`.cxx`、build、崩溃转储、IDE/AI 工具缓存或散落日志。
- 应用图标只能使用 ProIcons 官网或 `docs/PROICONS_ICONS.md` 登记的 ProIcons 资产，优先彩色配色版本，禁止新增自绘 SVG、Emoji 或字符图标。

## 文档同步规则

每轮修改代码、脚本、资源、构建流程或测试流程后，必须同步更新相关文档。新增文件写入 `docs/FILES.md`，测试路径写入 `docs/PULL_TEST_GUIDE.md` 或 `docs/BUILD_TEST.md`，风险写入 `docs/ISSUES.md`，状态变化写入 `docs/PROGRESS.md`。`docs/BUILD_TEST.md` 只能追加或补充，不能覆盖历史 HAP 哈希、故障栈和设备证据。
