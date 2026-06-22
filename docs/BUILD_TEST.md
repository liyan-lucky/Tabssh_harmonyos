# 构建与测试要求

## 基线命令

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\audit_project.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_mock_hap.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_mock_hap.ps1
```

脚本先复制干净副本到 `99_Temp\harmonyos_stage\10_Tabssh_harmonyos`，所有 Hvigor、CMake 和 native 产物在该副本内生成，再复制最终 HAP/APP 到 `99_Temp\harmonyos_build\10_Tabssh_harmonyos`。仓库根不得产生 build、`.cxx` 或日志。

2026-06-22 已验证基线：`entry-default-unsigned.hap` 为 `3,048,665` bytes / SHA256 `49CDE90FDD94C0623FF7A65107C112E519C9B732DA0842FC40288D6386471829`；包内存在 `libs/arm64-v8a/libentry.so`、`libs/arm64-v8a/libc++_shared.so`、`libs/x86_64/libentry.so`、`libs/x86_64/libc++_shared.so`。未签名包不算设备安装或发布验证。

## 设备验证

未来 signed HAP 必须分别安装到 arm64 真机和 x86_64 模拟器，核对 SHA256、mtime、版本、双 ABI、设备 `updateTime`、冷启动 PID 和安全筛选后的 hilog。测试凭据只在运行内存输入；不保存原始含敏感字段日志。

## 最终收口

每次重要修改和最终版本执行一次完整审计、全量构建、双设备安装，以及真实 SSH、终端、SFTP、转发、错误恢复和断开清理检查。任何功能源码、Native 依赖或构建配置变化都会使旧 HAP 哈希和设备证据失效。
