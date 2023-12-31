//
//  HMDMonitorConfig.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/14.
//

#import "HMDMonitorConfig.h"
#import "NSObject+HMDAttributes.h"

@implementation HMDMonitorConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(flushInterval, flush_interval, @(30), @(30))
        HMD_ATTR_MAP_DEFAULT(flushCount, flush_count, @(5), @(5))
        HMD_ATTR_MAP_DEFAULT(refreshInterval, refresh_interval, @(1), @(1))
        HMD_ATTR_MAP_DEFAULT(customEnableUpload, custom_enable_upload, @{}, @{})
        HMD_ATTR_MAP_DEFAULT(customOpenEnabled, enable_custom_scene_open, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(customOpenScene, custom_open_scene, @{}, @{})
    };
}

- (BOOL)canStart {
    return self.enableOpen || (self.customOpenEnabled && self.customOpenScene.count > 0);
}

@end
