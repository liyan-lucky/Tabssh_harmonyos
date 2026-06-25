# 拉取与测试指南

> 目标：让接手者直接拉取 `codex/real-ssh-core-foundation` 分支后，按顺序验证 Mock、真实 Core、SFTP、终端和端口转发。本文只描述测试流程，不把尚未验证的功能标记为完成。

## 1. 拉取分支

```powershell
git fetch origin
git checkout codex/real-ssh-core-foundation
git pull --ff-only origin codex/real-ssh-core-foundation
```

如果只想测试稳定的 Mock fallback，可不构建三方依赖；源码 checkout 默认会在缺少 `third_party` 产物时编译 `native_ssh_mock.cpp`。

## 2. 安全规则

- 不要把 SSH 密码、私钥口令、token、服务器地址、用户名写进提交、Issue、PR、截图、日志或文档。
- 测试凭据只允许在运行时输入或通过本机临时环境变量传入测试进程。
- `99_Temp` 是多项目共享目录，禁止整体删除；任何 APK/HAP 一律不得按扩展名全局清理。
- 构建/日志/依赖/测试端只允许进入 `docs/WORKSPACE_PATHS.md` 中登记的 TabSSH 专属目录。

## 3. Mock fallback 快速测试

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

## 4. 真实依赖构建

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

## 5. 真实 HAP 构建与验包

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_real_hap.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_real_hap.ps1
```

`verify_real_hap.ps1` 只证明包内是 real-core marker 和正确 ABI，不证明网络功能完成。

## 6. 推荐设备测试顺序

### 6.1 基础连接

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

### 6.2 终端

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

### 6.3 SFTP

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

### 6.4 端口转发

三类都要逐字节验证：

| 类型 | 场景 | 通过标准 |
|---|---|---|
| local `-L` | 本机 loopback → SSH → 远端 echo/http | 双向字节一致，移除后端口释放 |
| remote `-R` | 服务器回环监听 → SSH → 本地 echo/http | 服务端能连通，断开后监听消失 |
| dynamic `-D` | SOCKS5 CONNECT IPv4/IPv6/域名 | 返回目标真实响应，错误目标正确失败 |

端口转发源码存在不等于完成；必须有真实流量证据。

### 6.5 断线与重连

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

## 7. 当前不能写成完成的内容

- HUKS/ASSET 凭据安全存储。
- arm64 真机真实 SSH 完整验收。
- 完整 xterm 兼容。
- SFTP 大文件/取消/中断恢复。
- 三类端口转发真实 HAP 流量证据。
- 后台保持、RDB 持久化、ProxyJump、Mosh、X11、云/虚拟化/VNC。

## 8. 测试完成后要回填

每次测试后同步：

- `docs/BUILD_TEST.md`：构建、安装、设备和 HAP 哈希证据。
- `docs/PROGRESS.md`：哪些已通过，哪些仍阻塞。
- `docs/ISSUES.md`：失败、风险、复现步骤。
- `reports/project_audit_latest.md`：静态审计结果。

任何含凭据、服务器地址、用户名或私钥内容的原始日志不得提交。
