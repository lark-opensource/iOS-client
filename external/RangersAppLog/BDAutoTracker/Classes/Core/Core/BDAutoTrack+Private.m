//
//  BDAutoTrack+Private.m
//  Pods-BDAutoTracker_Example
//
//  Created by bob on 2019/6/4.
//

#import "BDAutoTrack+Private.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackUtility.h"

#import "BDAutoTrackServiceCenter.h"
#import "RangersLog.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackRemoteSettingService.h"

#import "BDAutoTrackDataCenter.h"
#import "BDAutoTrack.h"
#import "BDAutoTrackBatchService.h"
#import "BDAutoTrackBatchTimer.h"
#import "BDAutoTrackMainBundle.h"

#if __has_include("BDAutoTrack+UITracker.h")
#import "BDAutoTrack+UITracker.h"
#endif

#import "NSDictionary+VETyped.h"

@implementation BDAutoTrack (Private)

@dynamic dataCenter;
@dynamic showDebugLog;
@dynamic gameModeEnable;
@dynamic serialQueue;
@dynamic alinkActivityContinuation;
@dynamic profileReporter;

+ (NSArray<BDAutoTrack *> *)allTrackers {
    return [[BDAutoTrackServiceCenter defaultCenter] servicesForName:BDAutoTrackServiceNameTracker];
}

+ (BDAutoTrack *)trackerWithAppId:(NSString *)appID {
    NSArray<BDAutoTrack *> *allTracker = [self allTrackers];
    for (BDAutoTrack *track in allTracker) {
        if ([track isKindOfClass:[BDAutoTrack class]] && track.appID == appID) {
            continue;
        }
    }
    return nil;
}

