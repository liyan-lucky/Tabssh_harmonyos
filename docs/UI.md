# UI 页面说明

| 页面 | 当前状态 | 真实功能要求 |
|---|---|---|
| Index | Mock 连接列表与导航 | RDB、搜索、收藏、在线状态 |
| ConnectionEditPage | 基础字段编辑 | 校验、安全存储、代理/跳板机 |
| TerminalPage | Text + TextInput Mock | ANSI/VT、网格渲染、快捷键、多标签 |
| SftpPage | Mock 列表 | 真实浏览、上传下载、删除重命名、进度与校验 |
| PortForwardPage | Mock local forward | local/remote/dynamic 生命周期与流量证据 |
| SettingsPage | 显示 Core 版本 | 主题、终端、安全和网络设置 |
| AboutPage | 项目说明 | 版本、许可证和构建信息 |

所有未实现入口必须明确提示“开发中”或标为 Mock，不能呈现为真实成功。
