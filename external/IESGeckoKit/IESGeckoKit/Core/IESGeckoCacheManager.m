//
//  IESGurdCacheManager.m
//  IESGurdKit
//
//  Created by willorfang on 2017/11/2.
//
//

#import "IESGeckoCacheManager.h"
//meta
#import "IESGurdResourceMetadataStorage.h"
//manager
#import "IESGurdFileBusinessManager.h"
#import "IESGurdClearCacheManager.h"
#import "IESGurdCacheCleanerManager.h"
#import "IESGurdResourceManager+MultiAccessKey.h"
#import "IESGurdApplyPackageManager.h"
#import "IESGurdPackagesNormalRequest.h"
#import "IESGurdLazyResourcesManager.h"
//logger
#import "IESGurdAppLogger.h"
//api
#import "IESGeckoAPI.h"
#import "IESGurdKit+Experiment.h"

@implementation IESGurdCacheManager

#pragma mark - Public - Operations

+ (void)applyAllInactiveCacheWithCompletion:(IESGurdSyncStatusBlock)completion
{
    [[IESGurdApplyPackageManager sharedManager] applyAllInactiveCacheWithCompletion:^(BOOL succeed, IESGurdSyncStatus status) {
        !completion ? : completion(succeed, status);
    }];
}

+ (void)applyInactiveCacheForAccessKey:(NSString *)accessKey
                               channel:(NSString *)channel
                            completion:(IESGurdSyncStatusBlock)completion
{
    [[IESGurdApplyPackageManager sharedManager] applyInactiveCacheForAccessKey:accessKey
                                                                       channel:channel
                                                                    completion:completion];
}

+ (void)syncResourcesWithParams:(IESGurdFetchResourcesParams *)params
                     completion:(IESGurdSyncStatusDictionaryBlock)completion
{
    if ([self isLazyRequest:params]) {
        NSArray<IESGurdResourceModel *> *packagesArray = [[IESGurdLazyResourcesManager sharedManager] modelsToDownloadWithParams:params];
        [IESGurdResourceManager downloadLazyResources:packagesArray
                                           completion:completion];
        return;
    }
    
    if ([self needRequest:params]) {
        IESGurdPackagesNormalRequest *request = [IESGurdPackagesNormalRequest requestWithParams:params
                                                                                     completion:completion];
        request.forceDownload = YES;
        [IESGurdResourceManager fetchConfigWithURLString:[IESGurdAPI packagesInfo]
                                  multiAccessKeysRequest:request];
    } else {
        !completion ? : completion(YES, IESGurdMakePlaceHolder(IESGurdSyncStatusServerPackageUnavailable));
    }
}

+ (BOOL)isLazyRequest:(IESGurdFetchResourcesParams *)params
{
    if (!IESGurdKit.enableOnDemand) return NO;
    
    if (params.modelActivePolicy == IESGurdPackageModelActivePolicyMatchLazy) return YES;
    
    // 判断是不是单channel
    if (params.groupName.length > 0) return NO;
    if (params.channels.count != 1) return NO;
    
    // 单channel请求，再用settings里面的按需channel来判断
    return [[IESGurdLazyResourcesManager sharedManager] isLazyChannel:params.accessKey channel:params.channels[0]];
}

