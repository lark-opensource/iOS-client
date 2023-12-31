//
//  EMAPluginMonitorCustomImpl.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/3/3.
//

#import "EERoute.h"
#import "EMAAppEngine.h"
#import "EMADebugLaunchTracing.h"
#import <OPFoundation/EMADebugUtil.h>
#import "EMALifeCycleManager.h"
#import <OPFoundation/EMAMonitorHelper.h>
#import <OPFoundation/EMANetworkAPI.h>
#import <ECOInfra/EMANetworkManager.h>
#import "EMAPluginMonitorCustomImpl.h"
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOProbe/ECOProbe-Swift.h>
#import <ECOProbe/OPMonitorCode.h>
#import <OPFoundation/BDPMonitorEvent.h>
#import <OPFoundation/BDPNotification.h>
#import <OPFoundation/BDPTrackerConstants.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPVersionManager.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <OPFoundation/OPEnvTypeHelper.h>
#import <ECOProbe/OPMonitorReportPlatform.h>
#import <LKLoadable/Loadable.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>

LoadableRunloopIdleFuncBegin(EMAPluginMonitorCustomImplSharePlugin)
static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
    [EMAPluginMonitorCustomImpl sharedPlugin];
});
LoadableRunloopIdleFuncEnd(EMAPluginMonitorCustomImplSharePlugin)

@implementation EMAPluginMonitorCustomImpl
+ (id<BDPMonitorPluginDelegate>)sharedPlugin
{
    static EMAPluginMonitorCustomImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupObserver];
    }
    return self;
}

- (void)setupObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enterForeground:)
                                                 name:kBDPDidEnterForegroundNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(exitForeground:)
                                                 name:kBDPEnterBackgroundNotification
                                               object:nil];

}

- (void)enterForeground:(NSNotification *)notification {
#ifndef DEBUG
    id<EMAProtocol> delegate = [EMARouteProvider getEMADelegate];
    if ([delegate respondsToSelector:@selector(setHMDInjectedInfoWith:localLibVersionString:)]) {
        NSString *localLibVersionString = [BDPVersionManager localLibVersionString];
        [delegate setHMDInjectedInfoWith:notification localLibVersionString:localLibVersionString];
    }
#endif
}

- (void)exitForeground:(NSNotification *)notification {
#ifndef DEBUG
    id<EMAProtocol> delegate = [EMARouteProvider getEMADelegate];
    if ([delegate respondsToSelector:@selector(removeHMDInjectedInfo)]) {
        [delegate removeHMDInjectedInfo];
    }
#endif
}

- (void)bdp_monitorEventName:(NSString *)name
                      metric:(NSDictionary *)metric
                    category:(NSDictionary *)category
                       extra:(NSDictionary *)extraValue
                    platform:(OPMonitorReportPlatform)platform {
    // 目前先不区分 extra 和 category，全部合并成一个
    NSMutableDictionary *data = NSMutableDictionary.dictionary;

    if (!BDPIsEmptyDictionary(category)) {
        [data addEntriesFromDictionary:category];
    }

    if (!BDPIsEmptyDictionary(extraValue)) {
        [data addEntriesFromDictionary:extraValue];
    }
    [self bdp_monitorEventName:name metric:metric category:data platform:platform];
}

- (void)bdp_monitorEventName:(NSString *)name
                      metric:(NSDictionary *)metric
                    category:(NSDictionary *)category
                    platform:(OPMonitorReportPlatform)platform
{
    // 增加公共字段
    NSMutableDictionary *attributes = category.mutableCopy;
    
    OPEnvType envType = EMAAppEngine.currentEngine.config.envType;
    
    // 为所有的埋点设置环境参数
    attributes[kEventKey_evn_type] = OPEnvTypeToString(envType);

    // 为所有的埋点设置网络状态
    attributes[kEventKey_net_status] = OPNetStatusHelperBridge.opNetStatus;

    // 日志打印需要打印所有数据，将 metric 与 category 合并为 data
    NSMutableDictionary *data = [category mutableCopy];
    [data addEntriesFromDictionary:metric];

    // 打印日志的时候，根据埋点level，如果level有值，且不是normal，使用warn，否则都是用info
    NSNumber *level = data[OPMonitorEventKey.monitor_level];
    NSString *logValue = [NSString stringWithFormat:@"monitor_event:%@|%@|%@,data%@",
                          data[kEventKey_time] ?: @"",
                          name ?: @"",
                          data[kEventKey_trace_id] ?: @"",
                          [data JSONRepresentationWithOptions:NSJSONWritingPrettyPrinted]];
    if (level && [level isKindOfClass:[NSNumber class]] && level.intValue != OPMonitorLevelNormal) {
        BDPLogTagWarn(OPMonitorConstants.default_log_tag, @"%@", logValue);
    } else {
        BDPLogTagInfo(OPMonitorConstants.default_log_tag, @"%@", logValue);
    }

    if ([EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigUploadEvent].boolValue) {
        // 如果打开了强制上传, 不需要判断上传时机了
        BDPLogInfo(@"force upload event is open");
    } else {
        // 调试过小程序，不再上报
        if (EMADebugUtil.sharedInstance.usedDebugApp) {
            BDPLogInfo(@"usedDebugApp");
            return;
        }

        // 调试状态 不用上报
        if (EMADebugUtil.sharedInstance.enable) {
            [[EMADebugLaunchTracing sharedInstance] processIfNeeded:name attributes:data];
            BDPLogInfo(@"debug enable");
            return;
        }

        // 非正式环境不用上报
        if (envType == OPEnvTypeStaging || envType == OPEnvTypePreRelease) {
            BDPLogInfo(@"OPEnvType %llu", envType);
            return;
        }
    }
    // debug 判断kEMADebugConfigUploadEvent
    id<EMAProtocol> delegate = [EMARouteProvider getEMADelegate];
#ifndef DEBUG
    if ([delegate respondsToSelector:@selector(monitorService:metricsData:categoriesData:platform:)]) {
        [delegate monitorService:name metricsData:metric categoriesData:attributes platform:platform];
    }
#else
    if ([EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigUploadEvent].boolValue && [delegate respondsToSelector:@selector(monitorService:metricsData:categoriesData:platform:)]) {
        [delegate monitorService:name metricsData:metric categoriesData:attributes platform:platform];
    }
#endif
}

@end
