cmake_minimum_required(VERSION 3.5.0)
project(opentabssh_native)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})
include_directories(${NATIVERENDER_ROOT_PATH})

add_library(entry SHARED
    napi_init.cpp
    native_ssh_mock.cpp
)

target_compile_features(entry PRIVATE cxx_std_17)
target_compile_options(entry PRIVATE -Wall -Wextra -Wno-unused-parameter)

target_link_libraries(entry PUBLIC
    libace_napi.z.so
    libhilog_ndk.z.so
)

# 真实 libssh2 接入方式：
# 1. 按 docs/LIBSSH2_COMPILE_GUIDE.md 编译 libssh2 / openssl / zlib。
# 2. 将 include 和 so 放到 entry/src/main/cpp/third_party/。
# 3. 把 native_ssh_mock.cpp 从 add_library 中移除，改为 native_ssh_libssh2.cpp。
# 4. 打开下面示例路径并按实际 SDK/ABI 调整。
#
# target_compile_definitions(entry PRIVATE OPEN_TAB_SSH_ENABLE_LIBSSH2=1)
# target_include_directories(entry PRIVATE
#     ${NATIVERENDER_ROOT_PATH}/third_party/libssh2/include
#     ${NATIVERENDER_ROOT_PATH}/third_party/openssl/include
# )
# add_library(ssh2 SHARED IMPORTED)
# set_target_properties(ssh2 PROPERTIES IMPORTED_LOCATION
#     ${NATIVERENDER_ROOT_PATH}/third_party/libssh2/libs/${OHOS_ARCH}/libssh2.so)
# add_library(crypto SHARED IMPORTED)
# set_target_properties(crypto PROPERTIES IMPORTED_LOCATION
#     ${NATIVERENDER_ROOT_PATH}/third_party/openssl/libs/${OHOS_ARCH}/libcrypto.so)
# add_library(ssl SHARED IMPORTED)
# set_target_properties(ssl PROPERTIES IMPORTED_LOCATION
#     ${NATIVERENDER_ROOT_PATH}/third_party/openssl/libs/${OHOS_ARCH}/libssl.so)
# target_link_libraries(entry PRIVATE ssh2 ssl crypto)
