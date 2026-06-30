# GitHub 发布规范

远端：`https://github.com/liyan-lucky/Tabssh_harmonyos.git`；默认分支：`main`。

用户已明确允许直接操作 `main`。当前项目改动已直接应用到 `main`，PR #1 已处于 merged/closed 状态，后续以 `main` 作为当前开发与测试入口。提交前仍建议检查完整 `git status`、diff、审计和构建结果；禁止提交 local.properties、凭据、崩溃转储、构建产物、三方生成二进制或原始日志。

DevEco 的签名 profile、证书、keystore、私钥和口令是本机私有材料，即使可以自动生成或在 `.idea` 中找到也不得提交。发布文档只记录资产哈希和公开证书信息，不记录口令。

## 线上构建

线上构建当前保留三个手动入口，并参考 `rustdesk_harmonyos/.github/workflows/build-harmonyos-linux.yml` 的成功结构：

- 仅支持 `workflow_dispatch` 手动触发。
- 运行环境为 `ubuntu-latest`。
- 不再自动响应 push 或 PR。
- `.github/workflows/build-harmonyos.yml` 做 HAP 构建、BuildInfo 刷新、HAP/SHA256/包清单上传和可选 Release 发布，依赖 `HARMONYOS_SDK_TOKEN` 读取私有 SDK release。
- `.github/workflows/test-harmonyos-sdk-token.yml` 用于发布构建前预检 SDK Token 权限。
- `.github/workflows/cleanup-releases.yml` 具备删除 Release、构建标签和旧 workflow run 的能力，只能在明确清理线上资产时手动运行。
- workflow 设置 `DEVECO_TOOLS_ROOT`、`TABSSH_HWSDK_ROOT`、`HARMONYOS_SDK_DIR`、`HARMONYOS_NODE_DIR`、`PATH` 和 `LD_LIBRARY_PATH` 后通过 `node scripts/run_hvigor_with_sdk_patch.js assembleHap` 执行 Hvigor。
- 构建后用 `unzip -t` 验证 HAP zip 格式，并检查对应 ABI 的 `libentry.so`。
- 发布构建 artifact 为 `tabssh-hap`。

线上 HAP 仍是 unsigned，不能当成正式发布包。先确认 SDK Token 预检和发布构建最小路径通过，再逐步加回静态审计、Real HAP、安装冒烟和 push/PR 自动检查。线上 Release 不能只看 workflow 绿色或版本号。必须下载资产到 `99_Temp\release_inspect\10_Tabssh_harmonyos`，复核 SHA256、签名、双 ABI、BuildInfo/依赖来源并安装双设备，再把 run、commit、asset 和哈希写回文档。
