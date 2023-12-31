//
//  IESGurdResourceManager+MultiAccessKey.m
//  BDAssert
//
//  Created by 陈煜钏 on 2020/11/10.
//

#import "IESGurdResourceManager+MultiAccessKey.h"

#import "IESGurdKit+Experiment.h"
#import "IESGeckoAPI.h"
#import "IESGeckoDefines+Private.h"
#import "IESGurdProtocolDefines.h"
#import "IESGurdResourceManager+Business.h"
#import "IESGurdDownloadPackageManager+Business.h"
#import "IESGurdResourceMetadataStorage.h"
#import "IESGurdSyncResourcesGroup.h"
#import "IESGurdDelegateDispatcherManager.h"
#import "IESGurdLazyResourcesManager.h"
#import "IESGurdChannelBlocklistManager.h"
#import "IESGeckoResourceModel+DownloadPriority.h"
#import "IESGurdLogProxy.h"
#import "IESGurdExpiredCacheManager.h"
#import "IESGurdAppLogger.h"
#import "IESGurdCachePackageModelsManager.h"
#import "IESGurdPackagesExtraManager.h"
#import "IESGurdKitUtil.h"

#import "UIApplication+IESGurdKit.h"

@implementation IESGurdResourceManager (MultiAccessKey)

+ (void)fetchConfigWithURLString:(NSString *)URLString
          multiAccessKeysRequest:(IESGurdMultiAccessKeysRequest *)request
{
    if (![request isParamsValid]) {
        NSDictionary<NSString *, IESGurdSyncStatusDictionaryBlock> *requestCompletions = [request requestCompletions];
        [requestCompletions enumerateKeysAndObjectsUsingBlock:^(NSString *identifier, IESGurdSyncStatusDictionaryBlock completion, BOOL * stop) {
            dispatch_queue_async_safe(dispatch_get_main_queue(), ^{
                !completion ? : completion(YES, IESGurdMakePlaceHolder(IESGurdSyncStatusParameterEmpty));
            });
        }];
        return;
    }
    
    IESGurdPackagesConfigCompletion completion = ^(IESGurdSyncStatus status, IESGurdPackagesConfigResponse * _Nullable response) {
        NSArray<IESGurdResourceModel *> *packagesArray = [self packagesArrayWithResponse:response request:request];
        [self gurdDidFetchConfigWithPackagesArray:packagesArray request:request];
        
        NSMutableArray<IESGurdResourceModel *> *filteredPackagesArray = [packagesArray mutableCopy];
        void (^filterModel)(IESGurdResourceModel *) = ^(IESGurdResourceModel *model) {
            [filteredPackagesArray removeObject:model];
            [[IESGurdCachePackageModelsManager sharedManager] addModel:model];
        };
        
        BOOL filterLazy = (request.modelActivePolicy == IESGurdPackageModelActivePolicyFilterLazy);
        
        BOOL filterBlocklist = [IESGurdExpiredCacheManager sharedManager].clearExpiredCacheEnabled;
        NSMutableArray<NSString *> *channelsInBlocklist = filterBlocklist ? [NSMutableArray array] : nil;
        
        [packagesArray enumerateObjectsUsingBlock:^(IESGurdResourceModel *model, NSUInteger idx, BOOL *stop) {
            NSString *accessKey = model.accessKey;
            NSString *channel = model.channel;
            
            // 过滤按需加载的资源
            if (filterLazy) {
                if ([[IESGurdLazyResourcesManager sharedManager] isLazyResourceWithModel:model]) {
                    filterModel(model);
                }
            }
            
            // 过滤黑名单资源
            if (filterBlocklist) {
                NSString *targetGroup = [IESGurdExpiredCacheManager sharedManager].targetGroupDictionary[accessKey];
                if (targetGroup.length == 0) {
                    return;
                }
                if (![[IESGurdChannelBlocklistManager sharedManager] isBlocklistChannel:channel accessKey:accessKey]) {
                    return;
                }
                if ([model.groups containsObject:targetGroup]) {
                    filterModel(model);
                    [channelsInBlocklist addObject:channel];
                } else {
                    [[IESGurdChannelBlocklistManager sharedManager] removeChannel:channel forAccessKey:accessKey];
                }
            }
            
            if ([IESGurdKit isChannelLocked:model.accessKey channel:model.channel]) {
                [filteredPackagesArray removeObject:model];
            }
        }];
        
        if (channelsInBlocklist.count > 0) {
            IESGurdLogInfo(@"Filter download channels in blocklist : %@", [channelsInBlocklist componentsJoinedByString:@"、"]);
        }
        
        if (filteredPackagesArray.count == 0 && response.appLogParams) {
            // 筛选后没有需要更新的资源时，上报query_pkgs
            [IESGurdAppLogger recordQueryPkgsStats:response.appLogParams];
        }
        
        [self downloadResourcesWithRequest:request
                             packagesArray:[filteredPackagesArray copy]];
    };
    NSDictionary *params = [request paramsForRequest];
    if (!params) {
        [IESGurdAppLogger recordQueryPkgsStats:@{
            @"is_intercept": @(1),
            @"err_code": @(800),
            @"err_msg": @"not available storage"
        }];
        NSDictionary<NSString *, IESGurdSyncStatusDictionaryBlock> *requestCompletions = [request requestCompletions];
        [requestCompletions enumerateKeysAndObjectsUsingBlock:^(NSString *identifier, IESGurdSyncStatusDictionaryBlock completion, BOOL * stop) {
            dispatch_queue_async_safe(dispatch_get_main_queue(), ^{
                !completion ? : completion(NO, IESGurdMakePlaceHolder(IESGurdSyncStatusNoAvailableStorage));
            });
        }];
//        [[IESGurdExpiredCacheManager sharedManager] clearCacheWhenLowStorage];
        return;
    }
    
    [IESGurdResourceManager requestConfigWithURLString:URLString
                                                params:params
                                               logInfo:[request logInfo]
                                            completion:completion];
}

