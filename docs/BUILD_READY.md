# 当前构建测试就绪说明

> 更新时间：2026-07-01。本文记录当前 `main` 是否已经可以进入本地/线上构建测试，以及构建后应该优先验证什么。

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
- 首页工作台不显示已保存主机的名称、地址、用户、端口或状态；主机管理卡片左侧点击进入已保存主机列表，右侧添加按钮进入新增主机，卡片下方不再显示新增主机、已保存主机和连接历史三行入口。
- 已保存主机完整列表进入 `SavedHostsPage` 独立页面，新增主机仍进入原 `ConnectionEditPage`；资料变更后通过刷新令牌更新入口计数和独立页列表。
- 连接 Tab 不再显示完整保存列表，改为最近 10 条连接历史摘要，并提供完整历史入口。
- “设置 / 工具 / 工具箱”入口能打开 `ToolboxPage`。
- 第四个底部 Tab 为“设置”，且主题/语言、文件、缓存、终端、工具和关于分组直接展开；浅色/深色、中文/English 和系统语言跟随切换能即时刷新，并在重启后保持偏好。
- 连接页“全部分组 / 分组名 / 管理分组”芯片能筛选或跳转。
- 连接页顶部避让后直接进入“连接方式”，不再显示 logo 下方 SSH/二进制横幅。
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

2026-06-30 22:30 最新本地基线已推进到 Real HAP SHA256 `7947F63EB123D386BB4B5D858B6A5D9C3F348020E1B38F7D73DF2A514F3C4DB1`。本轮继续补工具箱：上传测速使用纯 HarmonyOS `@ohos.net.http` POST 64 KiB 文本样本；Nginx 摘要新增同输入变量展开、include 检出和 upstream server；二维码工具新增纯 ArkTS QR Version 2-L Byte 矩阵；IP 详情源码新增路由和地址族字段。`scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 123/123；x86_64 模拟器安装冷启动 PID `30385`。设备证据 `layout_20260630_223018_toolbox_upload_result.json` 显示上传字节 `65536`、耗时 `2967 ms` 和吞吐 `177 kbps`；`layout_20260630_223018_toolbox_nginx_expanded_result.json` 显示 `$target -> http://app`、`include: conf.d/*.conf` 和 `upstream server`；`layout_20260630_223018_toolbox_qr_matrix_result.json` / `screenshot_20260630_223018_toolbox_qr_matrix_result.jpeg` 显示 `Version 2-L Byte, 25x25` QR 矩阵。

2026-07-01 03:29 本地基线曾恢复首页顶部和 Logo 区的稳定避让：`HeaderOverlay` 为 `headerStatusInset() + 48`，状态栏占位为 `Math.max(24, avoidStatusBarHeight - 18)`，内容顶部为 `Math.max(32, headerOverlayHeight() - 40)`。该轮 Real HAP SHA256 为 `E3C30833F5E4DAF546EBFB214C11E70003831F0E17463A0177E72967F8C877FE`，首页默认首屏层级 `layout_20260701_032859_home_header_default_restored.json` 显示 Logo/标题与状态栏保持避让。

2026-07-01 03:36 最新本地基线已推进到 Real HAP SHA256 `BA4AB59EC193C02F77B00EBF143882F7D560DE740C8C30406A54327C4E674145`。本轮按在线反馈在稳定避让基础上把首页顶部 Logo/标题区加高一倍：`HeaderOverlay` 为 `headerStatusInset() + 96`，状态栏占位为 `Math.max(24, avoidStatusBarHeight - 18)`，内容顶部为 `Math.max(80, headerOverlayHeight() - 40)`，普通 Header 行高 80、监控 Header 行高 92。`scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 123/123；x86_64 模拟器安装冷启动 PID `7726`，首页默认首屏层级 `layout_20260701_033648_home_header_double_height.json` 显示标题 bounds `[596,179][827,269]`，右上工具箱 bounds `[1167,186][1244,263]`，首个主机卡片 bounds `[53,329][1267,882]`。

2026-07-01 04:55 阶段基线推进到 Real HAP SHA256 `D23BEF0226A9B8EE4FDE519610C605C7ED61F16769245061A4B27193D1B480ED`。本轮移除连接页 logo 下方 SSH/二进制横幅，新增工具箱 ICMP 等价验收，使用普通应用可用的默认网络、DNS 解析和 TCP connect 作为应用层连通性证据；同时完成用户提供局域网测试主机的 x86_64 hdc SSH 验证：HostKey 确认、密码认证、PTY 打开、`whoami` 输出和连接次数回写均通过。`scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 124/124；覆盖安装冒烟通过 9/9，HAP 大小 `13,109,588` bytes，构建时间 `2026-07-01 03:55:03 +08:00`。设备证据包括 `screenshot_20260701_035805_connection_no_hero.jpeg`、`screenshot_20260701_044250_ssh_after_hostkey.jpeg`、`screenshot_20260701_044430_ssh_whoami.jpeg`、`screenshot_20260701_045050_app_home_after_forcestop.jpeg` 和 `screenshot_20260701_045540_toolbox_icmp_equivalent_result.jpeg`。当前 hdc 目标报告为 `x86_64` / `emulator`，不能替代 arm64 真机验收。

