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

2026-06-29 08:38（Asia/Shanghai）同步 Android 参考源码到 `99_Temp\tabssh_reference` 后，首页工作台和连接页新增连接分组入口，连接页新增分组筛选芯片，并修复本地检查、Mock 构建、安装冒烟脚本在当前 Windows/DevEco SDK 环境下的解析和 JBR 定位问题。`scripts/run_local_checks.ps1` 全量通过 8/8，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_083850.md`。Mock HAP 为 `E:\Visual_Studio_Code\99_Temp\harmonyos_build\10_Tabssh_harmonyos\entry-default-unsigned.hap`，大小 `3,569,124` bytes，SHA256 `7496E689F7E618C1543023851B7695A7418B503831E8B761B711C22831151DAF`；包内 `libs/arm64-v8a/libentry.so`、`libs/arm64-v8a/libc++_shared.so`、`libs/x86_64/libentry.so`、`libs/x86_64/libc++_shared.so` 均通过验包。ArkTS/HAP 编译通过，仅保留既有 deprecated API/throw handling 警告。

2026-06-29 08:42（Asia/Shanghai）同一 Mock HAP 已通过 `scripts/install_and_smoke.ps1` 安装/冷启动冒烟，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\summary_20260629_084241.md`。x86_64 模拟器启动 PID `30856`，筛选 `hilog` 为 0 行，`faultlogger` exitCode 为 0。随后通过 `uitest dumpLayout` 拉取首屏层级，文本包含“工作台 / 主机列表 / 连接分组 / Redis连接 / SFTP连接 / 连接”，证明本轮首页入口与连接页入口已打包、安装并在首屏可见。该证据仍不代表连接分组页完整点击流程、搜索/收藏/排序交互、真实 SSH/SFTP/转发、签名发布或 arm64 真机验收完成。

2026-06-29 08:49（Asia/Shanghai）文档回填后再次执行 `scripts/run_local_checks.ps1 -SkipMockBuild`，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_084926.md`。`git diff --check`、全局审计、连接分组专项审计和终端解析器测试均 PASS；全局审计为 74/74，连接分组专项审计为 15/15。Mock/Real HAP 构建在该轻量复核中按参数跳过，完整 HAP 证据仍以上方 08:38 和 08:42 记录为准。

2026-06-29 08:55（Asia/Shanghai）继续对齐 Android Room 方向，`ProfileRepository` 接入 HarmonyOS `relationalStore` RDB：启动时创建 `connection_groups` 与 `connection_profiles`，以 RDB JSON 行保存分组、主机配置、收藏、排序、HostKey 元数据和连接统计；`password` 与 `privateKeyPassphrase` 在持久化前清空，仍只允许运行内存使用。`scripts/run_local_checks.ps1` 全量通过 8/8，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_085512.md`。

2026-06-29 08:56（Asia/Shanghai）RDB 版 Mock HAP 已覆盖安装并冷启动，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\summary_20260629_085614.md`。HAP 大小 `3,590,329` bytes，SHA256 `36E1E19ED6DA2B464B025BCAAFF8B064496C440A4875A1D43E96C09F86B7C45E`；x86_64 模拟器启动 PID `9591`，筛选 `hilog` 为 0 行，`faultlogger` exitCode 为 0。UI hierarchy 复查仍显示“工作台 / 主机列表 / 连接分组 / Redis连接 / SFTP连接 / 连接”。该证据证明 RDB 初始化随 HAP 启动通过；尚未证明新增/改名/筛选后杀进程重启仍持久、真实 SSH 统计跨重启保存或数据库迁移策略完整。

2026-06-29 09:03（Asia/Shanghai）更新 RDB 页面提示和审计项后完成最终复核：`scripts/run_local_checks.ps1` 全量通过 8/8，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_090240.md`。最终 Mock HAP 大小 `3,590,301` bytes，SHA256 `103F3E8FC961A83BFF64F6E10148A82B476931031378384897B5FA61987B5327`，安装冒烟摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\summary_20260629_090339.md`；x86_64 模拟器启动 PID `15071`，筛选 `hilog` 为 0 行，`faultlogger` exitCode 为 0，首屏 UI hierarchy 仍包含“工作台 / 主机列表 / 连接分组 / Redis连接 / SFTP连接 / 连接”。随后刷新仓库内审计报告：全局审计 77/77，连接分组专项审计 16/16。

2026-06-29 09:36（Asia/Shanghai）继续对齐 Android 连接管理体验，首页连接页新增搜索命中高亮、批量模式、批量收藏/取消收藏、批量移组、批量删除，并按全屏窗口要求在 `EntryAbility` 中开启全屏布局、透明系统栏、隐私窗口和系统/挖孔/手势避让区写入 `AppStorage`。`scripts/run_local_checks.ps1` 全量通过 8/8，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_093629.md`。Mock HAP 随后覆盖安装并冷启动，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\summary_20260629_093744.md`；HAP 大小 `3,630,685` bytes，SHA256 `58A1EC896F858BF789FD5AFE63BB8EE566E490912AEABD16233AAE58EBE6D05B`，x86_64 模拟器启动 PID `4195`，筛选 `hilog` 为 0 行，`faultlogger` exitCode 为 0。首屏 UI hierarchy 文本包含“工作台 / 主机列表 / 连接分组 / Redis连接 / SFTP连接 / 连接”。该证据证明源码通过 Mock 构建、安装和首屏渲染；仍不代表批量操作逐项点击、跨重启、不同屏幕全屏避让矩阵或真实连接流量验收完成。

2026-06-29 09:44（Asia/Shanghai）在同一轮全屏避让与批量/高亮代码上执行真实 Core 本地检查：`scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_094256.md`。最新 Mock HAP 大小 `3,630,685` bytes，SHA256 `32426F4916C405EA828382A3B7C1CDE3A5CA54BF2644BE5A4FDC4838E59E1CCC`；最新 Real HAP 为 `E:\Visual_Studio_Code\99_Temp\harmonyos_build\10_Tabssh_harmonyos\entry-default-unsigned-real.hap`，大小 `12,380,469` bytes，SHA256 `73A472526A096E1BE701A0CF2BB8E6086F07EDBEC9F373CD39F4B15D86040ECA`。Real HAP 验包确认 arm64-v8a `libentry.so` 大小 `4,500,608` bytes、SHA256 `451CAF5013D6957B575FBF9778B653F8DBEBB2438116106C4F597B067012C0C9`，x86_64 `libentry.so` 大小 `4,556,680` bytes、SHA256 `46127963DBF9FBFCB96B7943899287886F6041BBEED24DE7598F11CA86CCE34B`。

2026-06-29 09:45（Asia/Shanghai）最新 Real HAP `73A472526A096E1BE701A0CF2BB8E6086F07EDBEC9F373CD39F4B15D86040ECA` 已覆盖安装并冷启动于默认 hdc 目标，安装冒烟摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\summary_20260629_094528.md`；x86_64 模拟器启动 PID `10179`，筛选 `hilog` 为 0 行，`faultlogger` exitCode 为 0。随后通过 `uitest dumpLayout` 拉取首屏层级到 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\layout_20260629_094528_real.json`，可见文本包含“工作台 / 主机列表 / 连接分组 / 钥匙串 / Redis连接 / SFTP连接 / 文件管理 / 连接 / 监控 / 我的”。该证据只证明 Real HAP 安装、冷启动、首屏可见和基础全屏避让未遮挡主入口；仍不代表 SSH/SFTP/转发流量、批量点击、RDB 跨重启、arm64 真机或签名发布验收完成。

2026-06-29 09:54（Asia/Shanghai）文档回填后执行 `scripts/run_local_checks.ps1 -SkipMockBuild` 复核，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_095420.md`。`git diff --check`、全局审计、连接分组专项审计和终端解析器测试均 PASS；全局审计为 80/80，连接分组专项审计为 16/16。该轻量复核跳过 HAP 重建，HAP/安装证据以上方 09:44 和 09:45 记录为准。

