//
//  TTNetworkManager.h
//  Pods
//
//  Created by ZhangLeonardo on 15/9/6.
//
//  TTNetworkManager是字节跳动网络库的对业务层的接口
//
//  网络库的requestSerializer以接口及基类形式提供，业务层开发RD可以不用设置，库中提供了已经实现的基类。
//  如果需要自定义网络请求的序列化对象，只要实现TTHTTPRequestSerializerProtocol定义的接口即可，并非
//  一定要求继承基类。
//
//  网络库的responseSerializer只以接口形式提供，这部分的考虑是各组之前的对网络返回处理非常不一致，所以
//  交给业务层自行处理。如果使用网络库， 必须在发起第一个请求之前指定需要用到的responseSerializerClass，
//  否则网络库会报错。
//
//  除了设置请求和返回的序列化对象外，业务开发RD还自已通过commonParams设置通用的参数。通用参数会拼接到get
//  参数上。
//
//  网络库提供三种常用的请求接口：JSON, Model, Binary。
//  用户可以根据requestForJSONWithURL:params:method:needCommonParams:callback:简单的获取JSON对
//  应的task， 该task默认是resume的。如果需要设置优先级（目前仅支持iOS8）,则需要通过带有autoResume:的
//  接口，并且传递no，让task不默认resume，然后设置后优先级后，再resume task
//  三种常用的请求接口都提供了常用和高可控两种接口方案，常用则使用全局设置的序列化对象，不能获取未resume的
//  task。高可控接口的控制力度比较强，但用起来也麻烦，RD自行斟酌。
//
//  网络库还提供了上传接口，可以TTNetworkManager(UploadData)中查看
//
//  网络库还提供了同步的接口， 可以在TTNetworkManager(SynchronizedRequest)中查看


#import <Foundation/Foundation.h>
#import "TTNetworkDefine.h"
#import "TTDispatchResult.h"
#import "TTDnsResult.h"
#import "TTHTTPRequestSerializerProtocol.h"
#import "TTHTTPResponseSerializerProtocol.h"
#import "TTHttpTask.h"
#import "TTNetworkQualityEstimator.h"

@class RequestRetryResult;

NS_ASSUME_NONNULL_BEGIN
extern NSString * const kTTNetColdStartFinishNotification;
extern NSString * const kTTNetNetDetectResultNotification;
extern NSString * const kTTNetConnectionTypeNotification;
extern NSString * const kTTNetNetworkQualityLevelNotification;
extern NSString * const kTTNetServerConfigChangeNotification;
extern NSString * const kTTNetMultiNetworkStateNotification;
extern NSString * const kTTNetServerConfigChangeDataKey;
extern NSString * const kTTNetStoreIdcChangeNotification;
extern NSString * const kTTNetPublicIPsNotification;
extern NSString * const kTTNetNeedDropClientRequest;
extern NSString * const kTTNetRequestTagHeaderName;

/**
 * execute after request serializer， before request start
 */
typedef void (^RequestFilterBlock)(TTHttpRequest * _Nonnull request);

/**
 * execute before response serializer, both response and responseError can NOT be changed
 */
typedef void (^ResponseFilterBlock)(TTHttpRequest * _Nonnull request, TTHttpResponse * _Nonnull response, id _Nullable data, NSError * _Nullable responseError);

/**
 * change data in this response block before response serializer, responseError can be changed
 */
typedef void (^ResponseMutableDataFilterBlock)(TTHttpRequest * _Nonnull request, TTHttpResponse * _Nonnull response, NSData * _Nullable * _Nonnull data, NSError * _Nullable * _Nullable responseError);

/**
 * execute before response serializer，responseError can be changed
 */
typedef void (^ResponseChainFilterBlock)(TTHttpRequest * _Nonnull request, TTHttpResponse * _Nonnull response, id _Nullable data, NSError * _Nullable * _Nullable responseError);

//Intercept TTNet response and check for verification code
typedef BOOL (^AddResponseHeadersCallback)(TTHttpResponse * _Nonnull response);

typedef RequestRetryResult* _Nonnull (^RetryRequestByTuringHeaderCallback)(TTHttpResponse * _Nonnull response);

typedef NSDictionary<NSString *, NSString *> * _Nullable (^TTNetworkManagerCommonParamsBlock)(void);

typedef NSDictionary<NSString *, NSString *> * _Nullable (^TTNetworkManagerCommonParamsBlockWithURL)(NSString *);
/**
 * get L0 or L1 level common paramter from LogSDK, level = 0 means L0, level = 1 means L1
*/
typedef NSDictionary<NSString *, NSString *> * _Nullable (^TTNetworkManagerGetCommonParamsByLevelBlock)(int level);
typedef NSURL * _Nullable (^TTURLTransformBlock)(NSURL * _Nonnull url);

typedef NS_ENUM(NSInteger, TTNetworkManagerImplType) {
    TTNetworkManagerImplTypeAFNetworking = 0,
    TTNetworkManagerImplTypeLibChromium = 1,
};

typedef NSString *TTNetworkManagerPathMatchingType NS_STRING_ENUM;
FOUNDATION_EXPORT TTNetworkManagerPathMatchingType const kPathEqualMatch; // equal match
FOUNDATION_EXPORT TTNetworkManagerPathMatchingType const kPathPrefixMatch; // prefix match
FOUNDATION_EXPORT TTNetworkManagerPathMatchingType const kPathPatternMatch; // pattern match
FOUNDATION_EXPORT TTNetworkManagerPathMatchingType const kCommonMatch; // wildcard match,support * and ?

typedef NSURL * _Nonnull (^TTURLHashBlock)(NSURL * _Nonnull url, NSDictionary * _Nonnull formData);

typedef NS_ENUM(NSInteger, TTNetEffectiveConnectionType) {
  // Effective connection type reported when the network is fake network.
  EFFECTIVE_CONNECTION_TYPE_FAKE_NETWORK = -1,

  // Unknown network quality.
  EFFECTIVE_CONNECTION_TYPE_UNKNOWN = 0,

  // Unreachable, the device does not have a connection or the connection is too slow to be usable.
  EFFECTIVE_CONNECTION_TYPE_OFFLINE,
    
  // Poor 2G connection.
  EFFECTIVE_CONNECTION_TYPE_SLOW_2G,

  // Faster 2G connection.
  EFFECTIVE_CONNECTION_TYPE_2G,

  // 3G connection.
  EFFECTIVE_CONNECTION_TYPE_3G,

  //For bytedance network quality estimation
  // doc/doccnpEekZvelthGFc7IqylvvEa
  // Effective connection type reported when the network has the quality of a 4G
  // connection.
  //EFFECTIVE_CONNECTION_TYPE_4G,

  // Effective connection type reported when the network has the quality of a SLOW_4G
  // connection.
  EFFECTIVE_CONNECTION_TYPE_SLOW_4G,

  // Effective connection type reported when the network has the quality of a MODERATE_4G
  // connection.
  EFFECTIVE_CONNECTION_TYPE_MODERATE_4G,

  // Effective connection type reported when the network has the quality of a GOOD_4G
  // connection.
  EFFECTIVE_CONNECTION_TYPE_GOOD_4G,

  // Effective connection type reported when the network has the quality of a EXCELLENT_4G
  // connection.
  EFFECTIVE_CONNECTION_TYPE_EXCELLENT_4G,

  // Last value of the effective connection type. This value is unused.
  EFFECTIVE_CONNECTION_TYPE_LAST,
};

typedef NS_ENUM(int, TTNetworkQualityLevel) {
    NQL_FAKE_NETWORK = -1,
    NQL_UNKNOWN = 0,  // Default value
    NQL_OFFLINE = 1,
    NQL_POOR_NETWORK = 2,
    NQL_MODERATE_NETWORK = 3,
    NQL_GOOD_NETWORK,
    NQL_LAST,
};

@interface TTClientCertificate : NSObject

@property(nonatomic, copy) NSArray<NSString *> * HostsList;

@property(nonatomic, strong) NSData * Certificate;

@property(nonatomic, strong) NSData * PrivateKey;

@end

@interface TTQuicHint : NSObject

@property(nonatomic, copy) NSString* Host;

@property(nonatomic, assign) int Port;

@property(nonatomic, assign) int AlterPort;

@end

#pragma mark - new request filter object
/**
 * new request filter object
 * requestFilterName must be unique
 */
@interface TTRequestFilterObject : NSObject
//request filter name, user should pass a unique name
@property(nonatomic, copy) NSString* requestFilterName;
//request filter block
@property(nonatomic, copy) RequestFilterBlock requestFilterBlock;

- (instancetype)initWithName:(NSString *)requestFilterName requestFilterBlock:(RequestFilterBlock)requestFilterBlock;
@end

#pragma mark - new response filter object
/**
 * new response filter object
 * requestFilterName must be unique
 */
@interface TTResponseFilterObject : NSObject
//response filter name, user should pass a unique name
@property(nonatomic, copy) NSString* responseFilterName;
//response filter block
@property(nonatomic, copy) ResponseFilterBlock responseFilterBlock;

- (instancetype)initWithName:(NSString *)responseFilterName responseFilterBlock:(ResponseFilterBlock)responseFilterBlock;
@end

@interface TTResponseChainFilterObject : NSObject
//response filter name, user should pass a unique name
@property(nonatomic, copy) NSString* responseChainFilterName;
//response chain filter block, which could change error in block
@property(nonatomic, copy) ResponseChainFilterBlock responseChainFilterBlock;

- (instancetype)initWithName:(NSString *)responseChainFilterName responseChainFilterBlock:(ResponseChainFilterBlock)responseChainFilterBlock;
@end

@interface TTResponseMutableDataFilterObject : NSObject
//response filter name, user should pass a unique name
@property(nonatomic, copy) NSString* responseMutableDataFilterName;
//change data in this response block before response serializer, responseError can be changed as well
@property(nonatomic, copy) ResponseMutableDataFilterBlock responseMutableDataFilterBlock;

- (instancetype)initWithName:(NSString *)responseMutableDataFilterName responseMutableDataFilterBlock:(ResponseMutableDataFilterBlock)responseMutableDataFilterBlock;
@end

