// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestKit.h"

#import "IESForestRemoteParameters.h"
#import "IESForestBaseFetcher.h"
#import "IESForestMemoryFetcher.h"
#import "IESForestBuiltinFetcher.h"
#import "IESForestCDNFetcher.h"
#import "IESForestCDNDownloaderFetcher.h"
#import "IESForestGeckoFetcher.h"
#import "IESForestWorkflow.h"
#import "IESForestEventTrackData.h"
#import "IESForestGeckoUtil.h"

#import "IESForestMemoryCacheManager.h"
#import "IESForestRequestOperationManager.h"
#import "IESForestRequest.h"
#import "IESForestPreloadConfig.h"
#import "IESForestImagePreloader.h"
#import "IESForestRequestOperation.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSSet+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/UIApplication+BTDAdditions.h>

#import <IESGeckoKit/IESGeckoKit.h>
#import <IESGeckoKit/IESGurdLogProxy.h>
#import <IESGeckoKit/IESGurdMonitorManager.h>
#import <IESGeckoKit/IESGurdKit+ResourceLoader.h>

#include <pthread/pthread.h>

static int kNextCustomFetcherId = 1000;
static pthread_mutex_t kCDNMultiVersionDomainsLock = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t kCDNMultiVersionCommonParamsLock = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t kInterceptorsLock = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t kCustomFetchersLock = PTHREAD_MUTEX_INITIALIZER;

static NSString * const kPerformanceEventName = @"res_loader_perf";
static NSString * const kErrorEventName = @"res_loader_error";
static NSString * const kTemplatePerformanceEventName = @"res_loader_perf_template";
static NSString * const kTemplateErrorEventName = @"res_loader_error_template";

// 9 means don't put current user into experimental group
static NSString * const kDefaultGeckoBucket = @"9";

#pragma mark-- IESForestKit

@interface IESForestKit ()
{
    IESForestConfig *_forestConfig;
}
@property (nonatomic, strong) IESForestRequestOperationManager* operationManager;
@property (nonatomic, strong) NSMutableArray<id<IESForestInterceptor>> *interceptors;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSMutableSet<NSString *> *> *> *sessionIDToChannelList;
@property (nonatomic, assign) BOOL isSharedInstance;
@property (nonatomic, strong) NSLock *operationLock;
@property (nonatomic, strong) IESForestConfig *forestConfig;

- (NSArray<id<IESForestInterceptor>> *)mergedInterceptors;

+ (NSMutableDictionary *)fetcherDictionary;
+ (NSMutableArray<id<IESForestInterceptor>> *)globalInterceptors;

@end

@implementation IESForestKit

+ (instancetype)sharedInstance
{
    static IESForestKit *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
        _sharedInstance.isSharedInstance = YES;
    });
    return _sharedInstance;
}

- (instancetype)initWithForestConfig:(IESForestConfig *)config
{
    if (self = [super init]) {
        self.operationManager = [[IESForestRequestOperationManager alloc] init];
        self.operationManager.forestKit = self;
        self.interceptors = [NSMutableArray new];
        _isSharedInstance = NO;
        self.forestConfig = [config copy];
        self.operationLock = [NSLock new];
        self.sessionIDToChannelList = [NSMutableDictionary new];
    }
    return self;
}

- (instancetype)init
{
    return [self initWithForestConfig:[[IESForestConfig alloc] init]];
}

+ (instancetype)forestWithBlock:(void(^)(IESMutableForestConfig *config)) block
{
    IESMutableForestConfig *config = [[IESMutableForestConfig alloc] init];
    block(config);
    return [[[self class] alloc] initWithForestConfig:config];
}

- (void)updateForestConfig:(IESForestConfig *)config
{
    IESMutableForestConfig *mutableConfig = [self.forestConfig mutableCopy];
    if (config.accessKey) {
        mutableConfig.accessKey = config.accessKey;
    }
    if (config.defaultPrefixToAccessKey) {
        mutableConfig.defaultPrefixToAccessKey = config.defaultPrefixToAccessKey;
    }
    if (config.disableGecko) {
        mutableConfig.disableGecko = config.disableGecko;
    }
    if (config.disableCDN) {
        mutableConfig.disableCDN = config.disableCDN;
    }
    if (config.waitGeckoUpdate) {
        mutableConfig.waitGeckoUpdate = config.waitGeckoUpdate;
    }
    if (config.enableMemoryCache) {
        mutableConfig.enableMemoryCache = config.enableMemoryCache;
    }
    
    if (config.fetcherSequence) {
        mutableConfig.fetcherSequence = config.fetcherSequence;
    }
    
    self.forestConfig = mutableConfig;
}

