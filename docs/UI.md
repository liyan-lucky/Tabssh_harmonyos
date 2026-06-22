# UI 页面说明

| 页面 | 当前状态 | 真实功能要求 |
|---|---|---|
| Index | Mock 连接列表与导航 | RDB、搜索、收藏、在线状态 |
| ConnectionEditPage | 基础字段编辑 | 校验、安全存储、代理/跳板机 |
| TerminalPage | 基础 ANSI/VT 无颜色网格、轮询、控制键；Mock 明示 | 完整 xterm-256、样式、宽字符、选择/搜索、真实多标签 |
| SftpPage | 复用已认证会话；Mock 明示 | 真实浏览、上传下载、删除重命名、进度与校验 |
| PortForwardPage | 已禁用 Mock 成功提示 | local/remote/dynamic 生命周期与流量证据 |
| SettingsPage | 显示 Core 版本 | 主题、终端、安全和网络设置 |
| AboutPage | 项目说明 | 版本、许可证和构建信息 |

所有未实现入口必须明确提示“开发中”或标为 Mock，不能呈现为真实成功。
