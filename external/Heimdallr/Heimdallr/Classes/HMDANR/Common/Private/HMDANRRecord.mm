//
//  HMDANRRecord.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/1/30.
//

#import "HMDANRRecord.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDMacro.h"
#import "HMDMemoryUsage.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

static NSString *const kHMDANREventType = @"lag";

@implementation HMDANRRecord

+ (NSString *)tableName {
    return @"anr";
}

- (NSString *)JSONForObject:(id)object {
    NSError *error = nil;
    NSData *encoded = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:&error];

    if(error) {
        return [NSString stringWithFormat:@"Error encoding JSON: %@", error];
    } else {
        return [[NSString alloc] initWithData:encoded encoding:NSUTF8StringEncoding];
    }
}

+ (NSArray *)bg_ignoreKeys {
    return @[@"threadBacktraces"];
}

- (NSString *)generateANRLogStringWithStack:(NSString *)stack {
    NSString *anrLogStr = [NSString stringWithFormat:@"timestamp  %f\nsessionID  %@\n%@\n", self.timestamp, self.sessionID, stack];
    return anrLogStr;
}

- (NSDictionary *)reportDictionary {
    NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];

    long long timestamp = MilliSecond(self.timestamp);
    hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
    double allMemory = memoryBytes.totalMemory/HMD_MB;

    [dataValue setValue:@(timestamp) forKey:@"timestamp"];
    [dataValue setValue:kHMDANREventType forKey:@"event_type"];
    [dataValue setValue:self.sessionID forKey:@"session_id"];
    [dataValue setValue:self.anrLogStr forKey:@"stack"];
    [dataValue setValue:@(self.memoryUsage) forKey:@"memory_usage"];
    [dataValue setValue:@(self.freeDiskBlockSize) forKey:@"d_zoom_free"];
    [dataValue setValue:@(hmd_calculateMemorySizeLevel(self.freeMemoryUsage*HMD_MEMORY_MB)) forKey:HMD_Free_Memory_Key];
    double free_memory_percent = (int)(self.freeMemoryUsage/allMemory*100)/100.0;
    [dataValue setValue:@(free_memory_percent) forKey:HMD_Free_Memory_Percent_key];
    [dataValue setValue:self.business forKey:@"business"];
    [dataValue setValue:self.lastScene forKey:@"last_scene"];
    [dataValue setValue:self.operationTrace forKey:@"operation_trace"];
    [dataValue setValue:@(self.inAppTime) forKey:@"inapp_time"];
    [dataValue setValue:self.access forKey:@"access"];
    [dataValue setValue:@(self.blockDuration) forKey:@"block_duration"];
    [dataValue setValue:@(self.isLaunch) forKey:@"is_launch"];
    [dataValue setValue:self.settings forKey:@"settings"];
    [dataValue setValue:@(self.netQualityType) forKey:@"network_quality"];
    [dataValue hmd_setObject:@(self.isScrolling) forKey:@"is_scrolling"];
    [dataValue hmd_setObject:@(self.isBackground) forKey:@"is_background"];
    [dataValue hmd_setObject:@(self.isSampleHit) forKey:@"sample_flag"];
  
    if (self.customParams.count > 0) {
        [dataValue setValue:self.customParams forKey:@"custom"];
    }
    if (self.filters.count > 0) {
        [dataValue setValue:self.filters forKey:@"filters"];
    }
    [dataValue addEntriesFromDictionary:self.environmentInfo];
    [dataValue hmd_setObject:@(self.enableUpload) forKey:@"enable_upload"];
    
    if (hermas_enabled() && self.sequenceCode >= 0) {
        [dataValue setValue:@(self.sequenceCode) forKey:@"sequence_code"];
    }
    
    return [dataValue copy];
}
@end