+ (void)downloadResourcesWithRequest:(IESGurdMultiAccessKeysRequest *)request
                       packagesArray:(NSArray<IESGurdResourceModel *> *)packagesArray
{
    NSDictionary<NSString *, IESGurdSyncStatusDictionaryBlock> *requestCompletions = [request requestCompletions];
    NSMutableDictionary<NSString *, IESGurdSyncResourcesGroup *> *groupsDictionary = [NSMutableDictionary dictionary];
    [packagesArray enumerateObjectsUsingBlock:^(IESGurdResourceModel *model, NSUInteger idx, BOOL *stop) {
        // 是否强制下载
        model.forceDownload = request.forceDownload;
        
        NSArray<NSString *> *businessIdentifiers = model.businessIdentifiers;
        for (NSString *identifier in businessIdentifiers) {
            IESGurdSyncResourcesGroup *group = groupsDictionary[identifier];
            IESGurdSyncStatusDictionaryBlock completion = requestCompletions[identifier];
            if (!group && completion) {
                // 给需要回调的业务方创建 group
                group = [IESGurdSyncResourcesGroup groupWithCompletion:completion];
                groupsDictionary[identifier] = group;
            }
            [group enter];
        }
    }];
    
    [requestCompletions enumerateKeysAndObjectsUsingBlock:^(NSString *identifier, IESGurdSyncStatusDictionaryBlock completion, BOOL * stop) {
        if (!groupsDictionary[identifier]) {
            // 无需下载的业务方直接回调
            dispatch_queue_async_safe(dispatch_get_main_queue(), ^{
                !completion ? : completion(YES, IESGurdMakePlaceHolder(IESGurdSyncStatusServerPackageUnavailable));
            });
        }
    }];
    
    IESGurdDownloadResourceCallback callback = ^(IESGurdResourceModel *model, BOOL succeed, IESGurdSyncStatus status) {
        dispatch_queue_async_safe(dispatch_get_main_queue(), ^{
            NSArray<NSString *> *businessIdentifiers = model.businessIdentifiers;
            for (NSString *identifier in businessIdentifiers) {
                // 通知各个业务方该 channel 下载激活完成
                IESGurdSyncResourcesGroup *group = groupsDictionary[identifier];
                [group leaveWithChannel:model.channel isSuccessful:succeed status:status];
            }
        });
    };
    [IESGurdDownloadPackageManager downloadResourcesWithModels:packagesArray
                                           logInfo:[request logInfo]
                                          callback:callback];
    
    [groupsDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *identifier, IESGurdSyncResourcesGroup *group, BOOL *stop) {
        [group notifyWithBlock:nil];
    }];
}

