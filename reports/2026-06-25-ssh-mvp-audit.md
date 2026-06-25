# 2026-06-25 SSH MVP 审计摘要

## 对照对象

- HarmonyOS：`liyan-lucky/Tabssh_harmonyos`
- Android 原版：`tabssh/android`

## 结论

HarmonyOS 当前是可构建 Mock 骨架，不是可发布 SSH 客户端。第一批优化应先固定真实 SSH MVP 工程边界，再逐步接入 libssh2。

## 本次处理

- CMake 增加 `OPEN_TAB_SSH_ENABLE_LIBSSH2` 开关。
- 默认继续编译 `native_ssh_mock.cpp`，避免干净仓库缺三方库时构建失败。
- 开启开关后切换 `native_ssh_libssh2.cpp`，并从 `third_party/` 链接 `libssh2/OpenSSL/zlib`。
- 新增 `docs/SSH_MVP_ROADMAP.md`，定义真实 SSH MVP 范围、`profileJson` 字段、错误码、HostKey 和验收标准。
- 同步更新 `docs/README.md`、`docs/PROGRESS.md`、`docs/CORE.md`、`docs/IMPLEMENTATION_STEPS.md`。

## 未执行

- 未在本环境运行 DevEco/Hvigor 构建。
- 未编译 HarmonyOS 版 OpenSSL/zlib/libssh2。
- 未实现真实 socket/libssh2 连接。

## 下一步建议

1. 在 `99_Temp\tabssh_harmonyos_dependencies` 编译 OpenSSL、zlib、libssh2 的 arm64-v8a/x86_64 产物。
2. 把头文件和 `.so` 按 CMake 约定放入 `entry/src/main/cpp/third_party/` 的项目专属可再生目录或 stage 目录。
3. 实现 `native_ssh_libssh2.cpp` 的 socket、handshake、password auth、shell channel、read/write/resize/disconnect。
4. 再做 HostKey 最小确认和 known_hosts 存储。
