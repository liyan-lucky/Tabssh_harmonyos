# GitHub 发布规范

远端：`https://github.com/liyan-lucky/Tabssh_harmonyos.git`；默认分支：`main`。

用户已明确允许直接操作 `main`。当前项目改动已直接应用到 `main`，PR #1 已处于 merged/closed 状态，后续以 `main` 作为当前开发与测试入口。提交前仍建议检查完整 `git status`、diff、审计和构建结果；禁止提交 local.properties、凭据、崩溃转储、构建产物、三方生成二进制或原始日志。

DevEco 的签名 profile、证书、keystore、私钥和口令是本机私有材料，即使可以自动生成或在 `.idea` 中找到也不得提交。发布文档只记录资产哈希和公开证书信息，不记录口令。

## 线上构建

`.github/workflows/online-build.yml` 是当前线上构建入口：

- push 到 `main` 和 PR 默认只跑静态审计。
- 手动触发 `build_mock_hap=true` 时，在 `self-hosted / Windows / X64 / tabssh-deveco` runner 上构建 Mock unsigned HAP，并上传 `opentabssh-mock-unsigned-hap`。
- 手动触发 `build_real_hap=true` 时，在同一 DevEco runner 上构建固定依赖和真实 SSH unsigned HAP，并上传 `opentabssh-real-unsigned-hap`。

GitHub 托管 runner 没有 DevEco/HarmonyOS SDK，不能直接构建 HAP；必须配置自托管 Windows DevEco runner。线上 HAP 仍是 unsigned，不能当成正式发布包。

线上 Release 不能只看 workflow 绿色或版本号。必须下载资产到 `99_Temp\release_inspect\10_Tabssh_harmonyos`，复核 SHA256、签名、双 ABI、BuildInfo/依赖来源并安装双设备，再把 run、commit、asset 和哈希写回文档。
