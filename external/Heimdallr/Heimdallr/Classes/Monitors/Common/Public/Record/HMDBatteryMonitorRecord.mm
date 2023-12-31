//
//  HMDBatteryMonitorRecord.m
//  Heimdallr
//
//  Created by fengyadong on 2018/6/14.
//


#import "HMDBatteryMonitorRecord.h"
#import "HMDMacro.h"
#import "HMDMonitorRecord+Private.h"
#import "NSDictionary+HMDSafe.h"

#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

@implementation HMDBatteryMonitorRecord

- (HMDMonitorRecordValue)value {
    return self.batteryLevel;
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
    [dataValue setValue:@"battery" forKey:@"service"];
    [dataValue setValue:logType forKey:@"log_type"];
    [dataValue setValue:@(self.localID) forKey:@"log_id"];
    [dataValue setValue:@"HMDBatteryMonitorRecord" forKey:@"class_name"];
    [dataValue setValue:@(self.netQualityType) forKey:@"network_quality"];

    // extral value
    NSMutableDictionary *extraValues = [NSMutableDictionary dictionaryWithCapacity:3];
    if (self.perMinuteUsage >= 0) {
        [extraValues setValue:@(self.perMinuteUsage) forKey:@"minute_usage"];
    }
    if (self.sessionUsage >= 0) {
        [extraValues setValue:@(self.sessionUsage) forKey:@"session_usage"];
    }
    [extraValues setValue:@(self.batteryLevel) forKey:@"level"];
    if (self.pageUsage >= 0) {
        [extraValues setValue:@(self.pageUsage) forKey:@"page_usage"];
    }
    [dataValue setValue:extraValues forKey:@"extra_values"];
    
    // extra status
    NSMutableDictionary *extraStatus = [NSMutableDictionary dictionary];
    [extraStatus setValue:@(self.batteryState) forKey:@"state"];
    [extraStatus setValue:self.scene forKey:@"scene"];
    [extraStatus setValue:@(self.isSpecialSceneOpenRecord) forKey:@"is_special_scene_open"];
    [extraStatus hmd_addEntriesFromDict:[HMDMonitorRecord getInjectedPatchFilters]];
    [dataValue setValue:extraStatus forKey:@"extra_status"];
    
    // enable_upload
    [dataValue setValue:@(self.enableUpload) forKey:@"enable_upload"];
    return dataValue;
}

+ (NSArray *)aggregateDataWithRecords:(NSArray<HMDBatteryMonitorRecord *> *)records
{
    HMDPerformanceAggregate *aggregate = [[HMDPerformanceAggregate alloc] init];
    for (int index = 0; index < records.count; index ++) {
        HMDBatteryMonitorRecord *record = records[index];
        
        NSMutableDictionary *needAggregateDictionary = [NSMutableDictionary dictionary];
        
        NSMutableDictionary *extraValues = [NSMutableDictionary dictionary];
        [extraValues setValue:@(record.batteryLevel) forKey:@"level"];
        if (record.perMinuteUsage >= 0) {
            [extraValues setValue:@(record.perMinuteUsage) forKey:@"minute_usage"];
        }
        if (record.pageUsage >= 0) {
            [extraValues setValue:@(record.pageUsage) forKey:@"page_usage"];
        }
        if (record.sessionUsage >= 0) {
            [extraValues setValue:@(record.sessionUsage) forKey:@"session_usage"];
        }
        [needAggregateDictionary setValue:[extraValues mutableCopy] forKey:@"extra_values"];
        
        NSMutableDictionary *normalDictionary = [NSMutableDictionary dictionary];
        [normalDictionary setValue:@"battery" forKey:@"service"];
        [normalDictionary setValue:@"performance_monitor" forKey:@"log_type"];
        long long time = MilliSecond(record.timestamp);
        [normalDictionary setValue:@(time) forKey:@"timestamp"];
        [normalDictionary setValue:@(record.inAppTime) forKey:@"inapp_time"];
        [normalDictionary setValue:@(record.netQualityType) forKey:@"network_quality"];

        NSMutableDictionary *keysDictionary = [NSMutableDictionary dictionary];
        [keysDictionary setValue:@(record.batteryState) forKey:@"state"];
        [keysDictionary setValue:record.scene forKey:@"scene"];
        [keysDictionary setValue:@(record.isSpecialSceneOpenRecord) forKey:@"is_special_scene_open"];
        [keysDictionary hmd_addEntriesFromDict:[HMDMonitorRecord getInjectedPatchFilters]];
        [aggregate aggregateWithSessionID:record.sessionID
                            aggregateKeys:keysDictionary
                  needAggregateDictionary:needAggregateDictionary
                         normalDictionary:normalDictionary
                           listDictionary:nil
                        currentecordIndex:index];
    }
    
    return [aggregate getAggregateRecords];
}

+ (NSUInteger)cleanupWeight {
    return 40;
}

@end
