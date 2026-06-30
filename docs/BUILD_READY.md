# 当前构建测试就绪说明

> 更新时间：2026-06-30。本文记录当前 `main` 是否已经可以进入本地/线上构建测试，以及构建后应该优先验证什么。

## 当前判断

当前线上构建已经改为纯 GitHub 托管 Linux runner 的手动构建链路，并已对齐 `rustdesk_harmonyos` 的 Linux 构建结构。现在有两个主要入口：`online-build.yml` 做 4-package unsigned HAP 格式验证，`build-harmonyos.yml` 做 HAP 构建、BuildInfo 刷新、产物上传和可选 Release 发布。

原因：

- `.github/workflows/online-build.yml` 现在只保留手动触发，按 HarmonyOS/OpenHarmony 与 arm64-v8a/x86_64 矩阵生成四个 unsigned HAP artifact。
- `.github/workflows/build-harmonyos.yml` 现在只保留手动触发，通过 `HARMONYOS_SDK_TOKEN` 读取私有 SDK release，支持版本号处理、HAP 包校验开关和可选 Release。
- 线上运行环境是 `ubuntu-latest`，不再依赖自托管 Windows runner。
- workflow 使用 `harmonyos-dev/setup-harmonyos-sdk@0.2.1` 初始化 `/home/runner/harmonyos-sdk`。
- `HARMONYOS_SDK_URL` 用于安装 full HarmonyOS SDK 到 `/home/runner/harmonyos-sdk`。
- `HARMONYOS_FULL_URL` 用于替换 `/home/runner/harmonyos-sdk/command-line-tools/hvigor`。
- `HARMONYOS_SDK_TOKEN` 用于 `build-harmonyos.yml` 和 `test-harmonyos-sdk-token.yml` 读取 `liyan-lucky/HarmonyOS_SDK_Tools` 的 SDK release 资产。
- workflow 会设置 `DEVECO_TOOLS_ROOT`、`TABSSH_HWSDK_ROOT`、`HARMONYOS_SDK_DIR`、`HARMONYOS_NODE_DIR`、`PATH` 和 `LD_LIBRARY_PATH`。
- `online-build.yml` 只执行 unsigned HAP 构建、HAP zip 格式检查、单 ABI `libentry.so` 检查和 artifact 上传。
- `build-harmonyos.yml` 使用 `scripts/run_hvigor_with_sdk_patch.js` 构建，刷新 `BuildInfo.ets`，上传 HAP、SHA256、包清单和 `version.env`，并可在手动选择时创建 Release。
- 线上静态审计、连接分组专项审计、安装冒烟、push/PR 自动触发仍暂时移除。
- 没有新增签名材料、凭据、构建产物或原始日志。

## 线上构建入口

GitHub Actions 文件：

- `.github/workflows/test-harmonyos-sdk-token.yml`：先验证 `HARMONYOS_SDK_TOKEN` 能读取私有 SDK 仓库、Release 和资产。
- `.github/workflows/online-build.yml`：4-package unsigned HAP 格式验证，依赖 `HARMONYOS_SDK_URL` 和 `HARMONYOS_FULL_URL`。
- `.github/workflows/build-harmonyos.yml`：HAP 构建、BuildInfo 刷新、产物上传和可选 Release 发布，依赖 `HARMONYOS_SDK_TOKEN`。

触发方式：

1. GitHub → Actions → `测试 HarmonyOS SDK Token`，先确认 SDK token 和 release 资产可读。
2. GitHub → Actions → `TabSSH Linux HAP 4-package build` 或 `构建并发布 HarmonyOS HAP`。
3. 点击 `Run workflow`。
4. 选择 `main`。
5. 运行 4-package 格式验证前，在仓库 Secrets 或 Variables 设置 `HARMONYOS_SDK_URL` 和 `HARMONYOS_FULL_URL`。
6. 运行发布构建前，在仓库 Secrets 设置 `HARMONYOS_SDK_TOKEN`。
7. 4-package 格式验证可选填写 `sdk_sha256` 和 `full_sha256`，用于分别校验两个 SDK 包。
8. 发布构建可选择版本号处理、是否跳过 HAP 包校验、是否创建 Release。
9. 运行后下载 artifact：`opentabssh-harmonyos-arm64-v8a-unsigned-hap`、`opentabssh-harmonyos-x86_64-unsigned-hap`、`opentabssh-openharmony-arm64-v8a-unsigned-hap`、`opentabssh-openharmony-x86_64-unsigned-hap` 或 `tabssh-hap`。

