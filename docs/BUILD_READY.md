# 当前构建测试就绪说明

> 更新时间：2026-06-30。本文记录当前 `main` 是否已经可以进入本地/线上构建测试，以及构建后应该优先验证什么。

## 当前判断

当前线上构建已经改为纯 GitHub 托管 Linux runner 的手动构建链路，并已对齐 `rustdesk_harmonyos` 的 Linux 构建结构。当前保留的主要入口是 `build-harmonyos.yml`：做 HAP 构建、BuildInfo 刷新、产物上传和可选 Release 发布；SDK Token 预检与线上清理由独立手动 workflow 承担。旧 `online-build.yml` 4-package 格式验证入口已由远端提交移除。

原因：

- `.github/workflows/build-harmonyos.yml` 现在只保留手动触发，通过 `HARMONYOS_SDK_TOKEN` 读取私有 SDK release，支持版本号处理、HAP 包校验开关和可选 Release。
- 线上运行环境是 `ubuntu-latest`，不再依赖自托管 Windows runner。
- workflow 使用 `harmonyos-dev/setup-harmonyos-sdk@0.2.1` 初始化 `/home/runner/harmonyos-sdk`。
- `HARMONYOS_SDK_TOKEN` 用于 `build-harmonyos.yml` 和 `test-harmonyos-sdk-token.yml` 读取 `liyan-lucky/HarmonyOS_SDK_Tools` 的 SDK release 资产。
- workflow 会设置 `DEVECO_TOOLS_ROOT`、`TABSSH_HWSDK_ROOT`、`HARMONYOS_SDK_DIR`、`HARMONYOS_NODE_DIR`、`PATH` 和 `LD_LIBRARY_PATH`。
- `build-harmonyos.yml` 使用 `scripts/run_hvigor_with_sdk_patch.js` 构建，刷新 `BuildInfo.ets`，上传 HAP、SHA256、包清单和 `version.env`，并可在手动选择时创建 Release。
- 线上静态审计、连接分组专项审计、安装冒烟、push/PR 自动触发仍暂时移除。
- 没有新增签名材料、凭据、构建产物或原始日志。

## 线上构建入口

GitHub Actions 文件：

- `.github/workflows/test-harmonyos-sdk-token.yml`：先验证 `HARMONYOS_SDK_TOKEN` 能读取私有 SDK 仓库、Release 和资产。
- `.github/workflows/build-harmonyos.yml`：HAP 构建、BuildInfo 刷新、产物上传和可选 Release 发布，依赖 `HARMONYOS_SDK_TOKEN`。

触发方式：

1. GitHub → Actions → `测试 HarmonyOS SDK Token`，先确认 SDK token 和 release 资产可读。
2. GitHub → Actions → `构建并发布 HarmonyOS HAP`。
3. 点击 `Run workflow`。
4. 选择 `main`。
5. 运行发布构建前，在仓库 Secrets 设置 `HARMONYOS_SDK_TOKEN`。
6. 发布构建可选择版本号处理、是否跳过 HAP 包校验、是否创建 Release。
7. 运行后下载 artifact：`tabssh-hap`。

当前 workflow 主要步骤：

- `actions/checkout@v4`
- `actions/setup-java@v4`，Zulu Java 17。
- `actions/setup-node@v4`，Node 20。
- 安装 unzip / zip / curl / jq / python3 / rsync。
- `harmonyos-dev/setup-harmonyos-sdk@0.2.1` 初始化基础 SDK。
- 通过 `HARMONYOS_SDK_TOKEN` 从私有 SDK release 下载 full SDK 包。
- 把 `openharmony`、`hms`、`sdk-pkg.json` 规范化移动到 `/home/runner/harmonyos-sdk`。
- 使用 SDK release 内的 full hvigor 包。
- 替换 `/home/runner/harmonyos-sdk/command-line-tools/hvigor`。
- 设置构建环境变量和 `local.properties`。
- 执行 `node scripts/run_hvigor_with_sdk_patch.js assembleHap`。
- 查找 `outputs` 下的 `.hap`。
- 执行 `unzip -t` 校验 HAP zip 格式。
- `build-harmonyos.yml` 可选执行 HAP zip 校验，并检查 HAP 内存在 arm64-v8a 与 x86_64 的 `libentry.so`。
- 上传 HAP、SHA256 和 HAP 文件列表。

## SDK 包要求

SDK release 中的 command line tool/full SDK 解压后应能定位到：

```text
openharmony
hms 或 HarmonyOS-6.1.1
sdk-pkg.json
```

full hvigor 解压后应能在 `command-line-tools` 下形成：

