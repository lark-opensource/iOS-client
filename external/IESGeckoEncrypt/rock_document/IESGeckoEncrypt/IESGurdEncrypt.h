NS_ASSUME_NONNULL_BEGIN

@class IESGurdNetworkResponse;

typedef void(^IESGurdHTTPRequestCompletion)(IESGurdNetworkResponse *response);

extern void IESGurdEncryptRequest(NSString *method, NSString *URLString, NSMutableDictionary *params, IESGurdHTTPRequestCompletion completion);

NS_ASSUME_NONNULL_END
