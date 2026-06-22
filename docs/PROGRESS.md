# 功能进度

## 已实现（Mock 基线）

- HarmonyOS Stage 模型、`com.open.tabssh`、arm64-v8a/x86_64 配置。
- 首页、连接编辑、终端、SFTP、端口转发、设置、关于页面。
- Native N-API 接口与内存 Mock session/channel/forward。
- 内存连接配置仓库；示例配置不含密码。
- 统一文档、路径、清理、备份、审计和发布脚本规范。
- 单次静态基线审计 29/29；Mock unsigned HAP 构建成功并确认双 ABI native entries。
- Web/Android/Desktop 三份上游源码已在 `99_Temp\tabssh_reference` 建立浅克隆参考。

## 未实现（发布阻塞）

- 真实 libssh2/OpenSSL/zlib 双架构构建与加载。
- HostKey、密码/私钥认证和 HUKS/ASSET 安全存储。
- ANSI/VT/xterm 终端解析、渲染、键盘与滚动历史。
- 真实 SFTP 上传、下载、删除、重命名和校验。
- local/remote/dynamic forwarding 的真实流量链路。
- RDB 持久化、代理/跳板机、多标签复用、后台保持。
- 超时、重连、错误恢复和完整断开清理。
- arm64 真机与 x86_64 模拟器真实 SSH 端到端验收。
- 独立 HarmonyOS 签名配置与 signed HAP 安装验证。
