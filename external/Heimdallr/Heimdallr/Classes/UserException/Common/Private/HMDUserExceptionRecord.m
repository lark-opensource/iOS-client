//
//  HMDUserExceptionRecord.m
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/4/1.
//

#import "HMDUserExceptionRecord.h"
#import "HMDUserExceptionConfig.h"
#import "HMDMemoryUsage.h"
#import "HMDMacro.h"
#import "HMDInjectedInfo+UniqueKey.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

NSString *const kHMDUserExceptionEventType = @"custom_exception";

@implementation HMDUserExceptionRecord
+ (NSString *)tableName {
    return [HMDUserExceptionConfig configKey];
}

- (NSDictionary *)reportDictionary {
    NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
    long long timestamp = MilliSecond(self.timestamp);
    [dataValue setValue:@(timestamp) forKey:@"timestamp"];
    [dataValue setValue:kHMDUserExceptionEventType forKey:@"event_type"];
    [dataValue setValue:self.sessionID forKey:@"session_id"];
    [dataValue setValue:self.log forKey:@"stack"];
    [dataValue setValue:self.title forKey:@"title"];
    [dataValue setValue:self.subTitle forKey:@"subtitle"];
    [dataValue setValue:(self.needSymbolicate ? @(0) : @(1)) forKey:@"disable_symbolicate"];
    [dataValue setValue:@(self.inAppTime) forKey:@"inapp_time"];
    [dataValue setValue:self.type forKey:@"custom_exception_type"];
    [dataValue setValue:@(self.memoryUsage) forKey:@"memory_usage"];
    [dataValue setValue:@(self.freeDiskBlockSize) forKey:@"d_zoom_free"];
    [dataValue setValue:@(hmd_calculateMemorySizeLevel(((uint64_t)self.freeMemoryUsage)*HMD_MEMORY_MB)) forKey:HMD_Free_Memory_Key];
    hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
    CGFloat          allMemory   = memoryBytes.totalMemory / HMD_MB;
    CGFloat freeMemoryRate = ((int)(self.freeMemoryUsage/allMemory*100))/100.0;
    [dataValue setValue:@(freeMemoryRate) forKey:HMD_Free_Memory_Percent_key];
    [dataValue setValue:self.business forKey:@"business"];
    [dataValue setValue:self.lastScene forKey:@"last_scene"];
    [dataValue setValue:self.operationTrace forKey:@"operation_trace"];
    [dataValue setValue:@(self.netQualityType) forKey:@"network_quality"];
    if (self.customParams.count > 0) {
        [dataValue setValue:self.customParams forKey:@"custom"];
    }
    if (self.filters.count > 0) {
        [dataValue setValue:self.filters forKey:@"filters"];
    }
    if (self.addressList.count > 0) {
        [dataValue setValue:self.addressList forKey:@"custom_address_analysis"];
    }
    
    if (self.viewHierarchy) {
        [dataValue setObject:self.viewHierarchy forKey:@"view_hierarchy"];
    }
    
    [dataValue addEntriesFromDictionary:self.environmentInfo];

    [[HMDInjectedInfo defaultInfo] confUniqueKeyForData:dataValue timestamp:timestamp eventType:kHMDUserExceptionEventType];
    [dataValue setValue:@(self.enableUpload) forKey:@"enable_upload"];
    if (hermas_enabled() && self.sequenceCode >= 0) {
        [dataValue setValue:@(self.sequenceCode) forKey:@"sequence_code"];
    }
    return dataValue;
}
@end
