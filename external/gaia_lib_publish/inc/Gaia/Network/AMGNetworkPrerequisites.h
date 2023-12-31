#ifndef AMGNetworkPrerequisites_h
#define AMGNetworkPrerequisites_h

#include <unordered_map>

#include "Gaia/AMGPrerequisites.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

class NetworkRequest;

using NetworkHeaders = std::unordered_map<std::string, std::string>;
using NetworkParams = std::unordered_map<std::string, std::string>;

struct NetworkResponse
{
    std::string body;
    int32_t statusCode;
    std::string statusDesc;
    NetworkHeaders headers;
    uint32_t newBytesNum = 0;
};

struct NetworkError
{
    std::string desc;
};

enum NetworkStatus
{
    NETWORK_START = 0,
    NETWORK_UPDATE,
    NETWORK_SUCCESS,
    NETWORK_FAIL,
    NETWORK_CANCEL
};

using NetworkResponse = struct NetworkResponse;
using NetworkError = struct NetworkError;

using OnNetworkResponseStart = std::function<void(const NetworkRequest* request,
                                                  const NetworkResponse& response)>;

using OnNetworkResponseUpdate = std::function<void(const NetworkRequest* request,
                                                   const NetworkResponse& response)>;

using OnNetworkSucceededFunc = std::function<void(const NetworkRequest* request,
                                                  const NetworkResponse& response)>;

using OnNetworkFailedFunc = std::function<void(const NetworkRequest* request,
                                               const NetworkError& errorDesc)>;

using OnNetworkCanceledFunc = std::function<void(const NetworkRequest* request)>;

using OnNetworkResponseFunc = std::function<void(const NetworkRequest* request,
                                                 const NetworkResponse& response,
                                                 NetworkStatus status)>;

using WS_OnConnectionStateChangedFunc = void (*)(void* ctx, uint32_t wsid, int32_t state, const char* url);
using WS_OnConnectionErrorFunc = void (*)(void* ctx, uint32_t wsid, int32_t state, const char* url, const char* error);
using WS_OnMessageReceivedFunc = void (*)(void* ctx, uint32_t wsid, const char* message, uint64_t size);
using WS_OnFeedbackLogFunc = void (*)(void* ctx, uint32_t wsid, const char* log);

NAMESPACE_AMAZING_ENGINE_END

#endif /* AMGNetworkPrerequisites_h */
