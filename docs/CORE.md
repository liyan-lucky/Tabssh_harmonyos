# Native Core 架构

## 当前链路

普通源码 checkout：`ArkTS 页面 → NativeSshCore.ets → libentry.so N-API → native_ssh_mock.cpp`。

真实 stage（依赖 manifest 与当前 ABI 文件全部通过校验后）：`ArkTS → N-API → native_ssh_libssh2.cpp → 静态 libssh2/OpenSSL/zlib`。

Mock Core 用于验证页面、路由、N-API 参数和会话生命周期，不进行网络 SSH。现有函数包括 session、shell、read/write/resize、SFTP 列表和三类转发接口。

## 真实 Core 已编码部分（待端到端验证）

`native_ssh_libssh2.cpp` 的基线已完成双 ABI 真实 HAP 链接，并取得外部服务器 HostKey、密码认证、PTY/命令、SFTP 列目和隔离回环 SFTP 写操作证据。当前未提交增量又加入三类转发、keepalive、EOF/重连配合与 SFTP 大文件空闲超时修正，虽然通过 arm64-v8a/x86_64 OHOS 目标语法编译，但尚未重新链接、安装和完成对应流量验证；旧 HAP 不能代表这些修改。

仍必须覆盖：异步 N-API 取消、HUKS/ASSET、完整 xterm、SFTP 大文件/取消/中断恢复、三类转发真实流量、断线重连设备证据以及 forward/SFTP 全路径压力清理。SFTP 与转发必须用真实文件哈希和流量证明，不以函数返回 `ok` 或源码存在作为完成证据。

端口转发实现采用每条规则一个监听 worker、每个连接一个数据泵；所有 libssh2 session 调用继续由 native mutex 串行化。本地 `-L` 和 SOCKS5 `-D` 强制绑定 `127.0.0.1`，远程 `-R` 请求服务器回环监听。`Disconnect` 先标记 session 正在断开，再停止/等待全部 forward worker 和 channel，之后才释放 libssh2 session。

终端轮询会调用 libssh2 keepalive，并区分正常 EOF 与传输错误；自动重连只对“曾成功建立”的会话启用，5 秒指数退避至 5 分钟上限。HarmonyOS `NetConnection`/`hasDefaultNet` 在离线时暂停定时器、网络恢复时立即唤醒，并每 5 分钟兜底核对。每次重连先关闭旧 channel、断开旧 session（同步触发 forward 清理），再从仅驻留运行内存的 profile 创建新 session，并重新执行 HostKey/认证/PTY 流程。HostKey 变化、认证失败、无效配置和正常 shell 退出不得进入自动循环。

ArkTS 终端状态机已从纯字符网格扩展为带单元格属性的 VT 解析器：支持常用光标/擦除/插删/滚动区、SGR 16 色/256 色/RGB、备用屏、宽字符/组合字符、OSC 标题、DSR/DA 回复、application cursor、bracketed paste 和 PTY 尺寸同步。TerminalPage 使用 `Span` 呈现前景色、背景色、粗体、斜体、下划线和删除线，并开放系统文本复制。解析器内存测试已通过；完整 HAP 编译、输入法逐键交互、vim/tmux/htop、选择/搜索和设备性能仍须验证，不能标为完整 xterm。

行为对照优先读取 `99_Temp\tabssh_reference\android` 的会话、终端、SFTP 和转发实现；桌面交互对照 `desktop`，官网功能说明对照 `tabssh.github.io`。参考源码不得直接复制二进制、凭据或不兼容许可证内容，移植时记录来源和改写范围。
