//
//  IESBridgeMonitor.m
//  IESWebKit
//
//  Created by Lizhen Hu on 2020/1/3.
//

#import "IESBridgeMonitor.h"
#import "IESJSBridgeCoreABTestManager.h"
#import "IESBridgeMessage.h"
#import "IESBridgeMethod.h"
#import <BDMonitorProtocol/BDMonitorProtocol.h>

@implementation IESBridgeMonitor

+ (void)monitorJSBInvokeEventWithBridgeMessage:(IESBridgeMessage *)message bridgeMethod:(IESBridgeMethod *)method url:(NSURL *)url isAuthorized:(BOOL)isAuthorized
{
    if (!IESPiperCoreABTestManager.sharedManager.shouldMonitorJSBInvokeEvent || !message || !method || !url) {
        return;
    }
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    data[@"service"] = @"hybrid_app_monitor_bridge_invoke_event";
    data[@"status"] = @(0);
    data[@"category"] = ({
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[@"type"] = @"h5";
        dict[@"trigger"] = @"bridge_invoke";
        dict[@"bridge_name"] = message.methodName;
        dict[@"bridge_access"] = [self authStringWithType:method.authType];
        dict[@"host"] = url.host;
        dict[@"path"] = url.path;
        dict[@"url"] = url.absoluteString;
        dict[@"is_authorized"] = @(isAuthorized);
        [dict copy];
    });
    data[@"value"] = @{
        @"ts": @([[NSDate date] timeIntervalSince1970] * 1000),
    };

    // 端监控 https://bytedance.feishu.cn/docs/doccn2whe25ItSOKnHCaVRw2dFb#
    [BDMonitorProtocol hmdTrackData:[data copy] logType:@"ies_hybrid_monitor"];
}

+ (NSString *)authStringWithType:(IESPiperAuthType)type
{
    switch (type) {
        case IESPiperAuthPublic: return @"public";
        case IESPiperAuthProtected: return @"protect";
        case IESPiperAuthPrivate: return @"private";
        default: return @"unknown";
    }
}

@end
