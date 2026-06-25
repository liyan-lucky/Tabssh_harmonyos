# 脚本说明

- `run_local_checks.ps1`：本地拉取后的一键检查入口；默认执行 `git diff --check`、静态审计、终端解析器测试、Mock 构建和 Mock 验包；加 `-WithRealCore` 后执行真实 HAP 构建与验包，加 `-BuildDependencies` 后先重建双 ABI 三方依赖。
- `stage_project_for_build.ps1`：把干净源码复制到 `99_Temp\harmonyos_stage\10_Tabssh_harmonyos`，仓库根不生成构建产物。
- `build_mock_hap.ps1`：在 stage 中执行 Hvigor Mock HAP 构建，复制 HAP/APP 到 `99_Temp\harmonyos_build\10_Tabssh_harmonyos`，日志写入 `99_Temp\tabssh_harmonyos_logs`。
- `run_hvigor_with_sdk_patch.js`：仅修正当前 DevEco 命令行 SDK 组件发现错误，不改版本、不隐藏 ArkTS 编译错误；由构建脚本在 stage 中调用。
- `verify_mock_hap.ps1`：参考 RustDesk 验包流程，检查 HAP 内 arm64-v8a/x86_64 的 `libentry.so`、`libc++_shared.so` 和 ELF magic，再输出大小与 SHA256；不把 unsigned 包当成安装证据。
- `build_native_dependencies.ps1`：固定版本/commit/SHA256 构建双 ABI 静态 zlib/OpenSSL/libssh2，并在依赖区生成哈希 manifest。
- `build_real_hap.ps1`：复核 manifest 后把依赖复制到仓库外 stage，构建 `entry-default-unsigned-real.hap`。
- `verify_real_hap.ps1`：检查双 ABI machine 与 real-core marker，并拒绝 Mock marker；仍不代替端到端测试。
- `audit_project.ps1`：单次检查文档、Bundle、双 ABI、Mock 边界、凭据卫生和清理状态；新项目不做机械重复多轮审计。
- `test_terminal_emulator.ps1`：对 `TerminalEmulator.ets` 做 TypeScript 语义检查和 VT/SGR/宽字符/备用屏/响应序列/fuzz 冒烟；不能替代设备端 ArkUI 性能回归。
- `start_test_sshd.ps1`：启动仅绑定 `127.0.0.1` 的本机 OpenSSH 测试端；测试密钥和日志只进入 `99_Temp`，不得提交。
- `clean_project.ps1`：默认只清理仓库内可再生项；`-BuildOnly` 只清理 build/entry build/.cxx；`-IncludeExternalBuild` 才清理本项目的 stage/build/log。发现 APK 时拒绝删除。
- `backup_project.ps1`：创建不含凭据/产物/缓存的源码备份到 `99_Temp\tabssh_harmonyos_backups`，默认只保留最新 2 份。

所有脚本从项目位置推导 `%VSCODE_ROOT%`。禁止把其他项目路径加进清理列表。
