
#import "IESGurdExpiredCacheManager.h"
#import "NSData+IESGurdKit.h"
#import "IESGurdKit+Experiment.h"
#import "IESGeckoDefines+Private.h"
#import "IESGurdResourceMetadataStorage.h"
#import "IESGurdSettingsManager.h"
#import "IESGurdFilePaths.h"
#import "IESGeckoCacheManager.h"
#import "IESGurdClearCacheManager.h"
#import "IESGurdAppLogger.h"
#import "IESGurdChannelBlocklistManager.h"
#import "IESGurdPackagesExtraManager.h"

#import <objc/runtime.h>
#import <pthread/pthread.h>

// 3 分钟后监听后台通知
static const NSInteger kIESGurdClearExpiredCacheDelay = 3 * 60;
// 5 分钟后如果没后台清理，强制清理一次
static const NSInteger kIESGurdClearExpiredCacheBackupDelay = 5 * 60;
// 清理限频，5min
static const NSInteger kIESGurdClearExpiredCacheThrottleInterval = 5 * 60;

static pthread_mutex_t kTargetChannelsLock = PTHREAD_MUTEX_INITIALIZER;

@interface IESGurdExpiredCacheConfig : NSObject
// 过期时间
@property (nonatomic, assign) int expireAge;
// 清理类型，4被动，5主动
@property (nonatomic, assign) int cleanType;

@property (nonatomic, copy) NSString *accessKey;

@property (nonatomic, copy) NSDictionary<NSString *,IESGurdActivePackageMeta *> *channelsMap;

@end

@implementation IESGurdExpiredCacheConfig
@end

@interface IESGurdExpiredCacheManager ()

// 上一次清理的时间
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDate *> *lastCleanDateDictionary;

@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *targetGroupDictionary;

@property (nonatomic, copy) NSDictionary<NSString *, NSArray<NSString *> *> *targetChannelDictionary;

@end

@implementation IESGurdExpiredCacheManager

+ (instancetype)sharedManager
{
    static IESGurdExpiredCacheManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
        manager.lastCleanDateDictionary = [NSMutableDictionary dictionary];
    });
    return manager;
}

#pragma mark - setup

- (void)setup
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kIESGurdClearExpiredCacheDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(innerClearCache)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kIESGurdClearExpiredCacheBackupDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self innerClearCache];
    });
}

- (void)updateTargetGroupDictionary:(NSDictionary<NSString *, NSString *> *)targetGroupDictionary
{
    GURD_MUTEX_LOCK(kTargetChannelsLock);
    
    self.targetGroupDictionary = targetGroupDictionary;
}

- (void)updateTargetChannels:(NSDictionary<NSString *, NSArray<NSString *> *> *)targetChannels
{
    GURD_MUTEX_LOCK(kTargetChannelsLock);
    
    self.targetChannelDictionary = targetChannels;
}

#pragma mark - ClearCache

- (int64_t)getClearCacheSize:(int)expireAge
{
    if (!self.clearExpiredCacheEnabled) {
        return 0;
    }
    
    IESGurdExpiredCacheConfig *config = [[IESGurdExpiredCacheConfig alloc] init];
    config.expireAge = expireAge;
    
    __block int64_t totalResourceUsage = 0;
    [[IESGurdResourceMetadataStorage copyActiveMetadataDictionary] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull accessKey, NSDictionary<NSString *,IESGurdActivePackageMeta *> * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj enumerateKeysAndObjectsUsingBlock:^(NSString *channel, IESGurdActivePackageMeta *activeMeta, BOOL *stop) {
            if ([self isExpiredChannelWithActiveMeta:accessKey activeMeta:activeMeta config:config]) {
                NSInteger channelResourceUsage = [IESGurdFilePaths fileSizeAtDirectory:[IESGurdFilePaths directoryPathForAccessKey:accessKey channel:channel]];
                totalResourceUsage += channelResourceUsage;
            }
        }];
    }];
    return totalResourceUsage;
}

- (int64_t)getClearCacheSizeWithAccesskey:(NSString *)accessKey
                                expireAge:(int)expireAge
{
    if (!self.clearExpiredCacheEnabled) {
        return 0;
    }
    
    IESGurdExpiredCacheConfig *config = [[IESGurdExpiredCacheConfig alloc] init];
    config.expireAge = expireAge;
    
    __block int64_t totalResourceUsage = 0;
    [[IESGurdResourceMetadataStorage copyActiveMetadataDictionary][accessKey] enumerateKeysAndObjectsUsingBlock:^(NSString *channel, IESGurdActivePackageMeta *activeMeta, BOOL *stop) {
        if ([self isExpiredChannelWithActiveMeta:accessKey activeMeta:activeMeta config:config]) {
            NSInteger channelResourceUsage = [IESGurdFilePaths fileSizeAtDirectory:[IESGurdFilePaths directoryPathForAccessKey:accessKey channel:channel]];
            totalResourceUsage += channelResourceUsage;
        }
    }];
    return totalResourceUsage;
}

