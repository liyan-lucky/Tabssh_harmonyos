# OpenTabSsh 文档索引

## 新接手必读顺序

1. `CURRENT_STATUS.md`：当前仓库事实、功能边界、分支/备份策略和合规边界。
2. `AGENT_HANDOFF.md`：当前事实、边界和第一执行序列。
3. `WORKSPACE_PATHS.md`：唯一允许的构建、测试、日志、备份和清理路径。
4. `PROGRESS.md`：已实现与未实现功能。
5. `ANDROID_TO_HARMONY_MAPPING.md`：Android 版能力矩阵和当前 HarmonyOS 对齐状态。
6. `ANDROID_PARITY_ROADMAP.md`：Android 功能对齐路线图和优先级。
7. `CORE.md`：Mock/真实 Native Core 架构和安全要求。
8. `BUILD_READY.md`：当前 `main` 是否可以进入构建测试，以及本轮优先验证项。
9. `BUILD_TEST.md`：构建、设备验证和单次完整验收规则。
10. `PULL_TEST_GUIDE.md`：拉取 `main` 后的 Mock、真实 Core、SFTP、转发和重连测试步骤。
11. `CONNECTION_GROUP_TEST.md`：连接编辑页分组选择、连接分组页和专项审计测试步骤。
12. `ISSUES.md`：已知问题与风险。
13. `FILES.md`、`UI.md`：文件职责与页面结构。
14. `PROICONS_ICONS.md`：唯一允许的图标来源、映射和审计规则。
15. `UPSTREAM_REFERENCES.md`：TabSSH Web/Android/Desktop 上游参考源码。
16. `GIT_PUBLISH.md`：提交、推送和 Release 验收。
17. `NEW_CHAT_PROMPT.md`：新对话可直接复制的提示词。

历史/专项资料：`IMPLEMENTATION_STEPS.md`、`LIBSSH2_COMPILE_GUIDE.md`、`NATIVE_CORE_FUNCTIONS.md`。

任何功能、路径、构建、测试或发布状态变化，都必须同步更新 `CURRENT_STATUS.md`、根 README 和上述相关文档。真实功能只能以端到端证据标记完成。
