//
//  IESGurdLazyResourcesManager.m
//  Aspects
//
//  Created by 陈煜钏 on 2021/6/9.
//

#import "IESGurdLazyResourcesManager.h"

#import "IESGeckoDefines+Private.h"
#import "IESGurdSettingsRequestMeta.h"
#import "IESGurdSettingsManager.h"
#import "IESGurdFetchResourcesResult.h"
#import "IESGurdDownloadPackageManager+Business.h"
#import "IESGurdProtocolDefines.h"
#import "IESGurdDelegateDispatcherManager.h"
#import "IESGurdLazyResourcesInfo.h"
#import "IESGurdMultiAccessKeysRequest.h"
#import "IESGeckoResourceModel+DownloadPriority.h"
#import "IESGurdCachePackageModelsManager.h"
#import "IESGurdChannelUsageMananger.h"
#import "IESGurdKit+Experiment.h"
#import "IESGurdAppLogger.h"
#import <objc/runtime.h>

@implementation IESGurdLazyResourcesManager

#pragma mark - Public

+ (instancetype)sharedManager
{
    static IESGurdLazyResourcesManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (BOOL)isLazyResourceWithModel:(IESGurdResourceModel *)model
{
    if (!IESGurdKit.enableOnDemand) return NO;
    if (!model.onDemand) return NO;

    if (!model.alwaysOnDemand && [IESGurdChannelUsageMananger isChannelUsed:model.accessKey channel:model.channel]) {
        // 非始终按需，且已经消费过时，按照普通channel更新，将缓存的按需信息清理掉
        [[IESGurdCachePackageModelsManager sharedManager] removeModel:model];
        return NO;
    }
    return YES;
}

- (BOOL)isLazyChannel:(NSString *)accesskey channel:(NSString *)channel
{
    if (!IESGurdKit.enableOnDemand) return NO;
    
    IESGurdSettingsRequestMeta *requestMeta = [IESGurdSettingsManager sharedInstance].settingsResponse.requestMeta;
    NSArray<NSString *> *channels = requestMeta.lazyResourceInfosDictionary[accesskey].channels;
    return [channels containsObject:channel];
}

- (IESGurdLazyResourcesInfo *)lazyResourceInfoWithAccesskey:(NSString *)accessKey channel:(NSString *)channel
{
    @synchronized (self) {
        IESGurdLazyResourcesInfo *info = [[IESGurdLazyResourcesInfo alloc] init];
        // 默认为 new version
        info.status = IESGurdLazyResourceStatusNewVersion;
        
        IESGurdCachePackageInfo *packageInfo = [[IESGurdCachePackageModelsManager sharedManager] packageInfoWithAccessKey:accessKey
                                                                                                                  channel:channel];
        IESGurdResourceModel *model = packageInfo.model;
        IESGurdActivePackageMeta *metadata = packageInfo.metadata;
                
        if (model) {
            // 如果有 model，取 model 里的 id 和 size
            info.packageID = model.package.ID;
            info.packageSize = model.package.packageSize;
            // 如果 model 和本地 meta 的 packageid 一致，则为最新
            if (info.packageID == metadata.packageID && info.packageID > 0) {
                info.status = IESGurdLazyResourceStatusLazyResourceAlreadyNewest;
            }
        } else {
            info.status = metadata.packageID > 0
            ? IESGurdLazyResourceStatusNotLazyButExist
            : IESGurdLazyResourceStatusNotLazyResources;
            // 如果无 model，取本地 meta 里的 id 和 size
            info.packageID = metadata.packageID;
            info.packageSize = metadata.packageSize;
        }
        
        return info;
    }
}

- (NSArray<IESGurdResourceModel *> *)modelsToDownloadWithParams:(IESGurdFetchResourcesParams *)params
{
    NSMutableSet<IESGurdCachePackageInfo *> *packageInfosSet = [NSMutableSet set];
    
    IESGurdCachePackageModelsManager *packageModelsManager = [IESGurdCachePackageModelsManager sharedManager];
    if (params.groupName.length > 0) {
        NSArray<IESGurdCachePackageInfo *> *packageInfos = [packageModelsManager packageInfosWithAccessKey:params.accessKey group:params.groupName];
        [packageInfosSet addObjectsFromArray:packageInfos];
    }
    
    NSString *channelsNoCache = @"";
    for (NSString *channel in params.channels) {
        IESGurdCachePackageInfo *packageInfo = [packageModelsManager packageInfoWithAccessKey:params.accessKey channel:channel];
        if (packageInfo) {
            [packageInfosSet addObject:packageInfo];
        }
        if (!packageInfo.model) {
            // 没有这个channel的缓存信息时，有可能是没有新包，也有可能是meta信息还没回来
            // 本地有版本时，就不上报这个埋点了
            if ([IESGurdKit packageVersionForAccessKey:params.accessKey channel:channel] == 0) {
                channelsNoCache = [channelsNoCache stringByAppendingFormat:@"%@,", channel];
            }
        }
    }
    if (channelsNoCache.length > 0) {
        [IESGurdAppLogger recordEventWithType:IESGurdAppLogEventTypeOnDemand
                                      subtype:IESGurdAppLogEventSubtypeOnDemandNoCache
                                       params:nil
                                    extraInfo:nil
                                 errorMessage:@"No update meta for the channel on demand"
                                    accessKey:params.accessKey
                                     channels:channelsNoCache];
    }
    
    NSMutableSet<IESGurdResourceModel *> *models = [NSMutableSet set];
    [packageInfosSet enumerateObjectsUsingBlock:^(IESGurdCachePackageInfo *packageInfo, BOOL *stop) {
        if (packageInfo.status != IESGurdCachePackageStatusNewVersion) {
            return;
        }
        IESGurdResourceModel *model = packageInfo.model;
        model.retryDownload = params.retryDownload;
        model.downloadPriority = params.downloadPriority;
        model.forceDownload = YES;
        
        [models addObject:model];
    }];
    return [models copy];
}

@end
