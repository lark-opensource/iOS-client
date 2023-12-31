//
//  HMDWatchDogRecord.m
//  Heimdallr
//
//  Created by sunrunwang on don't matter time
//

#import "HMDWatchDogRecord.h"
#import "HMDSessionTracker.h"
#import "HMDWatchDogDefine.h"
#import "HMDMemoryUsage.h"
#import "HMDMacro.h"
#import "HMDInjectedInfo.h"
#import "HMDInjectedInfo+UniqueKey.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

NSString * const kHMDWatchDogRecordTableName = @"HMDWatchDogRecordTable";
NSString *const kHMDWatchDogEventType = @"watch_dog";

@implementation HMDWatchDogRecord

+ (NSString *)tableName {
    return kHMDWatchDogRecordTableName;
}

+ (NSArray <NSDictionary *>*)reportDataForRecords:(NSArray *)records {
    return nil;
}

+ (NSArray <NSDictionary *>*)aggregateDataForRecords:(NSArray *)records {
    return nil;
}

+ (instancetype)newRecord {
    __kindof HMDWatchDogRecord *record = [super newRecord];
    return record;
}

- (NSDictionary *)reportDictionary {
    
    NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
    [dataValue setValue:kHMDWatchDogEventType forKey:@"event_type"];
    [dataValue setValue:@(self.memoryUsage) forKey:kHMDWatchDogExportKeyMemoryUsage];
    hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
    double allMemory = memoryBytes.totalMemory/HMD_MB;
    [dataValue setValue:@(self.freeDiskBlocks) forKey:kHMDWatchDogExportKeyFreeDiskBlocks];
    [dataValue setValue:@(hmd_calculateMemorySizeLevel(((uint64_t)self.freeMemoryUsage)*HMD_MEMORY_MB)) forKey:HMD_Free_Memory_Key];
    double free_memory_percent = (int)(self.freeMemoryUsage/allMemory*100)/100.0;
    [dataValue setValue:@(free_memory_percent) forKey:HMD_Free_Memory_Percent_key];
    [dataValue setValue:self.backtrace forKey:kHMDWatchDogExportKeyStack];
    [dataValue setValue:self.connectionTypeName forKey:kHMDWatchDogExportKeyNetwork];
    [dataValue setValue:@(self.timeoutDuration * 1000) forKey:kHMDWatchDogExportKeyTimeoutDuration];
    long long timestamp = MilliSecond(self.timestamp);
    [dataValue setValue:self.sessionID forKey:kHMDWatchDogExportKeySessionID];
    [dataValue setValue:@(timestamp) forKey:kHMDWatchDogExportKeyTimestamp];
    [dataValue setValue:@(self.inAppTime) forKey:kHMDWatchDogExportKeyinAppTime];
    [dataValue setValue:self.business forKey:kHMDWatchDogExportKeyBusiness];
    [dataValue setValue:self.lastScene forKey:kHMDWatchDogExportKeylastScene];
    [dataValue setValue:self.operationTrace forKey:kHMDWatchDogExportKeyOperationTrace];
    [dataValue setValue:@(self.isBackground) forKey:kHMDWatchDogExportKeyIsBackground];
    [dataValue setValue:@(self.isLaunchCrash) forKey:kHMDWatchDogExportKeyIsLaunchCrash];
    [dataValue setValue:self.settings forKey:kHMDWatchDogExportKeySettings];
    
    if (self.customParams.count > 0)
        [dataValue setValue:self.customParams forKey:kHMDWatchDogExportKeyCustom];
    if (self.filters.count > 0) {
        [dataValue setValue:self.filters forKey:kHMDWatchDogExportKeyFilters];
    }
    
    [dataValue setValue:self.timeline forKey:kHMDWatchDogExportKeyTimeline];
    [dataValue addEntriesFromDictionary:self.environmentInfo];
    [dataValue setObject:@(self.isMainDeadlock) forKey:kHMDWatchDogExportKeyIsMainDeadlock];
    if(self.deadlock){
        [dataValue setObject:self.deadlock forKey:kHMDWatchDogExportKeyDeadlock];
    }
    
    [dataValue setObject:@(self.exceptionMainAddress) forKey:kHMDWatchDogExportKeyExeptionMainAdress];
    [[HMDInjectedInfo defaultInfo] confUniqueKeyForData:dataValue timestamp:timestamp eventType:kHMDWatchDogEventType];
    [dataValue setValue:@(self.enableUpload) forKey:@"enable_upload"];
    if (hermas_enabled() && self.sequenceCode >= 0) {
        [dataValue setValue:@(self.sequenceCode) forKey:@"sequence_code"];
    }
    return [dataValue copy];
}

@end