2026-06-29 10:03（Asia/Shanghai）继续对齐 Android 审计/访问日志基础能力，新增 `ConnectionAuditLog` 模型、RDB `connection_audit_logs` 表、`AuditLogPage` 页面和首页“访问日志”入口；当前只记录连接认证结果、批量操作和分组变更摘要，不记录命令输出、密码、私钥口令或服务器地址。`scripts/run_local_checks.ps1` 全量通过 8/8，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_100207.md`。Mock HAP 大小 `3,685,510` bytes，SHA256 `20DDF1258762C59A2C25CFBA46B094080EEA1FECFB166EBB7ACA682DA2702C4B`，随后覆盖安装并冷启动，安装冒烟摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\summary_20260629_100334.md`；x86_64 模拟器启动 PID `24202`，筛选 `hilog` 为 0 行，`faultlogger` exitCode 为 0。通过 `uitest uiInput click` 从工作台点进“访问日志”后拉取页面层级到 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\layout_20260629_100334_audit_log.json`，可见文本包含“访问日志 / 本地 RDB 摘要日志，不记录命令输出或凭据 / 刷新 / 清空 / 审计范围 / 暂无访问日志”。该证据证明新页面路由、首屏和基础点击可用；不代表 Android 完整命令审计、日志导出、MDM、syslog、保留策略或跨重启日志回显已完成。

2026-06-29 10:14（Asia/Shanghai）访问日志文档和审计项补齐后执行 `scripts/run_local_checks.ps1 -WithRealCore`，通过 9/9，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_101254.md`。最新 Mock HAP 大小 `3,685,523` bytes，SHA256 `0E243350EBA7E368C33E3FA33008C2D8359B4BB2FF9DBF71F39D497AC3D2BE31`；最新 Real HAP 大小 `12,435,307` bytes，SHA256 `6602D1CDED6265978E30EBD8720F5C71577B7AB080FF0929E048D10C7C3A4E25`。Real HAP 验包确认 arm64-v8a `libentry.so` 大小 `4,500,608` bytes、SHA256 `451CAF5013D6957B575FBF9778B653F8DBEBB2438116106C4F597B067012C0C9`，x86_64 `libentry.so` 大小 `4,556,680` bytes、SHA256 `46127963DBF9FBFCB96B7943899287886F6041BBEED24DE7598F11CA86CCE34B`。

2026-06-29 10:15（Asia/Shanghai）最新 Real HAP `6602D1CDED6265978E30EBD8720F5C71577B7AB080FF0929E048D10C7C3A4E25` 覆盖安装并冷启动，安装冒烟摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\summary_20260629_101526.md`；x86_64 模拟器启动 PID `1364`，筛选 `hilog` 为 0 行，`faultlogger` exitCode 为 0。随后通过 `uitest uiInput click` 从工作台点进“访问日志”并拉取层级到 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\layout_20260629_101526_real_audit_log.json`，可见文本包含“访问日志 / 本地 RDB 摘要日志，不记录命令输出或凭据 / 刷新 / 清空 / 审计范围 / 暂无访问日志”。该证据证明 Real HAP 的访问日志页面路由和基础点击可用；仍不代表真实连接事件、跨重启、导出、MDM/syslog 或完整审计能力完成。

2026-06-29 10:17（Asia/Shanghai）最终文档回填后执行 `scripts/run_local_checks.ps1 -SkipMockBuild`，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_101734.md`。`git diff --check`、全局审计、连接分组专项审计和终端解析器测试均 PASS；全局审计为 84/84，连接分组专项审计为 16/16。该轻量复核跳过 HAP 重建，HAP/安装证据以上方 10:14 和 10:15 记录为准。

2026-06-29 10:21（Asia/Shanghai）在最新 Real HAP `6602D1CDED6265978E30EBD8720F5C71577B7AB080FF0929E048D10C7C3A4E25` 上继续做无凭据交互验证：从工作台进入连接分组页，点击“新建”生成一个分组，再返回工作台进入访问日志页。UI hierarchy 拉取到 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\layout_20260629_101526_real_audit_log_after_group_success.json`，可见文本包含“分组变更 / 06-29 10:21 / 连接分组 / 新增分组”。该证据证明分组变更摘要能写入 RDB 并在访问日志页读取显示；仍未覆盖跨重启、清空日志、真实 SSH 认证事件或隐私字段落库审计。

2026-06-29 10:20:50（Asia/Shanghai，文件时间）在同一 Real HAP 上执行强停与重新启动，重启后 PID 为 `24500`。随后拉取 `layout_20260629_102050_real_audit_log_after_restart.json` 与 `layout_20260629_102050_real_group_after_restart.json`，访问日志仍显示“分组变更 / 新增分组”，连接分组页仍显示“新分组 1 / 0 台主机 · 已展开”。该证据证明新增分组与对应摘要日志的基础 RDB 跨重启回显通过；仍不能外推到改名、换色、收藏、统计、清空日志、批量操作日志、真实认证事件或 schema migration。

2026-06-29 14:42（Asia/Shanghai）补齐所有路由页的全屏避让后执行 `scripts/run_local_checks.ps1 -WithRealCore`，通过 9/9，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_144116.md`。最新 Mock HAP 大小 `3,697,532` bytes，SHA256 `6D5AD9A436757D3FD535B2F899DAB98E01F4B52208C94324143E1F0C5A3C9068`；最新 Real HAP 大小 `12,447,316` bytes，SHA256 `EBE21ED75F5B00E5C13B22EB48A53163D958AE3AC7E619E8E808BF5D9FFBC413`。Real HAP 验包确认 arm64-v8a `libentry.so` 大小 `4,500,608` bytes、SHA256 `451CAF5013D6957B575FBF9778B653F8DBEBB2438116106C4F597B067012C0C9`，x86_64 `libentry.so` 大小 `4,556,680` bytes、SHA256 `46127963DBF9FBFCB96B7943899287886F6041BBEED24DE7598F11CA86CCE34B`。

2026-06-29 14:43（Asia/Shanghai）最新 Real HAP `EBE21ED75F5B00E5C13B22EB48A53163D958AE3AC7E619E8E808BF5D9FFBC413` 覆盖安装并冷启动，安装冒烟摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\summary_20260629_144332.md`；x86_64 模拟器启动 PID `18390`，筛选 `hilog` 为 0 行，`faultlogger` exitCode 为 0。随后拉取全屏避让抽样层级：首页 `layout_20260629_144332_fullscreen_home.json`、我的页 `layout_20260629_144332_fullscreen_my.json`、系统设置 `layout_20260629_144332_fullscreen_settings.json`、终端设置 `layout_20260629_144332_fullscreen_terminal_settings.json`、关于页 `layout_20260629_144332_fullscreen_about.json`、连接页 `layout_20260629_144332_fullscreen_connection_tab2.json`、连接编辑 `layout_20260629_144332_fullscreen_connection_edit.json`、SFTP `layout_20260629_144332_fullscreen_sftp.json`、端口转发 `layout_20260629_144332_fullscreen_port_forward.json`。层级文本覆盖“工作台 / 设置 / 系统设置 / 终端设置 / 关于 / 新建连接 / SFTP 文件 / 端口转发”，且底部胶囊导航和页面底部控件仍可见。该证据证明本轮全屏避让代码已打包安装并通过单台 x86_64 模拟器多页无凭据抽样；仍不代表横竖屏、手势导航、挖孔设备、软键盘、终端真实会话或多设备矩阵全部完成。