- (IESForestRequest *)createRequestWithURLString:(NSString *)url parameters:(IESForestRequestParameters *)parameters
{
    IESForestRequest *request = [[IESForestRequest alloc] initWithUrl:url forestConfig:self.forestConfig requestParameters:parameters];
//    IESGurdLogInfo(@"Forest - request: %@", request);

    for (id<IESForestInterceptor> interceptor in self.mergedInterceptors) {
        if ([interceptor respondsToSelector:@selector(didCreateRequest:)]) {
            [interceptor didCreateRequest:request];
        }
    }
//    IESGurdLogInfo(@"Forest - request after interceptors: %@", request);
    return request;
}

- (id<IESForestRequestOperation>)fetchResourceAsync:(NSString *)url
                                         parameters:(nullable IESForestRequestParameters *)parameters
                                         completion:(nullable IESForestCompletionHandler)completionHandler
{
    double startTime = [[NSDate date] timeIntervalSince1970] * 1000;
    for (id<IESForestInterceptor> interceptor in self.mergedInterceptors) {
        if ([interceptor respondsToSelector:@selector(willFetchWithURL:parameters:)]) {
            [interceptor willFetchWithURL:url parameters:parameters];
        }
    }
    double parseStart = [[NSDate date] timeIntervalSince1970] * 1000;
    IESForestRequest *request = [self createRequestWithURLString:url parameters:parameters];
    
    request.metrics.parseStart = parseStart;
    request.metrics.parseFinish = [[NSDate date] timeIntervalSince1970] * 1000;
    request.metrics.loadStart = startTime;

    return [self fetchResourceAsyncWithRequest:request completion:completionHandler];
}

- (IESForestRequestOperation *)fetchResourceAsyncWithRequest:(IESForestRequest *)request
                                                  completion:(nullable IESForestCompletionHandler)completionHandler
{
    __weak typeof(self) weak_self = self;

    [self.operationLock lock];
    IESForestRequestOperation *requestOperation = [self.operationManager operationWithRequest:request];
    __weak typeof(requestOperation) weak_operation = requestOperation;
    IESForestCompletionHandler wrapCompletionHandler = ^(IESForestResponse* response, NSError *error) {
        __strong typeof(weak_self) strong_self = weak_self;
        __strong typeof(weak_operation) strong_operation = weak_operation;
        IESForestResponse *copiedResponse = [response copy];
        copiedResponse.request = request;
        request.metrics.loadFinish = [[NSDate date] timeIntervalSince1970] * 1000;
        if (completionHandler) {
            if (request.isSync) {
                completionHandler(copiedResponse, error);
            } else {
                dispatch_queue_t completionQueue = request.completionQueue ?: dispatch_get_main_queue();
                if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(completionQueue)) == 0) {
                    completionHandler(copiedResponse, error);
                } else {
                    dispatch_async(completionQueue, ^{
                        completionHandler(copiedResponse, error);
                     });
                }
            }
        }
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [strong_self completeWithOperation:strong_operation response:copiedResponse error:error];
        });
    };

    [requestOperation appendCompletion:wrapCompletionHandler];
    [self.operationLock unlock];

    IESForestCompletionHandler operationHandler = ^(IESForestResponse* response, NSError *error) {
        __strong typeof(weak_self) strong_self = weak_self;
        __strong typeof(weak_operation) strong_operation = weak_operation;

        // cache response into memory when needed
        [[IESForestMemoryCacheManager sharedInstance] cacheResponse:response withRequest:request];

        [strong_self.operationLock lock];
        NSArray *completions = strong_operation.completions;
        [strong_self.operationManager removeOperation:strong_operation];
        [strong_self.operationLock unlock];

        [completions enumerateObjectsUsingBlock:^(IESForestCompletionHandler completion, NSUInteger idx, BOOL * _Nonnull stop) {
            completion(response, error);
        }];

    };

    [requestOperation.workflow fetchResourceWithCompletion:operationHandler];
    return requestOperation;
}

