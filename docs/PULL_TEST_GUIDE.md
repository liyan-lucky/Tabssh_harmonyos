# 拉取与测试指南

> 目标：让接手者直接拉取 `main` 后，按顺序验证 Mock、真实 Core、连接管理 UI、SFTP、终端和端口转发。本文只描述测试流程，不把尚未验证的功能标记为完成。

## 1. 拉取 main

```powershell
git fetch origin
git checkout main
git pull --ff-only origin main
```

如果只想测试稳定的 Mock fallback，可不构建三方依赖；源码 checkout 默认会在缺少 `third_party` 产物时编译 `native_ssh_mock.cpp`。

## 2. 安全规则

- 不要把 SSH 密码、私钥口令、token、服务器地址、用户名写进提交、Issue、PR、截图、日志或文档。
- 测试凭据只允许在运行时输入或通过本机临时环境变量传入测试进程。
- `99_Temp` 是多项目共享目录，禁止整体删除；任何 APK/HAP 一律不得按扩展名全局清理。
- 构建/日志/依赖/测试端只允许进入 `docs/WORKSPACE_PATHS.md` 中登记的 TabSSH 专属目录。

## 3. 本地一键检查

推荐先跑默认检查：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_local_checks.ps1
```

默认会执行：

- `git diff --check`
- `scripts\audit_project.ps1`
- `scripts\test_terminal_emulator.ps1`
- `scripts\build_mock_hap.ps1`
- `scripts\verify_mock_hap.ps1`

检查摘要会写入：

```text
99_Temp\tabssh_harmonyos_logs\local_checks\summary_*.md
```

只做快速静态/终端检查，不构建 HAP：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_local_checks.ps1 -SkipMockBuild
```

已有三方依赖 manifest 时，构建并验真实 HAP：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_local_checks.ps1 -WithRealCore
```

需要从零重建三方依赖时：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_local_checks.ps1 -WithRealCore -BuildDependencies
```

## 4. Mock fallback 手动测试

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\audit_project.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_mock_hap.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_mock_hap.ps1
```

预期：

- `audit_project.ps1` 输出 0 FAIL。
- Mock HAP 包内存在 arm64-v8a 与 x86_64 的 `libentry.so`。
- Terminal 页面必须清楚显示 Mock，不得伪装成真实 SSH。
- SFTP/端口转发在 Mock 下不得显示真实成功。

## 5. 真实依赖构建

前提：Windows + DevEco Studio/OpenHarmony Native SDK + MSYS2 Perl/make + Git。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_native_dependencies.ps1
```

脚本会在 `99_Temp\tabssh_harmonyos_dependencies` 中构建并记录 manifest：

- zlib `1.3.2`
- OpenSSL `3.5.7`
- libssh2 `1.11.1`
- ABI：`arm64-v8a`、`x86_64`

不要把生成的 `.a`、`.so`、头文件或 SDK 内容提交进仓库。

## 6. 真实 HAP 构建与验包

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_real_hap.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_real_hap.ps1
```

`verify_real_hap.ps1` 只证明包内是 real-core marker 和正确 ABI，不证明网络功能完成。

## 7. 安装与冷启动冒烟

构建并验包后，可安装到 hdc 默认设备：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\install_and_smoke.ps1
```

指定 HAP 和设备：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\install_and_smoke.ps1 `
  -HapPath "..\99_Temp\harmonyos_build\10_Tabssh_harmonyos\entry-default-unsigned-real.hap" `
  -DeviceId "127.0.0.1:5555"
