//
//  IESGeckoKit.m
//  IESGeckoKit
//
//  Created by willorfang on 2017/8/7.
//
//

#import "IESGeckoKit+Private.h"
#import "IESGurdKit+ByteSync.h"
#import "IESGurdKit+Experiment.h"
#import "IESGeckoDefines.h"
#import "IESGeckoDefines+Private.h"
#import "UIDevice+IESGeckoKit.h"

#import "IESGurdAppLogger.h"
#import "IESGurdLogProxy.h"
#import "IESGurdRegisterManager.h"
#import "IESGeckoCacheManager.h"
#import "IESGeckoResourceManager.h"
#import "IESGurdFileBusinessManager.h"
#import "IESGurdResourceMetadataStorage.h"
#import "IESGurdEventTraceManager+Message.h"
#import "IESGurdDelegateDispatcherManager.h"
#import "IESGurdPollingManager.h"
#import "IESGurdSettingsManager.h"
#import "IESGurdDiskUsageManager.h"
#import "IESGurdChannelUsageMananger.h"
#import "IESGurdMonitorManager.h"
#import "IESGurdExpiredCacheManager.h"
#import "IESGurdChannelBlocklistManager.h"
#import "IESGurdDownloadPackageManager.h"

#import "IESGurdFetchResourcesResult.h"

#import "IESGurdLazyResourcesManager.h"
#import "IESGurdPackagesExtraManager.h"

#import <Gaia/GAIAEngine.h>

#ifndef GECKO_SPEC_VERSION
#define GECKO_SPEC_VERSION  @"3.0.0"
#endif

NSString *IESGurdKitSDKVersion(void)
{
    static NSString *version = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        version = [GECKO_SPEC_VERSION stringByReplacingOccurrencesOfString:@".1.binary" withString:@""];
    });
    return version;
}

static BOOL kIESGurdKitDidSetup = NO;
static NSInteger kIESGurdSetupTimestamp = NSUIntegerMax;

#define CHECKIF_SDK_SETUP   \
NSAssert(kIESGurdKitDidSetup, @"IESGeckoKit hasn't setup, call +[IESGurdKit setupWithAppId:appVersion:cacheRootDirectory:]");    \
if (!kIESGurdKitDidSetup) { \
return;                 \
}                           \

@implementation IESGurdLowStorageData

@end

@implementation IESGurdKit

+ (instancetype)sharedInstance
{
    static IESGurdKit *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [IESGurdKit new];
        instance.lockChannels = [NSMutableDictionary dictionary];
        instance.lowStorageWhiteList = [NSMutableDictionary dictionary];
    });
    return instance;
}

#pragma mark - Class properties

+ (void)setEnv:(IESGurdEnvType)env
{
    IESGurdKitInstance.env = env;
}

+ (IESGurdEnvType)env
{
    return IESGurdKitInstance.env;
}

static BOOL kIESGurdKitEnable = YES;
+ (BOOL)enable
{
    return kIESGurdKitEnable;
}

+ (void)setEnable:(BOOL)enable
{
    IESGurdSettingsRequestMeta *requestMeta = [IESGurdSettingsManager sharedInstance].settingsResponse.requestMeta;
    if (requestMeta) {
        enable = enable && requestMeta.isRequestEnabled;
    }
    
    BOOL shouldPostNotification = (!kIESGurdKitEnable && enable);
    kIESGurdKitEnable = enable;
    if (shouldPostNotification) {
        [IESGurdEventTraceManager traceEventWithMessage:@"🎉 Gurd did enable." hasError:NO shouldLog:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:IESGurdKitDidSetEnableGurdNotification object:nil];
    }
}

+ (void)setDeviceID:(NSString *)deviceID
{
    if (!IES_isEmptyString(deviceID)) {
        IESGurdKitInstance.deviceID = deviceID;
    }
}

+ (NSString *)deviceID
{
    return IESGurdKitInstance.deviceID;
}

+ (NSString *)appId
{
    return IESGurdKitInstance.appId;
}

+ (NSString *)appVersion
{
    return IESGurdKitInstance.appVersion;
}

+ (NSString * _Nonnull (^)(void))getDeviceID
{
    return IESGurdKitInstance.getDeviceID;
}

+ (void)setGetDeviceID:(NSString * _Nonnull (^)(void))getDeviceID
{
    IESGurdKitInstance.getDeviceID = getDeviceID;
}