#pragma mark - new redirect filter object
/**
 * 全局重定向回调
 */

@class TTRedirectTask;

typedef void (^RedirectFilterBlock)(TTRedirectTask * _Nonnull task);

@interface TTRedirectFilterObject : NSObject
@property(nonatomic, copy) NSString* redirectFilterName;
@property(nonatomic, copy) RedirectFilterBlock redirectFilterBlock;

- (instancetype)initWithName:(NSString *)redirectFilterName redirectFilterBlock:(RedirectFilterBlock)redirectFilterBlock;
@end

#pragma mark - TTNetworkManager
@interface TTNetworkManager : NSObject

/**
 *  默认JSON类型返回值得序列化对象Class
 */
@property(nonatomic, strong, nullable)Class<TTJSONResponseSerializerProtocol> defaultJSONResponseSerializerClass;
/**
 *  默认Model类型返回值的序列化对象Class
 */
@property(nonatomic, strong)Class<TTResponseModelResponseSerializerProtocol> defaultResponseModelResponseSerializerClass;
/**
 *  默认二进制返回类型的序列化对象Class
 */
@property(nonatomic, strong, nullable)Class<TTBinaryResponseSerializerProtocol> defaultBinaryResponseSerializerClass;
/**
 *  默认请求序列化对象Class
 */
@property(nonatomic, strong, nullable)Class<TTHTTPRequestSerializerProtocol> defaultRequestSerializerClass;
/**
 *  默认在Response返回之前做一些预处理工作的Class
 */
@property(nonatomic, strong, nullable)Class<TTResponsePreProcessorProtocol> defaultResponseRreprocessorClass;
/**
 *  设置通用参数， 静态
 */
@property(nonatomic, copy, nullable)NSDictionary * commonParams;

/**
 *  设置通用参数， 动态
 */
@property(atomic, copy, nullable)TTNetworkManagerCommonParamsBlock commonParamsblock;

/**
 *  根据当前URL进行推理，设置通用参数，动态
 */
@property(atomic, copy, nullable)TTNetworkManagerCommonParamsBlockWithURL commonParamsblockWithURL;

/**
 *  设置region对应的TNC hardcode配置， 静态
 */
@property(nonatomic, copy, nullable)NSDictionary *getDomainRegionConfig;

/**
 * enable new common parameter strategy
 * default value is NO,which means use old strategy
 */
@property(nonatomic, assign) BOOL enableNewAddCommonParamsStrategy;

/**
 * enable add min common paramter when only match domain
 * default value is NO,which means add max common paramter
 */
@property(nonatomic, assign) BOOL enableMinCommonParamsWhenDomainMatch;

/**
 * get L0 or L1 level common paramter from LogSDK
 * level = 0 means L0, level = 1 means L1
 * L0 means max common paramter, including sensitive paramter
 * L1 means min common paramter,excluding sensitive paramter
 */
@property(nonatomic, copy, nullable) TTNetworkManagerGetCommonParamsByLevelBlock getCommonParamsByLevelBlock;

/**
 * set domain list which is used to filter request and add common parameter
 * domain are NSString
 * only matched domian will add common parameter
 * support wildcard matching, like * and ?
 */
@property(atomic, copy, nullable) NSArray<NSString *> *domainFilterArray;

/**
 * set path that will add max common parameter
 * key is matching type,support kPathEqualMatch,kPathPrefixMatch,kPathPatternMatch
 * value is NSArray that contains NSString type path
 */
@property(atomic, copy, nullable) NSDictionary<TTNetworkManagerPathMatchingType, NSArray<NSString *> *> *maxParamsPathFilterDict;

/**
 * set path that will add min common parameter
 * key is matching type,support kPathEqualMatch,kPathPrefixMatch,kPathPatternMatch
 * value is NSArray that contains NSString type path
*/
@property(atomic, copy, nullable) NSDictionary<TTNetworkManagerPathMatchingType, NSArray<NSString *> *> *minParamsPathFilterDict;

/**
 *the keys to be removed from L1 level common paramters
 */
@property(atomic, copy, nullable) NSArray<NSString *> *minExcludingParams;

/**
 *  设置url transfer block
 */
@property (nonatomic, copy, nullable)TTURLTransformBlock urlTransformBlock;

/**
 *  默认是NO，如何设置为YES，内部不对JSON进行序列化
 */
@property(nonatomic, assign)BOOL pureChannelForJSONResponseSerializer;

/**
 *  默认是NO，如何设置为YES，则对query里面的敏感字段加密（放到query最前面， 同时去掉query里面那些对应未加密的敏感字段）
 */
@property(nonatomic, assign) BOOL isEncryptQuery;
/**
 *  默认是NO，如何设置为YES，则对query里面的敏感字段加密，并放到header里面（去掉query里面那些对应未加密的敏感字段）
 */
@property(nonatomic, assign) BOOL isEncryptQueryInHeader;
/**
 *  默认是NO，如何设置为YES，则对query里面的敏感字段加密，（不去掉query里面那些对应的未加密敏感字段）
 */
@property(nonatomic, assign) BOOL isKeepPlainQuery;

/**
 *  设置url hash block，可以用于签名校验
 */
@property(nonatomic, copy, nullable) TTURLHashBlock urlHashBlock;

//add verification code callback, TTNet will retry the request if this block return YES
@property(atomic, copy, nullable) AddResponseHeadersCallback addResponseHeadersCallback;

@property(atomic, copy, nullable) RetryRequestByTuringHeaderCallback retryRequestByTuringHeaderCallback;

/**
 * @brief Disable cronet native IPv6 reachability detect check and use SCNetwork method.
 */
@property(nonatomic, assign) BOOL scIpv6DetectEnabled;

/*!
 * @brief 是否使用大小写敏感的Headers字典。存储Header时仍然区分大小写，获取Header值时不区分大小写。
 */
@property(nonatomic, assign) BOOL enableRequestHeaderCaseInsensitive;

/**
 *  生成TTNetworkManager单例
 *
 *  @return TTNetworkManager单例
 */
+ (instancetype)shareInstance;


/**
 *  设置底层网络库实现
 */
+ (void)setLibraryImpl:(TTNetworkManagerImplType)impl DEPRECATED_MSG_ATTRIBUTE("Please don`t call this function,default impl is chromium,set to AFNetworking will lead to error");
+ (TTNetworkManagerImplType)getLibraryImpl;

- (NSURL *)transferedURL:(NSURL *)url;

//set local query filter engine config while initializing TTNetworkManager
- (void)setLocalCommonParamsConfig:(NSString *)contentString;

/**
 *  默认是NO，如何设置为YES，Chromium net 会启用http dns， AF无作用
 */
+ (void)setHttpDnsEnabled:(BOOL)httpDnsEnabled;
+ (BOOL)httpDnsEnabled;

//add by songlu
typedef void (^Monitorblock)(NSDictionary* _Nonnull, NSString* _Nonnull);
+ (void)setMonitorBlock:(Monitorblock)block;
+ (Monitorblock)MonitorBlock;

typedef void (^GetDomainblock)(NSData* _Nonnull);
+ (void)setGetDomainBlock:(GetDomainblock)block;
+ (GetDomainblock)GetDomainBlock;

- (void)creatAppInfo;

- (void)enableVerboseLog;// AF not implemented

- (void)start;

- (void)setProxy:(NSString *)proxy;// AF not implemented
- (void)setBoeProxyEnabled:(BOOL)enabled;// AF not implemented
- (void)addReferrerScheme:(NSString*)newScheme; // AF not implemented

- (TTNetEffectiveConnectionType)getEffectiveConnectionType;
- (TTNetworkQuality*)getNetworkQuality;
- (TTPacketLossMetrics*)getPacketLossMetrics:(TTPacketLossProtocol)protocol;
- (TTNetworkQualityV2*)getNetworkQualityV2;

//add for get-domain and api host
@property(nonatomic, copy) NSString* ServerConfigHostFirst;
@property(nonatomic, copy) NSString* ServerConfigHostSecond;
@property(nonatomic, copy) NSString* ServerConfigHostThird;

@property(nonatomic, copy) NSString* DomainHttpDns;
@property(nonatomic, copy) NSString* DomainNetlog;
@property(nonatomic, copy) NSString* DomainBoe;
@property(nonatomic, copy) NSString* DomainBoeHttps;

@property(nonatomic, copy, nullable) NSString* getDomainDefaultJSON;

@property(nonatomic, copy, nullable) NSString* bypassBoeJSON;

@property(atomic, copy, nullable) NSArray* ServerCertificate;

@property(atomic, copy, nullable) NSArray<TTClientCertificate *> * ClientCertificates;

@property(nonatomic, assign) BOOL enableHttp2;

@property(nonatomic, assign) BOOL enableQuic;

@property(nonatomic, assign) BOOL enableBrotli;

@property (atomic, copy, nullable) NSDictionary<NSString *, NSString *> *TncRequestHeaders;

@property (atomic, copy, nullable) NSDictionary<NSString *, NSString *> *TncRequestQueries;

@property(nonatomic, copy, nullable) NSString* userAgent;

@property(atomic, copy, nullable) NSArray<TTQuicHint *> * QuicHints;

@property(nonatomic, copy, nullable) NSString* storeIdcRuleJSON;

@property(nonatomic, copy, nullable) NSString* appInitialRegionInfo;

// device's default store_idc
@property(nonatomic, copy, nullable) NSString* StoreIdc;

// user id
@property(nonatomic, copy, nullable) NSString* UserId;

// Additional setting for sdk_app_id, can overwrite sdk_app_id in commonparams block
@property(nonatomic, copy, nullable) NSString* tncSdkAppId;

// Additional setting for sdk_version, can overwrite sdk_version in commonparams block
@property(nonatomic, copy, nullable) NSString* tncSdkVersion;

// Host resolver rules for testing
@property(nonatomic, copy, nullable) NSString* hostResolverRulesForTesting;

// Get the client public ip address which returned from TT-HttpDns service.
// NOTE: please DO NOT CACHE the result, call it directly instead.
@property(nonatomic, copy, readonly, nullable) NSString* clientIP;

