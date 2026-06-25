# 已知问题与风险

## P0：真实 SSH 端到端尚未通过

源码 checkout 没有生成的三方静态库时，CMake 明确编译 `native_ssh_mock.cpp`。固定三方库和真实 Core 双 ABI HAP 已完成构建、链接、验包和 x86_64 冷启动，密码认证/PTY/SFTP 已有端到端证据；私钥、arm64 真机和端口转发仍阻塞生产使用。端口转发 UI 已禁用 Mock 成功提示。

2026-06-22 首次真实连接暴露同步 N-API 主线程卡死，系统以 `APP_INPUT_BLOCK` 终止进程。现有网络与 SFTP 操作均已迁移到后台 async work，x86_64 模拟器没有新增 faultlogger 记录；用户取消正在进行的 native async work 仍需实现。

read/write/resize/close/disconnect 现也已迁移到 async work，并在外部 Windows OpenSSH 完成命令、SFTP、关闭和再次连接回归；已知旧 appfreeze 没有复现。尚未实现用户取消正在进行的 native async work，极端慢服务器下的任务终止仍是风险。

三类转发 worker 已编码但尚无 HAP/设备流量证据。重点风险是同一 libssh2 session 上终端、SFTP 与多个转发 channel 的并发、公网 sshd 是否允许 remote forward、SOCKS5 半关闭、端口占用和断开竞态；必须以真实 TCP 回显/哈希、监听地址和断开后端口释放分别验收。

重连退避和 HarmonyOS `NetConnection` 网络状态观察器已编码，但尚未经过 Hvigor/HAP 与设备验证。需验证权限/API 兼容、用户关闭、HostKey 变化、认证失败、正常 EOF、前后台切换、网络回调丢失兜底和断网恢复不会产生重连风暴或资源泄漏。

2026-06-22 SFTP 系统文档选择器的“保存”界面在当前 x86_64 自动化模拟器上出现 Promise 未返回且界面未显示；已通过应用私有缓存中的受限文本上传→下载回读完成核心数据校验，但系统保存选择器还需真机手工验证和取消/超时处理。

## P0：凭据与 HostKey 安全

密码、私钥和口令不能进入源码或普通首选项。HostKey 首次信任/变更警告已编码；私钥文件可导入应用私有目录并删除，但长期凭据仍需 HUKS/ASSET 安全存储。初始源码中的示例密码已移除。

## P1：文档与配置曾不一致

旧 README 写 `io.github.opentabssh`，实际 `build-profile.json5` 与 `AppScope/app.json5` 均为 `com.open.tabssh`；现已统一，以构建配置为准。

2026-06-25 经验规则：每轮新增或修改脚本、Native、ArkTS 页面、资源、构建流程后，必须同步更新至少一个状态文档。最低要求：新增文件写入 `docs/FILES.md` 或 `scripts/README.md`；新增测试流程写入 `docs/PULL_TEST_GUIDE.md` 或 `docs/BUILD_TEST.md`；发现风险写入本文件；完成/待验状态写入 `docs/PROGRESS.md`。不能只改代码不更新文档。

## P1：仓库内生成产物

初始目录含 build、`.cxx`、Hvigor/IDE/AI 缓存和崩溃转储。首次提交前按 `WORKSPACE_PATHS.md` 清理，后续只能在 `99_Temp` stage 构建。

2026-06-23 当前受限执行环境只允许写项目根，无法创建/替换 `99_Temp` stage。仓库内既有的 `entry/build` 与 `entry/.cxx` 已通过新增的 `scripts/clean_project.ps1 -BuildOnly` 安全清理，静态审计恢复为 45/45；ProIcons 替换尚未产生新 HAP。恢复具备 `99_Temp` 写权限的会话后必须执行 Mock/真实构建和模拟器安装。

## P1：安装/冷启动冒烟不能替代功能验收

2026-06-25 新增 `scripts/install_and_smoke.ps1`，用于安装 HAP、启动 `com.open.tabssh`、记录 bundle dump/PID、过滤 hilog/faultlogger 基础异常线索。该脚本只证明 HAP 能安装和冷启动，不能证明 SSH、SFTP、端口转发、重连、签名或发布质量。经验总结：安装冒烟摘要可以提交结论，但原始 hilog 可能包含设备隐私、路径或服务器线索，提交前必须脱敏；不要把 `install_and_smoke.ps1` 的 PASS 当作真实 SSH 通过。

## P1：本地一键检查的边界

2026-06-25 新增 `scripts/run_local_checks.ps1`，用于串联 `git diff --check`、静态审计、终端解析器测试、Mock 构建/验包和可选真实 HAP 构建/验包。它减少人工漏跑脚本，但仍不能替代设备端操作、真实服务器流量、SFTP 哈希、转发逐字节验证和长时间重连压力测试。经验总结：一键脚本失败时优先看 `99_Temp\tabssh_harmonyos_logs\local_checks\summary_*.md`，只贴无敏感信息片段。

## P1：ProIcons 资源验证

ProIcons SVG 必须保持标准 XML 且不得含重复属性；浏览器可显示不代表 HarmonyOS 资源编译器一定接受。`scripts/audit_project.ps1` 已阻止旧自绘 `tab_*.svg` 和已知 Emoji/字符图标，完整映射见 `PROICONS_ICONS.md`。当前 28 个使用中的 SVG 已通过 XML 解析，设备渲染仍须由下一次 HAP 构建安装确认。

## P1：终端渲染仍缺设备编译与性能证据

终端样式渲染使用 ArkUI `Text`/`Span` 动态 runs；解析器内存测试不能替代 ArkUI DSL 编译和设备性能测试。恢复 `99_Temp` 写权限后要先构建，再以长彩色输出、CJK/Emoji、vim/tmux/htop/nano、备用屏进退、复制和窗口 resize 回归；若单个 `Text` 的 2,000 行样式 runs 出现卡顿，应改为可视区域虚拟化，而不是缩短历史后声称兼容。

## P1：签名尚未配置

当前基线产物是 unsigned HAP，已验证双 ABI 包内容但不能作为安装/发布证据。后续应为 `com.open.tabssh` 配置独立签名材料，存放在 `99_Temp` 的项目专属目录并保持 Git 忽略；不得复用或提交其他项目的签名口令。

用户曾通过 DevEco Studio 构建，但当前仓库配置没有可提交的签名项；这属于正确状态。首次提交扫描未发现证书、私钥或签名口令，未来也必须保持如此。

2026-06-22 x86_64 模拟器接受并安装了 `appProvisionType=debug / appSignType=none` 的 Mock fallback HAP；这不改变正式发布需要独立签名的要求，也不能外推到 arm64 真机。
