//
//  BDXResourceLoaderGurdProcessor.m
//  BDXResourceLoader
//
//  Created by David on 2021/3/16.
//

#import "BDXRLGurdProcessor.h"

#import "BDXGurdSyncManager.h"
#import "BDXGurdSyncTask.h"
#import "BDXResourceLoader.h"
#import "BDXResourceProvider.h"
#import "NSData+BDXSource.h"
#import "NSError+BDXRL.h"

#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <IESGeckoKit/IESGeckoKit.h>
#import <IESGeckoKit/UIDevice+IESGeckoKit.h>
#import <IESGeckoKit/IESGurdInternalPackagesManager.h>
#import <IESGeckoKit/IESGurdKit+InternalPackages.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface BDXRLGurdProcessor ()

@end

@implementation BDXRLGurdProcessor

- (NSString *)resourceLoaderName
{
    return @"XDefaultGurdLoader";
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        //
    }
    return self;
}

- (void)fetchResourceWithURL:(NSString *)url container:(UIView *__nullable)container loaderConfig:(BDXResourceLoaderConfig *__nullable)loaderConfig taskConfig:(BDXResourceLoaderTaskConfig *__nullable)taskConfig resolve:(BDXResourceLoaderResolveHandler)resolveHandler reject:(BDXResourceLoaderRejectHandler)rejectHandler
{
    // sourceURL
    NSString *sourceURL = url;
    if (!BTD_isEmptyString([self.paramConfig sourceURL])) {
        // self.paramConfig中的sourceURL来自于对传入URL中参数的解析。如果不为空则优先使用
        sourceURL = [self.paramConfig sourceURL];
    }

    // warp返回回调
    @weakify(self);
    void (^warpResolveHandler)(id<BDXResourceProtocol> resourceProvider) = ^(id<BDXResourceProtocol> resourceProvider) {
        @strongify(self);
        if (resolveHandler && !self.isCanceled) {
            resolveHandler(resourceProvider, [self resourceLoaderName]);
        }
    };
    void (^warpRejectHandler)(BDXRLErrorCode code, NSString *message) = ^(BDXRLErrorCode code, NSString *message) {
        @strongify(self);
        if (rejectHandler && !self.isCanceled) {
            rejectHandler([NSError errorWithCode:code message:message]);
        }
    };

    /// 确保Gecko的参数
    if (!BTD_isEmptyString([self.paramConfig channelName]) && !BTD_isEmptyString([self.paramConfig bundleName]) && !BTD_isEmptyString([self.paramConfig accessKey])) {
        if ([[self.paramConfig channelName] containsString:@"../"] || [[self.paramConfig bundleName] containsString:@"../"]) {
            warpRejectHandler(BDXRLErrorCodeGurdFaile, @"XDefaultGurdLoader path contains ../");
            return;
        }
        NSString *errorMessage = @"";
        switch ([self.paramConfig dynamic]) {
            case 0: {
                // dynamic = 0, 只读取Gecko本地
                BDXResourceProvider *resourceProvider = [self getProviderWith:sourceURL loaderConfig:loaderConfig];
                if (resourceProvider.resourceData) {
                    warpResolveHandler(resourceProvider);
                    return; // 成功 直接return
                } else {
                    errorMessage = @"XDefaultGurdLoader Dynamic is 0, but Gurd has no data";
                }
            } break;
            case 1: {
                // dynamic = 1, 读取Gecko(Falcon),
                // 若获取到数据则返回并且触发新数据同步，若未能获取数据则尝试新建GurdSyncTask拉取数据
                BDXResourceProvider *resourceProvider = [self getProviderWith:sourceURL loaderConfig:loaderConfig];
                if (resourceProvider.resourceData) {
                    warpResolveHandler(resourceProvider);
                    //若获取到数据则返回并且触发新数据同步
                    [self.advancedOperator syncChannelIfNeeded:[self.paramConfig channelName] accessKey:[self.paramConfig accessKey] completion:nil];
                    return; /// 直接return
                } else if ([self.paramConfig disableGurdUpdate] == NO) {
                    /// 若未能获取数据则尝试新建GurdSyncTask拉取数据
                    [self doTaskWith:sourceURL loaderConfig:loaderConfig container:container warpResolveHandler:warpResolveHandler warpRejectHandler:warpRejectHandler];
                    return; /// 直接return，成功或失败的回调交给doGurdSyncTask方法
                } else {
                    errorMessage = @"XDefaultGurdLoader Dynamic is 1, but Gurd has no data "
                                   @"and container is nil";
                }
            } break;
            case 2: {
                // dynamic = 2, 直接尝试新建GurdSyncTask拉取数据
                if ([self.paramConfig disableGurdUpdate] == NO) {
                    /// 若未能获取数据则尝试新建GurdSyncTask拉取数据
                    [self doTaskWith:sourceURL loaderConfig:loaderConfig container:container warpResolveHandler:warpResolveHandler warpRejectHandler:warpRejectHandler];
                    return; /// 直接return，成功或失败的回调交给doGurdSyncTask方法
                } else {
                    errorMessage = @"XDefaultGurdLoader Dynamic is 2, but container is nil";
                }
            } break;
            case 3: {
                // dynamic = 3, 读取Gecko(Falcon),并触发更新
                BDXResourceProvider *resourceProvider = [self getProviderWith:sourceURL loaderConfig:loaderConfig]; // 获取数据
                [self.advancedOperator syncChannelIfNeeded:[self.paramConfig channelName] accessKey:[self.paramConfig accessKey] completion:nil]; // 触发更新
                
                if (resourceProvider.resourceData) {
                    warpResolveHandler(resourceProvider);
                    return; /// 直接return
                } else {
                    errorMessage = @"XDefaultGurdLoader Dynamic is 3, but Gurd has no data ";
                }
            } break;

            default:
                errorMessage = @"XDefaultGurdLoader Unkonw Dynamic Code";
                break;
        }
        warpRejectHandler(BDXRLErrorCodeGurdFaile, errorMessage);
    } else {
        warpRejectHandler(BDXRLErrorCodeGurdNoParams, @"XDefaultGurdLoader no channelName or bundleName or accessKey");
    }
}