```text
hvigor/bin/hvigorw.js
hvigor/hvigor-ohos-plugin/node_modules/@ohos/hos-sdkmanager-common/build/src/hos/mapper/platform-sdks.js
```

仓库 Secrets：

```text
HARMONYOS_SDK_TOKEN
```

## 本地推荐先跑

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_local_checks.ps1 -SkipMockBuild
```

如果只想对齐本地最小 HAP 格式构建，再跑：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_mock_hap.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_mock_hap.ps1
```

## 构建成功后再逐步加回

必须先确认 SDK Token 预检和线上 Linux HAP 发布构建最小路径通过，再按顺序恢复：

1. PowerShell 语法检查。
2. `audit_project.ps1`。
3. `audit_connection_groups.ps1`。
4. Mock HAP 安装冒烟。
5. Real HAP 构建。
6. 真实 SSH/SFTP/转发验证。
7. push/PR 自动审计。

不要一次性全部加回，否则失败时难以判断是 SDK 包结构、Hvigor、ArkTS、Native、审计脚本还是 artifact 路径问题。

## 构建后必须验证

### HAP 格式

- Workflow 成功结束。
- 发布构建 artifact 名称为 `tabssh-hap`。
- artifact 内存在 HAP、SHA256 和 HAP 文件列表。
- HAP zip 格式通过 `unzip -t`。
- 发布构建 HAP 内含 arm64-v8a 与 x86_64 的 `libentry.so`。

### 基础页面回归

构建通过后再安装到模拟器/真机，确认：

- 首页能启动。
- 首页四个底部标签仍可切换。
- 连接编辑页仍可打开。
- 首页工作台和连接页的“连接分组”入口能打开 `ConnectionGroupPage`。
- 首页工作台“访问日志”入口能打开 `AuditLogPage`。
- 首页工作台和连接页“导入导出”入口能打开 `ConnectionImportExportPage`。
- 首页工作台右上角入口能打开 `ToolboxPage`，不再打开设置页。
- 首页工作台主机列表直接显示已保存主机信息和连接按钮，不再通过动作切换到连接 Tab。
- “设置 / 工具 / 工具箱”入口能打开 `ToolboxPage`。
- 第四个底部 Tab 为“设置”，且主题/语言、文件、缓存、终端、工具和关于分组直接展开；浅色/深色、中文/English 和系统语言跟随切换能即时刷新，并在重启后保持偏好。
- 连接页“全部分组 / 分组名 / 管理分组”芯片能筛选或跳转。
- 连接页搜索命中高亮和批量模式控件不会撑破筛选卡片或遮挡连接行。
- 全屏窗口下顶部标题、滚动内容和底部胶囊导航不被状态栏、导航栏、手势区或挖孔遮挡。
- TerminalPage、SftpPage、PortForwardPage、SettingsPage、TerminalSettingsPage、AboutPage 路由仍可打开。
- ConnectionGroupPage 路由能被 HAP 编译进包。

2026-06-30 本地 Mock/Real HAP 构建和验包、x86_64 模拟器安装/冷启动和多页 UI hierarchy 冒烟已通过；当轮 Real HAP SHA256 为 `8648E6C621B600A339B6853BB98022A4C5BAF8D6A6521DCB1B14737054688079`。已从工作台点击进入 `AuditLogPage`，并验证新建分组后显示“分组变更 / 新增分组”摘要；强停重启后访问日志和连接分组页仍分别回显分组变更摘要与“新分组 1”。补齐全屏避让后，Real HAP 已抽样验证首页、我的、系统设置、终端设置、关于、连接页、连接编辑、SFTP 和端口转发页面。访问日志导出入口已能唤起系统保存选择器并显示 `opentabssh-audit-*.json` 默认文件名，访问日志事件筛选芯片和无匹配空状态已通过页面层级验证。连接历史入口和空状态已完成 Real HAP 页面层级验证。连接导入导出入口、页面首屏、JSON 导出保存选择器和 OpenSSH 导入选择器已完成 Real HAP 页面层级验证。工作台右上角工具箱入口、我的页工具箱入口、工具箱 JSON/Encoding 面板输出、工具箱网络拓扑默认网络输出、工具箱端口扫描输出、工作台保存主机直显、设置页浅色/深色与中文/English 偏好也已完成构建安装和页面层级抽样。后续又验证连接历史、连接分组、导入导出、访问日志、终端设置和关于页 English/Dark 层级刷新，并验证底部 Tab 胶囊导航随暗色/浅色主题变色、底部避让不再压住手势区。该结果只覆盖编译、安装、冷启动、入口可见性、访问日志页面点击、基础分组/日志跨重启、导出选择器唤起、访问日志筛选空状态、连接历史空状态、连接导入导出 picker 入口、工具箱首批开发/系统小工具、工具箱部分网络工具、部分页面主题/语言刷新和单台模拟器多页全屏避让，不替代逐项点击、工具箱剩余网络能力、真实流量、导出文件回读、导入样本落库、历史真实数据、横竖屏/挖孔矩阵或 arm64 真机验证。

