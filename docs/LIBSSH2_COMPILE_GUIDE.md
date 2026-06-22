# libssh2 接入和编译指导

> 2026-06-22 路径修订：三方源码、build、日志与生成 `.so` 不放仓库，统一使用 `%VSCODE_ROOT%\99_Temp\tabssh_harmonyos_dependencies`。下文仓库内 `third_party` 路径只表示构建 stage 的临时组装结构。当前 ABI 是 arm64-v8a 与 x86_64，不再以 armeabi-v7a 作为本项目目标。

当前工程默认使用 `native_ssh_mock.cpp`，可以不带任何三方库直接构建。真实 SSH 需要把 `libssh2`、`openssl`、`zlib` 编译为 HarmonyOS/OpenHarmony 目标 so 后链接进 `entry` native 模块。

## 一、目录建议

最终建议目录：

```text
entry/src/main/cpp/third_party/
├── libssh2/
│   ├── include/
│   └── libs/
│       ├── arm64-v8a/libssh2.so
│       └── x86_64/libssh2.so
├── openssl/
│   ├── include/
│   └── libs/
│       ├── arm64-v8a/libssl.so
│       ├── arm64-v8a/libcrypto.so
│       ├── x86_64/libssl.so
│       └── x86_64/libcrypto.so
└── zlib/
    ├── include/
    └── libs/
        ├── arm64-v8a/libz.so
        └── x86_64/libz.so
```

## 二、编译准备

安装 DevEco Studio，并确认本机有 HarmonyOS/OpenHarmony Native SDK。不同 DevEco 版本 SDK 路径略有不同，你需要在本机找到类似目录：

```bash
# 示例，按你电脑实际路径修改
export OHOS_NDK_HOME=/path/to/HarmonyOS/Sdk/default/openharmony/native
```

常见工具链文件位置类似：

```bash
$OHOS_NDK_HOME/build/cmake/ohos.toolchain.cmake
```

## 三、编译 zlib / OpenSSL / libssh2 思路

libssh2 依赖加密库，建议选择 OpenSSL 后端。编译顺序：

```text
zlib → OpenSSL → libssh2
```

如果你已经有 HarmonyOS 可用的 `libssl.so`、`libcrypto.so`、`libz.so`，可以跳过前两步。

## 四、libssh2 CMake 示例

下面是示例命令，实际参数要按你下载的 libssh2 源码版本和 SDK 路径调整：

```bash
export OHOS_NDK_HOME=/path/to/HarmonyOS/Sdk/default/openharmony/native
export TOOLCHAIN=$OHOS_NDK_HOME/build/cmake/ohos.toolchain.cmake

cmake -S ./libssh2 -B ./build-libssh2-arm64 \
  -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN \
  -DOHOS_ARCH=arm64-v8a \
  -DBUILD_SHARED_LIBS=ON \
  -DBUILD_EXAMPLES=OFF \
  -DBUILD_TESTING=OFF \
  -DCRYPTO_BACKEND=OpenSSL \
  -DOPENSSL_ROOT_DIR=/absolute/path/to/openssl-ohos-arm64 \
  -DZLIB_ROOT=/absolute/path/to/zlib-ohos-arm64

cmake --build ./build-libssh2-arm64 --config Release
```

生成后，把 `libssh2.so` 和头文件复制到：

```text
entry/src/main/cpp/third_party/libssh2/include
entry/src/main/cpp/third_party/libssh2/libs/arm64-v8a/libssh2.so
```

## 五、切换 CMake

打开：

```text
entry/src/main/cpp/CMakeLists.txt
```

把：

```cmake
add_library(entry SHARED
    napi_init.cpp
    native_ssh_mock.cpp
)
```

改成：

```cmake
add_library(entry SHARED
    napi_init.cpp
    native_ssh_libssh2.cpp
)

target_compile_definitions(entry PRIVATE OPEN_TAB_SSH_ENABLE_LIBSSH2=1)
```

然后放开文件里的三方 include 和 so 链接配置。

## 六、真实 SSH 实现顺序

建议不要一次性做完所有功能，按下面顺序加：

1. socket connect：`host:port`
2. `libssh2_session_init_ex`
3. `libssh2_session_handshake`
4. HostKey fingerprint 获取
5. password auth：`libssh2_userauth_password`
6. shell channel：`libssh2_channel_open_session`
7. PTY：`libssh2_channel_request_pty_ex`
8. shell：`libssh2_channel_shell`
9. write：`libssh2_channel_write`
10. read：`libssh2_channel_read`
11. resize：`libssh2_channel_request_pty_size_ex`
12. private key auth：`libssh2_userauth_publickey_fromfile_ex`
13. SFTP：`libssh2_sftp_init`、`libssh2_sftp_opendir`、`libssh2_sftp_readdir`
14. forwarding：`libssh2_channel_direct_tcpip_ex` / listener API

## 七、为什么默认不直接带 libssh2

因为 libssh2 不是 HarmonyOS SDK 自带库，不同 DevEco Studio、HarmonyOS NEXT/OpenHarmony SDK、CPU ABI 路径差异较大。直接把未编译的外部依赖写死进工程，会导致你导入就构建失败。所以本包默认用 mock native core，让页面、路由、N-API、CMake 先跑通；然后你再按本机 SDK 编译 libssh2 接入。
