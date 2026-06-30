# Changelog

All notable changes to TabSSH / OpenTabSsh should be documented in this file.

This project aims to follow a simple, human-readable changelog format and semantic versioning where possible.

## Unreleased

### Added

- Added four-artifact CI build flow for HarmonyOS/OpenHarmony named packages across `arm64-v8a` and `x86_64`.
- Added MIT `LICENSE` file.
- Added `NOTICE` with copyright, trademark, platform, and unofficial-project notices.
- Added `THIRD_PARTY_NOTICES.md` dependency and redistribution inventory.
- Added `SECURITY.md` security reporting policy.
- Added `CODE_OF_CONDUCT.md` community rules.
- Added `CONTRIBUTING.md` contribution guide.
- Added `SUPPORT.md` support policy.
- 建立统一的接力、路径、构建测试、清理、备份、审计和 GitHub 发布规范。
- 新增固定版本双 ABI zlib/OpenSSL/libssh2 构建、真实 HAP stage 和 real-marker 验包脚本。
- 编码 libssh2 非阻塞握手、HostKey SHA256 阻断/确认、密码/私钥认证、PTY、SFTP list 和断开清理；尚待真实构建与端到端验证。
- 新增基础 ANSI/VT 网格、输出轮询和控制键；端口转发不再呈现 Mock 成功。
- 新增并收敛 GitHub 托管 `ubuntu-latest` 手动最小 HAP 格式 workflow，先验证 unsigned HAP zip 和双 ABI `libentry.so`。
- 首页工作台与连接页接入连接分组管理入口，连接页增加分组筛选芯片；已通过 HAP 编译、安装和首屏可见性检查，仍待完整设备点击证据。
- 连接仓库接入 HarmonyOS `relationalStore` RDB，保存分组、主机配置、收藏、排序、HostKey 元数据和连接统计，写库前清空密码与私钥口令。
- 连接页新增搜索命中高亮、批量模式、批量收藏/取消收藏、批量移组和批量删除；仍待逐项设备点击和跨重启验证。
- 应用开启全屏布局、透明系统栏、窗口隐私保护和系统避让区 padding；仍待多设备全屏避让矩阵。
- 新增访问日志摘要页、RDB `connection_audit_logs` 表和工作台入口；当前只记录认证结果、批量操作和分组变更摘要，不记录命令输出或凭据。
- 所有已注册 ArkUI 页面接入全屏避让区 padding；最新 Real HAP 已完成单台 x86_64 模拟器多页无凭据 UI hierarchy 抽样。
- 访问日志页新增 summary-only JSON 导出入口，可唤起系统保存选择器并使用 `opentabssh-audit-*.json` 默认文件名。
- 访问日志页新增本地事件筛选芯片，对齐 Android Filter 入口。
- 新增连接历史页，对齐 Android 只读历史视图，基于 RDB profile 统计字段展示历史主机、成功主机和失败记录。
- 新增连接导入导出页，对齐 Android Import / Export 的安全核心路径，支持 OpenSSH config 与脱敏 JSON 连接备份导入/导出。
- 新增工具箱页，并从工作台右上角和“设置 / 工具 / 工具箱”接入；首批纯 ArkTS / 纯 HarmonyOS 工具支持 JSON 格式化/压缩、Base64 编解码、FNV-1a 快速校验、文本统计、颜色转换、单位换算、系统/存储/IP 基础信息、访问审计跳转、默认网络/DNS/网关摘要、TCP 连通性探测、端口扫描、HTTP 下载样本测速、Nginx 配置摘要和 QR 负载摘要。
- 新增应用级浅色/深色主题偏好和中文/English 语言偏好，当前覆盖首页主壳、工作台、设置 Tab、设置页、工具箱页、关于、终端设置、连接历史、访问日志、连接分组和连接导入导出页。
- 底部 Tab 胶囊导航接入浅色/深色主题色板，并增加底部安全距离与内容区预留，避免与页面底部控件或手势条重叠。
- 新增 `BuildInfo.ets` 和 `scripts/update_build_info.ps1`，构建脚本刷新版本号与构建时间，关于页展示应用版本和构建时间。
- 第四个底部 Tab 改为“设置”，并将主题/语言、文件、缓存、终端、工具和关于分组直接展开到主 Tab。
- 连接编辑、终端、SFTP 和端口转发页面接入应用主题色板与中文/English 双语刷新。

### Changed

- Documented that the project is independent and not an official Huawei, HarmonyOS, OpenHarmony, OpenSSH, SSH, or libssh2 project.
- Documented that proprietary SDKs, signing materials, credentials, and third-party binaries must not be committed unless redistribution rights and notices are confirmed.
- Updated build configuration to support separate ABI artifacts.
- 明确当前版本是 Mock SSH 工程骨架，真实 SSH/SFTP/转发尚未完成。
- 统一 Bundle 文档为 `com.open.tabssh`。
- 构建和测试统一迁移到工作区共享 `99_Temp` 的项目专属子目录。
- 将 TabSSH Web、Android、Desktop 三份上游源码浅克隆到 `99_Temp\tabssh_reference` 供对照，不纳入本仓库。
- 访问日志和 RDB 文档状态更新为“新增分组与分组变更摘要已通过基础强停重启回显”，不再笼统写成跨重启完全未验。
- `stage_project_for_build.ps1` 清理旧 stage 时增加重试与空目录镜像兜底，降低 Windows 深路径缓存导致的无人值守构建失败。
- 工作台右上角入口改为工具箱，不再跳转系统设置。
- 工作台主机列表改为直接显示已保存主机信息和连接按钮，不再通过“主机列表”动作切换到连接 Tab。
- 顶部 Logo/标题区改为 RustDesk HarmonyOS 风格的半透明渐变过渡，底部 Tab 区保留半透明 Thin blur 胶囊；全局浅色/深色色板同步调整为更清透的 `#F0F4FA` / `#171A1E` 基底。

### Fixed

- Replaced ArkTS-incompatible standard library usage in connection profile normalization.
- Added missing build targets needed by the CI matrix.
- Improved HAP artifact discovery and packaging verification in CI.
- Mock unsigned HAP 已通过仓库外构建并验证双 ABI native entries。
- Mock fallback 已在 x86_64 模拟器覆盖安装、冷启动并完成无凭据 UI hierarchy 冒烟。
- 真实连接测试定位到同步 N-API 导致的 ArkUI `APP_INPUT_BLOCK`；将 connect/openShell/SFTP list 迁移到 async work / Promise，并修复连接编辑返回后的列表刷新。

### Security

- Added explicit rules against committing SSH credentials, private keys, tokens, signing materials, SDK archives, and sensitive logs.
- 移除源码中的示例密码，凭据仅允许在测试运行内存中使用。
- 修复全屏顶部覆盖层吞掉设置 Tab 滚动手势的问题，空白覆盖层改为透明命中。

## 0.1.0

### Added

- Initial TabSSH / OpenTabSsh HarmonyOS ArkTS + Native C++ project skeleton.
- UI structure for connection management, terminal placeholder, SFTP placeholder, settings, and about pages.
- Native N-API bridge structure.
- Explicit Mock native fallback when real SSH third-party libraries are absent.