- (IESForestResponse *)fetchLocalResourceSync:(NSString *)url
                                   parameters:(IESForestRequestParameters *)parameters
{
    IESForestRequestParameters *params = [parameters copy];
    params.onlyPath = @(YES);
    params.onlyLocal = @(YES);
    return [self fetchResourceSync:url parameters:params];
}

- (IESForestResponse *)fetchLocalResourceSync:(NSString *)url
{
    IESForestRequestParameters *params = [IESForestRequestParameters new];
    params.skipMonitor = ![[self class] isGeckoResource:url];
    return [self fetchLocalResourceSync:url parameters:params];
}

- (IESForestResponse *)fetchLocalResourceSync:(NSString *)url skipMonitor:(BOOL)skipMonitor
{
    IESForestRequestParameters *params = [IESForestRequestParameters new];
    params.skipMonitor = skipMonitor;
    return [self fetchLocalResourceSync:url parameters:params];
}

- (IESForestResponse *)fetchResourceSync:(NSString *)url
                              parameters:(IESForestRequestParameters *)parameters
{
    return [self fetchResourceSync:url parameters:parameters error:nil];
}

- (IESForestResponse *)fetchResourceSync:(NSString *)url
                              parameters:(IESForestRequestParameters *)parameters
                                   error:(NSError * _Nullable *)errorPtr
{
    double startTime = [[NSDate date] timeIntervalSince1970] * 1000;
    for (id<IESForestInterceptor> interceptor in self.mergedInterceptors) {
        if ([interceptor respondsToSelector:@selector(willFetchWithURL:parameters:)]) {
            [interceptor willFetchWithURL:url parameters:parameters];
        }
    }

    double parseStart = [[NSDate date] timeIntervalSince1970] * 1000;
    IESForestRequest *request = [self createRequestWithURLString:url parameters:parameters];
    request.metrics.parseStart = parseStart;
    request.metrics.parseFinish = [[NSDate date] timeIntervalSince1970] * 1000;
    request.metrics.loadStart = startTime;

    request.isSync = YES;

    __block IESForestResponse* fetchResponse;
    __block NSError *fetchError;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    IESForestCompletionHandler syncHandler = ^(IESForestResponse* response, NSError *error) {
        fetchResponse = response;
        fetchError = error;
        dispatch_semaphore_signal(semaphore);
    };

    [self fetchResourceAsyncWithRequest:request completion:syncHandler];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    if (errorPtr) {
        *errorPtr = fetchError;
    }

    if (fetchResponse) {
        return fetchResponse;
    }
    return nil;
}

- (void)completeWithOperation:(IESForestRequestOperation *)operation
                     response:(nullable IESForestResponse *)response
                        error:(NSError *__nullable)error
{
    IESForestRequest *request = response.request;
    request.debugInfo = [operation.workflow debugInfo] ?: @"";
    IESGurdLogInfo(@"Forest - complete: url=%@, debugInfo=%@", request.url, request.debugInfo);
    request.fetcherNames = [operation.workflow fetcherNames];
    request.errorCode = error ? error.code : 0;
    if (request != operation.workflow.request) {
        // TODO: refactor
        request.ttNetErrorCode = operation.workflow.request.ttNetErrorCode;
        request.geckoErrorCode = operation.workflow.request.geckoErrorCode;
        request.geckoSDKErrorCode = operation.workflow.request.geckoSDKErrorCode;
        request.httpStatusCode = operation.workflow.request.httpStatusCode;

        request.builtinError = operation.workflow.request.builtinError;
        request.geckoError = operation.workflow.request.geckoError;
        request.cdnError = operation.workflow.request.cdnError;
        request.memoryError = operation.workflow.request.memoryError;
        IESForestPerformanceMetrics *metrics = [operation.workflow.request.metrics copy];
        metrics.loadStart = request.metrics.loadStart;
        request.metrics = metrics;
    }

    [self monitorEvent:response];
    // invoke interceptor
    for (id<IESForestInterceptor> interceptor in self.mergedInterceptors) {
        if ([interceptor respondsToSelector:@selector(didFetchWithRequest:response:error:)]) {
            [interceptor didFetchWithRequest:request response:response error:error];
        }
    }
}

#pragma mark - preload

- (void)preload:(IESForestPreloadConfig *)config
{
    [self preload:config parameters:nil];
}

