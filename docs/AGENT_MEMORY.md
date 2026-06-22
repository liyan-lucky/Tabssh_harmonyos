# 长期维护约束

- 项目当前是 Mock SSH 骨架，真实功能状态以 `AGENT_HANDOFF.md` 和 `PROGRESS.md` 为准。
- 所有构建、测试、日志、下载、备份和临时证据统一到 `%VSCODE_ROOT%\99_Temp` 的 TabSSH 专属子目录。
- `99_Temp` 为多项目共享；任何 APK 永不清理，TabSSH 脚本不得触碰 RustDesk 或其他项目目录。
- 不在源码、日志、文档、截图、备份说明和提交说明中保存凭据。
- 同版本不代表同产物；未来 HAP 必须同时核对 SHA256、mtime、BuildInfo、双 ABI、设备 updateTime 和安全筛选后的 hilog。
- 每次重要修改同步文档，并执行一次完整审计、构建与相关功能检查；新项目不要求重复多轮审计。
