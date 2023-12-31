//
//  HMDExceptionRecord.m
//  Heimdallr
//
//  Created by fengyadong on 2018/4/11.
//
#import "HMDExceptionRecord.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDMacro.h"
#import "HMDMemoryUsage.h"
#import "HMDInjectedInfo+UniqueKey.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

NSString *const kHMDExceptionEventType = @"exception";

@implementation HMDExceptionRecord

+ (NSString *)tableName {
    return @"exception";
}

+ (NSUInteger)cleanupWeight {
    return 0;
}

- (NSDictionary *)reportDictionary {
    NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
    
    long long timestamp = MilliSecond(self.timestamp);
    
    [dataValue setValue:@(timestamp) forKey:@"timestamp"];
    [dataValue setValue:kHMDExceptionEventType forKey:@"event_type"];
    [dataValue setValue:self.sessionID forKey:@"session_id"];
    [dataValue setValue:@(self.errorType) forKey:@"error_type"];
    [dataValue setValue:self.protectTypeString forKey:@"protect_type_string"];
    [dataValue setValue:self.reason forKey:@"reason"];
    [dataValue setValue:self.crashKey forKey:@"crashKey"];
    [dataValue setValue:self.crashKeyList forKey:@"crashKeyList"];
    [dataValue setValue:self.exceptionLogStr forKey:@"stack"];
    [dataValue setValue:@(self.memoryUsage) forKey:@"memory_usage"];
    [dataValue setValue:@(self.freeDiskBlockSize) forKey:@"d_zoom_free"];
    [dataValue setValue:@(hmd_calculateMemorySizeLevel(((uint64_t)self.freeMemoryUsage)*HMD_MEMORY_MB)) forKey:HMD_Free_Memory_Key];
    [dataValue setValue:self.lastScene forKey:@"last_scene"];
    [dataValue setValue:self.operationTrace forKey:@"operation_trace"];
    [dataValue setValue:@(self.inAppTime) forKey:@"inapp_time"];
    if (self.customParams.count > 0) {
        [dataValue setValue:self.customParams forKey:@"custom"];
    }
    
    if (self.filterParams.count > 0) {
        [dataValue setValue:self.filterParams forKey:@"filters"];
    }
    if (self.settings.count > 0) {
        [dataValue setValue:self.settings forKey:@"settings"];
    }
    
    [dataValue addEntriesFromDictionary:self.environmentInfo];
    
    [[HMDInjectedInfo defaultInfo] confUniqueKeyForData:dataValue timestamp:timestamp eventType:kHMDExceptionEventType];
    
    [dataValue setValue:@(self.enableUpload) forKey:@"enable_upload"];
    if (hermas_enabled() && self.sequenceCode >= 0) {
        [dataValue setValue:@(self.sequenceCode) forKey:@"sequence_code"];
    }
    return [dataValue copy];
}

@end
