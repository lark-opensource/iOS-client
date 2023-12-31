// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestConfig.h"
#import "IESForestDefines.h"
#import "IESForestRequestParameters.h"
#import "IESForestFetcherProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol IESForestFetcherProtocol;
typedef NSInteger IESForestFetcherID;
@class IESForestRequest;
@class IESForestResponse;
@class IESForestPreloadConfig;

#pragma mark -- IESForestInterceptor
@protocol IESForestInterceptor <NSObject>
- (NSString *)interceptorName;

@optional
- (void)willFetchWithURL:(NSString *)url parameters:(IESForestRequestParameters *)parameters;
- (void)didCreateRequest:(IESForestRequest *)request;
- (void)didFetchWithRequest:(IESForestRequest *)request
                   response:(nullable id<IESForestResponseProtocol>)response
                      error:(nullable NSError *)error;
@end

#pragma mark -- IESForestEventMonitor
@protocol IESForestEventMonitor <NSObject>
- (void)monitorEvent:(NSString *)event
                data:(NSDictionary * _Nullable)data
               extra:(NSDictionary * _Nullable)extra;

@optional
- (void)customReport:(NSString * _Nonnull)eventName
                 url:(NSString * _Nonnull)url
                 bid:(NSString * _Nullable)bid
         containerId:(NSString * _Nullable)containerId
            category:(NSDictionary * _Nullable)category
             metrics:(NSDictionary * _Nullable)metrics
               extra:(NSDictionary * _Nullable)extra
         sampleLevel:(NSInteger)level;
@end

#pragma mark -- IESForestKit
@interface IESForestKit : NSObject

+ (instancetype)sharedInstance;

- (instancetype)initWithForestConfig:(IESForestConfig *)config;

+ (instancetype)forestWithBlock:(void(^)(IESMutableForestConfig *config)) block;

- (void)updateForestConfig:(IESForestConfig *)config;

/// forestConfig getter
@property (nonatomic, strong, readonly) IESForestConfig *forestConfig;

/// Please do NOT use this property!!!
@property (nonatomic, strong) id<IESForestEventMonitor> eventMonitor __attribute__((deprecated("Use class property instead!")));

/// event track monitor setter/getter
@property (class, nonatomic, strong) id<IESForestEventMonitor> _Nullable eventMonitor;

/// create IESForestRequest by URLString and RequestParameters
- (IESForestRequest *)createRequestWithURLString:(NSString *)url
                                      parameters:(nullable IESForestRequestParameters *)parameters;

/// Fetch resource ASYNC according to URLString, requestParameters
/// The workflow will iterate all the fetchers to fetch resource until one fetch resource successfully,
/// or all fetchers failed.
/// @param url  resource url
/// @param parameters  additional request paramters
/// @param completionHandler  completion callback
/// @result  RequestOperation, can be used to cancel a request
- (id<IESForestRequestOperation>)fetchResourceAsync:(NSString *)url
                                         parameters:(nullable IESForestRequestParameters *)parameters
                                         completion:(nullable IESForestCompletionHandler)completionHandler;

/// Fetch resource ASYNC according to URLString, requestParameters
/// The workflow will iterate all the fetchers to fetch resource until one fetch resource successfully,
/// or all fetchers failed.
/// @param url  resource url
/// @param parameters  additional request paramters
/// @result  IESForestResponse object, contains resource data and meta info
- (IESForestResponse *)fetchResourceSync:(NSString *)url
                              parameters:(nullable IESForestRequestParameters *)parameters;

- (IESForestResponse *)fetchResourceSync:(NSString *)url
                              parameters:(nullable IESForestRequestParameters *)parameters
                                   error:(NSError * _Nullable *)errorPtr;

// Similar to fetchResourceSync, but only fetch local resources
// it will use default local fetchers i.e. gecko, builtin
- (IESForestResponse *)fetchLocalResourceSync:(NSString *)url
                                   parameters:(nullable IESForestRequestParameters *)parameters;
/// The asme as the above one with default param
/// skip monitor if it is not gecko resource
- (IESForestResponse *)fetchLocalResourceSync:(NSString *)url;
/// The same as the above one, can pass skipMonitor parameter
- (IESForestResponse *)fetchLocalResourceSync:(NSString *)url skipMonitor:(BOOL)skipMonitor;

- (void)preload:(IESForestPreloadConfig *)config;
- (void)preload:(IESForestPreloadConfig *)config parameters:(nullable IESForestRequestParameters *)parameters;

/// clear memory cache for certain urls. If urls is nil, clear all caches
- (void)clearMemoryCacheFor:(nullable NSArray<NSString *> *)urls;

- (void)registerInterceptor:(id<IESForestInterceptor>)monitor;
- (void)unregisterInterceptor:(id<IESForestInterceptor>)monitor;

/// open session to lock channel not update or change
- (NSString *)openSession:(nullable NSString *)sessionId;
- (void)closeSession:(nullable NSString *)sessionId;

/// wheher url is gecko cdn url
+ (BOOL)isGeckoResource:(NSString *)url;

/// whether url can receive gecko resource, if not return nil
+ (nullable NSString *)geckoResourcePathForURLString:(NSString *)url;

+ (BOOL)isCDNMultiVersionResource:(NSString *)urlString;

+ (void)addDefaultCDNMultiVersionDomains:(NSArray<NSString *> *)domains;

+ (NSString *)addCommonParamsForCDNMultiVersionURLString:(NSString *)urlString;

/// register custom fetcher
+ (IESForestFetcherID)registerCustomFetcher:(Class<IESForestFetcherProtocol>)customFetcherClass;

/// update Memory cache in Byte
+ (void)updateMemoryCacheLimit:(NSInteger)cacheLimit;

/// update Preload Memory cache in Byte
+ (void)updatePreloadMemoryCacheLimit:(NSInteger)cacheLimit;

/// register global interceptor, it will affect all Forest instance.
/// It should only used in debug!!!
+ (void)registerGlobalInterceptor:(id<IESForestInterceptor>)interceptor;
+ (void)unregisterGlobalInterceptor:(id<IESForestInterceptor>)interceptor;

+ (NSDictionary *)cdnMultiVersionCommonParameters;
@end

NS_ASSUME_NONNULL_END