```

该脚本会：

- 使用 hdc 安装 HAP。
- 启动 `com.open.tabssh/EntryAbility`。
- 查询 bundle dump 和 PID。
- 过滤 `com.open.tabssh|OpenTabSsh|FATAL|cppcrash|jscrash|appfreeze|APP_INPUT_BLOCK` 相关 hilog 线索。
- 尝试列出 faultlogger。
- 输出摘要到 `99_Temp\tabssh_harmonyos_logs\install_smoke\summary_*.md`。

这只证明安装/冷启动和基础日志采集，不证明 SSH、SFTP、端口转发或发布签名通过。

## 8. 推荐设备测试顺序

### 8.1 基础连接

1. 新建连接。
2. host/port/username 在 UI 输入。
3. password 只在运行时输入，不保存到普通文本。
4. 第一次连接必须出现 HostKey 指纹确认。
5. HostKey 变化必须阻断并显示高风险警告。

通过标准：

- 未知 HostKey 返回阻断状态，确认后才继续认证。
- 错误密码返回认证失败，不崩溃。
- 正确密码进入 PTY shell。
- 再次连接同一 profile 不重复出现首次 HostKey 提示。

### 8.2 首页连接管理 UI

在“连接”页测试：

- 搜索名称、主机、用户或备注。
- 搜索命中后确认名称、主机、用户、备注命中标签和高亮片段正确显示。
- 全部 / 只看收藏筛选。
- 全部分组 / 分组名筛选。
- 管理分组入口跳转到 `ConnectionGroupPage`。
- 默认、名称、主机、最近、次数、收藏排序芯片。
- 收藏 / 取消收藏。
- 进入批量模式，测试选择单条、全选当前、清空选择、批量收藏、批量取消收藏、批量移组、批量删除和退出批量模式。
- 连接次数与上次失败提示显示。
- 首页工作台“访问日志”入口可进入 `AuditLogPage`，批量操作和分组变更后能看到摘要日志。
- 首页工作台或连接页“导入导出”入口可进入 `ConnectionImportExportPage`。
- 首页工作台右上角入口应进入 `ToolboxPage`，不得进入设置页。
- 首页工作台主机区域只应显示一张“主机管理”卡片和右侧“添加”按钮，不应显示下方新增主机、已保存主机和连接历史三行入口，也不应显示已保存主机的名称、用户、主机、端口、状态或连接按钮。
- 点击“主机管理”卡片左侧应进入 `SavedHostsPage` 独立页面；点击右侧“添加”仍应进入原 `ConnectionEditPage`。
- 连接 Tab 的原保存列表区域应显示最近 10 条连接历史摘要，不应显示旧保存列表搜索过滤器。
- 从工作台或连接页新增/编辑主机并返回后，入口计数和独立保存主机页应通过资料刷新令牌更新，不需要手动切换 Tab 才显示。

当前这些数据来自 RDB-backed 仓库；需要补测关闭应用并重新启动后收藏、排序相关统计、分组筛选和访问日志仍正确。

### 8.2.1 工具箱与主题语言

测试：

- 从工作台右上角进入工具箱，确认页面标题、本机信息卡、搜索框、全部/网络/系统/开发分类可见。
- 从“设置 / 工具 / 工具箱”进入同一工具箱页。
- 滚动工具箱，确认网络拓扑、网络测速、Nginx 拓扑、IP 详情、连通性测试、端口扫描、JSON、编码、二维码、取色、文本和单位转换卡片不被底部手势区遮挡。
- 点击 JSON 工具，确认 Format / Minify 能输出格式化或压缩 JSON。
- 点击编码转换，确认 Base64 Encode / Decode / Hash 能输出结果；Hash 当前是 FNV-1a 快速校验，不是密码学哈希。
- 点击文本工具箱、取色器、单位转换，确认分别能输出文本统计、HEX/RGB/亮度和单位换算。
- 点击系统信息、存储空间、IP 详情，确认能显示基础本地信息且不泄露完整设备隐私路径。
- 点击访问审计能进入 `AuditLogPage`。
- 点击网络拓扑，确认输出本机到默认网络再到已保存 SSH 主机的摘要，并显示默认网络、接口、链路地址和网关；若设备没有默认网络，应明确显示不可用而不是伪造结果。
- 点击 IP 详情，确认显示默认网络、全部网络数量、netId、接口名、承载、能力、链路地址、DNS、网关、路由和 IPv4/IPv6 链路有效性，不泄露完整设备隐私路径。
- 点击连通性测试，使用 `host port` 输入执行 TCP 探测；再点击“等价验收”，确认输出说明普通应用不使用特权 ICMP raw socket，并显示默认网络、DNS 解析和 TCP connect 结果。
- 点击端口扫描，默认输入 `127.0.0.1 22,80,443`，确认每个端口都有 TCP 状态和耗时，并确认单次最多 32 个端口的限制提示。
- 点击网络测速，使用 HTTP/HTTPS URL 分别做下载样本测速和上传测速；上传测速使用 HTTP POST 64 KiB 文本样本，服务端返回 4xx/5xx 时也必须显示上传字节、耗时和吞吐，不得伪造成功。
- 点击 Nginx 拓扑，确认能汇总 upstream、upstream server、server、listen、server_name、location、proxy_pass、include，并能展开同一输入中的 `set` 变量；外部 include 文件仍需粘贴内容或后续接入文件导入。
- 点击二维码工具，确认输出 QR Version 2-L Byte、码字统计和 `##/..` 矩阵；SVG 预览、保存写入和回读可用，PNG/相册保存、扫码兼容性和进一步美化仍待补。
- 在设置 Tab 中切换浅色/深色，确认首页、工作台、设置、工具箱、关于、终端设置、连接历史、访问日志、连接分组、连接导入导出、连接编辑、终端、SFTP 和端口转发页同步变色。
- 在设置 Tab 中切换中文/English，确认首页、工作台、设置、工具箱、关于、终端设置、连接历史、访问日志、连接分组、连接导入导出、连接编辑、终端、SFTP 和端口转发页文字即时刷新。
- 在设置 Tab 中切换“系统”语言，确认语言摘要显示“跟随系统 · 当前语言”，强停并重新启动后仍保持该选项。
- 强停并重新启动后，主题和语言偏好应保持。

