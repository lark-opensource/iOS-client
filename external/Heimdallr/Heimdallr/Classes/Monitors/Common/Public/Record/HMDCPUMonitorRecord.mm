//
//  HMDCPUMonitorRecord.m
//  Heimdallr
//
//  Created by fengyadong on 2018/6/14.
//

#import "HMDCPUMonitorRecord.h"
#import "HMDMacro.h"
#import "HMDPerformanceAggregate+FindMaxValue.h"
#import "HMDMonitorRecord+Private.h"
#import "NSDictionary+HMDSafe.h"

#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

@implementation HMDCPUMonitorRecord

- (HMDMonitorRecordValue)value {
    return self.appUsage;
}

- (id)copyWithZone:(NSZone *)zone {
    HMDCPUMonitorRecord *model = [[[self class] allocWithZone:zone] init];
    model.sessionID = self.sessionID;
    model.timestamp = self.timestamp;
    model.isReported = self.isReported;
    model.inAppTime = self.inAppTime;
    model.scene = self.scene;
    model.isBackground = self.isBackground;
    model.threadDict = self.threadDict;
    return model;
}

- (NSDictionary *)reportDictionary {
    NSMutableDictionary *extraValues = [NSMutableDictionary dictionary];
    if([self.service isEqualToString:@"cpu"]) {
        [extraValues setValue:@(self.appUsage) forKey:@"app_usage"];
        [extraValues setValue:@(self.appUsage) forKey:@"peak_usage"];
        if (self.gpu > 0) {
            [extraValues setValue:@(self.gpu) forKey:@"app_gpu"];
        }
    } else if([self.service isEqualToString:@"cpu_thread"]){
        if (self.threadDict) {
            [extraValues addEntriesFromDictionary:self.threadDict];
        }
    }
    else {
        return nil;
    }
    
    NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
    
    [dataValue setValue:extraValues forKey:@"extra_values"];

    NSString *logType = hermas_enabled() ? @"performance_monitor" : @"performance_monitor_debug";
    [dataValue setValue:@(MilliSecond(self.timestamp)) forKey:@"timestamp"];
    [dataValue setValue:self.sessionID forKey:@"session_id"];
    [dataValue setValue:@(self.inAppTime) forKey:@"inapp_time"];

    [dataValue setValue:self.service forKey:@"service"];
    [dataValue setValue:logType forKey:@"log_type"];
    
    [dataValue setValue:self.business forKey:@"business"];
    [dataValue setValue:@(self.localID) forKey:@"log_id"];
    [dataValue setValue:@"HMDCPUMonitorRecord" forKey:@"class_name"];
    [dataValue setValue:@(self.netQualityType) forKey:@"network_quality"];

    NSMutableDictionary *extraStatusDict = [NSMutableDictionary dictionary];
    [extraStatusDict setValue:@(self.isBackground) forKey:@"is_background"];
    [extraStatusDict setValue:@(self.baseSample) forKey:@"base_sample"];
    [extraStatusDict setValue:@(self.isSpecialSceneOpenRecord) forKey:@"is_special_scene_open"];
    [extraStatusDict hmd_addEntriesFromDict:[HMDMonitorRecord getInjectedPatchFilters]];
    if(self.scene.length > 0) {
        [extraStatusDict setValue:self.scene forKey:@"scene"];
    }
    if(self.customScene.length > 0) {
        [extraStatusDict setValue:self.customScene forKey:@"custom_scene"];
    }
    NSString *tmaID = [self.filters valueForKey:@"tma_app_id"];
    if (tmaID && [tmaID isKindOfClass:[NSString class]]) {
        [extraStatusDict setValue:tmaID forKey:@"tma_app_id"];
    }
    [dataValue setObject:extraStatusDict forKey:@"extra_status"];
    [dataValue setValue:@(self.enableUpload) forKey:@"enable_upload"];
    return dataValue;
}

+ (NSArray *)aggregateDataWithRecords:(NSArray<HMDCPUMonitorRecord *> *)records {
    NSMutableArray *array = [NSMutableArray array];
    [array addObjectsFromArray:[HMDCPUMonitorRecord aggregateCPURecords:records]];
    [array addObjectsFromArray:[HMDCPUMonitorRecord aggregateCPUThreadRecords:records]];
    return array;
}

