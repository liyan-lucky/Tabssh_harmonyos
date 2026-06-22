# 当前实现状态（2026-06-22）

## 可以直接测试

- 导入 DevEco Studio（仓库外 stage）
- 构建 Mock entry 模块
- 启动 OpenTabSsh
- 首页查看示例连接
- 新建/编辑连接
- 打开 Terminal 页面
- Terminal 输入 mock 命令
- 打开 SFTP mock 列表（明确标识）
- 查看端口转发开发中提示（不会创建 Mock 成功记录）
- 查看 native version
- 在 x86_64 模拟器验证基础 ANSI/VT 网格和 Mock `pwd` 输出

## 已编码、尚不能标记完成

- 双架构固定依赖构建/manifest/真实 HAP 脚本
- libssh2 非阻塞握手、HostKey、密码/私钥认证、PTY、SFTP list、清理
- HostKey 首次信任与变化警告 UI
- 基础 ANSI/VT 网格和控制键（不是完整 xterm）
- `connect`、`openShell`、`sftpList` N-API async work / Promise（已构建，尚待设备回归）

## 尚未实现，不能标记完成

- HostKey/认证/PTY 的真实服务器成功证据
- HostKey 持久化
- 真实终端模拟器
- 真实 SFTP 上传下载
- 真实端口转发
- 本地数据库持久化与安全凭据存储
- write/resize/close/disconnect 异步化、真实服务器证据、异步取消、重连和全部断开清理路径
- arm64 真机与 x86_64 模拟器的真实 SSH 端到端验证

## 验收规则

真实 SSH 完成前必须以实际服务器、真实终端输出、SFTP 文件校验、端口转发流量和断开后的资源清理为证据。每次重要修改执行一次完整基线审计、构建和相关设备功能检查；不得以 Mock 返回、页面存在或函数名存在代替端到端结果。
