# 当前任务交接入口

> 建立时间：2026-06-22（Europe/Berlin）

## 当前事实

项目根为 `%VSCODE_ROOT%\10_Tabssh_harmonyos`，GitHub 目标为 `https://github.com/liyan-lucky/Tabssh_harmonyos.git`，默认分支 `main`。实际应用 Bundle 为 `com.open.tabssh`，版本 `0.1.0 / 1`，Native 模块为 `libentry.so`，ABI 配置为 arm64-v8a 与 x86_64。

默认无三方库的构建仍是 `native_ssh_mock.cpp`。固定版本 libssh2/OpenSSL/zlib 双架构静态库与 manifest 已构建，真实 Core HAP 已完成双 ABI 验包并在 x86_64 模拟器加载；HostKey/密码认证/PTY/命令/SFTP 列目已有外部服务器证据，SFTP 写操作已有隔离回环端证据。完整 xterm、三类转发、持久化、HUKS/ASSET、重连、私钥与 arm64 真机仍未完成。禁止把源码存在、加载成功、Mock 行为或函数返回写成真实 SSH 已完成。

2026-06-22 02:34 重要修改回归：静态审计 34 PASS / 0 FAIL；仓库外 Mock fallback HAP 为 `3,099,325` bytes / SHA256 `1CF2D83204AE61D10B08C1C003D9C90CE0E78807A59C7CB885F1A4C2D7C478AB`，双 ABI native entries 通过验证。该包成功覆盖安装并冷启动于 `127.0.0.1:5555` x86_64 模拟器，`updateTime=1782092052465`、PID `21653`、安全筛选异常日志 0 行。模拟器接受的是 `debug / appSignType=none` 包；这不是正式签名或真实 SSH 验收。

2026-06-22 06:55 真实 Core HAP 为 `11,566,708` bytes / SHA256 `6E47A6C7FAB84214210D959F7CFE3088BCF937B7E90E56F9A65B7536429F6A4E`，双 ABI real marker/machine 通过且不含 Mock marker；成功安装并冷启动于 x86_64 模拟器，`updateTime=1782107735827`、PID `27063`、加载/崩溃筛选日志 0 行。仍需真实 SSH 端到端证据。

2026-06-22 07:05 私钥文件选择/沙箱导入和窗口隐私保护修改后的真实 Core HAP 为 `11,578,032` bytes / SHA256 `A38EFE5FD4C6B67096412BEDBCF04A057EC76ADA55A0BCC9931F0BA12EB24EB7`，双 ABI real marker/machine 复验通过，并成功覆盖安装于 x86_64 模拟器，`updateTime=1782108374943`。尚未把安装成功写成 SSH 功能完成；下一步是文件选择、HostKey、认证、PTY 和 SFTP 真实流量验证。

2026-06-22 07:13 修复编辑页返回后连接列表未刷新的生命周期缺陷；真实 HAP `11,578,318` bytes / SHA256 `9D7C75BC498547463EBEF319FE1A06F8505F758B84A065A5C5386704CCDB9DB3` 已通过双 ABI 验包并覆盖安装，`updateTime=1782108829995`。私钥系统选择器已确认能打开；仍需完成真实服务器 HostKey/认证/PTY/SFTP 流量验证。

2026-06-22 07:20 真实连接触发系统 `APP_INPUT_BLOCK`，故障栈证明同步 N-API `opentabssh::Connect` 阻塞 ArkUI 主线程，进程被系统终止；没有取得 HostKey/认证成功证据。随后已将 `connect`、`openShell`、`sftpList` 改为 N-API async work / Promise，并同步调整 Terminal/SFTP 状态机。暂停前 Mock 构建通过；最新真实 HAP 为 `11,587,958` bytes / SHA256 `4C6FDDBCF104BC926C2870D1BFB5AEEDD5AB476C26CB34294477EC64880E7A80`，双 ABI 验包通过，但因用户要求关机暂停，尚未安装或回归。恢复后第一步应安装该哈希并重测 HostKey，再继续认证/PTY/SFTP；不得把“异步源码已编译”写成问题已在设备解决。

恢复后已成功覆盖安装该异步 HAP，x86_64 模拟器 `updateTime=1782151379401`；GitHub PR #1 的托管静态审计也已通过。尚未取得 HostKey/认证/PTY/SFTP 或 appfreeze 消失的运行证据，下一步仍是用仅内存测试凭据重测真实连接。

随后已用仅绑定宿主机回环的隔离 SSH 测试端取得真实协议证据：ArkUI 在异步握手期间保持响应；HostKey 首次 `1001` 阻断、变化 `1002` 警告、显式信任/替换、密码认证、PTY、channel 命令读写、ANSI 渲染和同 session 的 SFTP 根目录列表全部通过，且没有新增 appfreeze/cppcrash/jscrash。测试端 HostKey 在进程内生成，密码只存在测试进程和应用内存。用户提供的外部 IPv6 能 ping 通但宿主机 TCP/22 同样不可达，故公网服务器和 arm64 真机仍未验收。恢复开发时应优先异步化 write/resize/close/disconnect、补 SFTP 写操作和三类转发，再在外部服务器端口恢复后复测。

read/write/resize/closeChannel/disconnect 已继续迁移到 async work / Promise，带终端单次 read/write 在途保护的新真实 HAP 为 `11,594,519` bytes / SHA256 `26BC17D44E24986006EAB13BCC2EEBF3F521DFB73C8BF5260C8F0057D4C0CC6F`，已通过双 ABI 验包并覆盖安装，`updateTime=1782152252857`。下一步是复跑真实 channel/SFTP/关闭清理后再更新完成状态。

