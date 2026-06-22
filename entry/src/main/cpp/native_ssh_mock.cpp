#include "native_ssh_core.h"

#include <chrono>
#include <map>
#include <mutex>
#include <sstream>
#include <string>

namespace opentabssh {
namespace {

struct SessionState {
    bool connected = false;
};

struct ChannelState {
    std::string sessionId;
    std::string pendingOutput;
    int32_t cols = 80;
    int32_t rows = 24;
};

std::mutex g_mutex;
std::map<std::string, SessionState> g_sessions;
std::map<std::string, ChannelState> g_channels;
std::map<std::string, std::string> g_forwards;
uint64_t g_counter = 1;

std::string NextId(const std::string& prefix)
{
    std::lock_guard<std::mutex> lock(g_mutex);
    std::ostringstream oss;
    oss << prefix << "-" << g_counter++;
    return oss.str();
}

std::string EscapeJson(const std::string& text)
{
    std::ostringstream oss;
    for (char c : text) {
        switch (c) {
            case '\\': oss << "\\\\"; break;
            case '"': oss << "\\\""; break;
            case '\n': oss << "\\n"; break;
            case '\r': oss << "\\r"; break;
            case '\t': oss << "\\t"; break;
            default: oss << c; break;
        }
    }
    return oss.str();
}

std::string MockPrompt()
{
    return "\r\nOpenTabSsh mock shell ready.\r\n" \
           "This native module is compiled without libssh2.\r\n" \
           "Enable docs/LIBSSH2_COMPILE_GUIDE.md for real SSH.\r\n" \
           "root@opentabssh:~$ ";
}

} // namespace

std::string Version()
{
    return "OpenTabSsh Native Core 0.1.0 / mock-build / ABI-ready";
}

void SecureClear(std::string& value)
{
    volatile char* data = value.empty() ? nullptr : &value[0];
    for (size_t i = 0; i < value.size(); ++i) {
        data[i] = 0;
    }
    value.clear();
}

std::string CreateSession(std::string profileJson)
{
    std::string id = NextId("session");
    SecureClear(profileJson);
    std::lock_guard<std::mutex> lock(g_mutex);
    g_sessions[id] = SessionState{false};
    return id;
}

NativeResult Connect(const std::string& sessionId)
{
    std::lock_guard<std::mutex> lock(g_mutex);
    auto it = g_sessions.find(sessionId);
    if (it == g_sessions.end()) {
        return {false, 404, "session not found", ""};
    }
    it->second.connected = true;
    return {true, 0, "mock connected", sessionId};
}

NativeResult ConfirmHostKey(const std::string& sessionId, const std::string& fingerprint)
{
    std::lock_guard<std::mutex> lock(g_mutex);
    if (g_sessions.find(sessionId) == g_sessions.end()) {
        return {false, 404, "session not found", ""};
    }
    return {false, 501, "Mock Core has no SSH host key to confirm", fingerprint};
}

std::string OpenShell(const std::string& sessionId)
{
    std::string channelId = NextId("channel");
    std::lock_guard<std::mutex> lock(g_mutex);
    g_channels[channelId] = ChannelState{sessionId, MockPrompt(), 80, 24};
    return channelId;
}

NativeResult Write(const std::string& channelId, const std::string& data)
{
    std::lock_guard<std::mutex> lock(g_mutex);
    auto it = g_channels.find(channelId);
    if (it == g_channels.end()) {
        return {false, 404, "channel not found", ""};
    }
    std::string command = data;
    while (!command.empty() && (command.back() == '\n' || command.back() == '\r')) {
        command.pop_back();
    }

    std::ostringstream out;
    out << data;
    if (command == "clear") {
        out << "\r\n";
    } else if (command == "pwd") {
        out << "/home/opentabssh\r\n";
    } else if (command == "whoami") {
        out << "root\r\n";
    } else if (command == "ls" || command == "ls -la") {
        out << "drwxr-xr-x  2 root root 4096 .\r\n";
        out << "drwxr-xr-x 14 root root 4096 ..\r\n";
        out << "-rw-r--r--  1 root root  128 README.txt\r\n";
    } else if (command.rfind("echo ", 0) == 0) {
        out << command.substr(5) << "\r\n";
    } else {
        out << "mock: command executed: " << command << "\r\n";
    }
    out << "root@opentabssh:~$ ";
    it->second.pendingOutput += out.str();
    return {true, 0, "written", ""};
}

NativeResult Read(const std::string& channelId)
{
    std::lock_guard<std::mutex> lock(g_mutex);
    auto it = g_channels.find(channelId);
    if (it == g_channels.end()) {
        return {false, 404, "channel not found", ""};
    }
    std::string output = it->second.pendingOutput;
    it->second.pendingOutput.clear();
    return {true, 0, "read", output};
}

NativeResult Resize(const std::string& channelId, int32_t cols, int32_t rows)
{
    std::lock_guard<std::mutex> lock(g_mutex);
    auto it = g_channels.find(channelId);
    if (it == g_channels.end()) {
        return {false, 404, "channel not found", ""};
    }
    it->second.cols = cols;
    it->second.rows = rows;
    return {true, 0, "pty resized", ""};
}

NativeResult CloseChannel(const std::string& channelId)
{
    std::lock_guard<std::mutex> lock(g_mutex);
    g_channels.erase(channelId);
    return {true, 0, "channel closed", ""};
}

NativeResult Disconnect(const std::string& sessionId)
{
    std::lock_guard<std::mutex> lock(g_mutex);
    for (auto it = g_channels.begin(); it != g_channels.end();) {
        if (it->second.sessionId == sessionId) {
            it = g_channels.erase(it);
        } else {
            ++it;
        }
    }
    auto sessionIt = g_sessions.find(sessionId);
    if (sessionIt != g_sessions.end()) {
        sessionIt->second.connected = false;
    }
    return {true, 0, "session disconnected", ""};
}

NativeResult SftpList(const std::string& sessionId, const std::string& path)
{
    std::lock_guard<std::mutex> lock(g_mutex);
    if (g_sessions.find(sessionId) == g_sessions.end()) {
        return {false, 404, "session not found", ""};
    }
    std::string data = "["
        "{\"name\":\"home\",\"path\":\"/home\",\"type\":\"dir\",\"size\":0,\"modifiedTime\":\"mock\"},"
        "{\"name\":\"etc\",\"path\":\"/etc\",\"type\":\"dir\",\"size\":0,\"modifiedTime\":\"mock\"},"
        "{\"name\":\"README.txt\",\"path\":\"/README.txt\",\"type\":\"file\",\"size\":128,\"modifiedTime\":\"mock\"}"
        "]";
    return {true, 0, "sftp list", data};
}

std::string AddLocalForward(const std::string& sessionId, int32_t localPort, const std::string& remoteHost, int32_t remotePort)
{
    std::string id = NextId("lfwd");
    std::lock_guard<std::mutex> lock(g_mutex);
    std::ostringstream oss;
    oss << "local:" << sessionId << ":" << localPort << ":" << remoteHost << ":" << remotePort;
    g_forwards[id] = oss.str();
    return id;
}

std::string AddRemoteForward(const std::string& sessionId, int32_t remotePort, const std::string& localHost, int32_t localPort)
{
    std::string id = NextId("rfwd");
    std::lock_guard<std::mutex> lock(g_mutex);
    std::ostringstream oss;
    oss << "remote:" << sessionId << ":" << remotePort << ":" << localHost << ":" << localPort;
    g_forwards[id] = oss.str();
    return id;
}

std::string AddDynamicForward(const std::string& sessionId, int32_t localPort)
{
    std::string id = NextId("dfwd");
    std::lock_guard<std::mutex> lock(g_mutex);
    std::ostringstream oss;
    oss << "dynamic:" << sessionId << ":" << localPort;
    g_forwards[id] = oss.str();
    return id;
}

NativeResult RemoveForward(const std::string& forwardId)
{
    std::lock_guard<std::mutex> lock(g_mutex);
    g_forwards.erase(forwardId);
    return {true, 0, "forward removed", ""};
}

std::string ToJson(const NativeResult& result)
{
    std::ostringstream oss;
    oss << "{\"ok\":" << (result.ok ? "true" : "false")
        << ",\"code\":" << result.code
        << ",\"message\":\"" << EscapeJson(result.message) << "\""
        << ",\"data\":\"" << EscapeJson(result.data) << "\"}";
    return oss.str();
}

} // namespace opentabssh
