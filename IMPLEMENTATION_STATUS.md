# 当前实现状态（2026-06-22）

## 可以直接测试

- 导入 DevEco Studio（仓库外 stage）
- 构建 Mock entry 模块
- 启动 OpenTabSsh
- 首页查看示例连接
- 新建/编辑连接
- 打开 Terminal 页面
- Terminal 输入 mock 命令
- 打开 SFTP mock 列表
- 创建端口转发 mock 记录
- 查看 native version

## 尚未实现，不能标记完成

- 真正 SSH 网络连接
- libssh2/OpenSSL/zlib HarmonyOS so 编译
- HostKey 持久化
- 真实终端模拟器
- 真实 SFTP 上传下载
- 真实端口转发
- 本地数据库持久化与安全凭据存储
- 非阻塞 I/O、重连、超时和断开清理
- arm64 真机与 x86_64 模拟器的真实 SSH 端到端验证

## 验收规则

真实 SSH 完成前必须以实际服务器、真实终端输出、SFTP 文件校验、端口转发流量和断开后的资源清理为证据。每次重要修改执行一次完整基线审计、构建和相关设备功能检查；不得以 Mock 返回、页面存在或函数名存在代替端到端结果。
