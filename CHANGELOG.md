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
- 新增 GitHub 托管静态审计与受控 DevEco self-hosted 真实 HAP workflow。

### Changed

- Documented that the project is independent and not an official Huawei, HarmonyOS, OpenHarmony, OpenSSH, SSH, or libssh2 project.
- Documented that proprietary SDKs, signing materials, credentials, and third-party binaries must not be committed unless redistribution rights and notices are confirmed.
- Updated build configuration to support separate ABI artifacts.
- 明确当前版本是 Mock SSH 工程骨架，真实 SSH/SFTP/转发尚未完成。
- 统一 Bundle 文档为 `com.open.tabssh`。
- 构建和测试统一迁移到工作区共享 `99_Temp` 的项目专属子目录。
- 将 TabSSH Web、Android、Desktop 三份上游源码浅克隆到 `99_Temp\tabssh_reference` 供对照，不纳入本仓库。

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

## 0.1.0

### Added

- Initial TabSSH / OpenTabSsh HarmonyOS ArkTS + Native C++ project skeleton.
- UI structure for connection management, terminal placeholder, SFTP placeholder, settings, and about pages.
- Native N-API bridge structure.
- Explicit Mock native fallback when real SSH third-party libraries are absent.
