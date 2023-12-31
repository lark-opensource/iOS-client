//
//  TSPKRequestAnalysistSubscriber.m
//  Musically
//
//  Created by admin on 2023/2/20.
//

#import "TSPKRequestAnalyzeSubscriber.h"
#import "TSPKNetworkEvent.h"
#import "TSPKNetworkConfigs.h"
#import "TSPKThreadPool.h"
#import "TSPKNetworkReporter.h"
#import "TSPKNetworkUtil.h"

@implementation TSPKRequestAnalyzeSubscriber

- (NSString *)uniqueId {
    return @"TSPKNetworkEngineSubscriber";
}

- (BOOL)canHandelEvent:(TSPKEvent *)event {
    return YES;
}

- (TSPKHandleResult *)hanleEvent:(TSPKEvent *)event {
    if (![event isKindOfClass:[TSPKNetworkEvent class]]) {
        return nil;
    }
    TSPKNetworkEvent *networkEvent = (TSPKNetworkEvent *)event;
 
    dispatch_async([[TSPKThreadPool shardPool] networkWorkQueue], ^{
        if ([TSPKNetworkConfigs canAnalyzeRequest] && [TSPKNetworkConfigs canReportAllowNetworkEvent:networkEvent]) {
            [TSPKNetworkReporter reportWithCommonInfo:[self convertNetworkModelToParams:networkEvent] networkEvent:networkEvent];
        }
    });
    
    return nil;
}

- (NSDictionary *)convertNetworkModelToParams:(TSPKNetworkEvent *)networkEvent {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    // common
    dict[@"is_request"] = @(NO);
    dict[@"method"] = networkEvent.request.tspk_util_HTTPMethod ?: @"";
    dict[@"event_type"] = networkEvent.request.tspk_util_eventType ?: @"";
    dict[@"event_source"] = networkEvent.request.tspk_util_eventSource ?: @"";
    dict[@"is_redirect"] = @(networkEvent.request.tspk_util_isRedirect);
    // NSURL
    /// request
    dict[@"domain"] = networkEvent.request.tspk_util_url.host ?: @"";
    dict[@"path"] = [TSPKNetworkUtil realPathFromURL:networkEvent.request.tspk_util_url] ?: @"";
    dict[@"scheme"] = networkEvent.request.tspk_util_url.scheme ?: @"";
    /// response
    dict[@"res_domain"] = networkEvent.response.tspk_util_url.host ?: @"";
    dict[@"res_path"] = [TSPKNetworkUtil realPathFromURL:networkEvent.response.tspk_util_url] ?: @"";
    dict[@"res_scheme"] = networkEvent.response.tspk_util_url.scheme ?: @"";
    // other infos
    dict[@"monitor_scenes"] = @"network_anaylze";
    
    return dict;
}

@end
