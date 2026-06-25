# 构建与测试要求

## 当前拉取后推荐入口

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_local_checks.ps1
```

默认入口会串联 `git diff --check`、静态审计、终端解析器测试、Mock 构建和 Mock 验包。真实 Core 需要已有三方依赖 manifest 时使用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_local_checks.ps1 -WithRealCore
```

从零构建三方依赖时使用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_local_checks.ps1 -WithRealCore -BuildDependencies
```

构建完成后安装/冷启动冒烟使用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\install_and_smoke.ps1
```

`install_and_smoke.ps1` 只证明安装、启动、PID 与基础异常日志采集；不能替代 SSH、SFTP、端口转发、重连、签名或发布验收。

## 基线命令

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\audit_project.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_mock_hap.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_mock_hap.ps1
```

脚本先复制干净副本到 `99_Temp\harmonyos_stage\10_Tabssh_harmonyos`，所有 Hvigor、CMake 和 native 产物在该副本内生成，再复制最终 HAP/APP 到 `99_Temp\harmonyos_build\10_Tabssh_harmonyos`。仓库根不得产生 build、`.cxx` 或日志。

## 历史验证摘要

详细历史构建和设备验证证据见 Git 历史中的本文件旧版本、`docs/AGENT_HANDOFF.md`、`docs/PROGRESS.md` 与 PR #1 描述。后续每轮新增构建、安装或设备测试证据时，必须追加新的时间戳、HAP 大小/SHA256、设备类型、通过项和未通过项；不得覆盖旧失败记录。

已记录过的关键结论包括：

- Mock fallback 曾在 x86_64 模拟器完成覆盖安装、冷启动和无凭据 UI 冒烟。
- 真实 Core HAP 曾完成双 ABI marker/machine 验证和 x86_64 加载冷启动。
- 首次真实连接曾暴露同步 N-API `APP_INPUT_BLOCK`，后续已迁移为 async work / Promise；该失败记录必须保留作为经验。
- x86_64 模拟器曾通过本机隔离测试端验证 HostKey 首次/变化阻断、密码认证、PTY、命令读写和真实 SFTP 列表。
- 外部 IPv6 Windows OpenSSH 曾通过 ECDSA HostKey、密码认证、PTY、CR 命令提交、SFTP 列表、异步关闭和再次连接不重复 HostKey 提示。
- SFTP 写操作曾在隔离回环测试端验证上传、下载回读、建目录、重命名、chmod 与清理。

## 当前必须补的新证据

- 运行 `scripts/run_local_checks.ps1` 后生成的 `summary_*.md` 结论。
- 运行 `scripts/install_and_smoke.ps1` 后生成的 `summary_*.md` 结论。
- 最新 ProIcons 资源包的 HAP 构建、安装和页面渲染证据。
- 最新终端 Span 渲染、复制、视口 resize、复杂 TUI 和性能证据。
- 三类端口转发真实 HAP 的逐字节流量证据。
- SFTP 大文件、取消和中断恢复证据。
- arm64 真机真实 SSH 端到端证据。

## 记录规则

- 原始日志保存在 `99_Temp`，不要提交。
- 可提交文档只写摘要、HAP 哈希、设备类型、通过项和失败项。
- 不写服务器地址、用户名、密码、私钥、token、完整文件名列表或设备隐私路径。
- 每轮修改脚本、构建、安装、Native、ArkTS 页面或资源后，必须同步更新 `docs/FILES.md`、`docs/PROGRESS.md`、`docs/ISSUES.md` 或本文中的相关条目。
