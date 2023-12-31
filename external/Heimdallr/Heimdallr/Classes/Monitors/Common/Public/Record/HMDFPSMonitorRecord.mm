//
//  HMDFPSMonitorRecord.m
//  Heimdallr
//
//  Created by fengyadong on 2018/6/14.
//

#import "HMDFPSMonitorRecord.h"
#import "HMDMacro.h"
#import "HMDMonitorRecord+Private.h"
#import "NSDictionary+HMDSafe.h"

#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

@implementation HMDFPSMonitorRecord

- (HMDMonitorRecordValue)value {
    return self.fps;
}

- (NSDictionary *)reportDictionary
{
    NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
    
    long long time = MilliSecond(self.timestamp);
    NSString *logType = hermas_enabled() ? @"performance_monitor" : @"performance_monitor_debug";
    
    // normal
    [dataValue setValue:@(time) forKey:@"timestamp"];
    [dataValue setValue:self.sessionID forKey:@"session_id"];
    [dataValue setValue:@(self.inAppTime) forKey:@"inapp_time"];
    [dataValue setValue:@"fps" forKey:@"service"];
    [dataValue setValue:self.business forKey:@"business"];
    [dataValue setValue:logType forKey:@"log_type"];
    [dataValue setValue:@(self.localID) forKey:@"log_id"];
    [dataValue setValue:@"HMDFPSMonitorRecord" forKey:@"class_name"];
    [dataValue setValue:@(self.netQualityType) forKey:@"network_quality"];

    // extra value
    NSMutableDictionary *extraValue = [NSMutableDictionary dictionaryWithCapacity:1];
    [extraValue setValue:@(self.fps) forKey:@"fps"];
    if (self.fpsExtralValue && self.fpsExtralValue.count > 0) {
        [extraValue addEntriesFromDictionary:self.fpsExtralValue];
    }
    [dataValue setValue:extraValue forKey:@"extra_values"];

    // extra status
    NSMutableDictionary *extraStatus = [NSMutableDictionary new];
    if(self.scene.length > 0) {
        [extraStatus setValue:self.scene forKey:@"scene"];
    }
    if (self.customScene.length > 0) {
        [extraStatus setValue:self.customScene forKey:@"custom_scene"];
    }
    if (self.refreshRate == 0) {
        self.refreshRate = 60; //默认 60 帧;
    }
    [extraStatus setValue:@(self.refreshRate) forKey:@"refresh_rate"];
    [extraStatus setValue:@(self.isScrolling) forKey:@"isScrolling"];
    [extraStatus setValue:@(self.sceneInSwitch) forKey:@"is_scene_switch"];
    [extraStatus setValue:@(self.isLowPowerMode) forKey:@"is_low_power_mode"];
    [extraStatus setValue:@(self.baseSample) forKey:@"base_sample"];
    [extraStatus setValue:@(self.isSpecialSceneOpenRecord) forKey:@"is_special_scene_open"];
    NSString *useAppTimeTag = @"in_app_time_step";
    NSTimeInterval inAppTime = self.inAppTime;
    if (inAppTime > 0 && inAppTime <= 10) {
        [extraStatus setValue:kHMDMonitorLaunchTagIn10sec forKey:useAppTimeTag];
    } else if (inAppTime > 10 && inAppTime <= 30) {
        [extraStatus setValue:kHMDMonitorLaunchTagIn30sec forKey:useAppTimeTag];
    } else if (inAppTime > 30 && inAppTime <= 60) {
        [extraStatus setValue:kHMDMonitorLaunchTagInOneMin forKey:useAppTimeTag];
    } else if (inAppTime > 60) {
        [extraStatus setValue:kHMDMonitorLaunchTagGreaterThanOneMin forKey:useAppTimeTag];
    }
    [extraStatus hmd_addEntriesFromDict:[HMDMonitorRecord getInjectedPatchFilters]];
    NSString *tmaID = [self.filters valueForKey:@"tma_app_id"];
    if (tmaID && [tmaID isKindOfClass:[NSString class]]) {
        [extraStatus setValue:tmaID forKey:@"tma_app_id"];
    }
    [dataValue setValue:extraStatus forKey:@"extra_status"];
    
    // enable_upload
    [dataValue setValue:@(self.enableUpload) forKey:@"enable_upload"];
    return dataValue;
}

