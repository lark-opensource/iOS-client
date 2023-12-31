//
//  BDWebView+TTNet.m
//  ByteWebView
//
//  Created by 杨牧白 on 2019/12/30.
//

#import "BDWebViewTTNetUtil.h"

#import <ByteDanceKit/ByteDanceKit.h>
#import <TTNetworkManager/TTHttpResponseChromium.h>

static NSMutableArray *ttnetRefErrorURL = nil;

@implementation BDWebViewTTNetUtil
+ (NSArray *)ttnetRefErrorURLs {
    return [ttnetRefErrorURL copy];
}

+ (void)addTTNetBlockList:(NSString *)url {
    if (url.length <= 0) {
        return;
    }
    if (!ttnetRefErrorURL) {
        ttnetRefErrorURL = [NSMutableArray new];
    }
    if (![ttnetRefErrorURL containsObject:url]) {
        [ttnetRefErrorURL addObject:url];
    }
}

+ (BOOL)isHitTTNetBlockListWithURL:(NSString *)url {
    NSArray *autoBlankList = ttnetRefErrorURL.copy;
    if (autoBlankList.count == 0) {
        return NO;
    }
    
    for (NSString *blackURL in autoBlankList) {
        if ([url containsString:blackURL]) {
            return YES;
        }
    }
    return NO;
}

+ (NSInteger)ttnetAutoBlockListCount {
    return ttnetRefErrorURL.count;
}

+ (NSSet *)monitorResponseHeaders
{
    static NSSet *headers = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        headers = [NSSet setWithArray: @[
            @"content-type", @"content-length", @"content-encoding", @"x-gecko-proxy-logid", @"x-gecko-proxy-pkgid",
            @"x-gecko-proxy-tvid", @"x-tos-version-id", @"x-bdcdn-cache-status", @"x-cache", @"x-response-cache",
            @"x-tt-trace-host", @"via"
        ]];
    });
    return headers;
}

+ (NSDictionary *)ttnetResponseHeaders:(TTHttpResponse *)ttResponse
{
    NSDictionary *dict = [ttResponse.allHeaderFields btd_filter:^BOOL(id _Nonnull key, id  _Nonnull obj) {
        return [[[self class] monitorResponseHeaders] containsObject: key];
    }];
    return [dict copy];
}

+ (NSDictionary *)ttnetResponseTimingInfo:(TTHttpResponse *)ttResponse
{
    if ([ttResponse isKindOfClass:[TTHttpResponseChromium class]]) {
        TTHttpResponseChromium *targetResponse = (TTHttpResponseChromium *)ttResponse;
        TTHttpResponseChromiumTimingInfo *timingInfo = targetResponse.timingInfo;
        
        // process request log
        NSDictionary *originRequestLogDic = [NSJSONSerialization JSONObjectWithData:[targetResponse.requestLog dataUsingEncoding:NSUTF8StringEncoding]
                                                                            options:0
                                                                              error:nil];
        NSMutableDictionary *processedRequestLogDic = [[NSMutableDictionary alloc] init];
        if ([originRequestLogDic isKindOfClass:[NSDictionary class]]) {
            if ([originRequestLogDic.allKeys containsObject:@"response"] && [originRequestLogDic[@"response"] isKindOfClass:[NSDictionary class]]) {
                processedRequestLogDic[@"response"] = [originRequestLogDic[@"response"] copy];
            }
            if ([originRequestLogDic.allKeys containsObject:@"timing"] && [originRequestLogDic[@"timing"] isKindOfClass:[NSDictionary class]]) {
                processedRequestLogDic[@"timing"] = [originRequestLogDic[@"timing"] copy];
            }
        }
        
        NSString *requestLogStr = nil;
        if ([NSJSONSerialization isValidJSONObject:processedRequestLogDic]) {
            NSData *data = [NSJSONSerialization dataWithJSONObject:processedRequestLogDic
                                                           options:kNilOptions
                                                             error:nil];
            requestLogStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        }
        
        return @{
            @"ttnet_start" : @([timingInfo.start timeIntervalSince1970] * 1000),
            @"ttnet_proxy" : @(timingInfo.proxy),
            @"ttnet_dns" : @(timingInfo.dns),
            @"ttnet_connect" : @(timingInfo.connect),
            @"ttnet_ssl" : @(timingInfo.ssl),
            @"ttnet_send" : @(timingInfo.send),
            @"ttnet_wait" : @(timingInfo.wait),
            @"ttnet_receive" : @(timingInfo.receive),
            @"ttnet_total" : @(timingInfo.total),
            @"ttnet_receivedResponseContentLength" : @(timingInfo.receivedResponseContentLength),
            @"ttnet_totalReceivedBytes" : @(timingInfo.totalReceivedBytes),
            @"ttnet_isSocketReused" : @(timingInfo.isSocketReused),
            @"ttnet_isCached" : @(timingInfo.isCached),
            @"ttnet_isFromProxy" : @(timingInfo.isFromProxy),
            @"ttnet_requestLog" : requestLogStr
        };
    }
    return [[NSDictionary alloc] init];
}

@end