当前工具箱已有首批纯 ArkTS 开发/系统小工具和纯 HarmonyOS 网络工具子集；网络拓扑、端口扫描、公网 IP、受控子网发现、HTTP 下载/上传测速、连通性、ICMP 等价验收、Nginx 同输入变量/include 摘要、外部 include 导入展开和 QR Version 2-L 矩阵、二维码预览、SVG 保存写入/回读和 IP 详情全部网络/多网卡枚举已有设备输出。PNG/相册保存、扫码兼容性和进一步美化仍未完成。主题和多语言当前已覆盖主壳、工作台、设置 Tab、设置页、工具箱页、主要二级页、连接编辑、终端、SFTP 和端口转发；系统语言跟随已有设置 Tab 点击和强停重启证据，仍需完整多页面切换矩阵和无障碍/高对比验证。

### 8.2.2 全屏避让

应用当前使用全屏窗口和透明系统栏。至少检查：

- 首屏顶部标题、右上入口和第一个卡片不被状态栏、挖孔或系统胶囊遮挡。
- 底部悬浮胶囊导航不被导航栏或手势区域遮挡。
- 顶部 Logo/标题区应是半透明渐变过渡，底部 Tab 区应是半透明 Thin blur 胶囊；中间内容可滚动到玻璃层下方，且标题控件不能压住第一张卡片，滚动手势不能被空白覆盖层吞掉。
- 连接页顶部避让后应直接进入“连接方式”，不再显示 logo 下方 SSH/二进制横幅。
- 切换横竖屏或不同窗口尺寸后，连接页列表、筛选卡片和底栏仍有足够 padding。
- Terminal/SFTP 等滚动页面底部内容不会被底栏覆盖。

### 8.3 连接分组页

`pages/ConnectionGroupPage` 已注册到页面路由，并已从首页工作台与连接页接入。测试：

- 页面标题、说明卡片和分组列表保持现有浅蓝背景、白色圆角卡片风格。
- 首页“连接分组”入口可进入页面。
- 连接页筛选卡片中的“管理分组”可进入页面。
- 默认分组显示主机数量，且默认分组不能删除。
- 新建分组后列表刷新。
- 折叠 / 展开状态可切换。
- 空分组可删除，非空分组暂不删除。

当前分组走 RDB-backed 仓库；需要补测关闭应用并重新启动后新增分组、改名、换色、排序和折叠状态仍正确。

### 8.4 访问日志页

`pages/AuditLogPage` 已注册到页面路由，并已从首页工作台接入。测试：

- 首页“访问日志”入口能进入页面。
- 页面显示“本地 RDB 摘要日志，不记录命令输出或凭据”提示。
- 执行连接成功、连接失败、批量收藏、批量移组、批量删除、分组新增/改名/折叠后，日志列表出现对应摘要。
- 清空日志后列表为空。
- 关闭应用并重新启动后，未清空的日志仍可回显。
- 检查日志摘要不包含密码、私钥口令、命令输出或服务器地址。

