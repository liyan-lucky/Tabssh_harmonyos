# 连接分组专项测试指南

> 当前范围：`Index.ets`、`ConnectionEditPage.ets`、`ConnectionGroupPage.ets`、`ProfileRepository.ets` 和 `main_pages.json`。本文件只记录测试步骤，不把功能标记为完成。

## 静态检查

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\audit_connection_groups.ps1
```

该脚本检查：

- 分组页面文件存在。
- `main_pages.json` 已注册 `pages/ConnectionGroupPage`。
- RDB-backed 仓库存在 `listGroups`、`saveGroup`、`removeGroup` 和分组持久化路径。
- 分组页包含新建、改名、换色、上移/下移、折叠和页面提示。
- 首页包含 `ConnectionGroupPage` 入口和连接页分组筛选。
- 连接编辑页包含所属分组芯片选择。
- 文档包含连接分组、改名和所属分组说明。

## 连接编辑页测试

1. 打开新建连接页。
2. 确认页面展示“所属分组”。
3. 确认已有分组以芯片形式展示。
4. 点击不同分组芯片，选中颜色应变化。
5. 保存后回到连接列表。
6. 再次编辑该连接，应回显刚才选择的分组。

当前分组数据来自 RDB-backed 仓库；保存后应在重新打开页面时回显，完整杀进程重启回显仍需设备验证。

## 连接分组页测试

1. 从首页工作台或连接页筛选卡片打开 `pages/ConnectionGroupPage`。
2. 确认页面保持浅蓝背景、白色圆角卡片和轻阴影风格。
3. 点击“新建”，列表应增加一个分组并进入名称编辑状态。
4. 修改名称后点击“保存”，列表应显示新名称。
5. 点击“取消”，名称编辑状态应退出。
6. 点击色块，分组颜色应切换。
7. 点击“上移”或“下移”，列表顺序应变化。
8. 点击“折叠”或“展开”，状态文字应变化。
9. 默认分组和非空分组应按页面提示保持安全保护。
10. 关闭应用并重新启动后，新增分组、改名、换色、排序和折叠状态应仍然存在。

## 当前仍待补

- RDB 持久化已编码并通过 HAP 安装/冷启动；尚未完成分组逐项点击后的跨重启回显验证。
- 非空分组迁移尚未实现。
- 拖拽排序尚未实现，当前是上移/下移按钮。
- 尚未通过真机/模拟器完整点击验证。
- 2026-06-29 已通过 Mock HAP 构建、x86_64 模拟器安装/冷启动和首屏入口可见性验证；仍未完成上方分组页逐项点击。

## 测试结果回填

测试后同步：

- `docs/BUILD_TEST.md`
- `docs/PROGRESS.md`
- `docs/ISSUES.md`
- `reports/connection_group_audit_latest.md`

只写摘要、通过项和失败项，不写服务器地址、用户名、密码、私钥、token 或原始设备日志。
