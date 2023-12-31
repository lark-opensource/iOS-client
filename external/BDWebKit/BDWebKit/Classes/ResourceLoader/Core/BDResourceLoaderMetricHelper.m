//
//  BDResourceLoaderMetricHelper.m
//  Aweme
//
//  Created by bytedance on 2022/5/19.
//

#import <BDXResourceLoader/BDXResourceProtocol.h>
#import <BDXResourceLoader/BDXResourceLoaderMetricModel.h>
#import "BDResourceLoaderMetricHelper.h"

@implementation BDResourceLoaderMetricHelper

+ (NSString *)webContainerId:(WKWebView *)webView {
    NSString *containerId = @"";
    if ([webView respondsToSelector:@selector(reactID)]) { // containerId in BDXWebView
        containerId = [webView performSelector:@selector(reactID)];
    } else if ([webView respondsToSelector:@selector(iwk_containerID)]) { // containerId in IESWKWebView
        containerId = [webView performSelector:@selector(iwk_containerID)];
    }
    if (![containerId isKindOfClass:[NSString class]] || containerId.length == 0) {
        containerId = [[NSUUID UUID] UUIDString]; // UUID 兜底
    }
    return containerId;
}

+ (NSDictionary *)monitorDict:(id<BDXResourceProtocol>)resourceProvider  containerId:(NSString *)containerId{
    if (!resourceProvider) {
        return @{};
    }
    NSString *resourceFrom = @"";
    BDXResourceLoaderMetricModel *metricInfo = resourceProvider.metricInfo;
    switch (resourceProvider.resourceType) {
        case BDXResourceStatusGecko:
            if (resourceProvider.isGeckoUpdate) {
                resourceFrom = @"gecko_update";
            } else {
                resourceFrom = @"gecko";
            }
            break;
        case BDXResourceStatusCdn:
            resourceFrom = @"cdn";
            break;
        case BDXResourceStatusCdnCache:
            resourceFrom = @"cdn_cache";
            break;
        case BDXResourceStatusBuildIn:
            resourceFrom = @"builtin";
            break;
        case BDXResourceStatusOffline:
            resourceFrom = @"offline";
            break;
        default:
            break;
    }
    return @{
            @"rl_container_uuid": containerId,
            @"res_loader_name": @"x_resource_loader",
            @"res_src": resourceProvider.sourceUrl ?:@"",
            @"gecko_channel": resourceProvider.channel ?: @"",
            @"gecko_bundle": resourceProvider.bundle ?: @"",
            @"gecko_access_key": resourceProvider.accessKey ?: @"",
            @"cdn_cache_enable":@(NO),
            @"res_from":resourceFrom ?: @"",
            @"is_memory": @(resourceProvider.isFromMemory),
            @"res_size": @(resourceProvider.resourceData.length),
            @"res_load_start": @(metricInfo.res_load_start),
            @"res_load_finish": @(metricInfo.res_load_finish),
            @"init_start": @(metricInfo.init_start),
            @"init_finish": @(metricInfo.init_finish),
            @"memory_start": @(metricInfo.memory_start),
            @"memory_finish": @(metricInfo.memory_finish),
            @"gecko_total_start": @(metricInfo.gecko_total_start),
            @"gecko_total_finish": @(metricInfo.gecko_total_finish),
            @"gecko_start": @(metricInfo.gecko_start),
            @"gecko_finish": @(metricInfo.gecko_finish),
            @"cdn_total_start": @(metricInfo.cdn_total_start),
            @"cdn_total_finish": @(metricInfo.cdn_total_finish),
            @"cdn_cache_start": @(metricInfo.cdn_cache_start),
            @"cdn_cache_finish": @(metricInfo.cdn_cache_finish),
            @"cdn_start": @(metricInfo.cdn_start),
            @"cdn_finish": @(metricInfo.cdn_finish),
            @"builtin_start": @(metricInfo.builtin_start),
            @"builtin_finish": @(metricInfo.builtin_finish),
    };
}

@end
