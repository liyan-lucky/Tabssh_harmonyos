# OpenTabSsh / Tabssh_harmonyos

这是使用 **ArkTS + ArkUI + Native C++ N-API** 的 HarmonyOS 原生 SSH 客户端工程骨架。

- 工作区目录：`10_Tabssh_harmonyos`
- 应用名称：`OpenTabSsh`
- 实际 Bundle：`com.open.tabssh`
- 默认 Native 模块：`libentry.so`
- 当前目标：验证 Mock UI/N-API 链路，为真实 libssh2 Core 留出稳定接口。

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

## 构建与测试

禁止直接在仓库内留下构建产物。运行 `scripts\build_mock_hap.ps1`，脚本会把干净副本放到 `%VSCODE_ROOT%\99_Temp\harmonyos_stage\10_Tabssh_harmonyos` 后构建，并把最终产物复制到 `%VSCODE_ROOT%\99_Temp\harmonyos_build\10_Tabssh_harmonyos`。路径与清理白名单见 `docs/WORKSPACE_PATHS.md`。

## 重要说明

当前 Native 层默认是 Mock 模式。真实 SSH 必须接入 C/C++ 的 `libssh2` 或等价实现，而且不是简单替换一个源文件：还必须完成 HostKey、安全存储、非阻塞 I/O、终端解析、SFTP、转发、错误恢复和断开清理。不得用 Mock 成功冒充真实功能完成。

## 推荐开发顺序

1. 先确认 Mock 版本能构建运行。
2. 编译 `openssl + zlib + libssh2` 的 HarmonyOS 目标库。
3. 用 `scripts\build_real_hap.ps1` 在仓库外 stage 自动启用真实 Core。
4. 实现 password 登录。
5. 实现 shell channel 读写。
6. 实现 PTY resize。
7. 验证 HostKey 未知/变化阻断与显式确认（源码已编码，待真实证据）。
8. 实现 private key 登录。
9. 实现 SFTP。
10. 实现 local/remote/dynamic forwarding。
11. 再补跳板机、代理、tmux/screen/zellij 自动启动、多标签复用。