// Get all public IPv4 exit addresses.
// NOTE: please DO NOT CACHE the result, call it directly instead.
@property (atomic, strong, readonly, nullable) NSArray<NSString *> *publicIPv4List;

// Get all public IPv6 exit addresses.
// NOTE: please DO NOT CACHE the result, call it directly instead.
@property (atomic, strong, readonly, nullable) NSArray<NSString *> *publicIPv6List;

// Get the information of IDC where user data is located.
// NOTE: please DO NOT CACHE the result, call it directly instead.
@property(nonatomic, copy, readonly, nullable) NSString* userIdc;

// Get the information of region where user data is located.
// NOTE: please DO NOT CACHE the result, call it directly instead.
@property(nonatomic, copy, readonly, nullable) NSString* userRegion;

// Get the information of region source where user data is located.
// NOTE: please DO NOT CACHE the result, call it directly instead.
@property(nonatomic, copy, readonly, nullable) NSString* regionSource;

// Network thread will set value.And others thread read it.So add atomic.
@property(atomic, copy, readonly, nullable) NSString *shareCookieDomainNameList;

// get oc layer version which produced by Bits
@property (nonatomic, copy, readonly) NSString* componentVersion;

// Enable using domestic store region, default value is NO.
@property(nonatomic, assign) BOOL useDomesticStoreRegion;

typedef void (^GetNqeResultBlock)(NSInteger httpRtt, NSInteger transportRtt, NSInteger downstreamThroughputKbps);

typedef void (^GetPacketLossResultBlock)(TTPacketLossProtocol protocol, double upstreamLossRate, double upstreamLossRateVariance, double downstreamLossRate, double downstreamLossRateVariance);

/**
 *  设置全局回调函数， 可以在request发出前和response收到后得到回调
 */
@property(nonatomic, copy, nullable) RequestFilterBlock requestFilterBlock DEPRECATED_MSG_ATTRIBUTE("call addRequestFilterObject instead");
@property(nonatomic, copy, nullable) ResponseFilterBlock responseFilterBlock DEPRECATED_MSG_ATTRIBUTE("call addResponseFilterObject instead");

/**
 *  拦截器开关
 */
- (void)setEnableReqFilter:(BOOL)enableReqFilter;

/**
 *  request 拦截器
 */
- (void)addRequestFilterBlock:(RequestFilterBlock)requestFilterBlock DEPRECATED_MSG_ATTRIBUTE("call addRequestFilterObject instead");

/**
 *  remove request filter
 */
- (void)removeRequestFilterBlock:(RequestFilterBlock)requestFilterBlock DEPRECATED_MSG_ATTRIBUTE("call removeRequestFilterObject instead");

/**
 *  response 拦截器
 */
- (void)addResponseFilterBlock:(ResponseFilterBlock)responseFilterBlock DEPRECATED_MSG_ATTRIBUTE("call addResponseFilterObject instead");

/**
 *  remove response filter
 */
- (void)removeResponseFilterBlock:(ResponseFilterBlock)responseFilterBlock DEPRECATED_MSG_ATTRIBUTE("call removeResponseFilterObject instead");

/**
 *  response chain 拦截器，可修改Error
 */
- (void)addResponseChainFilterBlock:(ResponseChainFilterBlock)responseChainFilterBlock DEPRECATED_MSG_ATTRIBUTE("call addResponseChainFilterObject instead");

/**
 *  remove response chain filter
 */
- (void)removeResponseChainFilterBlock:(ResponseChainFilterBlock)responseChainFilterBlock DEPRECATED_MSG_ATTRIBUTE("call removeResponseChainFilterObject instead");

/**
 *add a response filter block which can change data
 */
- (void)addResponseMutableDataFilterBlock:(ResponseMutableDataFilterBlock)responseMutableDataFilterBlock DEPRECATED_MSG_ATTRIBUTE("call addResponseMutableDataFilterObject instead");

- (void)removeResponseMutableDataFilterBlock:(ResponseMutableDataFilterBlock)responseMutableDataFilterBlock DEPRECATED_MSG_ATTRIBUTE("call removeResponseMutableDataFilterObject instead");

/**
 * add and remove  new request and response filter object
 */
- (BOOL)addRequestFilterObject:(TTRequestFilterObject *)requestFilterObject;

- (void)removeRequestFilterObject:(TTRequestFilterObject *)requestFilterObject;

- (BOOL)addResponseFilterObject:(TTResponseFilterObject *)responseFilterObject;

- (void)removeResponseFilterObject:(TTResponseFilterObject *)responseFilterObject;

- (BOOL)addResponseChainFilterObject:(TTResponseChainFilterObject *)responseChainFilterObject;

- (void)removeResponseChainFilterObject:(TTResponseChainFilterObject *)responseChainFilterObject;

- (BOOL)addResponseMutableDataFilterObject:(TTResponseMutableDataFilterObject *)responseMutableDataFilterObject;

- (void)removeResponseMutableDataFilterObject:(TTResponseMutableDataFilterObject *)responseMutableDataFilterObject;

- (BOOL)addRedirectFilterObject:(TTRedirectFilterObject *)redirectFilterObject;

- (void)removeRedirectFilterObject:(TTRedirectFilterObject *)redirectFilterObject;

/**
 *  默认是NO，如果设置为YES，则业务回调不在主线程里
 *  建议设置为YES，对回调速度提升明显， 特别是刚启动时。 由业务代码去主动把UI相关的逻辑dispatch到主线程
 *  细节数据见： https://wiki.bytedance.net/pages/viewpage.action?pageId=213732839
 */
@property(nonatomic, assign) BOOL dontCallbackInMainThread;

/**
 *  TTNet提供enableApiHttpIntercept开关，用于拦截TNC下发的api_http_host_list字段对应的api http请求，并上报api_http类型的端监控日志，业务在回调里可以拿到此情况对应的错误码TTNetworkErrorCodeApiHttpIntercepted(-8)，业务在local_test开启以保证在开发阶段发现api http请求的问题
 *  *会在主线程和io线程访问，加atomic修饰
 */
@property(atomic, assign) BOOL enableApiHttpIntercept;

/**
 *  开启enableApiHttpIntercept开关时，存储TNC下发的api_http_host_list
 *  *会在主线程和io线程访问，加atomic修饰
 */
@property(atomic, copy, nullable) NSArray *apiHttpHostListArray;

/**
 *  关闭http缓存的开关，Cronet默认开启，某些低端机上业务可以选择性关闭缓存
 */
@property(nonatomic, assign) BOOL enableHttpCache;

/**
 *Cronet初始化时默认的http缓存的大小是64*1024*1024，提供业务设置大小的接口
 */
@property(nonatomic, assign) int httpCacheSize;

/*
 * Cronet Init Network Thread Priority
 */
@property(nonatomic, assign) double initNetworkThreadPriority;

/**
 *  长连接地址设置回调函数，在get domain含有frontier 地址收到后得到回调
 */
typedef void (^FrontierUrlsCallbackBlock)(NSArray<NSString *> * _Nonnull urls);
+ (void)setFrontierUrlsCallbackBlock:(FrontierUrlsCallbackBlock)block;
+ (nullable FrontierUrlsCallbackBlock)GetFrontierUrlsCallbackBlock;

/**
 *  set to YES in ColdStartObserver::OnCronetInitCompleted
 *  after the kTTNetInitCompletedNotification
 */
@property(atomic, assign) BOOL isInitCompleted;

/**
 * 用于安全接口的回调，会在请求发送前调用，回调实现者可获取请求url和Header并新增校验Header
 *
 */
typedef NSDictionary* _Nullable (^AddSecurityFactorBlock)(NSURL* _Nonnull url, NSDictionary * _Nonnull requestHeaders);
@property(atomic, copy, nullable) AddSecurityFactorBlock addSecurityFactorBlock;

typedef void (^TTRedirectInterceptorBlock)(TTHttpTask * _Nonnull httpTask);
@property(atomic, copy, nullable) TTRedirectInterceptorBlock redirectInterceptorBlock;

/**
 *improper images check in webview
 *AddAIImageCheckBlock is set by ClientAI to check whether the image is improper
 *AIImageCheckDidFinishBlock is set by TTNetworkManager to get result of the diagnosed image
 */
typedef void (^AIImageCheckDidFinishBlock)(NSString * _Nonnull uuid, int result, NSDictionary * _Nonnull extraInfo);
typedef void (^AddAIImageCheckBlock)(NSString * _Nonnull uuid, NSData * _Nonnull data, NSDictionary * _Nonnull extraInfo, AIImageCheckDidFinishBlock _Nonnull handler);
@property(atomic, copy, nullable) AddAIImageCheckBlock addAIImageCheckBlock;
//send image data to Client AI from this point, acceptable range is (0.0, 1.0], for example 0.65 (65%), default value is 70%
@property(nonatomic, assign) float imageCheckPoint;
//send image data to Client AI if data increasing by this step after imageCheckPoint, acceptable range is (0.0, 1.0), for example 0.10 (10%), default value is 15%
@property(nonatomic, assign) float increasingStep;

#pragma mark -- Response Model
#pragma mark -- Response Model Request Use RequestModel
/**
 *  通过requestModel请求
 *
 *  @param model    请求model
 *  @param callback 结果回调
 *
 *  @return TTHttpTask
 */
- (nullable TTHttpTask *)requestModel:(TTRequestModel *)model
                          callback:(nullable TTNetworkResponseModelFinishBlock)callback;

/**
 *  通过requestModel请求
 *
 *  @param model    请求model
 *  @param callback 结果回调
 *  @param callbackInMainThread YES在主线程回调（不建议设置为YES,若为NO则在global queue回调），AF里该参数不起作用
 *
 *  @return TTHttpTask
 */
//NOTE: callbackInMainThread is NOT USED
- (nullable TTHttpTask *)requestModel:(TTRequestModel *)model
                    callback:(nullable TTNetworkResponseModelFinishBlock)callback
        callbackInMainThread:(BOOL)callbackInMainThread;
/**
 *  通过requestModel请求
 *
 *  @param model              请求model
 *  @param requestSerializer  自定义请求的序列化对象, 如果传nil，用默认值
 *  @param responseSerializer 自定义返回结果序列化对象, 如果传nil，用默认值
 *  @param autoResume         是否自动开始
 *  @param callback           回调结果
 *
 *  @return TTHttpTask
 */