2026-06-29 14:57（Asia/Shanghai）文档同步后执行 `scripts/run_local_checks.ps1 -SkipMockBuild`，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_145715.md`。`git diff --check`、全局审计、连接分组专项审计和终端解析器测试均 PASS；全局审计为 84/84，连接分组专项审计为 16/16。该轻量复核跳过 HAP 重建，HAP/安装/页面层级证据以上方 14:42 和 14:43 记录为准。

2026-06-29 15:02（Asia/Shanghai）对齐 Android `audit_log_menu.xml` 的 Export 能力后，`AuditLogPage` 新增纯 HarmonyOS 摘要 JSON 导出：只导出页面已展示的时间、事件类型、状态、配置名和摘要消息，并写入 `summary-only` 策略说明，不导出命令输出、密码、私钥口令或服务器地址。执行 `scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_150054.md`。最新 Mock HAP 大小 `3,706,312` bytes，SHA256 `B9F049A58AD77E3E73DF332E95A69D8B5DA6BEC088EEE0613453F9A7C0C0CFC6`；最新 Real HAP 大小 `12,456,096` bytes，SHA256 `F775A91C2A8E1DDBA3BD9CF5BC9A56CA3F2E14CB7FE573AAAD391B6A3FA2483A`。Real HAP 验包确认 arm64-v8a `libentry.so` 大小 `4,500,608` bytes、SHA256 `451CAF5013D6957B575FBF9778B653F8DBEBB2438116106C4F597B067012C0C9`，x86_64 `libentry.so` 大小 `4,556,680` bytes、SHA256 `46127963DBF9FBFCB96B7943899287886F6041BBEED24DE7598F11CA86CCE34B`。

2026-06-29 15:03（Asia/Shanghai）最新 Real HAP `F775A91C2A8E1DDBA3BD9CF5BC9A56CA3F2E14CB7FE573AAAD391B6A3FA2483A` 覆盖安装并冷启动，安装冒烟摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\summary_20260629_150315.md`；x86_64 模拟器启动 PID `2170`，筛选 `hilog` 为 0 行，`faultlogger` exitCode 为 0。随后从工作台进入访问日志页并拉取 `layout_20260629_150315_audit_export.json`，可见“访问日志 / 刷新 / 导出 / 清空 / 分组变更 / 新增分组”。点击“导出”后拉取 `layout_20260629_150315_audit_export_picker.json`，可见系统保存界面文本“将文件保存至 "我的手机" / opentabssh-audit-20260629-1504.json / Download / Documents / 请选择目标位置”。该证据证明导出控件已打包、访问日志页布局未被挤破、系统保存选择器可唤起；仍未选择目标位置完成真实文件写入和 JSON 内容回读校验。

2026-06-29 15:07（Asia/Shanghai）访问日志导出文档和审计项补齐后执行 `scripts/run_local_checks.ps1 -SkipMockBuild`，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_150704.md`。`git diff --check`、全局审计、连接分组专项审计和终端解析器测试均 PASS；全局审计为 85/85，连接分组专项审计为 16/16。该轻量复核跳过 HAP 重建，HAP/安装/导出选择器证据以上方 15:02 和 15:03 记录为准。

2026-06-29 15:12（Asia/Shanghai）对齐 Android `ConnectionHistoryActivity` 后新增 `ConnectionHistoryPage` 和工作台“连接历史”入口：基于本地 RDB profile 统计聚合 `lastConnectedAt / connectionCount / lastErrorMessage`，不新增历史表，不记录命令输出或凭据。执行 `scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_151103.md`。最新 Mock HAP 大小 `3,744,036` bytes，SHA256 `F3E19190A6DEF469057340C728FA8A1D417BFDC66BB54217F13CC09FDEA9F54E`；最新 Real HAP 大小 `12,493,820` bytes，SHA256 `5D2FECF509A7D8793A8F6E288B790B2A14589F2521ADEA8385F4A329D7257F0D`。Real HAP 验包确认 arm64-v8a `libentry.so` 大小 `4,500,608` bytes、SHA256 `451CAF5013D6957B575FBF9778B653F8DBEBB2438116106C4F597B067012C0C9`，x86_64 `libentry.so` 大小 `4,556,680` bytes、SHA256 `46127963DBF9FBFCB96B7943899287886F6041BBEED24DE7598F11CA86CCE34B`。

2026-06-29 15:13（Asia/Shanghai）最新 Real HAP `5D2FECF509A7D8793A8F6E288B790B2A14589F2521ADEA8385F4A329D7257F0D` 覆盖安装并冷启动，安装冒烟摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\summary_20260629_151321.md`；x86_64 模拟器启动 PID `10273`，筛选 `hilog` 为 0 行，`faultlogger` exitCode 为 0。随后拉取首页层级 `layout_20260629_151321_home_history_entry.json`，可见“主机列表 / 连接历史 / 连接分组 / 访问日志”；点击“连接历史”后拉取 `layout_20260629_151321_connection_history.json`，可见“连接历史 / 基于本地 RDB 连接统计，不记录命令输出或凭据 / 历史主机 / 成功主机 / 失败记录 / 暂无连接历史”。该证据证明新页面路由、工作台入口、空状态和全屏避让可用；仍未覆盖真实连接成功后历史行、失败行、点击历史行自动进入终端或跨重启统计回显。

2026-06-29 15:16（Asia/Shanghai）连接历史文档和审计项补齐后执行 `scripts/run_local_checks.ps1 -SkipMockBuild`，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_151607.md`。`git diff --check`、全局审计、连接分组专项审计和终端解析器测试均 PASS；全局审计为 87/87，连接分组专项审计为 16/16。该轻量复核跳过 HAP 重建，HAP/安装/连接历史页面层级证据以上方 15:12 和 15:13 记录为准。

2026-06-29 15:21（Asia/Shanghai）对齐 Android `audit_log_menu.xml` 的 Filter 能力后，`AuditLogPage` 新增本地事件筛选芯片：全部、认证成功、认证失败、分组、批量、配置。执行 `scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_151936.md`。最新 Mock HAP 大小 `3,750,366` bytes，SHA256 `854C236B91AE0B2768848048DC88569D2B2D2F15AE12CEC87AB8BB611B62A743`；最新 Real HAP 大小 `12,500,150` bytes，SHA256 `D89DA03877A4A8EF43EB7CEBDC48A0BC6817664CE3E7EB2C568DA8B33B270898`。Real HAP 验包确认 arm64-v8a `libentry.so` 大小 `4,500,608` bytes、SHA256 `451CAF5013D6957B575FBF9778B653F8DBEBB2438116106C4F597B067012C0C9`，x86_64 `libentry.so` 大小 `4,556,680` bytes、SHA256 `46127963DBF9FBFCB96B7943899287886F6041BBEED24DE7598F11CA86CCE34B`。

2026-06-29 15:22（Asia/Shanghai）最新 Real HAP `D89DA03877A4A8EF43EB7CEBDC48A0BC6817664CE3E7EB2C568DA8B33B270898` 覆盖安装并冷启动，安装冒烟摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\summary_20260629_152155.md`；x86_64 模拟器启动 PID `16909`，筛选 `hilog` 为 0 行，`faultlogger` exitCode 为 0。随后进入访问日志页拉取 `layout_20260629_152155_audit_filter.json`，可见“全部 / 认证成功 / 认证失败 / 分组 / 批量 / 配置”和既有“分组变更 / 新增分组”；点击“认证成功”后拉取 `layout_20260629_152155_audit_filter_empty.json`，可见“当前筛选暂无访问日志”。该证据证明筛选芯片已打包、页面布局未被挤破，且无匹配筛选空状态可用；仍未覆盖真实认证成功/失败日志写入后的筛选结果。

