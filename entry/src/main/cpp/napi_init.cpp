#include "native_ssh_core.h"
#include "napi/native_api.h"

#include <cstdint>
#include <string>

namespace {

std::string GetStringArg(napi_env env, napi_value value)
{
    size_t length = 0;
    napi_get_value_string_utf8(env, value, nullptr, 0, &length);
    std::string result(length + 1, '\0');
    napi_get_value_string_utf8(env, value, result.data(), result.size(), &length);
    result.resize(length);
    return result;
}

int32_t GetIntArg(napi_env env, napi_value value)
{
    int32_t result = 0;
    napi_get_value_int32(env, value, &result);
    return result;
}

napi_value MakeString(napi_env env, const std::string& value)
{
    napi_value result = nullptr;
    napi_create_string_utf8(env, value.c_str(), value.size(), &result);
    return result;
}

napi_value Version(napi_env env, napi_callback_info info)
{
    return MakeString(env, opentabssh::Version());
}

napi_value CreateSession(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string profileJson = argc > 0 ? GetStringArg(env, args[0]) : "{}";
    return MakeString(env, opentabssh::CreateSession(profileJson));
}

napi_value Connect(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string sessionId = argc > 0 ? GetStringArg(env, args[0]) : "";
    return MakeString(env, opentabssh::ToJson(opentabssh::Connect(sessionId)));
}

napi_value OpenShell(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string sessionId = argc > 0 ? GetStringArg(env, args[0]) : "";
    return MakeString(env, opentabssh::OpenShell(sessionId));
}

napi_value Write(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value args[2] = {nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string channelId = argc > 0 ? GetStringArg(env, args[0]) : "";
    std::string data = argc > 1 ? GetStringArg(env, args[1]) : "";
    return MakeString(env, opentabssh::ToJson(opentabssh::Write(channelId, data)));
}

napi_value Read(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string channelId = argc > 0 ? GetStringArg(env, args[0]) : "";
    return MakeString(env, opentabssh::ToJson(opentabssh::Read(channelId)));
}

napi_value Resize(napi_env env, napi_callback_info info)
{
    size_t argc = 3;
    napi_value args[3] = {nullptr, nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string channelId = argc > 0 ? GetStringArg(env, args[0]) : "";
    int32_t cols = argc > 1 ? GetIntArg(env, args[1]) : 80;
    int32_t rows = argc > 2 ? GetIntArg(env, args[2]) : 24;
    return MakeString(env, opentabssh::ToJson(opentabssh::Resize(channelId, cols, rows)));
}

napi_value CloseChannel(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string channelId = argc > 0 ? GetStringArg(env, args[0]) : "";
    return MakeString(env, opentabssh::ToJson(opentabssh::CloseChannel(channelId)));
}

napi_value Disconnect(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string sessionId = argc > 0 ? GetStringArg(env, args[0]) : "";
    return MakeString(env, opentabssh::ToJson(opentabssh::Disconnect(sessionId)));
}

napi_value SftpList(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value args[2] = {nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string sessionId = argc > 0 ? GetStringArg(env, args[0]) : "";
    std::string path = argc > 1 ? GetStringArg(env, args[1]) : "/";
    return MakeString(env, opentabssh::ToJson(opentabssh::SftpList(sessionId, path)));
}

napi_value AddLocalForward(napi_env env, napi_callback_info info)
{
    size_t argc = 4;
    napi_value args[4] = {nullptr, nullptr, nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string sessionId = argc > 0 ? GetStringArg(env, args[0]) : "";
    int32_t localPort = argc > 1 ? GetIntArg(env, args[1]) : 0;
    std::string remoteHost = argc > 2 ? GetStringArg(env, args[2]) : "127.0.0.1";
    int32_t remotePort = argc > 3 ? GetIntArg(env, args[3]) : 0;
    return MakeString(env, opentabssh::AddLocalForward(sessionId, localPort, remoteHost, remotePort));
}

napi_value AddRemoteForward(napi_env env, napi_callback_info info)
{
    size_t argc = 4;
    napi_value args[4] = {nullptr, nullptr, nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string sessionId = argc > 0 ? GetStringArg(env, args[0]) : "";
    int32_t remotePort = argc > 1 ? GetIntArg(env, args[1]) : 0;
    std::string localHost = argc > 2 ? GetStringArg(env, args[2]) : "127.0.0.1";
    int32_t localPort = argc > 3 ? GetIntArg(env, args[3]) : 0;
    return MakeString(env, opentabssh::AddRemoteForward(sessionId, remotePort, localHost, localPort));
}

napi_value AddDynamicForward(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value args[2] = {nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string sessionId = argc > 0 ? GetStringArg(env, args[0]) : "";
    int32_t localPort = argc > 1 ? GetIntArg(env, args[1]) : 0;
    return MakeString(env, opentabssh::AddDynamicForward(sessionId, localPort));
}

napi_value RemoveForward(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string forwardId = argc > 0 ? GetStringArg(env, args[0]) : "";
    return MakeString(env, opentabssh::ToJson(opentabssh::RemoveForward(forwardId)));
}

napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        {"version", nullptr, Version, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"createSession", nullptr, CreateSession, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"connect", nullptr, Connect, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"openShell", nullptr, OpenShell, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"write", nullptr, Write, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"read", nullptr, Read, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"resize", nullptr, Resize, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"closeChannel", nullptr, CloseChannel, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"disconnect", nullptr, Disconnect, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"sftpList", nullptr, SftpList, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addLocalForward", nullptr, AddLocalForward, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addRemoteForward", nullptr, AddRemoteForward, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addDynamicForward", nullptr, AddDynamicForward, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeForward", nullptr, RemoveForward, nullptr, nullptr, nullptr, napi_default, nullptr}
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

} // namespace

static napi_module g_module = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "entry",
    .nm_priv = nullptr,
    .reserved = {0}
};

extern "C" __attribute__((constructor)) void RegisterOpenTabSshModule(void)
{
    napi_module_register(&g_module);
}
