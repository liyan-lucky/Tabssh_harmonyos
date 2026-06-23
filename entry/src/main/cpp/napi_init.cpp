#include "native_ssh_core.h"
#include "napi/native_api.h"

#include <cstdint>
#include <exception>
#include <string>
#include <utility>

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

enum class AsyncOperation {
    CONNECT,
    OPEN_SHELL,
    WRITE,
    READ,
    RESIZE,
    CLOSE_CHANNEL,
    DISCONNECT,
    SFTP_LIST,
    SFTP_UPLOAD,
    SFTP_DOWNLOAD,
    SFTP_MKDIR,
    SFTP_REMOVE,
    SFTP_RENAME,
    SFTP_CHMOD
};

struct AsyncContext {
    napi_env env = nullptr;
    napi_async_work work = nullptr;
    napi_deferred deferred = nullptr;
    AsyncOperation operation = AsyncOperation::CONNECT;
    std::string first;
    std::string second;
    std::string third;
    int32_t firstNumber = 0;
    int32_t secondNumber = 0;
    std::string result;
    bool failed = false;
};

void ExecuteAsync(napi_env, void* rawContext)
{
    auto* context = static_cast<AsyncContext*>(rawContext);
    try {
        switch (context->operation) {
            case AsyncOperation::CONNECT:
                context->result = opentabssh::ToJson(opentabssh::Connect(context->first));
                break;
            case AsyncOperation::OPEN_SHELL:
                context->result = opentabssh::OpenShell(context->first);
                break;
            case AsyncOperation::WRITE:
                context->result = opentabssh::ToJson(opentabssh::Write(context->first, context->second));
                break;
            case AsyncOperation::READ:
                context->result = opentabssh::ToJson(opentabssh::Read(context->first));
                break;
            case AsyncOperation::RESIZE:
                context->result = opentabssh::ToJson(opentabssh::Resize(
                    context->first, context->firstNumber, context->secondNumber));
                break;
            case AsyncOperation::CLOSE_CHANNEL:
                context->result = opentabssh::ToJson(opentabssh::CloseChannel(context->first));
                break;
            case AsyncOperation::DISCONNECT:
                context->result = opentabssh::ToJson(opentabssh::Disconnect(context->first));
                break;
            case AsyncOperation::SFTP_LIST:
                context->result = opentabssh::ToJson(opentabssh::SftpList(context->first, context->second));
                break;
            case AsyncOperation::SFTP_UPLOAD:
                context->result = opentabssh::ToJson(opentabssh::SftpUpload(
                    context->first, context->second, context->third));
                break;
            case AsyncOperation::SFTP_DOWNLOAD:
                context->result = opentabssh::ToJson(opentabssh::SftpDownload(
                    context->first, context->second, context->third));
                break;
            case AsyncOperation::SFTP_MKDIR:
                context->result = opentabssh::ToJson(opentabssh::SftpMkdir(context->first, context->second));
                break;
            case AsyncOperation::SFTP_REMOVE:
                context->result = opentabssh::ToJson(opentabssh::SftpRemove(
                    context->first, context->second, context->firstNumber != 0));
                break;
            case AsyncOperation::SFTP_RENAME:
                context->result = opentabssh::ToJson(opentabssh::SftpRename(
                    context->first, context->second, context->third));
                break;
            case AsyncOperation::SFTP_CHMOD:
                context->result = opentabssh::ToJson(opentabssh::SftpChmod(
                    context->first, context->second, context->firstNumber));
                break;
        }
    } catch (const std::exception&) {
        context->failed = true;
        context->result = "native async operation failed";
    } catch (...) {
        context->failed = true;
        context->result = "native async operation failed";
    }
}

void CompleteAsync(napi_env env, napi_status status, void* rawContext)
{
    auto* context = static_cast<AsyncContext*>(rawContext);
    if (status == napi_ok && !context->failed) {
        napi_resolve_deferred(env, context->deferred, MakeString(env, context->result));
    } else {
        napi_value message = MakeString(env, context->result.empty() ? "native async work failed" : context->result);
        napi_value error = nullptr;
        napi_create_error(env, nullptr, message, &error);
        napi_reject_deferred(env, context->deferred, error);
    }
    napi_delete_async_work(env, context->work);
    delete context;
}

