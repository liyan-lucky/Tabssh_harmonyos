cmake_minimum_required(VERSION 3.5.0)
project(opentabssh_native)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})
include_directories(${NATIVERENDER_ROOT_PATH})

# Default stays Mock so a clean checkout can still build without third-party SSH libs.
# Enable with -DOPEN_TAB_SSH_ENABLE_LIBSSH2=ON only after the HarmonyOS
# arm64-v8a/x86_64 openssl + zlib + libssh2 artifacts exist under third_party/.
option(OPEN_TAB_SSH_ENABLE_LIBSSH2 "Build native core with real libssh2 backend" OFF)

set(OPENTABSSH_NATIVE_SOURCES
    napi_init.cpp
)

if(OPEN_TAB_SSH_ENABLE_LIBSSH2)
    list(APPEND OPENTABSSH_NATIVE_SOURCES native_ssh_libssh2.cpp)
else()
    list(APPEND OPENTABSSH_NATIVE_SOURCES native_ssh_mock.cpp)
endif()

add_library(entry SHARED
    ${OPENTABSSH_NATIVE_SOURCES}
)

target_compile_features(entry PRIVATE cxx_std_17)
target_compile_options(entry PRIVATE -Wall -Wextra -Wno-unused-parameter)

target_link_libraries(entry PUBLIC
    libace_napi.z.so
    libhilog_ndk.z.so
)

if(OPEN_TAB_SSH_ENABLE_LIBSSH2)
    target_compile_definitions(entry PRIVATE OPEN_TAB_SSH_ENABLE_LIBSSH2=1)

    target_include_directories(entry PRIVATE
        ${NATIVERENDER_ROOT_PATH}/third_party/libssh2/include
        ${NATIVERENDER_ROOT_PATH}/third_party/openssl/include
        ${NATIVERENDER_ROOT_PATH}/third_party/zlib/include
    )

    add_library(ssh2 SHARED IMPORTED)
    set_target_properties(ssh2 PROPERTIES IMPORTED_LOCATION
        ${NATIVERENDER_ROOT_PATH}/third_party/libssh2/libs/${OHOS_ARCH}/libssh2.so)

    add_library(crypto SHARED IMPORTED)
    set_target_properties(crypto PROPERTIES IMPORTED_LOCATION
        ${NATIVERENDER_ROOT_PATH}/third_party/openssl/libs/${OHOS_ARCH}/libcrypto.so)

    add_library(ssl SHARED IMPORTED)
    set_target_properties(ssl PROPERTIES IMPORTED_LOCATION
        ${NATIVERENDER_ROOT_PATH}/third_party/openssl/libs/${OHOS_ARCH}/libssl.so)

    add_library(zlib SHARED IMPORTED)
    set_target_properties(zlib PROPERTIES IMPORTED_LOCATION
        ${NATIVERENDER_ROOT_PATH}/third_party/zlib/libs/${OHOS_ARCH}/libz.so)

    target_link_libraries(entry PRIVATE ssh2 ssl crypto zlib)
endif()
