//
//  IESGurdByteSyncMessageManager.m
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/10/23.
//

#import "IESGurdByteSyncMessageManager.h"

#import "IESGurdKit+ByteSync.h"
#import "IESGurdEventTraceManager+Message.h"
#import "IESGurdAppLogger.h"
#import "IESGurdFetchResourcesParams.h"
#import "IESGurdPackagesNormalRequest.h"
#import "IESGeckoAPI.h"
#import "IESGurdResourceManager+MultiAccessKey.h"
#import "IESGurdLazyResourcesManager.h"
#import "IESGurdCachePackageModelsManager.h"
#import "IESGurdChannelUsageMananger.h"

static NSMutableDictionary *kIESGurdCustomValueBlocksDictionary = nil;

@interface IESGurdResourceModel (ByteSync)
+ (instancetype)modelWithByteSyncDictionary:(NSDictionary *)dictionary;
@end

@implementation IESGurdByteSyncMessageManager

#pragma mark - Public

+ (int32_t)businessIdWithType:(IESGurdByteSyncBusinessType)type
{
    switch (type) {
        case IESGurdByteSyncBusinessTypeRelease: {
            return 8;
        }
        case IESGurdByteSyncBusinessTypeBOE: {
            return 57;
        }
    }
    NSAssert(NO, @"Invalid business type for byte sync");
    return -1;
}

+ (void)registerCustomParamKey:(NSString *)key
                 getValueBlock:(IESGurdByteSyncCustomParamGetValueBlock)getValueBlock
                  forAccessKey:(NSString *)accessKey
{
    if (key.length == 0 || accessKey.length == 0 || !getValueBlock) {
        return;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kIESGurdCustomValueBlocksDictionary = [NSMutableDictionary dictionary];
    });
    @synchronized (kIESGurdCustomValueBlocksDictionary) {
        NSMutableDictionary *blocks = kIESGurdCustomValueBlocksDictionary[accessKey];
        if (!blocks) {
            blocks = [NSMutableDictionary dictionary];
            kIESGurdCustomValueBlocksDictionary[accessKey] = blocks;
        }
        blocks[key] = getValueBlock;
    }
}

