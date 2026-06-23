# 已知问题与风险

## P0：真实 SSH 端到端尚未通过

源码 checkout 没有生成的三方静态库时，CMake 明确编译 `native_ssh_mock.cpp`。固定三方库和真实 Core 双 ABI HAP 已完成构建、链接、验包和 x86_64 冷启动，密码认证/PTY/SFTP 已有端到端证据；私钥、arm64 真机和端口转发仍阻塞生产使用。端口转发 UI 已禁用 Mock 成功提示。

2026-06-22 首次真实连接暴露同步 N-API 主线程卡死，系统以 `APP_INPUT_BLOCK` 终止进程。现有网络与 SFTP 操作均已迁移到后台 async work，x86_64 模拟器没有新增 faultlogger 记录；用户取消正在进行的 native async work 仍需实现。

read/write/resize/close/disconnect 现也已迁移到 async work，并在外部 Windows OpenSSH 完成命令、SFTP、关闭和再次连接回归；已知旧 appfreeze 没有复现。尚未实现用户取消正在进行的 native async work，极端慢服务器下的任务终止仍是风险。

2026-06-22 SFTP 系统文档选择器的“保存”界面在当前 x86_64 自动化模拟器上出现 Promise 未返回且界面未显示；已通过应用私有缓存中的受限文本上传→下载回读完成核心数据校验，但系统保存选择器还需真机手工验证和取消/超时处理。

## P0：凭据与 HostKey 安全

密码、私钥和口令不能进入源码或普通首选项。HostKey 首次信任/变更警告已编码；私钥文件可导入应用私有目录并删除，但长期凭据仍需 HUKS/ASSET 安全存储。初始源码中的示例密码已移除。

## P1：文档与配置曾不一致

旧 README 写 `io.github.opentabssh`，实际 `build-profile.json5` 与 `AppScope/app.json5` 均为 `com.open.tabssh`；现已统一，以构建配置为准。

## P1：仓库内生成产物

初始目录含 build、`.cxx`、Hvigor/IDE/AI 缓存和崩溃转储。首次提交前按 `WORKSPACE_PATHS.md` 清理，后续只能在 `99_Temp` stage 构建。

## P1：签名尚未配置

当前基线产物是 unsigned HAP，已验证双 ABI 包内容但不能作为安装/发布证据。后续应为 `com.open.tabssh` 配置独立签名材料，存放在 `99_Temp` 的项目专属目录并保持 Git 忽略；不得复用或提交其他项目的签名口令。

用户曾通过 DevEco Studio 构建，但当前仓库配置没有可提交的签名项；这属于正确状态。首次提交扫描未发现证书、私钥或签名口令，未来也必须保持如此。

2026-06-22 x86_64 模拟器接受并安装了 `appProvisionType=debug / appSignType=none` 的 Mock fallback HAP；这不改变正式发布需要独立签名的要求，也不能外推到 arm64 真机。