+ (void)setPlatformDomain:(NSString *)domain
{
    if (!IES_isEmptyString(domain)) {
        IESGurdKitInstance.domain = domain;
    }
}

+ (NSString *)platformDomain
{
    return IESGurdKitInstance.domain;
}

+ (BOOL)isLogEnabled
{
    return IESGurdEventTraceManager.isEnabled;
}

+ (void)setLogEnable:(BOOL)logEnable
{
    IESGurdEventTraceManager.enabled = logEnable;
}

+ (BOOL)isEventTraceEnabled
{
    return IESGurdEventTraceManager.isEnabled;
}

+ (void)setEventTraceEnabled:(BOOL)eventTraceEnabled
{
    IESGurdEventTraceManager.enabled = eventTraceEnabled;
}

+ (void)setNetworkDelegate:(id<IESGurdNetworkDelegate>)networkDelegate
{
    IESGurdKitInstance.networkDelegate = networkDelegate;
}

+ (id<IESGurdNetworkDelegate>)networkDelegate
{
    return IESGurdKitInstance.networkDelegate;
}

+ (void)setDownloaderDelegate:(id<IESGurdDownloaderDelegate>)downloaderDelegate
{
    IESGurdKitInstance.downloaderDelegate = downloaderDelegate;
}

+ (id<IESGurdDownloaderDelegate>)downloaderDelegate
{
    return IESGurdKitInstance.downloaderDelegate;
}

+ (void)setAppLogDelegate:(id<IESGurdAppLogDelegate>)appLogDelegate
{
    IESGurdAppLogger.appLogDelegate = appLogDelegate;
}

+ (id<IESGurdAppLogDelegate>)appLogDelegate
{
    return IESGurdAppLogger.appLogDelegate;
}

static NSMutableDictionary<NSString *, NSDictionary<NSString *, NSArray<NSString *> *> *> *kIESGurdKitPrefetchChannels = nil;
+ (NSDictionary<NSString *, NSDictionary<NSString *, NSArray<NSString *> *> *> *)prefetchChannels
{
    return [kIESGurdKitPrefetchChannels copy];
}

+ (void)setPrefetchChannels:(NSDictionary<NSString *, NSDictionary<NSString *, NSArray<NSString *> *> *> *)prefetchChannels
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kIESGurdKitPrefetchChannels = [NSMutableDictionary dictionary];
    });
    @synchronized (kIESGurdKitPrefetchChannels) {
        [kIESGurdKitPrefetchChannels addEntriesFromDictionary:prefetchChannels];
    }
}

#pragma mark - Config

+ (BOOL)didSetup
{
    return kIESGurdKitDidSetup;
}

+ (NSInteger)setupTimestamp
{
    return kIESGurdSetupTimestamp;
}

+ (void)setupWithAppId:(NSString * _Nonnull)appId
            appVersion:(NSString * _Nonnull)appVersion
    cacheRootDirectory:(NSString * _Nullable)cacheRootDirectory
{
    IESGurdKit *instance = IESGurdKitInstance;
    if (kIESGurdKitDidSetup) {
        NSAssert([appId isEqualToString:instance.appId], @"AppId will be overrided");
        NSAssert([appVersion isEqualToString:instance.appVersion], @"AppVersion will be overrided");
        if (cacheRootDirectory) {
            NSAssert([cacheRootDirectory isEqualToString:IESGurdCacheRootDirectoryPath.path],
                     @"CacheRootDirectory will be overrided");
        }
        return;
    }
    kIESGurdKitDidSetup = YES;
    kIESGurdSetupTimestamp = [[NSDate date] timeIntervalSince1970];
    
    NSParameterAssert(appId.length > 0);
    instance.appId = appId;
    
    NSParameterAssert(appVersion.length > 0);
    instance.appVersion = appVersion;
    
    IESGurdCacheRootDirectoryPath.path = cacheRootDirectory;
    
    [IESGurdFileBusinessManager setup];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:IESGurdKitDidSetupGurdNotification object:nil];
    
    [GAIAEngine startTasksForKey:@kIESGurdKitRegisterAccesskey];
}

+ (NSString *)cacheRootDir
{
    return IESGurdFilePaths.cacheRootDirectoryPath;
}

