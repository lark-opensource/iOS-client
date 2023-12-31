//
//  HMDControllerTimeRecord.m
//  Heimdallr
//
//  Created by joy on 2018/5/10.
//

#import "HMDControllerTimeRecord.h"
#import "HMDSessionTracker.h"
#import "HMDNetworkHelper.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP


@implementation HMDControllerTimeRecord

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

+ (instancetype)newRecord
{
    HMDControllerTimeRecord *record = [[self alloc] init];
    
    record.timestamp = [[NSDate date] timeIntervalSince1970];
    record.sessionID = [HMDSessionTracker currentSession].sessionID;
    record.inAppTime = [HMDSessionTracker currentSession].timeInSession;
    record.netQualityType = [HMDNetworkHelper currentNetQuality];
    
    return record;
}

+ (NSString *)tableName {
    return @"page_load";
}

+ (NSUInteger)cleanupWeight {
    return 50;
}

- (NSDictionary *)reportDictionary {
    NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
    long long time = MilliSecond(self.timestamp);
    NSString *logType = hermas_enabled() ? @"performance_monitor" : @"performance_monitor_debug";
    
    // normal
    [dataValue setValue:@(time) forKey:@"timestamp"];
    [dataValue setValue:self.sessionID forKey:@"session_id"];
    [dataValue setValue:@"page_load" forKey:@"service"];
    [dataValue setValue:logType forKey:@"log_type"];
    [dataValue setValue:@(self.localID) forKey:@"log_id"];
    [dataValue setValue:@"HMDControllerTimeRecord" forKey:@"class_name"];
    [dataValue setValue:@(self.netQualityType) forKey:@"network_quality"];

    // extra value
    NSMutableDictionary *extraValue = [NSMutableDictionary dictionary];
    if (self.typeName) {
        [extraValue setValue:@(self.timeInterval) forKey:self.typeName];
    }
    [dataValue setValue:extraValue forKey:@"extra_values"];

    // extra status
    NSMutableDictionary *extraStatus = [NSMutableDictionary dictionary];
    [extraStatus setValue:self.pageName forKey:@"scene"];
    [extraStatus setValue:@(self.isFirstOpen) forKey:@"is_first_open"];
    [dataValue setValue:extraStatus forKey:@"extra_status"];
    
    // enable_upload
    [dataValue setValue:@(self.enableUpload) forKey:@"enable_upload"];
    return dataValue;
}

@end