2026-06-30 01:44 本地基线推进到 Real HAP SHA256 `145DD997852A047D764D495116CAC1F5DA2446707BE56D56B0DFEF0494089A93`。本轮新增 BuildInfo 构建时间刷新、关于页版本/构建时间展示、第四 Tab “设置”展开、顶部 Logo/标题区与底部 Tab 半透明模糊背景，并修复全屏 Header overlay 阻断设置 Tab 滚动的问题。`scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 107/107；x86_64 模拟器安装冷启动 PID `17261`，已取得首页玻璃层、设置 Tab 展开/滚动和关于页版本构建时间截图证据。旧段落中的“我的页工具箱入口”已经由“设置 / 工具 / 工具箱”入口取代。

2026-06-30 07:14 最新本地基线已推进到 Real HAP SHA256 `34A2CA50560F1BAE9662888216B2E287DC078B8E386A8E7659B954E753FC406C`。本轮参考 RustDesk HarmonyOS UI 文档修正主题色板，顶部 Logo/标题区改为半透明渐变过渡，底部 Tab 保留半透明 Thin blur 胶囊，并把连接编辑、终端、SFTP 和端口转发页接入浅色/深色与中文/English。`scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 108/108；x86_64 模拟器安装冷启动 PID `15229`，已取得首页最终截图 `screenshot_20260630_074325_home_theme_gradient_final.jpeg`。

2026-06-30 15:28 最新本地基线已推进到 Real HAP SHA256 `9E2394A128527539E263F9C8CF35DB5954B2CCFBD609D66DD064634D5A95BB5A`。本轮按在线检查反馈收紧首页顶部和 Logo 区默认距离：`HeaderOverlay` 为 `avoidStatusBarHeight + 76`，内容顶部为 `headerOverlayHeight() - 14`，Header 行高和顶部 padding 已缩小。`scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9；x86_64 模拟器安装冷启动 PID `6767`，已取得首页紧凑顶部截图 `screenshot_20260630_152837_home_top_tighter.jpeg` 和层级 `layout_20260630_152837_home_top_tighter.json`，确认顶部贴近且第一张卡片未压住标题。

2026-06-30 15:43 最新本地基线已推进到 Real HAP SHA256 `A54EDDE5C4338B393952875A4BACA1AFD7A8D2E67ECBB5845F9A03823053DFED`。本轮补齐系统语言跟随：设置 Tab 语言分段为“系统 / 中 / EN”，系统选项通过 `@ohos.i18n` 解析首选语言并归一到中文/English。`scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 119/119；x86_64 模拟器安装冷启动 PID `17370`，点击“系统”后设置 Tab 显示“跟随系统 · 简体中文”，强停重启 PID `17427` 后仍回显。证据为 `layout_20260630_154312_settings_system_language_selected.json`、`screenshot_20260630_154312_settings_system_language_selected.jpeg` 和 `layout_20260630_154312_settings_system_language_after_restart.json`。

2026-06-30 16:06 最新本地基线已推进到 Real HAP SHA256 `254DD95BD808D3E02CCB2608D6F556100F736107B4E08CCEADDA709F6DB8ABAA`。本轮继续压缩首页顶部 Logo/标题区默认距离：`HeaderOverlay` 改为 `headerStatusInset() + 64`，状态栏占位收紧到 `avoidStatusBarHeight - 10`，内容顶部为 `headerOverlayHeight() - 12`；同时为工具箱 IP 详情新增纯 HarmonyOS HTTP 公网 IP 查询。`scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 120/120；x86_64 模拟器安装冷启动 PID `2098`，首页层级 `layout_20260630_160625_home_header_tightest.json` 显示标题 y=141，公网 IP 证据 `layout_20260630_160625_toolbox_public_ip_result_attempt1.json` 显示 `公网 IP：<redacted> / 来源：https://ifconfig.me/ip / HTTP 200`。

