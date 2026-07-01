# 当前仓库状态

更新时间：2026-07-01

## 定位

`Tabssh_harmonyos` 是面向 HarmonyOS / OpenHarmony 的 OpenTabSsh 原生 SSH 客户端工程，使用 ArkTS / ArkUI 与 Native C++ N-API。当前仓库是可构建、可运行 UI 与 Mock Native Core 的工程骨架，不应被描述为真实 SSH 成品。

## 当前工程信息

- `oh-package.json5`：`modelVersion` 为 `6.1.1`，工程名为 `10_tabssh_harmonyos`，版本字段为 `0.1.0`。
- 技术栈：HarmonyOS ArkTS / ArkUI + Native C++ N-API。
- 许可证：MIT。

## 当前能力边界

- 已有：首页、连接编辑、明确标识的 Mock fallback、基础 ANSI/VT 网格、SFTP/转发占位、设置和关于页面。
- 已编码待验证：固定版本双架构依赖脚本、真实 libssh2 Core、HostKey 阻断/确认、密码/私钥认证、PTY shell 与 SFTP list。
- 未完成：真实依赖/HAP 端到端证据、完整 xterm、SFTP 写操作、三类转发、持久化、HUKS/ASSET、重连和 Android 全功能矩阵。
- 凭据只能在测试运行内存中使用，禁止写入源码、日志、文档、截图、备份说明或提交说明。

## 当前分支和备份

- `main`：当前主工作分支。
- `backup`：`main` 的快照备份分支。
- `.github/workflows/force-backup-main.yml`：手动输入 `YES` 后，把 `main` 当前提交强制覆盖到 `backup`。

## 文档入口

- `docs/AGENT_HANDOFF.md`：当前事实、边界和第一执行序列。
- `docs/README.md`：文档阅读顺序。
- `docs/WORKSPACE_PATHS.md`：唯一允许的构建、测试、日志、备份和清理路径。
- `docs/PROGRESS.md`：已实现与未实现功能。
- `docs/ANDROID_TO_HARMONY_MAPPING.md`：Android 版能力矩阵和当前 HarmonyOS 对齐状态。
- `docs/CORE.md`：Mock / 真实 Native Core 架构和安全要求。

## 合规边界

- 不提交私钥、签名证书、SDK 压缩包、专有 SDK 文件、凭据、token、包含敏感信息的设备日志或用户连接信息。
- 不宣称未完成或未端到端验证的真实 SSH、SFTP、转发、持久化或安全存储能力已经完成。
- HarmonyOS、OpenHarmony、Huawei、SSH、OpenSSH、libssh2 等名称仅用于兼容、构建或平台识别。

任何功能、路径、构建、测试或发布状态变化，都必须同步更新本文件、根 README 和相关专项文档。真实功能只能以端到端证据标记完成。
