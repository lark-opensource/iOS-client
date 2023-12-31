//
//  BDPPluginTrackerCustomImpl.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/3/22.
//

#import "BDPPluginTrackerCustomImpl.h"
#import "EERoute.h"
#import "EMAAppEngine.h"
#import <OPFoundation/EMAMonitorHelper.h>
#import <OPFoundation/BDPCommonMonitorHelper.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <OPFoundation/BDPTrackerEvents.h>
#import <OPFoundation/BDPUtils.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <ECOProbe/OPMonitorReportPlatform.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>

@implementation BDPPluginTrackerCustomImpl

+ (id<BDPTrackerPluginDelegate>)sharedPlugin {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

/// 使用 Tracker.post 埋点，默认打 TEA，若 eventId 为性能相关埋点会同步打 Slardar
/// @param eventId  埋点名称
/// @param params 埋点数据
- (void)bdp_event:(NSString *)eventId params:(NSDictionary *)params {
    if (BDPIsEmptyString(eventId)) {
        BDPLogTagError(@"Tracker", @"bdp_event with empty eventId! params: %@", BDPParamStr(eventId, params));
        return;
    }
    OPMonitorReportPlatform reportOption = OPMonitorReportPlatformTea;
    // 性能相关事件发送到Slardar平台
    if (eventId && [self.class.monitorEventSet containsObject:eventId]) {
        // 需要使用 BDPMonitor 的参数注入功能，用 eventId 创建 BDPMonitor
        BDPMonitorWithName(eventId, nil).addMap(params).flush();
    } else {
        BDPLogTagInfo(@"Tracker", @"%@", BDPParamStr(eventId, params));
    }
    id<EMAProtocol> delegate = [EMARouteProvider getEMADelegate];
    [delegate trackerEvent:eventId params:params option: reportOption];
}

- (void)bdp_monitorService:(NSString *)service metric:(NSDictionary<NSString *,NSNumber *> *)metric category:(NSDictionary *)category extra:(NSDictionary *)extra {
    if (BDPIsEmptyString(service)) {
        return;
    }
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    if (!BDPIsEmptyDictionary(metric)) {
        [data addEntriesFromDictionary:metric];
    }
    if (!BDPIsEmptyDictionary(category)) {
        [data addEntriesFromDictionary:category];
    }
    if (!BDPIsEmptyDictionary(extra)) {
        [data addEntriesFromDictionary:extra];
    }
    [[BDPMonitorEvent alloc] initWithService:GDMonitorService.gadgetMonitorService name:service metrics:nil categories:data].flush();
}

static NSSet *eventSet = nil;
static BOOL remoteListReady = NO;

+ (NSSet *)monitorEventSet {
    @synchronized (self) {
        if (!remoteListReady) {
            if (EMAAppEngine.currentEngine.onlineConfig.tea2slardarList) {
                remoteListReady = YES;
                eventSet = nil;
            }
        }
        if (!eventSet) {
            eventSet = [self newEventSet];
        }
    }
    return eventSet;
}

+ (NSSet *)newEventSet {
    NSMutableArray *eventList = @[@"mp_load_result",
                                  kEventName_mp_meta_request_start,
                                  kEventName_mp_meta_request_result,
                                  @"mp_download_start",
                                  @"mp_download_result",
                                  @"mp_lib_download_result",
                                  @"mp_load_domready",
                                  BDPTELoadFirstContent,
                                  kEventName_mp_report_analytics].mutableCopy;
    NSArray *remoteList = EMAAppEngine.currentEngine.onlineConfig.tea2slardarList;
    if (!BDPIsEmptyArray(remoteList)) {
        [eventList addObjectsFromArray:remoteList];
    }
    return [NSSet setWithArray:eventList];
}

@end
