# Changelog

## Unreleased

- 建立统一的接力、路径、构建测试、清理、备份、审计和 GitHub 发布规范。
- 明确当前版本是 Mock SSH 工程骨架，真实 SSH/SFTP/转发尚未完成。
- 统一 Bundle 文档为 `com.open.tabssh`。
- 移除源码中的示例密码，凭据仅允许在测试运行内存中使用。
- 构建和测试统一迁移到工作区共享 `99_Temp` 的项目专属子目录。
- Mock unsigned HAP 已通过仓库外构建并验证双 ABI native entries。
- 将 TabSSH Web、Android、Desktop 三份上游源码浅克隆到 `99_Temp\tabssh_reference` 供对照，不纳入本仓库。
