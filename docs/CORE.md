# Native Core 架构

## 当前链路

`ArkTS 页面 → NativeSshCore.ets → libentry.so N-API → native_ssh_mock.cpp`

Mock Core 用于验证页面、路由、N-API 参数和会话生命周期，不进行网络 SSH。现有函数包括 session、shell、read/write/resize、SFTP 列表和三类转发接口。

## 真实 Core 目标

真实实现使用 `native_ssh_libssh2.cpp`，依赖 HarmonyOS 双架构的 libssh2、OpenSSL 和 zlib。依赖源码、build、日志和二进制统一放在 `99_Temp\tabssh_harmonyos_dependencies`；仓库仅保留可复现脚本、补丁、头文件接口与许可证，不提交机器生成的 `.so`。

实现必须覆盖：非阻塞 socket/I/O、超时和取消、HostKey 首次信任及变更警告、密码与私钥认证、安全存储、PTY resize、断线/重连、channel/session/forward 资源释放。SFTP 与转发必须用真实文件哈希和流量证明，不以函数返回 `ok` 作为完成证据。

行为对照优先读取 `99_Temp\tabssh_reference\android` 的会话、终端、SFTP 和转发实现；桌面交互对照 `desktop`，官网功能说明对照 `tabssh.github.io`。参考源码不得直接复制二进制、凭据或不兼容许可证内容，移植时记录来源和改写范围。
