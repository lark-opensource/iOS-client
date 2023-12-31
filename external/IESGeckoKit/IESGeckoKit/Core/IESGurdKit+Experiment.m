//
//  IESGurdKit+Experiment.m
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/8/23.
//

#import "IESGurdKit+Experiment.h"

#import "IESGurdMonitorManager.h"
#import "IESGurdSettingsManager.h"
#import "IESGurdEventTraceManager+Message.h"

//cache
#import "IESGurdExpiredCacheManager.h"

#import "IESGurdDownloadPackageManager.h"

@implementation IESGurdKit (Experiment)

static BOOL kIESGurdSettingsEnable = YES;
+ (BOOL)isSettingsEnable
{
    return kIESGurdSettingsEnable;
}

+ (void)setSettingsEnable:(BOOL)settingsEnable
{
    kIESGurdSettingsEnable = settingsEnable;
}

static BOOL kIESGurdRequestThrottleEnabled = YES;
+ (BOOL)isThrottleEnabled
{
    return kIESGurdRequestThrottleEnabled;
}

+ (void)setThrottleEnabled:(BOOL)throttleEnabled
{
    IESGurdSettingsRequestMeta *requestMeta = [IESGurdSettingsManager sharedInstance].settingsResponse.requestMeta;
    if (requestMeta) {
        throttleEnabled = throttleEnabled && requestMeta.isFrequenceControlEnable;
    }
    kIESGurdRequestThrottleEnabled = throttleEnabled;
}

static BOOL kIESGurdRequestRetryEnabled = YES;
+ (BOOL)isRetryEnabled
{
    return kIESGurdRequestRetryEnabled;
}

+ (void)setRetryEnabled:(BOOL)retryEnabled
{
    kIESGurdRequestRetryEnabled = retryEnabled;
}

static BOOL kIESGurdRequestPollingEnabled = YES;
+ (BOOL)isPollingEnabled
{
    return kIESGurdRequestPollingEnabled;
}

+ (void)setPollingEnabled:(BOOL)pollingEnabled
{
    IESGurdSettingsRequestMeta *requestMeta = [IESGurdSettingsManager sharedInstance].settingsResponse.requestMeta;
    if (requestMeta) {
        pollingEnabled = pollingEnabled && requestMeta.isPollingEnabled;
    }
    kIESGurdRequestPollingEnabled = pollingEnabled;
}

static int availableStorageFull = -1;
+ (int)availableStorageFull
{
    return availableStorageFull;
}

+ (void)setAvailableStorageFull:(int)availableStorage
{
    availableStorageFull = availableStorage;
}

static int availableStoragePatch = -1;
+ (int)availableStoragePatch
{
    return availableStoragePatch;
}

+(void)setAvailableStoragePatch:(int)availableStorage
{
    availableStoragePatch = availableStorage;
}

static BOOL kEnableDownload = YES;
+ (BOOL)enableDownload
{
    return kEnableDownload;
}

+ (void)setEnableDownload:(BOOL)enable
{
    kEnableDownload = enable;
    if (enable) {
        [[IESGurdDownloadPackageManager sharedManager] downloadIfNeeded];
    }
}

static BOOL kEnableMetadataIndexLog = NO;
+ (BOOL)enableMetadataIndexLog
{
    return kEnableMetadataIndexLog;
}

+ (void)setEnableMetadataIndexLog:(BOOL)enableMetadataIndexLog
{
    kEnableMetadataIndexLog = enableMetadataIndexLog;
}

static BOOL kEnableEncrypt = YES;
+ (BOOL)enableEncrypt
{
    return kEnableEncrypt;
}

+ (void)setEnableEncrypt:(BOOL)enable
{
    kEnableEncrypt = enable;
}

static BOOL kEnableOnDemand = YES;
+ (BOOL)enableOnDemand
{
    return kEnableOnDemand;
}

+ (void)setEnableOnDemand:(BOOL)enable
{
    kEnableOnDemand = enable;
}

+ (NSInteger)monitorFlushCount
{
    return [IESGurdMonitorManager sharedManager].flushCount;
}

+ (void)setMonitorFlushCount:(NSInteger)monitorFlushCount
{
    [IESGurdMonitorManager sharedManager].flushCount = monitorFlushCount;
}

#pragma mark - expired cache getters & settings

+ (BOOL)clearExpiredCacheEnabled
{
    return [IESGurdExpiredCacheManager sharedManager].clearExpiredCacheEnabled;
}

+ (void)setClearExpiredCacheEnabled:(BOOL)clearExpiredCacheEnabled
{
    [IESGurdExpiredCacheManager sharedManager].clearExpiredCacheEnabled = clearExpiredCacheEnabled;
}

+ (NSDictionary<NSString *, NSString *> *)expiredTargetGroups
{
    return [IESGurdExpiredCacheManager sharedManager].targetGroupDictionary;
}

+ (void)setExpiredTargetGroups:(NSDictionary<NSString *, NSString *> *)targetGrouplDictionary
{
    [[IESGurdExpiredCacheManager sharedManager] updateTargetGroupDictionary:targetGrouplDictionary];
}

+ (NSDictionary<NSString *, NSArray<NSString *> *> *)expiredTargetChannels
{
    return [IESGurdExpiredCacheManager sharedManager].targetChannelDictionary;
}

+ (void)setExpiredTargetChannels:(NSDictionary<NSString *, NSArray<NSString *> *> *)targetChannelDictionary
{
    [[IESGurdExpiredCacheManager sharedManager] updateTargetChannels:targetChannelDictionary];
}

static BOOL kUseNewDecompressZstd = YES;
+ (BOOL)useNewDecompressZstd
{
    return kUseNewDecompressZstd;
}

+ (void)setUseNewDecompressZstd:(BOOL)use
{
    kUseNewDecompressZstd = use;
}

@end