+ (void)handleMessageDictionary:(NSDictionary *)messageDictionary
{
    if (![messageDictionary isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    NSInteger timestamp = [messageDictionary[@"timestamp"] integerValue];
    BOOL shouldHandle = [IESGurdKit shouldHandleByteSyncMessageWithTimestamp:timestamp];
    
    [self recordStatsWithMessageDictionary:messageDictionary
                              shouldHandle:shouldHandle];
    
    if (!shouldHandle) {
        return;
    }
    
    NSDictionary *dataDictionary = messageDictionary[@"data"];
    if (![dataDictionary isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSInteger messageType = [messageDictionary[@"msg_type"] integerValue];
    int taskId = [messageDictionary[@"sync_task_id"] intValue];
    switch (messageType) {
        case 1: {
            [self handleCheckUpdateMessage:dataDictionary taskId:taskId];
            break;
        }
        case 2: {
            [self handleClearCacheMessage:dataDictionary taskId:taskId];
            break;
        }
        case 3: {
            [self handleDownloadPackagesMessage:dataDictionary taskId:taskId];
            break;
        }
    }
    
    NSString *message = [NSString stringWithFormat:@"【ByteSync】Receive message : %@", [messageDictionary description]];
    [IESGurdEventTraceManager traceEventWithMessage:message hasError:NO shouldLog:YES];
}

#pragma mark - Private

+ (void)recordStatsWithMessageDictionary:(NSDictionary *)messageDictionary
                            shouldHandle:(BOOL)shouldHandle
{
    NSInteger syncStatsType = shouldHandle ? 1 : 2;
    NSInteger taskId = [messageDictionary[@"sync_task_id"] integerValue];
    NSInteger messageType = [messageDictionary[@"msg_type"] integerValue];
    [IESGurdAppLogger recordStatsWithSyncStatusType:syncStatsType
                                             taskId:taskId
                                           taskType:messageType];
}

+ (void)handleCheckUpdateMessage:(NSDictionary *)messageDictionary taskId:(int)taskId
{
    NSDictionary *checkUpdateInfoDictionary = messageDictionary[@"check_update_info"];
    if (![checkUpdateInfoDictionary isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSDictionary *configDictionary = checkUpdateInfoDictionary[@"config"];
    if (![configDictionary isKindOfClass:[NSDictionary class]]) {
        return;
    }
    if (configDictionary.count == 0) {
        return;
    }
    
    IESGurdPackagesNormalRequest *request = [[IESGurdPackagesNormalRequest alloc] init];
    request.requestType = IESGurdPackagesConfigRequestTypeByteSync;
    request.syncTaskId = taskId;
    request.modelActivePolicy = IESGurdPackageModelActivePolicyFilterLazy;
    
    [configDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSDictionary *config, BOOL *stop) {
        IESGurdFetchResourcesParams *params = [[IESGurdFetchResourcesParams alloc] init];
        params.accessKey = accessKey;
        
        BOOL requestTargetChannels = NO;
        NSArray *targetChannels = config[@"target_chs"];
        if ([targetChannels isKindOfClass:[NSArray class]]) {
            if (targetChannels.count > 0) {
                params.channels = targetChannels;
                requestTargetChannels = YES;
            }
        }
        if (!requestTargetChannels) {
            params.groupName = config[@"group"];
        }
        
        if (kIESGurdCustomValueBlocksDictionary.count > 0) {
            NSArray<NSString *> *customParamKeys = config[@"custom_keys"];
            NSMutableDictionary *customParams = [NSMutableDictionary dictionary];
            [customParamKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
                @synchronized (kIESGurdCustomValueBlocksDictionary) {
                    NSMutableDictionary *blocks = kIESGurdCustomValueBlocksDictionary[accessKey];
                    if (blocks.count == 0) {
                        return;
                    }
                    IESGurdByteSyncCustomParamGetValueBlock block = blocks[key];
                    if (!block) {
                        return;
                    }
                    NSString *value = block();
                    if (value.length == 0) {
                        return;
                    }
                    customParams[key] = value;
                }
            }];
            if (customParams.count > 0) {
                params.customParams = [customParams copy];
            }
        }
        [request updateConfigWithParams:params];
    }];
    
    [IESGurdResourceManager fetchConfigWithURLString:[IESGurdAPI packagesInfo]
                              multiAccessKeysRequest:request];
}

+ (void)handleClearCacheMessage:(NSDictionary *)messageDictionary taskId:(int)taskId
{
    NSDictionary *cleanInfoDictionary = messageDictionary[@"clean_info"];
    if (![cleanInfoDictionary isKindOfClass:[NSDictionary class]]) {
        return;
    }
    if (cleanInfoDictionary.count == 0) {
        return;
    }
    [IESGurdKit clearCacheWithCleanInfoDictionary:cleanInfoDictionary taskId:taskId];
}

+ (void)handleDownloadPackagesMessage:(NSDictionary *)messageDictionary taskId:(int)taskId
{
    NSDictionary *downloadInfoDictionary = messageDictionary[@"download_info"];
    if (![downloadInfoDictionary isKindOfClass:[NSDictionary class]]) {
        return;
    }
    if (downloadInfoDictionary.count == 0) {
        return;
    }
    [downloadInfoDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSArray<NSDictionary *> *packagesArray, BOOL *stop) {
        NSMutableArray *modelsArray = [NSMutableArray array];
        [packagesArray enumerateObjectsUsingBlock:^(NSDictionary *packagesDictionary, NSUInteger idx, BOOL *stop) {
            IESGurdResourceModel *model = [IESGurdResourceModel modelWithByteSyncDictionary:packagesDictionary];
            if (!model) {
                return;
            }
            
            uint64_t packageVersion = [IESGurdKit packageVersionForAccessKey:accessKey channel:model.channel];
            if (model.version != packageVersion) {
                model.accessKey = accessKey;
                model.onDemand = [[IESGurdLazyResourcesManager sharedManager] isLazyChannel:accessKey channel:model.channel];
                // 始终按需没法读到，写死为NO
                model.alwaysOnDemand = NO;
                BOOL isLazy = [[IESGurdLazyResourcesManager sharedManager] isLazyResourceWithModel:model];
                if (isLazy) {
                    IESGurdCachePackageInfo *info = [[IESGurdCachePackageModelsManager sharedManager] packageInfoWithAccessKey:accessKey channel:model.channel];
                    if (!info.model.version || info.model.version != model.version) {
                        // 仅在version改变的时候才添加到cache，因为一般冷启请求队列就会有这些缓存了，那里能支持增量
                        [[IESGurdCachePackageModelsManager sharedManager] addModel:model];
                    }
                } else {
                    [modelsArray addObject:model];
                }
            }
        }];
        [IESGurdKit downloadResourcesWithModelsArray:[modelsArray copy] taskId:taskId];
    }];
}

@end

@implementation IESGurdResourceModel (ByteSync)

+ (instancetype)modelWithByteSyncDictionary:(NSDictionary *)dictionary
{
    NSString *channel = dictionary[@"channel"];
    uint64_t version = [dictionary[@"version"] unsignedLongLongValue];
    uint64_t packageID = [dictionary[@"id"] unsignedLongLongValue];
    NSString *md5String = dictionary[@"md5"];
    NSInteger packageType = [dictionary[@"package_type"] integerValue];
    if (channel.length == 0 ||
        version == 0 ||
        packageID == 0 ||
        md5String.length == 0) {
        return nil;
    }
    IESGurdResourceURLInfo *URLInfo = [[IESGurdResourceURLInfo alloc] init];
    if(![URLInfo parseUrlList:dictionary[@"url"]]) {
        return nil;
    }
    URLInfo.ID = packageID;
    URLInfo.md5 = md5String;
    
    IESGurdResourceModel *model = [[self alloc] init];
    model.channel = channel;
    model.version = version;
    model.package = URLInfo;
    model.packageType = packageType;
    model.retryDownload = YES;
    return model;
}

@end