- (void)preload:(IESForestPreloadConfig *)config parameters:(nullable IESForestRequestParameters *)parameters;
{
//    IESGurdLogInfo(@"Forest-preload start preload");
    [self preloadMainURL:config parameters:parameters];

    [self preloadImages:config parameters:parameters];

    [self preloadOtherResources:config parameters:parameters];
}

- (void)preloadMainURL:(IESForestPreloadConfig *)config parameters:(nullable IESForestRequestParameters *)parameters;
{
    if (!BTD_isEmptyString(config.mainUrl)) {
        IESForestRequestParameters *newParams = parameters ? [parameters copy] : [IESForestRequestParameters new];
        newParams.enableMemoryCache = @(YES);
        newParams.isPreload = @(YES);
        newParams.resourceScene = IESForestResourceSceneLynxTemplate;
        IESGurdLogInfo(@"Forest-preload start preload task: url:%@", config.mainUrl);
        [self fetchResourceAsync:config.mainUrl parameters:newParams completion:nil];
    }
}

- (void)preloadImages:(IESForestPreloadConfig *)config parameters:(nullable IESForestRequestParameters *)parameters
{
    for (IESForestPreloadSubResourceConfig* subResConfig in config.imageResources) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            IESGurdLogInfo(@"Forest-preload start preload task: url: %@", subResConfig.url);
            IESForestRequestParameters *newParams = parameters ? [parameters copy] : [IESForestRequestParameters new];
            newParams.isPreload = @(YES);
            IESForestResponse *response = [self fetchLocalResourceSync:subResConfig.url parameters:newParams];
            NSString *resolvedURL = response.resolvedURL;

            if (resolvedURL) {
                [IESForestImagePreloader preloadWithURLString:resolvedURL enableMemory:subResConfig.enableMemory];
                IESGurdLogInfo(@"Forest-preload finished for url: %@ with resolvedURL: %@", subResConfig.url, resolvedURL);
            } else {
                IESGurdLogInfo(@"Forest-preload failed for url: %@ ", subResConfig.url);
            }
        });
    }
}

- (void)preloadOtherResources:(IESForestPreloadConfig *)config parameters:(nullable IESForestRequestParameters *)parameters
{
    for (IESForestPreloadSubResourceConfig* subResConfig in config.otherResources) {
        IESGurdLogInfo(@"Forest-preload start preload task: url:%@", subResConfig.url);
        IESForestRequestParameters *newParams = parameters ? [parameters copy] : [IESForestRequestParameters new];
        newParams.enableMemoryCache = @(subResConfig.enableMemory);
        newParams.isPreload = @(YES);
        [self fetchResourceAsync:subResConfig.url parameters:newParams completion:nil];
    }
}

- (IESForestConfig *)forestConfig
{
    if (_forestConfig == nil) {
        _forestConfig = [IESForestConfig new];
    }
    return _forestConfig;
}

- (void)registerInterceptor:(id<IESForestInterceptor>)interceptor
{
    if (![interceptor conformsToProtocol:@protocol(IESForestInterceptor)]) {
        return;
    }
    
    if ([self.interceptors containsObject:interceptor]) {
        return;
    }

    pthread_mutex_lock(&kInterceptorsLock);
    [self.interceptors addObject:interceptor];
    pthread_mutex_unlock(&kInterceptorsLock);
}

- (void)unregisterInterceptor:(id<IESForestInterceptor>)interceptor
{
    pthread_mutex_lock(&kInterceptorsLock);
    [self.interceptors removeObject:interceptor];
    pthread_mutex_unlock(&kInterceptorsLock);
}

- (void)clearMemoryCacheFor:(nullable NSArray<NSString *> *)urls
{
    if (urls == nil) {
        [[IESForestMemoryCacheManager sharedInstance] clearCaches];
    } else {
        for (NSString *url in urls) {
            IESForestRequest *request = [[IESForestRequest alloc] initWithUrl:url forestConfig:nil requestParameters:nil];
            [[IESForestMemoryCacheManager sharedInstance] clearCacheForRequest:request];
        }
    }
}

- (NSString *)openSession:(nullable NSString *)sessionId
{
    if (!BTD_isEmptyString(sessionId)) {
        return sessionId;
    }
    return [NSUUID.UUID UUIDString];
}
 