// 删除全部 channels & 加过期 channel 进黑名单
- (void)clearCache:(int)expireAge
         cleanType:(int)cleanType
        completion:(void (^ _Nullable)(NSDictionary<NSString *, IESGurdSyncStatusDict> *info))completion
{
    if (!self.clearExpiredCacheEnabled) {
        !completion ? : completion(@{});
        return;
    }
    
    __block NSMutableDictionary<NSString *, IESGurdSyncStatusDict> *statusDictionary = [NSMutableDictionary dictionary];
    dispatch_group_t group = dispatch_group_create();
    [[IESGurdResourceMetadataStorage copyActiveMetadataDictionary] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull accessKey, NSDictionary<NSString *,IESGurdActivePackageMeta *> * _Nonnull obj, BOOL * _Nonnull stop) {
        dispatch_group_enter(group);
        void (^innerCompletion)(IESGurdSyncStatusDict) = ^(IESGurdSyncStatusDict result) {
            @synchronized (statusDictionary) {
                statusDictionary[accessKey] = result;
            }
            dispatch_group_leave(group);
        };
        
        IESGurdExpiredCacheConfig *config = [[IESGurdExpiredCacheConfig alloc] init];
        config.expireAge = expireAge;
        config.cleanType = cleanType;
        config.accessKey = accessKey;
        config.channelsMap = obj;
        
        [self clearCacheWithConfig:config
                        completion:innerCompletion];
    }];
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        !completion ?: completion([statusDictionary copy]);
    });
}

- (void)clearCacheWithAccesskey:(NSString *)accessKey
                      expireAge:(int)expireAge
                      cleanType:(int)cleanType
                     completion:(void (^ _Nullable)(IESGurdSyncStatusDict info))completion
{
    if (accessKey.length == 0) {
        !completion ? : completion(@{});
        return;
    }
    if (!self.clearExpiredCacheEnabled) {
        !completion ? : completion(@{});
        return;
    }
    NSDictionary<NSString *,IESGurdActivePackageMeta *> *channelsMap = [IESGurdResourceMetadataStorage copyActiveMetadataDictionary][accessKey];
    
    IESGurdExpiredCacheConfig *config = [[IESGurdExpiredCacheConfig alloc] init];
    config.expireAge = expireAge;
    config.cleanType = cleanType;
    config.accessKey = accessKey;
    config.channelsMap = channelsMap;
    
    [self clearCacheWithConfig:config
                    completion:completion];
}

- (void)clearCacheWhenLowStorage
{
    if (!self.clearExpiredCacheEnabled) {
        return;
    }
    if ([objc_getAssociatedObject(self, _cmd) boolValue]) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self clearCache:2 cleanType:IESGurdExpiredCleanTypeLowStorage completion:nil];
    });
    objc_setAssociatedObject(self, _cmd, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)clearCacheWithConfig:(IESGurdExpiredCacheConfig *)config
                  completion:(void (^)(IESGurdSyncStatusDict _Nonnull))completion
{
    NSString *accessKey = config.accessKey;
    // 每个 accesskey 的清理限频 5min
    @synchronized (self.lastCleanDateDictionary) {
        NSDate *lastCleanDate = self.lastCleanDateDictionary[accessKey];
        if (lastCleanDate) {
            if ([[NSDate date] timeIntervalSinceDate:lastCleanDate] < kIESGurdClearExpiredCacheThrottleInterval) {
                !completion ?: completion(@{});
                return;
            }
        }
        self.lastCleanDateDictionary[accessKey] = [NSDate date];
    }
    
    GURD_MUTEX_LOCK(kTargetChannelsLock);
    
    // 需要加入黑名单的 channel, 只在 target group 范围中计算
    NSMutableArray<NSString *> *channelsToClear = [NSMutableArray array];
    
    [config.channelsMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull channel, IESGurdActivePackageMeta * _Nonnull activeMeta, BOOL * _Nonnull stop) {
        if ([self isExpiredChannelWithActiveMeta:accessKey activeMeta:activeMeta config:config]) {
            // channel 过期，需要清理
            [channelsToClear addObject:channel];
        }
    }];
    if (channelsToClear.count == 0) {
        !completion ?: completion(@{});
        return;
    }
    [self innerClearCacheWithConfig:config
                           channels:channelsToClear
                         completion:completion];
}

#pragma mark - Private

