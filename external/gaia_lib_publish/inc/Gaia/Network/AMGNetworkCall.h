#ifndef AMGNetworkCall_h
#define AMGNetworkCall_h

#include "Gaia/Network/AMGNetworkRequest.h"

#include <mutex>
#include "Gaia/AMGExport.h"
#include "Gaia/AMGRefBase.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

class NetworkRequest;
struct NetworkRequestBody;

class GAIA_LIB_EXPORT NetworkCall : public RefBase
{
public:
    void call(bool sync);

    virtual ~NetworkCall() = default;

    NetworkCall& setWrappedOnResponseFunc(OnNetworkResponseFunc&& succeedFunc);
    NetworkCall& setWrappedOnFailedFunc(OnNetworkFailedFunc&& failedFunc);
    NetworkCall& setWrappedOnCanceledFunc(OnNetworkCanceledFunc&& cancelFunc);

    NetworkCall& setNetworkRequest(NetworkRequest* request);

    void cancel();

    NetworkRequest* getRequest();

    void onResponseStart();

    void onResponseUpdate();

    void onSucceeded();

    void onFailed();

    void onCanceled();

    const std::string& getUrl();

    NetworkRequestBody& getBody();

protected:
    virtual void _cancel() = 0;

    virtual void _call(bool sync) = 0;

protected:
    NetworkResponse m_response;
    NetworkError m_error;

    OnNetworkResponseFunc m_wrappedOnResponseFunc;
    OnNetworkFailedFunc m_wrappedOnFailedFunc;
    OnNetworkCanceledFunc m_wrappedOnCanceledFunc;

private:
    SharePtr<NetworkRequest> m_request;
    bool m_canceled{false};

    std::mutex m_lock;
};

NAMESPACE_AMAZING_ENGINE_END

#endif /* AMGNetworkCall_h */
