# 当前构建测试就绪说明

> 更新时间：2026-06-26。本文记录当前 `main` 是否已经可以进入本地/线上构建测试，以及构建后应该优先验证什么。

## 当前判断

当前线上构建已经收敛为最小 HAP 格式验证。

原因：

- `.github/workflows/online-build.yml` 现在只保留手动触发。
- 线上只执行 Mock unsigned HAP 构建、HAP 包格式/双 ABI 验证和 artifact 上传。
- 线上静态审计、连接分组专项审计、Real HAP 构建、push/PR 自动触发已暂时移除。
- 这样可以先验证 DevEco runner、Hvigor、HAP 输出路径和 artifact 上传是否正确。
- 没有新增签名材料、凭据、构建产物或原始日志。

## 线上构建入口

GitHub Actions 文件：`.github/workflows/online-build.yml`。

触发方式：

1. GitHub → Actions → `TabSSH HAP format build`。
2. 点击 `Run workflow`。
3. 选择 `main`。
4. 运行后下载 artifact：`opentabssh-unsigned-hap-format-test`。

当前 workflow 只做三步：

- `scripts\build_mock_hap.ps1`
- `scripts\verify_mock_hap.ps1`
- 上传 `entry-default-unsigned.hap`

注意：GitHub 托管 runner 没有 DevEco/HarmonyOS SDK，HAP 构建必须使用带 `tabssh-deveco` 标签的自托管 Windows runner。线上产物仍是 unsigned HAP，不等于发布签名包。

## 本地推荐先跑

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_local_checks.ps1 -SkipMockBuild
```

如果只想对齐线上最小 HAP 格式构建，再跑：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_mock_hap.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_mock_hap.ps1
```

## 构建成功后再逐步加回

必须先确认线上最小 HAP 格式构建通过，再按顺序恢复：

1. PowerShell 语法检查。
2. `audit_project.ps1`。
3. `audit_connection_groups.ps1`。
4. Mock HAP 安装冒烟。
5. Real HAP 构建。
6. 真实 SSH/SFTP/转发验证。
7. push/PR 自动审计。

不要一次性全部加回，否则失败时难以判断是 DevEco runner、Hvigor、ArkTS、Native、审计脚本还是 artifact 路径问题。

## 构建后必须验证

### HAP 格式

- Workflow 成功结束。
- artifact 名称为 `opentabssh-unsigned-hap-format-test`。
- artifact 内存在 `entry-default-unsigned.hap`。
- `verify_mock_hap.ps1` 确认 HAP 内含 arm64-v8a 与 x86_64 native entries。

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
