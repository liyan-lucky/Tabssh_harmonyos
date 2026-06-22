// 真实 SSH Core 预留实现文件。
// 默认 CMake 不编译此文件，保证工程不依赖外部 so 即可先构建。
// 按 docs/LIBSSH2_COMPILE_GUIDE.md 编好 libssh2 后：
// 1) 在 CMakeLists.txt 中把 native_ssh_mock.cpp 替换为 native_ssh_libssh2.cpp
// 2) 添加 target_compile_definitions(entry PRIVATE OPEN_TAB_SSH_ENABLE_LIBSSH2=1)
// 3) 链接 libssh2/libssl/libcrypto/libz
//
// 下方保留的是可继续扩展的 libssh2 接口轮廓，不直接启用是为了避免缺失三方库时构建失败。

#ifdef OPEN_TAB_SSH_ENABLE_LIBSSH2

#include "native_ssh_core.h"
#include <libssh2.h>
#include <libssh2_sftp.h>

// TODO: 实装真实网络 socket、session handshake、auth、channel shell、SFTP、forwarding。
// 推荐实现顺序见 docs/IMPLEMENTATION_STEPS.md。

#else

// 未启用 OPEN_TAB_SSH_ENABLE_LIBSSH2 时，此文件不会参与编译。
// 如误加入 CMake，也不会导出任何符号。

#endif