- (BDXResourceProvider *)getProviderWith:(NSString *)sourceURL loaderConfig:(BDXResourceLoaderConfig *__nullable)loaderConfig
{
    NSString *accessKey = [self.paramConfig accessKey] ?: @"";
    NSString *channelName = [self.paramConfig channelName] ?: @"";
    NSString *bundleName = [self.paramConfig bundleName] ?: @"";
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    NSData *resourceData = nil;
    
    if ([self.paramConfig onlyPath]) {
        NSString *dirName = [IESGurdKit rootDirForAccessKey:accessKey channel:channelName];
        if ([bundleName hasPrefix:@"/"]) {
            dirName = [NSString stringWithFormat:@"%@%@", dirName, bundleName];
        } else {
            dirName = [NSString stringWithFormat:@"%@/%@", dirName, bundleName];
        }
        if ([[NSFileManager defaultManager] fileExistsAtPath:dirName]) {
            resourceData = [[NSData alloc] init]; // 不读取数据，构造一个非空的data对象
            resourceData.bdx_SourceFrom = BDXResourceStatusGecko;
        }
    } else {
        IESGurdDataAccessPolicy dataAccessPolicy = [IESGurdInternalPackagesManager dataAccessPolicyForAccessKey:accessKey channel:channelName];
        [IESGurdInternalPackagesManager updateDataAccessPolicy:IESGurdDataAccessPolicyNormal accessKey:accessKey channel:channelName];
        resourceData = [IESGeckoKit dataForPath:bundleName accessKey:accessKey channel:channelName];
        [IESGurdInternalPackagesManager updateDataAccessPolicy:dataAccessPolicy accessKey:accessKey channel:channelName];
        resourceData.bdx_SourceFrom = BDXResourceStatusGecko;
    }

    BDXResourceProvider *resourceProvider = [BDXResourceProvider new];
    resourceProvider.res_originSourceURL = sourceURL;
    resourceProvider.res_sourceURL = sourceURL;
    resourceProvider.res_Data = resourceData;
    resourceProvider.res_localPath = [[IESGurdKit rootDirForAccessKey:accessKey channel:channelName] stringByAppendingPathComponent:bundleName];
    resourceProvider.res_sourceFrom = BDXResourceStatusGecko;
    resourceProvider.res_bundleName = bundleName;
    resourceProvider.res_channelName = channelName;
    resourceProvider.res_accessKey = accessKey;
    if (!BTD_isEmptyString(accessKey) && !BTD_isEmptyString(channelName)) {
        resourceProvider.res_version = [IESGeckoKit packageVersionForAccessKey:accessKey channel:channelName];
    }
    CFTimeInterval loadDuration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000;
    if (resourceData.length > 0) {
        [[BDXResourceLoader monitor] reportWithEventName:@"geckosdk_resource_load_event" bizTag:nil commonParams:@{@"url": sourceURL ?: @""} metric:@{@"read_duration":@(loadDuration)} category:@{
            @"gecko_sdk_version":IESGurdKitSDKVersion() ?: @"unknown",
            @"access_key":[self.paramConfig accessKey] ?: @"unknown",
            @"channel":[self.paramConfig channelName] ?: @"unknown",
            @"aid": [BDXResourceLoader appid] ?: @"unknown",
            @"package_id":@(resourceProvider.res_version),
            @"path": [self.paramConfig bundleName] ?: @"unknown",
            @"from":@0
        } extra:nil platform:BDXMonitorReportPlatformLynx aid:@"1234" maySample:YES];
    }
    return resourceProvider;
}