+ (void)downloadLazyResources:(NSArray<IESGurdResourceModel *> *)packagesArray
                   completion:(IESGurdSyncStatusDictionaryBlock)completion
{
    if (packagesArray.count == 0) {
        // 无需下载的业务方直接回调
        !completion ? : completion(YES, IESGurdMakePlaceHolder(IESGurdSyncStatusServerPackageUnavailable));
        return;
    }
    
    IESGurdSyncResourcesGroup *group = [IESGurdSyncResourcesGroup groupWithCompletion:completion];
    [packagesArray enumerateObjectsUsingBlock:^(IESGurdResourceModel *model, NSUInteger idx, BOOL *stop) {
        [group enter];
    }];
    
    IESGurdDownloadResourceCallback callback = ^(IESGurdResourceModel *model, BOOL succeed, IESGurdSyncStatus status) {
        dispatch_queue_async_safe(dispatch_get_main_queue(), ^{
            [group leaveWithChannel:model.channel isSuccessful:succeed status:status];
        });
    };
    
    [IESGurdDownloadPackageManager downloadResourcesWithModels:packagesArray
                                                       logInfo:@{ @"req_type" : @(IESGurdPackagesConfigRequestTypeLazy) }
                                                      callback:callback];
    
    [group notifyWithBlock:nil];
}

+ (NSArray<IESGurdResourceModel *> *)packagesArrayWithResponse:(IESGurdPackagesConfigResponse *)response
                                                       request:(IESGurdMultiAccessKeysRequest *)request
{
    NSArray *packages = response.packages;
    if (![packages isKindOfClass:[NSArray class]]) {
        return @[];
    }
    NSDictionary<NSString *, NSNumber *> *downloadPrioritiesMap = [request downloadPrioritiesMap];
    NSMutableArray *packagesArray = [NSMutableArray array];
    [packages enumerateObjectsUsingBlock:^(NSDictionary *config, NSUInteger idx, BOOL *stop) {
        IESGurdResourceModel *model = [IESGurdResourceModel instanceWithDict:config local:response.local logId:response.logId];
        if (model) {
            [model updateDownloadPriorityWithDownloadPrioritiesMap:downloadPrioritiesMap];
            model.retryDownload = request.retryDownload;
            [packagesArray addObject:model];
        }
    }];
    if (packages.count > 0) {
        [[IESGurdPackagesExtraManager sharedManager] saveToFile];
    }
    return [packagesArray copy];
}

+ (void)gurdDidFetchConfigWithPackagesArray:(NSArray<IESGurdResourceModel *> *)packagesArray
                                    request:(IESGurdMultiAccessKeysRequest *)request
{
    NSMutableDictionary<NSString *, NSMutableDictionary *> *statusDictionary = [NSMutableDictionary dictionary];
    [[request targetChannelsMap] enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSArray<NSString *> *channels, BOOL *stop) {
        NSMutableDictionary *configsDictionary = [NSMutableDictionary dictionary];
        [channels enumerateObjectsUsingBlock:^(NSString *channel, NSUInteger idx, BOOL *stop) {
            uint64_t localVersion = [IESGurdResourceMetadataStorage activeMetaForAccessKey:accessKey channel:channel].version;
            configsDictionary[channel] = (localVersion == 0) ?
            @(IESGurdRequestChannelConfigStatusNotFound) : @(IESGurdRequestChannelConfigStatusLatestVersion);
        }];
        statusDictionary[accessKey] = configsDictionary;
    }];
    [packagesArray enumerateObjectsUsingBlock:^(IESGurdResourceModel *model, NSUInteger idx, BOOL *stop) {
        if (model.accessKey.length == 0 || model.channel.length == 0) {
            return;
        }
        NSMutableDictionary *configsDictionary = statusDictionary[model.accessKey];
        configsDictionary[model.channel] = @(IESGurdRequestChannelConfigStatusNewVersion);
    }];
    [statusDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSMutableDictionary *configsDictionary, BOOL *stop) {
        [DELEGATE_DISPATCHER(IESGurdEventDelegate) gurdDidRequestConfigForAccessKey:accessKey
                                                                  configsDictionary:[configsDictionary copy]];
    }];
}

@end
