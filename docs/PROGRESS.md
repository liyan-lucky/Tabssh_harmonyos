# 功能进度

## 已实现（Mock 基线）

- HarmonyOS Stage 模型、`com.open.tabssh`、arm64-v8a/x86_64 配置。
- 首页、连接编辑、连接分组、终端、SFTP、端口转发、设置、关于页面。
- 访问日志页面；当前是本地 RDB 摘要日志，不记录命令输出或凭据。
- 连接历史页面；当前基于 RDB profile 统计字段展示历史主机、成功主机和失败记录。
- 连接导入导出页面；当前支持 OpenSSH config 导入/导出和脱敏 JSON 连接备份导入/导出。
- Native N-API 接口与内存 Mock session/channel/forward。
- RDB-backed 连接配置仓库；示例配置不含密码，密码和私钥口令持久化前清空。
- 统一文档、路径、清理、备份、审计和发布脚本规范。
- 单次静态基线审计 29/29；Mock unsigned HAP 构建成功并确认双 ABI native entries。
- Web/Android/Desktop 三份上游源码已在 `99_Temp\tabssh_reference` 建立浅克隆参考。
- Mock fallback 新契约已完成 x86_64 模拟器覆盖安装和冷启动验证；证据见 `BUILD_TEST.md`。
- 2026-06-29 首页分组入口第一版本地一键检查、Mock HAP 构建/验包、x86_64 模拟器安装/冷启动和首屏 UI hierarchy 冒烟已通过；该版 HAP SHA256 为 `7496E689F7E618C1543023851B7695A7418B503831E8B761B711C22831151DAF`，首屏层级包含“连接分组”等入口文本，证据见 `BUILD_TEST.md`。
- 2026-06-29 连接仓库已接入 HarmonyOS `relationalStore` RDB，密码和私钥口令写库前清空；新增分组“新分组 1”和对应“分组变更 / 新增分组”摘要已在 Real HAP 强停重启后回显。改名、换色、收藏、统计、异常恢复和 schema migration 仍待验。
- 2026-06-29 连接页已编码搜索命中高亮、批量模式、批量收藏/取消收藏、批量移组和批量删除；同轮开启全屏布局、透明系统栏、窗口隐私保护和系统避让区 padding。该轮 Real HAP SHA256 为 `D89DA03877A4A8EF43EB7CEBDC48A0BC6817664CE3E7EB2C568DA8B33B270898`，已在 x86_64 模拟器安装/冷启动，并通过首页、我的、系统设置、终端设置、关于、连接页、连接编辑、SFTP、端口转发、访问日志筛选和连接历史空状态的无凭据 UI hierarchy 抽样。
- 2026-06-29 已新增访问日志摘要能力：连接认证结果、批量操作和分组变更写入 RDB `connection_audit_logs` 表，首页“访问日志”可进入 `AuditLogPage`；最新 Real HAP 已验证从连接分组“新建”写入“分组变更 / 新增分组”摘要并在访问日志页显示，且强停重启后仍可回显。对齐 Android Export 和 Filter 入口后，访问日志页已能唤起系统保存选择器导出 summary-only JSON，并支持按全部、认证成功、认证失败、分组、批量、配置筛选；真实文件写入/回读、完整 Android 审计日志的命令/输出记录、保留策略、MDM/syslog、真实认证事件仍待补。
- 2026-06-29 已新增连接历史页：对齐 Android `ConnectionHistoryActivity`，从 RDB profile 统计字段聚合最近连接历史，工作台“连接历史”入口和空状态已在最新 Real HAP 上通过 UI hierarchy 验证；真实成功/失败连接后的历史行、点击进入终端和跨重启统计回显仍待补。
- 2026-06-29 已新增连接导入导出页：对齐 Android `ImportExportActivity` 的安全核心路径，新增 `ConnectionImportExportService`，支持导出 OpenSSH config、导入 OpenSSH config、导出脱敏 JSON 连接备份和导入脱敏 JSON 连接备份；导出不包含密码、私钥文件、私钥口令或命令输出，导入采用非覆盖合并并按主机/端口/用户去重。最新 Mock HAP 大小 `3,860,803` bytes，SHA256 `F4B6AC6B9B89019EF9E0236CCE53AAA60BBDC9876E5B229BF2CDAB1F58B30331`；最新 Real HAP 大小 `12,610,587` bytes，SHA256 `2DA0DAC44B558F293B6465A9ED8429FB8DDF862EBE5B7CC0F6E2700C0C42C0DA`。Real HAP 已安装冷启动并验证工作台“导入导出”入口、新页面首屏、JSON 导出保存选择器和 OpenSSH 导入文件选择器；真实文件写入/回读、真实导入样本落库、加密 ZIP、云同步和 QR 配对仍待补。
- 2026-06-29 已按最新参考要求调整工作台与我的页：工作台右上角改为 `ToolboxPage` 工具箱入口，不再跳转设置；工作台主机列表直接显示 RDB 已保存主机与连接按钮，不再切到连接 Tab；“我的 / 工具”新增工具箱入口。新增 `AppSettings`、`AppTheme`、`I18n`，设置页支持浅色/深色主题和中文/English 语言偏好，当前主题和翻译已覆盖首页主壳、工作台、我的、设置页和工具箱页。最新 `scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，Mock HAP 大小 `4,016,989` bytes、SHA256 `A5630FDA5D9864B0D64FBBB6C88A327DC045BFEDECC2991FFEE0310A68DD04F5`，Real HAP 大小 `12,766,773` bytes、SHA256 `2E1716B9D25953089496D6CB5CF39A809B64502B2117F4F203E716E3286733C0`；同一 Real HAP 已完成安装冷启动冒烟，系统设置中 English/Dark 切换刷新已通过 UI hierarchy 复测。
- 2026-06-29 工具箱已从入口骨架推进到首批纯 ArkTS 工具能力：JSON 格式化/压缩、Base64 编解码、FNV-1a 快速校验、文本统计、颜色转换、单位换算、系统/存储/IP 基础信息和访问审计跳转；同日继续接入纯 HarmonyOS 网络工具，使用 `@ohos.net.connection` 读取默认网络/链路/DNS/网关，使用 `@ohos.net.socket` 做 TCP 连通性/端口扫描，使用 `@ohos.net.http` 做 HTTP 下载样本测速，并补 Nginx 配置摘要解析和 QR 负载摘要。`scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，Real HAP 大小 `12,885,465` bytes、SHA256 `047563BB8F223043CDAE3F4105636A34B0E6C37B8A56B96C3A48434FC1E9F44B`；安装冷启动 PID `9646`，工具箱网络拓扑 runner 已输出 `eth0 / 10.0.2.15/24 / 10.0.2.2`，端口扫描 runner 已对 `127.0.0.1 22,80,443` 输出逐端口 TCP 状态。主动子网发现、上传测速、特权 ICMP、QR 图片矩阵和复杂 Nginx include/变量展开仍待补。
- 2026-06-30 继续扩展浅色/深色和中文/English 覆盖：`AboutPage`、`TerminalSettingsPage`、`ConnectionHistoryPage`、`AuditLogPage`、`ConnectionGroupPage`、`ConnectionImportExportPage` 已接入 `AppTheme`、`I18n` 和 `@StorageLink` 刷新，并补齐二级页面中英文本。最新 `scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计更新为 103/103，连接分组专项审计 16/16；Mock HAP 大小 `4,184,471` bytes、SHA256 `F5BC956EE8D0A38E641626BA4D9274CB6A91F07696A9E8D513AB1AE9136E971D`，Real HAP 大小 `12,934,255` bytes、SHA256 `E12FD310F41542BBCFD13DDA25D6CD433328C6127DE6EA0A2E7F29C993DA7BD2`。最新 Real HAP 已覆盖安装冷启动，PID `9996`，并在 English/Dark 下取得首页、我的、连接历史、连接分组、导入导出、访问日志、终端设置和关于页 UI hierarchy 证据。连接编辑、终端、SFTP 和端口转发页仍需继续迁移主题色板和中英翻译。
- 2026-06-30 修复底部 Tab 菜单主题和避让：底部胶囊背景、边框、阴影、未选中图标和文字已跟随浅色/深色主题，底栏上移并增加页面内容底部预留，避免与下方控件或手势条重叠。当轮 `scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，Real HAP 大小 `12,956,285` bytes、SHA256 `8648E6C621B600A339B6853BB98022A4C5BAF8D6A6521DCB1B14737054688079`；安装冷启动 PID `26122`，已取得暗色/浅色底栏层级和截图证据。
- 2026-06-30 继续按最新偏好调整主壳：第四个 Tab 已从“我的”改为“设置”，设置内容直接展开到主 Tab，去掉旧顶部文本和“系统设置”跳转项；工作台右上角仍进入工具箱，工具箱入口也保留在设置 Tab 的工具分组中。顶部 Logo/标题区和底部 Tab 区改为半透明模糊背景，内容可延伸到玻璃层下方；关于页显示 `BuildInfo.ets` 提供的版本和构建时间，`scripts/update_build_info.ps1` 已接入 Mock/Real HAP 构建脚本。当轮 `scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 107/107，Real HAP 大小 `12,999,437` bytes、SHA256 `145DD997852A047D764D495116CAC1F5DA2446707BE56D56B0DFEF0494089A93`；安装冷启动 PID `17261`，已取得首页玻璃层、设置 Tab 展开/滚动和关于页版本构建时间截图证据。
- 2026-06-30 按 RustDesk HarmonyOS UI 文档修正全局主题色板：浅色基底改为 `#F0F4FA`，暗色基底改为 `#171A1E`，底部 Tab 胶囊使用 `#30FFFFFF` / `#20000000` 高透明材质色；顶部 Logo/标题区从整块毛玻璃改为多段半透明渐变，并把内容顶部起点与渐变高度分离，避免标题控件压到第一张卡片。本轮同时把 `ConnectionEditPage`、`TerminalPage`、`SftpPage`、`PortForwardPage` 接入 `AppTheme`、`I18n`、主题/语言 `@StorageLink`，清理主页残留中文 toast 和写死灰色。最新 `scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 108/108，Real HAP 大小 `13,032,652` bytes、SHA256 `34A2CA50560F1BAE9662888216B2E287DC078B8E386A8E7659B954E753FC406C`；安装冷启动 PID `15229`，首页最终截图 `screenshot_20260630_074325_home_theme_gradient_final.jpeg` 确认顶部渐变与内容间距已修正。
- 2026-06-30 继续按在线检查反馈收紧首页顶部和 Logo 区默认距离：`HeaderOverlay` 高度调整为 `avoidStatusBarHeight + 76`，内容起点调整为 `headerOverlayHeight() - 14`，Header 行高和顶部 padding 同步缩小，使顶部标题贴近安全区且第一张主机卡片进入渐变尾部但不重叠。最新 `scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，Real HAP 大小 `13,032,652` bytes、SHA256 `9E2394A128527539E263F9C8CF35DB5954B2CCFBD609D66DD064634D5A95BB5A`；安装冷启动 PID `6767`，首页截图 `screenshot_20260630_152837_home_top_tighter.jpeg` 已确认顶部/Logo 间距收紧。
- 2026-06-30 补齐设置 Tab 的系统语言跟随选项：语言分段改为“系统 / 中 / EN”，`AppSettings.ets` 使用纯 HarmonyOS `@ohos.i18n` 读取首选语言列表、系统语言和系统 locale，并在 `I18n.ets` 渲染时把 `system` 解析为中文/English。最新 `scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 119/119，Real HAP 大小 `13,039,728` bytes、SHA256 `A54EDDE5C4338B393952875A4BACA1AFD7A8D2E67ECBB5845F9A03823053DFED`；安装冷启动 PID `17370`，设置 Tab 语言行设备层级可见“系统 / 中 / EN”，点击系统后显示“跟随系统 · 简体中文”，强停重启后 PID `17427` 仍回显该偏好。
- 2026-06-30 继续按在线检查反馈把首页顶部 Logo/标题区贴近安全区：`HeaderOverlay` 改为 `headerStatusInset() + 64`，状态栏占位收紧为 `avoidStatusBarHeight - 10`，内容顶部从 `headerOverlayHeight() - 12` 起步；同时为 IP 详情工具新增“公网 IP”按钮，使用纯 HarmonyOS `@ohos.net.http` 依次查询 HTTPS 文本服务并用本地解析提取出口地址。最新 `scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 120/120，Real HAP 大小 `13,048,399` bytes、SHA256 `254DD95BD808D3E02CCB2608D6F556100F736107B4E08CCEADDA709F6DB8ABAA`；安装冷启动 PID `2098`，首页层级 `layout_20260630_160625_home_header_tightest.json` 显示“工作台”标题上沿已到 y=141，工具箱 `layout_20260630_160625_toolbox_public_ip_result_attempt1.json` 显示“公网 IP：<redacted> / 来源：https://ifconfig.me/ip / HTTP 200”。
- 2026-06-30 继续补工具箱网络拓扑的主动子网发现：新增“发现”按钮，读取默认 IPv4/CIDR 后使用纯 HarmonyOS `@ohos.net.socket` 对网关、DNS、已保存主机和网段前 16 个候选主机做受控 TCP 探测，每台只检查 22/80/443。最新 `scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 121/121，Real HAP 大小 `13,064,020` bytes、SHA256 `927FD7B8B5030B43FFA2E86B6B1B1E6BE35C6CBE4FE9C3C1DE552B73C40A5C3B`；安装冷启动 PID `14649`，工具箱 `layout_20260630_162351_toolbox_subnet_discovery_result.json` 显示 `发现范围：10.0.2.0/24 / 受控发现最多探测 16 个 IPv4 主机 / 10.0.2.2 -> 22/tcp 8 ms`。
- 2026-06-30 继续把首页顶部 Logo/标题区贴住安全区：`HeaderOverlay` 改为 `headerStatusInset() + 56`，状态栏占位收紧为 `avoidStatusBarHeight - 18`，内容顶部从 `headerOverlayHeight() - 20` 起步，普通 Header 行高为 44、监控 Header 行高为 50；同时同步远端删除旧 `online-build.yml` 后的审计和文档事实。最新 `scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 119/119，Real HAP 大小 `13,064,020` bytes、SHA256 `16E26087577669659A7715071C2FDD9E7078F979EC897983D072CDF75F8C6FD4`；安装冷启动 PID `31110`，首页层级 `layout_20260630_164803_home_header_sticky.json` 显示“工作台”标题 bounds 为 `[596,137][827,196]`，首个“主机列表”文本 bounds 为 `[102,298][354,372]`，顶部贴近且未遮挡首块内容。
- 2026-06-30 继续按在线反馈把首页顶部和 Logo 区默认距离贴紧，同时保留最小状态栏避让：`HeaderOverlay` 改为 `headerStatusInset() + 48`，状态栏占位使用 `Math.max(24, avoidStatusBarHeight - 18)`，内容顶部从 `Math.max(32, headerOverlayHeight() - 40)` 起步，普通 Header 行高为 40、监控 Header 行高为 46；同时修复 Nginx 默认单行样例解析，先把 `{` 和 `;` 归一成换行再解析。最新 `scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 119/119，Real HAP 大小 `13,064,386` bytes、SHA256 `F9A480A234589F180410976636DCB88B91E11CE2F0F1226CC3A2FD9090947585`；安装冷启动 PID `10457`，首页层级 `layout_20260630_220033_home_header_safe_flush.json` 显示首个主机卡片 bounds `[53,161][1267,714]`，“主机列表”文本 bounds `[102,210][354,284]`；工具箱 HTTP 下载样本、单项 TCP 连通性、Nginx 摘要和 QR 负载摘要均已有 Real HAP 输出证据，其中 HTTP 样本返回 `404` 但产生字节/耗时/速率统计，TCP 样本为关闭或超时。
- 2026-06-30 继续补齐工具箱剩余能力：网络测速新增纯 HarmonyOS HTTP POST 上传测速，Nginx 摘要新增同输入 `set` 变量展开、`include` 检出和 upstream server，二维码工具新增纯 ArkTS QR Version 2-L Byte 矩阵，IP 详情源码新增路由和地址族字段。最新 `scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，全局审计 123/123，Real HAP 大小 `13,106,528` bytes、SHA256 `7947F63EB123D386BB4B5D858B6A5D9C3F348020E1B38F7D73DF2A514F3C4DB1`；安装冷启动 PID `30385`，工具箱 `layout_20260630_223018_toolbox_upload_result.json` 显示 HTTP POST 上传 `65536` 字节、耗时 `2967 ms`、吞吐 `177 kbps`，`layout_20260630_223018_toolbox_nginx_expanded_result.json` 显示 `$target -> http://app`、`include: conf.d/*.conf` 和 upstream server，`layout_20260630_223018_toolbox_qr_matrix_result.json` / `screenshot_20260630_223018_toolbox_qr_matrix_result.jpeg` 显示 `Version 2-L Byte, 25x25` QR 矩阵。
- 旧 `.github/workflows/online-build.yml` 4-package 格式验证入口已由远端提交移除。当前线上保留 `test-harmonyos-sdk-token.yml` 预检私有 SDK Token、`build-harmonyos.yml` 手动 HAP 构建/可选 Release、`cleanup-releases.yml` 明确维护清理；`build-harmonyos.yml` 使用项目 SDK patch 脚本构建、刷新 BuildInfo、上传 HAP/SHA256/包清单。上述 workflow 仍缺本仓库线上成功 run 证据。
- `scripts/run_local_checks.ps1` 已作为本地拉取后一键检查入口：默认串联 `git diff --check`、全局静态审计、连接分组专项审计、终端解析器测试、Mock 构建和验包；可选 `-WithRealCore` 与 `-BuildDependencies` 执行真实 HAP 与三方依赖路径。
- `scripts/install_and_smoke.ps1` 已作为安装/冷启动冒烟入口：安装 `99_Temp` 中的 HAP、启动 `com.open.tabssh`、采集 bundle/PID/hilog/faultlogger 线索，并输出无凭据摘要；该脚本只做安装启动检查，不标记 SSH 功能完成。
- `scripts/audit_project.ps1` 已增加连接分组、RDB、访问日志、访问日志导出/筛选、连接历史、连接导入导出、搜索高亮、批量操作、全屏避让、工具箱入口、工具箱首批纯工具能力、工具箱网络工具能力、公网 IP、受控子网发现、上传测速、QR 矩阵、Nginx 单行配置/变量/include 解析、默认网络路由/地址族、工作台内联主机列表、主题/语言偏好、系统语言跟随、主题色板、中英翻译主页面覆盖、顶部/底部玻璃层和顶部紧凑间距审计项；`scripts/audit_connection_groups.ps1` 已增加专项审计，并接入一键检查，覆盖分组页面、路由、首页入口/分组筛选、RDB-backed 仓库接口、改名、换色、排序、折叠和文档同步。旧 4-package workflow 移除后，2026-06-30 最新本地检查已通过全局审计 123/123、连接分组专项审计、终端解析器、Mock HAP 和 Real HAP 验包。

## 已编码、待真实构建与端到端验证

- 线上 Linux HAP workflow 尚未取得本仓库成功 run 证据；下一步必须先跑 SDK Token 预检，再跑 `构建并发布 HarmonyOS HAP`，确认 artifact、SHA256、HAP 文件列表和 Release 参数，再决定是否加回更多审计、安装冒烟或自动触发。
- 固定 libssh2 `1.11.1`、OpenSSL `3.5.7 LTS`、zlib `1.3.2` 的双架构依赖已构建并生成 SHA/commit manifest；真实 HAP 已通过双 ABI marker/machine 验证和 x86_64 加载冷启动。
- 真实 Core 的非阻塞握手、HostKey SHA256 阻断/确认、密码/私钥认证、PTY shell、读写/resize、SFTP 列目录和断开清理源码。
- CMake 根据 stage 中经过清单校验的静态库自动切换真实 Core；源码 checkout 继续明确回退 Mock。
- ArkTS 首次 HostKey/变更警告流程；凭据仅保留在运行内存，Mock 不再保存 profile JSON。
- Android 对齐字段骨架已扩展到 `ConnectionProfile`：HostKey 元数据、代理认证、IPv4/IPv6 模式、压缩、agent/X11/Mosh、RemoteCommand、SendEnv、RequestTTY、多路复用、分组/收藏/排序/统计、同步元数据等。字段仅代表可承载配置，未接 UI/Native/RDB 的功能不能标记完成。
- 新增 `ConnectionGroup`、`ProfileFilter` 与 RDB-backed 仓库分组/过滤/排序接口，用于对齐 Android 的连接管理基础；当前 RDB 以 JSON 行保存配置和查询元数据，尚不是完整 Android Room 级规范化 schema。
- `ConnectionGroupPage` 已注册页面路由，用现有浅蓝背景、白色圆角卡片和 ProIcons 风格展示分组列表、新建分组、改名、换色、上移/下移、折叠/展开、空分组移除和每组主机数。首页工作台与连接页入口、连接页分组筛选芯片已通过 Mock HAP 编译、安装和首屏可见性验证；页面跳转、新增、改名、折叠/展开、返回刷新和筛选生效仍待设备点击验证。
- 首页连接页已保持现有浅蓝背景、白色圆角卡片、蓝色芯片和悬浮胶囊底栏风格，接入连接搜索、命中高亮、收藏筛选、分组筛选、排序芯片、收藏切换、批量模式、批量收藏/取消收藏、批量移组、批量删除、连接次数/上次失败提示。该 UI 已通过本轮 Mock/Real HAP 编译、Real HAP 安装和首屏层级冒烟；搜索/收藏/排序/分组筛选/批量操作的逐项点击仍待验证。
- 访问日志页沿用浅蓝背景与白色卡片风格，使用 ProIcons timer 图标，已从首页工作台入口完成 Real HAP 设备点击进入、页面层级验证和分组变更摘要写入/读取验证；当前仅是摘要日志，不是完整 Android 审计日志。
- `EntryAbility` 已开启全屏布局、透明系统栏和窗口隐私保护，并把系统/挖孔/手势避让区转换为 vp 后写入页面 padding；最新 Real HAP 首屏层级显示主入口未被系统栏遮挡。横竖屏、不同导航模式和挖孔设备矩阵仍待验。
- 会话管理已把认证成功写入统计 `lastConnectedAt/connectionCount`，把认证失败、HostKey 确认失败、异常中断和重连异常写入 `lastErrorMessage`；这些字段已接 RDB 持久化路径，但仍缺真实连接后重启回显证据。
- 私钥通过系统文档选择器复制到应用私有 `filesDir/ssh_keys`，不记录原文件 URI 或内容，并提供应用内删除入口；真实包已在 x86_64 模拟器覆盖安装，端到端认证待验。
- 连接导入导出已编码并通过 HAP 编译、Real HAP 安装和 picker 唤起验证；真实导出文件内容回读、真实 OpenSSH/JSON 样本导入落库、导入后跨重启回显、加密备份和 QR 配对仍未完成。
- 工具箱页已注册并能从工作台右上角与“设置 / 工具 / 工具箱”进入；页面使用已登记 ProIcons rawfile 资产展示本机信息、搜索、网络/系统/开发分类和工具卡片。首批纯 ArkTS/纯 HarmonyOS 工具已可用：JSON 格式化/压缩、Base64 编解码、FNV-1a 快速校验、文本统计、颜色转换、单位换算、系统/存储/IP 基础信息、访问审计跳转、默认网络/链路/DNS/网关/路由/地址族摘要、公网 IP、受控子网发现、TCP 连通性探测、端口扫描、HTTP 下载样本测速、HTTP POST 上传测速、Nginx 配置摘要/同输入变量展开/include 检出和 QR Version 2-L 矩阵；网络拓扑、端口扫描、公网 IP、受控子网发现、HTTP 下载样本测速、HTTP POST 上传测速、单项 TCP 连通性、Nginx 摘要/同输入变量展开/include 检出和 QR 矩阵已有 Real HAP 输出；仍未实现特权 ICMP 或完整等价验收说明、二维码图片保存/美化、IP 详情路由/地址族设备点击、多网卡枚举和外部 Nginx include 文件导入/展开。
- 主题和双语偏好已编码并通过 preferences 持久化，当前覆盖首页主壳、工作台、设置 Tab、设置页、工具箱页、关于、终端设置、连接历史、访问日志、连接分组、连接导入导出、连接编辑、终端、SFTP 和端口转发页；设置 Tab 已支持系统语言跟随并完成强停重启回显；仍需继续补更多 service/audit 动态文案、高对比/字体/无障碍和完整切换矩阵。
- 模拟器已验证系统文档选择器 UI 可打开；同时发现并修复连接编辑返回后的列表刷新问题。
- 首次真实连接发现同步 N-API 导致 `APP_INPUT_BLOCK`；`connect`、`openShell`、`sftpList` 已迁移为 async work / Promise 并完成 Mock/真实双架构构建，尚待安装回归。
- 上述异步真实 HAP 已成功覆盖安装到 x86_64 模拟器；HostKey/认证/PTY/SFTP 和无 appfreeze 回归仍待取证。
- x86_64 模拟器已通过本机隔离测试端的真实 SSH 流量回归：异步握手保持 UI 响应，HostKey 首次/变化阻断、密码认证、PTY、命令读写、ANSI 渲染和真实 SFTP 根目录列表均通过，无新增 faultlogger 记录。
- 外部 IPv6 Windows OpenSSH 已进一步通过 ECDSA HostKey、密码认证、PTY、CR 命令提交/真实输出、SFTP 列表、异步关闭和无重复 HostKey 提示的再次连接；无新增 faultlogger 记录。
- 底部主菜单已参照 RustDesk HarmonyOS 改为安全区内的半透明模糊悬浮胶囊；旧自绘底栏 SVG 已替换为 ProIcons 的 tune/network/monitor/display 资产。底栏与顶部 Logo/标题区均已接入半透明主题色板、模糊和避让，最新 Real HAP 已完成暗色/浅色、首页玻璃层和设置 Tab 截图/层级验证；逐页图标渲染仍需设备复查。
- 四张参考图对应的连接入口页、设备监控空状态、设置 Tab 和工具箱页已实现；主要菜单行统一降为 54–62 vp，模拟器逐页 UI hierarchy 验证通过。
- 真实 SFTP 已增加异步上传、下载、建目录、删除、重命名和 chmod；回环内存测试端完成上传→下载逐字节校验、目录、改名、`0644`与清理证据。
- SFTP 数据泵已把网络超时从“整次传输总时限”改为每次成功读写后续期的“空闲时限”，下载结束增加本地 flush 校验；系统 URI 与应用缓存之间改用异步 `fs.copyFile`，避免大文件同步复制阻塞 ArkUI。仍缺真实大文件、取消和中断恢复证据。
- 三类转发已编码：本地 `-L` 与动态 `-D` 只监听 `127.0.0.1`，动态转发实现无认证 SOCKS5 CONNECT（IPv4/IPv6/域名），远程 `-R` 请求服务器回环监听；多连接 worker、异步 N-API、显式移除和 session 断开前清理已接入。当前通过 arm64 与 x86_64 OHOS Clang `-fsyntax-only`，仍需真实构建与三类逐字节流量证据。
- 终端已编码 libssh2 keepalive、断线检测和网络感知自动重连：仅曾成功连接的 tab 参与，初始失败/认证失败/HostKey 待确认/正常 shell 退出不自动重试；退避为 5 秒起步、指数增长、5 分钟封顶，支持“立即重连”，离线时暂停，系统 `netAvailable` 恢复时立即重试，并有 5 分钟 `hasDefaultNet` 兜底轮询。重建 session/PTY 前先释放旧 channel、forward 和 session；keepalive 与 native 改动通过双 ABI语法检查，仍缺 HAP 编译及设备断网/恢复证据。
- 有界 2,000 行历史的 VT 单元格解析器已编码：常用光标/擦除/插删/滚动区、SGR 16/256/RGB 色、粗体/暗色/斜体/下划线/反色/隐藏/删除线、备用屏、OSC 标题、DSR/DA 回复、application cursor、bracketed paste、组合字符和 CJK/Emoji 双宽字符；TerminalPage 已接入样式 `Span`、复制、横向控制键、视口驱动的 PTY resize、主题色和中英双语。独立内存测试与最新 HAP 构建通过，但复杂 TUI/性能设备回归仍不能称完整 xterm。
- 启动、导航、页面入口、文件类型、返回/刷新和方向键图标已统一为 `docs/PROICONS_ICONS.md` 登记的 ProIcons SVG；源码不再使用 Emoji/Unicode 字符充当图标。后续新增/替换图标必须从 ProIcons 官网或已登记 ProIcons 提取记录获取，优先彩色配色资产。

以上 SSH 密码认证、PTY/命令与 SFTP 列目已有真实外部服务器证据；SFTP 写操作已有隔离回环端证据。私钥认证、三类转发、大文件/中断恢复和 arm64 真机仍不能标记完成。

## 未实现（发布阻塞）

- 私钥认证、外部服务器与 arm64 真机端到端证据；HUKS/ASSET 安全存储。
- 连接管理仍未完成：基础新增分组和分组变更摘要已通过跨重启回显，连接历史空状态和连接导入导出 picker 入口已通过设备冒烟，但批量操作逐项点击、搜索高亮逐字段点击、真实连接日志回显、统计页真实数据、导入样本落库/导出回读、schema migration 和设备端完整筛选/分组点击证据仍待补；首页分组入口、分组筛选、批量/高亮源码、访问日志页、连接历史页、连接导入导出页和多页全屏避让已有 HAP/安装/UI hierarchy 抽样证据，但完整设备交互未完成。
- 工具箱真实工具能力仍未完成：JSON、编码、文本、颜色、单位、系统/存储/IP 基础信息、访问审计跳转、默认网络摘要、公网 IP、受控子网发现、TCP 连通性测试、端口扫描、HTTP 下载/上传测速、Nginx 摘要/同输入变量展开/include 检出和 QR Version 2-L 矩阵已有首批纯 ArkTS/纯 HarmonyOS 能力；仍需补特权 ICMP 或等价验收说明、二维码图片保存/美化、IP 详情路由/地址族设备点击、多网卡枚举和外部 Nginx include 文件导入/展开。
- 主题与多语言仍需完整验收：当前浅色/深色、中文/English 和系统语言跟随偏好已覆盖主壳、工作台、设置 Tab、设置页、工具箱页、关于、终端设置、连接历史、访问日志、连接分组、连接导入导出、连接编辑、终端、SFTP 和端口转发页；系统语言选项已完成设置 Tab 点击和强停重启回显，仍缺字体/高对比/无障碍、更多动态 service/audit 文案和完整多页面切换矩阵。
- 终端剩余兼容：完整键盘/IME 逐键输入、选择与搜索、鼠标协议、更多 DEC/xterm 边界、vim/tmux/htop/nano 和设备端性能/渲染回归。
- SFTP 大文件、中断恢复、外部服务器写操作及系统文件保存选择器的稳定回归。
- local/remote/dynamic forwarding 的真实 HAP 与逐字节流量链路证据；源码实现不能替代验收。
- 代理/跳板机、多标签复用、后台保持。
- 异步操作的用户取消、重连/错误恢复设备证据和更完整的压力清理。
- arm64 真机与 x86_64 模拟器真实 SSH 端到端验收。
- 独立 HarmonyOS 签名配置与 signed HAP 安装验证。
