# 已知问题与风险

## P0：真实 SSH Core 未接入

当前 CMake 编译 `native_ssh_mock.cpp`。任何连接、SFTP、转发结果都是 Mock，不具备生产用途。

## P0：凭据与 HostKey 安全

密码、私钥和口令不能进入源码或普通首选项。真实实现前必须设计 HostKey 信任/变更警告与 HUKS/ASSET 安全存储。初始源码中的示例密码已移除。

## P1：文档与配置曾不一致

旧 README 写 `io.github.opentabssh`，实际 `build-profile.json5` 与 `AppScope/app.json5` 均为 `com.open.tabssh`；现已统一，以构建配置为准。

## P1：仓库内生成产物

初始目录含 build、`.cxx`、Hvigor/IDE/AI 缓存和崩溃转储。首次提交前按 `WORKSPACE_PATHS.md` 清理，后续只能在 `99_Temp` stage 构建。

## P1：签名尚未配置

当前基线产物是 unsigned HAP，已验证双 ABI 包内容但不能作为安装/发布证据。后续应为 `com.open.tabssh` 配置独立签名材料，存放在 `99_Temp` 的项目专属目录并保持 Git 忽略；不得复用或提交其他项目的签名口令。

用户曾通过 DevEco Studio 构建，但当前仓库配置没有可提交的签名项；这属于正确状态。首次提交扫描未发现证书、私钥或签名口令，未来也必须保持如此。