### 8.4.1 连接导入导出页

`pages/ConnectionImportExportPage` 已注册到页面路由，并已从首页工作台、连接页和设置 Tab 接入。测试：

- “导出 OpenSSH config”能唤起系统保存选择器，保存后回读文件确认包含 Host/HostName/User/Port，不包含密码、私钥文件路径或私钥口令。
- “导入 OpenSSH config”能唤起系统文件选择器，选择样本后出现待导入预览，确认后连接列表新增主机。
- “导出 JSON 连接备份”能唤起系统保存选择器，保存后回读 JSON，确认 `policy` 为脱敏导出且敏感字段为空。
- “导入 JSON 连接备份”能非覆盖合并连接和分组，重复导入按主机、端口和用户去重。
- OpenSSH `IdentityFile` 样本导入后显示需重新导入私钥的提示，不保存原始本机私钥路径。
- 关闭应用并重新启动后，导入的连接和分组仍可回显。

### 8.5 终端

在远端执行：

```text
whoami
pwd
ls -la
stty size
```

再测试：

- 横竖屏或窗口变化后 `stty size` 变化。
- Ctrl/Alt/Esc/Tab/方向键可用。
- 彩色输出、CJK、滚动历史、复制。
- `vim`、`tmux`、`htop`、`nano` 至少各做一次冒烟。

当前终端是“较完整 VT 基线”，不能直接宣称完整 xterm。

### 8.6 SFTP

先测只读：

- 根目录列表。
- 进入目录。
- 返回上级。

再测写操作：

- 上传小文本。
- 下载后逐字节对比 SHA256。
- 新建目录。
- 重命名。
- chmod `0644`。
- 删除文件与空目录。

大文件、取消、中断恢复仍需单独取证。

### 8.7 端口转发

三类都要逐字节验证：

| 类型 | 场景 | 通过标准 |
|---|---|---|
| local `-L` | 本机 loopback → SSH → 远端 echo/http | 双向字节一致，移除后端口释放 |
| remote `-R` | 服务器回环监听 → SSH → 本地 echo/http | 服务端能连通，断开后监听消失 |
| dynamic `-D` | SOCKS5 CONNECT IPv4/IPv6/域名 | 返回目标真实响应，错误目标正确失败 |

端口转发源码存在不等于完成；必须有真实流量证据。

### 8.8 断线与重连

测试：

- 远端 sshd 重启。
- 手机/模拟器断网再恢复。
- HostKey 变化。
- 认证失败。
- 正常 exit。

通过标准：

- 只有“曾成功连接”的 tab 自动重连。
- HostKey 变化、认证失败、无效配置、正常 shell 退出不进入重连风暴。
- 断开前 channel、forward、session、socket 被清理。

## 9. 当前不能写成完成的内容

- HUKS/ASSET 凭据安全存储。
- arm64 真机真实 SSH 完整验收。
- 完整 xterm 兼容。
- SFTP 大文件/取消/中断恢复。
- 三类端口转发真实 HAP 流量证据。
- 后台保持、RDB 跨重启持久化验收、ProxyJump、Mosh、X11、云/虚拟化/VNC。
- 工具箱中的 PNG/相册保存、扫码兼容性和进一步美化；ICMP 当前只能按普通应用的默认网络、DNS 解析和 TCP connect 做等价验收。
- 全局主题/多语言完整矩阵；当前已完成主壳、工作台、设置 Tab、设置页、工具箱页、关于、终端设置、连接历史、访问日志、连接分组、连接导入导出、连接编辑、终端、SFTP 和端口转发页，系统语言跟随已有设置 Tab 点击和强停重启证据，仍需无障碍/高对比、动态文案和完整多页面切换验收。

## 10. 测试完成后要回填

每次测试后同步：

- `docs/BUILD_TEST.md`：构建、安装、设备和 HAP 哈希证据。
- `docs/PROGRESS.md`：哪些已通过，哪些仍阻塞。
- `docs/ISSUES.md`：失败、风险、复现步骤。
- `reports/project_audit_latest.md`：静态审计结果。

任何含凭据、服务器地址、用户名或私钥内容的原始日志不得提交。
