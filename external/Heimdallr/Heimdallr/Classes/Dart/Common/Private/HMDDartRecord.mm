//
//  HMDDartRecord.m
//  Heimdallr
//
//  Created by joy on 2018/10/24.
//

#import "HMDDartRecord.h"
#import "HMDUploadHelper.h"
#import "HMDMemoryUsage.h"
#import "HMDInjectedInfo.h"
#import "HMDInjectedInfo+UniqueKey.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP


static NSString *const kHMDDartEventType = @"dart";

@implementation HMDDartRecord

+ (NSString *)tableName {
    return @"dart";
}

+ (NSArray *)bg_ignoreKeys {
#if RANGERSAPM
    return @[];
#else
    return @[@"inAppTime"];
#endif
}

- (NSDictionary *)reportDictionary {
    NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
    
    long long timestamp = MilliSecond(self.timestamp);
    
    [dataValue setValue:@(timestamp) forKey:@"timestamp"];
    [dataValue setValue:kHMDDartEventType forKey:@"event_type"];
    [dataValue setValue:self.backTrace forKey:@"data"];
    [dataValue setValue:self.sessionID forKey:@"session_id"];
    [dataValue setValue:@(self.memoryUsage) forKey:@"memory_usage"];
    [dataValue setValue:@(self.freeDiskBlockSize) forKey:@"d_zoom_free"];
    [dataValue setValue:@(hmd_calculateMemorySizeLevel(((uint64_t)self.freeMemoryUsage)*HMD_MEMORY_MB)) forKey:HMD_Free_Memory_Key];
    [dataValue setValue:@(self.isBackground) forKey:@"is_background"];
    
    [dataValue addEntriesFromDictionary:self.environmentInfo];

    // 存到 Event 信息中供下载
    [dataValue setValue:self.customLog forKey:@"custom_log"];
    
    NSMutableDictionary *header = [NSMutableDictionary dictionaryWithDictionary:[HMDUploadHelper sharedInstance].headerInfo];
    [[HMDInjectedInfo defaultInfo] confUniqueKeyForData:header timestamp:timestamp eventType:kHMDDartEventType];
    [header setValue:self.commitID forKey:@"release_build"];
    [dataValue setValue:[header copy] forKey:@"header"];

    // 注入自定义信息
    [dataValue setValue:[self.injectedInfo copy] forKey:@"custom"];
    
    if ([self.filters count] > 0) {
        [dataValue setValue:[self.filters copy] forKey:@"filters"];
    }
    
    // add enableUpload
    [dataValue setValue:@(self.enableUpload) forKey:@"enable_upload"];
    
    if (hermas_enabled() && self.sequenceCode >= 0) {
        [dataValue setValue:@(self.sequenceCode) forKey:@"sequence_code"];
    }
    
    return [dataValue copy];
}

@end
