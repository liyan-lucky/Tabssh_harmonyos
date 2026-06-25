# UI 页面说明

## 图标来源

所有应用图标统一使用 ProIcons 资产，禁止自绘 SVG 和 Emoji/Unicode 字符图标。底栏沿用 RustDesk HarmonyOS 的悬浮胶囊布局，但图标资源分别使用 ProIcons tune/network/monitor/person；页面内图标映射、来源和审计规则见 `PROICONS_ICONS.md`。

## 现有样式规则

- 首页继续使用浅蓝页面背景、白色圆角卡片、轻阴影、浅蓝操作按钮和安全区内悬浮胶囊底栏。
- 连接页新增搜索、收藏筛选和排序芯片时，不改变整体页面结构；筛选卡片使用白色圆角卡片，内部使用浅灰输入底色和蓝色选中芯片。
- 收藏状态用文字标签呈现，不引入 Emoji/Unicode 图标。
- 筛选、排序、收藏当前只绑定内存仓库；未接 RDB 前不能写成持久化功能。

| 页面 | 当前状态 | 真实功能要求 |
|---|---|---|
| Index | Mock/真实连接入口、连接搜索、收藏筛选、排序芯片、内存连接统计展示与导航 | RDB、分组编辑 UI、批量编辑、在线状态、搜索高亮、统计页 |
| ConnectionEditPage | 基础字段编辑 | 校验、安全存储、代理/跳板机 |
| TerminalPage | VT 单元格解析、16/256/RGB 与文本样式 Span、备用屏/OSC/宽字符、复制、application cursor、bracketed paste、横向控制键和 PTY resize；Mock 明示 | IME 逐键输入、搜索、鼠标协议、复杂 TUI/性能设备回归、真实多标签 |
| SftpPage | 复用已认证会话；Mock 明示 | 真实浏览、上传下载、删除重命名、进度与校验 |
| PortForwardPage | 已禁用 Mock 成功提示 | local/remote/dynamic 生命周期与流量证据 |
| SettingsPage | 显示 Core 版本 | 主题、终端、安全和网络设置 |
| AboutPage | 项目说明 | 版本、许可证和构建信息 |

所有未实现入口必须明确提示“开发中”或标为 Mock，不能呈现为真实成功。