当前 workflow 主要步骤：

- `actions/checkout@v4`
- `actions/setup-java@v4`，Zulu Java 17。
- `actions/setup-node@v4`，Node 20。
- 安装 unzip / zip / curl / jq / python3 / rsync。
- `harmonyos-dev/setup-harmonyos-sdk@0.2.1` 初始化基础 SDK。
- 下载 `HARMONYOS_SDK_URL` 指向的 full SDK 包。
- 把 `openharmony`、`hms`、`sdk-pkg.json` 规范化移动到 `/home/runner/harmonyos-sdk`。
- 下载 `HARMONYOS_FULL_URL` 指向的 full hvigor 包。
- 替换 `/home/runner/harmonyos-sdk/command-line-tools/hvigor`。
- 设置构建环境变量和 `local.properties`。
- 执行 `node scripts/run_hvigor_with_sdk_patch.js assembleHap`。
- 查找 `outputs` 下的 `.hap`。
- 执行 `unzip -t` 校验 HAP zip 格式。
- `online-build.yml` 检查每个 HAP 内只存在当前矩阵 ABI 的 `libentry.so`。
- `build-harmonyos.yml` 可选执行 HAP zip 校验，并检查 HAP 内存在 arm64-v8a 与 x86_64 的 `libentry.so`。
- 上传 HAP、SHA256 和 HAP 文件列表。

## SDK 包要求

`HARMONYOS_SDK_URL` 解压后应能定位到：

```text
openharmony
hms 或 HarmonyOS-6.1.1
sdk-pkg.json
```

`HARMONYOS_FULL_URL` 解压后应能在 `command-line-tools` 下形成：

```text
hvigor/bin/hvigorw.js
hvigor/hvigor-ohos-plugin/node_modules/@ohos/hos-sdkmanager-common/build/src/hos/mapper/platform-sdks.js
```

仓库 Secrets 或 Variables：

```text
HARMONYOS_SDK_URL
HARMONYOS_FULL_URL
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

必须先确认 SDK Token 预检、线上 Linux 4-package HAP 格式构建和发布构建最小路径通过，再按顺序恢复：

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
- 4-package artifact 名称为 `opentabssh-harmonyos-arm64-v8a-unsigned-hap`、`opentabssh-harmonyos-x86_64-unsigned-hap`、`opentabssh-openharmony-arm64-v8a-unsigned-hap` 和 `opentabssh-openharmony-x86_64-unsigned-hap`。
- 发布构建 artifact 名称为 `tabssh-hap`。
- artifact 内存在 HAP、SHA256 和 HAP 文件列表。
- HAP zip 格式通过 `unzip -t`。
- 4-package HAP 内只含当前矩阵 ABI 的 `libentry.so`；发布构建 HAP 内含 arm64-v8a 与 x86_64 的 `libentry.so`。

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
- 第四个底部 Tab 为“设置”，且主题/语言、文件、缓存、终端、工具和关于分组直接展开；浅色/深色和中文/English 切换能即时刷新，并在重启后保持偏好。
- 连接页“全部分组 / 分组名 / 管理分组”芯片能筛选或跳转。
- 连接页搜索命中高亮和批量模式控件不会撑破筛选卡片或遮挡连接行。
- 全屏窗口下顶部标题、滚动内容和底部胶囊导航不被状态栏、导航栏、手势区或挖孔遮挡。
- TerminalPage、SftpPage、PortForwardPage、SettingsPage、TerminalSettingsPage、AboutPage 路由仍可打开。
- ConnectionGroupPage 路由能被 HAP 编译进包。

2026-06-30 本地 Mock/Real HAP 构建和验包、x86_64 模拟器安装/冷启动和多页 UI hierarchy 冒烟已通过；当轮 Real HAP SHA256 为 `8648E6C621B600A339B6853BB98022A4C5BAF8D6A6521DCB1B14737054688079`。已从工作台点击进入 `AuditLogPage`，并验证新建分组后显示“分组变更 / 新增分组”摘要；强停重启后访问日志和连接分组页仍分别回显分组变更摘要与“新分组 1”。补齐全屏避让后，Real HAP 已抽样验证首页、我的、系统设置、终端设置、关于、连接页、连接编辑、SFTP 和端口转发页面。访问日志导出入口已能唤起系统保存选择器并显示 `opentabssh-audit-*.json` 默认文件名，访问日志事件筛选芯片和无匹配空状态已通过页面层级验证。连接历史入口和空状态已完成 Real HAP 页面层级验证。连接导入导出入口、页面首屏、JSON 导出保存选择器和 OpenSSH 导入选择器已完成 Real HAP 页面层级验证。工作台右上角工具箱入口、我的页工具箱入口、工具箱 JSON/Encoding 面板输出、工具箱网络拓扑默认网络输出、工具箱端口扫描输出、工作台保存主机直显、设置页浅色/深色与中文/English 偏好也已完成构建安装和页面层级抽样。后续又验证连接历史、连接分组、导入导出、访问日志、终端设置和关于页 English/Dark 层级刷新，并验证底部 Tab 胶囊导航随暗色/浅色主题变色、底部避让不再压住手势区。该结果只覆盖编译、安装、冷启动、入口可见性、访问日志页面点击、基础分组/日志跨重启、导出选择器唤起、访问日志筛选空状态、连接历史空状态、连接导入导出 picker 入口、工具箱首批开发/系统小工具、工具箱部分网络工具、部分页面主题/语言刷新和单台模拟器多页全屏避让，不替代逐项点击、工具箱剩余网络能力、真实流量、导出文件回读、导入样本落库、历史真实数据、横竖屏/挖孔矩阵或 arm64 真机验证。

2026-06-30 01:44 本地基线推进到 Real HAP SHA256 `145DD997852A047D764D495116CAC1F5DA2446707BE56D56B0DFEF0494089A93`。本轮新增 BuildInfo 构建时间刷新、关于页版本/构建时间展示、第四 Tab “设置”展开、顶部 Logo/标题区与底部 Tab 半透明模糊背景，并修复全屏 Header overlay 阻断设置 Tab 滚动的问题。`scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 107/107；x86_64 模拟器安装冷启动 PID `17261`，已取得首页玻璃层、设置 Tab 展开/滚动和关于页版本构建时间截图证据。旧段落中的“我的页工具箱入口”已经由“设置 / 工具 / 工具箱”入口取代。