- (void)closeSession:(nullable NSString *)sessionId
{
    if (BTD_isEmptyString(sessionId)) {
        return;
    }

    @synchronized(self.sessionIDToChannelList){
        NSMutableDictionary<NSString *, NSMutableSet<NSString *> *> *channelDict = [self.sessionIDToChannelList btd_objectForKey:sessionId default:[NSMutableDictionary new]];
        for (NSString *accesskey in channelDict.allKeys) {
            NSMutableSet<NSString *> *channelSet = [channelDict btd_objectForKey:accesskey default:[NSMutableSet new]];
            for (NSString *channel in channelSet) {
                [IESGurdKit unlockChannel:accesskey channel:channel];
                [IESForestGeckoUtil syncChannel:channel accessKey:accesskey];
            }
        }
        [self.sessionIDToChannelList removeObjectForKey:sessionId];
    }
}

- (BOOL)addChannelToChannelListWithSessionID:(NSString *)sessionId andAccessKey:(NSString *)accesskey andChannel:(NSString *)channel
{
    if (BTD_isEmptyString(sessionId) || BTD_isEmptyString(accesskey) || BTD_isEmptyString(channel)) {
        NSParameterAssert(sessionId.length > 0 && accesskey.length > 0 && channel.length > 0);
        return NO;
    }
    
    @synchronized(self.sessionIDToChannelList){
        NSMutableDictionary<NSString *, NSMutableSet<NSString *> *> *channelDict = [self.sessionIDToChannelList btd_objectForKey:sessionId default:[NSMutableDictionary new]];
        NSMutableSet<NSString *> *channelSet = [channelDict btd_objectForKey:accesskey default:[NSMutableSet new]];
        [channelSet btd_addObject:channel];
        [channelDict btd_setObject:channelSet forKey:accesskey];
        [self.sessionIDToChannelList btd_setObject:channelDict forKey:sessionId];
    }
    return YES;
}

- (BOOL)containsChannelInChannelListWithSessionID:(NSString *)sessionId andAccessKey:(NSString *)accesskey andChannel:(NSString *)channel
{
    if (BTD_isEmptyString(sessionId) || BTD_isEmptyString(accesskey) || BTD_isEmptyString(channel)) {
        NSParameterAssert(sessionId.length > 0 && accesskey.length > 0 && channel.length > 0);
        return NO;
    }
    
    @synchronized(self.sessionIDToChannelList){
        NSMutableDictionary<NSString *, NSMutableSet<NSString *> *> *channelDict = [self.sessionIDToChannelList btd_objectForKey:sessionId default:[NSMutableDictionary new]];
        NSMutableSet<NSString *> *channelSet = [channelDict btd_objectForKey:accesskey default:[NSMutableSet new]];
        return [channelSet containsObject:channel];
    }
}

+ (NSDictionary *)extractGeckoResourceInfo:(NSString *)url
{    
    NSDictionary *detail = [IESForestRemoteParameters extractGeckoInfoFormURL:url];
    if (detail == nil) {
        return nil;
    }
    
    NSString *prefix = [detail btd_stringValueForKey:@"prefix"];
    IESGurdSettingsResourceMeta *resourceMeta = [[IESGeckoKit settingsResponse] resourceMeta];
    NSString *accessKey = [resourceMeta.appConfig.prefixToAccessKeyDictionary btd_stringValueForKey:prefix];
    if (BTD_isEmptyString(accessKey)) {
        return nil;
    }
    
    NSMutableDictionary *resourceInfo = [NSMutableDictionary new];
    [resourceInfo setObject:accessKey forKey:@"accessKey"];
    [resourceInfo addEntriesFromDictionary:detail];
    return [resourceInfo copy];
}

+ (BOOL)isGeckoResource:(NSString *)url
{
    NSDictionary *resourceInfo = [self extractGeckoResourceInfo:url];
    if (!BTD_isEmptyDictionary(resourceInfo)) {
        return YES;
    }
    return NO;
}

+ (nullable NSString *)geckoResourcePathForURLString:(NSString *)url
{
    NSDictionary *resourceInfo = [self extractGeckoResourceInfo:url];
    if (BTD_isEmptyDictionary(resourceInfo)) {
        return nil;
    }
    
    NSString *directory = [IESGurdKit rootDirForAccessKey:resourceInfo[@"accessKey"] channel:resourceInfo[@"channel"]];
    NSString *path = [NSString stringWithFormat:@"%@/%@", directory, resourceInfo[@"bundle"]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        return path;
    }
    return nil;
}

