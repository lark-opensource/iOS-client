//
//  IESGurdChannelUsageMananger.m
//  IESGeckoKit
//
//  Created by 黄李磊 on 2021/5/20.
//

#import "IESGurdChannelUsageMananger.h"

#import "IESGurdKit+Experiment.h"
#import "IESGurdMonitorManager.h"
#import "IESGurdResourceMetadataStorage+Private.h"
#import "IESGurdChannelBlocklistManager.h"
#import "IESGurdCachePackageModelsManager.h"
#import "IESGurdKitUtil.h"
#import "IESGeckoCacheManager.h"
#import "IESGurdExpiredCacheManager.h"
#import "IESGurdDownloadPackageManager+Business.h"

@implementation IESGurdChannelUsageMananger

+ (void)accessDataWithType:(IESGurdDataAccessType)type
                 accessKey:(NSString *)accessKey
                   channel:(NSString *)channel
                   hitData:(BOOL)hitData
{
    int64_t timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    
    static dispatch_queue_t channelUsageQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        channelUsageQueue = IESGurdKitCreateSerialQueue("com.IESGurdKit.ChannelUsageQueue");
    });
    dispatch_async(channelUsageQueue, ^{
        [self updateMetadataWithAccessKey:accessKey
                                  channel:channel
                                timestamp:timestamp];
        
        BOOL isBlocklist = [[IESGurdChannelBlocklistManager sharedManager] isBlocklistChannel:channel accessKey:accessKey];
        uint64_t packageVersion = [IESGurdCacheManager packageVersionForAccessKey:accessKey channel:channel];
        NSDictionary *category = @{ @"type": @(type).stringValue,
                                    @"hit_local": @(hitData),
                                    @"is_blacklist": @(isBlocklist),
                                    @"access_key": accessKey ? : @"",
                                    @"gecko_channel": channel ? : @"",
                                    @"gecko_id": @(packageVersion) };
        
        // 移出黑名单
        [[IESGurdChannelBlocklistManager sharedManager] removeChannel:channel forAccessKey:accessKey];
        
        // 下载黑名单资源
        IESGurdCachePackageInfo *packageInfo = [[IESGurdCachePackageModelsManager sharedManager] packageInfoWithAccessKey:accessKey
                                                                                                                  channel:channel];
        IESGurdResourceModel *model = packageInfo.model;
        if (model && packageInfo.status == IESGurdCachePackageStatusNewVersion) {
            NSArray<IESGurdResourceModel *> *packagesArray = @[ model ];
            [IESGurdDownloadPackageManager downloadResourcesWithModels:packagesArray
                                                               logInfo:nil];
        }
        
        [[IESGurdMonitorManager sharedManager] monitorEvent:@"geckosdk_resource_access"
                                                   category:category
                                                     metric:nil
                                                      extra:nil];
    });
}

+ (void)updateMetadataWithAccessKey:(NSString *)accessKey
                            channel:(NSString *)channel
                          timestamp:(int64_t)timestamp
{
    IESGurdActivePackageMeta *meta = [IESGurdResourceMetadataStorage activeMetaForAccessKey:accessKey channel:channel];
    if (meta) {
        // 保存当前时间戳
        meta.lastReadTimestamp = timestamp;
        meta.isUsed = YES;
        [IESGurdResourceMetadataStorage saveActiveMeta:meta];
    }
}

+ (BOOL)isChannelUsed:(NSString *)accessKey channel:(NSString *)channel {
    IESGurdActivePackageMeta *meta = [IESGurdResourceMetadataStorage activeMetaForAccessKey:accessKey channel:channel];
    if (meta) {
        return meta.isUsed;
    }
    return NO;
}

@end