+ (void)registerEventDelegate:(id<IESGurdEventDelegate>)eventDelegate
{
    [[IESGurdDelegateDispatcherManager sharedManager] registerDelegate:eventDelegate
                                                           forProtocol:@protocol(IESGurdEventDelegate)];
}

+ (void)unregiserEventDelegate:(id<IESGurdEventDelegate>)eventDelegate
{
    [[IESGurdDelegateDispatcherManager sharedManager] unregisterDelegate:eventDelegate
                                                             forProtocol:@protocol(IESGurdEventDelegate)];
}

+ (void)registerAccessKey:(NSString *)accessKey
{
    [[IESGurdRegisterManager sharedManager] registerAccessKey:accessKey];
}

+ (void)registerAccessKey:(NSString *)accessKey SDKVersion:(NSString *)SDKVersion
{
    [[IESGurdRegisterManager sharedManager] registerAccessKey:accessKey SDKVersion:SDKVersion];
}

+ (void)addCustomParamsForAccessKey:(NSString *)accessKey
                       customParams:(NSDictionary * _Nullable)customParams
{
    [[IESGurdRegisterManager sharedManager] addCustomParamsForAccessKey:accessKey customParams:customParams];
}

+ (NSArray<IESGurdRegisterModel *> *)allRegisterModels
{
    return [[IESGurdRegisterManager sharedManager] allRegisterModels];
}

+ (void)setRequestHeaderFieldBlock:(NSDictionary<NSString *, NSString *> *(^)(void))block
{
    IESGurdKitInstance.requestHeaderFieldBlock = block;
}

+ (void)addGurdLogDelegate:(id<IESGurdLogProxyDelegate>)logDelegate
{
    IESGurdLogAddDelegate(logDelegate);
}

+ (void)removeGurdLogDelegate:(id<IESGurdLogProxyDelegate>)logDelegate
{
    IESGurdLogRemoveDelegate(logDelegate);
}

+ (void)fetchSettings
{
    if (!IESGurdKit.isSettingsEnable) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[IESGurdSettingsManager sharedInstance] fetchSettingsWithRequestType:IESGurdSettingsRequestTypeNormal];
    });
}

+ (void)cleanSettingsCache
{
    [[IESGurdSettingsManager sharedInstance] cleanCache];
}

+ (void)cleanBlacklistCache
{
    [[IESGurdChannelBlocklistManager sharedManager] cleanCache];
}

+ (void)lockChannel:(NSString *)accessKey channel:(NSString *)channel
{
    NSString *identity = [NSString stringWithFormat:@"%@_%@", accessKey, channel];
    NSMutableDictionary<NSString *, NSNumber*> *lockChannels = IESGurdKitInstance.lockChannels;
    @synchronized (lockChannels) {
        NSString *message = [NSString stringWithFormat:@"lock channel: %@", identity];
        [IESGurdEventTraceManager traceEventWithMessage:message hasError:NO shouldLog:YES];
        lockChannels[identity] = @([lockChannels[identity] intValue] + 1);
    }
}

+ (void)unlockChannel:(NSString *)accessKey channel:(NSString *)channel
{
    NSString *identity = [NSString stringWithFormat:@"%@_%@", accessKey, channel];
    NSMutableDictionary<NSString *, NSNumber*> *lockChannels = IESGurdKitInstance.lockChannels;
    @synchronized (lockChannels) {
        NSString *message = [NSString stringWithFormat:@"unlockChannel channel: %@", identity];
        [IESGurdEventTraceManager traceEventWithMessage:message hasError:NO shouldLog:YES];
        int count = [lockChannels[identity] intValue] - 1;
        lockChannels[identity] = @(MAX(count, 0));
    }
}

+ (BOOL)isChannelLocked:(NSString *)accessKey channel:(NSString *)channel
{
    NSString *identity = [NSString stringWithFormat:@"%@_%@", accessKey, channel];
    NSMutableDictionary<NSString *, NSNumber*> *lockChannels = IESGurdKitInstance.lockChannels;
    @synchronized (lockChannels) {
        return [lockChannels[identity] intValue] > 0;
    }
}

#pragma mark - Apply

+ (void)applyInactivePackages:(IESGurdSyncStatusBlock _Nullable)completion
{
    [IESGurdCacheManager applyAllInactiveCacheWithCompletion:completion];
}