- (void)innerClearCache
{
//    if ([objc_getAssociatedObject(self, _cmd) boolValue]) {
//        return;
//    }
//    objc_setAssociatedObject(self, _cmd, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//
//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:UIApplicationDidEnterBackgroundNotification
//                                                  object:nil];
//
//    UIApplication *application = [UIApplication sharedApplication];
//    if (application.applicationState == UIApplicationStateBackground) {
//        // 3分钟后进入后台
//        __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
//            [application endBackgroundTask:bgTask];
//            bgTask = UIBackgroundTaskInvalid;
//        }];
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            [self clearCache:^(NSDictionary<NSString *,IESGurdSyncStatusDict> * _Nonnull info) {
//                [application endBackgroundTask:bgTask];
//                bgTask = UIBackgroundTaskInvalid;
//            }];
//        });
//    } else {
//        // 5分钟的兜底
//        [self clearCache:nil];
//    }
}

- (void)innerClearCacheWithConfig:(IESGurdExpiredCacheConfig *)config
                         channels:(NSArray<NSString *> *)channels
                       completion:(void (^)(NSDictionary<NSString *, NSNumber *> *info))completion
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *accessKey = config.accessKey;
        IESGurdChannelBlocklistManager *blocklistManager = [IESGurdChannelBlocklistManager sharedManager];
        // 用于保存清除错误
        __block NSMutableDictionary<NSString *, NSNumber *> *statusDictionary = [NSMutableDictionary dictionary];
        dispatch_group_t group = dispatch_group_create();
        [channels enumerateObjectsUsingBlock:^(NSString *channel, NSUInteger idx, BOOL *stop) {
            // 被清理的 channel 加入黑名单
            [blocklistManager addChannel:channel forAccessKey:accessKey];
            
            dispatch_group_enter(group);
            IESGurdActivePackageMeta *activeMeta = config.channelsMap[channel];
            [self clearCacheForAccessKey:accessKey channel:channel activeMeta:activeMeta config:config completion:^(IESGurdSyncStatus status, NSDictionary *info, NSError *error) {
                @synchronized (statusDictionary) {
                    statusDictionary[channel] = @(status);
                }
                if (status == IESGurdSyncStatusCleanCacheSuccess) {
                    [[IESGurdPackagesExtraManager sharedManager] updateExtra:accessKey channel:channel data:nil];
                }
                dispatch_group_leave(group);
            }];
        }];
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            [[IESGurdPackagesExtraManager sharedManager] saveToFile];
            !completion ?: completion([statusDictionary copy]);
        });
    });
}

- (void)clearCacheForAccessKey:(NSString *)accessKey
                       channel:(NSString *)channel
                    activeMeta:(IESGurdActivePackageMeta *)activeMeta
                        config:(IESGurdExpiredCacheConfig *)config
                    completion:(void (^)(IESGurdSyncStatus status, NSDictionary *info, NSError *error))completion
{
    uint64_t packageID = activeMeta.packageID;
    [IESGurdClearCacheManager clearCacheForAccessKey:accessKey channel:channel isSync:YES completion:^(BOOL succeed, NSDictionary * _Nonnull info, NSError * _Nonnull error) {
        IESGurdStatsType statsType = succeed ? IESGurdStatsTypeCleanExpiredCacheSucceed : IESGurdStatsTypeCleanExpiredCacheFail;
        IESGurdSyncStatus status = succeed ? IESGurdSyncStatusCleanCacheSuccess : IESGurdSyncStatusCleanCacheFailed;
        NSMutableDictionary *extra = [NSMutableDictionary dictionary];
        [extra addEntriesFromDictionary:info];
        extra[@"expire_age"] = @(config.expireAge);
        extra[@"clean_type"] = @(config.cleanType);
        extra[@"clean_group"] = self.targetGroupDictionary[accessKey] ? : @"null";
        [IESGurdAppLogger recordCleanStats:statsType
                                 accessKey:accessKey
                                   channel:channel
                                 packageID:packageID
                                     extra:[extra copy]];
        !completion ? : completion(status, info, error);
    }];
}

- (BOOL)isExpiredChannelWithActiveMeta:(NSString *)accesskey
                            activeMeta:(IESGurdActivePackageMeta *)activeMeta
                                config:(IESGurdExpiredCacheConfig *)config
{
    int64_t lastReadTimestamp = activeMeta.lastReadTimestamp;
    NSArray<NSString *> *groups = activeMeta.groups;
    if (lastReadTimestamp == 0) {
        return NO;
    }
    if ([groups containsObject:self.targetGroupDictionary[accesskey]] || [self.targetChannelDictionary[accesskey] containsObject:activeMeta.channel]) {
        return [[NSDate date] timeIntervalSince1970] * 1000 - lastReadTimestamp > config.expireAge * 24 * 60 * 60 * 1000;
    }
    return NO;
}

@end
