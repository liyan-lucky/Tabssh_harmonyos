# OpenTabSsh / Tabssh_harmonyos

这是使用 **ArkTS + ArkUI + Native C++ N-API** 的 HarmonyOS 原生 SSH 客户端工程骨架。

- 工作区目录：`10_Tabssh_harmonyos`
- 应用名称：`OpenTabSsh`
- 实际 Bundle：`com.open.tabssh`
- 默认 Native 模块：`libentry.so`
- 当前目标：先保留可构建 Mock fallback，再逐步验证真实 libssh2 Core。

## 这个包现在包含什么

1. ArkTS/ArkUI 页面：
   - 首页连接列表
   - 新建/编辑连接
   - Terminal 页面
   - SFTP 页面
   - 端口转发页面
   - 设置/关于页面

2. Native C++ N-API：
   - `version()`
   - `createSession()`
   - `connect()` / `confirmHostKey()`
   - `openShell()`
   - `write()`
   - `read()`
   - `resize()`
   - `closeChannel()`
   - `disconnect()`
   - `sftpList()`
   - `sftpUpload()` / `sftpDownload()`
   - `sftpMkdir()` / `sftpRemove()` / `sftpRename()` / `sftpChmod()`
   - `addLocalForward()`
   - `addRemoteForward()`
   - `addDynamicForward()`
   - `removeForward()`

3. 默认 Mock SSH Core：
   - 不依赖 libssh2，可以先直接构建测试。
   - Terminal 页面输入 `pwd`、`whoami`、`ls`、`echo xxx` 会得到 mock 输出。
   - SFTP 明示 Mock；端口转发不会再显示 Mock 成功。

4. 真实 libssh2 接入文件和说明：
   - `entry/src/main/cpp/native_ssh_libssh2.cpp`
   - `docs/LIBSSH2_COMPILE_GUIDE.md`
   - `docs/NATIVE_CORE_FUNCTIONS.md`
   - `docs/IMPLEMENTATION_STEPS.md`
   - `docs/PULL_TEST_GUIDE.md`

## 构建与测试

禁止直接在仓库内留下构建产物。先读 `docs/PULL_TEST_GUIDE.md`：

- Mock fallback：运行 `scripts\audit_project.ps1`、`scripts\build_mock_hap.ps1`、`scripts\verify_mock_hap.ps1`。
- 真实 Core：先运行 `scripts\build_native_dependencies.ps1`，再运行 `scripts\build_real_hap.ps1`、`scripts\verify_real_hap.ps1`。
- 所有 stage、依赖、日志和最终 HAP 必须进入 `%VSCODE_ROOT%\99_Temp` 的项目专属路径。

## 重要说明

源码 checkout 缺少三方依赖时默认走 Mock。真实 SSH 必须接入 C/C++ 的 `libssh2` 或等价实现，而且不是简单替换一个源文件：还必须完成 HostKey、安全存储、非阻塞 I/O、终端解析、SFTP、转发、错误恢复和断开清理。不得用 Mock 成功、源码存在或验包 marker 冒充真实功能完成。

## 推荐开发顺序

1. 先确认 Mock 版本能构建运行。
2. 编译 `openssl + zlib + libssh2` 的 HarmonyOS 目标库。
3. 用 `scripts\build_real_hap.ps1` 在仓库外 stage 自动启用真实 Core。
4. 验证 HostKey 未知/变化阻断与显式确认。
5. 验证 password 登录、shell channel 读写、PTY resize 和断开清理。
6. 验证 private key 登录。
7. 验证 SFTP list、上传、下载、删除、重命名、chmod 和大文件路径。
8. 验证 local/remote/dynamic forwarding 的真实流量。
9. 再补跳板机、代理、tmux/screen/zellij 自动启动、多标签复用、后台保持、云/虚拟化/VNC。
