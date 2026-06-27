# 当前构建测试就绪说明

> 更新时间：2026-06-26。本文记录当前 `main` 是否已经可以进入本地/线上构建测试，以及构建后应该优先验证什么。

## 当前判断

当前线上构建已经改为纯 GitHub 托管 Linux runner 的最小 HAP 格式验证。

原因：

- `.github/workflows/online-build.yml` 现在只保留手动触发。
- 线上运行环境是 `ubuntu-latest`，不再依赖自托管 Windows runner。
- SDK 由 repository secrets `HARMONYOS_SDK_URL` 和 `HARMONYOS_FULL_URL` 提供。
- workflow 会分别下载并解压两个完整 SDK 包，再在合并后的临时目录里自动探测 `tools/hvigor/bin/hvigorw.js` 和 `openharmony` SDK 目录。
- workflow 只执行 Mock unsigned HAP 构建、HAP zip 格式检查、双 ABI `libentry.so` 检查和 artifact 上传。
- 线上静态审计、连接分组专项审计、Real HAP 构建、push/PR 自动触发已暂时移除。
- 没有新增签名材料、凭据、构建产物或原始日志。

## 线上构建入口

GitHub Actions 文件：`.github/workflows/online-build.yml`。

触发方式：

1. GitHub → Actions → `TabSSH Linux HAP format build`。
2. 点击 `Run workflow`。
3. 选择 `main`。
4. 提前在仓库 Secrets 设置 `HARMONYOS_SDK_URL` 和 `HARMONYOS_FULL_URL`。
5. 可选填写 `sdk_sha256` 和 `full_sha256`，用于分别校验两个 SDK 包。
6. 运行后下载 artifact：`opentabssh-linux-unsigned-hap-format-test`。

当前 workflow 主要步骤：

- `actions/checkout@v4`
- `actions/setup-node@v4`，Node 20。
- 下载 `HARMONYOS_SDK_URL` 指向的包。
- 下载 `HARMONYOS_FULL_URL` 指向的包。
- 解压 zip / tar 类 SDK 包。
- 自动定位 DevEco `tools` 与 OpenHarmony SDK。
- 写入 `local.properties`。
- 执行 `node scripts/run_hvigor_with_sdk_patch.js assembleHap`。
- 查找 `outputs` 下的 `.hap`。
- 执行 `unzip -t` 校验 HAP zip 格式。
- 检查 HAP 内是否存在 arm64-v8a 与 x86_64 的 `libentry.so`。
- 上传 HAP、SHA256 和 HAP 文件列表。

## SDK 包要求

两个 SDK 包解压合并后必须能找到：

```text
tools/hvigor/bin/hvigorw.js
sdk/default/openharmony
```

目录可以更深，但必须包含等价的 `hvigor/bin/hvigorw.js` 和 `openharmony` 目录。workflow 会自动搜索，不要求固定根目录名。

仓库 Secrets：

```text
HARMONYOS_SDK_URL
HARMONYOS_FULL_URL
```

## 本地推荐先跑

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_local_checks.ps1 -SkipMockBuild
```

如果只想对齐本地最小 HAP 格式构建，再跑：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_mock_hap.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_mock_hap.ps1
```

## 构建成功后再逐步加回

必须先确认线上 Linux 最小 HAP 格式构建通过，再按顺序恢复：

1. PowerShell 语法检查。
2. `audit_project.ps1`。
3. `audit_connection_groups.ps1`。
4. Mock HAP 安装冒烟。
5. Real HAP 构建。
6. 真实 SSH/SFTP/转发验证。
7. push/PR 自动审计。

不要一次性全部加回，否则失败时难以判断是 SDK 包结构、Hvigor、ArkTS、Native、审计脚本还是 artifact 路径问题。

## 构建后必须验证

### HAP 格式

- Workflow 成功结束。
- artifact 名称为 `opentabssh-linux-unsigned-hap-format-test`。
- artifact 内存在 `entry-default-unsigned.hap`。
- HAP zip 格式通过 `unzip -t`。
- HAP 内含 arm64-v8a 与 x86_64 的 `libentry.so`。

### 基础页面回归

构建通过后再安装到模拟器/真机，确认：

- 首页能启动。
- 首页四个底部标签仍可切换。
- 连接编辑页仍可打开。
- TerminalPage、SftpPage、PortForwardPage、SettingsPage、TerminalSettingsPage、AboutPage 路由仍可打开。
- ConnectionGroupPage 路由能被 HAP 编译进包。

## 当前不能判定完成

- RDB 持久化。
- 首页分组入口。
- 非空分组迁移和拖拽排序。
- 私钥认证完整端到端证据。
- arm64 真机完整验收。
- 三类端口转发真实逐字节流量证据。
- SFTP 大文件、取消和中断恢复。
- 完整 xterm 兼容。
- HUKS / ASSET 凭据安全存储。
- Signed HAP 发布包。

## 测试结果回填

测试完成后更新：

- `docs/BUILD_TEST.md`：写 HAP 哈希、设备、通过项和失败项。
- `docs/PROGRESS.md`：把通过项或阻塞项同步到状态。
- `docs/ISSUES.md`：记录构建失败、页面编译失败或设备点击失败。

不要提交原始 hilog、设备隐私路径、服务器地址、用户名、密码、私钥或 token。
