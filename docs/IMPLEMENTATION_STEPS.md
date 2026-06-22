# OpenTabSsh 真实功能实现步骤

> 2026-06-22：任何阶段只有在 arm64 真机与 x86_64 模拟器获得端到端证据后才能标记完成。每次重要修改按 `BUILD_TEST.md` 执行一次完整审计、构建和相关功能检查。

## 第一阶段：已完成在本包内

- ArkTS/ArkUI 工程结构
- OpenTabSsh 应用名和包名
- 连接配置模型
- 首页、连接编辑、Terminal、SFTP、端口转发、设置页面
- Native C++ N-API 函数表
- Mock SSH Core
- CMake 编译入口

## 第二阶段：真实 SSH 最小可用版

目标：能连接真实 Linux/OpenWrt SSH，并打开 shell。

Native 需要实现：

```cpp
CreateSession
Connect
OpenShell
Write
Read
Resize
CloseChannel
Disconnect
```

ArkTS 不需要大改，继续调用 `NativeSshCore.ets`。

## 第三阶段：安全能力

- HostKey 首次信任
- HostKey 变更警告
- known_hosts 本地存储
- 密码加密保存
- 私钥导入和私钥口令
- 生物识别解锁密码/私钥

## 第四阶段：TabSSH Android 功能补齐

- 多标签 SSH session/channel 管理
- 同一 profile 多 channel 复用
- SFTP 上传/下载/删除/重命名
- local/remote/dynamic forwarding
- ProxyHTTP / SOCKS4 / SOCKS5
- ProxyJump / Jump Host
- post-connect script
- tmux/screen/zellij 自动启动
- 连接性能监控
- 连接导入导出
- 云端同步
- 服务卡片

## 第五阶段：终端体验

当前 Terminal 页面是 Text + TextInput 的测试终端。真实产品建议实现：

- Canvas/XComponent 渲染终端字符网格
- ANSI/VT100/xterm-256color 解析
- 选择复制
- 快捷键栏：Ctrl、Alt、Esc、Tab、方向键
- 软键盘适配
- 触摸滚动历史
- URL 自动识别
- 字体大小和配色主题