+ (BOOL)needRequest:(IESGurdFetchResourcesParams *)params
{
    if (params.requestWhenHasLocalVersion) return YES;
    
    if (params.groupName.length > 0) return YES;
    // 遍历所有的channel，只要有一个channel本地没有资源，就需要发送请求
    for (NSString *channel in params.channels) {
        if ([self packageVersionForAccessKey:params.accessKey channel:channel] == 0) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Public - Cache Management

+ (BOOL)hasCacheForPath:(NSString *)path accessKey:(NSString *)accessKey channel:(NSString *)channel
{
    return [IESGurdFileBusinessManager hasCacheForAccessKey:accessKey channel:channel path:path];
}

+ (NSData *)dataForPath:(NSString *)path accessKey:(NSString *)accessKey channel:(NSString *)channel
{
    return [self dataForPath:path accessKey:accessKey channel:channel options:NSDataReadingMappedIfSafe];
}

+ (NSData *)dataForPath:(NSString *)path accessKey:(NSString *)accessKey channel:(NSString *)channel options:(NSDataReadingOptions)options
{
    NSData *data = [IESGurdFileBusinessManager dataForAccessKey:accessKey channel:channel path:path options:options];
    if (data.length > 0) {
        id<IESGurdCacheCleaner> cleaner = [[IESGurdCacheCleanerManager sharedManager] cleanerForAccessKey:accessKey];
        if ([cleaner respondsToSelector:@selector(gurdDidGetCachePackageForChannel:)]) {
            [cleaner gurdDidGetCachePackageForChannel:channel];
        }
    }
    return data;
}

+ (void)asyncGetDataForPath:(NSString *)path
                  accessKey:(NSString *)accessKey
                    channel:(NSString *)channel
                 completion:(IESGurdAccessResourceCompletion)completion
{
    if (accessKey.length == 0 || channel.length == 0) {
        !completion ? : completion(nil);
        return;
    }
    [IESGurdFileBusinessManager asyncExecuteBlock:^{
        NSData *data = [self dataForPath:path accessKey:accessKey channel:channel];
        dispatch_queue_async_safe(dispatch_get_main_queue(), ^{
            !completion ? : completion(data);
        });
    } accessKey:accessKey channel:channel];
}

+ (NSData *)offlineDataForPath:(NSString *)path accessKey:(NSString *)accessKey channel:(NSString *)channel
{
    NSData *data = [IESGurdFileBusinessManager offlineDataForAccessKey:accessKey channel:channel path:path];
    if (data.length > 0) {
        id<IESGurdCacheCleaner> cleaner = [[IESGurdCacheCleanerManager sharedManager] cleanerForAccessKey:accessKey];
        if ([cleaner respondsToSelector:@selector(gurdDidGetCachePackageForChannel:)]) {
            [cleaner gurdDidGetCachePackageForChannel:channel];
        }
    }
    return data;
}

+ (IESGurdChannelFileType)fileTypeForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    IESGurdActivePackageMeta *meta = [IESGurdResourceMetadataStorage activeMetaForAccessKey:accessKey channel:channel];
    if (meta) {
        return meta.packageType;
    }
    return -1;
}

+ (uint64_t)packageVersionForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    IESGurdActivePackageMeta *meta = [IESGurdResourceMetadataStorage activeMetaForAccessKey:accessKey channel:channel];
    if (meta) {
        return meta.version;
    }
    return 0;
}

+ (NSString *)rootDirForAccessKey:(NSString *)accessKey
{
    return [IESGurdFilePaths directoryPathForAccessKey:accessKey];
}

+ (NSString *)rootDirForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    return [IESGurdFilePaths directoryPathForAccessKey:accessKey channel:channel];
}

+ (IESGurdChannelCacheStatus)cacheStatusForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    IESGurdActivePackageMeta *activeMeta = [IESGurdResourceMetadataStorage activeMetaForAccessKey:accessKey channel:channel];
    if (activeMeta) {
        return IESGurdChannelCacheStatusActive;
    }
    IESGurdInactiveCacheMeta *inactiveMeta = [IESGurdResourceMetadataStorage inactiveMetaForAccessKey:accessKey channel:channel];
    if (inactiveMeta) {
        return IESGurdChannelCacheStatusInactive;
    }
    return IESGurdChannelCacheStatusNotFound;
}

+ (void)addCacheWhitelistWithAccessKey:(NSString *)accessKey
                              channels:(NSArray<NSString *> *)channels
{
    [IESGurdFileBusinessManager addCacheWhitelistWithAccessKey:accessKey channels:channels];
}

+ (void)clearCache
{
    [IESGurdClearCacheManager clearCache];
}

+ (void)clearCacheExceptWhitelist
{
    [IESGurdClearCacheManager clearCacheExceptWhitelist];
}

+ (void)clearCacheForAccessKey:(NSString *)accessKey
                       channel:(NSString *)channel
{
    uint64_t packageID = [self packageVersionForAccessKey:accessKey channel:channel];
    [IESGurdClearCacheManager clearCacheForAccessKey:accessKey channel:channel completion:^(BOOL succeed, NSDictionary * _Nonnull info, NSError * _Nonnull error) {
        IESGurdStatsType statsType = succeed ? IESGurdStatsTypeCleanCacheSucceed : IESGurdStatsTypeCleanCacheFail;
        NSMutableDictionary *extra = [NSMutableDictionary dictionary];
        [extra addEntriesFromDictionary:info];
        extra[@"clean_strategy"] = @(3);
        extra[@"clean_type"] = @(100);
        [IESGurdAppLogger recordCleanStats:statsType
                                 accessKey:accessKey
                                   channel:channel
                                 packageID:packageID
                                     extra:[extra copy]];
    }];
}

#pragma mark - Public - Clean

+ (void)setCacheConfiguration:(IESGurdCacheConfiguration *)configuration
                 forAccessKey:(NSString *)accessKey
{
    [[IESGurdCacheCleanerManager sharedManager] registerCacheCleanerForAccessKey:accessKey
                                                                   configuration:configuration];
}

+ (void)addChannelsWhitelist:(NSArray<NSString *> *)channels
                forAccessKey:(NSString *)accessKey
{
    [[IESGurdCacheCleanerManager sharedManager] addChannelsWhitelist:channels
                                                        forAccessKey:accessKey];
}

@end
