# 脚本说明

- `run_local_checks.ps1`：本地拉取后的一键检查入口；默认执行 `git diff --check`、全局静态审计、连接分组专项审计、终端解析器测试、Mock 构建和 Mock 验包；加 `-WithRealCore` 后执行真实 HAP 构建与验包，加 `-BuildDependencies` 后先重建双 ABI 三方依赖。
- `audit_connection_groups.ps1`：连接分组专项静态审计；检查 `ConnectionGroupPage.ets`、首页分组入口/筛选、`main_pages.json` 路由、RDB-backed 仓库接口、改名/换色/排序/折叠能力和文档同步；只证明源码结构完整，不证明 ArkUI/HAP 编译通过或跨重启点击验收。
- `audit_project.ps1`：全局静态审计；当前覆盖 ProIcons 政策、连接分组、连接历史、连接导入导出、RDB 持久化、访问日志摘要/导出/筛选、搜索高亮、批量操作、主题/中英双语偏好、系统语言跟随、设置 Tab 展开、顶部/底部半透明玻璃层、BuildInfo、所有注册页面的全屏避让、终端、SFTP、转发和生成产物清理。它不能替代 HAP 安装、设备点击、跨重启或真实流量证据。
- `install_and_smoke.ps1`：安装 `99_Temp` 中的 HAP 到 hdc 默认设备或 `-DeviceId` 指定设备，启动 `com.open.tabssh`，采集 bundle dump、PID、过滤 hilog/faultlogger 和 BuildInfo 线索，并输出无凭据摘要；只证明安装/冷启动和版本信息可读，不证明 SSH 功能。
- `stage_project_for_build.ps1`：把干净源码复制到 `99_Temp\harmonyos_stage\10_Tabssh_harmonyos`，仓库根不生成构建产物；清理旧 stage 时会重试并用空目录镜像兜底处理深路径缓存，但目标仍必须位于本项目 `99_Temp` stage 下。
- `build_mock_hap.ps1`：在 stage 中刷新 BuildInfo 并执行 Hvigor Mock HAP 构建，复制 HAP/APP 到 `99_Temp\harmonyos_build\10_Tabssh_harmonyos`，日志写入 `99_Temp\tabssh_harmonyos_logs`。
- `update_build_info.ps1`：从 `AppScope/app.json5` 读取版本号/版本码并写入 `entry/src/main/ets/common/BuildInfo.ets`，供关于页和安装冒烟摘要展示。
- `run_hvigor_with_sdk_patch.js`：仅修正当前 DevEco 命令行 SDK 组件发现错误，不改版本、不隐藏 ArkTS 编译错误；由构建脚本在 stage 中调用。
- `verify_mock_hap.ps1`：参考 RustDesk 验包流程，检查 HAP 内 arm64-v8a/x86_64 的 `libentry.so`、`libc++_shared.so` 和 ELF magic，再输出大小与 SHA256；不把 unsigned 包当成安装证据。
- `build_native_dependencies.ps1`：固定版本/commit/SHA256 构建双 ABI 静态 zlib/OpenSSL/libssh2，并在依赖区生成哈希 manifest。
- `build_real_hap.ps1`：复核 manifest 后刷新 BuildInfo，把依赖复制到仓库外 stage，构建 `entry-default-unsigned-real.hap`。
- `verify_real_hap.ps1`：检查双 ABI machine 与 real-core marker，并拒绝 Mock marker；仍不代替端到端测试。
- `audit_project.ps1`：单次检查文档、Bundle、双 ABI、Mock 边界、凭据卫生、ProIcons、连接分组基础和清理状态；新项目不做机械重复多轮审计。
- `test_terminal_emulator.ps1`：对 `TerminalEmulator.ets` 做 TypeScript 语义检查和 VT/SGR/宽字符/备用屏/响应序列/fuzz 冒烟；不能替代设备端 ArkUI 性能回归。
- `start_test_sshd.ps1`：启动仅绑定 `127.0.0.1` 的本机 OpenSSH 测试端；测试密钥和日志只进入 `99_Temp`，不得提交。
- `clean_project.ps1`：默认只清理仓库内可再生项；`-BuildOnly` 只清理 build/entry build/.cxx；`-IncludeExternalBuild` 才清理本项目的 stage/build/log。发现 APK 时拒绝删除。
- `backup_project.ps1`：创建不含凭据/产物/缓存的源码备份到 `99_Temp\tabssh_harmonyos_backups`，默认只保留最新 2 份。

所有脚本从项目位置推导 `%VSCODE_ROOT%`。禁止把其他项目路径加进清理列表。
