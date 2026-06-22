# Android TabSSH 到 HarmonyOS OpenTabSsh 映射

> 2026-06-22：本文是目标映射，不代表全部实现。当前完成度以 `AGENT_HANDOFF.md` 和 `PROGRESS.md` 为准；构建测试路径以 `WORKSPACE_PATHS.md` 为准。

| Android 组件 | HarmonyOS 方案 |
|---|---|
| MainActivity | `pages/Index.ets` |
| ConnectionEditActivity | `pages/ConnectionEditPage.ets` |
| TabTerminalActivity | `pages/TerminalPage.ets` + `TerminalSessionManager.ets` |
| SFTPActivity | `pages/SftpPage.ets` |
| PortForwardingActivity | `pages/PortForwardPage.ets` |
| SettingsActivity | `pages/SettingsPage.ets` |
| SSHConnection / JSch | `entry/src/main/cpp/native_ssh_*` + libssh2 |
| SSHSessionManager | `TerminalSessionManager.ets` + native session map |
| TermuxBridge / TerminalEmulator | 后续自研 ANSI/VT 解析和终端渲染 |
| Room DB | 后续换成 RDB Store |
| Android Keystore | 后续换成 HUKS / ASSET |
| WorkManager | 后续换成 HarmonyOS 后台任务能力 |
| AppWidgetProvider | 后续换成 FormExtensionAbility |
