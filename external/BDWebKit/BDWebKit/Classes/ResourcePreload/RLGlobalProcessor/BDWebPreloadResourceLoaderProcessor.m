
//
//  BDWebPreloadResourceLoaderProcessor.m
//
//  Created by wuyuqi on 2022/06/27.
//

#import "BDWebPreloadResourceLoaderProcessor.h"

#import <BDALogProtocol/BDALogProtocol.h>
#import <BDWebKit/BDWebContentPreloadManager.h>
#import <BDPreloadSDK/BDPreloadCachedResponse.h>
#import <BDXResourceLoader/NSError+BDXRL.h>
#import <BDXResourceLoader/NSData+BDXSource.h>
#import <BDXResourceLoader/BDXResourceProvider.h>
#import <BDXResourceLoader/BDXResourceLoaderMetricModel.h>

static NSString * const kPreloadResourceLoaderName = @"Web Preload Processor";

static NSString * const kLogTag = @"BDWebPreloadResourceLoaderProcessor";

#pragma mark BDWebPreloadResourceLoaderProcessor

@interface BDWebPreloadResourceLoaderProcessor ()

@end

@implementation BDWebPreloadResourceLoaderProcessor

- (NSString *)resourceLoaderName
{
    return kPreloadResourceLoaderName;
}

/// @abstract 在此方法中Processor具体实现获取资源的逻辑.
/// @param url  资源url
/// @param container  当前所在容器，可以为空
/// @param loaderConfig  加载配置
/// @param taskConfig  任务配置
/// @param resolveHandler  获取成功
/// @param rejectHandler  获取失败
- (void)fetchResourceWithURL:(NSString *)url container:(UIView *__nullable)container loaderConfig:(BDXResourceLoaderConfig *__nullable)loaderConfig taskConfig:(BDXResourceLoaderTaskConfig *__nullable)taskConfig resolve:(BDXResourceLoaderResolveHandler)resolveHandler reject:(BDXResourceLoaderRejectHandler)rejectHandler
{
    [self fetchResourceWithURL:url loaderConfig:loaderConfig taskConfig:taskConfig resolve:resolveHandler reject:rejectHandler];
}

- (void)fetchResourceWithURL:(NSString *)url loaderConfig:(BDXResourceLoaderConfig *__nullable)loaderConfig taskConfig:(BDXResourceLoaderTaskConfig *__nullable)taskConfig resolve:(BDXResourceLoaderResolveHandler)resolveHandler reject:(BDXResourceLoaderRejectHandler)rejectHandler
{
    if ([url hasPrefix:@"about://waitfix"]) {
        BDALOG_PROTOCOL_INFO_TAG(kLogTag, @"BDWebPreloadResourceLoaderProcessor do not support about-waitfix for %@", url);
        if (rejectHandler) {
            rejectHandler([NSError errorWithCode:BDXRLErrorCodeNoData message:@"BDW Preload do not handle about://waitfix"]);
        }
        return;
    }
    
    double startTime = [[NSDate date] timeIntervalSince1970] * 1000;
    BDPreloadCachedResponse *response = [BDWebContentPreloadManager fetchWebResourceSync:url];
    double finishTime = [[NSDate date] timeIntervalSince1970] * 1000;
    if (response == nil || response.data == nil) {
        BDALOG_PROTOCOL_INFO_TAG(kLogTag, @"BDWebPreloadResourceLoaderProcessor no offline resource for %@", url);
        if (rejectHandler) {
            rejectHandler([NSError errorWithCode:BDXRLErrorCodeNoData message:@"BDW Preload no cache response data"]);
        }
        return;
    }
    
    /// ResourceLoader 不提供response code & header fields, check status code for cache-response
    /// BDPreloadSDK 默认禁止ttnet follow redirect, 因此存在非200的资源
    if (response.statusCode != 200) {
        BDALOG_PROTOCOL_INFO_TAG(kLogTag, @"BDWebPreloadResourceLoaderProcessor cache resource not 200 for %@", url);
        if (rejectHandler) {
            rejectHandler([NSError errorWithCode:BDXRLErrorCodeNoData message:@"BDW Preload no cache response data"]);
        }
        return;
    }
    
    BDXResourceProvider *resourceProvider = [BDXResourceProvider resourceWithURL:url];
    resourceProvider.res_originSourceURL = url;
    
    resourceProvider.res_originSourceURL = url;
    resourceProvider.res_sourceURL = url;
    resourceProvider.res_cdnUrl = url;
    resourceProvider.res_Data = response.data;
    resourceProvider.res_localPath = nil;
    resourceProvider.res_sourceFrom = BDXResourceStatusCdnCache;
    resourceProvider.readTemplateLocalStart = 0;
    resourceProvider.readTemplateLocalEnd = 0;
    resourceProvider.downloadResourceEnd = 0;
    resourceProvider.downloadResourceStart = 0;
    
    resourceProvider.metricInfo.memory_start = startTime;
    resourceProvider.metricInfo.memory_finish = finishTime;
    
    BDALOG_PROTOCOL_INFO_TAG(kLogTag, @"BDWebPreloadResourceLoaderProcessor find resource for %@", url);
    if (resolveHandler) {
        resolveHandler(resourceProvider, self.resourceLoaderName);
    }
}

/// @abstract
/// 取消下载，调用当前正在执行的Processor的cancel方法，并取消后续过程。
- (void)cancelLoad
{
    // TODO
    BDALOG_PROTOCOL_INFO_TAG(kLogTag, @"BDWebPreloadResourceLoaderProcessor call cancel load.");
}

@end
