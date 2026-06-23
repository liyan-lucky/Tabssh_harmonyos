#include "native_ssh_core.h"

#ifdef OPEN_TAB_SSH_ENABLE_LIBSSH2

#include <libssh2.h>
#include <libssh2_sftp.h>

#include <algorithm>
#include <arpa/inet.h>
#include <array>
#include <atomic>
#include <cerrno>
#include <chrono>
#include <cctype>
#include <condition_variable>
#include <cstdio>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <fcntl.h>
#include <fstream>
#include <map>
#include <memory>
#include <mutex>
#include <netdb.h>
#include <netinet/in.h>
#include <poll.h>
#include <sstream>
#include <string>
#include <sys/socket.h>
#include <thread>
#include <unistd.h>
#include <vector>

namespace opentabssh {
namespace {

constexpr int32_t kHostKeyUnknown = 1001;
constexpr int32_t kHostKeyChanged = 1002;
constexpr int32_t kAuthenticationFailed = 1003;
constexpr int32_t kTimeout = 1004;
constexpr int32_t kInvalidProfile = 1005;
constexpr int32_t kNotConnected = 1006;

struct ProfileConfig {
    std::string host;
    int32_t port = 22;
    std::string username;
    std::string authType = "password";
    std::string password;
    std::string privateKeyPath;
    std::string privateKeyPassphrase;
    std::string terminalType = "xterm-256color";
    std::string expectedHostKey;
    int32_t keepAliveSeconds = 60;
    int32_t timeoutMilliseconds = 15000;
};

struct SessionState {
    ProfileConfig profile;
    int socketFd = -1;
    LIBSSH2_SESSION* session = nullptr;
    LIBSSH2_SFTP* sftp = nullptr;
    bool handshakeComplete = false;
    bool hostKeyConfirmed = false;
    bool authenticated = false;
    bool disconnecting = false;
    std::string observedHostKey;
    std::string observedHostKeyAlgorithm;
};

struct ChannelState {
    std::string sessionId;
    LIBSSH2_CHANNEL* channel = nullptr;
    int32_t cols = 80;
    int32_t rows = 24;
};

enum class ForwardKind {
    LOCAL,
    REMOTE,
    DYNAMIC
};

struct ForwardState {
    std::string id;
    std::string sessionId;
    ForwardKind kind = ForwardKind::LOCAL;
    std::string targetHost;
    int32_t bindPort = 0;
    int32_t targetPort = 0;
    int listenFd = -1;
    LIBSSH2_LISTENER* remoteListener = nullptr;
    std::atomic<bool> stopping{false};
    std::atomic<int32_t> activeConnections{0};
    std::mutex connectionMutex;
    std::condition_variable connectionCondition;
    std::mutex stopMutex;
    bool stopped = false;
    std::thread worker;
};

class Libssh2Runtime {
public:
    Libssh2Runtime() : status(libssh2_init(0)) {}
    ~Libssh2Runtime()
    {
        if (status == 0) {
            libssh2_exit();
        }
    }
    int status;
};

Libssh2Runtime g_runtime;
std::mutex g_mutex;
std::map<std::string, std::unique_ptr<SessionState>> g_sessions;
std::map<std::string, ChannelState> g_channels;
std::mutex g_forwardMutex;
std::map<std::string, std::shared_ptr<ForwardState>> g_forwards;
uint64_t g_counter = 1;

void SecureClear(std::string& value)
{
    volatile char* bytes = value.empty() ? nullptr : &value[0];
    for (size_t index = 0; index < value.size(); ++index) {
        bytes[index] = 0;
    }
    value.clear();
    value.shrink_to_fit();
}

void ClearCredentials(ProfileConfig& profile)
{
    SecureClear(profile.password);
    SecureClear(profile.privateKeyPassphrase);
}

std::string NextId(const char* prefix)
{
    std::ostringstream output;
    output << prefix << '-' << g_counter++;
    return output.str();
}

std::string EscapeJson(const std::string& text)
{
    std::ostringstream output;
    static const char* hex = "0123456789abcdef";
    for (unsigned char character : text) {
        switch (character) {
            case '\\': output << "\\\\"; break;
            case '"': output << "\\\""; break;
            case '\b': output << "\\b"; break;
            case '\f': output << "\\f"; break;
            case '\n': output << "\\n"; break;
            case '\r': output << "\\r"; break;
            case '\t': output << "\\t"; break;
            default:
                if (character < 0x20) {
                    output << "\\u00" << hex[(character >> 4) & 0x0f] << hex[character & 0x0f];
                } else {
                    output << static_cast<char>(character);
                }
        }
    }
    return output.str();
}

void AppendUtf8(std::string& output, uint32_t codePoint)
{
    if (codePoint <= 0x7f) {
        output.push_back(static_cast<char>(codePoint));
    } else if (codePoint <= 0x7ff) {
        output.push_back(static_cast<char>(0xc0 | (codePoint >> 6)));
        output.push_back(static_cast<char>(0x80 | (codePoint & 0x3f)));
    } else {
        output.push_back(static_cast<char>(0xe0 | (codePoint >> 12)));
        output.push_back(static_cast<char>(0x80 | ((codePoint >> 6) & 0x3f)));
        output.push_back(static_cast<char>(0x80 | (codePoint & 0x3f)));
    }
}

bool ParseJsonString(const std::string& json, size_t start, std::string& value, size_t& end)
{
    if (start >= json.size() || json[start] != '"') {
        return false;
    }
    value.clear();
    for (size_t index = start + 1; index < json.size(); ++index) {
        char character = json[index];
        if (character == '"') {
            end = index + 1;
            return true;
        }
        if (character != '\\') {
            value.push_back(character);
            continue;
        }
        if (++index >= json.size()) {
            return false;
        }
        switch (json[index]) {
            case '"': value.push_back('"'); break;
            case '\\': value.push_back('\\'); break;
            case '/': value.push_back('/'); break;
            case 'b': value.push_back('\b'); break;
            case 'f': value.push_back('\f'); break;
            case 'n': value.push_back('\n'); break;
            case 'r': value.push_back('\r'); break;
            case 't': value.push_back('\t'); break;
            case 'u': {
                if (index + 4 >= json.size()) {
                    return false;
                }
                uint32_t codePoint = 0;
                for (size_t offset = 1; offset <= 4; ++offset) {
                    char digit = json[index + offset];
                    codePoint <<= 4;
                    if (digit >= '0' && digit <= '9') codePoint |= static_cast<uint32_t>(digit - '0');
                    else if (digit >= 'a' && digit <= 'f') codePoint |= static_cast<uint32_t>(digit - 'a' + 10);
                    else if (digit >= 'A' && digit <= 'F') codePoint |= static_cast<uint32_t>(digit - 'A' + 10);
                    else return false;
                }
                AppendUtf8(value, codePoint);
                index += 4;
                break;
            }
            default: return false;
        }
    }
    return false;
}

size_t FindJsonValue(const std::string& json, const std::string& key)
{
    const std::string token = "\"" + key + "\"";
    size_t position = 0;
    while ((position = json.find(token, position)) != std::string::npos) {
        size_t cursor = position + token.size();
        while (cursor < json.size() && std::isspace(static_cast<unsigned char>(json[cursor]))) ++cursor;
        if (cursor < json.size() && json[cursor] == ':') {
            ++cursor;
            while (cursor < json.size() && std::isspace(static_cast<unsigned char>(json[cursor]))) ++cursor;
            return cursor;
        }
        position += token.size();
    }
    return std::string::npos;
}

std::string JsonString(const std::string& json, const std::string& key, const std::string& fallback = "")
{
    size_t start = FindJsonValue(json, key);
    if (start == std::string::npos) return fallback;
    std::string value;
    size_t end = start;
    return ParseJsonString(json, start, value, end) ? value : fallback;
}

int32_t JsonInt(const std::string& json, const std::string& key, int32_t fallback)
{
    size_t start = FindJsonValue(json, key);
    if (start == std::string::npos) return fallback;
    char* end = nullptr;
    long value = std::strtol(json.c_str() + start, &end, 10);
    if (end == json.c_str() + start || value < INT32_MIN || value > INT32_MAX) return fallback;
    return static_cast<int32_t>(value);
}

ProfileConfig ParseProfile(std::string& json)
{
    ProfileConfig profile;
    profile.host = JsonString(json, "host");
    profile.port = JsonInt(json, "port", 22);
    profile.username = JsonString(json, "username");
    profile.authType = JsonString(json, "authType", "password");
    profile.password = JsonString(json, "password");
    profile.privateKeyPath = JsonString(json, "privateKeyPath");
    profile.privateKeyPassphrase = JsonString(json, "privateKeyPassphrase");
    profile.terminalType = JsonString(json, "terminalType", "xterm-256color");
    profile.expectedHostKey = JsonString(json, "hostKeyFingerprint");
    profile.keepAliveSeconds = std::max(0, JsonInt(json, "keepAliveSeconds", 60));
    profile.timeoutMilliseconds = std::max(1000, JsonInt(json, "timeoutMilliseconds", 15000));
    SecureClear(json);
    return profile;
}

bool ConstantTimeEqual(const std::string& left, const std::string& right)
{
    size_t maximum = std::max(left.size(), right.size());
    size_t difference = left.size() ^ right.size();
    for (size_t index = 0; index < maximum; ++index) {
        unsigned char a = index < left.size() ? static_cast<unsigned char>(left[index]) : 0;
        unsigned char b = index < right.size() ? static_cast<unsigned char>(right[index]) : 0;
        difference |= static_cast<size_t>(a ^ b);
    }
    return difference == 0;
}

NativeResult InvalidProfileResult(const ProfileConfig& profile)
{
    if (profile.host.empty()) return {false, kInvalidProfile, "host is required", ""};
    if (profile.username.empty()) return {false, kInvalidProfile, "username is required", ""};
    if (profile.port < 1 || profile.port > 65535) return {false, kInvalidProfile, "port is out of range", ""};
    if (profile.authType == "privateKey" && profile.privateKeyPath.empty()) {
        return {false, kInvalidProfile, "private key path is required", ""};
    }
    if (profile.authType != "password" && profile.authType != "privateKey") {
        return {false, kInvalidProfile, "unsupported authentication type", ""};
    }
    return {true, 0, "profile valid", ""};
}

int RemainingMilliseconds(const std::chrono::steady_clock::time_point& deadline)
{
    auto remaining = std::chrono::duration_cast<std::chrono::milliseconds>(deadline - std::chrono::steady_clock::now()).count();
    if (remaining <= 0) return 0;
    return remaining > INT32_MAX ? INT32_MAX : static_cast<int>(remaining);
}

bool WaitSocket(LIBSSH2_SESSION* session, int socketFd, const std::chrono::steady_clock::time_point& deadline)
{
    int timeout = RemainingMilliseconds(deadline);
    if (timeout <= 0) return false;
    int directions = libssh2_session_block_directions(session);
    short events = 0;
    if ((directions & LIBSSH2_SESSION_BLOCK_INBOUND) != 0) events |= POLLIN;
    if ((directions & LIBSSH2_SESSION_BLOCK_OUTBOUND) != 0) events |= POLLOUT;
    if (events == 0) events = POLLIN | POLLOUT;
    pollfd descriptor{socketFd, events, 0};
    int result;
    do {
        result = poll(&descriptor, 1, timeout);
    } while (result < 0 && errno == EINTR);
    return result > 0 && (descriptor.revents & (POLLERR | POLLHUP | POLLNVAL)) == 0;
}

std::string SessionError(LIBSSH2_SESSION* session, const std::string& fallback)
{
    char* message = nullptr;
    int length = 0;
    libssh2_session_last_error(session, &message, &length, 0);
    if (message != nullptr && length > 0) {
        return std::string(message, static_cast<size_t>(length));
    }
    return fallback;
}

int ConnectTcp(const std::string& host, int32_t port, int timeoutMilliseconds, std::string& error)
{
    addrinfo hints{};
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;
    addrinfo* addresses = nullptr;
    std::string service = std::to_string(port);
    int lookup = getaddrinfo(host.c_str(), service.c_str(), &hints, &addresses);
    if (lookup != 0) {
        error = std::string("DNS resolution failed: ") + gai_strerror(lookup);
        return -1;
    }
    int connectedSocket = -1;
    for (addrinfo* address = addresses; address != nullptr; address = address->ai_next) {
        int socketFd = socket(address->ai_family, address->ai_socktype, address->ai_protocol);
        if (socketFd < 0) continue;
        int flags = fcntl(socketFd, F_GETFL, 0);
        if (flags < 0 || fcntl(socketFd, F_SETFL, flags | O_NONBLOCK) < 0) {
            close(socketFd);
            continue;
        }
        int result = connect(socketFd, address->ai_addr, address->ai_addrlen);
        if (result == 0) {
            connectedSocket = socketFd;
            break;
        }
        if (errno != EINPROGRESS) {
            close(socketFd);
            continue;
        }
        pollfd descriptor{socketFd, POLLOUT, 0};
        do {
            result = poll(&descriptor, 1, timeoutMilliseconds);
        } while (result < 0 && errno == EINTR);
        if (result > 0 && (descriptor.revents & POLLOUT) != 0) {
            int socketError = 0;
            socklen_t errorLength = sizeof(socketError);
            if (getsockopt(socketFd, SOL_SOCKET, SO_ERROR, &socketError, &errorLength) == 0 && socketError == 0) {
                connectedSocket = socketFd;
                break;
            }
        }
        close(socketFd);
    }
    freeaddrinfo(addresses);
    if (connectedSocket < 0) error = "TCP connection failed or timed out";
    return connectedSocket;
}

std::string HostKeyAlgorithm(int type)
{
    switch (type) {
        case LIBSSH2_HOSTKEY_TYPE_RSA: return "ssh-rsa";
        case LIBSSH2_HOSTKEY_TYPE_DSS: return "ssh-dss";
#ifdef LIBSSH2_HOSTKEY_TYPE_ECDSA_256
        case LIBSSH2_HOSTKEY_TYPE_ECDSA_256: return "ecdsa-sha2-nistp256";
        case LIBSSH2_HOSTKEY_TYPE_ECDSA_384: return "ecdsa-sha2-nistp384";
        case LIBSSH2_HOSTKEY_TYPE_ECDSA_521: return "ecdsa-sha2-nistp521";
#endif
#ifdef LIBSSH2_HOSTKEY_TYPE_ED25519
        case LIBSSH2_HOSTKEY_TYPE_ED25519: return "ssh-ed25519";
#endif
        default: return "unknown";
    }
}

std::string Base64(const unsigned char* data, size_t length)
{
    static const char alphabet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    std::string encoded;
    encoded.reserve(((length + 2) / 3) * 4);
    for (size_t index = 0; index < length; index += 3) {
        uint32_t block = static_cast<uint32_t>(data[index]) << 16;
        bool hasSecond = index + 1 < length;
        bool hasThird = index + 2 < length;
        if (hasSecond) block |= static_cast<uint32_t>(data[index + 1]) << 8;
        if (hasThird) block |= static_cast<uint32_t>(data[index + 2]);
        encoded.push_back(alphabet[(block >> 18) & 0x3f]);
        encoded.push_back(alphabet[(block >> 12) & 0x3f]);
        if (hasSecond) encoded.push_back(alphabet[(block >> 6) & 0x3f]);
        if (hasThird) encoded.push_back(alphabet[block & 0x3f]);
    }
    return encoded;
}

bool CaptureHostKey(SessionState& state)
{
    size_t keyLength = 0;
    int keyType = 0;
    if (libssh2_session_hostkey(state.session, &keyLength, &keyType) == nullptr || keyLength == 0) return false;
    const char* hash = libssh2_hostkey_hash(state.session, LIBSSH2_HOSTKEY_HASH_SHA256);
    if (hash == nullptr) return false;
    std::string base64 = Base64(reinterpret_cast<const unsigned char*>(hash), 32);
    state.observedHostKey = "SHA256:" + base64;
    state.observedHostKeyAlgorithm = HostKeyAlgorithm(keyType);
    state.hostKeyConfirmed = !state.profile.expectedHostKey.empty() &&
        ConstantTimeEqual(state.profile.expectedHostKey, state.observedHostKey);
    return true;
}

std::string HostKeyData(const SessionState& state)
{
    return "{\"fingerprint\":\"" + EscapeJson(state.observedHostKey) +
        "\",\"algorithm\":\"" + EscapeJson(state.observedHostKeyAlgorithm) + "\"}";
}

void CloseNetwork(SessionState& state)
{
    auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(2000);
    if (state.sftp != nullptr) {
        int result;
        do {
            result = libssh2_sftp_shutdown(state.sftp);
        } while (result == LIBSSH2_ERROR_EAGAIN && state.session != nullptr && state.socketFd >= 0 &&
            WaitSocket(state.session, state.socketFd, deadline));
        state.sftp = nullptr;
    }
    if (state.session != nullptr) {
        int result;
        do {
            result = libssh2_session_disconnect_ex(
                state.session, SSH_DISCONNECT_BY_APPLICATION, "OpenTabSsh disconnect", "en");
        } while (result == LIBSSH2_ERROR_EAGAIN && state.socketFd >= 0 &&
            WaitSocket(state.session, state.socketFd, deadline));
        do {
            result = libssh2_session_free(state.session);
        } while (result == LIBSSH2_ERROR_EAGAIN && state.socketFd >= 0 &&
            WaitSocket(state.session, state.socketFd, deadline));
        state.session = nullptr;
    }
    if (state.socketFd >= 0) {
        close(state.socketFd);
        state.socketFd = -1;
    }
    state.handshakeComplete = false;
    state.hostKeyConfirmed = false;
    state.authenticated = false;
    state.observedHostKey.clear();
    state.observedHostKeyAlgorithm.clear();
}

NativeResult EnsureHandshake(SessionState& state)
{
    if (state.handshakeComplete) return {true, 0, "handshake complete", ""};
    std::string socketError;
    state.socketFd = ConnectTcp(state.profile.host, state.profile.port, state.profile.timeoutMilliseconds, socketError);
    if (state.socketFd < 0) return {false, kTimeout, socketError, ""};
    state.session = libssh2_session_init_ex(nullptr, nullptr, nullptr, nullptr);
    if (state.session == nullptr) {
        close(state.socketFd);
        state.socketFd = -1;
        return {false, -1, "libssh2 session allocation failed", ""};
    }
    libssh2_session_set_blocking(state.session, 0);
    auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(state.profile.timeoutMilliseconds);
    int result;
    do {
        result = libssh2_session_handshake(state.session, state.socketFd);
        if (result == LIBSSH2_ERROR_EAGAIN && !WaitSocket(state.session, state.socketFd, deadline)) {
            CloseNetwork(state);
            return {false, kTimeout, "SSH handshake timed out", ""};
        }
    } while (result == LIBSSH2_ERROR_EAGAIN);
    if (result != 0) {
        std::string message = SessionError(state.session, "SSH handshake failed");
        CloseNetwork(state);
        return {false, result, message, ""};
    }
    state.handshakeComplete = true;
    if (!CaptureHostKey(state)) {
        CloseNetwork(state);
        return {false, -1, "server host key is unavailable", ""};
    }
    return {true, 0, "handshake complete", HostKeyData(state)};
}

NativeResult Authenticate(SessionState& state)
{
    if (state.authenticated) return {true, 0, "already authenticated", ""};
    auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(state.profile.timeoutMilliseconds);
    int result;
    do {
        if (state.profile.authType == "privateKey") {
            const char* passphrase = state.profile.privateKeyPassphrase.empty() ? nullptr : state.profile.privateKeyPassphrase.c_str();
            result = libssh2_userauth_publickey_fromfile_ex(
                state.session,
                state.profile.username.c_str(), static_cast<unsigned int>(state.profile.username.size()),
                nullptr, state.profile.privateKeyPath.c_str(), passphrase);
        } else {
            result = libssh2_userauth_password_ex(
                state.session,
                state.profile.username.c_str(), static_cast<unsigned int>(state.profile.username.size()),
                state.profile.password.c_str(), static_cast<unsigned int>(state.profile.password.size()), nullptr);
        }
        if (result == LIBSSH2_ERROR_EAGAIN && !WaitSocket(state.session, state.socketFd, deadline)) {
            return {false, kTimeout, "SSH authentication timed out", ""};
        }
    } while (result == LIBSSH2_ERROR_EAGAIN);
    if (result != 0) {
        return {false, kAuthenticationFailed, SessionError(state.session, "SSH authentication failed"), ""};
    }
    state.authenticated = true;
    libssh2_keepalive_config(state.session, 1, static_cast<unsigned int>(state.profile.keepAliveSeconds));
    return {true, 0, "authenticated", HostKeyData(state)};
}

SessionState* FindAuthenticatedSession(const std::string& sessionId)
{
    auto iterator = g_sessions.find(sessionId);
    if (iterator == g_sessions.end() || !iterator->second->authenticated || iterator->second->disconnecting) {
        return nullptr;
    }
    return iterator->second.get();
}

bool WaitForChannel(SessionState& session, const std::chrono::steady_clock::time_point& deadline)
{
    return WaitSocket(session.session, session.socketFd, deadline);
}

void CloseChannelInternal(SessionState& session, LIBSSH2_CHANNEL* channel)
{
    if (channel == nullptr) return;
    auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(2000);
    int result;
    do {
        result = libssh2_channel_send_eof(channel);
    } while (result == LIBSSH2_ERROR_EAGAIN && WaitForChannel(session, deadline));
    do {
        result = libssh2_channel_close(channel);
    } while (result == LIBSSH2_ERROR_EAGAIN && WaitForChannel(session, deadline));
    do {
        result = libssh2_channel_free(channel);
    } while (result == LIBSSH2_ERROR_EAGAIN && WaitForChannel(session, deadline));
}

NativeResult EnsureSftp(SessionState& session, const std::chrono::steady_clock::time_point& deadline)
{
    while (session.sftp == nullptr) {
        session.sftp = libssh2_sftp_init(session.session);
        if (session.sftp == nullptr && libssh2_session_last_errno(session.session) == LIBSSH2_ERROR_EAGAIN) {
            if (!WaitForChannel(session, deadline)) return {false, kTimeout, "SFTP initialization timed out", ""};
            continue;
        }
        if (session.sftp == nullptr) {
            return {false, -1, SessionError(session.session, "SFTP initialization failed"), ""};
        }
    }
    return {true, 0, "SFTP ready", ""};
}

bool CloseSftpHandle(SessionState& session, LIBSSH2_SFTP_HANDLE* handle)
{
    if (handle == nullptr) return true;
    auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(2000);
    int result;
    do {
        result = libssh2_sftp_close_handle(handle);
    } while (result == LIBSSH2_ERROR_EAGAIN && WaitForChannel(session, deadline));
    return result == 0;
}

LIBSSH2_SFTP_HANDLE* OpenSftpFile(SessionState& session, const std::string& path, unsigned long flags,
    long mode, const std::chrono::steady_clock::time_point& deadline)
{
    LIBSSH2_SFTP_HANDLE* handle = nullptr;
    while (handle == nullptr) {
        handle = libssh2_sftp_open_ex(session.sftp, path.c_str(), static_cast<unsigned int>(path.size()),
            flags, mode, LIBSSH2_SFTP_OPENFILE);
        if (handle == nullptr && libssh2_session_last_errno(session.session) == LIBSSH2_ERROR_EAGAIN) {
            if (!WaitForChannel(session, deadline)) return nullptr;
            continue;
        }
        return handle;
    }
    return handle;
}

NativeResult SftpSimpleResult(SessionState& session, int result, const std::string& successMessage,
    const std::string& failureMessage)
{
    if (result == 0) return {true, 0, successMessage, ""};
    return {false, static_cast<int32_t>(result), SessionError(session.session, failureMessage), ""};
}

bool ValidForwardPort(int32_t port)
{
    return port >= 1 && port <= 65535;
}

bool SetNonBlocking(int socketFd)
{
    int flags = fcntl(socketFd, F_GETFL, 0);
    return flags >= 0 && fcntl(socketFd, F_SETFL, flags | O_NONBLOCK) == 0;
}

int CreateLoopbackListener(int32_t port)
{
    int socketFd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (socketFd < 0) return -1;
    int enabled = 1;
    setsockopt(socketFd, SOL_SOCKET, SO_REUSEADDR, &enabled, sizeof(enabled));
    fcntl(socketFd, F_SETFD, FD_CLOEXEC);
    sockaddr_in address{};
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    address.sin_port = htons(static_cast<uint16_t>(port));
    if (bind(socketFd, reinterpret_cast<sockaddr*>(&address), sizeof(address)) != 0 ||
        listen(socketFd, 16) != 0 || !SetNonBlocking(socketFd)) {
        close(socketFd);
        return -1;
    }
    return socketFd;
}

int SocketSendFlags()
{
#ifdef MSG_NOSIGNAL
    return MSG_NOSIGNAL;
#else
    return 0;
#endif
}

bool WaitLocalSocket(int socketFd, short events, const std::chrono::steady_clock::time_point& deadline,
    const std::atomic<bool>& stopping)
{
    while (!stopping.load()) {
        int remaining = RemainingMilliseconds(deadline);
        if (remaining <= 0) return false;
        pollfd descriptor{socketFd, events, 0};
        int result = poll(&descriptor, 1, std::min(remaining, 100));
        if (result < 0 && errno == EINTR) continue;
        if (result < 0 || (result > 0 && (descriptor.revents & (POLLERR | POLLHUP | POLLNVAL)) != 0)) {
            return false;
        }
        if (result > 0 && (descriptor.revents & events) != 0) return true;
    }
    return false;
}

bool ReadSocketExact(int socketFd, unsigned char* output, size_t length,
    const std::shared_ptr<ForwardState>& state, int timeoutMilliseconds = 10000)
{
    auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(timeoutMilliseconds);
    size_t offset = 0;
    while (offset < length && !state->stopping.load()) {
        ssize_t received = recv(socketFd, output + offset, length - offset, 0);
        if (received > 0) {
            offset += static_cast<size_t>(received);
            continue;
        }
        if (received == 0) return false;
        if (errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR) return false;
        if (!WaitLocalSocket(socketFd, POLLIN, deadline, state->stopping)) return false;
    }
    return offset == length;
}

bool WriteSocketExact(int socketFd, const unsigned char* input, size_t length,
    const std::shared_ptr<ForwardState>& state, int timeoutMilliseconds = 10000)
{
    auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(timeoutMilliseconds);
    size_t offset = 0;
    while (offset < length && !state->stopping.load()) {
        ssize_t sent = send(socketFd, input + offset, length - offset, SocketSendFlags());
        if (sent > 0) {
            offset += static_cast<size_t>(sent);
            continue;
        }
        if (sent == 0) return false;
        if (errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR) return false;
        if (!WaitLocalSocket(socketFd, POLLOUT, deadline, state->stopping)) return false;
    }
    return offset == length;
}

LIBSSH2_CHANNEL* OpenDirectChannel(const std::shared_ptr<ForwardState>& state,
    const std::string& host, int32_t port, int32_t originPort)
{
    int timeoutMilliseconds = 15000;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        SessionState* session = FindAuthenticatedSession(state->sessionId);
        if (session == nullptr) return nullptr;
        timeoutMilliseconds = session->profile.timeoutMilliseconds;
    }
    auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(timeoutMilliseconds);
    while (!state->stopping.load() && RemainingMilliseconds(deadline) > 0) {
        LIBSSH2_CHANNEL* channel = nullptr;
        int error = 0;
        {
            std::lock_guard<std::mutex> lock(g_mutex);
            SessionState* session = FindAuthenticatedSession(state->sessionId);
            if (session == nullptr) return nullptr;
            channel = libssh2_channel_direct_tcpip_ex(session->session, host.c_str(), port,
                "127.0.0.1", originPort);
            if (channel == nullptr) error = libssh2_session_last_errno(session->session);
        }
        if (channel != nullptr) return channel;
        if (error != LIBSSH2_ERROR_EAGAIN) return nullptr;
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    return nullptr;
}

void CloseForwardChannel(const std::shared_ptr<ForwardState>& state, LIBSSH2_CHANNEL* channel)
{
    if (channel == nullptr) return;
    std::lock_guard<std::mutex> lock(g_mutex);
    auto sessionIterator = g_sessions.find(state->sessionId);
    if (sessionIterator != g_sessions.end() && sessionIterator->second->session != nullptr) {
        CloseChannelInternal(*sessionIterator->second, channel);
    }
}

void CancelRemoteListener(const std::shared_ptr<ForwardState>& state)
{
    if (state->remoteListener == nullptr) return;
    std::lock_guard<std::mutex> lock(g_mutex);
    auto sessionIterator = g_sessions.find(state->sessionId);
    if (sessionIterator != g_sessions.end() && sessionIterator->second->session != nullptr) {
        auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(2000);
        int result;
        do {
            result = libssh2_channel_forward_cancel(state->remoteListener);
        } while (result == LIBSSH2_ERROR_EAGAIN && WaitForChannel(*sessionIterator->second, deadline));
    }
    state->remoteListener = nullptr;
}

void RelayForwardConnection(const std::shared_ptr<ForwardState>& state, LIBSSH2_CHANNEL* channel,
    int socketFd)
{
    constexpr size_t kBufferLimit = 262144;
    std::string toSsh;
    std::string toSocket;
    size_t toSshOffset = 0;
    size_t toSocketOffset = 0;
    bool socketReadClosed = false;
    bool socketWriteClosed = false;
    bool channelEofSent = false;
    bool channelReadClosed = false;
    bool fatal = false;
    std::array<char, 32768> buffer{};

    while (!state->stopping.load() && !fatal) {
        if (toSshOffset == toSsh.size()) {
            toSsh.clear();
            toSshOffset = 0;
        }
        if (toSocketOffset == toSocket.size()) {
            toSocket.clear();
            toSocketOffset = 0;
        }
        short events = 0;
        if (!socketReadClosed && toSsh.size() - toSshOffset < kBufferLimit) events |= POLLIN;
        if (toSocketOffset < toSocket.size()) events |= POLLOUT;
        pollfd descriptor{socketFd, events, 0};
        int pollResult = poll(&descriptor, 1, 20);
        if (pollResult < 0 && errno != EINTR) break;
        if (pollResult > 0 && (descriptor.revents & POLLIN) != 0) {
            ssize_t received = recv(socketFd, buffer.data(), buffer.size(), 0);
            if (received > 0) {
                toSsh.append(buffer.data(), static_cast<size_t>(received));
            } else if (received == 0) {
                socketReadClosed = true;
            } else if (errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR) {
                socketReadClosed = true;
            }
        }
        if (pollResult > 0 && (descriptor.revents & POLLOUT) != 0 && toSocketOffset < toSocket.size()) {
            ssize_t sent = send(socketFd, toSocket.data() + toSocketOffset,
                toSocket.size() - toSocketOffset, SocketSendFlags());
            if (sent > 0) {
                toSocketOffset += static_cast<size_t>(sent);
            } else if (sent < 0 && errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR) {
                fatal = true;
            }
        }
        if (pollResult > 0 && (descriptor.revents & (POLLERR | POLLNVAL)) != 0) fatal = true;
        if (pollResult > 0 && (descriptor.revents & POLLHUP) != 0) socketReadClosed = true;

        {
            std::lock_guard<std::mutex> lock(g_mutex);
            SessionState* session = FindAuthenticatedSession(state->sessionId);
            if (session == nullptr) {
                fatal = true;
            } else {
                if (toSshOffset < toSsh.size()) {
                    ssize_t written = libssh2_channel_write_ex(channel, 0, toSsh.data() + toSshOffset,
                        toSsh.size() - toSshOffset);
                    if (written > 0) toSshOffset += static_cast<size_t>(written);
                    else if (written != LIBSSH2_ERROR_EAGAIN && written != 0) fatal = true;
                }
                if (socketReadClosed && toSshOffset == toSsh.size() && !channelEofSent) {
                    int eofResult = libssh2_channel_send_eof(channel);
                    if (eofResult == 0) channelEofSent = true;
                    else if (eofResult != LIBSSH2_ERROR_EAGAIN) fatal = true;
                }
                if (!channelReadClosed && toSocket.size() - toSocketOffset < kBufferLimit) {
                    ssize_t received = libssh2_channel_read_ex(channel, 0, buffer.data(), buffer.size());
                    if (received > 0) toSocket.append(buffer.data(), static_cast<size_t>(received));
                    else if (received != LIBSSH2_ERROR_EAGAIN && received < 0) fatal = true;
                }
                channelReadClosed = libssh2_channel_eof(channel) != 0;
            }
        }

        if (channelReadClosed && toSocketOffset == toSocket.size() && !socketWriteClosed) {
            shutdown(socketFd, SHUT_WR);
            socketWriteClosed = true;
        }
        if (socketReadClosed && channelReadClosed && toSshOffset == toSsh.size() &&
            toSocketOffset == toSocket.size()) break;
    }
    close(socketFd);
    CloseForwardChannel(state, channel);
}

template<typename Callback>
bool StartConnectionWorker(const std::shared_ptr<ForwardState>& state, Callback callback)
{
    state->activeConnections.fetch_add(1);
    try {
        std::thread([state, callback = std::move(callback)]() mutable {
            try {
                callback();
            } catch (...) {
            }
            if (state->activeConnections.fetch_sub(1) == 1) {
                std::lock_guard<std::mutex> lock(state->connectionMutex);
                state->connectionCondition.notify_all();
            }
        }).detach();
        return true;
    } catch (...) {
        if (state->activeConnections.fetch_sub(1) == 1) state->connectionCondition.notify_all();
        return false;
    }
}

int32_t PeerPort(const sockaddr_storage& address)
{
    if (address.ss_family == AF_INET) {
        return ntohs(reinterpret_cast<const sockaddr_in*>(&address)->sin_port);
    }
    if (address.ss_family == AF_INET6) {
        return ntohs(reinterpret_cast<const sockaddr_in6*>(&address)->sin6_port);
    }
    return 0;
}

void LocalForwardWorker(const std::shared_ptr<ForwardState>& state)
{
    while (!state->stopping.load()) {
        pollfd descriptor{state->listenFd, POLLIN, 0};
        int result = poll(&descriptor, 1, 100);
        if (result < 0 && errno == EINTR) continue;
        if (result <= 0) continue;
        if ((descriptor.revents & (POLLERR | POLLHUP | POLLNVAL)) != 0) break;
        sockaddr_storage peer{};
        socklen_t peerLength = sizeof(peer);
        int client = accept(state->listenFd, reinterpret_cast<sockaddr*>(&peer), &peerLength);
        if (client < 0) continue;
        fcntl(client, F_SETFD, FD_CLOEXEC);
        if (!SetNonBlocking(client)) {
            close(client);
            continue;
        }
        int32_t originPort = PeerPort(peer);
        if (!StartConnectionWorker(state, [state, client, originPort]() {
            LIBSSH2_CHANNEL* channel = OpenDirectChannel(state, state->targetHost, state->targetPort, originPort);
            if (channel == nullptr) {
                close(client);
                return;
            }
            RelayForwardConnection(state, channel, client);
        })) close(client);
    }
}

bool SendSocksReply(int client, unsigned char code, const std::shared_ptr<ForwardState>& state)
{
    const unsigned char reply[10] = {0x05, code, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
    return WriteSocketExact(client, reply, sizeof(reply), state);
}

void HandleSocksClient(const std::shared_ptr<ForwardState>& state, int client, int32_t originPort)
{
    unsigned char greeting[2]{};
    if (!ReadSocketExact(client, greeting, sizeof(greeting), state) || greeting[0] != 0x05 || greeting[1] == 0) {
        close(client);
        return;
    }
    std::vector<unsigned char> methods(greeting[1]);
    if (!ReadSocketExact(client, methods.data(), methods.size(), state)) {
        close(client);
        return;
    }
    bool noAuthentication = std::find(methods.begin(), methods.end(), 0x00) != methods.end();
    const unsigned char methodReply[2] = {0x05, static_cast<unsigned char>(noAuthentication ? 0x00 : 0xff)};
    if (!WriteSocketExact(client, methodReply, sizeof(methodReply), state) || !noAuthentication) {
        close(client);
        return;
    }

    unsigned char request[4]{};
    if (!ReadSocketExact(client, request, sizeof(request), state) || request[0] != 0x05 || request[2] != 0x00) {
        SendSocksReply(client, 0x01, state);
        close(client);
        return;
    }
    if (request[1] != 0x01) {
        SendSocksReply(client, 0x07, state);
        close(client);
        return;
    }
    std::string host;
    if (request[3] == 0x01) {
        std::array<unsigned char, 4> bytes{};
        char text[INET_ADDRSTRLEN]{};
        if (!ReadSocketExact(client, bytes.data(), bytes.size(), state) ||
            inet_ntop(AF_INET, bytes.data(), text, sizeof(text)) == nullptr) {
            SendSocksReply(client, 0x08, state);
            close(client);
            return;
        }
        host = text;
    } else if (request[3] == 0x03) {
        unsigned char length = 0;
        if (!ReadSocketExact(client, &length, 1, state) || length == 0) {
            SendSocksReply(client, 0x08, state);
            close(client);
            return;
        }
        std::vector<unsigned char> bytes(length);
        if (!ReadSocketExact(client, bytes.data(), bytes.size(), state)) {
            close(client);
            return;
        }
        host.assign(reinterpret_cast<const char*>(bytes.data()), bytes.size());
    } else if (request[3] == 0x04) {
        std::array<unsigned char, 16> bytes{};
        char text[INET6_ADDRSTRLEN]{};
        if (!ReadSocketExact(client, bytes.data(), bytes.size(), state) ||
            inet_ntop(AF_INET6, bytes.data(), text, sizeof(text)) == nullptr) {
            SendSocksReply(client, 0x08, state);
            close(client);
            return;
        }
        host = text;
    } else {
        SendSocksReply(client, 0x08, state);
        close(client);
        return;
    }
    unsigned char portBytes[2]{};
    if (!ReadSocketExact(client, portBytes, sizeof(portBytes), state)) {
        close(client);
        return;
    }
    int32_t port = static_cast<int32_t>((static_cast<uint16_t>(portBytes[0]) << 8) | portBytes[1]);
    if (!ValidForwardPort(port)) {
        SendSocksReply(client, 0x01, state);
        close(client);
        return;
    }
    LIBSSH2_CHANNEL* channel = OpenDirectChannel(state, host, port, originPort);
    SecureClear(host);
    if (channel == nullptr) {
        SendSocksReply(client, 0x05, state);
        close(client);
        return;
    }
    if (!SendSocksReply(client, 0x00, state)) {
        close(client);
        CloseForwardChannel(state, channel);
        return;
    }
    RelayForwardConnection(state, channel, client);
}

void DynamicForwardWorker(const std::shared_ptr<ForwardState>& state)
{
    while (!state->stopping.load()) {
        pollfd descriptor{state->listenFd, POLLIN, 0};
        int result = poll(&descriptor, 1, 100);
        if (result < 0 && errno == EINTR) continue;
        if (result <= 0) continue;
        if ((descriptor.revents & (POLLERR | POLLHUP | POLLNVAL)) != 0) break;
        sockaddr_storage peer{};
        socklen_t peerLength = sizeof(peer);
        int client = accept(state->listenFd, reinterpret_cast<sockaddr*>(&peer), &peerLength);
        if (client < 0) continue;
        fcntl(client, F_SETFD, FD_CLOEXEC);
        if (!SetNonBlocking(client)) {
            close(client);
            continue;
        }
        int32_t originPort = PeerPort(peer);
        if (!StartConnectionWorker(state, [state, client, originPort]() {
            HandleSocksClient(state, client, originPort);
        })) close(client);
    }
}

void RemoteForwardWorker(const std::shared_ptr<ForwardState>& state)
{
    while (!state->stopping.load()) {
        LIBSSH2_CHANNEL* channel = nullptr;
        {
            std::lock_guard<std::mutex> lock(g_mutex);
            SessionState* session = FindAuthenticatedSession(state->sessionId);
            if (session == nullptr) break;
            channel = libssh2_channel_forward_accept(state->remoteListener);
            if (channel == nullptr && libssh2_session_last_errno(session->session) != LIBSSH2_ERROR_EAGAIN) break;
        }
        if (channel == nullptr) {
            std::this_thread::sleep_for(std::chrono::milliseconds(20));
            continue;
        }
        if (!StartConnectionWorker(state, [state, channel]() {
            std::string socketError;
            int client = ConnectTcp(state->targetHost, state->targetPort, 5000, socketError);
            if (client < 0) {
                CloseForwardChannel(state, channel);
                return;
            }
            RelayForwardConnection(state, channel, client);
        })) CloseForwardChannel(state, channel);
    }
}

void StopForwardState(const std::shared_ptr<ForwardState>& state)
{
    std::unique_lock<std::mutex> stopLock(state->stopMutex);
    if (state->stopped) return;
    state->stopping.store(true);
    if (state->worker.joinable()) state->worker.join();
    if (state->listenFd >= 0) {
        close(state->listenFd);
        state->listenFd = -1;
    }
    CancelRemoteListener(state);
    std::unique_lock<std::mutex> lock(state->connectionMutex);
    state->connectionCondition.wait(lock, [&state]() { return state->activeConnections.load() == 0; });
    state->stopped = true;
}

void StopForwardsForSession(const std::string& sessionId)
{
    std::vector<std::shared_ptr<ForwardState>> states;
    {
        std::lock_guard<std::mutex> lock(g_forwardMutex);
        for (auto iterator = g_forwards.begin(); iterator != g_forwards.end();) {
            if (iterator->second->sessionId == sessionId) {
                states.push_back(iterator->second);
                iterator = g_forwards.erase(iterator);
            } else {
                ++iterator;
            }
        }
    }
    for (const auto& state : states) StopForwardState(state);
}

struct ForwardRuntimeCleanup {
    ~ForwardRuntimeCleanup()
    {
        std::vector<std::shared_ptr<ForwardState>> states;
        {
            std::lock_guard<std::mutex> lock(g_forwardMutex);
            for (const auto& entry : g_forwards) states.push_back(entry.second);
            g_forwards.clear();
        }
        for (const auto& state : states) StopForwardState(state);
    }
};

ForwardRuntimeCleanup g_forwardRuntimeCleanup;

} // namespace

std::string Version()
{
    return std::string("OpenTabSsh Native Core 0.3.0 / libssh2 ") + LIBSSH2_VERSION + " / real-ssh";
}

std::string CreateSession(std::string profileJson)
{
    ProfileConfig profile = ParseProfile(profileJson);
    auto state = std::make_unique<SessionState>();
    state->profile = std::move(profile);
    std::lock_guard<std::mutex> lock(g_mutex);
    std::string id = NextId("session");
    g_sessions[id] = std::move(state);
    return id;
}

NativeResult Connect(const std::string& sessionId)
{
    std::lock_guard<std::mutex> lock(g_mutex);
    if (g_runtime.status != 0) return {false, g_runtime.status, "libssh2 initialization failed", ""};
    auto iterator = g_sessions.find(sessionId);
    if (iterator == g_sessions.end()) return {false, 404, "session not found", ""};
    SessionState& state = *iterator->second;
    NativeResult profileStatus = InvalidProfileResult(state.profile);
    if (!profileStatus.ok) return profileStatus;
    NativeResult handshake = EnsureHandshake(state);
    if (!handshake.ok) return handshake;
    if (!state.hostKeyConfirmed) {
        int32_t code = state.profile.expectedHostKey.empty() ? kHostKeyUnknown : kHostKeyChanged;
        const char* message = code == kHostKeyUnknown ? "host key confirmation required" : "host key changed";
        return {false, code, message, HostKeyData(state)};
    }
    return Authenticate(state);
}

NativeResult ConfirmHostKey(const std::string& sessionId, const std::string& fingerprint)
{
    std::lock_guard<std::mutex> lock(g_mutex);
    auto iterator = g_sessions.find(sessionId);
    if (iterator == g_sessions.end()) return {false, 404, "session not found", ""};
    SessionState& state = *iterator->second;
    if (!state.handshakeComplete || state.observedHostKey.empty()) {
        return {false, kNotConnected, "SSH handshake has not produced a host key", ""};
    }
    if (!ConstantTimeEqual(fingerprint, state.observedHostKey)) {
        return {false, kHostKeyChanged, "host key confirmation does not match the observed key", HostKeyData(state)};
    }
    state.profile.expectedHostKey = state.observedHostKey;
    state.hostKeyConfirmed = true;
    return {true, 0, "host key confirmed for this session", HostKeyData(state)};
}

std::string OpenShell(const std::string& sessionId)
{
    std::lock_guard<std::mutex> lock(g_mutex);
    SessionState* session = FindAuthenticatedSession(sessionId);
    if (session == nullptr) return "";
    auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(session->profile.timeoutMilliseconds);
    LIBSSH2_CHANNEL* channel = nullptr;
    do {
        channel = libssh2_channel_open_ex(session->session, "session", 7, LIBSSH2_CHANNEL_WINDOW_DEFAULT,
            LIBSSH2_CHANNEL_PACKET_DEFAULT, nullptr, 0);
        if (channel == nullptr && libssh2_session_last_errno(session->session) == LIBSSH2_ERROR_EAGAIN &&
            !WaitForChannel(*session, deadline)) return "";
    } while (channel == nullptr && libssh2_session_last_errno(session->session) == LIBSSH2_ERROR_EAGAIN);
    if (channel == nullptr) return "";
    int result;
    do {
        result = libssh2_channel_request_pty_ex(channel,
            session->profile.terminalType.c_str(), static_cast<unsigned int>(session->profile.terminalType.size()),
            nullptr, 0, 80, 24, 0, 0);
        if (result == LIBSSH2_ERROR_EAGAIN && !WaitForChannel(*session, deadline)) {
            CloseChannelInternal(*session, channel);
            return "";
        }
    } while (result == LIBSSH2_ERROR_EAGAIN);
    if (result != 0) {
        CloseChannelInternal(*session, channel);
        return "";
    }
    do {
        result = libssh2_channel_shell(channel);
        if (result == LIBSSH2_ERROR_EAGAIN && !WaitForChannel(*session, deadline)) {
            CloseChannelInternal(*session, channel);
            return "";
        }
    } while (result == LIBSSH2_ERROR_EAGAIN);
    if (result != 0) {
        CloseChannelInternal(*session, channel);
        return "";
    }
    std::string channelId = NextId("channel");
    g_channels[channelId] = ChannelState{sessionId, channel, 80, 24};
    return channelId;
}

NativeResult Write(const std::string& channelId, const std::string& data)
{
    std::lock_guard<std::mutex> lock(g_mutex);
    auto channelIterator = g_channels.find(channelId);
    if (channelIterator == g_channels.end()) return {false, 404, "channel not found", ""};
    SessionState* session = FindAuthenticatedSession(channelIterator->second.sessionId);
    if (session == nullptr) return {false, kNotConnected, "session is not authenticated", ""};
    auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(session->profile.timeoutMilliseconds);
    size_t written = 0;
    while (written < data.size()) {
        ssize_t result = libssh2_channel_write_ex(channelIterator->second.channel, 0,
            data.data() + written, data.size() - written);
        if (result == LIBSSH2_ERROR_EAGAIN) {
            if (!WaitForChannel(*session, deadline)) return {false, kTimeout, "terminal write timed out", ""};
            continue;
        }
        if (result < 0) return {false, static_cast<int32_t>(result), SessionError(session->session, "terminal write failed"), ""};
        written += static_cast<size_t>(result);
    }
    return {true, 0, "written", std::to_string(written)};
}

NativeResult Read(const std::string& channelId)
{
    std::lock_guard<std::mutex> lock(g_mutex);
    auto channelIterator = g_channels.find(channelId);
    if (channelIterator == g_channels.end()) return {false, 404, "channel not found", ""};
    SessionState* session = FindAuthenticatedSession(channelIterator->second.sessionId);
    if (session == nullptr) return {false, kNotConnected, "session is not authenticated", ""};
    int secondsToNextKeepalive = 0;
    int keepaliveResult = libssh2_keepalive_send(session->session, &secondsToNextKeepalive);
    if (keepaliveResult != 0 && keepaliveResult != LIBSSH2_ERROR_EAGAIN) {
        return {false, keepaliveResult, SessionError(session->session, "SSH keepalive failed"), ""};
    }
    std::string output;
    char buffer[16384];
    for (int streamId : {0, 1}) {
        while (output.size() < 262144) {
            ssize_t result = libssh2_channel_read_ex(channelIterator->second.channel, streamId, buffer, sizeof(buffer));
            if (result > 0) {
                output.append(buffer, static_cast<size_t>(result));
                continue;
            }
            if (result == LIBSSH2_ERROR_EAGAIN || result == 0) break;
            return {false, static_cast<int32_t>(result), SessionError(session->session, "terminal read failed"), output};
        }
    }
    bool eof = libssh2_channel_eof(channelIterator->second.channel) != 0;
    int32_t exitStatus = eof ? static_cast<int32_t>(libssh2_channel_get_exit_status(
        channelIterator->second.channel)) : 0;
    return {true, exitStatus, eof ? "eof" : "read", output};
}

NativeResult Resize(const std::string& channelId, int32_t cols, int32_t rows)
{
    if (cols < 1 || rows < 1) return {false, kInvalidProfile, "terminal size must be positive", ""};
    std::lock_guard<std::mutex> lock(g_mutex);
    auto channelIterator = g_channels.find(channelId);
    if (channelIterator == g_channels.end()) return {false, 404, "channel not found", ""};
    SessionState* session = FindAuthenticatedSession(channelIterator->second.sessionId);
    if (session == nullptr) return {false, kNotConnected, "session is not authenticated", ""};
    auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(session->profile.timeoutMilliseconds);
    int result;
    do {
        result = libssh2_channel_request_pty_size_ex(channelIterator->second.channel, cols, rows, 0, 0);
        if (result == LIBSSH2_ERROR_EAGAIN && !WaitForChannel(*session, deadline)) {
            return {false, kTimeout, "PTY resize timed out", ""};
        }
    } while (result == LIBSSH2_ERROR_EAGAIN);
    if (result != 0) return {false, result, SessionError(session->session, "PTY resize failed"), ""};
    channelIterator->second.cols = cols;
    channelIterator->second.rows = rows;
    return {true, 0, "pty resized", ""};
}

NativeResult CloseChannel(const std::string& channelId)
{
    std::lock_guard<std::mutex> lock(g_mutex);
    auto channelIterator = g_channels.find(channelId);
    if (channelIterator == g_channels.end()) return {false, 404, "channel not found", ""};
    auto sessionIterator = g_sessions.find(channelIterator->second.sessionId);
    if (sessionIterator != g_sessions.end() && sessionIterator->second->session != nullptr) {
        CloseChannelInternal(*sessionIterator->second, channelIterator->second.channel);
    }
    g_channels.erase(channelIterator);
    return {true, 0, "channel closed", ""};
}

NativeResult Disconnect(const std::string& sessionId)
{
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        auto sessionIterator = g_sessions.find(sessionId);
        if (sessionIterator == g_sessions.end()) return {false, 404, "session not found", ""};
        sessionIterator->second->disconnecting = true;
    }
    StopForwardsForSession(sessionId);
    std::lock_guard<std::mutex> lock(g_mutex);
    auto sessionIterator = g_sessions.find(sessionId);
    if (sessionIterator == g_sessions.end()) return {false, 404, "session not found", ""};
    for (auto channelIterator = g_channels.begin(); channelIterator != g_channels.end();) {
        if (channelIterator->second.sessionId == sessionId) {
            CloseChannelInternal(*sessionIterator->second, channelIterator->second.channel);
            channelIterator = g_channels.erase(channelIterator);
        } else {
            ++channelIterator;
        }
    }
    CloseNetwork(*sessionIterator->second);
    ClearCredentials(sessionIterator->second->profile);
    g_sessions.erase(sessionIterator);
    return {true, 0, "session disconnected and resources released", ""};
}

NativeResult SftpList(const std::string& sessionId, const std::string& path)
{
    std::lock_guard<std::mutex> lock(g_mutex);
    SessionState* session = FindAuthenticatedSession(sessionId);
    if (session == nullptr) return {false, kNotConnected, "session is not authenticated", ""};
    auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(session->profile.timeoutMilliseconds);
    NativeResult sftpStatus = EnsureSftp(*session, deadline);
    if (!sftpStatus.ok) return sftpStatus;
    LIBSSH2_SFTP_HANDLE* directory = nullptr;
    while (directory == nullptr) {
        directory = libssh2_sftp_opendir(session->sftp, path.c_str());
        if (directory == nullptr && libssh2_session_last_errno(session->session) == LIBSSH2_ERROR_EAGAIN) {
            if (!WaitForChannel(*session, deadline)) return {false, kTimeout, "SFTP directory open timed out", ""};
            continue;
        }
        if (directory == nullptr) return {false, -1, SessionError(session->session, "SFTP directory open failed"), ""};
    }
    std::ostringstream entries;
    entries << '[';
    bool first = true;
    char name[4096];
    LIBSSH2_SFTP_ATTRIBUTES attributes{};
    while (true) {
        ssize_t result = libssh2_sftp_readdir_ex(directory, name, sizeof(name), nullptr, 0, &attributes);
        if (result == LIBSSH2_ERROR_EAGAIN) {
            if (!WaitForChannel(*session, deadline)) {
                libssh2_sftp_closedir(directory);
                return {false, kTimeout, "SFTP listing timed out", ""};
            }
            continue;
        }
        if (result < 0) {
            libssh2_sftp_closedir(directory);
            return {false, static_cast<int32_t>(result), SessionError(session->session, "SFTP listing failed"), ""};
        }
        if (result == 0) break;
        std::string fileName(name, static_cast<size_t>(result));
        if (fileName == "." || fileName == "..") continue;
        bool directoryEntry = (attributes.flags & LIBSSH2_SFTP_ATTR_PERMISSIONS) != 0 &&
            LIBSSH2_SFTP_S_ISDIR(attributes.permissions);
        uint64_t size = (attributes.flags & LIBSSH2_SFTP_ATTR_SIZE) != 0 ? attributes.filesize : 0;
        uint64_t modified = (attributes.flags & LIBSSH2_SFTP_ATTR_ACMODTIME) != 0 ? attributes.mtime : 0;
        std::string fullPath = path;
        if (fullPath.empty()) fullPath = "/";
        if (fullPath.back() != '/') fullPath.push_back('/');
        fullPath += fileName;
        if (!first) entries << ',';
        first = false;
        entries << "{\"name\":\"" << EscapeJson(fileName)
            << "\",\"path\":\"" << EscapeJson(fullPath)
            << "\",\"type\":\"" << (directoryEntry ? "dir" : "file")
            << "\",\"size\":" << size
            << ",\"modifiedTime\":\"" << modified << "\"}";
    }
    int closeResult;
    do {
        closeResult = libssh2_sftp_closedir(directory);
    } while (closeResult == LIBSSH2_ERROR_EAGAIN && WaitForChannel(*session, deadline));
    entries << ']';
    return {true, 0, "sftp list", entries.str()};
}

NativeResult SftpUpload(const std::string& sessionId, const std::string& localPath, const std::string& remotePath)
{
    if (localPath.empty() || remotePath.empty()) return {false, kInvalidProfile, "file path is required", ""};
    std::lock_guard<std::mutex> lock(g_mutex);
    SessionState* session = FindAuthenticatedSession(sessionId);
    if (session == nullptr) return {false, kNotConnected, "session is not authenticated", ""};
    std::ifstream input(localPath, std::ios::binary);
    if (!input.is_open()) return {false, -1, "local file could not be opened", ""};
    auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(session->profile.timeoutMilliseconds);
    NativeResult sftpStatus = EnsureSftp(*session, deadline);
    if (!sftpStatus.ok) return sftpStatus;
    LIBSSH2_SFTP_HANDLE* remote = OpenSftpFile(*session, remotePath,
        LIBSSH2_FXF_WRITE | LIBSSH2_FXF_CREAT | LIBSSH2_FXF_TRUNC, 0600, deadline);
    if (remote == nullptr) return {false, -1, SessionError(session->session, "remote file could not be opened"), ""};

    std::array<char, 32768> buffer{};
    uint64_t total = 0;
    while (input.good()) {
        input.read(buffer.data(), static_cast<std::streamsize>(buffer.size()));
        std::streamsize count = input.gcount();
        if (count <= 0) break;
        std::streamsize offset = 0;
        while (offset < count) {
            ssize_t written = libssh2_sftp_write(remote, buffer.data() + offset,
                static_cast<size_t>(count - offset));
            if (written == LIBSSH2_ERROR_EAGAIN) {
                if (!WaitForChannel(*session, deadline)) {
                    CloseSftpHandle(*session, remote);
                    return {false, kTimeout, "SFTP upload timed out", ""};
                }
                continue;
            }
            if (written <= 0) {
                CloseSftpHandle(*session, remote);
                return {false, static_cast<int32_t>(written), SessionError(session->session, "SFTP upload failed"), ""};
            }
            offset += static_cast<std::streamsize>(written);
            total += static_cast<uint64_t>(written);
            deadline = std::chrono::steady_clock::now() +
                std::chrono::milliseconds(session->profile.timeoutMilliseconds);
        }
    }
    if (input.bad()) {
        CloseSftpHandle(*session, remote);
        return {false, -1, "local file read failed", ""};
    }
    if (!CloseSftpHandle(*session, remote)) {
        return {false, -1, SessionError(session->session, "remote file close failed"), ""};
    }
    return {true, 0, "SFTP upload complete", std::to_string(total)};
}

NativeResult SftpDownload(const std::string& sessionId, const std::string& remotePath, const std::string& localPath)
{
    if (localPath.empty() || remotePath.empty()) return {false, kInvalidProfile, "file path is required", ""};
    std::lock_guard<std::mutex> lock(g_mutex);
    SessionState* session = FindAuthenticatedSession(sessionId);
    if (session == nullptr) return {false, kNotConnected, "session is not authenticated", ""};
    auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(session->profile.timeoutMilliseconds);
    NativeResult sftpStatus = EnsureSftp(*session, deadline);
    if (!sftpStatus.ok) return sftpStatus;
    LIBSSH2_SFTP_HANDLE* remote = OpenSftpFile(*session, remotePath, LIBSSH2_FXF_READ, 0, deadline);
    if (remote == nullptr) return {false, -1, SessionError(session->session, "remote file could not be opened"), ""};
    std::ofstream output(localPath, std::ios::binary | std::ios::trunc);
    if (!output.is_open()) {
        CloseSftpHandle(*session, remote);
        return {false, -1, "local destination could not be opened", ""};
    }

    std::array<char, 32768> buffer{};
    uint64_t total = 0;
    while (true) {
        ssize_t read = libssh2_sftp_read(remote, buffer.data(), buffer.size());
        if (read == LIBSSH2_ERROR_EAGAIN) {
            if (!WaitForChannel(*session, deadline)) {
                CloseSftpHandle(*session, remote);
                output.close();
                std::remove(localPath.c_str());
                return {false, kTimeout, "SFTP download timed out", ""};
            }
            continue;
        }
        if (read < 0) {
            CloseSftpHandle(*session, remote);
            output.close();
            std::remove(localPath.c_str());
            return {false, static_cast<int32_t>(read), SessionError(session->session, "SFTP download failed"), ""};
        }
        if (read == 0) break;
        output.write(buffer.data(), static_cast<std::streamsize>(read));
        if (!output.good()) {
            CloseSftpHandle(*session, remote);
            output.close();
            std::remove(localPath.c_str());
            return {false, -1, "local destination write failed", ""};
        }
        total += static_cast<uint64_t>(read);
        deadline = std::chrono::steady_clock::now() +
            std::chrono::milliseconds(session->profile.timeoutMilliseconds);
    }
    output.flush();
    if (!output.good()) {
        CloseSftpHandle(*session, remote);
        output.close();
        std::remove(localPath.c_str());
        return {false, -1, "local destination flush failed", ""};
    }
    output.close();
    if (!CloseSftpHandle(*session, remote)) {
        std::remove(localPath.c_str());
        return {false, -1, SessionError(session->session, "remote file close failed"), ""};
    }
    return {true, 0, "SFTP download complete", std::to_string(total)};
}

NativeResult SftpMkdir(const std::string& sessionId, const std::string& path)
{
    if (path.empty()) return {false, kInvalidProfile, "directory path is required", ""};
    std::lock_guard<std::mutex> lock(g_mutex);
    SessionState* session = FindAuthenticatedSession(sessionId);
    if (session == nullptr) return {false, kNotConnected, "session is not authenticated", ""};
    auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(session->profile.timeoutMilliseconds);
    NativeResult sftpStatus = EnsureSftp(*session, deadline);
    if (!sftpStatus.ok) return sftpStatus;
    int result;
    do {
        result = libssh2_sftp_mkdir_ex(session->sftp, path.c_str(), static_cast<unsigned int>(path.size()), 0700);
        if (result == LIBSSH2_ERROR_EAGAIN && !WaitForChannel(*session, deadline)) {
            return {false, kTimeout, "SFTP create directory timed out", ""};
        }
    } while (result == LIBSSH2_ERROR_EAGAIN);
    return SftpSimpleResult(*session, result, "SFTP directory created", "SFTP create directory failed");
}

NativeResult SftpRemove(const std::string& sessionId, const std::string& path, bool directory)
{
    if (path.empty()) return {false, kInvalidProfile, "remote path is required", ""};
    std::lock_guard<std::mutex> lock(g_mutex);
    SessionState* session = FindAuthenticatedSession(sessionId);
    if (session == nullptr) return {false, kNotConnected, "session is not authenticated", ""};
    auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(session->profile.timeoutMilliseconds);
    NativeResult sftpStatus = EnsureSftp(*session, deadline);
    if (!sftpStatus.ok) return sftpStatus;
    int result;
    do {
        result = directory ?
            libssh2_sftp_rmdir_ex(session->sftp, path.c_str(), static_cast<unsigned int>(path.size())) :
            libssh2_sftp_unlink_ex(session->sftp, path.c_str(), static_cast<unsigned int>(path.size()));
        if (result == LIBSSH2_ERROR_EAGAIN && !WaitForChannel(*session, deadline)) {
            return {false, kTimeout, "SFTP remove timed out", ""};
        }
    } while (result == LIBSSH2_ERROR_EAGAIN);
    return SftpSimpleResult(*session, result, "SFTP entry removed", "SFTP remove failed");
}

NativeResult SftpRename(const std::string& sessionId, const std::string& sourcePath,
    const std::string& destinationPath)
{
    if (sourcePath.empty() || destinationPath.empty()) return {false, kInvalidProfile, "remote paths are required", ""};
    std::lock_guard<std::mutex> lock(g_mutex);
    SessionState* session = FindAuthenticatedSession(sessionId);
    if (session == nullptr) return {false, kNotConnected, "session is not authenticated", ""};
    auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(session->profile.timeoutMilliseconds);
    NativeResult sftpStatus = EnsureSftp(*session, deadline);
    if (!sftpStatus.ok) return sftpStatus;
    int result;
    do {
        result = libssh2_sftp_rename_ex(session->sftp,
            sourcePath.c_str(), static_cast<unsigned int>(sourcePath.size()),
            destinationPath.c_str(), static_cast<unsigned int>(destinationPath.size()),
            LIBSSH2_SFTP_RENAME_OVERWRITE);
        if (result == LIBSSH2_ERROR_EAGAIN && !WaitForChannel(*session, deadline)) {
            return {false, kTimeout, "SFTP rename timed out", ""};
        }
    } while (result == LIBSSH2_ERROR_EAGAIN);
    return SftpSimpleResult(*session, result, "SFTP entry renamed", "SFTP rename failed");
}

NativeResult SftpChmod(const std::string& sessionId, const std::string& path, int32_t mode)
{
    if (path.empty() || mode < 0 || mode > 07777) return {false, kInvalidProfile, "valid path and mode are required", ""};
    std::lock_guard<std::mutex> lock(g_mutex);
    SessionState* session = FindAuthenticatedSession(sessionId);
    if (session == nullptr) return {false, kNotConnected, "session is not authenticated", ""};
    auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(session->profile.timeoutMilliseconds);
    NativeResult sftpStatus = EnsureSftp(*session, deadline);
    if (!sftpStatus.ok) return sftpStatus;
    LIBSSH2_SFTP_ATTRIBUTES attributes{};
    attributes.flags = LIBSSH2_SFTP_ATTR_PERMISSIONS;
    attributes.permissions = static_cast<unsigned long>(mode);
    int result;
    do {
        result = libssh2_sftp_stat_ex(session->sftp, path.c_str(), static_cast<unsigned int>(path.size()),
            LIBSSH2_SFTP_SETSTAT, &attributes);
        if (result == LIBSSH2_ERROR_EAGAIN && !WaitForChannel(*session, deadline)) {
            return {false, kTimeout, "SFTP permission update timed out", ""};
        }
    } while (result == LIBSSH2_ERROR_EAGAIN);
    return SftpSimpleResult(*session, result, "SFTP permissions updated", "SFTP permission update failed");
}

std::string AddLocalForward(const std::string& sessionId, int32_t localPort,
    const std::string& remoteHost, int32_t remotePort)
{
    if (!ValidForwardPort(localPort) || !ValidForwardPort(remotePort) || remoteHost.empty()) return "";
    auto state = std::make_shared<ForwardState>();
    state->sessionId = sessionId;
    state->kind = ForwardKind::LOCAL;
    state->bindPort = localPort;
    state->targetHost = remoteHost;
    state->targetPort = remotePort;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (FindAuthenticatedSession(sessionId) == nullptr) return "";
        state->id = NextId("forward-local");
    }
    state->listenFd = CreateLoopbackListener(localPort);
    if (state->listenFd < 0) return "";
    {
        std::lock_guard<std::mutex> sessionLock(g_mutex);
        if (FindAuthenticatedSession(sessionId) == nullptr) {
            close(state->listenFd);
            state->listenFd = -1;
            return "";
        }
        try {
            state->worker = std::thread(LocalForwardWorker, state);
        } catch (...) {
            close(state->listenFd);
            state->listenFd = -1;
            return "";
        }
        std::lock_guard<std::mutex> forwardLock(g_forwardMutex);
        g_forwards[state->id] = state;
    }
    return state->id;
}