+ (void)applyInactivePackageForAccessKey:(NSString *)accessKey
                                 channel:(NSString *)channel
                              completion:(IESGurdSyncStatusBlock _Nullable)completion
{
    [IESGurdCacheManager applyInactiveCacheForAccessKey:accessKey
                                                channel:channel
                                             completion:completion];
}

#pragma mark - Download

+ (void)downloadResourcesWithAccessKey:(NSString *)accessKey
                              channels:(NSArray<NSString *> *)channels
                            completion:(IESGurdSyncStatusDictionaryBlock _Nullable)completion
{
    NSAssert(NO, @"Use +[IESGurdKit syncResourcesWithAccessKey] instead");
}

+ (void)downloadResourcesWithParamsBlock:(IESGurdFetchResourcesParamsBlock)paramsBlock
                              completion:(IESGurdSyncStatusDictionaryBlock _Nullable)completion
{
    NSAssert(NO, @"Use +[IESGurdKit syncResourcesWithParamsBlock] instead");
}

#pragma mark - Sync Resource

+ (void)syncResourcesWithAccessKey:(NSString *)accessKey
                          channels:(NSArray<NSString *> * _Nullable)channels
                        completion:(IESGurdSyncStatusDictionaryBlock _Nullable)completion
{
    [self syncResourcesWithParamsBlock:^(IESGurdFetchResourcesParams * _Nonnull params) {
        params.accessKey = accessKey;
        params.channels = channels;
    } completion:completion];
}

+ (void)syncResourcesWithAccessKey:(NSString *)accessKey
                           channel:(NSString *)channel
                           version:(uint64_t)version
                        completion:(IESGurdSyncStatusDictionaryBlock _Nullable)completion
{
    if (channel.length == 0) {
        !completion ? : completion(NO, IESGurdMakePlaceHolder(IESGurdSyncStatusParameterInvalid));
        return;
    }
    [self syncResourcesWithParamsBlock:^(IESGurdFetchResourcesParams * _Nonnull params) {
        params.accessKey = accessKey;
        params.channels = @[ channel ];
        params.targetVersionsDictionary = @{ channel : @(version) };
    } completion:completion];
}

+ (void)syncResourcesWithParamsBlock:(IESGurdFetchResourcesParamsBlock)paramsBlock
                          completion:(IESGurdSyncStatusDictionaryBlock _Nullable)completion
{
    CHECKIF_SDK_SETUP
    
    if (!paramsBlock) {
        !completion ? : completion(NO, IESGurdMakePlaceHolder(IESGurdSyncStatusParameterInvalid));
        return;
    }
    
    IESGurdFetchResourcesParams *params = [[IESGurdFetchResourcesParams alloc] init];
    paramsBlock(params);
    
    if (![params isValid]) {
        NSAssert(NO, @"Sync resources params invalid");
        !completion ? : completion(NO, IESGurdMakePlaceHolder(IESGurdSyncStatusParameterInvalid));
        return;
    }
    
    NSString *accessKey = params.accessKey;
    if (![[IESGurdRegisterManager sharedManager] isAccessKeyRegistered:accessKey]) {
        NSAssert(NO, @"Access key must be registered.");
        !completion ? : completion(NO, IESGurdMakePlaceHolder(IESGurdSyncStatusParameterNotRegister));
        return;
    }
    
    if (params.pollingPriority > IESGurdPollingPriorityNone) {
        [IESGurdPollingManager addPollingConfigWithParams:params];
    }
    
    if (![self enable] && !params.forceRequest) {
        !completion ? : completion(NO, IESGurdMakePlaceHolder(IESGurdSyncStatusDisable));
        return;
    }
    
    [self applyInactivePackages:^(BOOL applySucceed, IESGurdSyncStatus applyStatus) {
        [IESGurdCacheManager syncResourcesWithParams:params completion:^(BOOL succeed, IESGurdSyncStatusDict dict) {
            [DELEGATE_DISPATCHER(IESGurdEventDelegate) gurdDidSyncResourceWithAccessKey:accessKey
                                                                                succeed:succeed
                                                                             statusDict:dict];
            !completion ? : completion(succeed, dict);
        }];
    }];
}

