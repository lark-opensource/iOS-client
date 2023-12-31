//
//  IESGurdCacheCleanerManager+Delegate.m
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/7/22.
//

#import "IESGurdCacheCleanerManager.h"

#import "IESGeckoDefines+Private.h"
#import "IESGurdClearCacheManager.h"
#import "IESGurdFileMetaManager.h"
#import "IESGurdAppLogger.h"

@interface IESGurdCacheCleanerManager (Delegate) <IESGurdCacheCleanerManagerDelegate>

@end

@implementation IESGurdCacheCleanerManager (Delegate)

- (id<IESGurdCacheCleanerManagerDelegate>)delegate
{
    return self;
}

#pragma mark - IESGurdCacheCleanerManagerDelegate

- (void)cacheCleanerManager:(IESGurdCacheCleanerManager *)manager
     cleanCacheForAccessKey:(NSString *)accessKey
        channelsToBeCleaned:(NSArray<NSString *> *)channelsToBeCleaned
                cachePolicy:(IESGurdCleanCachePolicy)cachePolicy
               enableAppLog:(BOOL)enableAppLog
{
    GurdLog(@"【%@】channels need to be cleaned : %@", accessKey, [channelsToBeCleaned componentsJoinedByString:@","]);
    [channelsToBeCleaned enumerateObjectsUsingBlock:^(NSString *channel, NSUInteger idx, BOOL *stop) {
        uint64_t packageID = [IESGurdFileMetaManager activeMetaForAccessKey:accessKey channel:channel].packageID;
        [IESGurdClearCacheManager clearCacheForAccessKey:accessKey channel:channel completion:^(BOOL succeed, NSDictionary * _Nonnull info, NSError * _Nonnull error) {
            if (!enableAppLog) {
                return;
            }
            IESGurdStatsType statsType = succeed ? IESGurdStatsTypeCleanCacheSucceed : IESGurdStatsTypeCleanCacheFail;
            NSMutableDictionary *extra = [NSMutableDictionary dictionary];
            [extra addEntriesFromDictionary:info];
            extra[@"clean_strategy"] = @(3);
            extra[@"clean_type"] = @([self cleanTypeWithCachePolicy:cachePolicy]);
            [IESGurdAppLogger recordCleanStats:statsType
                                     accessKey:accessKey
                                       channel:channel
                                     packageID:packageID
                                         extra:[extra copy]];
        }];
    }];
}

- (NSInteger)cleanTypeWithCachePolicy:(IESGurdCleanCachePolicy)cachePolicy
{
    switch (cachePolicy) {
        case IESGurdCleanCachePolicyFIFO: {
            return 101;
        }
        case IESGurdCleanCachePolicyLRU: {
            return 102;
        }
        case IESGurdCleanCachePolicyNone: {
            break;
        }
    }
    return 199;
}

@end