2026-06-29 15:26（Asia/Shanghai）访问日志筛选文档和审计项补齐后执行 `scripts/run_local_checks.ps1 -SkipMockBuild`，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_152559.md`。`git diff --check`、全局审计、连接分组专项审计和终端解析器测试均 PASS；全局审计为 88/88，连接分组专项审计为 16/16。该轻量复核跳过 HAP 重建，HAP/安装/访问日志筛选页面层级证据以上方 15:21 和 15:22 记录为准。

2026-06-29 15:40（Asia/Shanghai）对齐 Android `ImportExportActivity` 的安全核心路径后，新增 `ConnectionImportExportService` 和 `ConnectionImportExportPage`：支持 OpenSSH config 导出、OpenSSH config 导入、脱敏 JSON 连接备份导出和脱敏 JSON 连接备份导入；导出不包含密码、私钥文件、私钥口令或命令输出，导入采用非覆盖合并并按主机/端口/用户去重。首次完整检查发现 ArkUI `Row` 不支持 `.minHeight()`，已改为稳定高度；随后 Mock 构建和验包通过，Mock HAP 大小 `3,860,803` bytes，SHA256 `F4B6AC6B9B89019EF9E0236CCE53AAA60BBDC9876E5B229BF2CDAB1F58B30331`。Real 构建前还发现 stage 目录旧 ArkTS 编译缓存深路径导致 PowerShell `Remove-Item` 清理失败，已为 `stage_project_for_build.ps1` 增加三次重试和空目录镜像兜底，避免无人值守构建卡在旧缓存。

2026-06-29 15:43（Asia/Shanghai）修复后执行 `scripts/run_local_checks.ps1 -SkipMockBuild -WithRealCore` 通过 9/9，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_154304.md`；本次摘要中的 Mock 构建按参数跳过，Mock HAP 证据以上方 15:40 为准。最新 Real HAP 大小 `12,610,587` bytes，SHA256 `2DA0DAC44B558F293B6465A9ED8429FB8DDF862EBE5B7CC0F6E2700C0C42C0DA`。Real HAP 验包确认 arm64-v8a `libentry.so` 大小 `4,500,608` bytes、SHA256 `451CAF5013D6957B575FBF9778B653F8DBEBB2438116106C4F597B067012C0C9`，x86_64 `libentry.so` 大小 `4,556,680` bytes、SHA256 `46127963DBF9FBFCB96B7943899287886F6041BBEED24DE7598F11CA86CCE34B`。

2026-06-29 15:44（Asia/Shanghai）最新 Real HAP `2DA0DAC44B558F293B6465A9ED8429FB8DDF862EBE5B7CC0F6E2700C0C42C0DA` 覆盖安装并冷启动，安装冒烟摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\summary_20260629_154431.md`；x86_64 模拟器启动 PID `2546`，筛选 `hilog` 为 0 行，`faultlogger` exitCode 为 0。随后拉取首页层级 `layout_20260629_154431_import_export_home.json`，可见“导入导出”入口；点击进入后拉取 `layout_20260629_154431_import_export_page.json`，可见“导入导出 / 连接配置迁移 / 导出 OpenSSH config / 导入 OpenSSH config / 导出 JSON 连接备份 / 导入 JSON 连接备份”。点击“导出 JSON 连接备份”后拉取 `layout_20260629_154431_import_export_save_picker.json`，可见系统保存界面和默认文件名 `opentabssh-connections-20260629-1545.json`；点击“导入 OpenSSH config”后拉取 `layout_20260629_154431_import_export_select_picker.json`，可见系统文件选择界面“最近 / 浏览 / 已选 (0) / 完成”。该证据证明新页面路由、全屏首屏、导出 picker 和导入 picker 可用；仍未完成选择目标位置后的真实文件写入/回读、真实样本导入落库、跨重启回显、加密 ZIP、云同步、QR 配对或冲突合并。

2026-06-29 15:55（Asia/Shanghai）导入导出文档回填后执行 `scripts/run_local_checks.ps1 -SkipMockBuild`，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_155454.md`。`git diff --check`、全局审计、连接分组专项审计和终端解析器测试均 PASS；全局审计为 92/92，连接分组专项审计为 16/16。该轻量复核跳过 HAP 重建，HAP/安装/导入导出页面层级证据以上方 15:40、15:43 和 15:44 记录为准。

2026-06-29 20:48（Asia/Shanghai）按最新参考图和补充要求完成工作台/工具箱/主题/语言调整后执行 `scripts/run_local_checks.ps1 -WithRealCore`，通过 9/9，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_204618.md`。本轮新增 `ToolboxPage`、`AppSettings`、`AppTheme` 和 `I18n`，工作台右上角改为工具箱入口，工作台主机列表改为直接展示 RDB 已保存主机信息，“我的 / 工具”新增工具箱入口，设置页新增浅色/深色主题和中文/English 语言切换。最新 Mock HAP 为 `E:\Visual_Studio_Code\99_Temp\harmonyos_build\10_Tabssh_harmonyos\entry-default-unsigned.hap`，大小 `4,016,989` bytes，SHA256 `A5630FDA5D9864B0D64FBBB6C88A327DC045BFEDECC2991FFEE0310A68DD04F5`；最新 Real HAP 为 `E:\Visual_Studio_Code\99_Temp\harmonyos_build\10_Tabssh_harmonyos\entry-default-unsigned-real.hap`，大小 `12,766,773` bytes，SHA256 `2E1716B9D25953089496D6CB5CF39A809B64502B2117F4F203E716E3286733C0`。本轮构建前曾发现 ArkTS 静态方法中使用 `this` 会触发 `arkts-no-standalone-this`，已改为直接调用主题常量。

2026-06-29 20:50（Asia/Shanghai）最新 Real HAP `2E1716B9D25953089496D6CB5CF39A809B64502B2117F4F203E716E3286733C0` 覆盖安装并冷启动，安装冒烟摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\summary_20260629_204956.md`；x86_64 模拟器启动 PID `15498`，筛选 `hilog` 为 0 行，`faultlogger` exitCode 为 0。随后 UI hierarchy 复查：首页 `layout_20260629_204956_home_after_reinstall.json` 可见 English/Dark 偏好下的 `Workbench / Host List / Saved SSH hosts / 示例连接 / root@192.168.1.1:22 / Never connected / Connect / Quick Actions`，证明工作台直接渲染已保存主机列表且未跳转连接 Tab；我的页 `layout_20260629_204956_mine_dark_en.json` 可见 `Me / Tools / Toolbox / Network, system, and developer utilities / System Settings / Theme, language, and file preferences`；设置页 `layout_20260629_204956_settings_dark_en_refreshed.json` 可见 `System Settings / Appearance & Language / Language / Theme / Dark / File Management / Storage & Cache / Connection Import / Export`，证明设置页语言刷新问题已由 `@StorageLink` 修复。