- (void)doTaskWith:(NSString *)sourceURL loaderConfig:(BDXResourceLoaderConfig *__nullable)loaderConfig container:(UIView *)container warpResolveHandler:(void (^)(id<BDXResourceProtocol> resourceProvider))warpResolveHandler warpRejectHandler:(void (^)(BDXRLErrorCode code, NSString *message))warpRejectHandler
{
    @weakify(self);
    [BDXResourceLoader reportLog:[NSString stringWithFormat:@"resourceLoader == start gecko fetch , url : %@", sourceURL]];
    BDXGurdSyncTask *task = [BDXGurdSyncTask taskWithAccessKey:[self.paramConfig accessKey] ?: @"" groupName:nil channelsArray:@[[self.paramConfig channelName] ?: @""] completion:^(BDXGurdSyncResourcesResult *result) {
        @strongify(self);
        if ([self.paramConfig onlyLocal]) {
            return;
        }
        if (result.successfully) {
            BDXResourceProvider *resourceProvider = [self getProviderWith:sourceURL loaderConfig:loaderConfig];
            if (resourceProvider.resourceData) {
                /// 调用成功回
                [BDXResourceLoader reportLog:@"resourceLoader == gecko Sync success"];
                warpResolveHandler(resourceProvider);
            } else {
                warpRejectHandler(BDXRLErrorCodeGurdFaile, @"resourceLoader == gecko Sync success, but no data");
            }
            if (!resourceProvider.resourceData && container && [[NSStringFromClass(container.class) lowercaseString] containsString:@"lynx"]) {
                NSDictionary *category = @{
                    @"type": [NSString stringWithFormat:@"%ld", BDXRLFailedTypeGecko],
                    @"geckoStatus": [NSString stringWithFormat:@"%ld", BDXRLGeckoStatusReadLocalFail],
                };
                [[BDXResourceLoader monitor] reportWithEventName:@"bd_monitor_lynxResLoadError" bizTag:nil commonParams:@{@"url": sourceURL ?: @""} metric:nil category:category extra:nil platform:BDXMonitorReportPlatformLynx aid:@"" maySample:NO];
                [BDXResourceLoader reportError:[NSString stringWithFormat:@"lynxResLoadError : %@", sourceURL ?: @""]];
            }
        } else {
            NSString *errorMessage = [NSString stringWithFormat:@"resourceLoader == gecko fetch fail , url : %@", sourceURL];
            [BDXResourceLoader reportLog:errorMessage];
            /// 调用失败回调
            warpRejectHandler(BDXRLErrorCodeGurdFaile, errorMessage);
            if (container && [[NSStringFromClass(container.class) lowercaseString] containsString:@"lynx"]) {
                NSDictionary *category = @{
                    @"type": [NSString stringWithFormat:@"%ld", BDXRLFailedTypeGecko],
                    @"geckoStatus": [NSString stringWithFormat:@"%ld", BDXRLGeckoStatusDownloadFail],
                };
                [[BDXResourceLoader monitor] reportWithEventName:@"bd_monitor_lynxResLoadError" bizTag:nil commonParams:@{@"url": sourceURL ?: @""} metric:nil category:category extra:nil platform:BDXMonitorReportPlatformLynx aid:@"" maySample:NO];
                [BDXResourceLoader reportError:[NSString stringWithFormat:@"lynxResLoadError : %@", sourceURL ?: @""]];
            }
        }
    }];
    task.disableThrottle = YES; //doTaskWith 模式下不节流
    task.downloadPriority = loaderConfig.gurdDownloadPrority;
    task.pollingPriority = BDXGurdSyncResourcesPollingPriorityLevel1;

    if (task.disableThrottle) {
        task.options |= BDXGurdSyncResourcesOptionsDisableThrottle;
    } else {
        task.options &= ~BDXGurdSyncResourcesOptionsDisableThrottle;
    }
    [BDXGurdSyncManager enqueueSyncResourcesTask:task];
    if ([self.paramConfig onlyLocal]) {
        warpRejectHandler(BDXRLErrorCodeGurdFaile, @"data not found, case = only local");
    }
}

