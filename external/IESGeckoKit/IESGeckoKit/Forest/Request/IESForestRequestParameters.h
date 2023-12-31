// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, IESForestResourceScene) {
    IESForestResourceSceneOther,
    IESForestResourceSceneLynxTemplate,
    IESForestResourceSceneLynxChildResource,
    IESForestResourceSceneLynxComponent,
    IESForestResourceSceneLynxFont,
    IESForestResourceSceneLynxI18n,
    IESForestResourceSceneLynxImage,
    IESForestResourceSceneLynxLottie,
    IESForestResourceSceneLynxVideo,
    IESForestResourceSceneLynxSVG,
    IESForestResourceSceneLynxExternalJS,
    IESForestResourceSceneWebMainResource,
    IESForestResourceSceneWebChildResource,
};

@interface IESForestRequestParameters : NSObject <NSCopying>

/// disable certain fetcher, default value is NO
@property (nonatomic, strong) NSNumber *disableGecko;
@property (nonatomic, strong) NSNumber *disableBuiltin;
@property (nonatomic, strong) NSNumber *disableCDN;
@property (nonatomic, strong) NSNumber *disableCDNCache;

/// gecko related parameter
@property (nonatomic, copy) NSString *accessKey;
@property (nonatomic, copy) NSString *channel;
@property (nonatomic, copy) NSString *bundle;
@property (nonatomic, copy) NSString *resourceVersion;

/// This parameter is for gecko fetcher. If gecko local data exist, return the data and trigger lazy sync.
/// Otherwise, gecko fetcher will trigger normal sync.
/// If waitGeckoUpdate = NO, gecko fetcher will not wait for sync, thus fail
/// If waitGeckoUpdate = YES, gecko fetcher will wait for sync and return the synced data
@property (nonatomic, strong) NSNumber *waitGeckoUpdate;

/// only use local data - disable CDN and Gecko update
@property (nonatomic, strong) NSNumber *onlyLocal;

/// set default resource fetchers, default value is Gecko -> Builtin -> CDN
@property (nonatomic, copy, nullable) NSArray<NSNumber *> *fetcherSequence;

/// CDN retry times, defalut value is 0
@property (nonatomic, assign) NSInteger cdnRetryTimes;

/// check if local file exist, but will not read data, default value is NO
@property (nonatomic, strong) NSNumber *onlyPath;

/// enable memory cache, default value is NO
@property (nonatomic, strong) NSNumber *enableMemoryCache;

/// resource expired time for memory cache in seconds, default value is 300s
@property (nonatomic, strong) NSNumber *memoryExpiredTime;

/// open session with sessionID for lock channel
@property (nonatomic, strong) NSString *sessionId;
@property (nonatomic, strong) NSNumber *isPreload;
@property (nonatomic, strong) NSNumber *enableRequestReuse;
@property (nonatomic, strong) dispatch_queue_t completionQueue;

/// resource scene, only used for event track
@property (nonatomic, assign) IESForestResourceScene resourceScene;

/// whether load resource in globalQueue, default value is YES
@property (nonatomic, strong) NSNumber *runWorkflowInGlobalQueue;

/// use for event track and debug.
@property (nonatomic, strong) NSString *groupId;
@property (nonatomic, copy) NSDictionary *customParameters;

/// skip event track
@property (nonatomic, assign) BOOL skipMonitor;

@end

NS_ASSUME_NONNULL_END