+ (BOOL)isCDNMultiVersionResource:(NSString *)urlString
{
    NSURL* url = [NSURL URLWithString:urlString];
    NSString* domain = [url host];
    if (BTD_isEmptyString(domain)) {
        return NO;
    }
    return [[self cdnMultiVersionDomains] containsObject:domain];
}

+ (void)addDefaultCDNMultiVersionDomains:(NSArray<NSString *> *)domains
{
    if (![domains isKindOfClass:[NSArray class]]) {
        return;
    }

    pthread_mutex_lock(&kCDNMultiVersionDomainsLock);
    for (id domain in domains) {
        if (!BTD_isEmptyString(domain)) {
            [[self defalutCDNMultiVersionDomains] addObject:domain];
        }
    }
    pthread_mutex_unlock(&kCDNMultiVersionDomainsLock);
}

+ (IESForestFetcherID)registerCustomFetcher:(Class<IESForestFetcherProtocol>)customFetcherClass
{
    if ([customFetcherClass conformsToProtocol:@protocol(IESForestFetcherProtocol)]) {
        pthread_mutex_lock(&kCustomFetchersLock);
        int customFetcherId = kNextCustomFetcherId++;
        NSString *key = [NSString stringWithFormat:@"%d", customFetcherId];
        [self.fetcherDictionary btd_setObject:customFetcherClass forKey:key];
        pthread_mutex_unlock(&kCustomFetchersLock);
        return customFetcherId;
    }
    return -1;
}

+ (void)updateMemoryCacheLimit:(NSInteger)cacheLimit
{
    [IESForestMemoryCacheManager updateCacheLimit:cacheLimit];
}

+ (void)updatePreloadMemoryCacheLimit:(NSInteger)cacheLimit
{
    [IESForestMemoryCacheManager updatePreloadCacheLimit:cacheLimit];
}

+ (void)registerGlobalInterceptor:(id<IESForestInterceptor>)interceptor
{
    if (![interceptor conformsToProtocol:@protocol(IESForestInterceptor)]) {
        return;
    }
    
    if ([self.globalInterceptors containsObject:interceptor]) {
        return;
    }

    pthread_mutex_lock(&kInterceptorsLock);
    [self.globalInterceptors addObject:interceptor];
    pthread_mutex_unlock(&kInterceptorsLock);
}

+ (void)unregisterGlobalInterceptor:(id<IESForestInterceptor>)interceptor
{
    pthread_mutex_lock(&kInterceptorsLock);
    [self.globalInterceptors removeObject:interceptor];
    pthread_mutex_unlock(&kInterceptorsLock);
}

static id<IESForestEventMonitor> kIESForestEventMonitor = nil;
+ (id<IESForestEventMonitor>)eventMonitor
{
    return kIESForestEventMonitor;
}

+ (void)setEventMonitor:(id<IESForestEventMonitor>)eventMonitor
{
    kIESForestEventMonitor = eventMonitor;
}

+ (NSDictionary *)cdnMultiVersionCommonParameters
{
    static NSDictionary * params = nil;
    pthread_mutex_lock(&kCDNMultiVersionCommonParamsLock);
    if (params != nil) {
        pthread_mutex_unlock(&kCDNMultiVersionCommonParamsLock);
        return params;
    }
    pthread_mutex_unlock(&kCDNMultiVersionCommonParamsLock);

    if (IESGurdKit.appId || IESGurdKit.appVersion || IESGurdKit.deviceID) {
        return [self generateCdnMultiVersionCommonParams];
    }
    pthread_mutex_lock(&kCDNMultiVersionCommonParamsLock);
    params = [self generateCdnMultiVersionCommonParams];
    pthread_mutex_unlock(&kCDNMultiVersionCommonParamsLock);
    return params;
}

#pragma mark -- private