+ (void)trackUIEventWithData:(NSDictionary *)data {
    if (![data isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    NSString *className = [[data objectForKey:@"params"] objectForKey:@"page_key"];
    if ([className hasPrefix:@"BDAutoTrack"]) {
        return;
    }

    NSString *event = [data objectForKey:@"event"];
    if (![NSJSONSerialization isValidJSONObject:data]) {
        
        RL_WARN(BDAutoTrack.sharedTrack,@"AutoTrack", @"Event:%@ termimate due to INVALID PARAMETERS.", event);
        return;
    }
    NSArray<BDAutoTrack *> *allTracker = [self allTrackers];
    for (BDAutoTrack *track in allTracker) {
        if (![track isKindOfClass:[BDAutoTrack class]]) {
            continue;
        }
        // 全埋点开关，有远端配置和本地代码的配置，两端都开启则开启，有一端关闭则关闭
        bool autoTrackEnabled = track.remoteConfig.autoTrackEnabled && track.localConfig.autoTrackEnabled;
        if (!autoTrackEnabled) {
            RL_WARN(track,@"AutoTrack", @"Event:%@ termimate due to AUTOTACKER DISABLED", event);
            continue;
        }
        
        // 拿取本地配置
        BDAutoTrackLocalConfigService *settings = track.localConfig;
        
        //判断是否 Igore
        BOOL ignored = NO;
        if ([event isEqualToString:@"bav2b_page"]) {
            if (!settings.trackPageEnabled) {
                continue;
            }
            
            if ([track respondsToSelector:@selector(isPageIgnored:)]) {
                NSString *className = [[data objectForKey:@"params"] objectForKey:@"page_key"];
                ignored = [track performSelector:@selector(isPageIgnored:) withObject:className];
            }
        } else if ([event isEqualToString:@"bav2b_click"]) {
            if (!settings.trackPageClickEnabled) {
                continue;
            }
            
            if ([track respondsToSelector:@selector(isClickIgnored:)]) {
                NSString *className = [[data objectForKey:@"params"] objectForKey:@"element_type"];
                ignored = [track performSelector:@selector(isClickIgnored:) withObject:className];
            }
        } else if ([event isEqualToString:@"$bav2b_page_leave"]) {
            if (!settings.trackPageLeaveEnabled) {
                continue;
            }
            
            if ([track respondsToSelector:@selector(isPageIgnored:)]) {
                NSString *className = [[data objectForKey:@"params"] objectForKey:@"page_key"];
                ignored = [track performSelector:@selector(isPageIgnored:) withObject:className];
            }
        }

        if (ignored) {
            RL_WARN(track, @"AutoTrack", @"Event:%@ termimate due to IGNORED.",event);
            continue;
        }
        
        if (track.config.rollback) {
            [track.dataCenter trackUIEventWithData:data];
        } else {
            [track.eventGenerator trackEventType:BDAutoTrackTableUIEvent eventBody:data options:nil];
        }
       
    }
}

+ (void)trackLaunchEventWithData:(NSMutableDictionary *)data {
    if (bd_is_extension()) {
        return;
    }
    NSArray<BDAutoTrack *> *allTracker = [self allTrackers];
    for (BDAutoTrack *track in allTracker) {
        if (![track isKindOfClass:[BDAutoTrack class]]) {
            continue;
        }
        if (track.config.rollback) {
            [track.dataCenter trackLaunchEventWithData:[[NSMutableDictionary alloc] initWithDictionary:data copyItems:YES]];
        } else {
            [track.eventGenerator trackLaunch:data];
        }
        
        // 如果是被动启动，产生 $app_launch_passively 事件，放到 event_v3 中
        // 产品侧为了不影响老逻辑，launch事件依然发送，后续看需求可以去掉launch
        if([data vetyped_boolForKey:kBDAutoTrackIsBackground]) {
            bool resumeFromBackground = [data vetyped_boolForKey:kBDAutoTrackResumeFromBackground];
            if (track.config.rollback) {
                NSDictionary *trackData = @{kBDAutoTrackEventType:@"$app_launch_passively",
                                            kBDAutoTrackEventData:@{kBDAutoTrackResumeFromBackground: @(resumeFromBackground)}};
                [track.dataCenter trackUserEventWithData:trackData];
            } else {
                [track.eventGenerator trackEvent:@"$app_launch_passively" parameter:@{kBDAutoTrackResumeFromBackground: @(resumeFromBackground)} options:nil];
            }
        }
    }
}

+ (void)trackTerminateEventWithData:(NSMutableDictionary *)data {
    if (bd_is_extension()) {
        return;
    }
    
    NSArray<BDAutoTrack *> *allTracker = [self allTrackers];
    for (BDAutoTrack *track in allTracker) {
        if (![track isKindOfClass:[BDAutoTrack class]]) {
            continue;
        }
        if (track.config.rollback) {
            [track.dataCenter trackTerminateEventWithData:[[NSMutableDictionary alloc] initWithDictionary:data copyItems:YES]];
        } else {
            [track.eventGenerator trackTerminate:data];
        }
    }
}

+ (void)trackPlaySessionEventWithData:(NSDictionary *)data {
    NSString *event = [data objectForKey:@"event"];
    NSArray<BDAutoTrack *> *allTracker = [self allTrackers];
    for (BDAutoTrack *track in allTracker) {
        if (![track isKindOfClass:[BDAutoTrack class]]) {
            continue;
        }
        if (track.gameModeEnable) {
            if (track.config.rollback) {
                [track.dataCenter trackUserEventWithData:data];
            } else {
                [track.eventGenerator trackEventType:BDAutoTrackTableEventV3 eventBody:data options:nil];
            }
            
        }
    }
}

- (void)setAppTouchPoint:(NSString *)appTouchPoint {
    dispatch_async(self.serialQueue, ^{
        [self.localConfig saveAppTouchPoint:[appTouchPoint copy]];
    });
}

/// caller: Profile上报、Tracer上报
/// 若上次上报时间在flushTimeInterval内，立即发起一次Batch上报。
/// 传入timeInterval=0，可实现立即上报.
/// @param flushTimeInterval Flush上报的最小间隔，整数。单位：秒。
- (void)flushWithTimeInterval:(NSInteger)flushTimeInterval {
    NSString *appID = self.appID;
    dispatch_async(self.serialQueue, ^{
        BDAutoTrackBatchService *service = (BDAutoTrackBatchService *)bd_standardServices(BDAutoTrackServiceNameBatch, appID);
        [service sendTrackDataFrom:BDAutoTrackTriggerSourceManually flushTimeInterval:flushTimeInterval];
    });
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@-%@", self.config.appID, self.config.appName];
}


@end