2026-06-30 16:23 最新本地基线已推进到 Real HAP SHA256 `927FD7B8B5030B43FFA2E86B6B1B1E6BE35C6CBE4FE9C3C1DE552B73C40A5C3B`。本轮为工具箱网络拓扑新增受控子网发现：默认 IPv4/CIDR 下最多探测 16 个候选主机，每台只检查 22/80/443。`scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 121/121；x86_64 模拟器安装冷启动 PID `14649`，证据 `layout_20260630_162351_toolbox_subnet_discovery_result.json` 显示 `发现范围：10.0.2.0/24 / 发现主机：1 / 10.0.2.2 -> 22/tcp 8 ms`。

2026-06-30 16:49 最新本地基线已推进到 Real HAP SHA256 `16E26087577669659A7715071C2FDD9E7078F979EC897983D072CDF75F8C6FD4`。本轮把首页顶部 Logo/标题区进一步贴住安全区：`HeaderOverlay` 为 `headerStatusInset() + 56`，状态栏占位为 `avoidStatusBarHeight - 18`，内容顶部为 `headerOverlayHeight() - 20`，普通 Header 行高 44、监控 Header 行高 50；同时对齐远端删除旧 `online-build.yml` 后的审计和文档状态。`scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 119/119；x86_64 模拟器安装冷启动 PID `31110`，首页层级 `layout_20260630_164803_home_header_sticky.json` 显示“工作台”标题 bounds `[596,137][827,196]`，首个“主机列表”文本 bounds `[102,298][354,372]`，顶部贴近且未遮挡首块内容。

2026-06-30 22:00 最新本地基线已推进到 Real HAP SHA256 `F9A480A234589F180410976636DCB88B91E11CE2F0F1226CC3A2FD9090947585`。本轮继续压缩首页顶部和 Logo 区默认距离，同时保留最小状态栏避让：`HeaderOverlay` 为 `headerStatusInset() + 48`，状态栏占位为 `Math.max(24, avoidStatusBarHeight - 18)`，内容顶部为 `Math.max(32, headerOverlayHeight() - 40)`，普通 Header 行高 40、监控 Header 行高 46；并修复 Nginx 单行样例解析。`scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 119/119；x86_64 模拟器安装冷启动 PID `10457`，首页层级 `layout_20260630_220033_home_header_safe_flush.json` 显示首个主机卡片 bounds `[53,161][1267,714]`，“主机列表”文本 bounds `[102,210][354,284]`；工具箱 `layout_20260630_214125_toolbox_nginx_inline_result.json` 显示 `listen/server_name/location/proxy_pass` 已从默认 Nginx 样例中解析出来，`layout_20260630_214125_toolbox_qr_payload_result.json` 显示 QR 负载摘要可输出。

## 当前不能判定完成

- RDB 完整跨重启点击证据和 schema migration；基础新增分组与分组变更摘要跨重启已通过。
- 首页分组入口和分组筛选的完整设备点击证据。
- 连接搜索高亮、批量收藏/移组/删除的完整设备点击证据。
- 访问日志真实连接事件写入、清空、导出文件写入/回读和隐私字段审计证据；分组变更摘要基础跨重启、导出选择器唤起和筛选空状态已通过。
- 连接历史真实成功/失败数据、点击行进入终端和跨重启统计回显。
- 连接导入导出真实文件写入/回读、真实 OpenSSH/JSON 样本导入落库、跨重启回显、加密 ZIP、QR 配对和冲突合并。
- 工具箱剩余网络类能力：网络拓扑、默认网络信息、端口扫描、公网 IP、受控子网发现、HTTP 下载样本测速、单项 TCP 连通性、Nginx 摘要和 QR 负载摘要已有 Real HAP 输出；上传测速、特权 ICMP、二维码图片矩阵、更多网卡字段和复杂 Nginx include/变量展开仍未完成。
- 主题/多语言完整矩阵；当前已覆盖首页主壳、工作台、设置 Tab、设置页、工具箱页、关于、终端设置、连接历史、访问日志、连接分组、连接导入导出、连接编辑、终端、SFTP 和端口转发页，系统语言跟随已完成设置 Tab 点击和强停重启回显；仍需多页面切换即时刷新、无障碍/高对比和部分动态文案验收。
- 全屏避让的横竖屏、手势导航、挖孔、软键盘和终端长会话矩阵；单台 x86_64 模拟器多页抽样已通过。
- 非空分组迁移和拖拽排序。
- 私钥认证完整端到端证据。
- arm64 真机完整验收。
- 三类端口转发真实逐字节流量证据。
- SFTP 大文件、取消和中断恢复。
- 完整 xterm 兼容。
- HUKS / ASSET 凭据安全存储。
- Signed HAP 发布包。

## 测试结果回填

测试完成后更新：

- `docs/BUILD_TEST.md`：写 HAP 哈希、设备、通过项和失败项。
- `docs/PROGRESS.md`：把通过项或阻塞项同步到状态。
- `docs/ISSUES.md`：记录构建失败、页面编译失败或设备点击失败。

不要提交原始 hilog、设备隐私路径、服务器地址、用户名、密码、私钥或 token。
