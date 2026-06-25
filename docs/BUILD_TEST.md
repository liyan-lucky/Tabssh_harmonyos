# 构建与测试要求

## 当前拉取后推荐入口

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_local_checks.ps1
```

默认入口会串联 `git diff --check`、静态审计、终端解析器测试、Mock 构建和 Mock 验包。真实 Core 需要已有三方依赖 manifest 时使用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_local_checks.ps1 -WithRealCore
```

从零构建三方依赖时使用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_local_checks.ps1 -WithRealCore -BuildDependencies
```

构建完成后安装/冷启动冒烟使用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\install_and_smoke.ps1
```

`install_and_smoke.ps1` 只证明安装、启动、PID 与基础异常日志采集；不能替代 SSH、SFTP、端口转发、重连、签名或发布验收。

## 基线命令

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\audit_project.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_mock_hap.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_mock_hap.ps1
```

脚本先复制干净副本到 `99_Temp\harmonyos_stage\10_Tabssh_harmonyos`，所有 Hvigor、CMake 和 native 产物在该副本内生成，再复制最终 HAP/APP 到 `99_Temp\harmonyos_build\10_Tabssh_harmonyos`。仓库根不得产生 build、`.cxx` 或日志。

## 历史验证记录

2026-06-22 02:34（Europe/Berlin）重要修改回归：含 HostKey UI 和基础 ANSI/VT 网格的 Mock fallback HAP `entry-default-unsigned.hap` 为 `3,099,325` bytes / SHA256 `1CF2D83204AE61D10B08C1C003D9C90CE0E78807A59C7CB885F1A4C2D7C478AB`；包内四个双 ABI native entries 通过 ELF 检查。该包随后成功覆盖安装到 `127.0.0.1:5555` x86_64 模拟器，Bundle `com.open.tabssh`、版本 `0.1.0 / 1`、`updateTime=1782092052465`，冷启动 PID `21653`，筛选 `com.open.tabssh|OpenTabSsh|FATAL|Fatal|cppcrash` 得到 0 行。模拟器报告 `appProvisionType=debug`、`appSignType=none`；这只证明 Mock fallback 的安装/冷启动，不是签名发布证据，也不是任何真实 SSH 功能证据。

同一安装包完成无凭据 UI hierarchy 冒烟：首页 → 连接 → 示例连接 → Terminal；页面明确显示“Mock 已连接（非真实 SSH）”，基础终端网格正确呈现 Mock banner，并在输入 `pwd` 后显示 `/home/opentabssh`；关闭终端后返回 `pages/Index`，进程保持存活。该检查只验证 UI、轮询、基础控制字符解析和 Mock 会话清理，不验证 ANSI 颜色/复杂 xterm 行为或真实网络。

2026-06-22 06:55（Europe/Berlin）真实 Core 首次构建/安装：`entry-default-unsigned-real.hap` 为 `11,566,708` bytes / SHA256 `6E47A6C7FAB84214210D959F7CFE3088BCF937B7E90E56F9A65B7536429F6A4E`。其中 arm64-v8a `libentry.so` 为 `4,363,464` bytes / SHA256 `A796B05DCC1E1C7D0A3EDDECF10D291B650A45ED5E2BDF07E02B071C84F3551F`，x86_64 为 `4,417,528` bytes / SHA256 `F79F87F2EC8FA833BF01D977A38F32D14CF89F49F451D1DA9B53F9974A2AFD1D`；两者 machine 与 `real-ssh/libssh2` marker 通过，且不含 Mock shell marker。该包成功覆盖安装并冷启动于 `127.0.0.1:5555` x86_64 模拟器，`updateTime=1782107735827`、PID `27063`、筛选加载/崩溃日志 0 行。它证明双架构真实 Core 可链接、打包、加载和冷启动；在获得真实 HostKey/认证/shell/SFTP/流量证据前仍不代表网络功能完成。

2026-06-22 07:05（Europe/Berlin）加入应用私有目录私钥导入和窗口隐私保护后再次构建并覆盖安装真实包：`entry-default-unsigned-real.hap` 为 `11,578,032` bytes / SHA256 `A38EFE5FD4C6B67096412BEDBCF04A057EC76ADA55A0BCC9931F0BA12EB24EB7`，双 ABI real marker/machine 复验通过；x86_64 模拟器返回 `install bundle successfully`，Bundle `com.open.tabssh`、版本 `0.1.0 / 1`、`updateTime=1782108374943`。本条仅证明新包安装成功；私钥选择、真实 HostKey/认证/shell/SFTP 仍须随后取得端到端证据。

2026-06-22 07:13（Europe/Berlin）模拟器运行时测试发现编辑页返回后连接列表未刷新，补充 `onPageShow` 重载后再次构建/验包/覆盖安装：真实 HAP `11,578,318` bytes / SHA256 `9D7C75BC498547463EBEF319FE1A06F8505F758B84A065A5C5386704CCDB9DB3`，双 ABI native 哈希保持不变，安装成功且 `updateTime=1782108829995`。密码只在测试进程和应用内存输入，未写入本证据或任何落盘日志。

2026-06-22 07:20（Europe/Berlin）首次使用真实网络配置点击连接时，系统生成 `APP_INPUT_BLOCK`：主线程栈明确停在 `libentry.so -> opentabssh::Connect -> libace_napi`，约 6 秒后进程被终止。因此本次没有取得 HostKey、认证或 PTY 成功证据，且不能把 Core 内部的 nonblocking socket 写成 UI 非阻塞。故障原始记录仅保存在 `99_Temp\tabssh_harmonyos_logs`，不进入仓库且不含测试密码。

随后已把 `connect`、`openShell` 和 `sftpList` N-API 改为后台 async work / Promise，并让 Terminal 页面先渲染“正在连接”状态后异步等待 HostKey。暂停前 Mock HAP 已构建成功（`3,128,166` bytes / SHA256 `7059161CD44D54210B11DE66512BF4258A034B2690F1BBBA1FDF61852E5AE95F`）；真实 HAP 已构建并通过双 ABI real-marker/machine 验证（`11,587,958` bytes / SHA256 `4C6FDDBCF104BC926C2870D1BFB5AEEDD5AB476C26CB34294477EC64880E7A80`，arm64 native SHA256 `CFE61E49666FDE1C442BD47C316F14E60E24B554F0FB8AA0CFDA72EC64B39E67`，x86_64 native SHA256 `8E83489C6DBC242F64A5908AB157DD195381CA6A8183BE592B1611C8197252B6`）。应用户关机请求，此包尚未安装，异步连接修复尚未取得设备回归证据。

2026-06-22 恢复测试后，上述 SHA256 `4C6FDDBCF104BC926C2870D1BFB5AEEDD5AB476C26CB34294477EC64880E7A80` 的真实 HAP 已成功覆盖安装到 `127.0.0.1:5555` x86_64 模拟器，Bundle 版本 `0.1.0`、`updateTime=1782151379401`。本条只证明异步修复包安装成功；HostKey、认证、PTY、SFTP 与无 appfreeze 回归须由后续步骤分别取证。

同一异步 HAP 随后完成本机隔离测试端的真实 SSH 流量回归。测试端仅绑定宿主机回环，由 HDC reverse 暴露给模拟器；RSA HostKey 在测试进程内生成，密码只由进程环境和应用运行内存持有，均未写入仓库、测试日志或 UI 层级文件。验证结果：

- 点击连接后 1.5 秒内 Terminal 页面已显示“正在连接并校验 HostKey”，主进程持续响应，证明耗时握手没有继续阻塞 ArkUI 主线程。
- 首次连接返回 `1001` 并显示算法/指纹核对对话框；显式信任后密码认证成功，状态为“SSH 已认证 / PTY 已打开”。
- 真实 SSH channel 收到测试端 banner；发送测试命令后，预期标记由远端经加密 channel 返回并进入终端网格。
- 重启测试端生成新 HostKey 后，客户端返回 `1002` 并显示高风险“HostKey 已变化”警告；显式替换后重新认证和 PTY 打开成功。
- 同一已认证 session 打开真实 SFTP 子系统，根目录列出 `documents` 目录与 `welcome.txt`（18 bytes），证明不是 Mock SFTP 返回。
- 回归结束时 `com.open.tabssh` 进程仍存活；faultlogger 中只有异步修复前的那一条 `APP_INPUT_BLOCK`，没有新增 appfreeze/cppcrash/jscrash。

该证据验证本机回环上的真实 SSH 协议和 libssh2 数据路径，但临时测试端的 shell 是受限验收端，不等同于任意生产服务器。用户提供的外部 IPv6 可由模拟器 ping 通，但宿主机 TCP/22 同样不可达，因此本次不能宣称公网服务器、arm64 真机或复杂网络条件验收完成。

2026-06-22 将 read/write/resize/closeChannel/disconnect 一并迁移到 N-API async work / Promise，并为终端 read/write 增加单次在途保护后完成全量重建：Mock HAP `3,134,727` bytes / SHA256 `CDBDF475C9162D5C08BBCB8FCC898C41604129B6B994687F15FBD7293BE72D12`；真实 HAP `11,594,519` bytes / SHA256 `26BC17D44E24986006EAB13BCC2EEBF3F521DFB73C8BF5260C8F0057D4C0CC6F`。arm64 native SHA256 `348135107DC96F315D0DC5110E2E8CC322ADBF3C120F422710173D38D66210E6`，x86_64 native SHA256 `FF0873BD6C7AAB28608013215D4D342CCAB498D9E39F406A4C36A62BE7A5C890`；双 ABI real marker/machine 通过。该真实 HAP 已成功覆盖安装到 x86_64 模拟器，`updateTime=1782152252857`；相关流量与清理回归仍需随后取证。

外部 IPv6 的 TCP/22 恢复后，客户端已取得真实公网 HostKey（ECDSA）、密码认证和 Windows OpenSSH PTY banner。首次发送命令只在远端提示符回显但未执行，定位为 Windows PTY 需要 CR 而客户端发送 LF；提交终止符改为 `\r` 后重新构建的真实 HAP 为 `11,594,519` bytes / SHA256 `6DB07DB21303EA29FBCA24B9FD17953A04CE5B49BF4BEAB929825D1D6FD3ED20`，双 ABI native 哈希保持不变，并已成功覆盖安装，`updateTime=1782152525374`。公网命令执行与 SFTP 仍须用此哈希复测后才能标记通过。

SHA256 `6DB07DB21303EA29FBCA24B9FD17953A04CE5B49BF4BEAB929825D1D6FD3ED20` 的公网复测随后通过：首次 ECDSA HostKey 阻断/确认、密码认证、Windows OpenSSH PTY banner、命令回显与独立远端输出均进入终端网格；同一 session 的 SFTP 页面显示真实状态并返回 4 个远端条目（证据采集只记录数量，不保存文件名）。从 SFTP 返回后关闭会话，350 ms 内回到连接列表且进程 PID 保持；再次连接同一 profile 时直接认证/打开 PTY，没有重复 HostKey 首次提示，证明已信任指纹的 session 重建路径可用。结束时 faultlogger 仍只有异步修复前的旧 `APP_INPUT_BLOCK`，无新增 appfreeze/cppcrash/jscrash。测试地址、用户名和密码均未写入本文件或构建/测试日志。

2026-06-22 19:30（Europe/Berlin）参照 RustDesk HarmonyOS 底部导航样式完成四标签悬浮胶囊底栏，使用仓库内 SVG 图标、半透明 Thin blur、圆角、边框、轻阴影和底部安全区适配。Mock HAP 为 `3,142,255` bytes / SHA256 `0B2A06D4268F4FFE3FEF5D032BACC72809D25F96BA5880852AAB3C55F1698FC8`；真实 HAP 为 `11,597,503` bytes / SHA256 `237DF2E7A0DBD04139CD6F2CBFE23B91E7EA72119EEC37A58B783F94D276EF62`，双 ABI marker/machine 复验通过。真实 HAP 已成功覆盖安装到 x86_64 模拟器；UI hierarchy 显示底栏为 56 vp 高、左右约 16 vp、底部约 8 vp，“工作台 / 连接 / 监控 / 我的”四项均可点击切换，进程保持存活。

2026-06-22 20:15（Europe/Berlin）完成真实 SFTP 写操作阶段回归。最终 Mock HAP 为 `3,292,642` bytes / SHA256 `2C0950D4AEC0A0265D04E7B19406F22F11DF49F283BB74D4C83ECAACA40C11CB`；真实 HAP 为 `11,822,274` bytes / SHA256 `4E3195BF26531FD4377C6F8D6261C6B2E460E9CF890266595079578586219CEB`，arm64 native SHA256 `D0B8E0AF09729F4013D46B418E8DDF68FAF4CFB4BD544EE2605BB22FF6F20B60`、x86_64 native SHA256 `360D226AB9CD237E4C8A28539D3FED3E7B55E2523EB9C20287BB859D1F9769A5`，双 ABI real marker/machine 验包通过，并已覆盖安装到 x86_64 模拟器。

隔离验收端仅绑定宿主机回环，HostKey 与文件系统均在测试进程内生成，凭据仅存在环境变量和应用运行内存。真实 libssh2/N-API 路径完成：建目录；小文本上传后再下载到应用私有缓存并逐字节一致；重命名；chmod 为 `0644`；删除文件和空目录。最终哈希安装后又复验了密码认证、PTY 与上传→下载回读一致，进程保持存活。系统文档“保存”选择器在当前自动化模拟器上出现界面未显示且 Promise 未返回，未写成通过；需在真机手工验证取消、覆盖与大文件保存。

2026-06-23 ProIcons 统一替换后，源码字符图标扫描为 0，28 个使用中的 SVG 均通过 XML 解析，旧 `tab_*.svg` 引用为 0；仓库内 `entry/build`、`entry/.cxx` 已由 `clean_project.ps1 -BuildOnly` 清理，完整静态审计为 45/45。当前受限执行环境不允许写 `%VSCODE_ROOT%\99_Temp`，Mock stage 创建被系统拒绝。因此本轮没有新 HAP 哈希、安装或设备渲染证据，旧安装包不能代表 ProIcons 修改。恢复外部目录写权限后必须重新运行 Mock/真实构建、安装和四标签/设置/SFTP 图标冒烟。

三类转发新增源码随后使用本机 OHOS arm64 与 x86_64 Clang、固定 libssh2 `1.11.1` 头文件执行 `-fsyntax-only`，real core、Mock core 与 N-API 翻译单元均通过。这不是链接、HAP 或流量证据；权限恢复后需分别验证：`-L` 双向 TCP 字节流；`-D` IPv4/IPv6/域名 SOCKS5 CONNECT；`-R` 服务器回环监听到本机服务；多连接并发；单条移除和 session 断开后的端口/channel 释放。

同轮加入 libssh2 keepalive、终端 EOF/传输错误检测、5 秒至 5 分钟指数退避、立即重连、HarmonyOS 网络离线暂停/恢复唤醒/5 分钟兜底轮询和旧 session 清理，并增加 `GET_NETWORK_INFO`。加入 keepalive 后 Native Core 继续通过 arm64/x86_64 `-fsyntax-only`；ArkTS 状态机因 `99_Temp` 不可写尚未经过 Hvigor 编译。后续设备测试需覆盖长时间空闲、正常 `exit` 不重连、网络断开暂停、恢复后立即重试、HostKey 变化停止自动重试、手动立即重连、关闭页面取消重连，以及重连前后监听端口和 PID/faultlogger。

终端解析器随后升级为带样式单元格的 VT 状态机。`scripts/test_terminal_emulator.ps1` 的严格语义检查为 0 错误，并复验光标覆盖、16 色、256 色、RGB 背景、备用屏隔离/恢复、OSC/C1 标题与控制字符清理、DSR/DA 回复、组合/双宽字符、有界滚动、DEC 线条字符和确定性控制序列 fuzz，13 项功能检查全部 PASS。TerminalPage 已编码样式 `Span`、复制、application cursor、bracketed paste、横向控制键和视口→PTY resize，但 ArkUI DSL 必须通过下一次 Hvigor/HAP 构建和模拟器安装后才算编译验证；旧 HAP 不代表这些修改。

SFTP 大文件路径已修正两个源码级风险：Native 上传/下载不再把 profile timeout 当作整次传输总时限，而是在每个成功块后刷新空闲 deadline；下载在成功返回前检查本地 flush。Document URI 与私有缓存之间的复制也由同步 `copyFileSync` 改为 Promise `fs.copyFile`，避免在 ArkUI 线程同步搬运大文件。Native 修改继续通过 arm64/x86_64 语法检查；尚无新 HAP、大文件哈希、取消或断点恢复证据。

2026-06-25 审计同步修正：新增 `scripts/run_local_checks.ps1` 与 `scripts/install_and_smoke.ps1` 后，本文件曾被错误压缩为摘要。已按历史记录恢复详细构建/安装/失败证据，并追加当前入口与记录规则。经验：构建测试文档只能追加或补充，不应覆盖旧失败和旧哈希；旧失败记录是后续排查依据。

## 当前必须补的新证据

- 运行 `scripts/run_local_checks.ps1` 后生成的 `summary_*.md` 结论。
- 运行 `scripts/install_and_smoke.ps1` 后生成的 `summary_*.md` 结论。
- 最新 ProIcons 资源包的 HAP 构建、安装和页面渲染证据。
- 最新终端 Span 渲染、复制、视口 resize、复杂 TUI 和性能证据。
- 三类端口转发真实 HAP 的逐字节流量证据。
- SFTP 大文件、取消和中断恢复证据。
- arm64 真机真实 SSH 端到端证据。

## 设备验证

未来真实 Core HAP 必须分别安装到 arm64 真机和 x86_64 模拟器，核对 SHA256、mtime、版本、双 ABI、设备 `updateTime`、冷启动 PID 和安全筛选后的 hilog；正式发布仍必须使用独立签名。测试凭据只在运行内存输入；不保存原始含敏感字段日志。

## 最终收口

每次重要修改和最终版本执行一次完整审计、全量构建、双设备安装，以及真实 SSH、终端、SFTP、转发、错误恢复和断开清理检查。任何功能源码、Native 依赖或构建配置变化都会使旧 HAP 哈希和设备证据失效。

## 记录规则

- 原始日志保存在 `99_Temp`，不要提交。
- 可提交文档只写摘要、HAP 哈希、设备类型、通过项和失败项。
- 不写服务器地址、用户名、密码、私钥、token、完整文件名列表或设备隐私路径。
- 每轮修改脚本、构建、安装、Native、ArkTS 页面或资源后，必须同步更新 `docs/FILES.md`、`docs/PROGRESS.md`、`docs/ISSUES.md` 或本文中的相关条目。