外部 IPv6 的 TCP/22 随后恢复，真实公网 ECDSA HostKey、密码认证和 Windows OpenSSH PTY banner 已通过。公网 Windows PTY 暴露命令提交使用 LF 不执行的问题，现已改为 CR；修复 HAP SHA256 `6DB07DB21303EA29FBCA24B9FD17953A04CE5B49BF4BEAB929825D1D6FD3ED20` 已安装，`updateTime=1782152525374`，待立即复测命令与 SFTP。

该哈希的公网复测已经通过：ECDSA HostKey 首次确认、密码认证、Windows OpenSSH PTY、命令真实输出、同 session SFTP（4 个条目）、关闭后 350 ms 内返回、再次连接不重复提示 HostKey 均取得 UI hierarchy 证据；进程持续存活且 faultlogger 无新增记录。测试地址、用户和密码未写入仓库或日志。尚未完成私钥认证、arm64 真机、SFTP 写操作、三类转发、重连退避及 Android 全功能矩阵。

底部主菜单已参照 RustDesk HarmonyOS 改为 56 vp 高的半透明模糊悬浮胶囊，使用四个本地 SVG 图标、选中色与底部安全区适配。SHA256 `237DF2E7A0DBD04139CD6F2CBFE23B91E7EA72119EEC37A58B783F94D276EF62` 的真实 HAP 已安装到 x86_64 模拟器，四标签 UI hierarchy 与点击切换均通过。

随后已继续实现四张参考图的连接、监控、我的/设置和系统设置内容，主菜单行降为 54–62 vp。当前已安装的真实 HAP 为 `11,672,981` bytes / SHA256 `9B4415C64E885E0EF96C89D354785835BB27E6C262D6D21C92970BBE241B23CB`；x86_64 模拟器逐页 UI hierarchy 和系统设置路由已验证，未完成的扫描/本地 shell/文件处理能力仍明确标为开发中。

当前最新真实 HAP 为 `11,822,274` bytes / SHA256 `4E3195BF26531FD4377C6F8D6261C6B2E460E9CF890266595079578586219CEB`，双 ABI native SHA256 为 arm64 `D0B8E0AF09729F4013D46B418E8DDF68FAF4CFB4BD544EE2605BB22FF6F20B60`、x86_64 `360D226AB9CD237E4C8A28539D3FED3E7B55E2523EB9C20287BB859D1F9769A5`，已覆盖安装。SFTP 已增加上传/下载/建目录/删除/改名/chmod 的 async N-API 和紧凑 UI；回环内存端验证了逐字节上传→下载回读、建目录、改名、`0644`、文件/空目录删除。系统“保存”选择器在当前自动化模拟器上仍有 Promise 不返回问题，须真机复验。

2026-06-23 图标来源规则已收紧：启动图标、底部导航、四张参考页、SFTP、返回/刷新和终端方向键均改用可追溯的 ProIcons SVG，旧 `tab_*.svg` 自绘资源已删除，字符/Emoji 图标已移除。28 个使用中的 SVG 通过 XML 解析，完整静态审计 45/45；当前执行环境无 `99_Temp` 写权限，尚无新 HAP 或安装证据。来源、组件语义和映射见 `PROICONS_ICONS.md`。

同轮继续编码三类真实端口转发：libssh2 direct-tcpip 本地转发、服务器回环 remote-forward、无认证 SOCKS5 CONNECT 动态转发，均已接入多连接 worker、async N-API、Mock 明确拒绝和断开前清理。arm64 与 x86_64 OHOS Clang `-fsyntax-only` 均已通过；尚未构建 HAP，也没有三类真实流量证据，禁止标记完成。

终端重连状态机也已编码：轮询发送 libssh2 keepalive，仅已成功会话自动重试，5 秒指数退避到 5 分钟，正常 EOF/认证/HostKey 错误不循环，用户关闭会取消定时器；HarmonyOS 网络回调在离线时暂停、恢复时立即唤醒，并有 5 分钟兜底轮询。重连前释放旧 channel/forward/session 并重建 HostKey/认证/PTY。keepalive 后的 Native Core 已通过 arm64/x86_64 语法检查，尚缺 ArkTS/HAP 构建、长时间空闲和断网恢复设备证据。

终端渲染同轮继续升级：`TerminalEmulator.ets` 已支持常用 VT 光标/擦除/插删/滚动区、SGR 16/256/RGB、文本属性、备用屏、OSC/C1 标题、DSR/DA、DEC 线条字符、application cursor、bracketed paste、组合字符与双宽字符；TerminalPage 已接样式 Span、复制、横向控制键和动态 PTY resize。`scripts/test_terminal_emulator.ps1` 的严格语义检查及 13 类功能/确定性 fuzz 检查通过，静态审计更新为 67/67。受 `99_Temp` 写权限限制，ArkUI DSL、HAP、模拟器上的 vim/tmux/htop/nano 与性能仍未验证，禁止写成完整 xterm 已完成。

SFTP 大文件路径也做了源码级加固：Native 每个成功数据块刷新空闲 deadline，下载返回前检查本地 flush；Document URI 与 cache 的复制改为异步 `fs.copyFile`。双 ABI native 语法检查通过，但尚无新 HAP、大文件哈希、取消或断点恢复证据。

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
- 应用图标只能使用 `docs/PROICONS_ICONS.md` 登记的 ProIcons 资产，禁止新增自绘 SVG、Emoji 或字符图标。