+ (NSString *)generateBucketWithDeviceID:(NSString *)deviceID
{
    if (BTD_isEmptyString(deviceID) || [deviceID integerValue] <= 0) {
        return kDefaultGeckoBucket;
    }

    NSInteger deviceIDSign = [deviceID integerValue] % 100;
    if (deviceIDSign == 0) {
        return @"s01";
    }
    if (deviceIDSign < 5) {
        return @"s05";
    }
    return [NSString stringWithFormat:@"%ld", (long)(deviceIDSign / 10)];
}

+ (NSDictionary *)generateCdnMultiVersionCommonParams {
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    [mutableParams setObject:[UIApplication btd_platformName] forKey:@"device_platform"];
    [mutableParams setObject:@"ios" forKey:@"os"];
    if (!BTD_isEmptyString(IESGurdKit.appId)) {
        [mutableParams setObject:IESGurdKit.appId forKey:@"app_id"];
    }
    if (!BTD_isEmptyString(IESGurdKit.appVersion)) {
        [mutableParams setObject:IESGurdKit.appVersion forKey:@"app_version"];
    }
    NSString *bucketValue = [self generateBucketWithDeviceID:IESGurdKit.deviceID];
    [mutableParams setObject:bucketValue forKey:@"gecko_bkt"];
    return [mutableParams copy];
}

- (void)monitorEvent:(IESForestResponse *)response
{
    if (response.request.skipMonitor) {
        return;
    }

    IESForestEventTrackData * eventTrackData = response.eventTrackData;

    if (response.request.isPreload) {
        [self reportPreloadTrackData:eventTrackData withRequest:response.request];
    } else {
        [self reportFullLinkTrackData:eventTrackData];
    }
    [self reportComponentTrackData:eventTrackData];
}

- (void)reportComponentTrackData:(IESForestEventTrackData *)eventTrackData
{
    NSMutableDictionary *category = [NSMutableDictionary dictionaryWithDictionary:eventTrackData.loaderInfo];
    [category addEntriesFromDictionary:eventTrackData.resourceInfo];
    [category addEntriesFromDictionary:eventTrackData.errorInfo];

    NSDictionary *extra = eventTrackData.extraInfo;
//    IESGurdLogInfo(@"IESGurd forest metrics: %@", eventTrackData.calculatedMetricInfo);
    NSString *eventName = eventTrackData.isTemplate ? kTemplatePerformanceEventName : kPerformanceEventName;
    [[IESGurdMonitorManager sharedManager] monitorEvent:eventName category:category metric:eventTrackData.calculatedMetricInfo extra:extra];

    if (!eventTrackData.isSuccess) {
        NSString *errorEventName = eventTrackData.isTemplate ? kTemplateErrorEventName : kErrorEventName;
        [[IESGurdMonitorManager sharedManager] monitorEvent:errorEventName category:category metric:nil extra:extra];
    }
}

- (void)reportPreloadTrackData:(IESForestEventTrackData *)eventTrackData withRequest:(IESForestRequest *)request {
    if ([[[self class] eventMonitor] respondsToSelector:@selector(customReport:url:bid:containerId:category:metrics:extra:sampleLevel:)]) {
        NSString *eventName = nil;
        if (eventTrackData.isTemplate) {
            eventName = eventTrackData.isSuccess ? kTemplatePerformanceEventName : kTemplateErrorEventName;
        } else {
            eventName = eventTrackData.isSuccess ? kPerformanceEventName : kErrorEventName;
        }

        NSMutableDictionary *category = [NSMutableDictionary dictionaryWithDictionary:eventTrackData.loaderInfo];
        [category addEntriesFromDictionary:eventTrackData.resourceInfo];
        [category addEntriesFromDictionary:eventTrackData.errorInfo];

        NSInteger sampleLevel = eventTrackData.isSuccess ? 1 : 0;
        [[[self class] eventMonitor] customReport:eventName
                                              url:request.url
                                              bid:nil
                                      containerId:request.groupId
                                         category:category
                                          metrics:eventTrackData.calculatedMetricInfo
                                            extra:nil
                                      sampleLevel:sampleLevel];
    }
}