- (nullable TTHttpTask *)requestModel:(TTRequestModel *)model
                 requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                responseSerializer:(nullable Class<TTResponseModelResponseSerializerProtocol>)responseSerializer
                        autoResume:(BOOL)autoResume
                          callback:(nullable TTNetworkResponseModelFinishBlock)callback;

/**
 *  通过requestModel请求
 *
 *  @param model              请求model
 *  @param requestSerializer  自定义请求的序列化对象, 如果传nil，用默认值
 *  @param responseSerializer 自定义返回结果序列化对象, 如果传nil，用默认值
 *  @param autoResume         是否自动开始
 *  @param callbackWithResponse           回调结果，回调里有response
 *
 *  @return TTHttpTask
 */
- (nullable TTHttpTask *)requestModelWithResponse:(TTRequestModel *)model
                       requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                      responseSerializer:(nullable Class<TTResponseModelResponseSerializerProtocol>)responseSerializer
                              autoResume:(BOOL)autoResume
                                callback:(nullable TTNetworkModelFinishBlockWithResponse)callbackWithResponse;

/**
 *  通过requestModel请求
 *
 *  @param model              请求model
 *  @param requestSerializer  自定义请求的序列化对象, 如果传nil，用默认值
 *  @param responseSerializer 自定义返回结果序列化对象, 如果传nil，用默认值
 *  @param autoResume         是否自动开始
 *  @param callback           回调结果
 *  @param callbackInMainThread YES在主线程回调（不建议设置为YES,若为NO则在global queue回调），AF里该参数不起作用
 *
 *  @return TTHttpTask
 */
//NOTE: callbackInMainThread is NOT USED
- (nullable TTHttpTask *)requestModel:(TTRequestModel *)model
           requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
          responseSerializer:(nullable Class<TTResponseModelResponseSerializerProtocol>)responseSerializer
                  autoResume:(BOOL)autoResume
                    callback:(nullable TTNetworkResponseModelFinishBlock)callback
        callbackInMainThread:(BOOL)callbackInMainThread;

/**
 *当callbackInMainThread == NO时，即回调在子线程时，支持业务传入他们自己设置回调线程优先级的callbackQueue
 *AF NOT Implemented
 */
- (nullable TTHttpTask *)requestModel:(TTRequestModel *)model
           requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
          responseSerializer:(nullable Class<TTResponseModelResponseSerializerProtocol>)responseSerializer
                  autoResume:(BOOL)autoResume
                    callback:(nullable TTNetworkResponseModelFinishBlock)callback
               callbackQueue:(dispatch_queue_t)callbackQueue;

#pragma mark -- Response JSON
#pragma mark -- Response JSON Request User URL

/**
 *  通过URL和参数获取JSON,  调用后， task会自动resume
 *
 *  @param URL                请求的URL
 *  @param params             请求的参数
 *  @param method             请求的方法
 *  @param commonParams       是否需要通用参数
 *  @param callback           回调结果
 *
 *  @return TTHttpTask
 */
- (nullable TTHttpTask *)requestForJSONWithURL:(NSString *)URL
                                     params:(id _Nullable)params
                                     method:(NSString *)method
                           needCommonParams:(BOOL)commonParams
                                   callback:(nullable TTNetworkJSONFinishBlock)callback;

/**
 @param callbackInMainThread YES在主线程回调（不建议设置为YES,若为NO则在global queue回调），AF里该参数不起作用
 */
- (nullable TTHttpTask *)requestForJSONWithURL:(NSString *)URL
                               params:(id _Nullable)params
                               method:(NSString *)method
                     needCommonParams:(BOOL)commonParams
                             callback:(nullable TTNetworkJSONFinishBlock)callback
                 callbackInMainThread:(BOOL)callbackInMainThread;

/**
 *  通过URL和参数获取JSON,  调用后， task会自动resume, 返回的回调里面有TTHttpResponse
 *
 *  @param URL                请求的URL
 *  @param params             请求的参数
 *  @param method             请求的方法
 *  @param commonParams       是否需要通用参数
 *  @param callback           回调结果
 *
 *  @return TTHttpTask
 */

- (nullable TTHttpTask *)requestForJSONWithResponse:(NSString *)URL
                                    params:(id _Nullable)params
                                    method:(NSString *)method
                          needCommonParams:(BOOL)commonParams
                                  callback:(nullable TTNetworkJSONFinishBlockWithResponse)callback;

/**
 *  通过URL和参数获取JSON,调用后,task会自动resume
 *
 *  @param URL                请求的URL
 *  @param params             请求的参数
 *  @param method             请求的方法
 *  @param commonParams       是否需要通用参数
 *  @param requestSerializer  设置该接口该次请求的的序列化对象, 如果传nil，用默认值
 *  @param responseSerializer 设置该接口该次返回的的序列化对象, 如果传nil，用默认值
 *  @param autoResume         是否自动开始
 *  @param callback           回调结果
 *
 *  @return TTHttpTask
 */
- (nullable TTHttpTask *)requestForJSONWithURL:(NSString *)URL
                                     params:(id _Nullable)params
                                     method:(NSString *)method
                           needCommonParams:(BOOL)commonParams
                          requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                         responseSerializer:(nullable Class<TTJSONResponseSerializerProtocol>)responseSerializer
                                 autoResume:(BOOL)autoResume
                                   callback:(nullable TTNetworkJSONFinishBlock)callback;


/**
 *  通过URL和参数获取JSON,回调里面有Response
 *
 *  @param URL                请求的URL
 *  @param params             请求的参数
 *  @param method             请求的方法
 *  @param commonParams       是否需要通用参数
 *  @param requestSerializer  设置该接口该次请求的的序列化对象, 如果传nil，用默认值
 *  @param responseSerializer 设置该接口该次返回的的序列化对象, 如果传nil，用默认值
 *  @param autoResume         是否自动开始
 *  @param callback           回调结果
 *
 *  @return TTHttpTask
 */
- (nullable TTHttpTask *)requestForJSONWithResponse:(NSString *)URL
                                    params:(id _Nullable)params
                                    method:(NSString *)method
                          needCommonParams:(BOOL)commonParams
                         requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                        responseSerializer:(nullable Class<TTJSONResponseSerializerProtocol>)responseSerializer
                                autoResume:(BOOL)autoResume
                                  callback:(nullable TTNetworkJSONFinishBlockWithResponse)callback;

/**
 *  通过URL和参数获取JSON，支持定制header，回调里面有Response
 *
 *  @param URL                请求的URL
 *  @param params             请求的参数
 *  @param method             请求的方法
 *  @param commonParams       是否需要通用参数
 *  @param headerField        header dic
 *  @param requestSerializer  设置该接口该次请求的的序列化对象, 如果传nil，用默认值
 *  @param responseSerializer 设置该接口该次返回的的序列化对象, 如果传nil，用默认值
 *  @param autoResume         是否自动开始
 *  @param callback           回调结果
 *
 *  @return TTHttpTask
 */
- (nullable TTHttpTask *)requestForJSONWithResponse:(NSString *)URL
                                    params:(id _Nullable)params
                                    method:(NSString *)method
                          needCommonParams:(BOOL)commonParams
                               headerField:(nullable NSDictionary *)headerField
                         requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                        responseSerializer:(nullable Class<TTJSONResponseSerializerProtocol>)responseSerializer
                                autoResume:(BOOL)autoResume
                                  callback:(nullable TTNetworkJSONFinishBlockWithResponse)callback;

/**
 *  通过URL和参数获取JSON，支持定制header，回调里面有Response
 *
 *  @param URL                请求的URL
 *  @param params             请求的参数
 *  @param method             请求的方法
 *  @param commonParams       是否需要通用参数
 *  @param headerField        header dic
 *  @param requestSerializer  设置该接口该次请求的的序列化对象, 如果传nil，用默认值
 *  @param responseSerializer 设置该接口该次返回的的序列化对象, 如果传nil，用默认值
 *  @param autoResume         是否自动开始
 *  @param verifyRequest      是否要校验request
 *  @param isCustomizedCookie 是否要使用自定义的cookie, 如果是No，则会默认携带系统cookie
 *  @param callback           回调结果
 *
 *  @return TTHttpTask
 */
- (nullable TTHttpTask *)requestForJSONWithResponse:(NSString *)URL
                                    params:(id _Nullable)params
                                    method:(NSString *)method
                          needCommonParams:(BOOL)commonParams
                               headerField:(nullable NSDictionary *)headerField
                         requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                        responseSerializer:(nullable Class<TTJSONResponseSerializerProtocol>)responseSerializer
                                autoResume:(BOOL)autoResume
                             verifyRequest:(BOOL)verifyRequest
                        isCustomizedCookie:(BOOL)isCustomizedCookie
                                  callback:(nullable TTNetworkJSONFinishBlockWithResponse)callback;


/**
 *  通过URL和参数获取JSON，支持定制header，回调里面有Response
 *
 *  @param URL                请求的URL
 *  @param params             请求的参数
 *  @param method             请求的方法
 *  @param commonParams       是否需要通用参数
 *  @param headerField        header dic
 *  @param requestSerializer  设置该接口该次请求的的序列化对象, 如果传nil，用默认值
 *  @param responseSerializer 设置该接口该次返回的的序列化对象, 如果传nil，用默认值
 *  @param autoResume         是否自动开始
 *  @param verifyRequest      是否要校验request
 *  @param isCustomizedCookie 是否要使用自定义的cookie, 如果是No，则会默认携带系统cookie
 *  @param callback           回调结果
 *  @param callbackInMainThread YES在主线程回调（不建议设置为YES），AF里该参数不起作用
 *
 *  @return TTHttpTask
 */
// NOTE: callbackInMainThread is not used in AF
- (nullable TTHttpTask *)requestForJSONWithResponse:(NSString *)URL
                                    params:(id _Nullable)params
                                    method:(NSString *)method
                          needCommonParams:(BOOL)commonParams
                               headerField:(nullable NSDictionary *)headerField
                         requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                        responseSerializer:(nullable Class<TTJSONResponseSerializerProtocol>)responseSerializer
                                autoResume:(BOOL)autoResume
                             verifyRequest:(BOOL)verifyRequest
                        isCustomizedCookie:(BOOL)isCustomizedCookie
                                  callback:(nullable TTNetworkJSONFinishBlockWithResponse)callback
                      callbackInMainThread:(BOOL)callbackInMainThread;

