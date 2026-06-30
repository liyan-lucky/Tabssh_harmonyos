# ProIcons 图标规则与映射

## 强制规则

- 应用启动图标、底部导航、页面入口、操作按钮、返回/刷新、文件类型和空状态图标统一使用 [ProIcons](https://proicons.com/) 提供的图标，禁止新增自绘 SVG、Emoji 或 Unicode 字符图标。
- 新增或替换图标必须从 ProIcons 官网或已登记的 ProIcons 提取记录获取；如果 ProIcons 提供彩色/多色配色版本，优先使用彩色配色资产，没有合适彩色版本时才使用单色 stroke/fill SVG 并通过主题色适配。
- 文字按钮、状态圆点、产品名和 SSH 文本标识不属于图标；不得用字符图标冒充 UI 资产。
- SVG 统一放在 `entry/src/main/resources/rawfile`，保留 ProIcons 的路径数据；运行时只允许通过尺寸、旋转和 `colorFilter` 做主题适配。
- 启动图标使用同一 ProIcons `Terminal` SVG，资源名为 `app_icon_proicons.svg`。

## 来源与可追溯性

当前仓库内图标复用了 RustDesk HarmonyOS 参考工程中已从 `proicons` npm 包提取并记录来源的 SVG。该参考工程记录的提取流程为：安装 `proicons` 包、读取 `proicons/dist/esm/icons/*Icon.js`、生成标准 SVG、去除重复属性、卸载临时包。文件传输资产和设置资产分别有 ProIcons 提取记录；设置资产来自 ProIcons 收录的 Lucide Icons 集合。

后续若网络访问 `proicons.com` 或 npm 包失败，等待 5 分钟后重试，最多 3 次；仍失败时只能继续使用已登记的仓库内 ProIcons 资产，不得临时自绘替代。

参考记录只用于确认资产来源，不作为本项目构建输入。本项目构建只读取仓库内已纳入审计的 SVG。

2026-06-29 新增的工具箱页没有新增自绘 SVG，网络、系统、开发工具卡片均复用下方已登记 ProIcons rawfile 资源，通过主题色和浅色背景块做区分。首批工具能力和后续网络工具能力只扩展 ArkTS/HarmonyOS 逻辑，不新增图标。后续如果为某个工具补专属图标，仍必须从 ProIcons 官网或已登记提取记录获取。

## 资源映射

| 本项目资源 | ProIcons 组件/语义 | 使用位置 |
|---|---|---|
| `ft_back.svg` | `ArrowLeftIcon` | 返回 |
| `ft_up.svg` | `ArrowUpIcon` | 方向键、行尾箭头 |
| `ft_file.svg` / `ft_folder.svg` | `FileIcon` / `FolderIcon` | SFTP 与文件设置 |
| `ft_new_folder.svg` | `AddSquareIcon` | 新建连接、添加设备 |
| `ft_remote.svg` | `ComputerIcon` | SFTP/远端入口 |
| `ft_sort.svg` | ProIcons 下载资源 `417686` | 监控筛选 |
| `ft_delete.svg` | `DeleteIcon` | 缓存与删除 |
| `refresh.svg` | `ArrowSyncIcon` | 刷新 |
| `settings_terminal.svg` | Lucide `terminal` | 启动图标、终端入口 |
| `settings_network.svg` | Lucide `network` | 连接、局域网与分享 |
| `settings_monitor.svg` | Lucide `monitor` | 监控 |
| `settings_display.svg` | Lucide `monitor` | 设置 Tab、显示与字体 |
| `settings_person.svg` | Lucide `user` | 历史“我的”资源，当前不作为底部 Tab 使用 |
| `settings_tune.svg` | Lucide `sliders` | 工作台、设置、操作菜单 |
| `settings_server.svg` | Lucide `server` | 主机与存储 |
| `settings_shield.svg` | Lucide `shield` | 钥匙串安全入口 |
| `settings_cpu.svg` | Lucide `cpu` | Redis 预留入口 |
| `settings_folder.svg` | Lucide `folder` | 文件管理与自动保存 |
| `settings_timer.svg` | Lucide `timer` | 访问日志 |
| `settings_update.svg` | Lucide `refresh-cw` | 导入导出、自动压缩/更新语义 |
| `settings_privacy.svg` | Lucide `file-text` | 笔记与备案信息 |
| `settings_info.svg` | Lucide `info` | 关于与功能介绍 |
| `settings_language.svg` | Lucide `languages` | 语言 |
| `settings_palette.svg` | Lucide `palette` | 主题 |
| `settings_remark.svg` | Lucide `message-square-plus` | 每日寄语 |

## 校验

`scripts/audit_project.ps1` 检查本文件、ProIcons 启动资源、底部四个映射、自绘旧 `tab_*.svg` 的移除和已知字符图标的清理。构建仍需验证 SVG 能被 HarmonyOS 资源编译器解析。
