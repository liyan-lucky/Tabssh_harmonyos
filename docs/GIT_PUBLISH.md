# GitHub 发布规范

远端：`https://github.com/liyan-lucky/Tabssh_harmonyos.git`；默认分支：`main`。

用户已明确允许直接操作 `main`。当前项目改动已直接应用到 `main`，PR #1 已处于 merged/closed 状态，后续以 `main` 作为当前开发与测试入口。提交前仍建议检查完整 `git status`、diff、审计和构建结果；禁止提交 local.properties、凭据、崩溃转储、构建产物、三方生成二进制或原始日志。

DevEco 的签名 profile、证书、keystore、私钥和口令是本机私有材料，即使可以自动生成或在 `.idea` 中找到也不得提交。发布文档只记录资产哈希和公开证书信息，不记录口令。

## 线上构建

`.github/workflows/online-build.yml` 当前已经收敛为最小 HAP 格式构建入口：

- 仅支持 `workflow_dispatch` 手动触发。
- 不再自动响应 push 或 PR。
- 不跑静态审计、不跑分组专项审计、不构建 Real HAP。
- 只在 `self-hosted / Windows / X64 / tabssh-deveco` runner 上执行 Mock unsigned HAP 构建。
- 构建后执行 `verify_mock_hap.ps1` 验证 HAP 包格式和双 ABI native entries。
- 上传 artifact：`opentabssh-unsigned-hap-format-test`。

GitHub 托管 runner 没有 DevEco/HarmonyOS SDK，不能直接构建 HAP；必须配置自托管 Windows DevEco runner。线上 HAP 仍是 unsigned，不能当成正式发布包。

先确认最小 HAP 格式构建通过，再逐步加回静态审计、Real HAP、安装冒烟和 push/PR 自动检查。线上 Release 不能只看 workflow 绿色或版本号。必须下载资产到 `99_Temp\release_inspect\10_Tabssh_harmonyos`，复核 SHA256、签名、双 ABI、BuildInfo/依赖来源并安装双设备，再把 run、commit、asset 和哈希写回文档。