/**
 *当callbackInMainThread == NO时，即回调在子线程时，支持业务传入他们自己设置回调线程优先级的callbackQueue
 *AF not implemented,return nil
 */
- (nullable TTHttpTask *)requestForJSONWithResponse:(NSString *)URL
                                    params:(id _Nullable)params
                                    method:(NSString *)method
                          needCommonParams:(BOOL)commonParams
                               headerField:(nullable NSDictionary *)headerField
                         requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                        responseSerializer:(nullable Class<TTJSONResponseSerializerProtocol>)responseSerializer
                                autoResume:(BOOL)autoResume
                             verifyRequest:(BOOL)verifyRequest
                        isCustomizedCookie:(BOOL)isCustomizedCookie
                                  callback:(nullable TTNetworkJSONFinishBlockWithResponse)callback
                             callbackQueue:(dispatch_queue_t)callbackQueue;


#pragma mark -- Binary Model
#pragma mark -- Binary Model Request Use URL

/**
 *  通过URL和参数请求
 *
 *  @param URL                请求的URL
 *  @param params             请求的参数
 *  @param method             请求的方法
 *  @param commonParams       是否需要通用参数
 *  @param callback           请求的返回值
 *
 *  @return TTHttpTask
 */
- (nullable TTHttpTask *)requestForBinaryWithURL:(NSString *)URL
                                       params:(id _Nullable)params
                                       method:(NSString *)method
                             needCommonParams:(BOOL)commonParams
                                     callback:(nullable TTNetworkObjectFinishBlock)callback;



- (nullable TTHttpTask *)requestForBinaryWithResponse:(NSString *)URL
                                 params:(id _Nullable)params
                                 method:(NSString *)method
                       needCommonParams:(BOOL)commonParams
                               callback:(nullable TTNetworkObjectFinishBlockWithResponse)callback;

