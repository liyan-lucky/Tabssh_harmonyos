cmake_minimum_required(VERSION 3.5.0)
project(opentabssh_native)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})
include_directories(${NATIVERENDER_ROOT_PATH})

set(TABSSH_THIRD_PARTY_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/third_party")
set(TABSSH_ABI_LIB_ROOT "${TABSSH_THIRD_PARTY_ROOT}/libs/${OHOS_ARCH}")
set(TABSSH_REAL_SSH_READY TRUE)
foreach(required_file
    "${TABSSH_THIRD_PARTY_ROOT}/libssh2/include/libssh2.h"
    "${TABSSH_THIRD_PARTY_ROOT}/openssl/include/${OHOS_ARCH}/openssl/ssl.h"
    "${TABSSH_THIRD_PARTY_ROOT}/zlib/include/zlib.h"
    "${TABSSH_ABI_LIB_ROOT}/libssh2.a"
    "${TABSSH_ABI_LIB_ROOT}/libssl.a"
    "${TABSSH_ABI_LIB_ROOT}/libcrypto.a"
    "${TABSSH_ABI_LIB_ROOT}/libz.a")
    if(NOT EXISTS "${required_file}")
        set(TABSSH_REAL_SSH_READY FALSE)
    endif()
endforeach()

if(TABSSH_REAL_SSH_READY)
    set(TABSSH_CORE_SOURCE native_ssh_libssh2.cpp)
    message(STATUS "OpenTabSsh: building real libssh2 core for ${OHOS_ARCH}")
else()
    set(TABSSH_CORE_SOURCE native_ssh_mock.cpp)
    message(WARNING "OpenTabSsh: third-party libraries are absent; building explicit Mock core")
endif()

add_library(entry SHARED
    napi_init.cpp
    ${TABSSH_CORE_SOURCE}
)

target_compile_features(entry PRIVATE cxx_std_17)
target_compile_options(entry PRIVATE -Wall -Wextra -Wno-unused-parameter)

if(TABSSH_REAL_SSH_READY)
    target_compile_definitions(entry PRIVATE OPEN_TAB_SSH_ENABLE_LIBSSH2=1)
    target_include_directories(entry PRIVATE
        "${TABSSH_THIRD_PARTY_ROOT}/libssh2/include"
        "${TABSSH_THIRD_PARTY_ROOT}/openssl/include/${OHOS_ARCH}"
        "${TABSSH_THIRD_PARTY_ROOT}/zlib/include"
    )
    add_library(tabssh_ssh2 STATIC IMPORTED)
    set_target_properties(tabssh_ssh2 PROPERTIES IMPORTED_LOCATION "${TABSSH_ABI_LIB_ROOT}/libssh2.a")
    add_library(tabssh_ssl STATIC IMPORTED)
    set_target_properties(tabssh_ssl PROPERTIES IMPORTED_LOCATION "${TABSSH_ABI_LIB_ROOT}/libssl.a")
    add_library(tabssh_crypto STATIC IMPORTED)
    set_target_properties(tabssh_crypto PROPERTIES IMPORTED_LOCATION "${TABSSH_ABI_LIB_ROOT}/libcrypto.a")
    add_library(tabssh_z STATIC IMPORTED)
    set_target_properties(tabssh_z PROPERTIES IMPORTED_LOCATION "${TABSSH_ABI_LIB_ROOT}/libz.a")
    target_link_libraries(entry PRIVATE tabssh_ssh2 tabssh_ssl tabssh_crypto tabssh_z libdl.so)
endif()

target_link_libraries(entry PUBLIC
    libace_napi.z.so
    libhilog_ndk.z.so
)

# `scripts/build_real_hap.ps1` stages pinned headers and static libraries under
# `third_party`; a normal source checkout intentionally has no generated third-party
# binaries and therefore remains an explicit Mock build.