2026-06-30 07:14 最新本地基线已推进到 Real HAP SHA256 `34A2CA50560F1BAE9662888216B2E287DC078B8E386A8E7659B954E753FC406C`。本轮参考 RustDesk HarmonyOS UI 文档修正主题色板，顶部 Logo/标题区改为半透明渐变过渡，底部 Tab 保留半透明 Thin blur 胶囊，并把连接编辑、终端、SFTP 和端口转发页接入浅色/深色与中文/English。`scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 108/108；x86_64 模拟器安装冷启动 PID `15229`，已取得首页最终截图 `screenshot_20260630_074325_home_theme_gradient_final.jpeg`。

## 当前不能判定完成

- RDB 完整跨重启点击证据和 schema migration；基础新增分组与分组变更摘要跨重启已通过。
- 首页分组入口和分组筛选的完整设备点击证据。
- 连接搜索高亮、批量收藏/移组/删除的完整设备点击证据。
- 访问日志真实连接事件写入、清空、导出文件写入/回读和隐私字段审计证据；分组变更摘要基础跨重启、导出选择器唤起和筛选空状态已通过。
- 连接历史真实成功/失败数据、点击行进入终端和跨重启统计回显。
- 连接导入导出真实文件写入/回读、真实 OpenSSH/JSON 样本导入落库、跨重启回显、加密 ZIP、QR 配对和冲突合并。
- 工具箱剩余网络类能力：网络拓扑、默认网络信息和端口扫描已有 Real HAP 输出；HTTP 下载测速、单项 TCP 连通性、Nginx 摘要和 QR 负载摘要仍缺逐项点击证据；主动子网发现、上传测速、特权 ICMP、二维码图片矩阵、公网 IP、更多网卡字段和复杂 Nginx include/变量展开仍未完成。
- 主题/多语言完整矩阵；当前已覆盖首页主壳、工作台、设置 Tab、设置页、工具箱页、关于、终端设置、连接历史、访问日志、连接分组、连接导入导出、连接编辑、终端、SFTP 和端口转发页，仍需系统语言跟随、跨重启偏好保持、多页面切换即时刷新、无障碍/高对比和部分动态文案验收。
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
