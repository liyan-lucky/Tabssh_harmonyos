#ifndef OPENTABSSH_NATIVE_SSH_CORE_H
#define OPENTABSSH_NATIVE_SSH_CORE_H

#include <cstdint>
#include <string>

namespace opentabssh {

struct NativeResult {
    bool ok;
    int32_t code;
    std::string message;
    std::string data;
};

std::string Version();
std::string CreateSession(std::string profileJson);
NativeResult Connect(const std::string& sessionId);
NativeResult ConfirmHostKey(const std::string& sessionId, const std::string& fingerprint);
std::string OpenShell(const std::string& sessionId);
NativeResult Write(const std::string& channelId, const std::string& data);
NativeResult Read(const std::string& channelId);
NativeResult Resize(const std::string& channelId, int32_t cols, int32_t rows);
NativeResult CloseChannel(const std::string& channelId);
NativeResult Disconnect(const std::string& sessionId);
NativeResult SftpList(const std::string& sessionId, const std::string& path);
std::string AddLocalForward(const std::string& sessionId, int32_t localPort, const std::string& remoteHost, int32_t remotePort);
std::string AddRemoteForward(const std::string& sessionId, int32_t remotePort, const std::string& localHost, int32_t localPort);
std::string AddDynamicForward(const std::string& sessionId, int32_t localPort);
NativeResult RemoveForward(const std::string& forwardId);

std::string ToJson(const NativeResult& result);

} // namespace opentabssh

#endif // OPENTABSSH_NATIVE_SSH_CORE_H
