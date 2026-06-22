#include "native_ssh_core.h"

#ifdef OPEN_TAB_SSH_ENABLE_LIBSSH2

#include <libssh2.h>
#include <libssh2_sftp.h>

#include <algorithm>
#include <cerrno>
#include <chrono>
#include <cctype>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <fcntl.h>
#include <map>
#include <memory>
#include <mutex>
#include <netdb.h>
#include <poll.h>
#include <sstream>
#include <string>
#include <sys/socket.h>
#include <unistd.h>

namespace opentabssh {
namespace {

constexpr int32_t kHostKeyUnknown = 1001;
constexpr int32_t kHostKeyChanged = 1002;
constexpr int32_t kAuthenticationFailed = 1003;
constexpr int32_t kTimeout = 1004;
constexpr int32_t kInvalidProfile = 1005;
constexpr int32_t kNotConnected = 1006;
constexpr int32_t kNotImplemented = 1501;

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
    std::string observedHostKey;
    std::string observedHostKeyAlgorithm;
};

struct ChannelState {
    std::string sessionId;
    LIBSSH2_CHANNEL* channel = nullptr;
    int32_t cols = 80;
    int32_t rows = 24;
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
    if (iterator == g_sessions.end() || !iterator->second->authenticated) return nullptr;
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

} // namespace

std::string Version()
{
    return std::string("OpenTabSsh Native Core 0.2.0 / libssh2 ") + LIBSSH2_VERSION + " / real-ssh";
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
    return {true, 0, libssh2_channel_eof(channelIterator->second.channel) != 0 ? "eof" : "read", output};
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
    while (session->sftp == nullptr) {
        session->sftp = libssh2_sftp_init(session->session);
        if (session->sftp == nullptr && libssh2_session_last_errno(session->session) == LIBSSH2_ERROR_EAGAIN) {
            if (!WaitForChannel(*session, deadline)) return {false, kTimeout, "SFTP initialization timed out", ""};
            continue;
        }
        if (session->sftp == nullptr) return {false, -1, SessionError(session->session, "SFTP initialization failed"), ""};
    }
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

std::string AddLocalForward(const std::string&, int32_t, const std::string&, int32_t)
{
    return "";
}

std::string AddRemoteForward(const std::string&, int32_t, const std::string&, int32_t)
{
    return "";
}

std::string AddDynamicForward(const std::string&, int32_t)
{
    return "";
}

NativeResult RemoveForward(const std::string&)
{
    return {false, kNotImplemented, "real port forwarding is not implemented yet", ""};
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
