# Tabssh_harmonyos

OpenTabSsh 是面向 HarmonyOS / OpenHarmony 的原生 SSH 客户端工程，使用 ArkTS/ArkUI 与 Native C++ N-API。当前版本是可构建、可运行 UI 与 Mock Native Core 的工程骨架，不应被描述为真实 SSH 成品。

## 当前状态

当前事实以 [CURRENT_STATUS.md](docs/CURRENT_STATUS.md) 为准。

## 当前边界

- 已有：首页、连接编辑、明确标识的 Mock fallback、基础 ANSI/VT 网格、SFTP/转发占位、设置和关于页面。
- 已编码待验证：固定版本双架构依赖脚本、真实 libssh2 Core、HostKey 阻断/确认、密码/私钥认证、PTY shell 与 SFTP list。
- 未完成：真实依赖/HAP 端到端证据、完整 xterm、SFTP 写操作、三类转发、持久化、HUKS/ASSET、重连和 Android 全功能矩阵。
- 凭据只能在测试运行内存中使用，禁止写入源码、日志、文档、截图、备份说明或提交说明。

2026-06-22 02:34 Mock fallback 在 `99_Temp` 构建并覆盖安装到 x86_64 模拟器：unsigned HAP `3,099,325` bytes，SHA256 `1CF2D83204AE61D10B08C1C003D9C90CE0E78807A59C7CB885F1A4C2D7C478AB`，双 ABI native entries 通过验证。该结果只证明 Mock fallback 的编译、安装、冷启动和无凭据 UI 冒烟。

## 接手入口

新对话先完整读取 [CURRENT_STATUS.md](docs/CURRENT_STATUS.md) 和 [AGENT_HANDOFF.md](docs/AGENT_HANDOFF.md)，再按 [文档索引](docs/README.md) 的必读顺序继续。所有构建、测试、日志、下载、备份和临时证据统一放在工作区共享的 `99_Temp`，详细职责见 [WORKSPACE_PATHS.md](docs/WORKSPACE_PATHS.md)。`99_Temp` 属于多个项目，禁止整体清空，任何 APK 一律不得删除。

中文项目说明见 [README_zh.md](README_zh.md)。

## 分支和备份

- `main`：当前主工作分支。
- `backup`：`main` 的快照备份分支。
- `.github/workflows/force-backup-main.yml`：手动输入 `YES` 后，把 `main` 当前提交强制覆盖到 `backup`。

## Project Governance

- [License](LICENSE)
- [Notice](NOTICE)
- [Third-party notices](THIRD_PARTY_NOTICES.md)
- [Security policy](SECURITY.md)
- [Contributing guide](CONTRIBUTING.md)
- [Code of conduct](CODE_OF_CONDUCT.md)
- [Support policy](SUPPORT.md)
- [Changelog](CHANGELOG.md)
- [Legal and compliance notes](docs/LEGAL.md)
- [Release checklist](docs/RELEASE_CHECKLIST.md)

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

Third-party components, SDKs, tools, and dependencies remain under their respective licenses. Their notices should be reviewed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) once the dependency audit is completed.

## Legal Notice

TabSSH/OpenTabSsh is an independent open source project. It is not an official Huawei, HarmonyOS, OpenHarmony, OpenAtom Foundation, SSH, OpenSSH, or libssh2 product.

HarmonyOS, OpenHarmony, Huawei, and other names may be trademarks of their respective owners. Their use in this repository is only for compatibility, build, or platform identification.

Do not commit private keys, signing certificates, SDK archives, proprietary SDK files, credentials, tokens, device logs containing secrets, or user connection information to this repository.