+ (void)loadResourceForAccessKey:(NSString *)accessKey
                         channel:(NSString *)channel
                            path:(NSString *)path
                      completion:(IESGurdLoadResourceCompletion)completion
{
    [self loadResourceWithParamsBlock:^(IESGurdLoadResourcesParams * _Nonnull params) {
        params.accessKey = accessKey;
        params.channel = channel;
        params.resourcePath = path;
    } completion:completion];
}

+ (void)loadResourceWithParamsBlock:(void (^)(IESGurdLoadResourcesParams *params))paramsBlock
                         completion:(IESGurdLoadResourceCompletion)completion
{
    CHECKIF_SDK_SETUP
    
    if (!paramsBlock) {
        !completion ? : completion(nil, IESGurdSyncStatusParameterInvalid);
        return;
    }
    
    IESGurdLoadResourcesParams *params = [[IESGurdLoadResourcesParams alloc] init];
    paramsBlock(params);
    
    NSString *accessKey = params.accessKey;
    NSString *channel = params.channel;
    NSString *path = params.resourcePath;
    if (accessKey.length == 0 || channel.length == 0 || path.length == 0) {
        !completion ? : completion(nil, IESGurdSyncStatusParameterInvalid);
        return;
    }
    
    [self asyncGetDataForPath:path accessKey:accessKey channel:channel completion:^(NSData * _Nullable data) {
        BOOL alwaysFetch = params.options & IESGurdLoadResourceOptionAlwaysFetch;
        if (data.length > 0 && !alwaysFetch) {
            !completion ? : completion(data, IESGurdSyncStatusServerPackageUnavailable);
            return;
        }
        
        BOOL forceRequest = params.options & IESGurdLoadResourceOptionForceRequest;
        if (![self enable] && !forceRequest) {
            !completion ? : completion(data, IESGurdSyncStatusDisable);
            return;
        }
        
        IESGurdFetchResourcesParams *fetchParams = [params toFetchParams];
        [IESGurdCacheManager syncResourcesWithParams:fetchParams completion:^(BOOL succeed, IESGurdSyncStatusDict dict) {
            if (!succeed) {
                IESGurdSyncStatus status = IESGurdStatusForChannel(dict, channel);
                !completion ? : completion(nil, status);
                return;
            }
            [self asyncGetDataForPath:path accessKey:accessKey channel:channel completion:^(NSData * _Nullable data) {
                !completion ? : completion(data, IESGurdSyncStatusSuccess);
            }];
        }];
    }];
}

#pragma mark - Enqueue

+ (void)enqueueSyncResourcesTaskWithParamsBlock:(IESGurdFetchResourcesParamsBlock)paramsBlock
                                     completion:(IESGurdSyncStatusDictionaryBlock _Nullable)completion;
{
    CHECKIF_SDK_SETUP
    
    if (!paramsBlock) {
        return;
    }
    
    IESGurdFetchResourcesParams *params = [[IESGurdFetchResourcesParams alloc] init];
    paramsBlock(params);
    
    if (![params isValid]) {
        NSAssert(NO, @"Enqueue task params invalid.");
        return;
    }
    
    NSString *accessKey = params.accessKey;
    if (![[IESGurdRegisterManager sharedManager] isAccessKeyRegistered:accessKey]) {
        NSAssert(NO, @"Access key must be registered.");
        return;
    }
    
    if (params.pollingPriority > IESGurdPollingPriorityNone) {
        [IESGurdPollingManager addPollingConfigWithParams:params];
    }
    
    [self applyInactivePackages:^(BOOL succeed, IESGurdSyncStatus status) {
        [IESGurdCacheManager syncResourcesWithParams:params completion:^(BOOL succeed, IESGurdSyncStatusDict dict) {
            [DELEGATE_DISPATCHER(IESGurdEventDelegate) gurdDidSyncResourceWithAccessKey:accessKey
                                                                                succeed:succeed
                                                                             statusDict:dict];
            !completion ? : completion(succeed, dict);
        }];
    }];
}

#pragma mark - Cancel Download

+ (void)cancelDownloadWithAccesskey:(NSString *)accessKey channel:(NSString *)channel
{
    if (accessKey.length == 0 || channel.length == 0) {
        return;
    }
    [[IESGurdDownloadPackageManager sharedManager] cancelDownloadWithAccessKey:accessKey channel:channel];
}

#pragma mark - Cache