+ (NSArray *)aggregateCPURecords:(NSArray<HMDCPUMonitorRecord *> *)records {
    HMDPerformanceAggregate *aggregate = [[HMDPerformanceAggregate alloc] init]; 
    
    for (int index = 0; index < records.count; index ++) {
        HMDCPUMonitorRecord *record = records[index];
        if(![record.service isEqualToString:@"cpu"]) {
            continue;
        }
        
        NSMutableDictionary *needAggregateDictionary = [NSMutableDictionary dictionary];
        
        NSMutableDictionary *extraValues = [NSMutableDictionary dictionary];
        [extraValues setValue:@(record.appUsage) forKey:@"app_usage"];
        if (record.gpu > 0) {
            [extraValues setValue:@(record.gpu) forKey:@"app_gpu"];
        }
        
        [needAggregateDictionary setValue:[extraValues mutableCopy] forKey:@"extra_values"];
        
        NSMutableDictionary *normalDictionary = [NSMutableDictionary dictionary];
        [normalDictionary setValue:record.service forKey:@"service"];
        [normalDictionary setValue:@"performance_monitor" forKey:@"log_type"];
        [normalDictionary setValue:@(MilliSecond(record.timestamp)) forKey:@"timestamp"];
        [normalDictionary setValue:@(record.inAppTime) forKey:@"inapp_time"];
        [normalDictionary setValue:record.business forKey:@"business"];
        [normalDictionary setValue:@(record.netQualityType) forKey:@"network_quality"];

        NSMutableDictionary *extraStatusDict = [NSMutableDictionary dictionary];
        [extraStatusDict hmd_addEntriesFromDict:[HMDMonitorRecord getInjectedPatchFilters]];
        [extraStatusDict setValue:@(record.isBackground) forKey:@"is_background"];
        [extraStatusDict setValue:@(record.baseSample) forKey:@"base_sample"];
        [extraStatusDict setValue:@(record.isSpecialSceneOpenRecord) forKey:@"is_special_scene_open"];
        if(record.scene.length > 0) {
            [extraStatusDict setValue:record.scene forKey:@"scene"];
        }
        if(record.customScene.length > 0) {
            [extraStatusDict setValue:record.customScene forKey:@"custom_scene"];
        }
        NSString *tmaID = [record.filters valueForKey:@"tma_app_id"];
        if (tmaID && [tmaID isKindOfClass:[NSString class]]) {
            [extraStatusDict setValue:tmaID forKey:@"tma_app_id"];
        }

        NSMutableDictionary *findPickUsage = [NSMutableDictionary dictionary];
        [findPickUsage setValue:@{@"peak_usage": @(record.appUsage)}.mutableCopy forKey:@"extra_values"];


        [aggregate findMaxValueAggregateWithSessionID:record.sessionID
                                        aggregateKeys:extraStatusDict
                              needAggregateDictionary:needAggregateDictionary
                                     normalDictionary:normalDictionary
                                       listDictionary:nil
                                    currentecordIndex:index
                               findMaxValueDictionary:findPickUsage];
    }
    
    return [aggregate getAggregateRecords];
}

+ (NSArray *)aggregateCPUThreadRecords:(NSArray<HMDCPUMonitorRecord *> *)records {
    HMDPerformanceAggregate *aggregate = [[HMDPerformanceAggregate alloc] init];
    
    for (int index = 0; index < records.count; index ++) {
        HMDCPUMonitorRecord *record = records[index];
        if(![record.service isEqualToString:@"cpu_thread"]) {
            continue;
        }
        
        NSMutableDictionary *needAggregateDictionary = [NSMutableDictionary dictionary];
        
        NSMutableDictionary *extraValues = [NSMutableDictionary dictionary];
        if (record.threadDict) {
            [extraValues addEntriesFromDictionary:record.threadDict];
        }
        
        [needAggregateDictionary setValue:[extraValues mutableCopy] forKey:@"extra_values"];
        
        NSMutableDictionary *normalDictionary = [NSMutableDictionary dictionary];
        [normalDictionary setValue:record.service forKey:@"service"];
        [normalDictionary setValue:@"performance_monitor" forKey:@"log_type"];
        [normalDictionary setValue:@(MilliSecond(record.timestamp)) forKey:@"timestamp"];
        [normalDictionary setValue:@(record.inAppTime) forKey:@"inapp_time"];
        [normalDictionary setValue:record.business forKey:@"business"];
        [normalDictionary setValue:@(record.netQualityType) forKey:@"network_quality"];

        NSMutableDictionary *extraStatusDict = [NSMutableDictionary dictionary];
        [extraStatusDict setValue:@(record.isBackground) forKey:@"is_background"];
        [extraStatusDict setValue:@(record.baseSample) forKey:@"base_sample"];
        [extraStatusDict hmd_addEntriesFromDict:[HMDMonitorRecord getInjectedPatchFilters]];
        if(record.scene.length > 0) {
            [extraStatusDict setValue:record.scene forKey:@"scene"];
        }
        if(record.customScene.length > 0) {
            [extraStatusDict setValue:record.customScene forKey:@"custom_scene"];
        }
        NSString *tmaID = [record.filters valueForKey:@"tma_app_id"];
        if (tmaID && [tmaID isKindOfClass:[NSString class]]) {
            [extraStatusDict setValue:tmaID forKey:@"tma_app_id"];
        }

        [aggregate aggregateWithSessionID:record.sessionID
                            aggregateKeys:extraStatusDict
                  needAggregateDictionary:needAggregateDictionary
                         normalDictionary:normalDictionary
                           listDictionary:nil
                        currentecordIndex:index];
    }
    
    return [aggregate getAggregateRecords];
}

@end
