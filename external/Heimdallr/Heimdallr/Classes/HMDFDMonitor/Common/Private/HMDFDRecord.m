//
//  HMDFDRecord.m
//  Pods
//
//  Created by wangyinhui on 2022/2/10.
//

#import "HMDFDRecord.h"
#import "HMDFDConfig.h"
#import "HMDInjectedInfo.h"
#import "HMDMemoryUsage.h"
#import "HMDMacro.h"
#import "HMDInjectedInfo+UniqueKey.h"
#import "HMDHermasCounter.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

static NSString *const HMDFileDescriptorEventType = @"fd_exception";

@implementation HMDFDRecord
+ (NSString *)tableName {
    return [HMDFDConfig configKey];
}

- (NSDictionary *)reportDictionary {
    NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
    long long timestamp = MilliSecond(self.timestamp);
    [dataValue setValue:@(timestamp) forKey:@"timestamp"];
    [dataValue setValue:HMDFileDescriptorEventType forKey:@"event_type"];
    [dataValue setValue:self.sessionID forKey:@"session_id"];
    [dataValue setValue:self.log forKey:@"stack"];
    [dataValue setValue:@(self.inAppTime) forKey:@"inapp_time"];
    [dataValue setValue:self.errType forKey:@"error_type"];
    [dataValue setValue:@(self.maxFD) forKey:@"max_fd"];
    [dataValue setValue:self.fds forKey:@"fds"];
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
    
    [dataValue addEntriesFromDictionary:self.environmentInfo];

    [[HMDInjectedInfo defaultInfo] confUniqueKeyForData:dataValue timestamp:timestamp eventType:HMDFileDescriptorEventType];
    
    [dataValue setValue:@(self.localID) forKey:@"log_id"];
    
    if (hermas_enabled() && self.sequenceCode >= 0) {
        [dataValue setValue:@(self.sequenceCode) forKey:@"sequence_code"];
    }
    
    return dataValue;
}

@end


