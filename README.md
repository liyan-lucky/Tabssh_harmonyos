# Tabssh_harmonyos

OpenTabSsh 是面向 HarmonyOS 的原生 SSH 客户端工程，使用 ArkTS/ArkUI 与 Native C++ N-API。当前版本是可构建、可运行 UI 与 Mock Native Core 的工程骨架，不应被描述为真实 SSH 成品。

## 当前边界

- 已有：首页、连接编辑、Mock 终端、Mock SFTP、Mock 本地转发、设置和关于页面。
- 已有：arm64-v8a/x86_64 Native C++ 构建配置与 14 个 N-API 接口。
- 未完成：libssh2/OpenSSL/zlib、真实认证和 HostKey、终端模拟器、真实 SFTP、端口转发、持久化、密钥安全与完整会话清理。
- 凭据只能在测试运行内存中使用，禁止写入源码、日志、文档、截图、备份说明或提交说明。

2026-06-22 Mock 基线已在 `99_Temp` 成功构建：unsigned HAP `3,048,665` bytes，SHA256 `49CDE90FDD94C0623FF7A65107C112E519C9B732DA0842FC40288D6386471829`，包内含 arm64-v8a/x86_64 的 `libentry.so` 与 `libc++_shared.so`。该结果只证明工程和 Mock Native 双 ABI 可编译。

## 接手入口

新对话先完整读取 [AGENT_HANDOFF.md](docs/AGENT_HANDOFF.md)，再按 [文档索引](docs/README.md) 的必读顺序继续。所有构建、测试、日志、下载、备份和临时证据统一放在工作区共享的 `99_Temp`，详细职责见 [WORKSPACE_PATHS.md](docs/WORKSPACE_PATHS.md)。`99_Temp` 属于多个项目，禁止整体清空，任何 APK 一律不得删除。

中文项目说明见 [README_zh.md](README_zh.md)。
