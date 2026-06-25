# 文件职责

- `AppScope/`：Bundle、版本和应用资源。
- `entry/src/main/ets/pages/`：ArkUI 页面集合。
- `entry/src/main/ets/pages/ConnectionGroupPage.ets`：连接分组管理页；保持现有白色圆角卡片、浅蓝背景和 ProIcons 风格，当前使用内存仓库，页面已注册路由但首页入口仍待接入。
- `entry/src/main/resources/base/profile/main_pages.json`：页面路由清单；已注册 `pages/ConnectionGroupPage`。
- `entry/src/main/ets/common/`：模型、Native 包装、会话管理和内存仓库。
- `entry/src/main/ets/common/models/ConnectionProfile.ets`：连接配置模型；已扩展 Android 常见字段，但字段骨架不等于功能完成。
- `entry/src/main/ets/common/models/ConnectionGroup.ets`：连接分组、搜索过滤和排序模式模型；当前只供内存仓库使用，未接 RDB。
- `entry/src/main/ets/common/storage/ProfileRepository.ets`：内存连接仓库；支持默认分组、过滤、排序和连接统计字段，仍不是持久化数据库。
- `entry/src/main/ets/common/IconUtils.ets`：ProIcons stroke/fill SVG 的统一主题着色器。
- `entry/src/main/resources/rawfile/*.svg`：经 `docs/PROICONS_ICONS.md` 登记的 ProIcons UI 资产。
- `entry/src/main/cpp/`：N-API、Mock Core 与 libssh2 实现入口。
- `entry/src/main/ets/common/terminal/`：有样式单元格、颜色、备用屏、滚动区、宽字符和协议回复的 VT 解析器；当前仍不是完整 xterm 模拟器。
- `docs/`：权威接力、架构、路径、测试和历史资料。
- `docs/BUILD_READY.md`：当前 `main` 是否可以进入构建测试、优先验证项和测试结果回填规则。
- `docs/ANDROID_PARITY_ROADMAP.md`：Android 版功能对齐优先级路线图；按 P0/P1/P2/P3 拆分实现和验收。
- `docs/PULL_TEST_GUIDE.md`：拉取 `main` 后的本地一键检查、Mock/真实构建、安装冒烟和设备功能验证顺序。
- `docs/UPSTREAM_REFERENCES.md`：外部 Web/Android/Desktop 参考仓库的路径、commit 与用途。
- `docs/PROICONS_ICONS.md`：图标唯一来源、资源映射与审计规则。
- `scripts/`：stage、构建、审计、清理、备份、安装冒烟和本地检查；输出必须进入 `99_Temp`。
- `scripts/run_local_checks.ps1`：拉取后的一键本地检查入口，串联静态审计、终端解析器测试、Mock 构建/验包和可选真实 HAP 流程。
- `scripts/install_and_smoke.ps1`：HAP 安装与冷启动冒烟工具；采集 bundle/PID/hilog/faultlogger 线索，只证明安装启动，不证明 SSH 功能。
- `scripts/test_terminal_emulator.ps1`：不落盘产物的终端解析器内存回归。
- `.github/workflows/online-build.yml`：托管 runner 静态审计，以及受控 `tabssh-deveco` runner 的手动真实 HAP 构建。
- `reports/`：可提交的无敏感信息审计摘要。

`FILE_LIST.txt` 属于易过期的手工快照，不再使用；以后以 Git 文件树和本文为准。每轮新增或删除文件后必须同步更新本文，避免文件职责和仓库实际状态脱节。
