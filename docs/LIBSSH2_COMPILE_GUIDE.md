# libssh2 / OpenSSL / zlib 双架构构建

> 当前状态：脚本和真实 Core 源码已进入仓库，但双 ABI 依赖产物与真实 HAP 尚未完成本机验证。只有 `verify_real_hap.ps1` 和真实服务器端到端证据通过后，才能标记真实能力完成。

## 固定来源

| 组件 | 固定版本 | 完整性依据 |
|---|---|---|
| libssh2 | `1.11.1` | tag `libssh2-1.11.1`，commit `a312b43325e3383c865a87bb1d26cb52e3292641` |
| OpenSSL | `3.5.7 LTS` | tag `openssl-3.5.7`，commit `8cf17aaeb4599f8af87fefd810b5b5fee90fe69e` |
| zlib | `1.3.2` | 源码包 SHA256 `BB329A0A2CD0274D05519D61C667C062E06990D72E125EE2DFA8DE64F0119D16` |

源码、下载、build、install 和 `manifest.json` 只进入 `%VSCODE_ROOT%\99_Temp\tabssh_harmonyos_dependencies`。仓库不提交生成的头文件、`.a`、`.so` 或 SDK。

## 本机构建

前提：DevEco Studio/OpenHarmony Native SDK、完整 MSYS2 Perl/make、Git。默认 SDK 路径是 `C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\native`，可用 `HARMONYOS_NATIVE_SDK` 覆盖。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_native_dependencies.ps1
```

脚本对 `arm64-v8a` 与 `x86_64` 执行：

1. 校验固定源码 commit/压缩包 SHA256。
2. 用 OHOS clang/CMake 构建静态 zlib。
3. 用 `clang --target=<triple>` 构建 OpenSSL 静态 `libcrypto.a` / `libssl.a`。
4. 用 OpenSSL + zlib 构建静态 `libssh2.a`。
5. 为每个 `.a` 记录大小与 SHA256 到依赖区 `manifest.json`。

`-Rebuild` 只清理该依赖目录下六个明确的 ABI/component build/install 路径；发现 APK 会拒绝清理。

## 真实 HAP

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_real_hap.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_real_hap.ps1
```

`build_real_hap.ps1` 先创建仓库外干净 stage，复核 manifest 中每个库的 SHA256，再把双 ABI 头文件/静态库复制到 stage 的 `entry/src/main/cpp/third_party`。CMake 仅在当前 ABI 所需文件全部存在时编译 `native_ssh_libssh2.cpp`；普通源码 checkout 明确回退 `native_ssh_mock.cpp`。

最终三方库静态链接进每个 ABI 的 `libentry.so`，不会向仓库写入机器生成二进制。真实产物名为 `entry-default-unsigned-real.hap`；它仍是 unsigned 开发包，不是正式发布资产。

## 验收边界

- `verify_real_hap.ps1` 检查双 ABI ELF machine、`real-ssh/libssh2` marker，并拒绝含 Mock shell marker 的“真实”包。
- HostKey 必须先显示 SHA256 指纹；未知和变更状态必须阻断认证，用户显式核对后才能继续。
- 密码、私钥口令和测试凭据不得进入命令行、日志、文档、截图或 manifest。
- shell/PTY、SFTP、转发、重连和清理分别需要真实服务器输出、文件哈希、流量与资源证据；验包本身不代表功能完成。