+ (BOOL)hasCacheForPath:(NSString *)path accessKey:(NSString *)accessKey channel:(NSString *)channel
{
    BOOL hasCache = [IESGurdCacheManager hasCacheForPath:path accessKey:accessKey channel:channel];
    [IESGurdChannelUsageMananger accessDataWithType:IESGurdDataAccessTypeSyncAccess
                                          accessKey:accessKey
                                            channel:channel
                                            hitData:hasCache];
    return hasCache;
}

+ (NSData *)prefetchDataForPath:(NSString *)path accessKey:(NSString *)accessKey channel:(NSString *)channel
{
    NSData * data = nil;
    @synchronized (kIESGurdKitPrefetchChannels) {
        if ([kIESGurdKitPrefetchChannels[accessKey][channel] containsObject:path]) {
            data = [IESGurdCacheManager dataForPath:path accessKey:accessKey channel:channel options:0];
        }
    }
    return data;
}

+ (NSData *)dataForPath:(NSString *)path accessKey:(NSString *)accessKey channel:(NSString *)channel
{
    return [self dataForPath:path accessKey:accessKey channel:channel options:0];
}

+ (NSData *)dataForPath:(NSString *)path accessKey:(NSString *)accessKey channel:(NSString *)channel options:(NSDataReadingOptions)options
{
    NSData * data = [IESGurdCacheManager dataForPath:path accessKey:accessKey channel:channel options:options];
    [IESGurdChannelUsageMananger accessDataWithType:IESGurdDataAccessTypeSyncAccess
                                          accessKey:accessKey
                                            channel:channel
                                            hitData:(data.length > 0)];
    return data;
}

+ (void)asyncGetDataForPath:(NSString *)path
                  accessKey:(NSString *)accessKey
                    channel:(NSString *)channel
                 completion:(IESGurdAccessResourceCompletion)completion
{
    [IESGurdCacheManager asyncGetDataForPath:path accessKey:accessKey channel:channel completion:^(NSData * _Nullable data) {
        [IESGurdChannelUsageMananger accessDataWithType:IESGurdDataAccessTypeAsyncAccess
                                              accessKey:accessKey
                                                channel:channel
                                                hitData:(data.length > 0)];
        !completion ?: completion(data);
    }];
}

+ (NSData *)offlineDataForPath:(NSString *)path accessKey:(NSString *)accessKey channel:(NSString *)channel
{
    NSData * data = [IESGurdCacheManager offlineDataForPath:path accessKey:accessKey channel:channel];
    [IESGurdChannelUsageMananger accessDataWithType:IESGurdDataAccessTypeSyncAccess
                                          accessKey:accessKey
                                            channel:channel
                                            hitData:(data.length > 0)];
    return data;
}

+ (IESGurdChannelFileType)fileTypeForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    return [IESGurdCacheManager fileTypeForAccessKey:accessKey channel:channel];
}

+ (uint64_t)packageVersionForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    return [IESGurdCacheManager packageVersionForAccessKey:accessKey channel:channel];
}

+ (NSString *)rootDirForAccessKey:(NSString *)accessKey
{
    return [IESGurdCacheManager rootDirForAccessKey:accessKey];
}

+ (NSString *)rootDirForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    NSString *directory = [IESGurdCacheManager rootDirForAccessKey:accessKey channel:channel];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        BOOL directoryExist = ([[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:NULL].count > 0);
        [IESGurdChannelUsageMananger accessDataWithType:IESGurdDataAccessTypeDirectoryAccess
                                              accessKey:accessKey
                                                channel:channel
                                                hitData:directoryExist];
    });
    return directory;
}

+ (NSArray<NSString *> *)activeChannelsForAccessKey:(NSString *)accessKey
{
    return [IESGurdResourceMetadataStorage copyActiveMetadataDictionary][accessKey].allKeys;
}

+ (IESGurdChannelCacheStatus)cacheStatusForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    return [IESGurdCacheManager cacheStatusForAccessKey:accessKey channel:channel];
}

#pragma mark - Lazy

+ (IESGurdLazyResourcesInfo *)lazyResourcesInfoWithAccesskey:(NSString *)accesskey channel:(NSString *)channel
{
    return [[IESGurdLazyResourcesManager sharedManager] lazyResourceInfoWithAccesskey:accesskey channel:channel];
}

#pragma mark - ClearCache

