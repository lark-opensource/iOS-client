//
//  BDPowerLogConfig.m
//  LarkMonitor
//
//  Created by ByteDance on 2022/9/29.
//

#import "HMDPowerMonitorConfig.h"
#import "HMDPowerMonitor.h"
#import "HMDAttributesMacro.h"
#import "hmd_section_data_utility.h"

NSString *const kHMDModulePowerMonitor = @"power";

HMD_MODULE_CONFIG(HMDPowerMonitorConfig)

@implementation HMDPowerMonitorConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(flushCount, flush_count, @(1), @(1))
        HMD_ATTR_MAP_DEFAULT(refreshInterval, refresh_interval, @(0), @(0))
        HMD_ATTR_MAP_DEFAULT(sceneUpdateSessionMinTime, scene_duration_threshold, @(2), @(2))
        HMD_ATTR_MAP_DEFAULT(disableSceneUpdateSession, disable_scene_session, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(includeSceneUpdateBackgroundSession, scene_include_background, @(NO), @(NO))
    };
}

- (id)copyWithZone:(NSZone *)zone {
    HMDPowerMonitorConfig *newObject = [[HMDPowerMonitorConfig alloc] init];
//    newObject.enableNetMonitor = self.enableNetMonitor;
//    newObject.enableURLSessionMetrics = self.enableURLSessionMetrics;
    newObject.disableSceneUpdateSession = self.disableSceneUpdateSession;
//    newObject.enableWebKitMonitor = self.enableWebKitMonitor;
    newObject.sceneUpdateSessionMinTime = self.sceneUpdateSessionMinTime;
    newObject.includeSceneUpdateBackgroundSession = self.includeSceneUpdateBackgroundSession;
//    newObject.highpowerConfig = self.highpowerConfig;
//    newObject.subsceneConfig = self.subsceneConfig;
    return newObject;
}

+ (NSString *)configKey {
    return kHMDModulePowerMonitor;
}

- (id<HeimdallrModule>)getModule {
    return [HMDPowerMonitor sharedMonitor];
}

@end
