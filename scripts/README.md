# 脚本说明

- `stage_project_for_build.ps1`：把干净源码复制到 `99_Temp\harmonyos_stage\10_Tabssh_harmonyos`，仓库根不生成构建产物。
- `build_mock_hap.ps1`：在 stage 中执行 Hvigor Mock HAP 构建，复制 HAP/APP 到 `99_Temp\harmonyos_build\10_Tabssh_harmonyos`，日志写入 `99_Temp\tabssh_harmonyos_logs`。
- `run_hvigor_with_sdk_patch.js`：仅修正当前 DevEco 命令行 SDK 组件发现错误，不改版本、不隐藏 ArkTS 编译错误；由构建脚本在 stage 中调用。
- `verify_mock_hap.ps1`：参考 RustDesk 验包流程，检查 HAP 内 arm64-v8a/x86_64 的 `libentry.so`、`libc++_shared.so` 和 ELF magic，再输出大小与 SHA256；不把 unsigned 包当成安装证据。
- `audit_project.ps1`：单次检查文档、Bundle、双 ABI、Mock 边界、凭据卫生和清理状态；新项目不做机械重复多轮审计。
- `clean_project.ps1`：默认只清理仓库内可再生项；`-IncludeExternalBuild` 才清理本项目的 stage/build/log。发现 APK 时拒绝删除。
- `backup_project.ps1`：创建不含凭据/产物/缓存的源码备份到 `99_Temp\tabssh_harmonyos_backups`，默认只保留最新 2 份。

所有脚本从项目位置推导 `%VSCODE_ROOT%`。禁止把其他项目路径加进清理列表。