std::string AddRemoteForward(const std::string& sessionId, int32_t remotePort,
    const std::string& localHost, int32_t localPort)
{
    if (!ValidForwardPort(remotePort) || !ValidForwardPort(localPort) || localHost.empty()) return "";
    auto state = std::make_shared<ForwardState>();
    state->sessionId = sessionId;
    state->kind = ForwardKind::REMOTE;
    state->bindPort = remotePort;
    state->targetHost = localHost;
    state->targetPort = localPort;
    int timeoutMilliseconds = 15000;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        SessionState* session = FindAuthenticatedSession(sessionId);
        if (session == nullptr) return "";
        timeoutMilliseconds = session->profile.timeoutMilliseconds;
        state->id = NextId("forward-remote");
    }
    auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(timeoutMilliseconds);
    int boundPort = 0;
    while (state->remoteListener == nullptr && RemainingMilliseconds(deadline) > 0) {
        int error = 0;
        {
            std::lock_guard<std::mutex> lock(g_mutex);
            SessionState* session = FindAuthenticatedSession(sessionId);
            if (session == nullptr) return "";
            state->remoteListener = libssh2_channel_forward_listen_ex(session->session, "127.0.0.1",
                remotePort, &boundPort, 16);
            if (state->remoteListener == nullptr) error = libssh2_session_last_errno(session->session);
        }
        if (state->remoteListener != nullptr) break;
        if (error != LIBSSH2_ERROR_EAGAIN) return "";
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    if (state->remoteListener == nullptr || boundPort != remotePort) {
        CancelRemoteListener(state);
        return "";
    }
    {
        std::lock_guard<std::mutex> sessionLock(g_mutex);
        if (FindAuthenticatedSession(sessionId) == nullptr) {
            auto sessionIterator = g_sessions.find(sessionId);
            if (sessionIterator != g_sessions.end() && sessionIterator->second->session != nullptr) {
                libssh2_channel_forward_cancel(state->remoteListener);
            }
            state->remoteListener = nullptr;
            return "";
        }
        try {
            state->worker = std::thread(RemoteForwardWorker, state);
        } catch (...) {
            libssh2_channel_forward_cancel(state->remoteListener);
            state->remoteListener = nullptr;
            return "";
        }
        std::lock_guard<std::mutex> forwardLock(g_forwardMutex);
        g_forwards[state->id] = state;
    }
    return state->id;
}

