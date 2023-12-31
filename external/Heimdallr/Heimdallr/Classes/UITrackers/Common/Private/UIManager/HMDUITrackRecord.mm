//
//  HMDUITrackRecord.m
//  Heimdallr
//
//  Created by fengyadong on 2018/6/14.
//

#import "HMDUITrackRecord.h"
#import "HMDSessionTracker.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

@implementation HMDUITrackRecord


- (instancetype)init {
    if (self = [super init]) {
    }
    
    return self;
}

+ (instancetype)newRecord
{
    HMDUITrackRecord *record = [[self alloc] init];
    
    record.timestamp = [[NSDate date] timeIntervalSince1970];
    record.sessionID = [HMDSessionTracker currentSession].sessionID;
    record.inAppTime = [HMDSessionTracker currentSession].timeInSession;
    
    return record;
}

+ (NSString *)tableName {
    return @"ui_action";
}

+ (NSArray *)bg_ignoreKeys {
    return @[@"context"];
}

+ (NSUInteger)cleanupWeight {
    return 50;
}

- (NSDictionary *)reportDictionary {
    NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
    
    // 上传统一使用毫秒
    long long timestamp = MilliSecond(self.timestamp);
    
    // normal
    [dataValue setValue:@(timestamp) forKey:@"timestamp"];
    [dataValue setValue:@"ui_action" forKey:@"log_type"];
    [dataValue setValue:self.sessionID forKey:@"session_id"];
    [dataValue setValue:@(self.inAppTime) forKey:@"inapp_time"];
    [dataValue setValue:self.name forKey:@"page"];
    [dataValue setValue:self.event forKey:@"action"];
    [dataValue setValue:@(self.localID) forKey:@"log_id"];
    if (hermas_enabled() && self.sequenceCode >= 0) {
        [dataValue setValue:@(self.sequenceCode) forKey:@"sequence_code"];
    }

    if (self.extraInfo) {
        NSDictionary *contextDict = self.extraInfo;
        [dataValue setValue:contextDict forKey:@"context"];
    }
    
    // enable_upload
    [dataValue setValue:@(self.enableUpload) forKey:@"enable_upload"];
    return dataValue;
}
@end
