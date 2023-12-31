//
//  TSPKNetworkMonitor.m
//  TSPrivacyKit
//
//  Created by admin on 2022/8/24.
//

#import "TSPKNetworkMonitor.h"
#import "TSPKNetworkDetectPipeline.h"
#import "TSPKNetworkConfigs.h"
#import "TSPKLogger.h"
#import "TSPKNetworkUtil.h"
// Subscribers
#import "TSPKEventManager.h"
#import "TSPKSubscriber.h"

@implementation TSPKNetworkMonitor

+ (instancetype)sharedMonitor {
    static TSPKNetworkMonitor *env;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        env = [[TSPKNetworkMonitor alloc] init];
    });
    return env;
}

+ (void)setConfig:(NSDictionary *)config {
    [TSPKNetworkConfigs setConfigs:config];
}

+ (NSArray<NSString *> *)__pipelineNameArray
{
    return @[
        @"TSPKNetworkURLProtocolPipeline",
        @"TSPKTTNetInterceptorPipeline",
        @"TSPKTTNetRedirectInterceptPipeline"
    ];
}

+ (void)setupSubscribers
{
    // need to be registered before other subscribers
    if ([TSPKNetworkConfigs enableReuqestAnalyzeSubscriber]) {
        [TSPKLogger logWithTag:TSPKNetworkLogCommon message:@"enable_request_anaylze_control is true"];
        id networkAyalyzeSubscriber = [NSClassFromString(@"TSPKRequestAnalyzeSubscriber") new];
        if ([networkAyalyzeSubscriber conformsToProtocol:@protocol(TSPKSubscriber)]) {
            [TSPKEventManager registerSubsciber:networkAyalyzeSubscriber onEventType:TSPKEventTypeNetworkResponse];
        }
    }
    if ([TSPKNetworkConfigs enableNetworkFuseSubscriber]) {
        [TSPKLogger logWithTag:TSPKNetworkLogCommon message:@"enable_fuse_engine_control is true"];
        id networkFuseSubscriber = [NSClassFromString(@"TSPKNetworkFuseEngineSubscriber") new];
        if ([networkFuseSubscriber conformsToProtocol:@protocol(TSPKSubscriber)]) {
            [TSPKEventManager registerSubsciber:networkFuseSubscriber onEventType:TSPKEventTypeNetworkRequest];
        }
    }
    if ([TSPKNetworkConfigs enableNetworkSubscriber]) {
        [TSPKLogger logWithTag:TSPKNetworkLogCommon message:@"enable_guard_engine_control is true"];
        id networkSubscriber = [NSClassFromString(@"TSPKNetworkEngineSubscriber") new];
        if ([networkSubscriber conformsToProtocol:@protocol(TSPKSubscriber)]) {
            [TSPKEventManager registerSubsciber:networkSubscriber onEventType:TSPKEventTypeNetworkResponse];
        }
    }
}

+ (void)setupPipelines
{
    NSArray<NSString *> *allPipelines = [self __pipelineNameArray];
    for (NSString *pipeline in allPipelines) {
        Class class = NSClassFromString(pipeline);
        if (class) {
            TSPKNetworkDetectPipeline *pipeline = [class new];
            if ([pipeline isKindOfClass:[TSPKNetworkDetectPipeline class]]) {
                [[pipeline class] preload];
            }
        }
    }
}

+ (void)start {
    if (![TSPKNetworkConfigs isEnable]) {
        [TSPKLogger logWithTag:TSPKNetworkLogCommon message:@"TSPKNetworkMonitor start failed"];
        return;
    }
    
    [TSPKNetworkUtil updateMonitorStartTime];
    [self setupPipelines];
    [self setupSubscribers];
}

@end
