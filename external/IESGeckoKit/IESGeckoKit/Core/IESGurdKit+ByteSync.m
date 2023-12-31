//
//  IESGurdKit+ByteSync.m
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/10/23.
//

#import "IESGurdKit+ByteSync.h"

#import "IESGurdClearCacheManager+Remote.h"
#import "IESGurdDownloadPackageManager+Business.h"

@implementation IESGurdKit (ByteSync)

+ (BOOL)shouldHandleByteSyncMessageWithTimestamp:(NSInteger)timestamp
{
    return (timestamp > [IESGurdKit setupTimestamp] * 1000);
}

+ (void)syncResourcesWithTargetChannelsDictionary:(NSDictionary *)targetChannelsDictionary
                             groupNamesDictionary:(NSDictionary *)groupNamesDictionary
                           customParamsDictionary:(NSDictionary *)customParamsDictionary
                                           taskId:(int)taskId
{
    NSAssert(NO, @"deprecated");
}

+ (void)clearCacheWithCleanInfoDictionary:(NSDictionary *)cleanInfoDictionary taskId:(int)taskId
{
    if (cleanInfoDictionary.count == 0) {
        return;
    }
    NSMutableDictionary *universalStrategies = [NSMutableDictionary dictionary];
    [cleanInfoDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSDictionary *strategies, BOOL *stop) {
        IESGurdConfigUniversalStrategies *model = [IESGurdConfigUniversalStrategies strategiesWithDictionary:strategies];
        if (model) {
            universalStrategies[accessKey] = model;
        }
    }];
    [IESGurdClearCacheManager clearCacheWithUniversalStrategies:[universalStrategies copy]
                                                        logInfo:@{ @"req_type" : @(IESGurdPackagesConfigRequestTypeByteSync),
                                                                   @"sync_task_id" : @(taskId) }];
}

+ (void)downloadResourcesWithModelsArray:(NSArray<IESGurdResourceModel *> *)modelsArray taskId:(int)taskId
{
    if (modelsArray.count == 0) {
        return;
    }
    [IESGurdDownloadPackageManager downloadResourcesWithModels:modelsArray
                                                       logInfo:@{ @"req_type" : @(IESGurdPackagesConfigRequestTypeByteSync),
                                                                  @"sync_task_id" : @(taskId) }];
}

@end
