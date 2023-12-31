#ifndef AMGNetworkRequest_h
#define AMGNetworkRequest_h

#include "Gaia/Network/AMGNetworkPrerequisites.h"

#include <unordered_map>
#include <string>

#include "Gaia/AMGExport.h"
#include "Gaia/AMGRefBase.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

enum class HttpMethod
{
    GET = 0,
    POST,
};

enum class HttpRequestBodyType
{
    NONE = 0,
    MEMORY,
};

struct NetworkRequestBody
{
public:
    HttpRequestBodyType type = HttpRequestBodyType::NONE;
    std::string data;
};

class GAIA_LIB_EXPORT NetworkRequest : public RefBase
{
public:
    static SharePtr<NetworkRequest> create(HttpMethod method, const std::string& url);

    const std::string& getUrl();
    void setUrl(const std::string& url);

    NetworkRequest& addHeader(const std::string& headerName, const std::string& headerValue);
    const NetworkHeaders& getHeaders() const;

    NetworkRequest& addParam(const std::string& paramName, const std::string& paramValue);
    const NetworkParams& getParams() const;

    bool isCachable() const;
    NetworkRequest& setCachable(bool cachable);

    bool isValid();

    HttpMethod getMethod();
    HttpMethod getMethod() const;

    uint64_t getReadBufferSize() const;
    NetworkRequest& setReadBufferSize(uint64_t readBufferSize);

    NetworkRequest& setOnFailedFunc(OnNetworkFailedFunc&& failedFunc);
    OnNetworkFailedFunc& getOnFailedFunc();

    NetworkRequest& setOnResponseFunc(OnNetworkResponseFunc&& responseFunc);
    OnNetworkResponseFunc& getOnResponseFunc();

    NetworkRequest& setUserData(void* userData);
    void* getUserData();

    NetworkRequest& setBodyType(HttpRequestBodyType type);
    NetworkRequest& setBodyData(const std::string& data);
    NetworkRequest& setBodyData(std::string&& data);

    NetworkRequestBody& getBody();

private:
    NetworkRequest() = default;

private:
    std::string m_url;

    NetworkHeaders m_headers;
    NetworkParams m_params;

    HttpMethod m_method = HttpMethod::GET;

    bool m_cachable = false;

    uint64_t m_readBufferSize = 0;

    OnNetworkFailedFunc m_onFailedFunc;
    OnNetworkResponseFunc m_onResponseFunc;

    NetworkRequestBody m_body;

    void* m_userData = nullptr;
};

NAMESPACE_AMAZING_ENGINE_END

#endif /* AMGNetworkRequest_h */