2026-06-29 20:21（Asia/Shanghai）同一轮工具箱入口代码在修复设置页刷新前已取得工具箱页面层级证据：从工作台右上角进入 `layout_20260629_202128_toolbox_from_workbench.json`，可见“工具箱 / localhost / 本机IP / 全部 / 网络 / 网络拓扑 / 网络测速 / 系统”；从“我的 / 工具 / 工具箱”进入 `layout_20260629_202128_toolbox_from_mine.json`，可见“工具箱 / localhost / 网络拓扑 / 系统”；滚动后 `layout_20260629_202128_toolbox_fling_direction3.json` 与 `layout_20260629_202128_toolbox_fling_develop_bottom.json` 可见“开发 / JSON工具 / 编码转换 / 二维码工具 / 取色器 / 文本工具箱 / 单位转换”。最终 20:48 HAP 仅针对设置页主题/语言 StorageLink 刷新做后续修正，工具箱入口和页面骨架源码保持同一路径。该证据只证明入口、页面骨架、滚动和 ProIcons rawfile 资源引用可用，不代表网络测速、端口扫描、JSON、编码、二维码、取色、文本或单位转换等具体工具功能完成。

2026-06-29 21:15（Asia/Shanghai）本轮文档回填后执行 `scripts/run_local_checks.ps1 -SkipMockBuild`，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_211520.md`。`git diff --check`、全局审计、连接分组专项审计和终端解析器测试均 PASS；Mock/Real HAP 构建按参数跳过，HAP/安装/页面层级证据仍以上方 20:48、20:50 和 20:21 记录为准。

2026-06-29 21:29（Asia/Shanghai）继续把工具箱从入口骨架推进到首批纯 ArkTS 工具能力：`ToolboxPage` 新增同页工具面板，支持 JSON 格式化/压缩、Base64 编解码、FNV-1a 快速校验、文本统计、颜色转换、单位换算、系统/存储/IP 基础信息和访问审计跳转；未使用三方库。执行 `scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_212714.md`。最新 Real HAP 大小 `12,826,981` bytes，SHA256 `E17E1E87D9762E00603B7DDA6E4C69D7059152309CEBB8F6A2921D1FF4056415`。

2026-06-29 21:30（Asia/Shanghai）最新 Real HAP `E17E1E87D9762E00603B7DDA6E4C69D7059152309CEBB8F6A2921D1FF4056415` 覆盖安装并冷启动，安装冒烟摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\summary_20260629_213016.md`；x86_64 模拟器启动 PID `14776`，筛选 `hilog` 为 0 行，`faultlogger` exitCode 为 0。随后拉取页面层级：首页 `layout_20260629_213016_home_toolbox_tools.json` 仍显示 `Workbench / Host List / Saved SSH hosts / Connect`；工作台右上角进入 `layout_20260629_213016_toolbox_latest.json`，页面路径为 `pages/ToolboxPage`，可见 `Toolbox / localhost / Local IP / Network`；点击 Dev 分类后 `layout_20260629_213016_toolbox_dev_category_latest.json` 可见 `JSON Tool / Encoding / QR Tool / Color Picker / Text Toolbox / Unit Converter`；点击 JSON Tool 后 `layout_20260629_213016_toolbox_json_runner_latest.json` 可见 `JSON Tool / Close / Format / Minify`，并输出格式化 JSON；点击 Encoding 后 `layout_20260629_213016_toolbox_encoding_runner_latest.json` 可见 `Encoding / Base64 Encode / Base64 Decode / Hash`，并输出 `T3BlblRhYlNzaCBIYXJtb255T1M=`。该证据证明工具箱首批纯 ArkTS 工具已打包、安装、可点击并产生结果；仍不代表网络测速、端口扫描、二维码、公网 IP 或网卡枚举完成。

2026-06-29 22:02（Asia/Shanghai）继续用纯 HarmonyOS API 补工具箱网络能力：`@ohos.net.connection` 提供默认网络、链路地址、DNS 和网关摘要，`@ohos.net.socket` 提供 TCP 连通性探测和端口扫描，`@ohos.net.http` 提供 HTTP 下载样本测速，并增加 Nginx 配置摘要解析与 QR 负载摘要。执行 `scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_220235.md`；全局审计为 102/102，连接分组专项审计为 16/16，终端解析器 PASS。最新 Real HAP 为 `E:\Visual_Studio_Code\99_Temp\harmonyos_build\10_Tabssh_harmonyos\entry-default-unsigned-real.hap`，大小 `12,885,465` bytes，SHA256 `047563BB8F223043CDAE3F4105636A34B0E6C37B8A56B96C3A48434FC1E9F44B`。

2026-06-29 22:04（Asia/Shanghai）最新 Real HAP `047563BB8F223043CDAE3F4105636A34B0E6C37B8A56B96C3A48434FC1E9F44B` 覆盖安装并冷启动，安装冒烟摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\summary_20260629_220453.md`；x86_64 模拟器启动 PID `9646`，筛选 `hilog` 为 0 行，`faultlogger` exitCode 为 0。随后拉取页面层级：首页 `layout_20260629_220453_home_before_network_tools.json` 仍可启动；工作台右上角进入 `layout_20260629_220453_toolbox_network_tools.json`，页面路径为 `pages/ToolboxPage`，可见 `Toolbox / localhost / Local IP / Network` 和网络工具卡片；网络拓扑点击结果 `layout_20260629_220453_toolbox_topology_after_center_click.json` 可见 `Network Topology / Refresh`，输出 `Local device -> default network -> saved SSH hosts`、`Saved hosts: 1`、`Default network: Enabled`、`Interface: eth0`、`Link addresses: 10.0.2.15/24`、`Gateway: 10.0.2.2`；滚动到底部 `layout_20260629_220453_toolbox_network_bottom.json` 可见 `Connectivity Test / Port Scan / Network Speed / Nginx Topology / IP Details`；端口扫描 runner `layout_20260629_220453_toolbox_portscan_runner_ready.json` 可见默认输入 `127.0.0.1 22,80,443` 和 `Scan` 按钮，点击后 `layout_20260629_220453_toolbox_portscan_result.json` 输出 `Scan target: 127.0.0.1`、`DNS: 127.0.0.1`、最多 32 端口提示，以及 `22/tcp`、`80/tcp`、`443/tcp` 的 TCP 状态和耗时。该证据证明网络拓扑、默认网络信息和端口扫描已在设备上产生真实结果；HTTP 下载测速、单项 TCP 连通性、Nginx 解析和 QR 负载摘要仍需要逐项点击证据，公网 IP、主动子网发现、上传测速、特权 ICMP、二维码图片矩阵和复杂 Nginx include/变量展开仍未实现。

2026-06-29 22:24（Asia/Shanghai）本轮文档回填后执行 `scripts/run_local_checks.ps1 -SkipMockBuild`，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_222403.md`。`git diff --check`、全局审计、连接分组专项审计和终端解析器测试均 PASS；全局审计为 102/102，连接分组专项审计为 16/16。Mock/Real HAP 构建按参数跳过，HAP/安装/工具箱网络拓扑与端口扫描页面层级证据仍以上方 22:02 和 22:04 记录为准。

