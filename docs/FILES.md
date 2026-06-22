# 文件职责

- `AppScope/`：Bundle、版本和应用资源。
- `entry/src/main/ets/pages/`：七个 ArkUI 页面。
- `entry/src/main/ets/common/`：模型、Native 包装、会话管理和内存仓库。
- `entry/src/main/cpp/`：N-API、Mock Core 与 libssh2 实现入口。
- `docs/`：权威接力、架构、路径、测试和历史资料。
- `scripts/`：stage、构建、审计、清理和备份；输出必须进入 `99_Temp`。
- `.github/workflows/online-build.yml`：托管 runner 静态审计，以及受控 `tabssh-deveco` runner 的手动真实 HAP 构建。
- `entry/src/main/ets/common/terminal/`：基础 ANSI/VT 字符网格；当前不是完整 xterm 模拟器。
- `reports/`：可提交的无敏感信息审计摘要；原始日志不入仓库。
- `docs/UPSTREAM_REFERENCES.md`：外部 Web/Android/Desktop 参考仓库的路径、commit 与用途。

`FILE_LIST.txt` 属于易过期的手工快照，不再使用；以后以 Git 文件树和本文为准。
