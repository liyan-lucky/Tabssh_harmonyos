# 当前构建测试就绪说明

> 更新时间：2026-06-26。本文记录当前 `main` 是否已经可以进入本地构建测试，以及构建后应该优先验证什么。

## 当前判断

当前仓库已经可以进入本地构建测试。

原因：

- 所有本轮新增页面已经写入源码树。
- `pages/ConnectionGroupPage` 已注册到 `entry/src/main/resources/base/profile/main_pages.json`。
- 首页连接筛选 UI、连接分组页、内存仓库分组接口和相关文档已经同步。
- 没有新增签名材料、凭据、构建产物或原始日志。

## 推荐先跑

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_local_checks.ps1
```

该命令用于先做静态审计、PowerShell/终端解析器测试、Mock HAP 构建和验包。

如果只想快速检查源码和终端解析器，可先跑：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_local_checks.ps1 -SkipMockBuild
```

## 构建后必须验证

### 首页连接管理

- 搜索名称、主机、用户或备注。
- 全部 / 只看收藏筛选。
- 默认、名称、主机、最近、次数、收藏排序芯片。
- 收藏 / 取消收藏。
- 连接次数和上次失败提示。

### 连接分组页

- `pages/ConnectionGroupPage` 能通过路由编译进 HAP。
- 页面保持浅蓝背景、白色圆角卡片和轻阴影风格。
- 默认分组显示主机数量。
- 新建分组后列表刷新。
- 折叠 / 展开状态可切换。
- 默认分组不能删除。
- 空分组可删除，非空分组暂不删除。

注意：当前首页入口尚未接入，分组页路由已注册但还需要下一轮把入口接入 `Index.ets`。

### 基础页面回归

- 首页四个底部标签仍可切换。
- 连接编辑页仍可打开。
- TerminalPage、SftpPage、PortForwardPage、SettingsPage、TerminalSettingsPage、AboutPage 路由仍可打开。

## 当前不能判定完成

- RDB 持久化。
- 首页分组入口。
- 连接分组重命名、拖拽排序、非空分组迁移。
- 私钥认证完整端到端证据。
- arm64 真机完整验收。
- 三类端口转发真实逐字节流量证据。
- SFTP 大文件、取消和中断恢复。
- 完整 xterm 兼容。
- HUKS / ASSET 凭据安全存储。

## 测试结果回填

测试完成后更新：

- `docs/BUILD_TEST.md`：写 HAP 哈希、设备、通过项和失败项。
- `docs/PROGRESS.md`：把通过项或阻塞项同步到状态。
- `docs/ISSUES.md`：记录构建失败、页面编译失败或设备点击失败。
- `reports/project_audit_latest.md`：回填最新静态审计摘要。

不要提交原始 hilog、设备隐私路径、服务器地址、用户名、密码、私钥或 token。
