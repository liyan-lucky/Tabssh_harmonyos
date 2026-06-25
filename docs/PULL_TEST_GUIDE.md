# 拉取与测试指南

> 目标：让接手者直接拉取 `main` 后，按顺序验证 Mock、真实 Core、连接管理 UI、SFTP、终端和端口转发。本文只描述测试流程，不把尚未验证的功能标记为完成。

## 1. 拉取 main

```powershell
git fetch origin
git checkout main
git pull --ff-only origin main
```

如果只想测试稳定的 Mock fallback，可不构建三方依赖；源码 checkout 默认会在缺少 `third_party` 产物时编译 `native_ssh_mock.cpp`。

## 2. 安全规则

- 不要把 SSH 密码、私钥口令、token、服务器地址、用户名写进提交、Issue、PR、截图、日志或文档。
- 测试凭据只允许在运行时输入或通过本机临时环境变量传入测试进程。
- `99_Temp` 是多项目共享目录，禁止整体删除；任何 APK/HAP 一律不得按扩展名全局清理。
- 构建/日志/依赖/测试端只允许进入 `docs/WORKSPACE_PATHS.md` 中登记的 TabSSH 专属目录。

## 3. 本地一键检查

推荐先跑默认检查：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_local_checks.ps1
```

默认会执行：

- `git diff --check`
- `scripts\audit_project.ps1`
- `scripts\test_terminal_emulator.ps1`
- `scripts\build_mock_hap.ps1`
- `scripts\verify_mock_hap.ps1`

检查摘要会写入：

```text
99_Temp\tabssh_harmonyos_logs\local_checks\summary_*.md
```

只做快速静态/终端检查，不构建 HAP：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_local_checks.ps1 -SkipMockBuild
```

已有三方依赖 manifest 时，构建并验真实 HAP：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_local_checks.ps1 -WithRealCore
```

需要从零重建三方依赖时：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_local_checks.ps1 -WithRealCore -BuildDependencies
```

## 4. Mock fallback 手动测试

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\audit_project.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_mock_hap.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_mock_hap.ps1
```

预期：

- `audit_project.ps1` 输出 0 FAIL。
- Mock HAP 包内存在 arm64-v8a 与 x86_64 的 `libentry.so`。
- Terminal 页面必须清楚显示 Mock，不得伪装成真实 SSH。
- SFTP/端口转发在 Mock 下不得显示真实成功。

## 5. 真实依赖构建

前提：Windows + DevEco Studio/OpenHarmony Native SDK + MSYS2 Perl/make + Git。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_native_dependencies.ps1
```

脚本会在 `99_Temp\tabssh_harmonyos_dependencies` 中构建并记录 manifest：

- zlib `1.3.2`
- OpenSSL `3.5.7`
- libssh2 `1.11.1`
- ABI：`arm64-v8a`、`x86_64`

不要把生成的 `.a`、`.so`、头文件或 SDK 内容提交进仓库。

## 6. 真实 HAP 构建与验包

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_real_hap.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_real_hap.ps1
```

`verify_real_hap.ps1` 只证明包内是 real-core marker 和正确 ABI，不证明网络功能完成。

## 7. 安装与冷启动冒烟

构建并验包后，可安装到 hdc 默认设备：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\install_and_smoke.ps1
```

指定 HAP 和设备：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\install_and_smoke.ps1 `
  -HapPath "..\99_Temp\harmonyos_build\10_Tabssh_harmonyos\entry-default-unsigned-real.hap" `
  -DeviceId "127.0.0.1:5555"