+ (NSArray *)aggregateDataWithRecords:(NSArray<HMDFPSMonitorRecord *> *)records
{
    HMDPerformanceAggregate *aggregate = [[HMDPerformanceAggregate alloc] init];
    
    for (int index = 0; index < records.count; index ++) {
        HMDFPSMonitorRecord *record = records[index];
        
        NSMutableDictionary *needAggregateDictionary = [NSMutableDictionary dictionary];
        
        NSMutableDictionary *extraValue = [NSMutableDictionary dictionaryWithCapacity:1];
        [extraValue setValue:@(record.fps) forKey:@"fps"];
        if (record.fpsExtralValue && record.fpsExtralValue.count > 0) {
            [extraValue addEntriesFromDictionary:record.fpsExtralValue];
        }
        
        [needAggregateDictionary setValue:[extraValue mutableCopy] forKey:@"extra_values"];
        
        NSMutableDictionary *extraStatus = [NSMutableDictionary new];
        if(record.scene.length > 0) {
            [extraStatus setValue:record.scene forKey:@"scene"];
        }
        if (record.customScene.length > 0) {
            [extraStatus setValue:record.customScene forKey:@"custom_scene"];
        }
        if (record.refreshRate == 0) {
            record.refreshRate = 60; //默认 60 帧;
        }
        [extraStatus setValue:@(record.refreshRate) forKey:@"refresh_rate"];
        NSString *tmaID = [record.filters valueForKey:@"tma_app_id"];
        if (tmaID && [tmaID isKindOfClass:[NSString class]]) {
            [extraStatus setValue:tmaID forKey:@"tma_app_id"];
        }
        [extraStatus setValue:@(record.isScrolling) forKey:@"isScrolling"];
        [extraStatus setValue:@(record.sceneInSwitch) forKey:@"is_scene_switch"];
        [extraStatus setValue:@(record.isLowPowerMode) forKey:@"is_low_power_mode"];
        [extraStatus setValue:@(record.baseSample) forKey:@"base_sample"];
        [extraStatus setValue:@(record.isSpecialSceneOpenRecord) forKey:@"is_special_scene_open"];
        NSString *useAppTimeTag = @"in_app_time_step";
        NSTimeInterval inAppTime = record.inAppTime;
        if (inAppTime > 0 && inAppTime <= 10) {
            [extraStatus setValue:kHMDMonitorLaunchTagIn10sec forKey:useAppTimeTag];
        } else if (inAppTime > 10 && inAppTime <= 30) {
            [extraStatus setValue:kHMDMonitorLaunchTagIn30sec forKey:useAppTimeTag];
        } else if (inAppTime > 30 && inAppTime <= 60) {
            [extraStatus setValue:kHMDMonitorLaunchTagInOneMin forKey:useAppTimeTag];
        } else if (inAppTime > 60) {
            [extraStatus setValue:kHMDMonitorLaunchTagGreaterThanOneMin forKey:useAppTimeTag];
        }
        
        [extraStatus hmd_addEntriesFromDict:[HMDMonitorRecord getInjectedPatchFilters]];

        NSMutableDictionary *normalDictionary = [NSMutableDictionary dictionary];
        [normalDictionary setValue:@"fps" forKey:@"service"];
        [normalDictionary setValue:@"performance_monitor" forKey:@"log_type"];
        long long time = MilliSecond(record.timestamp);
        [normalDictionary setValue:@(time) forKey:@"timestamp"];
        [normalDictionary setValue:@(record.inAppTime) forKey:@"inapp_time"];
        [normalDictionary setValue:record.business forKey:@"business"];
        [normalDictionary setValue:@(record.netQualityType) forKey:@"network_quality"];

        [aggregate aggregateWithSessionID:record.sessionID
                            aggregateKeys:extraStatus
                  needAggregateDictionary:needAggregateDictionary
                         normalDictionary:normalDictionary
                           listDictionary:nil
                        currentecordIndex:index];
    }
    
    return [aggregate getAggregateRecords];
}

+ (NSUInteger)cleanupWeight {
    return 90;
}

@end
