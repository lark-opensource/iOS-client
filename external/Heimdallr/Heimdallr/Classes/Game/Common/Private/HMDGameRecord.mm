//  Heimdallr
//
//  Created by 谢俊逸 on 2019/06/13.
//


#import "HMDGameRecord.h"
#import "HMDUploadHelper.h"
#import "HMDMemoryUsage.h"
#import "HMDInjectedInfo.h"
#import "HMDInjectedInfo+UniqueKey.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

static NSString *const kHMDGameEventType = @"game";

@implementation HMDGameRecord

+ (NSString *)tableName {
    return @"game";
}

+ (NSArray *)bg_ignoreKeys {
    return @[@"inAppTime"];
}

- (NSDictionary *)reportDictionary {
    NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
    
    long long timestamp = MilliSecond(self.timestamp);
    
    [dataValue setValue:@(timestamp) forKey:@"timestamp"];
    [dataValue setValue:kHMDGameEventType forKey:@"event_type"];
    [dataValue setValue:self.backTrace forKey:@"data"];
    [dataValue setValue:self.name forKey:@"crash_name"];
    [dataValue setValue:self.reason forKey:@"crash_reason"];
    [dataValue setValue:self.sessionID forKey:@"session_id"];
    [dataValue setValue:@(self.memoryUsage) forKey:@"memory_usage"];
    [dataValue setValue:@(self.freeDiskBlockSize) forKey:@"d_zoom_free"];
    [dataValue setValue:@(hmd_calculateMemorySizeLevel(self.freeMemoryUsage)) forKey:HMD_Free_Memory_Key];
    [dataValue setValue:@(self.isBackground) forKey:@"is_background"];

    [dataValue addEntriesFromDictionary:self.environmentInfo];
    
    NSMutableDictionary *header = [NSMutableDictionary dictionaryWithDictionary:[HMDUploadHelper sharedInstance].headerInfo];
    [[HMDInjectedInfo defaultInfo] confUniqueKeyForData:header timestamp:timestamp eventType:kHMDGameEventType];
    [dataValue setValue:[header copy] forKey:@"header"];
    
    if (self.customParams.count > 0) {
        [dataValue setValue:self.customParams forKey:@"custom"];
    }
    
    if (self.filters.count > 0) {
        [dataValue setValue:self.filters forKey:@"filters"];
    }
    
    // add enableUpload
    [dataValue setValue:@(self.enableUpload) forKey:@"enable_upload"];
    
    if (hermas_enabled() && self.sequenceCode >= 0) {
        [dataValue setValue:@(self.sequenceCode) forKey:@"sequence_code"];
    }
    
    return dataValue;
}

@end