napi_value QueueAsync(napi_env env, AsyncOperation operation, std::string first, std::string second = "",
    std::string third = "", int32_t firstNumber = 0, int32_t secondNumber = 0)
{
    auto* context = new AsyncContext();
    context->env = env;
    context->operation = operation;
    context->first = std::move(first);
    context->second = std::move(second);
    context->third = std::move(third);
    context->firstNumber = firstNumber;
    context->secondNumber = secondNumber;

    napi_value promise = nullptr;
    if (napi_create_promise(env, &context->deferred, &promise) != napi_ok) {
        delete context;
        return nullptr;
    }
    napi_value resourceName = MakeString(env, "OpenTabSshNativeAsync");
    napi_status createStatus = napi_create_async_work(env, nullptr, resourceName, ExecuteAsync, CompleteAsync,
        context, &context->work);
    if (createStatus != napi_ok || napi_queue_async_work(env, context->work) != napi_ok) {
        napi_value message = MakeString(env, "failed to queue native async work");
        napi_value error = nullptr;
        napi_create_error(env, nullptr, message, &error);
        napi_reject_deferred(env, context->deferred, error);
        if (context->work != nullptr) napi_delete_async_work(env, context->work);
        delete context;
    }
    return promise;
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
    return MakeString(env, opentabssh::CreateSession(std::move(profileJson)));
}

napi_value Connect(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string sessionId = argc > 0 ? GetStringArg(env, args[0]) : "";
    return QueueAsync(env, AsyncOperation::CONNECT, std::move(sessionId));
}

napi_value OpenShell(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string sessionId = argc > 0 ? GetStringArg(env, args[0]) : "";
    return QueueAsync(env, AsyncOperation::OPEN_SHELL, std::move(sessionId));
}

