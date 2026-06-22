# Native Core 架构

## 当前链路

普通源码 checkout：`ArkTS 页面 → NativeSshCore.ets → libentry.so N-API → native_ssh_mock.cpp`。

真实 stage（依赖 manifest 与当前 ABI 文件全部通过校验后）：`ArkTS → N-API → native_ssh_libssh2.cpp → 静态 libssh2/OpenSSL/zlib`。

Mock Core 用于验证页面、路由、N-API 参数和会话生命周期，不进行网络 SSH。现有函数包括 session、shell、read/write/resize、SFTP 列表和三类转发接口。

## 真实 Core 已编码部分（待端到端验证）

`native_ssh_libssh2.cpp` 已编码非阻塞 TCP/handshake、超时、SHA256 HostKey 未知/变更阻断、显式确认、密码/文件私钥认证、PTY shell、read/write/resize、SFTP list 和断开清理。它已通过 arm64-v8a/x86_64 OHOS 目标语法编译，但尚未链接成真实 HAP或连接真实服务器，因此不计作完成功能。

仍必须覆盖：异步 N-API/取消、HUKS/ASSET、完整 xterm、SFTP 写操作与哈希、三类转发、断线重连、forward/SFTP 全路径资源释放。SFTP 与转发必须用真实文件哈希和流量证明，不以函数返回 `ok` 作为完成证据。

行为对照优先读取 `99_Temp\tabssh_reference\android` 的会话、终端、SFTP 和转发实现；桌面交互对照 `desktop`，官网功能说明对照 `tabssh.github.io`。参考源码不得直接复制二进制、凭据或不兼容许可证内容，移植时记录来源和改写范围。