- (void)reportFullLinkTrackData:(IESForestEventTrackData *)eventTrackData
{
    if ([[[self class] eventMonitor] respondsToSelector:@selector(monitorEvent:data:extra:)]) {
        NSDictionary *data = @{
            @"res_loader_info": eventTrackData.loaderInfo,
            @"res_info": eventTrackData.resourceInfo,
            @"res_load_perf": eventTrackData.metricInfo,
            @"res_load_error": eventTrackData.errorInfo,
        };

        NSString *eventName = eventTrackData.isTemplate ? kTemplatePerformanceEventName : kPerformanceEventName;
        [[[self class] eventMonitor] monitorEvent:eventName data:data extra:eventTrackData.extraInfo];

        if (!eventTrackData.isSuccess) {
            NSString *errorEventName = eventTrackData.isTemplate ? kTemplateErrorEventName : kErrorEventName;
            [[[self class] eventMonitor] monitorEvent:errorEventName data:data extra:eventTrackData.extraInfo];
        }
    }
}

+ (NSMutableDictionary *)fetcherDictionary
{
    static NSMutableDictionary *fetcherDictionary = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fetcherDictionary = [NSMutableDictionary dictionary];
        [fetcherDictionary btd_setObject:[IESForestMemoryFetcher class]
                                  forKey:[NSString stringWithFormat:@"%ld", (long)IESForestFetcherTypeMemory]];
        [fetcherDictionary btd_setObject:[IESForestGeckoFetcher class]
                                  forKey:[NSString stringWithFormat:@"%ld", (long)IESForestFetcherTypeGecko]];
        [fetcherDictionary btd_setObject:[IESForestBuiltinFetcher class]
                                  forKey:[NSString stringWithFormat:@"%ld", (long)IESForestFetcherTypeBuiltin]];
        [fetcherDictionary btd_setObject:[IESForestCDNFetcher class]
                                  forKey:[NSString stringWithFormat:@"%ld", (long)IESForestFetcherTypeCDN]];
        [fetcherDictionary btd_setObject:[IESForestCDNDownloaderFetcher class]
                                  forKey:[NSString stringWithFormat:@"%ld", (long)IESForestFetcherTypeCDNDownloader]];
    });
    return fetcherDictionary;
}

+ (NSMutableSet<NSString *> *)defalutCDNMultiVersionDomains
{
    static NSMutableSet *domains = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        domains = [[NSMutableSet alloc] init];
    });
    return domains;
}

+ (NSSet<NSString *> *)cdnMultiVersionDomains
{
    IESGurdSettingsResourceMeta *resourceMeta = [[IESGeckoKit settingsResponse] resourceMeta];
    NSArray *domainsArray = resourceMeta.appConfig.CDNMultiVersion.domainsArray;
    if (domainsArray.count > 0) {
        return [NSSet setWithArray:domainsArray];
    }
    pthread_mutex_lock(&kCDNMultiVersionDomainsLock);
    NSSet<NSString *> *defaultDomains = [self.defalutCDNMultiVersionDomains copy];
    pthread_mutex_unlock(&kCDNMultiVersionDomainsLock);
    return defaultDomains;
}

+ (NSMutableArray<id<IESForestInterceptor>> *)globalInterceptors
{
    static NSMutableArray *interceptors = nil;
    if (!interceptors) {
        interceptors = [[NSMutableArray alloc] init];
    }
    return interceptors;
}

- (NSArray<id<IESForestInterceptor>> *)mergedInterceptors
{
    pthread_mutex_lock(&kInterceptorsLock);
    NSMutableArray *monitors = [NSMutableArray arrayWithArray: [[self class] globalInterceptors]];
    [monitors addObjectsFromArray: self.interceptors];
    pthread_mutex_unlock(&kInterceptorsLock);
    return [monitors copy];
}

+ (NSString *)addCommonParamsForCDNMultiVersionURLString:(NSString *)urlString
{
    if (![self isCDNMultiVersionResource:urlString]) {
        return urlString;
    }

    NSURLComponents *componets = [[NSURLComponents alloc] initWithString:urlString];
    NSMutableArray *newQueryItems = [[componets queryItems] mutableCopy] ?: [NSMutableArray array];

    [[self cdnMultiVersionCommonParameters] enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSString* obj, BOOL * _Nonnull stop) {
        __block BOOL isExist = NO;
        [[componets queryItems] enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([item.name isEqualToString:key]) {
                isExist = YES;
                *stop = YES;
            }
        }];
        if (!isExist) {
            [newQueryItems addObject:[[NSURLQueryItem alloc] initWithName:key value:obj]];
        }
    }];
    [componets setQueryItems:newQueryItems];
    return [componets URL].absoluteString;
}

@end
