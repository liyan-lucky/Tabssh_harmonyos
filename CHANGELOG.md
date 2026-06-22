# Changelog

## Unreleased

- 建立统一的接力、路径、构建测试、清理、备份、审计和 GitHub 发布规范。
- 明确当前版本是 Mock SSH 工程骨架，真实 SSH/SFTP/转发尚未完成。
- 统一 Bundle 文档为 `com.open.tabssh`。
- 移除源码中的示例密码，凭据仅允许在测试运行内存中使用。
- 构建和测试统一迁移到工作区共享 `99_Temp` 的项目专属子目录。
- Mock unsigned HAP 已通过仓库外构建并验证双 ABI native entries。
- 将 TabSSH Web、Android、Desktop 三份上游源码浅克隆到 `99_Temp\tabssh_reference` 供对照，不纳入本仓库。
- 新增固定版本双 ABI zlib/OpenSSL/libssh2 构建、真实 HAP stage 和 real-marker 验包脚本。
- 编码 libssh2 非阻塞握手、HostKey SHA256 阻断/确认、密码/私钥认证、PTY、SFTP list 和断开清理；尚待真实构建与端到端验证。
- 新增基础 ANSI/VT 网格、输出轮询和控制键；端口转发不再呈现 Mock 成功。
- 新增 GitHub 托管静态审计与受控 DevEco self-hosted 真实 HAP workflow。
- Mock fallback 已在 x86_64 模拟器覆盖安装、冷启动并完成无凭据 UI hierarchy 冒烟。
- 真实连接测试定位到同步 N-API 导致的 ArkUI `APP_INPUT_BLOCK`；将 connect/openShell/SFTP list 迁移到 async work / Promise，并修复连接编辑返回后的列表刷新。