2026-06-29 22:29（Asia/Shanghai）继续把主题/语言覆盖扩展到连接历史、终端设置和关于页后执行 `scripts/run_local_checks.ps1 -WithRealCore`，通过 9/9，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260629_222915.md`。Real HAP 大小 `12,902,049` bytes，SHA256 `41BAB0C26C94AE053561E91FF2B94BF518F9E05747F3A808E70AACA9BD90B6D8`。随后覆盖安装并冷启动，安装冒烟摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\summary_20260629_223159.md`；x86_64 模拟器启动 PID `30568`，筛选 `hilog` 为 0 行，`faultlogger` exitCode 为 0。有效 UI hierarchy 使用 `com.open.tabssh` 重新启动后采集：首页 `layout_20260629_223159_tabssh_home_after_i18n_pages.json`、连接历史 `layout_20260629_223159_connection_history_dark_en.json`、我的页 `layout_20260629_223159_mine_dark_en_after_i18n_pages.json`、终端设置 `layout_20260629_223159_terminal_settings_dark_en.json`、关于页 `layout_20260629_223159_about_dark_en.json`。这些证据证明 English/Dark 偏好已进入上述二级页；不代表全部功能页已完成翻译。

2026-06-30 00:49（Asia/Shanghai）继续把主题/语言覆盖扩展到访问日志、连接分组和连接导入导出页后执行 `scripts/run_local_checks.ps1 -WithRealCore`，通过 9/9，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260630_004922.md`；全局审计为 103/103，连接分组专项审计为 16/16，终端解析器 PASS。最新 Mock HAP 大小 `4,184,471` bytes，SHA256 `F5BC956EE8D0A38E641626BA4D9274CB6A91F07696A9E8D513AB1AE9136E971D`；最新 Real HAP 大小 `12,934,255` bytes，SHA256 `E12FD310F41542BBCFD13DDA25D6CD433328C6127DE6EA0A2E7F29C993DA7BD2`。

2026-06-30 00:51（Asia/Shanghai）最新 Real HAP `E12FD310F41542BBCFD13DDA25D6CD433328C6127DE6EA0A2E7F29C993DA7BD2` 覆盖安装并冷启动，安装冒烟摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\summary_20260630_005126.md`；x86_64 模拟器启动 PID `9996`，筛选 `hilog` 为 0 行，`faultlogger` exitCode 为 0。随后强制确认 `com.open.tabssh` 前台后采集 English/Dark UI hierarchy：首页 `layout_20260630_005126_home_after_more_i18n.json`、连接分组 `layout_20260630_005126_connection_groups_dark_en.json`、导入导出 `layout_20260630_005126_import_export_dark_en.json`、访问日志 `layout_20260630_005126_audit_logs_dark_en.json`、连接历史 `layout_20260630_005126_connection_history_dark_en.json`、我的页 `layout_20260630_005126_mine_dark_en_after_more_i18n.json`、终端设置 `layout_20260630_005126_terminal_settings_dark_en.json`、关于页 `layout_20260630_005126_about_dark_en.json`。这些证据只覆盖二级页面主题/翻译和首屏可见性；连接编辑、终端、SFTP、端口转发、系统语言跟随、无障碍和完整点击矩阵仍未完成。

2026-06-30 01:03（Asia/Shanghai）文档回填后执行 `scripts/run_local_checks.ps1 -SkipMockBuild`，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260630_010300.md`。`git diff --check`、全局审计、连接分组专项审计和终端解析器测试均 PASS；全局审计为 103/103，连接分组专项审计为 16/16。Mock/Real HAP 构建按参数跳过，HAP/安装/二级页主题与中英双语页面层级证据仍以上方 00:49 和 00:51 记录为准。

2026-06-30 01:10（Asia/Shanghai）修复底部 Tab 胶囊导航后执行 `scripts/run_local_checks.ps1 -WithRealCore`，通过 9/9，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260630_011030.md`。本轮让底栏背景、边框、未选中图标/文字和阴影跟随浅色/深色主题，并把底栏底部安全距离从 `avoidNavigationBarHeight + 8` 调整为 `avoidNavigationBarHeight + 16`，内容区底部预留调整为 `avoidNavigationBarHeight + 96`，避免底栏与页面底部控件或手势条重叠。全局审计为 103/103，连接分组专项审计为 16/16，终端解析器 PASS。最新 Mock HAP 大小 `4,206,501` bytes，SHA256 `84753CE268462CC2ECEFCA77609F3B73A14B8EF00981CDA4F7AEB491BDF053B8`；最新 Real HAP 大小 `12,956,285` bytes，SHA256 `8648E6C621B600A339B6853BB98022A4C5BAF8D6A6521DCB1B14737054688079`。

2026-06-30 01:12（Asia/Shanghai）最新 Real HAP `8648E6C621B600A339B6853BB98022A4C5BAF8D6A6521DCB1B14737054688079` 覆盖安装并冷启动，安装冒烟摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\summary_20260630_011245.md`；x86_64 模拟器启动 PID `26122`，筛选 `hilog` 为 0 行，`faultlogger` exitCode 为 0。随后采集底栏修复证据：暗色模式层级 `layout_20260630_011245_bottom_nav_dark_after_fix.json` 和截图 `screenshot_20260630_011245_bottom_nav_after_fix.jpeg`，浅色模式层级 `layout_20260630_011245_bottom_nav_light_after_fix.json` 和截图 `screenshot_20260630_011245_bottom_nav_light_after_fix.jpeg`。层级显示底部 Tab 文本 bounds 为 `[151,2716][267,2761]` 等，屏幕底部为 2856，底栏与手势条之间保留清晰距离；截图确认暗色胶囊为深色、浅色胶囊为白色，未选中 Tab 使用主题灰色，激活 Tab 使用蓝色。

2026-06-30 01:42（Asia/Shanghai）按最新要求把第四个 Tab 从“我的”改为“设置”，将设置内容直接展开到主 Tab，移除原“我的”顶部文本与“系统设置”跳转项，并把顶部 Logo/标题区和底部 Tab 区改为半透明模糊背景，让内容可滚动到玻璃层下方。同时新增 `BuildInfo.ets` 与 `scripts/update_build_info.ps1`，Mock/Real HAP 构建脚本会刷新版本号与构建时间，关于页展示版本、构建时间和 Native Core 状态。执行 `scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260630_014021.md`；全局审计为 107/107，连接分组专项审计为 16/16，终端解析器 PASS。最新 Real HAP 大小 `12,999,437` bytes，SHA256 `145DD997852A047D764D495116CAC1F5DA2446707BE56D56B0DFEF0494089A93`，版本 `0.1.0 (1)`，构建时间 `2026-06-30 01:41:20 +08:00`。

2026-06-30 01:44（Asia/Shanghai）最新 Real HAP `145DD997852A047D764D495116CAC1F5DA2446707BE56D56B0DFEF0494089A93` 覆盖安装并冷启动，安装冒烟摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\summary_20260630_014226.md`；x86_64 模拟器启动 PID `17261`，筛选 `hilog` 为 0 行，`faultlogger` exitCode 为 0，安装摘要包含 BuildInfo 校验。随后采集页面层级与截图：首页 `layout_20260630_014256_home_after_glass_overlay_fix.json` / `screenshot_20260630_014256_home_after_glass_overlay_fix.jpeg` 确认顶部与底部半透明玻璃层在位且工作台内容可延伸到下方；设置 Tab `layout_20260630_014322_settings_tab_expanded_glass_final.json` / `screenshot_20260630_014322_settings_tab_expanded_glass_final.jpeg` 可见“设置 / 外观与语言 / 语言 / 主题 / 文件管理 / 存储与缓存”；滚动后 `layout_20260630_014353_settings_tab_scrolled_about_visible_final.json` / `screenshot_20260630_014353_settings_tab_scrolled_about_visible_final.jpeg` 可见终端、工具和关于分组；关于页 `layout_20260630_014422_about_version_build_time_final.json` / `screenshot_20260630_014422_about_version_build_time_final.jpeg` 可见版本和构建时间。本轮曾发现全屏 Header overlay 会吞掉设置 Tab 滚动手势，已通过给空白覆盖层设置透明命中行为修复。