- (void)cancelLoad
{
    self.isCanceled = YES;
}

- (void)dealloc
{
    // do nothing
}

+ (void)deleteGurdCacheForResource:(id<BDXResourceProtocol>)resource
{
    if (BTD_isEmptyString([resource accessKey]) || BTD_isEmptyString([resource channel])) {
        return;
    }

    NSString *sourceURL = [resource originSourceURL];
    if (!BTD_isEmptyString([resource sourceUrl])) {
        sourceURL = [resource sourceUrl];
    }
    if ([resource cdnUrl]) {
        sourceURL = [resource cdnUrl];
    }
    if (BTD_isEmptyString(sourceURL)) {
        sourceURL = [NSString stringWithFormat:@"lynx:/%@/%@", [resource channel], [resource bundle]]; //是有可能为空的，此时赋个空字符串
    }

    NSString *state = @"failed";
    if ([IESGeckoKit rootDirForAccessKey:[resource accessKey] channel:resource.channel]) {
        [IESGeckoKit clearCacheForAccessKey:[resource accessKey] channel:resource.channel];
        state = @"succeed";
    } else {
        state = @"failed";
    }
    NSDictionary *category = @{@"type": @"gecko", @"delete_state": state};
    [[BDXResourceLoader monitor] reportWithEventName:@"bd_monitor_lynxLoadFailDeleteResource" bizTag:nil commonParams:@{@"url": sourceURL ?: @""} metric:nil category:category extra:nil platform:BDXMonitorReportPlatformLynx aid:@"" maySample:NO];
    [BDXResourceLoader reportLog:[NSString stringWithFormat:@"GurdLoadFailDeleteResource : %@", sourceURL]];
}

@end