```

该脚本会：

- 使用 hdc 安装 HAP。
- 启动 `com.open.tabssh/EntryAbility`。
- 查询 bundle dump 和 PID。
- 过滤 `com.open.tabssh|OpenTabSsh|FATAL|cppcrash|jscrash|appfreeze|APP_INPUT_BLOCK` 相关 hilog 线索。
- 尝试列出 faultlogger。
- 输出摘要到 `99_Temp\tabssh_harmonyos_logs\install_smoke\summary_*.md`。

这只证明安装/冷启动和基础日志采集，不证明 SSH、SFTP、端口转发或发布签名通过。

## 8. 推荐设备测试顺序

### 8.1 基础连接

1. 新建连接。
2. host/port/username 在 UI 输入。
3. password 只在运行时输入，不保存到普通文本。
4. 第一次连接必须出现 HostKey 指纹确认。
5. HostKey 变化必须阻断并显示高风险警告。

通过标准：

- 未知 HostKey 返回阻断状态，确认后才继续认证。
- 错误密码返回认证失败，不崩溃。
- 正确密码进入 PTY shell。
- 再次连接同一 profile 不重复出现首次 HostKey 提示。

### 8.2 首页连接管理 UI

在“连接”页测试：

- 搜索名称、主机、用户或备注。
- 全部 / 只看收藏筛选。
- 默认、名称、主机、最近、次数、收藏排序芯片。
- 收藏 / 取消收藏。
- 连接次数与上次失败提示显示。

当前这些数据仍来自内存仓库；未接 RDB 前，退出应用后数据丢失属于预期。

### 8.3 连接分组页

`pages/ConnectionGroupPage` 已注册到页面路由，但首页入口仍待接入。接入入口后需测试：

- 页面标题、说明卡片和分组列表保持现有浅蓝背景、白色圆角卡片风格。
- 默认分组显示主机数量，且默认分组不能删除。
- 新建分组后列表刷新。
- 折叠 / 展开状态可切换。
- 空分组可删除，非空分组暂不删除。

当前分组仍是内存数据；未接 RDB 前，退出应用后数据丢失属于预期。

### 8.4 终端

在远端执行：

```text
whoami
pwd
ls -la
stty size
```

再测试：

- 横竖屏或窗口变化后 `stty size` 变化。
- Ctrl/Alt/Esc/Tab/方向键可用。
- 彩色输出、CJK、滚动历史、复制。
- `vim`、`tmux`、`htop`、`nano` 至少各做一次冒烟。

当前终端是“较完整 VT 基线”，不能直接宣称完整 xterm。

### 8.5 SFTP

先测只读：

- 根目录列表。
- 进入目录。
- 返回上级。

再测写操作：

- 上传小文本。
- 下载后逐字节对比 SHA256。
- 新建目录。
- 重命名。
- chmod `0644`。
- 删除文件与空目录。

大文件、取消、中断恢复仍需单独取证。

### 8.6 端口转发

三类都要逐字节验证：

| 类型 | 场景 | 通过标准 |
|---|---|---|
| local `-L` | 本机 loopback → SSH → 远端 echo/http | 双向字节一致，移除后端口释放 |
| remote `-R` | 服务器回环监听 → SSH → 本地 echo/http | 服务端能连通，断开后监听消失 |
| dynamic `-D` | SOCKS5 CONNECT IPv4/IPv6/域名 | 返回目标真实响应，错误目标正确失败 |

端口转发源码存在不等于完成；必须有真实流量证据。

### 8.7 断线与重连

测试：

- 远端 sshd 重启。
- 手机/模拟器断网再恢复。
- HostKey 变化。
- 认证失败。
- 正常 exit。

通过标准：

- 只有“曾成功连接”的 tab 自动重连。
- HostKey 变化、认证失败、无效配置、正常 shell 退出不进入重连风暴。
- 断开前 channel、forward、session、socket 被清理。

## 9. 当前不能写成完成的内容

- HUKS/ASSET 凭据安全存储。
- arm64 真机真实 SSH 完整验收。
- 完整 xterm 兼容。
- SFTP 大文件/取消/中断恢复。
- 三类端口转发真实 HAP 流量证据。
- 后台保持、RDB 持久化、ProxyJump、Mosh、X11、云/虚拟化/VNC。

## 10. 测试完成后要回填

每次测试后同步：

- `docs/BUILD_TEST.md`：构建、安装、设备和 HAP 哈希证据。
- `docs/PROGRESS.md`：哪些已通过，哪些仍阻塞。
- `docs/ISSUES.md`：失败、风险、复现步骤。
- `reports/project_audit_latest.md`：静态审计结果。

任何含凭据、服务器地址、用户名或私钥内容的原始日志不得提交。