//NOTE: progress will never be called, since AF has no API to support download binary with progress callback
- (nullable TTHttpTask *)requestForBinaryWithResponse:(NSString *)URL
                                      params:(id _Nullable)params
                                      method:(NSString *)method
                            needCommonParams:(BOOL)commonParams
                                 headerField:(nullable NSDictionary *)headerField
                             enableHttpCache:(BOOL)enableHttpCache
                           requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                          responseSerializer:(nullable Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                    progress:(NSProgress * _Nullable __autoreleasing * _Nullable)progress
                                    callback:(nullable TTNetworkObjectFinishBlockWithResponse)callback;

/**
 *  二进制数据请求， 回调里面有Response
 *
 *  @param URL                请求的URL
 *  @param params             请求的参数
 *  @param method             请求的方法
 *  @param needCommonParams   是否需要通用参数
 *  @param headerField        自定义header
 *  @param enableHttpCache    是否开启http cache
 *  @param autoResume         是否自动开始
 *  @param isCustomizedCookie 是否要使用自定义的cookie, 如果是No，则会默认携带系统cookie
 *  @param requestSerializer  请求的序列化对象, 如果传nil，用默认值
 *  @param responseSerializer 返回的序列化对象, 如果传nil，用默认值
 *  @param progress           进度回调
 *  @param callback           请求返回回调
 *  @param callbackInMainThread YES在主线程回调（不建议设置为YES），AF里该参数不起作用
 *
 *  @return TTHttpTask
 */

// NOTE: callbackInMainThread and isCustomizedCookie is not used in AF
- (nullable TTHttpTask *)requestForBinaryWithResponse:(NSString *)URL
                                      params:(id _Nullable)params
                                      method:(NSString *)method
                            needCommonParams:(BOOL)needCommonParams
                                 headerField:(nullable NSDictionary *)headerField
                             enableHttpCache:(BOOL)enableHttpCache
                                  autoResume:(BOOL)autoResume
                          isCustomizedCookie:(BOOL)isCustomizedCookie
                           requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                          responseSerializer:(nullable Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                    progress:(NSProgress * _Nullable __autoreleasing * _Nullable)progress
                                    callback:(nullable TTNetworkObjectFinishBlockWithResponse)callback
                        callbackInMainThread:(BOOL)callbackInMainThread;

// NOTE: callbackInMainThread is not used in AF
- (nullable TTHttpTask *)requestForBinaryWithResponse:(NSString *)URL
                                      params:(id _Nullable)params
                                      method:(NSString *)method
                            needCommonParams:(BOOL)needCommonParams
                                 headerField:(nullable NSDictionary *)headerField
                             enableHttpCache:(BOOL)enableHttpCache
                           requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                          responseSerializer:(nullable Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                    progress:(NSProgress * _Nullable __autoreleasing * _Nullable)progress
                                    callback:(nullable TTNetworkObjectFinishBlockWithResponse)callback
                        callbackInMainThread:(BOOL)callbackInMainThread;

// NOTE: callbackInMainThread is not used in AF
- (nullable TTHttpTask *)requestForBinaryWithResponse:(NSString *)URL
                                      params:(id _Nullable)params
                                      method:(NSString *)method
                            needCommonParams:(BOOL)needCommonParams
                                 headerField:(nullable NSDictionary *)headerField
                             enableHttpCache:(BOOL)enableHttpCache
                                  autoResume:(BOOL)autoResume
                           requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                          responseSerializer:(nullable Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                    progress:(NSProgress * _Nullable __autoreleasing * _Nullable)progress
                                    callback:(nullable TTNetworkObjectFinishBlockWithResponse)callback
                        callbackInMainThread:(BOOL)callbackInMainThread;

/**
 *当callbackInMainThread == NO时，即回调在子线程时，支持业务传入他们自己设置回调线程优先级的callbackQueue
 *AF not implemented,return nil
 */
- (nullable TTHttpTask *)requestForBinaryWithResponse:(NSString *)URL
                                      params:(id _Nullable)params
                                      method:(NSString *)method
                            needCommonParams:(BOOL)needCommonParams
                                 headerField:(nullable NSDictionary *)headerField
                             enableHttpCache:(BOOL)enableHttpCache
                                  autoResume:(BOOL)autoResume
                           requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                          responseSerializer:(nullable Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                    progress:(NSProgress * _Nullable __autoreleasing * _Nullable)progress
                                    callback:(nullable TTNetworkObjectFinishBlockWithResponse)callback
                               callbackQueue:(dispatch_queue_t)callbackQueue;


/**
 *  通过URL和参数请求
 *
 *  @param URL                请求的URL
 *  @param params             请求的参数
 *  @param method             请求的方法
 *  @param commonParams       是否需要通用参数
 *  @param requestSerializer  请求的序列化对象, 如果传nil，用默认值
 *  @param responseSerializer 返回的序列化对象, 如果传nil，用默认值
 *  @param autoResume         是否自动开始
 *  @param callback           请求的返回值
 *
 *  @return TTHttpTask
 */
- (nullable TTHttpTask *)requestForBinaryWithURL:(NSString *)URL
                                       params:(id _Nullable)params
                                       method:(NSString *)method
                             needCommonParams:(BOOL)commonParams
                            requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                           responseSerializer:(nullable Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                   autoResume:(BOOL)autoResume
                                     callback:(nullable TTNetworkObjectFinishBlock)callback;


/**
 *  通过URL和参数请求， 回调里面有Response
 *
 *  @param URL                请求的URL
 *  @param params             请求的参数
 *  @param method             请求的方法
 *  @param commonParams       是否需要通用参数
 *  @param requestSerializer  请求的序列化对象, 如果传nil，用默认值
 *  @param responseSerializer 返回的序列化对象, 如果传nil，用默认值
 *  @param autoResume         是否自动开始
 *  @param callback           请求的返回值
 *
 *  @return TTHttpTask
 */
- (nullable TTHttpTask *)requestForBinaryWithResponse:(NSString *)URL
                                      params:(id _Nullable)params
                                      method:(NSString *)method
                            needCommonParams:(BOOL)commonParams
                           requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                          responseSerializer:(nullable Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                  autoResume:(BOOL)autoResume
                                    callback:(nullable TTNetworkObjectFinishBlockWithResponse)callback;


/**
 *  通过URL和参数请求，数据会分块并及时通过回调返回 (AF not implemented,return nil)
 *
 *  @param URL                请求的URL
 *  @param params             请求的参数
 *  @param method             请求的方法
 *  @param commonParams       是否需要通用参数
 *  @param headerField        请求附加HTTP头部
 *  @param enableHttpCache    是否使用HTTPCache
 *  @param requestSerializer  请求的序列化对象, 如果传nil，用默认值
 *  @param responseSerializer 返回的序列化对象, 如果传nil，用默认值
 *  @param autoResume         是否自动开始
 *  @param headerCallback     获取响应头的回调
 *  @param dataCallback       获取响应体的回调
 *  @param callback           请求结束回调
 *
 *  @return TTHttpTask
 */
// AF not implemented,return nil
- (nullable TTHttpTask *)requestForChunkedBinaryWithURL:(NSString *)URL
                                        params:(id _Nullable)params
                                        method:(NSString *)method
                              needCommonParams:(BOOL)commonParams
                                   headerField:(nullable NSDictionary *)headerField
                               enableHttpCache:(BOOL)enableHttpCache
                             requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                            responseSerializer:(nullable Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                    autoResume:(BOOL)autoResume
                                headerCallback:(nullable TTNetworkChunkedDataHeaderBlock)headerCallback
                                  dataCallback:(nullable TTNetworkChunkedDataReadBlock)dataCallback
                                      callback:(nullable TTNetworkObjectFinishBlock)callback;

/**
 *  通过URL和参数请求，数据会分块并及时通过回调返回，请求结束回调包含Response (AF not implemented,return nil)
 *
 *  @param URL                   请求的URL
 *  @param params                请求的参数
 *  @param method                请求的方法
 *  @param commonParams          是否需要通用参数
 *  @param headerField           请求附加HTTP头部
 *  @param enableHttpCache       是否使用HTTPCache
 *  @param requestSerializer     请求的序列化对象, 如果传nil，用默认值
 *  @param responseSerializer    返回的序列化对象, 如果传nil，用默认值
 *  @param autoResume            是否自动开始
 *  @param isCustomizedCookie    是否要使用自定义的cookie, 如果是No，则会默认携带系统cookie
 *  @param headerCallback        获取响应头的回调
 *  @param dataCallback          获取响应体的回调
 *  @param callbackWithResponse  请求结束回调
 *  @param redirectCallback      请求重定向回调
 *
 *  @return TTHttpTask
 */
// AF not implemented,return nil
- (nullable TTHttpTask *)requestForChunkedBinaryWithResponse:(NSString *)URL
                                             params:(id _Nullable)params
                                             method:(NSString *)method
                                   needCommonParams:(BOOL)commonParams
                                        headerField:(nullable NSDictionary *)headerField
                                    enableHttpCache:(BOOL)enableHttpCache
                                  requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                                 responseSerializer:(nullable Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                         autoResume:(BOOL)autoResume
                                 isCustomizedCookie:(BOOL)isCustomizedCookie
                                     headerCallback:(nullable TTNetworkChunkedDataHeaderBlock)headerCallback
                                       dataCallback:(nullable TTNetworkChunkedDataReadBlock)dataCallback
                               callbackWithResponse:(nullable TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                                   redirectCallback:(nullable TTNetworkURLRedirectBlock)redirectCallback;

// AF not implemented,return nil
- (nullable TTHttpTask *)requestForChunkedBinaryWithResponse:(NSString *)URL
                                             params:(id _Nullable)params
                                             method:(NSString *)method
                                   needCommonParams:(BOOL)commonParams
                                        headerField:(nullable NSDictionary *)headerField
                                    enableHttpCache:(BOOL)enableHttpCache
                                  requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                                 responseSerializer:(nullable Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                        autoResume:(BOOL)autoResume
                                     headerCallback:(nullable TTNetworkChunkedDataHeaderBlock)headerCallback
                                       dataCallback:(nullable TTNetworkChunkedDataReadBlock)dataCallback
                               callbackWithResponse:(nullable TTNetworkObjectFinishBlockWithResponse)callbackWithResponse;

// AF not implemented,return nil
- (nullable TTHttpTask *)requestForChunkedBinaryWithResponse:(NSString *)URL
                                             params:(id _Nullable)params
                                             method:(NSString *)method
                                   needCommonParams:(BOOL)commonParams
                                        headerField:(nullable NSDictionary *)headerField
                                    enableHttpCache:(BOOL)enableHttpCache
                                  requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                                 responseSerializer:(nullable Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                         autoResume:(BOOL)autoResume
                                     headerCallback:(nullable TTNetworkChunkedDataHeaderBlock)headerCallback
                                       dataCallback:(nullable TTNetworkChunkedDataReadBlock)dataCallback
                               callbackWithResponse:(nullable TTNetworkObjectFinishBlockWithResponse)callbackWithResponse redirectCallback:(nullable TTNetworkURLRedirectBlock)redirectCallback;

// AF not implemented,return nil
- (nullable TTHttpTask *)requestForWebview:(NSURLRequest *)request
                  enableHttpCache:(BOOL)enableHttpCache
                   headerCallback:(nullable TTNetworkChunkedDataHeaderBlock)headerCallback
                     dataCallback:(nullable TTNetworkChunkedDataReadBlock)dataCallback
             callbackWithResponse:(nullable TTNetworkObjectFinishBlockWithResponse)callbackWithResponse;

// AF not implemented,return nil
- (nullable TTHttpTask *)requestForWebview:(NSURLRequest *)request
                       autoResume:(BOOL)autoResume
                  enableHttpCache:(BOOL)enableHttpCache
                   headerCallback:(nullable TTNetworkChunkedDataHeaderBlock)headerCallback
                     dataCallback:(nullable TTNetworkChunkedDataReadBlock)dataCallback
             callbackWithResponse:(nullable TTNetworkObjectFinishBlockWithResponse)callbackWithResponse;

// AF not implemented,return nil
- (nullable TTHttpTask *)requestForWebview:(NSURLRequest *)request
                       autoResume:(BOOL)autoResume
                  enableHttpCache:(BOOL)enableHttpCache
                   headerCallback:(nullable TTNetworkChunkedDataHeaderBlock)headerCallback
                     dataCallback:(nullable TTNetworkChunkedDataReadBlock)dataCallback
             callbackWithResponse:(nullable TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                 redirectCallback:(nullable TTNetworkURLRedirectBlock)redirectCallback;

- (TTHttpTask *)requestForWebview:(NSURLRequest *)request
                       mainDocURL:(NSString *)mainDocURL
                       autoResume:(BOOL)autoResume
                  enableHttpCache:(BOOL)enableHttpCache
                   headerCallback:(nullable TTNetworkChunkedDataHeaderBlock)headerCallback
                     dataCallback:(nullable TTNetworkChunkedDataReadBlock)dataCallback
             callbackWithResponse:(nullable TTNetworkObjectFinishBlockWithResponse)callbackWithResponse
                 redirectCallback:(nullable TTNetworkURLRedirectBlock)redirectCallback;

/**
 *  上传Data
 */


/**
*  上传数据
*
*  @param URLString        上传URL
*  @param parameters       参数
*  @param bodyBlock        multipart/form-data body体
*  @param progress         进度
*  @param needCommonParams 是否需要通用参数
*  @param callback         回调
*
*  @return TTHttpTask
*/
- (nullable TTHttpTask *)uploadWithURL:(NSString *)URLString
                               parameters:(id _Nullable)parameters
                constructingBodyWithBlock:(nullable TTConstructingBodyBlock)bodyBlock
                                 progress:(NSProgress * _Nullable __autoreleasing * _Nullable)progress
                         needcommonParams:(BOOL)needCommonParams
                                 callback:(nullable TTNetworkJSONFinishBlock)callback;

/**
 *  上传数据
 *
 *  @param URLString        上传URL
 *  @param parameters       参数
 *  @param headerField      HTTP 请求头部
 *  @param bodyBlock        multipart/form-data body体
 *  @param progress         进度
 *  @param needCommonParams 是否需要通用参数
 *  @param callback         回调
 *
 *  @return TTHttpTask
 */
- (nullable TTHttpTask *)uploadWithURL:(NSString *)URLString
                              headerField:(nullable NSDictionary *)headerField
                               parameters:(id _Nullable)parameters
                constructingBodyWithBlock:(nullable TTConstructingBodyBlock)bodyBlock
                                 progress:(NSProgress * _Nullable __autoreleasing * _Nullable)progress
                         needcommonParams:(BOOL)needCommonParams
                                 callback:(nullable TTNetworkJSONFinishBlock)callback;

/**
 *  上传数据
 *
 *  @param URLString          上传URL
 *  @param parameters         参数
 *  @param headerField        HTTP 请求头部
 *  @param bodyBlock          multipart/form-data body体
 *  @param progress           进度
 *  @param needCommonParams   是否需要通用参数
 *  @param requestSerializer  自定义请求序列化对象, 如果传nil，用默认值
 *  @param responseSerializer 自定义返回的序列化对象, 如果传nil，用默认值
 *  @param autoResume         是否自动开始
 *  @param callback           回调
 *
 *  @return TTHttpTask
 */
- (nullable TTHttpTask *)uploadWithURL:(NSString *)URLString
                               parameters:(id _Nullable)parameters
                              headerField:(nullable NSDictionary *)headerField
                constructingBodyWithBlock:(nullable TTConstructingBodyBlock)bodyBlock
                                 progress:(NSProgress * _Nullable __autoreleasing * _Nullable)progress
                         needcommonParams:(BOOL)needCommonParams
                        requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                       responseSerializer:(nullable Class<TTJSONResponseSerializerProtocol>)responseSerializer
                               autoResume:(BOOL)autoResume
                                 callback:(nullable TTNetworkJSONFinishBlock)callback;


/**
 *  上传数据，BINARY responseSerializer， callback 有response
 *
 *  @param URLString          上传URL
 *  @param parameters         参数
 *  @param headerField        HTTP 请求头部
 *  @param bodyBlock          multipart/form-data body体
 *  @param progress           进度
 *  @param needCommonParams   是否需要通用参数
 *  @param requestSerializer  自定义请求序列化对象, 如果传nil，用默认值
 *  @param responseSerializer 自定义返回的序列化对象, 如果传nil，用默认值
 *  @param autoResume         是否自动开始
 *  @param callback           回调
 *
 *  @return TTHttpTask
 */
- (nullable TTHttpTask *)uploadWithResponse:(NSString *)URLString
                        parameters:(id _Nullable)parameters
                       headerField:(nullable NSDictionary *)headerField
         constructingBodyWithBlock:(nullable TTConstructingBodyBlock)bodyBlock
                          progress:(NSProgress * _Nullable __autoreleasing * _Nullable)progress
                  needcommonParams:(BOOL)needCommonParams
                 requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                responseSerializer:(nullable Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                        autoResume:(BOOL)autoResume
                          callback:(nullable TTNetworkObjectFinishBlockWithResponse)callback;

/**
 *  上传数据，BINARY responseSerializer， callback 有response
 *
 *  @param URLString          上传URL
 *  @param parameters         参数
 *  @param headerField        HTTP 请求头部
 *  @param bodyBlock          multipart/form-data body体
 *  @param progress           进度
 *  @param needCommonParams   是否需要通用参数
 *  @param requestSerializer  自定义请求序列化对象, 如果传nil，用默认值
 *  @param responseSerializer 自定义返回的序列化对象, 如果传nil，用默认值
 *  @param autoResume         是否自动开始
 *  @param callback           回调
 *  @param timeout            timeout interval in seconds, default is 30 seconds (not support timeout in AF)
 *
 *  @return TTHttpTask
 */
- (nullable TTHttpTask *)uploadWithResponse:(NSString *)URLString
                        parameters:(id _Nullable)parameters
                       headerField:(nullable NSDictionary *)headerField
         constructingBodyWithBlock:(nullable TTConstructingBodyBlock)bodyBlock
                          progress:(NSProgress * _Nullable __autoreleasing * _Nullable)progress
                  needcommonParams:(BOOL)needCommonParams
                 requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                responseSerializer:(nullable Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                        autoResume:(BOOL)autoResume
                          callback:(nullable TTNetworkObjectFinishBlockWithResponse)callback
                           timeout:(NSTimeInterval)timeout;

/**
 *  上传无格式数据，BINARY responseSerializer， callback 有response
 *
 *  @param URLString          上传URL
 *  @param method             HTTP 方法: POST或PUT
 *  @param headerField        HTTP 请求头部
 *  @param bodyField          HTTP 请求体，无格式处理
 *  @param progress           进度
 *  @param requestSerializer  自定义请求序列化对象, 如果传nil，用默认值
 *  @param responseSerializer 自定义返回的序列化对象, 如果传nil，用默认值
 *  @param autoResume         是否自动开始
 *  @param callback           回调
 *  @param timeout            timeout interval in seconds, default is 30 seconds (not support timeout in AF)
 *
 *  @return TTHttpTask
 */
- (nullable TTHttpTask *)uploadRawDataWithResponse:(NSString *)URLString
                                   method:(NSString *)method
                              headerField:(nullable NSDictionary *)headerField
                                bodyField:(NSData *)bodyField
                                 progress:(NSProgress * _Nullable __autoreleasing * _Nullable)progress
                        requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                       responseSerializer:(nullable Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                               autoResume:(BOOL)autoResume
                                 callback:(nullable TTNetworkObjectFinishBlockWithResponse)callback
                                  timeout:(NSTimeInterval)timeout;

- (nullable TTHttpTask *)uploadRawDataWithResponse:(NSString *)URLString
                                            method:(NSString *)method
                                       headerField:(nullable NSDictionary *)headerField
                                         bodyField:(NSData *)bodyField
                                          progress:(NSProgress * _Nullable __autoreleasing * _Nullable)progress
                                 requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                                responseSerializer:(nullable Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                        autoResume:(BOOL)autoResume
                                          callback:(nullable TTNetworkObjectFinishBlockWithResponse)callback
                                           timeout:(NSTimeInterval)timeout
                                     callbackQueue:(dispatch_queue_t)callbackQueue;

/**
 *  上传文件数据，无格式，BINARY responseSerializer， callback 有response
 *
 *  @param URLString          上传URL
 *  @param method             HTTP 方法: POST或PUT
 *  @param headerField        HTTP 请求头部
 *  @param filePath           上传文件路径
 *  @param progress           进度
 *  @param requestSerializer  自定义请求序列化对象, 如果传nil，用默认值
 *  @param responseSerializer 自定义返回的序列化对象, 如果传nil，用默认值
 *  @param autoResume         是否自动开始
 *  @param callback           回调
 *  @param timeout            timeout interval in seconds, default is 30 seconds (not support timeout in AF)
 *
 *  @return TTHttpTask
 */
- (nullable TTHttpTask *)uploadRawFileWithResponse:(NSString *)URLString
                                   method:(NSString *)method
                              headerField:(nullable NSDictionary *)headerField
                                 filePath:(NSString *)filePath
                                 progress:(NSProgress * _Nullable __autoreleasing * _Nullable)progress
                 requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                responseSerializer:(nullable Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                        autoResume:(BOOL)autoResume
                          callback:(nullable TTNetworkObjectFinishBlockWithResponse)callback
                           timeout:(NSTimeInterval)timeout;

/** support range based file upload, AFNetworking NOT implement
 * @param uploadFileOffset  the offset of uploading file, value  > 0 means upload from this offset of file; value <= 0 means upload from the begining of file
 * @param uploadFileLength  the length of this upload, value > 0 means upload that length of file from offset; value <= 0 means upload the whole file from offset to the end
 * other parameters are the same as uploadRawFileWithResponse
 */
- (nullable TTHttpTask *)uploadRawFileWithResponseByRange:(NSString *)URLString
                                          method:(NSString *)method
                                     headerField:(nullable NSDictionary *)headerField
                                        filePath:(NSString *)filePath
                                          offset:(uint64_t)uploadFileOffset
                                          length:(uint64_t)uploadFileLength
                                        progress:(NSProgress * _Nullable __autoreleasing * _Nullable)progress
                               requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                              responseSerializer:(nullable Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                      autoResume:(BOOL)autoResume
                                        callback:(nullable TTNetworkObjectFinishBlockWithResponse)callback
                                         timeout:(NSTimeInterval)timeout;


/**
 *  同步请求
 */

/**
*  以POST方式发起一个同步请求, request会使用gzip压缩
*
*  @param URL              URL
*  @param method           请求的方法
*  @param headerField      HTTP header 信息
*  @param params           POST body信息, 默认需要是一个可以转换为json的obj，如果需要上传非json格式的body，请调用带requestSerializer的接口，并且在requestSerializer实现body的封装
*  @param needCommonParams 是否添加通用参数
*  @needContentEncoding 默认传NO
*  @return 返回值
*/
- (nullable NSDictionary *)synchronizedRequstForURL:(NSString *)URL
                                    method:(NSString *)method
                               headerField:(nullable NSDictionary *)headerField
                             jsonObjParams:(id _Nullable)params
                          needCommonParams:(BOOL)needCommonParams;

- (nullable NSDictionary *)synchronizedRequstForURL:(NSString *)URL
                                    method:(NSString *)method
                               headerField:(nullable NSDictionary *)headerField
                             jsonObjParams:(id _Nullable)params
                          needCommonParams:(BOOL)needCommonParams
                              needResponse:(BOOL)needReponse;

- (nullable NSDictionary *)synchronizedRequstForURL:(NSString *)URL
                                    method:(NSString *)method
                               headerField:(nullable NSDictionary *)headerField
                             jsonObjParams:(id _Nullable)params
                          needCommonParams:(BOOL)needCommonParams
                              needResponse:(BOOL)needReponse
                               needEncrypt:(BOOL)needEncrypt;

- (nullable NSDictionary *)synchronizedRequstForURL:(NSString *)URL
                                    method:(NSString *)method
                               headerField:(nullable NSDictionary *)headerField
                             jsonObjParams:(id _Nullable)params
                          needCommonParams:(BOOL)needCommonParams
                              needResponse:(BOOL)needReponse
                               needEncrypt:(BOOL)needEncrypt
           needContentEncodingAfterEncrypt:(BOOL)needContentEncoding;

- (nullable NSDictionary *)synchronizedRequstForURL:(NSString *)URL
                                    method:(NSString *)method
                               headerField:(nullable NSDictionary *)headerField
                             jsonObjParams:(id _Nullable)params
                          needCommonParams:(BOOL)needCommonParams
                         requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)serializer
                              needResponse:(BOOL)needResponse
                               needEncrypt:(BOOL)needEncrypt
           needContentEncodingAfterEncrypt:(BOOL)needContentEncoding;


#pragma mark - Interface for media usage

/**
 *  媒体类资源获取简单接口，支持Range方式请求，响应数据会分块并及时通过回调返回 (AF 不支持，直接返回nil)
 *
 *  @param URL                                      请求的URL
 *  @param params                                   请求的参数
 *  @param method                                   请求的方法
 *  @param offset                                   请求的资源偏移量起点
 *  @param requestedLength                          请求的资源长度，<=0表示到资源结束
 *  @param commonParams                             是否需要通用参数
 *  @param headerField                              请求附加HTTP头部
 *  @param enableHttpCache                          是否使用HTTPCache
 *  @param requestSerializer                        请求的序列化对象, 如果传nil，用默认值
 *  @param responseSerializer                       返回的序列化对象, 如果传nil，用默认值
 *  @param autoResume                               是否自动开始
 *  @param onHeaderReceivedCallback                 获取响应头的回调
 *  @param onDataReadCallback                       获取响应体的回调
 *  @param onRequestFinishCallback                  请求结束回调
 *
 *  @return TTHttpTask
 */
- (nullable TTHttpTask *)requestForRangeMediaResource:(NSString *)URL
                                      params:(id _Nullable)params
                                      method:(NSString *)method
                                      offset:(NSInteger)offset
                             requestedLength:(NSInteger)requestedLength
                            needCommonParams:(BOOL)commonParams
                                 headerField:(nullable NSDictionary *)headerField
                             enableHttpCache:(BOOL)enableHttpCache
                           requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                          responseSerializer:(nullable Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                  autoResume:(BOOL)autoResume
                    onHeaderReceivedCallback:(nullable TTNetworkChunkedDataHeaderBlock)onHeaderReceivedCallback
                          onDataReadCallback:(nullable TTNetworkChunkedDataReadBlock)onDataReadCallback
                     onRequestFinishCallback:(nullable TTNetworkObjectFinishBlock)onRequestFinishCallback;

/**
 *  媒体类资源获取简单接口，支持Range方式请求，响应数据会分块并及时通过回调返回，请求结束回调包含Response (AF 不支持，直接返回nil)
 *
 *  @param URL                                      请求的URL
 *  @param params                                   请求的参数
 *  @param method                                   请求的方法
 *  @param offset                                   请求的资源偏移量起点
 *  @param requestedLength                          请求的资源长度，<=0表示到资源结束
 *  @param commonParams                             是否需要通用参数
 *  @param headerField                              请求附加HTTP头部
 *  @param enableHttpCache                          是否使用HTTPCache
 *  @param requestSerializer                        请求的序列化对象, 如果传nil，用默认值
 *  @param responseSerializer                       返回的序列化对象, 如果传nil，用默认值
 *  @param autoResume                               是否自动开始
 *  @param onHeaderReceivedCallback                 获取响应头的回调
 *  @param onDataReadCallback                       获取响应体的回调
 *  @param onRequestFinishCallback                  请求结束回调
 *
 *  @return TTHttpTask
 */
- (nullable TTHttpTask *)requestForRangeMediaResourceWithResponse:(NSString *)URL
                                                  params:(id _Nullable)params
                                                  method:(NSString *)method
                                                  offset:(NSInteger)offset
                                         requestedLength:(NSInteger)requestedLength
                                        needCommonParams:(BOOL)commonParams
                                             headerField:(nullable NSDictionary *)headerField
                                         enableHttpCache:(BOOL)enableHttpCache
                                       requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                                      responseSerializer:(nullable Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                                              autoResume:(BOOL)autoResume
                                onHeaderReceivedCallback:(nullable TTNetworkChunkedDataHeaderBlock)onHeaderReceivedCallback
                                      onDataReadCallback:(nullable TTNetworkChunkedDataReadBlock)onDataReadCallback
                                 onRequestFinishCallback:(nullable TTNetworkObjectFinishBlockWithResponse)onRequestFinishCallback;

#pragma mark - MISC

/**
 *  trigger a c++ route selection process. Now used by LCS push notificaton
 */

- (void)doRouteSelection;// AF not implemented


#pragma mark - Progress download a file API

/**
 *  download file, can get the download progress
 *
 *  @param URL              URL
 *  @param parameters       请求的参数
 *  @param headerField      HTTP header 信息
 *  @param needCommonParams 是否添加通用参数
 *  @param progress         progress
 *  @param destination      文件存储位置
 *  @param completionHandler  完成后回调
 *  @return TTHttpTask
 */

- (nullable TTHttpTask *)downloadTaskWithRequest:(NSString *)URL
                             parameters:(id _Nullable)parameters
                            headerField:(nullable NSDictionary *)headerField
                       needCommonParams:(BOOL)needCommonParams
                               progress:(NSProgress * _Nullable __autoreleasing * _Nullable)progress
                            destination:(NSURL *)destination
                      completionHandler:(nullable DownloadCompletionHandler)completionHandler;

- (nullable TTHttpTask *)downloadTaskWithRequest:(NSString *)URL
                             parameters:(id _Nullable)parameters
                            headerField:(nullable NSDictionary *)headerField
                       needCommonParams:(BOOL)needCommonParams
                               progress:(NSProgress * _Nullable __autoreleasing * _Nullable)progress
                            destination:(NSURL *)destination
                             autoResume:(BOOL)autoResume
                      completionHandler:(nullable DownloadCompletionHandler)completionHandler;

// can specify request serializer
- (nullable TTHttpTask *)downloadTaskWithRequest:(NSString *)URL
                             parameters:(id _Nullable)parameters
                            headerField:(nullable NSDictionary *)headerField
                       needCommonParams:(BOOL)needCommonParams
                      requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                               progress:(NSProgress * _Nullable __autoreleasing * _Nullable)progress
                            destination:(NSURL *)destination
                             autoResume:(BOOL)autoResume
                      completionHandler:(nullable DownloadCompletionHandler)completionHandler;

/**
 * 用于游戏业务下载大文件，分片下载，实时显示进度
 */
- (nullable TTHttpTask *)downloadTaskBySlice:(NSString *)URLString
                         parameters:(id _Nullable)parameters
                        headerField:(nullable NSDictionary *)headerField
                   needCommonParams:(BOOL)needCommonParams
                  requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                   progressCallback:(nullable ProgressCallbackBlock)progressCallback
                        destination:(NSURL *)destination
                         autoResume:(BOOL)autoResume
                  completionHandler:(nullable DownloadCompletionHandler)completionHandler;

/**
 *  通过URL和参数获取StreamTask，后续数据读取使用TTHttpTask readDataOfMinLength函数
 *  仅Cronet内核支持，AFNetwork内核调用该函数会抛出异常
 *
 *  @param URL                   请求的URL
 *  @param params                请求的参数
 *  @param method                请求的方法
 *  @param commonParams          是否需要通用参数
 *  @param headerField           请求附加HTTP头部
 *  @param enableHttpCache       是否使用HTTPCache
 *  @param autoResume            是否自动开始
 *  @param dispatch_queue        运行Task回调使用的dispatch_queue，注意多线程queue可能会导致回调乱序
 *
 *  @return TTHttpTask
 */
- (nullable TTHttpTask *)requestForBinaryWithStreamTask:(NSString *)URL
                                                 params:(id _Nullable)params
                                                 method:(NSString *)method
                                       needCommonParams:(BOOL)commonParams
                                            headerField:(nullable NSDictionary *)headerField
                                        enableHttpCache:(BOOL)enableHttpCache
                                             autoResume:(BOOL)autoResume
                                         dispatch_queue:(dispatch_queue_t)dispatch_queue;// AF not implemented

- (nullable TTHttpTask *)requestForBinaryWithStreamTask:(NSString *)URL
                                                 params:(id _Nullable)params
                              constructingBodyWithBlock:(nullable TTConstructingBodyBlock)bodyBlock
                                                 method:(NSString *)method
                                       needCommonParams:(BOOL)commonParams
                                            headerField:(nullable NSDictionary *)headerField
                                        enableHttpCache:(BOOL)enableHttpCache
                                             autoResume:(BOOL)autoResume
                                         dispatch_queue:(dispatch_queue_t)dispatch_queue;

- (nullable TTHttpTask *)requestForBinaryWithStreamTask:(NSString *)URL
                                                 params:(id _Nullable)params
                              constructingBodyWithBlock:(nullable TTConstructingBodyBlock)bodyBlock
                                                 method:(NSString *)method
                                       needCommonParams:(BOOL)commonParams
                                      requestSerializer:(nullable Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                                            headerField:(nullable NSDictionary *)headerField
                                        enableHttpCache:(BOOL)enableHttpCache
                                             autoResume:(BOOL)autoResume
                                         dispatch_queue:(dispatch_queue_t)dispatch_queue;

- (void)clearHttpCache;// AF not implemented

- (int64_t)getHttpDiskCacheSize;// AF not implemented

- (void)setHttpDiskCacheSize:(int)size;// AF not implemented

/**
 *  Set a Chromium Network Quality Estimator observer to get RTT and Throughput information.
 */

- (void)setNetworkQualityObserverBlock:(GetNqeResultBlock)getNqeResultBlock;// AF not implemented

- (void)setPacketLossObserverBlock:(GetPacketLossResultBlock)block;// AF not implemented

+ (void)setNQEV2Block:(GetNqeResultBlock)nqeV2Block;
+ (GetNqeResultBlock)getNQEV2Block;

/**
 *  Change network Thread priority, default 0.5.
 *
 *  @param priority     network thread priority
 *  0    -> ThreadPriority::BACKGROUND
 *  0.5 -> ThreadPriority::NORMAL
 *  1    -> ThreadPriority::REALTIME_AUDIO
 */
- (void)changeNetworkThreadPriority:(double)priority;

- (void)tryStartNetDetect:(NSArray<NSString *> *)urls
                  timeout:(NSInteger)timeout
                  actions:(NSInteger)actions;// AF not implemented

- (nullable TTDnsResult*)ttDnsResolveWithHost:(NSString*)host
                               sdkId:(int)sdkId;// AF not implemented

- (BOOL)enableTTBizHttpDns:(BOOL)enable
                   domain:(NSString*)domain
                   authId:(NSString*)authId
                  authKey:(NSString*)authKey
                  tempKey:(BOOL)tempKey
         tempKeyTimestamp:(NSString*)tempKeyTimestamp;// AF not implemented

/**
 *  Get final url by URL-Dispatch module from TTNet.
 *  @param originalUrl The original url which need to be dispatched.
 *  @return The dispatch result accessed by URL-Dispatch module from TTNet.
 */
- (nullable TTDispatchResult*)ttUrlDispatchWithUrl:(NSString*)originalUrl; // AF not implemented

/**
 *  Preconnect one connection to be opened for url.
 *
 *  @param url The url of the connection to be opend.
 */
- (void)preconnectUrl:(NSString*)url; // AF not implemented

/**
 * Trigger get domain request for testing.
 */
- (void)triggerGetDomainForTesting; // AF not implemented

- (void)triggerGetDomain:(BOOL)useLatestParam; // AF not implemented

- (void)addClientOpaqueDataAfterInit:(TTClientCertificate*) cert;

- (void)clearClientOpaqueData;

- (void)removeClientOpaqueData:(NSString*)host;

- (void)notifySwitchToMultiNetwork:(BOOL)enable;

- (void)triggerSwitchingToCellular;

#pragma mark - get desensitized url for native webview request
- (NSString *)filterUrlWithCommonParams:(NSString *)originalUrl;

- (nullable NSDictionary *)removeL0CommonParams:(NSDictionary *)originalQueryMap;

#pragma mark - sync get dispatched url, common parameters and filter header according to origin url
/**
 *  get dispatched url
 *  append common parameters to the origin url if need
 *  return headers which added in filter block if need
 *  synchronize method
 *
 *  @param  nsRequest   由原始URL构成的请求对象
 *  @param  needCommonParams    是否将通参添加到原始URL中
 *  @param  needFilterHeaders  返回的TTHttpRequest对象中是否包含拦截器中添加的header
 */
- (TTHttpRequest *)syncGetDispatchedURL:(NSURLRequest *)nsRequest
                       needCommonParams:(BOOL)needCommonParams
                      needFilterHeaders:(BOOL)needFilterHeaders;

/**
 *  set zstd function address
 *
 *  @param createDCtxAddr    ZSTD_createDCtx Address
 *  @param decompressStreamAddr    ZSTD_decompressStream Address
 *  @param freeDctxAddr    ZSTD_freeDCtx Address
 *  @param isErrorAddr   ZSTD_isError Address
 *  @param createDDictAddr   ZSTD_createDDict  Address
 *  @param dctxRefDDictAddr   ZSTD_DCtx_refDDict Address
 *  @param freeDDictAddr   ZSTD_freeCDict Address
 *  @param dctxResetAddr   ZSTD_DCtx_reset Address
 */
- (void)setZstdFuncAddr:(void*)createDCtxAddr
   decompressStreamAddr:(void*)decompressStreamAddr
           freeDctxAddr:(void*)freeDctxAddr
            isErrorAddr:(void*)isErrorAddr
        createDDictAddr:(void*)createDDictAddr
       dctxRefDDictAddr:(void*)dctxRefDDictAddr
          freeDDictAddr:(void*)freeDDictAddr
          dctxResetAddr:(void*)dctxResetAddr;
@end
NS_ASSUME_NONNULL_END

