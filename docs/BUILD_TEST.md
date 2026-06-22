# 构建与测试要求

## 基线命令

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\audit_project.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_mock_hap.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_mock_hap.ps1
```

脚本先复制干净副本到 `99_Temp\harmonyos_stage\10_Tabssh_harmonyos`，所有 Hvigor、CMake 和 native 产物在该副本内生成，再复制最终 HAP/APP 到 `99_Temp\harmonyos_build\10_Tabssh_harmonyos`。仓库根不得产生 build、`.cxx` 或日志。

2026-06-22 02:34（Europe/Berlin）重要修改回归：含 HostKey UI 和基础 ANSI/VT 网格的 Mock fallback HAP `entry-default-unsigned.hap` 为 `3,099,325` bytes / SHA256 `1CF2D83204AE61D10B08C1C003D9C90CE0E78807A59C7CB885F1A4C2D7C478AB`；包内四个双 ABI native entries 通过 ELF 检查。该包随后成功覆盖安装到 `127.0.0.1:5555` x86_64 模拟器，Bundle `com.open.tabssh`、版本 `0.1.0 / 1`、`updateTime=1782092052465`，冷启动 PID `21653`，筛选 `com.open.tabssh|OpenTabSsh|FATAL|Fatal|cppcrash` 得到 0 行。模拟器报告 `appProvisionType=debug`、`appSignType=none`；这只证明 Mock fallback 的安装/冷启动，不是签名发布证据，也不是任何真实 SSH 功能证据。

同一安装包完成无凭据 UI hierarchy 冒烟：首页 → 连接 → 示例连接 → Terminal；页面明确显示“Mock 已连接（非真实 SSH）”，基础终端网格正确呈现 Mock banner，并在输入 `pwd` 后显示 `/home/opentabssh`；关闭终端后返回 `pages/Index`，进程保持存活。该检查只验证 UI、轮询、基础控制字符解析和 Mock 会话清理，不验证 ANSI 颜色/复杂 xterm 行为或真实网络。

2026-06-22 06:55（Europe/Berlin）真实 Core 首次构建/安装：`entry-default-unsigned-real.hap` 为 `11,566,708` bytes / SHA256 `6E47A6C7FAB84214210D959F7CFE3088BCF937B7E90E56F9A65B7536429F6A4E`。其中 arm64-v8a `libentry.so` 为 `4,363,464` bytes / SHA256 `A796B05DCC1E1C7D0A3EDDECF10D291B650A45ED5E2BDF07E02B071C84F3551F`，x86_64 为 `4,417,528` bytes / SHA256 `F79F87F2EC8FA833BF01D977A38F32D14CF89F49F451D1DA9B53F9974A2AFD1D`；两者 machine 与 `real-ssh/libssh2` marker 通过，且不含 Mock shell marker。该包成功覆盖安装并冷启动于 `127.0.0.1:5555` x86_64 模拟器，`updateTime=1782107735827`、PID `27063`、筛选加载/崩溃日志 0 行。它证明双架构真实 Core 可链接、打包、加载和冷启动；在获得真实 HostKey/认证/shell/SFTP/流量证据前仍不代表网络功能完成。

2026-06-22 07:05（Europe/Berlin）加入应用私有目录私钥导入和窗口隐私保护后再次构建并覆盖安装真实包：`entry-default-unsigned-real.hap` 为 `11,578,032` bytes / SHA256 `A38EFE5FD4C6B67096412BEDBCF04A057EC76ADA55A0BCC9931F0BA12EB24EB7`，双 ABI real marker/machine 复验通过；x86_64 模拟器返回 `install bundle successfully`，Bundle `com.open.tabssh`、版本 `0.1.0 / 1`、`updateTime=1782108374943`。本条仅证明新包安装成功；私钥选择、真实 HostKey/认证/shell/SFTP 仍须随后取得端到端证据。

2026-06-22 07:13（Europe/Berlin）模拟器运行时测试发现编辑页返回后连接列表未刷新，补充 `onPageShow` 重载后再次构建/验包/覆盖安装：真实 HAP `11,578,318` bytes / SHA256 `9D7C75BC498547463EBEF319FE1A06F8505F758B84A065A5C5386704CCDB9DB3`，双 ABI native 哈希保持不变，安装成功且 `updateTime=1782108829995`。密码只在测试进程和应用内存输入，未写入本证据或任何落盘日志。

2026-06-22 07:20（Europe/Berlin）首次使用真实网络配置点击连接时，系统生成 `APP_INPUT_BLOCK`：主线程栈明确停在 `libentry.so -> opentabssh::Connect -> libace_napi`，约 6 秒后进程被终止。因此本次没有取得 HostKey、认证或 PTY 成功证据，且不能把 Core 内部的 nonblocking socket 写成 UI 非阻塞。故障原始记录仅保存在 `99_Temp\tabssh_harmonyos_logs`，不进入仓库且不含测试密码。

随后已把 `connect`、`openShell` 和 `sftpList` N-API 改为后台 async work / Promise，并让 Terminal 页面先渲染“正在连接”状态后异步等待 HostKey。暂停前 Mock HAP 已构建成功（`3,128,166` bytes / SHA256 `7059161CD44D54210B11DE66512BF4258A034B2690F1BBBA1FDF61852E5AE95F`）；真实 HAP 已构建并通过双 ABI real-marker/machine 验证（`11,587,958` bytes / SHA256 `4C6FDDBCF104BC926C2870D1BFB5AEEDD5AB476C26CB34294477EC64880E7A80`，arm64 native SHA256 `CFE61E49666FDE1C442BD47C316F14E60E24B554F0FB8AA0CFDA72EC64B39E67`，x86_64 native SHA256 `8E83489C6DBC242F64A5908AB157DD195381CA6A8183BE592B1611C8197252B6`）。应用户关机请求，此包尚未安装，异步连接修复尚未取得设备回归证据。

## 设备验证

未来真实 Core HAP 必须分别安装到 arm64 真机和 x86_64 模拟器，核对 SHA256、mtime、版本、双 ABI、设备 `updateTime`、冷启动 PID 和安全筛选后的 hilog；正式发布仍必须使用独立签名。测试凭据只在运行内存输入；不保存原始含敏感字段日志。

## 最终收口

每次重要修改和最终版本执行一次完整审计、全量构建、双设备安装，以及真实 SSH、终端、SFTP、转发、错误恢复和断开清理检查。任何功能源码、Native 依赖或构建配置变化都会使旧 HAP 哈希和设备证据失效。
