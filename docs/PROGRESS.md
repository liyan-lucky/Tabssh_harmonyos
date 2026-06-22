# 功能进度

## 已实现（Mock 基线）

- HarmonyOS Stage 模型、`com.open.tabssh`、arm64-v8a/x86_64 配置。
- 首页、连接编辑、终端、SFTP、端口转发、设置、关于页面。
- Native N-API 接口与内存 Mock session/channel/forward。
- 内存连接配置仓库；示例配置不含密码。
- 统一文档、路径、清理、备份、审计和发布脚本规范。
- 单次静态基线审计 29/29；Mock unsigned HAP 构建成功并确认双 ABI native entries。
- Web/Android/Desktop 三份上游源码已在 `99_Temp\tabssh_reference` 建立浅克隆参考。
- Mock fallback 新契约已完成 x86_64 模拟器覆盖安装和冷启动验证；证据见 `BUILD_TEST.md`。

## 已编码、待真实构建与端到端验证

- 固定 libssh2 `1.11.1`、OpenSSL `3.5.7 LTS`、zlib `1.3.2` 的双架构依赖已构建并生成 SHA/commit manifest；真实 HAP 已通过双 ABI marker/machine 验证和 x86_64 加载冷启动。
- 真实 Core 的非阻塞握手、HostKey SHA256 阻断/确认、密码/私钥认证、PTY shell、读写/resize、SFTP 列目录和断开清理源码。
- CMake 根据 stage 中经过清单校验的静态库自动切换真实 Core；源码 checkout 继续明确回退 Mock。
- ArkTS 首次 HostKey/变更警告流程；凭据仅保留在运行内存，Mock 不再保存 profile JSON。
- 私钥通过系统文档选择器复制到应用私有 `filesDir/ssh_keys`，不记录原文件 URI 或内容，并提供应用内删除入口；真实包已在 x86_64 模拟器覆盖安装，端到端认证待验。
- 模拟器已验证系统文档选择器 UI 可打开；同时发现并修复连接编辑返回后的列表刷新问题。
- 首次真实连接发现同步 N-API 导致 `APP_INPUT_BLOCK`；`connect`、`openShell`、`sftpList` 已迁移为 async work / Promise 并完成 Mock/真实双架构构建，尚待安装回归。
- 有界 2,000 行历史的基础 ANSI/VT 字符网格、120 ms 输出轮询和 Ctrl-C/Ctrl-D/Esc/Tab/方向键入口；尚不是完整 xterm 兼容终端。

以上网络能力仍没有真实服务器证据，暂不计入“真实功能已实现”。

## 未实现（发布阻塞）

- HostKey/密码/私钥认证端到端证据；HUKS/ASSET 安全存储。
- ANSI/VT/xterm 终端解析、渲染、键盘与滚动历史。
- 真实 SFTP 上传、下载、删除、重命名和校验。
- local/remote/dynamic forwarding 的真实流量链路。
- RDB 持久化、代理/跳板机、多标签复用、后台保持。
- write/resize/close/disconnect 的异步化、取消、超时、重连、错误恢复和完整断开清理。
- arm64 真机与 x86_64 模拟器真实 SSH 端到端验收。
- 独立 HarmonyOS 签名配置与 signed HAP 安装验证。
