# 当前任务交接入口

> 建立时间：2026-06-22（Europe/Berlin）

## 当前事实

项目根为 `%VSCODE_ROOT%\10_Tabssh_harmonyos`，GitHub 目标为 `https://github.com/liyan-lucky/Tabssh_harmonyos.git`，默认分支 `main`。实际应用 Bundle 为 `com.open.tabssh`，版本 `0.1.0 / 1`，Native 模块为 `libentry.so`，ABI 配置为 arm64-v8a 与 x86_64。

当前 Core 是 `native_ssh_mock.cpp`。页面、N-API 函数表和 Mock 会话已存在；真实 libssh2、认证、HostKey、终端模拟器、SFTP、转发、持久化、安全存储、重连和完整资源清理均未完成。禁止把 Mock 行为写成真实 SSH 已完成。

2026-06-22 基线验证：单次静态审计 29 PASS / 0 FAIL；仓库外 stage 构建成功，unsigned HAP 为 `3,048,665` bytes / SHA256 `49CDE90FDD94C0623FF7A65107C112E519C9B732DA0842FC40288D6386471829`，包含 arm64-v8a/x86_64 两套 `libentry.so` 与 `libc++_shared.so`。尚未配置独立签名，因此未做安装验证。

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
