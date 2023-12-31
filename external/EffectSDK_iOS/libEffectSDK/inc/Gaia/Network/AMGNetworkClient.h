#ifndef AMGNetworkClient_h
#define AMGNetworkClient_h

#include "Gaia/Network/AMGNetworkCall.h"

#include <mutex>
#include <condition_variable>
#include <unordered_map>
#include "Gaia/Thread/AMGThreadFactory.h"

#include "Gaia/AMGExport.h"
#include "Gaia/AMGRefBase.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

class NetworkClient;
class NetworkRequest;

enum class NetworkClientType
{
    MOCK = 0,
    TTNET,
};

enum class NetworkCacheMode
{
    NO_CACHE = 0,
    MEMORY_CACHE,
    DISK_CACHE
};

class GAIA_LIB_EXPORT NetworkClientBuilder
{
public:
    SharePtr<NetworkClient> build(NetworkClientType type);

    NetworkClientBuilder& useQuic(bool use);

    NetworkClientBuilder& useHttp2(bool use);

    NetworkClientBuilder& setUserAgent(const std::string& userAgent);

    NetworkClientBuilder& setCacheMode(NetworkCacheMode cacheMode);

    NetworkClientBuilder& setCacheMaxSize(int64_t cacheMaxSize);

    bool useQuic() const;
    bool useHttp2() const;
    const std::string& getUserAgent() const;
    NetworkCacheMode getCacheMode() const;
    int64_t getCacheMaxSize() const;

private:
    friend class NetworkClient;

    bool m_useQuic = true;
    bool m_useHttp2 = false;
    std::string m_userAgent = "AmazingEngine";
    NetworkCacheMode m_cacheMode = NetworkCacheMode::NO_CACHE;
    int64_t m_cacheMaxSize = 0;
};

class GAIA_LIB_EXPORT NetworkClient : public RefBase
{
public:
    bool isRunning();

    bool sendRequest(NetworkRequest* request, bool sync = false);

    void cancelRequest(NetworkRequest* request);

    void shutdown();

    virtual ~NetworkClient();

protected:
    virtual bool _init(const NetworkClientBuilder& builder) = 0;
    virtual bool _initCall(NetworkCall* newCall) = 0;

    virtual void _shutdown() = 0;

    virtual SharePtr<NetworkCall> _createCall() = 0;

    friend class NetworkClientBuilder;

    NetworkClient() = default;

    NetworkClientType m_type;

private:
    void processLoadingTasks();

    bool init(const NetworkClientBuilder& builder);

    SharePtr<NetworkCall> createCall(NetworkRequest* request);

    bool initCall(NetworkCall* newCall, NetworkRequest* request);

    void onRequestResponse(NetworkCall* call,
                           const NetworkResponse& response,
                           NetworkStatus status);

    void onRequestFailed(NetworkCall* call,
                         const NetworkError& errorDesc);

    void onRequestCanceled(NetworkCall* call);

private:
    std::mutex m_callsLock;

    std::condition_variable m_clearCond;

    std::unordered_map<NetworkRequest*, SharePtr<NetworkCall>> m_calls;

    std::atomic_bool m_isRunnig{false};

    std::atomic_bool m_isInitializing{false};

    ThreadWrapper* m_initClientTask = nullptr;

    NetworkClientBuilder m_builder;
};

class TTNetWSClient;
class GAIA_LIB_EXPORT NetworkClientWS : public RefBase
{
public:
    NetworkClientWS();
    virtual ~NetworkClientWS();

    bool initWS(void* ctx,
                uint32_t wsid,
                WS_OnConnectionStateChangedFunc fState,
                WS_OnConnectionErrorFunc fError,
                WS_OnMessageReceivedFunc fMessageRecv,
                WS_OnFeedbackLogFunc fLog);
    void shutdown();

    bool startConnect(const std::string& server);
    bool sendData(const std::string& data);
    bool isConnected(void);

private:
    SharePtr<TTNetWSClient> m_client;
};

NAMESPACE_AMAZING_ENGINE_END

#endif /* AMGNetworkClient_h */