+ (void)addCacheWhitelistWithAccessKey:(NSString *)accessKey
                              channels:(NSArray<NSString *> *)channels
{
    [IESGurdCacheManager addCacheWhitelistWithAccessKey:accessKey channels:channels];
}

+ (void)clearCache
{
    [IESGurdCacheManager clearCache];
    [self cleanSettingsCache];
    [self cleanBlacklistCache];
}

+ (void)clearCacheExceptWhitelist
{
    [IESGurdCacheManager clearCacheExceptWhitelist];
}

+ (void)clearCacheForAccessKey:(NSString *)accessKey
                       channel:(NSString *)channel
{
    [IESGurdCacheManager clearCacheForAccessKey:accessKey
                                        channel:channel];
}

+ (int64_t)getClearCacheSize:(int)expireAge
{
    return [[IESGurdExpiredCacheManager sharedManager] getClearCacheSize:expireAge];
}

+ (int64_t)getClearCacheSizeWithAccesskey:(NSString *)accessKey
                                expireAge:(int)expireAge
{
    return [[IESGurdExpiredCacheManager sharedManager] getClearCacheSizeWithAccesskey:accessKey
                                                     expireAge:expireAge];
}

+ (void)clearExpiredCache:(int)expireAge
                  cleanType:(int)cleanType
                 completion:(void (^ _Nullable)(NSDictionary<NSString *, IESGurdSyncStatusDict> *info))completion
{
    [[IESGurdExpiredCacheManager sharedManager] clearCache:expireAge
                                                 cleanType:cleanType
                                                completion:completion];
}

+ (void)clearExpiredCacheWithAccesskey:(NSString *)accessKey
                             expireAge:(int)expireAge
                             cleanType:(int)cleanType
                            completion:(void (^ _Nullable)(IESGurdSyncStatusDict info))completion
{
    [[IESGurdExpiredCacheManager sharedManager] clearCacheWithAccesskey:accessKey
                                                  expireAge:expireAge
                                                  cleanType:cleanType
                                                 completion:completion];
}

#pragma mark - Clean

+ (void)setCacheConfiguration:(IESGurdCacheConfiguration *)configuration
                 forAccessKey:(NSString *)accessKey
{
    [IESGurdCacheManager setCacheConfiguration:configuration
                                  forAccessKey:accessKey];
}

+ (void)addChannelsWhitelist:(NSArray<NSString *> *)channels
                forAccessKey:(NSString *)accessKey
{
    [IESGurdCacheManager addChannelsWhitelist:channels
                                 forAccessKey:accessKey];
}

+ (nullable NSDictionary *)getPackageExtra:(NSString *)accsskey
                                   channel:(NSString *)channel
{
    return [[IESGurdPackagesExtraManager sharedManager] getExtra:accsskey channel:channel];
}

+ (void)addLowStorageWhiteList:(NSString *)accesskey
                        groups:(NSArray *_Nullable)groups
                      channels:(NSArray *_Nullable)channels
{
    IESGurdLowStorageData *data = [[IESGurdLowStorageData alloc] init];
    data.groups = groups;
    data.channels = channels;
    @synchronized (IESGurdKitInstance.lowStorageWhiteList) {
        IESGurdKitInstance.lowStorageWhiteList[accesskey] = data;
    }
}

+ (BOOL)isInLowStorageWhiteList:(NSString *)accesskey group:(NSString *_Nullable)group channel:(NSString *_Nullable)channel
{
    @synchronized (IESGurdKitInstance.lowStorageWhiteList) {
        IESGurdLowStorageData *data = IESGurdKitInstance.lowStorageWhiteList[accesskey];
        if (data) {
            // groups和channels都为nil或空数组，代表整个ak都是白名单
            if ((data.groups == nil || data.groups.count == 0) && (data.channels == nil || data.groups.count == 0)) {
                return true;
            }
            if ([data.groups containsObject:group] || [data.channels containsObject:channel]) {
                return true;
            }
        }
        return false;
    }
}

+ (BOOL)isInLowStorageWhiteList:(NSString *)accesskey channel:(NSString *)channel {
    return [IESGurdKit isInLowStorageWhiteList:accesskey group:nil channel:channel];
}

+ (BOOL)isInLowStorageWhiteList:(NSString *)accesskey group:(NSString *)group {
    return [IESGurdKit isInLowStorageWhiteList:accesskey group:group channel:nil];
}

@end