2026-07-01 05:05 最新本地基线已重建为 Real HAP SHA256 `C402EFED7D6A137E8190A613DC0821E621F8464D20C7A59D0C117980E8FF2FC4`。本轮针对工作台新增/编辑/删除或连接统计变更后必须切换 Tab 才刷新的问题，新增 `profileRefreshToken` 写入通知和首页 `@StorageLink` / `@Watch` reload，并把刷新令牌改为单调递增以覆盖快速连续写入；连接页去横幅与工具箱 ICMP 等价验收同步保留。`scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 125/125；覆盖安装冒烟通过 9/9，HAP 大小 `13,113,342` bytes，构建时间 `2026-07-01 05:03:31 +08:00`。新增层级证据为 `layout_20260701_050500_home_after_refresh_token_monotonic.json` 和 `layout_20260701_050500_connection_no_hero_after_refresh_token_monotonic.json`；同日 SSH 实测仍以 x86_64 hdc 目标证据为准，不能替代 arm64 真机验收。

2026-07-01 09:12 最新本地基线已推进到 Real HAP SHA256 `10A1398261F2BF13502AE156FA02C94EAC9443459B76BF4A08E2C823041BC5E1`。本轮将工作台改为主机管理卡片直达 `SavedHostsPage`、右侧保留新增主机按钮，去掉卡片下方新增主机/已保存主机/连接历史三行入口；`SavedHostsPage` 独立保存主机管理页保留，并把连接 Tab 的保存列表替换为最近 10 条历史摘要。`scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 128/128；覆盖安装冒烟通过 9/9，HAP 大小 `13,219,896` bytes，构建时间 `2026-07-01 09:09:25 +08:00`。设备层级证据为 `layout_20260701_091135_home_host_management_single_entry.json`、`layout_20260701_091206_saved_hosts_from_host_management.json` 和 `layout_20260701_091227_add_from_host_management.json`；当前 hdc 目标仍为 x86_64/emulator 范畴，不能替代 arm64 真机验收。

2026-07-01 09:26 最新本地基线已推进到 Real HAP SHA256 `E75DD509F72DE27B2D00778F43FD676EAA58EA8E4C7E4A44890E645AB69A1892`。本轮为二维码工具补同页预览和纯文本 SVG 保存源，保存入口使用 HarmonyOS `DocumentViewPicker.save`，不引入第三方二维码或图片编码库。`scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 129/129；覆盖安装冒烟通过 9/9，HAP 大小 `13,247,729` bytes，构建时间 `2026-07-01 09:21:16 +08:00`。设备层级证据为 `layout_20260701_0926_toolbox_qr_panel.json` 和 `layout_20260701_0926_toolbox_qr_save_picker.json`；当前只证明预览、系统保存选择器和预填文件名可用，真实目标文件写入/回读、PNG/相册保存和扫码兼容性仍待补。

2026-07-01 09:43 最新本地基线已推进到 Real HAP SHA256 `CF8EEFA582E6FE4925562D275568144DB3760A0A253A617D033C88FD768EB15F`。本轮为 IP 详情补全部网络/多网卡枚举、网络能力和更完整路由摘要，使用纯 HarmonyOS `getAllNets`、`getConnectionProperties` 和 `getNetCapabilities`。`scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 130/130；覆盖安装冒烟通过 9/9，HAP 大小 `13,263,384` bytes，构建时间 `2026-07-01 09:41:13 +08:00`。设备层级证据 `layout_20260701_0943_toolbox_ip_all_networks.json` 显示 `全部网络：2`、默认 `eth0`、`wlan0`、承载/能力、链路地址、DNS、网关和链路有效性。

## 当前不能判定完成

- RDB 完整跨重启点击证据和 schema migration；基础新增分组与分组变更摘要跨重启已通过。
- 首页分组入口和分组筛选的完整设备点击证据。
- 连接搜索高亮、批量收藏/移组/删除的完整设备点击证据。
- 访问日志真实连接事件写入、清空、导出文件写入/回读和隐私字段审计证据；分组变更摘要基础跨重启、导出选择器唤起和筛选空状态已通过。
- 连接历史真实成功/失败数据、点击行进入终端和跨重启统计回显。
- 连接导入导出真实文件写入/回读、真实 OpenSSH/JSON 样本导入落库、跨重启回显、加密 ZIP、QR 配对和冲突合并。
- 工具箱剩余网络类能力：网络拓扑、默认网络信息、端口扫描、公网 IP、IP 详情全部网络/多网卡枚举、受控子网发现、HTTP 下载样本测速、HTTP POST 上传测速、单项 TCP 连通性、ICMP 等价验收、Nginx 摘要/同输入变量展开/include 检出、QR Version 2-L 矩阵、二维码预览和 SVG 保存选择器已有 Real HAP 输出；二维码 SVG 真实目标写入/回读、PNG/相册保存、扫码兼容性和进一步美化，以及外部 Nginx include 文件导入/展开仍未完成。
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
