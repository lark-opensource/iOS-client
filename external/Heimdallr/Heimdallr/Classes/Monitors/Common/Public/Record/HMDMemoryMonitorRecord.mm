//
//  HMDMemoryMonitorRecord.m
//  Heimdallr
//
//  Created by fengyadong on 2018/6/14.
//

#import "HMDMemoryMonitorRecord.h"
#import "HMDMacro.h"
#import "NSDictionary+HMDSafe.h"
#import "NSArray+HMDSafe.h"
#import "HMDMemoryUsage.h"
#import "HMDMonitorRecord+Private.h"

#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

static const int memoryLevel = 100 * HMD_MB;

@implementation HMDMemoryMonitorRecord

- (HMDMonitorRecordValue)value {
    return self.appUsedMemory/HMD_MB;
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
    [dataValue setValue:@"memory" forKey:@"service"];
    [dataValue setValue:logType forKey:@"log_type"];
    [dataValue setValue:self.business forKey:@"business"];
    [dataValue setValue:@(self.localID) forKey:@"log_id"];
    [dataValue setValue:@"HMDMemoryMonitorRecord" forKey:@"class_name"];
    [dataValue setValue:@(self.netQualityType) forKey:@"network_quality"];
    if (self.dumpInfo.count > 0) {
        [dataValue setValue:self.dumpInfo forKey:@"dump"];
    }

    // extra value
    NSMutableDictionary *extraValue = [NSMutableDictionary dictionary];
    [extraValue setValue:@(self.appUsedMemory) forKey:@"app_memory"];
    [extraValue setValue:@(hmd_calculateMemorySizeLevel(self.totalMemory)) forKey:HMD_Total_Memory_Key];
    [extraValue setValue:@(hmd_calculateMemorySizeLevel(self.availableMemory)) forKey:HMD_Free_Memory_Key];
    [extraValue setValue:@(self.usedMemory) forKey:@"used_memory"];
    if (self.totalMemory > 0) {
        double rate = self.appUsedMemory / self.totalMemory;
        rate = ((int)(rate * 100)) / 100.0;
        [extraValue setValue:@(rate) forKey:HMD_Free_Memory_Percent_key];
    }
    if (self.pageUsedMemory > 0) {
        [extraValue setValue:@(self.pageUsedMemory) forKey:@"page_usage"];
    }
    if (self.customUsedMemory > 0) {
        [extraValue setValue:@(self.customUsedMemory) forKey:@"custom_usage"];
    }
    [dataValue setValue:extraValue forKey:@"extra_values"];
    
    // extra status
    NSMutableDictionary *extraStatus = [NSMutableDictionary dictionary];
    [extraStatus setValue:@(self.memoryWarning) forKey:@"memory_warning"];
    [extraStatus setValue:@(self.baseSample) forKey:@"base_sample"];
    [extraStatus setValue:@(self.isSpecialSceneOpenRecord) forKey:@"is_special_scene_open"];
    if (self.scene) {
        [extraStatus setValue:self.scene forKey:@"scene"];
    }
    if (self.customScene.length > 0) {
        [extraStatus setValue:self.customScene forKey:@"custom_scene"];
    }
    [extraStatus setValue:@(self.isBackground) forKey:@"is_background"];
    [extraStatus setValue:@(self.baseSample) forKey:@"base_sample"];
    [extraStatus hmd_addEntriesFromDict:[HMDMonitorRecord getInjectedPatchFilters]];
    NSString *tmaID = [self.filters valueForKey:@"tma_app_id"];
    if (tmaID && [tmaID isKindOfClass:[NSString class]]) {
        [extraStatus setValue:tmaID forKey:@"tma_app_id"];
    }
    [dataValue setValue:extraStatus forKey:@"extra_status"];
    
    // enable_upload
    [dataValue setValue:@(self.enableUpload) forKey:@"enable_upload"];
    
    // diff
    if (hermas_enabled()) {
        if (self.totalMemory > 0) {
            double rate = self.appUsedMemory/self.totalMemory;
            rate = ((int)(rate*100))/100.0;
            [extraValue setValue:@(rate) forKey:HMD_Free_Memory_Percent_key];
        }
        
        int level = self.appUsedMemory / memoryLevel;
        [extraStatus setValue:@(level) forKey:@"memory_level"];
        
        
    }
    
    return dataValue;
}

