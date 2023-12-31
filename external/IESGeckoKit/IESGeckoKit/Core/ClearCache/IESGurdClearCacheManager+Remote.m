//
//  IESGurdClearCacheManager+Remote.m
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/10/23.
//

#import "IESGurdClearCacheManager+Remote.h"

#import "IESGurdPackagesConfigResponse.h"
#import "IESGurdResourceMetadataStorage.h"
#import "IESGurdAppLogger.h"

@implementation IESGurdClearCacheManager (Remote)

static NSMutableDictionary *cleanChannelsDictionary = nil;
+ (void)clearCacheWithUniversalStrategies:(IESGurdClearCacheStrategies *)universalStrategies
                                  logInfo:(NSDictionary * _Nullable)logInfo
{
    if (universalStrategies.count == 0) {
        return;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cleanChannelsDictionary = [NSMutableDictionary dictionary];
    });
    
    [universalStrategies enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, IESGurdConfigUniversalStrategies *strategies, BOOL *stop) {
        [strategies.specifiedCleanArray enumerateObjectsUsingBlock:^(IESGurdConfigSpecifiedClean *specifiedClean, NSUInteger idx, BOOL *stop) {
            IESGurdSpecifiedCleanType cleanType = specifiedClean.cleanType;
            NSString *channel = specifiedClean.channel;
            if (cleanType == IESGurdSpecifiedCleanTypeUnknown || channel.length == 0) {
                return;
            }
            
            NSString *key = [NSString stringWithFormat:@"%@-%@", accessKey, channel];
            
            __block BOOL shouldClean = NO;
            @synchronized (cleanChannelsDictionary) {
                shouldClean = !cleanChannelsDictionary[key];
            }
            if (!shouldClean) {
                return;
            }
            
            IESGurdActivePackageMeta *activeMeta = [IESGurdResourceMetadataStorage activeMetaForAccessKey:accessKey channel:channel];
            shouldClean = [specifiedClean shouldCleanWithVersion:activeMeta.version];
            if (!shouldClean) {
                return;
            }
            
            @synchronized (cleanChannelsDictionary) {
                cleanChannelsDictionary[key] = @(YES);
            }
            
            [IESGurdClearCacheManager clearCacheForAccessKey:accessKey channel:channel completion:^(BOOL succeed, NSDictionary *info, NSError *error) {
                @synchronized (cleanChannelsDictionary) {
                    cleanChannelsDictionary[key] = nil;
                }
                
                IESGurdStatsType statsType = succeed ? IESGurdStatsTypeCleanCacheSucceed : IESGurdStatsTypeCleanCacheFail;
                NSMutableDictionary *extra = [NSMutableDictionary dictionary];
                [extra addEntriesFromDictionary:info];
                [extra addEntriesFromDictionary:logInfo];
                extra[@"clean_strategy"] = @(1);
                extra[@"clean_type"] = @(cleanType);
                if (!succeed) {
                    extra[@"err_msg"] = error.localizedDescription ? : @"";
                }
                [IESGurdAppLogger recordCleanStats:statsType
                                         accessKey:accessKey
                                           channel:channel
                                         packageID:activeMeta.packageID
                                             extra:[extra copy]];
            }];
        }];
    }];
}

@end
