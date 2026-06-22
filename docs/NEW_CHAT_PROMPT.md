# 新对话提示词

复制下面内容到新对话：

```text
继续 OpenTabSsh HarmonyOS 项目。项目根为 F:\Visual_Studio_Code\10_Tabssh_harmonyos。

先完整读取 docs\AGENT_HANDOFF.md，再严格按 docs\README.md 的必读顺序阅读全部项目资料；随后检查 git status、当前分支、远端同步状态和完整 diff，保留所有未提交修改，不得重置或覆盖用户工作。

所有构建、测试、日志、下载、备份和临时证据统一放在 F:\Visual_Studio_Code\99_Temp 的 TabSSH 专属子目录，严格遵守 docs\WORKSPACE_PATHS.md。99_Temp 是多项目共享目录，禁止整体清理，任何 APK 都不得删除，也不得触碰 RustDesk、TabSSH Android 或其他项目内容。

当前工程是 Mock SSH 骨架，绝不能把 Mock 返回、页面存在或函数名存在当作真实功能完成。优先贯通 libssh2/OpenSSL/zlib 双架构、HostKey 与密码/私钥安全、真实 shell/PTY 非阻塞读写、终端渲染、SFTP、local/remote/dynamic forwarding、重连、错误恢复和断开资源清理；随后在 arm64 真机与 x86_64 模拟器完成端到端验证。

上游参考源码位于 F:\Visual_Studio_Code\99_Temp\tabssh_reference：tabssh.github.io、android、desktop。先按 docs\UPSTREAM_REFERENCES.md 核对各仓库 origin 与 commit；只作行为、UI 和协议参考，不把它们当成本仓库子模块或构建输入，不修改其远端，不混用旧的 tabssh.github.io-main 目录。

密码、私钥、私钥口令、token 和服务器凭据只能在测试运行内存中使用，禁止写入源码、日志、文档、截图、备份说明或提交说明。所有未实现入口必须提示开发中或明确标注 Mock。

本项目不要求机械重复多轮审计。每次重要修改和最终发布前执行一次完整审计、全量构建、双设备安装与相关功能检查。功能、路径、构建、测试、清理或发布状态变化后立即同步文档。完成后精准清理项目专属可再生产物，保留全部 APK 和线上验证资产，生成最新备份，提交推送并下载复验线上 Release；全部非明确搁置需求完成前不要停止。
```