+ (NSArray *)aggregateDataWithRecords:(NSArray<HMDMemoryMonitorRecord *> *)records
{
    HMDPerformanceAggregate *aggregate = [[HMDPerformanceAggregate alloc] init];
    
    for (int index = 0; index < records.count; index ++) {
        HMDMemoryMonitorRecord *record = records[index];
        
        NSMutableDictionary *needAggregateDictionary = [NSMutableDictionary dictionary];
        
        NSMutableDictionary *extra_values = [NSMutableDictionary dictionary];
        [extra_values setValue:@(record.appUsedMemory) forKey:@"app_memory"];
        if (record.totalMemory > 0) {
            double rate = record.appUsedMemory/record.totalMemory;
            rate = ((int)(rate*100))/100.0;
            [extra_values setValue:@(rate) forKey:HMD_Free_Memory_Percent_key];
        }

        if (record.pageUsedMemory > 0) {
            [extra_values setValue:@(record.pageUsedMemory) forKey:@"page_usage"];
        }
        
        if (record.customUsedMemory > 0) {
            [extra_values setValue:@(record.customUsedMemory) forKey:@"custom_usage"];
        }
        [needAggregateDictionary setValue:extra_values forKey:@"extra_values"];
        
        NSMutableDictionary *normalDictionary = [NSMutableDictionary dictionary];
        [normalDictionary setValue:@"memory" forKey:@"service"];
        [normalDictionary setValue:@"performance_monitor" forKey:@"log_type"];
        long long time = MilliSecond(record.timestamp);
        [normalDictionary setValue:@(time) forKey:@"timestamp"];
        [normalDictionary setValue:@(record.inAppTime) forKey:@"inapp_time"];
        [normalDictionary setValue:record.business forKey:@"business"];
        [normalDictionary setValue:@(record.netQualityType) forKey:@"network_quality"];

        NSMutableDictionary *keysDictionary = [NSMutableDictionary dictionary];
        NSString *tmaID = [record.filters valueForKey:@"tma_app_id"];
        if (tmaID && [tmaID isKindOfClass:[NSString class]]) {
            [keysDictionary setValue:tmaID forKey:@"tma_app_id"];
        }
        [keysDictionary setValue:@(record.memoryWarning) forKey:@"memory_warning"];
        [keysDictionary setValue:@(record.isBackground) forKey:@"is_background"];
        [keysDictionary setValue:record.scene forKey:@"scene"];
        [keysDictionary setValue:@(record.baseSample) forKey:@"base_sample"];
        [keysDictionary setValue:@(record.isSpecialSceneOpenRecord) forKey:@"is_special_scene_open"];
        [keysDictionary hmd_addEntriesFromDict:[HMDMonitorRecord getInjectedPatchFilters]];

        if (record.customScene.length > 0) {
            [keysDictionary setValue:record.customScene forKey:@"custom_scene"];
        }
        int level = record.appUsedMemory / memoryLevel;
        [keysDictionary setValue:@(level) forKey:@"memory_level"];
        
        NSMutableDictionary *listDictionary = [NSMutableDictionary dictionary];
        if (record.dumpInfo.count > 0) {
            NSMutableArray *dumpArray = [NSMutableArray array];
            for (NSDictionary *info in record.dumpInfo) {
                [dumpArray hmd_addObject:[info mutableCopy]];
            }
            [listDictionary setValue:dumpArray forKey:@"dump"];
        }
        
        [aggregate aggregateWithSessionID:record.sessionID
                            aggregateKeys:keysDictionary
                  needAggregateDictionary:needAggregateDictionary
                         normalDictionary:normalDictionary
                           listDictionary:listDictionary
                        currentecordIndex:index];
    }
    
    return [aggregate getAggregateRecords];
}

+ (NSUInteger)cleanupWeight {
    return 40;
}

@end
