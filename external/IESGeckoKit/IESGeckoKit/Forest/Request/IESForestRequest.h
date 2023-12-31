// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestRequestParameters.h"
#import "IESForestConfig.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -- IESGurdRequest

@interface IESForestPerformanceMetrics : NSObject <NSCopying>

@property (nonatomic, assign) double loadStart;
@property (nonatomic, assign) double loadFinish;
@property (nonatomic, assign) double parseStart;
@property (nonatomic, assign) double parseFinish;
@property (nonatomic, assign) double memoryStart;
@property (nonatomic, assign) double memoryFinish;
@property (nonatomic, assign) double geckoStart;
@property (nonatomic, assign) double geckoFinish;
@property (nonatomic, assign) double geckoUpdateStart;
@property (nonatomic, assign) double geckoUpdateFinish;
@property (nonatomic, assign) double cdnCacheStart;
@property (nonatomic, assign) double cdnCacheFinish;

@property (nonatomic, assign) double cdnStart;
@property (nonatomic, assign) double cdnFinish;
@property (nonatomic, assign) double builtinStart;
@property (nonatomic, assign) double builtinFinish;

@end

@interface NSString (iesForestRequest)
@property (nonatomic, assign) BOOL ies_forestEnableRequestReuse;
@end

@interface IESForestRequest : NSObject

@property (nonatomic, strong) IESForestConfig *forestConfig;
@property (nonatomic, strong) IESForestRequestParameters *requestParameters;

- (instancetype)initWithUrl:(NSString *)url
               forestConfig:(nullable IESForestConfig *)config
          requestParameters:(nullable IESForestRequestParameters *)requestParameters;

@property (nonatomic, assign) BOOL isSync;
@property (nonatomic, assign) BOOL runWorkflowInGlobalQueue;

@property (nonatomic, copy) NSString* url;
@property (nonatomic, copy) NSString* accessKey;
@property (nonatomic, copy) NSString* channel;
@property (nonatomic, copy) NSString* bundle;

@property (nonatomic, assign) BOOL disableGecko;
@property (nonatomic, assign) BOOL disableBuiltin;
@property (nonatomic, assign) BOOL disableCDN;
@property (nonatomic, assign) BOOL disableCDNCache;
@property (nonatomic, assign) BOOL enableMemoryCache;
@property (nonatomic, assign) BOOL waitGeckoUpdate;

@property (nonatomic, copy) NSArray<NSNumber *> *fetcherSequence;

@property (nonatomic, assign) BOOL onlyLocal;
@property (nonatomic, assign) BOOL onlyPath;
@property (nonatomic, assign) BOOL isPreload;
@property (nonatomic, assign) BOOL enableRequestReuse;
@property (nonatomic, strong) dispatch_queue_t completionQueue;
@property (nonatomic, strong) NSMutableDictionary *extraInfo;
@property (nonatomic, strong) NSString *sessionId;

- (NSString *)identity;
- (BOOL)hasValidGeckoInfo;
- (nullable NSString *)geckoConfigSource;

- (NSTimeInterval)memoryExpiredTime;
- (nullable NSArray<NSString *> *)shuffleDomains;
- (nullable NSNumber *)cdnRetryTimes;
- (IESForestResourceScene)resourceScene;
- (NSString *)resourceSceneDescription;
- (NSString *)groupId;
- (NSDictionary *)customParameters;
- (BOOL)skipMonitor;
/// The fetcher sequences that will be used to fetch resources
- (NSArray<NSNumber *> *)actualFetcherSequence;

// The following properties are use to record workflow info
/// the fetchers used to fetch resource
@property (nonatomic, copy) NSString *fetcherNames;
/// performance metrics
@property (nonatomic, strong) IESForestPerformanceMetrics *metrics;
// TODO: 需要优化
// error codes
@property (nonatomic, assign) NSInteger errorCode;
@property (nonatomic, assign) NSInteger ttNetErrorCode;
@property (nonatomic, assign) NSInteger httpStatusCode;
@property (nonatomic, assign) NSInteger geckoErrorCode;
@property (nonatomic, assign) NSInteger geckoSDKErrorCode;
// error messages
@property (nonatomic, copy) NSString *memoryError;
@property (nonatomic, copy) NSString *geckoError;
@property (nonatomic, copy) NSString *builtinError;
@property (nonatomic, copy) NSString *cdnError;
/// whether the response is from memory (include preload memory)
@property (nonatomic, assign) BOOL isFromMemory;
/// whether the response is from reused request
@property (nonatomic, assign) BOOL isRequestReused;
/// whether the response is from preload memory
@property (nonatomic, assign) BOOL isPreloaded;

@property (nonatomic, copy) NSString *debugInfo;

@end

NS_ASSUME_NONNULL_END