2026-06-30 01:57（Asia/Shanghai）本轮文档回填后执行 `scripts/run_local_checks.ps1 -SkipMockBuild`，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260630_015702.md`。`git diff --check`、全局审计、连接分组专项审计和终端解析器测试均 PASS；全局审计为 107/107，连接分组专项审计为 16/16。Mock/Real HAP 构建按参数跳过，最新 HAP/安装/首页玻璃层、设置 Tab 展开滚动和关于页版本构建时间证据仍以上方 01:42 与 01:44 记录为准。

2026-06-30 07:12（Asia/Shanghai）参考 RustDesk HarmonyOS UI 文档修正主题色板和顶部半透明过渡后，执行 `scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260630_071214.md`。本轮检查覆盖 `git diff --check`、全局审计、连接分组专项审计、终端解析器、Mock 构建/验包和 Real 构建/验包；全局审计为 108/108。最新 Real HAP 为 `E:\Visual_Studio_Code\99_Temp\harmonyos_build\10_Tabssh_harmonyos\entry-default-unsigned-real.hap`，大小 `13,032,652` bytes，SHA256 `34A2CA50560F1BAE9662888216B2E287DC078B8E386A8E7659B954E753FC406C`，构建时间 `2026-06-30 07:13:31 +08:00`。本轮将浅色/深色主题覆盖扩展到 `ConnectionEditPage`、`TerminalPage`、`SftpPage` 和 `PortForwardPage`，并把顶部 Header 从整块毛玻璃改为 `#171A1E` / `#F0F4FA` 多段透明渐变。

2026-06-30 07:14（Asia/Shanghai）最新 Real HAP `34A2CA50560F1BAE9662888216B2E287DC078B8E386A8E7659B954E753FC406C` 覆盖安装并冷启动，安装冒烟摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\summary_20260630_071445.md`；x86_64 模拟器启动 PID `15229`，筛选 `hilog` 为 0 行，`faultlogger` exitCode 为 0。随后采集最终首页层级 `layout_20260630_074325_home_theme_gradient_final.json` 和截图 `screenshot_20260630_074325_home_theme_gradient_final.jpeg`，确认顶部标题区与第一张卡片已分离，顶部为半透明渐变过渡，底部 Tab 胶囊仍为半透明玻璃且保留手势条避让。该证据只覆盖首页视觉与安装启动，不代表主题/语言跨重启矩阵、复杂终端 TUI、真实 SSH/SFTP/转发或 arm64 真机完成。

2026-06-30 07:51（Asia/Shanghai）文档回填后执行 `scripts/run_local_checks.ps1 -SkipMockBuild`，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260630_075124.md`。`git diff --check`、全局审计、连接分组专项审计和终端解析器测试均 PASS；Mock/Real HAP 构建按参数跳过，最新 HAP/安装/首页顶部渐变截图证据仍以上方 07:12 与 07:14 记录为准。

2026-06-30 15:16（Asia/Shanghai）拉取远端新增 GitHub Actions 后，修正 `.github/workflows/build-harmonyos.yml` 的 action 版本、SDK patch 构建入口、BuildInfo 刷新、HAP/SHA256/包清单产物、可选 HAP 包校验、Release 版本来源和 Release 资产集，并把 `online-build.yml`、`build-harmonyos.yml`、`test-harmonyos-sdk-token.yml`、`cleanup-releases.yml` 纳入全局审计与文档。四个 workflow 已用 `js-yaml` 完成 YAML 解析检查；随后执行 `scripts/run_local_checks.ps1 -SkipMockBuild`，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260630_151638.md`。`git diff --check`、全局审计、连接分组专项审计和终端解析器测试均 PASS，全局审计为 117/117；Mock/Real HAP 构建按参数跳过，本轮只证明 workflow、脚本和文档静态一致，不代表线上 run、HAP 构建或 Release 已成功。

2026-06-30 15:28（Asia/Shanghai）按最新视觉反馈收紧首页顶部与 Logo 区默认间距：`HeaderOverlay` 从 `avoidStatusBarHeight + 104` 收到 `avoidStatusBarHeight + 76`，Header 行高与顶部 padding 同步缩小，内容顶部从 `headerOverlayHeight() - 14` 起步，让第一张卡片进入半透明渐变尾部但不遮挡状态栏、Logo 或标题。执行 `scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260630_152622.md`。最新 Real HAP 为 `E:\Visual_Studio_Code\99_Temp\harmonyos_build\10_Tabssh_harmonyos\entry-default-unsigned-real.hap`，大小 `13,032,652` bytes，SHA256 `9E2394A128527539E263F9C8CF35DB5954B2CCFBD609D66DD064634D5A95BB5A`，构建时间 `2026-06-30 15:27:27 +08:00`。随后覆盖安装并冷启动，安装冒烟摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\summary_20260630_152837.md`；x86_64 模拟器启动 PID `6767`，筛选 `hilog` 为 0 行，`faultlogger` exitCode 为 0。最终采集首页层级 `layout_20260630_152837_home_top_tighter.json` 和截图 `screenshot_20260630_152837_home_top_tighter.jpeg`，确认顶部 Logo/标题区已贴近安全区、第一张主机卡片上移且未与标题重叠。该证据只覆盖首页顶部间距、构建验包、安装和冷启动，不代表 SSH/SFTP/端口转发、主题/语言完整矩阵或 arm64 真机完成。

2026-06-30 15:34（Asia/Shanghai）文档和审计回填后执行 `scripts/run_local_checks.ps1 -SkipMockBuild`，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260630_153411.md`。`git diff --check`、全局审计、连接分组专项审计和终端解析器测试均 PASS；全局审计为 118/118，其中新增 `header-compact-spacing` 检查锁定顶部紧凑间距。Mock/Real HAP 构建按参数跳过，最新 HAP、安装和首页顶部截图证据仍以上方 15:28 记录为准。

2026-06-30 15:43（Asia/Shanghai）继续补主题/语言验收缺口，新增“系统 / 中 / EN”语言分段：`AppSettings.ets` 使用纯 HarmonyOS `@ohos.i18n` 的首选语言列表、系统语言和系统 locale 解析系统语言，并把 `system` 偏好归一到中文/English；`I18n.ets` 在渲染时解析有效语言。执行 `scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260630_154054.md`；全局审计为 119/119，其中新增 `language-system-follow` 检查。最新 Real HAP 大小 `13,039,728` bytes，SHA256 `A54EDDE5C4338B393952875A4BACA1AFD7A8D2E67ECBB5845F9A03823053DFED`，构建时间 `2026-06-30 15:42:00 +08:00`。随后覆盖安装并冷启动，安装冒烟摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\summary_20260630_154312.md`；启动 PID `17370`，筛选 `hilog` 为 0 行，`faultlogger` exitCode 为 0。进入设置 Tab 后采集 `layout_20260630_154312_settings_system_language_2.json` / `screenshot_20260630_154312_settings_system_language_2.jpeg`，可见语言行包含“系统 / 中 / EN”；点击“系统”后采集 `layout_20260630_154312_settings_system_language_selected.json` / `screenshot_20260630_154312_settings_system_language_selected.jpeg`，可见“跟随系统 · 简体中文”。强停重启后 PID `17427`，再次进入设置 Tab 拉取 `layout_20260630_154312_settings_system_language_after_restart.json`，仍可见“跟随系统 · 简体中文 / 系统 / 中 / EN”。该证据证明系统语言跟随选项、中文系统解析和偏好跨重启回显可用；仍不代表完整多页面语言切换矩阵、无障碍/高对比、动态 service/audit 文案或 arm64 真机完成。

