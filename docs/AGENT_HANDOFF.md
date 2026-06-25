# 当前任务交接入口

> 更新时间：2026-06-26。当前所有已完成的项目改动已经应用到 `main`，PR #1 已 merged/closed。后续默认直接在 `main` 上继续开发和更新文档。

## 当前事实

项目根为 `%VSCODE_ROOT%\10_Tabssh_harmonyos`，GitHub 目标为 `https://github.com/liyan-lucky/Tabssh_harmonyos.git`，默认分支 `main`。实际应用 Bundle 为 `com.open.tabssh`，版本 `0.1.0 / 1`，Native 模块为 `libentry.so`，ABI 配置为 arm64-v8a 与 x86_64。

默认无三方库的构建仍是 `native_ssh_mock.cpp`。固定版本 libssh2/OpenSSL/zlib 双架构静态库与 manifest 已构建，真实 Core HAP 已完成双 ABI 验包并在 x86_64 模拟器加载；HostKey/密码认证/PTY/命令/SFTP 列目已有外部服务器证据，SFTP 写操作已有隔离回环端证据。完整 xterm、三类转发、持久化、HUKS/ASSET、私钥认证与 arm64 真机仍未完成。禁止把源码存在、加载成功、Mock 行为或函数返回写成真实 SSH 已完成。

当前首页连接页已保持现有浅蓝背景、白色圆角卡片、蓝色芯片和悬浮胶囊底栏风格，接入搜索、收藏筛选、排序芯片、收藏切换、连接次数和上次失败提示。该 UI 已编码但尚未取得最新 HAP 编译和设备渲染证据。

`docs/PULL_TEST_GUIDE.md` 已改为直接拉取 `main`。`docs/GIT_PUBLISH.md` 已记录用户允许直接操作 `main`。后续如需继续对齐 Android 版，应优先补：RDB 持久化、分组编辑 UI、私钥认证、端口转发真实流量、终端复杂 TUI 设备证据、SFTP 大文件/取消/恢复和 arm64 真机验收。

## 当前必须补的新证据

- 运行 `scripts/run_local_checks.ps1` 后生成的 `summary_*.md` 结论。
- 运行 `scripts/install_and_smoke.ps1` 后生成的 `summary_*.md` 结论。
- 最新首页连接筛选 UI 的 HAP 构建、安装、搜索/收藏/排序点击和页面渲染证据。
- 最新 ProIcons 资源包的 HAP 构建、安装和页面渲染证据。
- 最新终端 Span 渲染、复制、视口 resize、复杂 TUI 和性能证据。
- 三类端口转发真实 HAP 的逐字节流量证据。
- SFTP 大文件、取消和中断恢复证据。
- arm64 真机真实 SSH 端到端证据。

## 第一执行序列

1. 完整读取本文件，再按 `docs/README.md` 顺序阅读。
2. 执行 `git status --short --branch` 和完整 diff，确认当前在 `main`。
3. 执行 `scripts/audit_project.ps1`，再用 `scripts/build_mock_hap.ps1` 在 `99_Temp` stage 中验证基线。
4. 真实功能优先级：libssh2 双架构 → HostKey/认证安全 → shell/PTY 非阻塞读写 → 终端渲染 → SFTP → local/remote/dynamic forwarding → 重连与断开清理。
5. 每次重要修改和最终发布前各运行一次完整审计、构建、安装与相关功能检查，并立即同步所有相关文档。

## 安全与清理规则

- 密码、私钥、私钥口令、token 和服务器凭据只允许存在测试运行内存，禁止写入源码、日志、文档、截图、备份说明或提交说明。
- `%VSCODE_ROOT%\99_Temp` 是多项目共享目录，只能使用 `docs/WORKSPACE_PATHS.md` 列明且明确归属本项目的可再生目录。
- 不在仓库根保留 `.hvigor`、`.cxx`、build、崩溃转储、IDE/AI 工具缓存或散落日志。
- 应用图标只能使用 `docs/PROICONS_ICONS.md` 登记的 ProIcons 资产，禁止新增自绘 SVG、Emoji 或字符图标。

## 文档同步规则

每轮修改代码、脚本、资源、构建流程或测试流程后，必须同步更新相关文档。新增文件写入 `docs/FILES.md`，测试路径写入 `docs/PULL_TEST_GUIDE.md` 或 `docs/BUILD_TEST.md`，风险写入 `docs/ISSUES.md`，状态变化写入 `docs/PROGRESS.md`。`docs/BUILD_TEST.md` 只能追加或补充，不能覆盖历史 HAP 哈希、故障栈和设备证据。
