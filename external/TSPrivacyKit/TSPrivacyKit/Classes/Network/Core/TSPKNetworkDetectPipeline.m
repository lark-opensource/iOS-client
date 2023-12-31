//
//  TSPKNetworkDetectPipeline.m
//  BDAlogProtocol
//
//  Created by admin on 2022/8/23.
//

#import "TSPKNetworkDetectPipeline.h"
#import "TSPKEventManager.h"
#import "TSPKNetworkEvent.h"

#import "TSPKHandleResult.h"
#import "TSPKHandleResult.h"
#import "TSPKCommonRequestProtocol.h"
#import "TSPKNetworkConfigs.h"
#import "TSPKNetworkReporter.h"
#import "TSPKReporter.h"
#import "TSPKUploadEvent.h"
#import "TSPKNetworkUtil.h"
#import <PNSServiceKit/PNSServiceCenter.h>
#import <PNSServiceKit/PNSBacktraceProtocol.h>

@implementation TSPKNetworkDetectPipeline

+ (void)preload {
    NSAssert(false, @"should override by subclass");
}

+ (void)reportWithBacktrace:(NSString *)source url:(NSURL *)url {
    if ([TSPKNetworkConfigs canReportNetworkBacktrace]) {
        [[TSPKNetworkConfigs uploadBacktraceURL:source] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSString class]]) {
                if ([url.absoluteString containsString:obj]) {
                    TSPKUploadEvent *event = [TSPKUploadEvent new];
                    event.eventName = @"PrivacyBadcase-Network";
                    event.backtraces = [PNS_GET_INSTANCE(PNSBacktraceProtocol) getBacktracesWithSkippedDepth:0 needAllThreads:NO];
                    event.params = @{
                        @"url": [TSPKNetworkUtil URLStringWithoutQuery:url.absoluteString],
                        @"scheme": url.scheme,
                        @"path": url.path,
                        @"domain": url.host,
                        @"source": source,
                        @"permissionType": source,
                        @"monitorScene": @"cross_domain"
                    }.mutableCopy;
                    event.filterParams = event.params;
                    [[TSPKReporter sharedReporter] report:event];
                }
            }
        }];
    }
}

+ (TSPKHandleResult *)onRequest:(id<TSPKCommonRequestProtocol>)request {
    NSTimeInterval startedTime = CFAbsoluteTimeGetCurrent();
    TSPKNetworkEvent *event = [TSPKNetworkEvent new];
    event.request = request;
    event.eventType = TSPKEventTypeNetworkRequest;
    TSPKHandleResult *result = [TSPKEventManager dispatchEvent:event];
    [TSPKNetworkReporter perfWithName:[NSString stringWithFormat:@"%@%@", request.tspk_util_eventType, request.tspk_util_isRedirect ? @"_redirect": @""] calledTime:startedTime networkEvent:event];
    return result;
}

+ (TSPKHandleResult *)onResponse:(id<TSPKCommonResponseProtocol>)response request:(id<TSPKCommonRequestProtocol>)request data:(id)data{
    TSPKNetworkEvent *event = [TSPKNetworkEvent new];
    event.request = request;
    event.response = response;
    event.responseData = data;
    event.eventType = TSPKEventTypeNetworkResponse;
    return [TSPKEventManager dispatchEvent:event];
}

@end
