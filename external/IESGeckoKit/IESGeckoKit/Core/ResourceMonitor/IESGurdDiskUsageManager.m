//
//  IESGurdDiskUsageManager.m
//  IESGeckoKit
//
//  Created by 黄李磊 on 2021/5/20.
//

#import "IESGurdDiskUsageManager.h"

#import "IESGeckoKit+Private.h"
#import "IESGurdFilePaths.h"
#import "IESGeckoDefines+Private.h"
#import "IESGurdKit+Experiment.h"
#import "IESGurdResourceMetadataStorage.h"
#import "IESGurdMonitorManager.h"
#import "IESGurdResourceInfoModel.h"
#import "IESGurdAppLogger.h"

@implementation IESGurdDiskUsageManager

+ (instancetype)sharedInstance
{
    static IESGurdDiskUsageManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)recordUsageIfNeeded
{
    // 每天上报一次
    NSDate *lastDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"gecko_resource_info"] ?: [NSDate dateWithTimeIntervalSinceNow:-(24*60*60)];
    NSDate *currentDate = [NSDate date];
    BOOL isSameDay = [[NSCalendar currentCalendar] isDate:currentDate inSameDayAsDate:lastDate];
    if (isSameDay) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setObject:currentDate forKey:@"gecko_resource_info"];
    [self recordUsage];
}

- (void)recordUsage
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableDictionary<NSString *, IESGurdResourceInfoModel *> *resourceInfoModelDictionary = [NSMutableDictionary dictionary];
        __block NSInteger geckoTotalResourceUsage = 0;
        
        // 计算每个 active&backup channel usage
        [[IESGurdResourceMetadataStorage copyActiveMetadataDictionary] enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSDictionary<NSString *,IESGurdActivePackageMeta *> *obj, BOOL *stop) {
            __block NSInteger accessKeyResourceUsage = 0;
            [obj enumerateKeysAndObjectsUsingBlock:^(NSString *channel, IESGurdActivePackageMeta *obj, BOOL *stop) {
                GURD_TIK;
                NSInteger activeResourceUsage = [IESGurdFilePaths fileSizeAtDirectory:[IESGurdFilePaths directoryPathForAccessKey:accessKey channel:channel]];
                NSInteger backupResourceUsage = 0;
                NSInteger cost = GURD_TOK;
                accessKeyResourceUsage += activeResourceUsage + backupResourceUsage;
                
                [self uploadResourceInfo:accessKey
                                channel:channel
                                cost:cost
                                activeResourceUsage:activeResourceUsage
                                inactiveResourceUsage:0
                                backupResourceUsage:backupResourceUsage];
            }];
            
            geckoTotalResourceUsage += accessKeyResourceUsage;
            IESGurdResourceInfoModel * resourceInfoModel = [[IESGurdResourceInfoModel alloc] init];
            resourceInfoModel.accessKeyResourceUsage = accessKeyResourceUsage;
            resourceInfoModel.channelCount = (int)[obj count];
            resourceInfoModelDictionary[accessKey] = resourceInfoModel;
        }];
   
        // 计算每个 inactive channel usage
        [[IESGurdResourceMetadataStorage copyInactiveMetadataDictionary] enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSDictionary<NSString *,IESGurdInactiveCacheMeta *> *obj, BOOL *stop) {
            __block NSInteger accessKeyResourceUsage = 0;
            [obj enumerateKeysAndObjectsUsingBlock:^(NSString *channel, IESGurdInactiveCacheMeta *obj, BOOL *stop) {
                GURD_TIK;
                NSInteger inactiveResourceUsage = [IESGurdFilePaths fileSizeAtDirectory:[IESGurdFilePaths inactivePathForAccessKey:accessKey channel:channel]];
                NSInteger cost = GURD_TOK;
                accessKeyResourceUsage += inactiveResourceUsage;
                
                [self uploadResourceInfo:accessKey
                                channel:channel
                                cost:cost
                                activeResourceUsage:0
                                inactiveResourceUsage:inactiveResourceUsage
                                backupResourceUsage:0];
            }];
            
            geckoTotalResourceUsage += accessKeyResourceUsage;
            IESGurdResourceInfoModel *resourceInfoModel = resourceInfoModelDictionary[accessKey];
            if (!resourceInfoModel) {
                resourceInfoModel = [[IESGurdResourceInfoModel alloc] init];
                resourceInfoModelDictionary[accessKey] = resourceInfoModel;
            }
            resourceInfoModel.accessKeyResourceUsage += accessKeyResourceUsage;
            resourceInfoModel.channelCount += (int)[obj count];
        }];
        
        [self uploadResourceInfoToTea:resourceInfoModelDictionary
                            geckoTotalResourceUsage:geckoTotalResourceUsage];
    });
}

/**
 *上传 resource info 到slardar平台
 */
- (void)uploadResourceInfo:(NSString *)accessKey
                    channel:(NSString *)channel
                    cost:(NSInteger)cost
                    activeResourceUsage:(NSInteger)activeResourceUsage
                    inactiveResourceUsage:(NSInteger)inactiveResourceUsage
                    backupResourceUsage:(NSInteger)backupResourceUsage
{
    NSInteger totalResourceUsage = inactiveResourceUsage + backupResourceUsage + activeResourceUsage;
    NSDictionary *category = @{ @"access_key": accessKey ? : @"",
                                @"channel" : channel ? : @"" };
    NSDictionary *metric = @{ @"cost": @(cost),
                              @"active_resource_usage": @(activeResourceUsage),
                              @"inactive_resource_usage": @(inactiveResourceUsage),
                              @"backup_resource_usage": @(backupResourceUsage),
                              @"total_resource_usage": @(totalResourceUsage)
    };
    [[IESGurdMonitorManager sharedManager] monitorEvent:@"geckosdk_resource_info"
                                               category:category
                                                 metric:metric
                                                  extra:nil];
}

/**
 *上传 resource info 到tea平台
 */
- (void)uploadResourceInfoToTea:(NSDictionary *)resourceInfoModelDictionary
                   geckoTotalResourceUsage:(NSInteger)geckoTotalResourceUsage
{
    [resourceInfoModelDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, IESGurdResourceInfoModel *resourceInfoModel, BOOL *stop) {
        [IESGurdAppLogger recordResourceInfoWithAccessKey:accessKey
                                   accessKeyResourceUsage:resourceInfoModel.accessKeyResourceUsage
                                             channelCount:resourceInfoModel.channelCount
                                  geckoTotalResourceUsage:geckoTotalResourceUsage];
    }];
}

@end