2026-06-30 15:52（Asia/Shanghai）文档回填后执行 `scripts/run_local_checks.ps1 -SkipMockBuild`，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260630_155235.md`。`git diff --check`、全局审计、连接分组专项审计和终端解析器测试均 PASS；全局审计为 119/119。Mock/Real HAP 构建按参数跳过，最新 HAP、安装、系统语言点击和强停重启证据仍以上方 15:43 记录为准。

2026-06-30 16:06（Asia/Shanghai）继续按在线检查反馈压缩首页顶部 Logo/标题区默认距离，并补齐工具箱 IP 详情的公网 IP 查询。主壳 `HeaderOverlay` 改为 `headerStatusInset() + 64`，状态栏占位为 `avoidStatusBarHeight - 10`，内容顶部从 `headerOverlayHeight() - 12` 起步；`ToolboxPage` 使用纯 HarmonyOS `@ohos.net.http` 请求 HTTPS 文本服务，解析 IPv4/IPv6 后输出公网 IP、来源、HTTP 状态和默认网络状态，不在文档中记录实际出口地址。执行 `scripts/run_local_checks.ps1 -WithRealCore` 通过 9/9，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260630_160407.md`；全局审计为 120/120，其中新增 `toolbox-public-ip` 并更新 `header-compact-spacing`。最新 Real HAP 大小 `13,048,399` bytes，SHA256 `254DD95BD808D3E02CCB2608D6F556100F736107B4E08CCEADDA709F6DB8ABAA`，构建时间 `2026-06-30 16:05:11 +08:00`。随后覆盖安装并冷启动，安装冒烟摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\install_smoke\summary_20260630_160625.md`；启动 PID `2098`，筛选 `hilog` 为 0 行，`faultlogger` exitCode 为 0。首页层级 `layout_20260630_160625_home_header_tightest.json` 和截图 `screenshot_20260630_160625_home_header_tightest.jpeg` 显示“工作台”标题 bounds 为 `[596,141][827,231]`，较上一轮继续贴近顶部；工具箱层级 `layout_20260630_160625_toolbox_open.json` 可见 `工具箱 / IP详情`，`layout_20260630_160625_toolbox_ip_details_open.json` 可见 `公网 IP` 按钮，点击后 `layout_20260630_160625_toolbox_public_ip_result_attempt1.json` 和 `screenshot_20260630_160625_toolbox_public_ip_result.jpeg` 显示 `公网 IP：<redacted> / 来源：https://ifconfig.me/ip / HTTP 200 / 默认网络：已开启`。该证据只覆盖单台 x86_64 模拟器的公网 IP 文本服务查询、首页顶部间距、构建验包、安装和冷启动，不代表主动子网发现、上传测速、特权 ICMP、二维码图片矩阵、复杂 Nginx 展开、arm64 真机或发布签名完成。

2026-06-30 16:16（Asia/Shanghai）文档回填后执行 `scripts/run_local_checks.ps1 -SkipMockBuild`，摘要为 `E:\Visual_Studio_Code\99_Temp\tabssh_harmonyos_logs\local_checks\summary_20260630_161652.md`。`git diff --check`、全局审计、连接分组专项审计和终端解析器测试均 PASS；全局审计为 120/120。Mock/Real HAP 构建按参数跳过，最新 HAP、安装、首页顶部截图和公网 IP 设备证据仍以上方 16:06 记录为准。

## 当前必须补的新证据

- GitHub Actions `测试 HarmonyOS SDK Token`、`TabSSH Linux HAP 4-package build` 和 `构建并发布 HarmonyOS HAP` 的线上 run、artifact、SHA256、HAP 文件列表和可选 Release 结果。
- 工具箱剩余真实工具能力证据：网络拓扑、默认网络信息、端口扫描和公网 IP 已取得 Real HAP 设备输出；仍需补 HTTP 下载测速、单项 TCP 连通性、Nginx 摘要、QR 负载摘要的点击证据，以及主动子网发现、上传测速、特权 ICMP 或等价说明、二维码图片矩阵/美化、更多网卡字段和复杂 Nginx include/变量展开。JSON、Base64/Hash、文本统计、颜色转换、单位换算和系统/存储/IP 基础信息已有首批设备证据。
- 主题/语言全局覆盖证据：关于、终端设置、连接历史、访问日志、连接分组、连接导入导出、连接编辑、终端、SFTP 和端口转发均已接入浅色/深色和中文/English；系统语言跟随已在设置 Tab 完成点击和强停重启回显；仍需验证多页面切换即时刷新、系统栏颜色、全屏避让不冲突、无障碍/高对比和完整点击矩阵。
- 工作台内联主机列表设备证据：新增/编辑/删除/收藏主机后，工作台列表能直接刷新并显示正确主机、用户、端口、状态和连接按钮，不再通过“主机列表”动作切到连接 Tab。
- 首页分组入口/分组筛选的设备点击流程：进入 `ConnectionGroupPage`、新增、改名、折叠/展开、返回刷新和筛选生效。
- RDB 跨重启设备证据：新增分组和分组变更摘要已通过基础重启回显；仍需补改名、换色、折叠、收藏、统计、异常恢复和 schema migration。
- 连接页批量模式逐项点击证据：选择、全选当前、清空选择、批量收藏、批量移组、批量删除和退出批量模式。
- 搜索高亮设备证据：名称、主机、用户、备注命中均能正确高亮，且不破坏列表布局。
- 访问日志跨重启和真实连接证据：分组变更摘要已通过基础重启回显，导出保存选择器可唤起，事件筛选空状态已通过；仍需补认证成功/失败、批量操作、清空、真实文件写入/回读和隐私字段落库审计。
- 连接历史真实数据证据：成功/失败连接后历史页显示正确时间、次数、错误摘要，点击历史行能进入对应终端，重启后统计仍正确。
- 连接导入导出证据：真实保存目标写入/回读 OpenSSH config 与 JSON 内容，真实 OpenSSH/JSON 样本导入落库，导入后跨重启回显，重复导入去重，IdentityFile 警告，加密 ZIP/QR/同步方案。
- 全屏避让矩阵证据：单台 x86_64 模拟器多页无凭据抽样已通过；仍需补不同分辨率、横竖屏、手势导航、挖孔、软键盘和终端长会话场景。
- 最新 ProIcons 资源包的逐页图标渲染证据；本轮只证明资源能随 HAP 编译安装和首屏入口文本可见。
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
