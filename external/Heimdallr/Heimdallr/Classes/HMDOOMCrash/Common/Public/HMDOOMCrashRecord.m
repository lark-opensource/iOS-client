//
//  HMDOOMCrashRecord.m
//  Heimdallr
//
//  Created by sunrunwang on don't matter time
//

#import "HMDOOMCrashRecord.h"
#import "HMDSessionTracker.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDMacro.h"
#import "HMDMemoryUsage.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

NSString * const kHMDOOMCrashRecordTableName = @"HMDOOMCrashRecordTableName";

@implementation HMDOOMCrashRecord

#pragma mark - HMDRecordStoreObject protocol

+ (NSString *)tableName {
    return kHMDOOMCrashRecordTableName;
}

+ (NSArray <NSDictionary *>*)reportDataForRecords:(NSArray *)records {
    return nil;
}

+ (NSArray <NSDictionary *>*)aggregateDataForRecords:(NSArray *)records {
    return nil;
}

#pragma mark - HMDTrackerRecord

+ (instancetype)newRecord {
    __kindof HMDOOMCrashRecord *record = [super newRecord];
    return record;
}


- (NSDictionary *)reportDictionary {
    NSMutableDictionary *dataValue = [super reportDictionary].mutableCopy;
    long long timestamp = MilliSecond(self.timestamp);
    [dataValue setValue:@"oom_crash" forKey:@"event_type"];
    [dataValue setValue:self.sessionID forKey:@"session_id"];
    [dataValue setValue:self.internalStorageSession forKey:@"internal_session_id"];
    [dataValue setValue:@(timestamp) forKey:@"timestamp"];
    [dataValue setValue:@(self.appUsedMemory) forKey:@"memory_usage"];
    [dataValue setValue:@(self.freeDiskBlockSize) forKey:@"d_zoom_free"];
    [dataValue setValue:@(hmd_calculateMemorySizeLevel(((uint64_t)self.deviceFreeMemory)*HMD_MEMORY_MB)) forKey:HMD_Free_Memory_Key];
    [dataValue setValue:self.business forKey:@"business"];
    [dataValue setValue:@(self.inAppTime) forKey:@"inapp_time"];
    [dataValue setValue:self.lastScene forKey:@"last_scene"];
    [dataValue setValue:self.operationTrace forKey:@"operation_trace"];
    [dataValue setValue:@(self.netQualityType) forKey:@"network_quality"];
    
    [dataValue addEntriesFromDictionary:self.environmentInfo];

    if (self.customParams.count > 0)
        [dataValue setValue:self.customParams forKey:@"custom"];
    
    if (self.filters.count > 0) {
        [dataValue setValue:self.filters forKey:@"filters"];
    }
    CLANG_DIAGNOSTIC_PUSH
    CLANG_DIAGNOSTIC_IGNORE_DEPRECATED_DECLARATIONS
    if (self.loginfo) {
        [dataValue setValue:self.loginfo forKey:@"log_info"];
    }
    CLANG_DIAGNOSTIC_POP
    [dataValue hmd_setObject:@(self.enableUpload) forKey:@"enable_upload"];
    if (hermas_enabled() && self.sequenceCode >= 0) {
        [dataValue setValue:@(self.sequenceCode) forKey:@"sequence_code"];
    }
    return [dataValue copy];
}

@end
