# 当前任务交接入口

> 建立时间：2026-06-22（Europe/Berlin）

## 当前事实

项目根为 `%VSCODE_ROOT%\10_Tabssh_harmonyos`，GitHub 目标为 `https://github.com/liyan-lucky/Tabssh_harmonyos.git`，默认分支 `main`。实际应用 Bundle 为 `com.open.tabssh`，版本 `0.1.0 / 1`，Native 模块为 `libentry.so`，ABI 配置为 arm64-v8a 与 x86_64。

默认无三方库的构建仍是 `native_ssh_mock.cpp`。固定版本 libssh2/OpenSSL/zlib 双架构静态库与 manifest 已构建，真实 Core HAP 已完成双 ABI 验包并在 x86_64 模拟器加载冷启动；但真实 HostKey/认证/shell/SFTP 尚未取得服务器端到端证据。完整终端模拟器、SFTP 写操作、三类转发、持久化、HUKS/ASSET、重连等仍未完成。禁止把源码存在、加载成功、Mock 行为或函数返回写成真实 SSH 已完成。

2026-06-22 02:34 重要修改回归：静态审计 34 PASS / 0 FAIL；仓库外 Mock fallback HAP 为 `3,099,325` bytes / SHA256 `1CF2D83204AE61D10B08C1C003D9C90CE0E78807A59C7CB885F1A4C2D7C478AB`，双 ABI native entries 通过验证。该包成功覆盖安装并冷启动于 `127.0.0.1:5555` x86_64 模拟器，`updateTime=1782092052465`、PID `21653`、安全筛选异常日志 0 行。模拟器接受的是 `debug / appSignType=none` 包；这不是正式签名或真实 SSH 验收。

2026-06-22 06:55 真实 Core HAP 为 `11,566,708` bytes / SHA256 `6E47A6C7FAB84214210D959F7CFE3088BCF937B7E90E56F9A65B7536429F6A4E`，双 ABI real marker/machine 通过且不含 Mock marker；成功安装并冷启动于 x86_64 模拟器，`updateTime=1782107735827`、PID `27063`、加载/崩溃筛选日志 0 行。仍需真实 SSH 端到端证据。

2026-06-22 07:05 私钥文件选择/沙箱导入和窗口隐私保护修改后的真实 Core HAP 为 `11,578,032` bytes / SHA256 `A38EFE5FD4C6B67096412BEDBCF04A057EC76ADA55A0BCC9931F0BA12EB24EB7`，双 ABI real marker/machine 复验通过，并成功覆盖安装于 x86_64 模拟器，`updateTime=1782108374943`。尚未把安装成功写成 SSH 功能完成；下一步是文件选择、HostKey、认证、PTY 和 SFTP 真实流量验证。

2026-06-22 07:13 修复编辑页返回后连接列表未刷新的生命周期缺陷；真实 HAP `11,578,318` bytes / SHA256 `9D7C75BC498547463EBEF319FE1A06F8505F758B84A065A5C5386704CCDB9DB3` 已通过双 ABI 验包并覆盖安装，`updateTime=1782108829995`。私钥系统选择器已确认能打开；仍需完成真实服务器 HostKey/认证/PTY/SFTP 流量验证。

2026-06-22 07:20 真实连接触发系统 `APP_INPUT_BLOCK`，故障栈证明同步 N-API `opentabssh::Connect` 阻塞 ArkUI 主线程，进程被系统终止；没有取得 HostKey/认证成功证据。随后已将 `connect`、`openShell`、`sftpList` 改为 N-API async work / Promise，并同步调整 Terminal/SFTP 状态机。暂停前 Mock 构建通过；最新真实 HAP 为 `11,587,958` bytes / SHA256 `4C6FDDBCF104BC926C2870D1BFB5AEEDD5AB476C26CB34294477EC64880E7A80`，双 ABI 验包通过，但因用户要求关机暂停，尚未安装或回归。恢复后第一步应安装该哈希并重测 HostKey，再继续认证/PTY/SFTP；不得把“异步源码已编译”写成问题已在设备解决。

用户曾在 DevEco Studio 构建过，但签名信息属于本机私有配置。首次提交前已扫描项目和暂存区：没有证书、密钥文件或签名口令；`build-profile.json5` 的 `signingConfigs` 为空。`.idea`、`signing/` 与常见证书/密钥扩展名全部 Git 忽略，后续不得把 DevEco 生成的签名材料带入仓库。

三份上游参考源码已浅克隆到 `%VSCODE_ROOT%\99_Temp\tabssh_reference`：Web `54298277...`、Android `0c455b8b...`、Desktop `79123c85...`。它们只用于行为/UI/协议对照，不是本仓库子模块或构建输入，详见 `UPSTREAM_REFERENCES.md`。

## 第一执行序列

1. 完整读取本文件，再按 `docs/README.md` 顺序阅读。
2. 执行 `git status --short --branch` 和完整 diff，保留用户所有未提交修改。
3. 执行 `scripts/audit_project.ps1`，再用 `scripts/build_mock_hap.ps1` 在 `99_Temp` stage 中验证基线。
4. 真实功能优先级：libssh2 双架构 → HostKey/认证安全 → shell/PTY 非阻塞读写 → 终端渲染 → SFTP → local/remote/dynamic forwarding → 重连与断开清理。
5. 每次重要修改和最终发布前各运行一次完整审计、构建、安装与相关功能检查，并立即同步所有相关文档。

## 安全与清理硬规则

- 密码、私钥、私钥口令、token 和服务器凭据只允许存在测试运行内存，禁止写入源码、日志、文档、截图、备份说明或提交说明。
- `%VSCODE_ROOT%\99_Temp` 是多项目共享目录，禁止整体删除、移动或按扩展名全局清理；任何 APK 一律不得删除。
- 只能清理 `docs/WORKSPACE_PATHS.md` 列明且明确归属本项目的可再生目录。
- 不在仓库根保留 `.hvigor`、`.cxx`、build、崩溃转储、IDE/AI 工具缓存或散落日志。