napi_value ConfirmHostKey(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value args[2] = {nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string sessionId = argc > 0 ? GetStringArg(env, args[0]) : "";
    std::string fingerprint = argc > 1 ? GetStringArg(env, args[1]) : "";
    return MakeString(env, opentabssh::ToJson(opentabssh::ConfirmHostKey(sessionId, fingerprint)));
}

napi_value Write(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value args[2] = {nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string channelId = argc > 0 ? GetStringArg(env, args[0]) : "";
    std::string data = argc > 1 ? GetStringArg(env, args[1]) : "";
    return QueueAsync(env, AsyncOperation::WRITE, std::move(channelId), std::move(data));
}

napi_value Read(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string channelId = argc > 0 ? GetStringArg(env, args[0]) : "";
    return QueueAsync(env, AsyncOperation::READ, std::move(channelId));
}

napi_value Resize(napi_env env, napi_callback_info info)
{
    size_t argc = 3;
    napi_value args[3] = {nullptr, nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string channelId = argc > 0 ? GetStringArg(env, args[0]) : "";
    int32_t cols = argc > 1 ? GetIntArg(env, args[1]) : 80;
    int32_t rows = argc > 2 ? GetIntArg(env, args[2]) : 24;
    return QueueAsync(env, AsyncOperation::RESIZE, std::move(channelId), "", "", cols, rows);
}

napi_value CloseChannel(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string channelId = argc > 0 ? GetStringArg(env, args[0]) : "";
    return QueueAsync(env, AsyncOperation::CLOSE_CHANNEL, std::move(channelId));
}

napi_value Disconnect(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string sessionId = argc > 0 ? GetStringArg(env, args[0]) : "";
    return QueueAsync(env, AsyncOperation::DISCONNECT, std::move(sessionId));
}

napi_value SftpList(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value args[2] = {nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string sessionId = argc > 0 ? GetStringArg(env, args[0]) : "";
    std::string path = argc > 1 ? GetStringArg(env, args[1]) : "/";
    return QueueAsync(env, AsyncOperation::SFTP_LIST, std::move(sessionId), std::move(path));
}

napi_value SftpUpload(napi_env env, napi_callback_info info)
{
    size_t argc = 3;
    napi_value args[3] = {nullptr, nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string sessionId = argc > 0 ? GetStringArg(env, args[0]) : "";
    std::string localPath = argc > 1 ? GetStringArg(env, args[1]) : "";
    std::string remotePath = argc > 2 ? GetStringArg(env, args[2]) : "";
    return QueueAsync(env, AsyncOperation::SFTP_UPLOAD, std::move(sessionId), std::move(localPath),
        std::move(remotePath));
}

napi_value SftpDownload(napi_env env, napi_callback_info info)
{
    size_t argc = 3;
    napi_value args[3] = {nullptr, nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string sessionId = argc > 0 ? GetStringArg(env, args[0]) : "";
    std::string remotePath = argc > 1 ? GetStringArg(env, args[1]) : "";
    std::string localPath = argc > 2 ? GetStringArg(env, args[2]) : "";
    return QueueAsync(env, AsyncOperation::SFTP_DOWNLOAD, std::move(sessionId), std::move(remotePath),
        std::move(localPath));
}

napi_value SftpMkdir(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value args[2] = {nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string sessionId = argc > 0 ? GetStringArg(env, args[0]) : "";
    std::string path = argc > 1 ? GetStringArg(env, args[1]) : "";
    return QueueAsync(env, AsyncOperation::SFTP_MKDIR, std::move(sessionId), std::move(path));
}

napi_value SftpRemove(napi_env env, napi_callback_info info)
{
    size_t argc = 3;
    napi_value args[3] = {nullptr, nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string sessionId = argc > 0 ? GetStringArg(env, args[0]) : "";
    std::string path = argc > 1 ? GetStringArg(env, args[1]) : "";
    int32_t directory = argc > 2 ? GetIntArg(env, args[2]) : 0;
    return QueueAsync(env, AsyncOperation::SFTP_REMOVE, std::move(sessionId), std::move(path), "", directory);
}

napi_value SftpRename(napi_env env, napi_callback_info info)
{
    size_t argc = 3;
    napi_value args[3] = {nullptr, nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string sessionId = argc > 0 ? GetStringArg(env, args[0]) : "";
    std::string sourcePath = argc > 1 ? GetStringArg(env, args[1]) : "";
    std::string destinationPath = argc > 2 ? GetStringArg(env, args[2]) : "";
    return QueueAsync(env, AsyncOperation::SFTP_RENAME, std::move(sessionId), std::move(sourcePath),
        std::move(destinationPath));
}

napi_value SftpChmod(napi_env env, napi_callback_info info)
{
    size_t argc = 3;
    napi_value args[3] = {nullptr, nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    std::string sessionId = argc > 0 ? GetStringArg(env, args[0]) : "";
    std::string path = argc > 1 ? GetStringArg(env, args[1]) : "";
    int32_t mode = argc > 2 ? GetIntArg(env, args[2]) : 0;
    return QueueAsync(env, AsyncOperation::SFTP_CHMOD, std::move(sessionId), std::move(path), "", mode);
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
        {"confirmHostKey", nullptr, ConfirmHostKey, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"openShell", nullptr, OpenShell, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"write", nullptr, Write, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"read", nullptr, Read, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"resize", nullptr, Resize, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"closeChannel", nullptr, CloseChannel, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"disconnect", nullptr, Disconnect, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"sftpList", nullptr, SftpList, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"sftpUpload", nullptr, SftpUpload, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"sftpDownload", nullptr, SftpDownload, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"sftpMkdir", nullptr, SftpMkdir, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"sftpRemove", nullptr, SftpRemove, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"sftpRename", nullptr, SftpRename, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"sftpChmod", nullptr, SftpChmod, nullptr, nullptr, nullptr, napi_default, nullptr},
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