std::string AddDynamicForward(const std::string& sessionId, int32_t localPort)
{
    if (!ValidForwardPort(localPort)) return "";
    auto state = std::make_shared<ForwardState>();
    state->sessionId = sessionId;
    state->kind = ForwardKind::DYNAMIC;
    state->bindPort = localPort;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (FindAuthenticatedSession(sessionId) == nullptr) return "";
        state->id = NextId("forward-dynamic");
    }
    state->listenFd = CreateLoopbackListener(localPort);
    if (state->listenFd < 0) return "";
    {
        std::lock_guard<std::mutex> sessionLock(g_mutex);
        if (FindAuthenticatedSession(sessionId) == nullptr) {
            close(state->listenFd);
            state->listenFd = -1;
            return "";
        }
        try {
            state->worker = std::thread(DynamicForwardWorker, state);
        } catch (...) {
            close(state->listenFd);
            state->listenFd = -1;
            return "";
        }
        std::lock_guard<std::mutex> forwardLock(g_forwardMutex);
        g_forwards[state->id] = state;
    }
    return state->id;
}

NativeResult RemoveForward(const std::string& forwardId)
{
    std::shared_ptr<ForwardState> state;
    {
        std::lock_guard<std::mutex> lock(g_forwardMutex);
        auto iterator = g_forwards.find(forwardId);
        if (iterator == g_forwards.end()) return {false, 404, "forward not found", ""};
        state = iterator->second;
    }
    StopForwardState(state);
    {
        std::lock_guard<std::mutex> lock(g_forwardMutex);
        auto iterator = g_forwards.find(forwardId);
        if (iterator != g_forwards.end() && iterator->second == state) g_forwards.erase(iterator);
    }
    return {true, 0, "forward removed and resources released", ""};
}

std::string ToJson(const NativeResult& result)
{
    std::ostringstream output;
    output << "{\"ok\":" << (result.ok ? "true" : "false")
        << ",\"code\":" << result.code
        << ",\"message\":\"" << EscapeJson(result.message) << "\""
        << ",\"data\":\"" << EscapeJson(result.data) << "\"}";
    return output.str();
}

} // namespace opentabssh

#endif // OPEN_TAB_SSH_ENABLE_LIBSSH2
