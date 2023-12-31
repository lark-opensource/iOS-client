//
//  HMDUIFrozenRecord.m
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/3/24.
//

#import "HMDUIFrozenRecord.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDMacro.h"
#import "HMDMemoryUsage.h"
#import "HMDInjectedInfo+UniqueKey.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

NSString * const kHMDUIFrozenRecordTableName = @"HMDUIFrozenRecordTable";
extern NSString *const kHMDUIFrozenEventType;

// 监控数据
extern NSString * const kHMDUIFrozenKeyType;
extern NSString * const kHMDUIFrozenKeyTargetView;
extern NSString * const kHMDUIFrozenKeyTargetWindow;
extern NSString * const kHMDUIFrozenKeyViewHierarchy;
extern NSString * const kHMDUIFrozenKeyResponseChain;
extern NSString * const kHMDUIFrozenKeyViewControllerHierarchy;
extern NSString * const kHMDUIFrozenKeySnapshot;
extern NSString * const kHMDUIFrozenKeyOperationCount;
extern NSString * const kHMDUIFrozenKeyIsLaunchCrash;
extern NSString * const kHMDUIFrozenKeyStartTimestamp;
extern NSString * const kHMDUIFrozenKeyTimestamp;
extern NSString * const kHMDUIFrozenKeyinAppTime;
extern NSString * const kHMDUIFrozenKeySettings;
extern NSString * const kHMDUIFrozenKeyNearViewController;
extern NSString * const kHMDUIFrozenKeyNearViewControllerDesc;

// 性能数据
extern NSString * const kHMDUIFrozenKeyNetwork;
extern NSString * const kHMDUIFrozenKeyMemoryUsage;
extern NSString * const kHMDUIFrozenKeyFreeMemoryUsage;
extern NSString * const kHMDUIFrozenKeyFreeDiskBlockSize;

// 业务数据
extern NSString * const kHMDUIFrozenKeyBusiness;
extern NSString * const kHMDUIFrozenKeySessionID;
extern NSString * const kHMDUIFrozenKeyInternalSessionID;
extern NSString * const kHMDUIFrozenKeylastScene;
extern NSString * const kHMDUIFrozenKeyOperationTrace;
extern NSString * const kHMDUIFrozenKeyNetQuality;
extern NSString * const kHMDUIFrozenKeyCustom;
extern NSString * const kHMDUIFrozenKeyFilters;


@implementation HMDUIFrozenRecord

+ (NSString *)tableName {
    return kHMDUIFrozenRecordTableName;
}

+ (NSArray <NSDictionary *>*)reportDataForRecords:(NSArray *)records {
    return nil;
}

+ (NSArray <NSDictionary *>*)aggregateDataForRecords:(NSArray *)records {
    return nil;
}

+ (instancetype)newRecord {
    __kindof HMDUIFrozenRecord *record = [super newRecord];
    return record;
}

- (NSDictionary *)reportDictionary {
    NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
    [dataValue setValue:kHMDUIFrozenEventType forKey:@"event_type"];
    
    // 监控数据
    [dataValue setValue:self.frozenType forKey:kHMDUIFrozenKeyType];
    [dataValue setValue:self.targetViewDescription forKey:kHMDUIFrozenKeyTargetView];
    [dataValue setValue:self.targetWindowDescription forKey:kHMDUIFrozenKeyTargetWindow];
    [dataValue setValue:self.viewHierarchy forKey:kHMDUIFrozenKeyViewHierarchy];
    [dataValue setValue:self.viewControllerHierarchy forKey:kHMDUIFrozenKeyViewControllerHierarchy];
    [dataValue setValue:self.responseChain forKey:kHMDUIFrozenKeyResponseChain];
    [dataValue setValue:self.nearViewController forKey:kHMDUIFrozenKeyNearViewController];
    [dataValue setValue:self.nearViewControllerDesc forKey:kHMDUIFrozenKeyNearViewControllerDesc];

    [dataValue setValue:@(self.operationCount) forKey:kHMDUIFrozenKeyOperationCount];
    long long timestamp = MilliSecond(self.timestamp);
    [dataValue setValue:@(timestamp) forKey:kHMDUIFrozenKeyTimestamp];
    [dataValue setValue:@(self.timestamp-self.startTS) forKey:@"duration"];
    [dataValue setValue:@(self.inAppTime) forKey:kHMDUIFrozenKeyinAppTime];
    [dataValue setValue:@(self.isLaunchCrash) forKey:kHMDUIFrozenKeyIsLaunchCrash];
    [dataValue setValue:self.settings forKey:kHMDUIFrozenKeySettings];
    
    // 性能数据
    [dataValue setValue:@(self.memoryUsage) forKey:kHMDUIFrozenKeyMemoryUsage];
    hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
    double allMemory = memoryBytes.totalMemory;
    [dataValue setValue:@(self.freeDiskBlocks) forKey:kHMDUIFrozenKeyFreeDiskBlockSize];
    [dataValue setValue:@(hmd_calculateMemorySizeLevel(self.freeMemoryUsage)) forKey:HMD_Free_Memory_Key];
    double free_memory_percent = (int)(self.freeMemoryUsage/allMemory*100)/100.0;
    [dataValue setValue:@(free_memory_percent) forKey:HMD_Free_Memory_Percent_key];
    [dataValue setValue:self.connectionTypeName forKey:kHMDUIFrozenKeyNetwork];
    
    // 业务数据
    [dataValue setValue:self.sessionID forKey:kHMDUIFrozenKeySessionID];
    [dataValue setValue:self.business forKey:kHMDUIFrozenKeyBusiness];
    [dataValue setValue:self.lastScene forKey:kHMDUIFrozenKeylastScene];
    [dataValue setValue:self.operationTrace forKey:kHMDUIFrozenKeyOperationTrace];
    if (self.customParams.count > 0)
        [dataValue setValue:self.customParams forKey:kHMDUIFrozenKeyCustom];
    if (self.filters.count > 0) {
        [dataValue setValue:self.filters forKey:kHMDUIFrozenKeyFilters];
    }

    [dataValue addEntriesFromDictionary:self.environmentInfo];
    [[HMDInjectedInfo defaultInfo] confUniqueKeyForData:dataValue timestamp:timestamp eventType:kHMDUIFrozenEventType];
    [dataValue setValue:@(self.enableUpload) forKey:@"enable_upload"];
    if (hermas_enabled() && self.sequenceCode >= 0) {
        [dataValue setValue:@(self.sequenceCode) forKey:@"sequence_code"];
    }
    return [dataValue copy];
}

@end
