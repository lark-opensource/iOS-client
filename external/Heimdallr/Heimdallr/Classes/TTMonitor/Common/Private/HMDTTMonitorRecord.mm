//
//  HMDTTMonitorRecord.m
//  Heimdallr
//
//  Created by joy on 2018/3/26.
//

#import "HMDTTMonitorRecord.h"
#import "HMDSessionTracker.h"
#import "HMDInfo+AppInfo.h"
#import "HMDInfo+SystemInfo.h"
#import "HMDNetworkHelper.h"
#import "HMDTTMonitorHelper.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

@implementation HMDTTMonitorRecord

+ (NSString *)tableName {
    return @"TTServiceEvent";
}

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

+ (instancetype)newRecord
{
    HMDTTMonitorRecord *record = [[self alloc] init];
    
    record.timestamp = [[NSDate date] timeIntervalSince1970];
    record.sessionID = [HMDSessionTracker currentSession].sessionID;
    record.inAppTime = [HMDSessionTracker currentSession].timeInSession;
    record.needUpload = NO;
    record.updateVersionCode = [HMDInfo defaultInfo].buildVersion;
    record.appVersion = [HMDInfo defaultInfo].shortVersion;
    record.osVersion = [HMDInfo defaultInfo].systemVersion;
    record.netQualityType = [HMDNetworkHelper currentNetQuality];
    record.singlePointOnly = 0;

    return record;
}

- (NSDictionary *)reportDictionary {
    NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
    
    long long time = MilliSecond(self.timestamp);
    
    [dataValue setValue:@"event" forKey:@"module"];
    [dataValue setValue:@(time) forKey:@"timestamp"];
    [dataValue setValue:self.sessionID forKey:@"session_id"];
    [dataValue setValue:@(self.inAppTime) forKey:@"inapp_time"];
    [dataValue setValue:self.log_type forKey:@"log_type"];
    [dataValue setValue:@(self.netQualityType) forKey:@"network_quality"];
    
    if (self.service) {
        [dataValue setValue:self.service forKey:@"service"];
    }
    if (self.appID) {
        [dataValue setValue:self.appID forKey:@"aid"];
    }
    [dataValue setValue:self.log_id forKey:@"insert_id"];
    [dataValue setValue:[HMDTTMonitorHelper generateUploadID] forKey:@"upload_id"];
    [dataValue setValue:@(self.localID) forKey:@"log_id"];
    if (hermas_enabled() && self.sequenceNumber > 0) {
        [dataValue setValue:@(self.sequenceNumber) forKey:@"sequence_code"];
    }
    
    if ([self.extra_values isKindOfClass:[NSDictionary class]]) {
        [dataValue addEntriesFromDictionary:self.extra_values];
    }

    if (self.sdkVersion) {
        [dataValue setValue:self.sdkVersion forKey:@"sdk_version"];
    }
    if (self.appVersion) {
        [dataValue setValue:self.appVersion forKey:@"app_version"];
    }
    if (self.osVersion) {
        [dataValue setValue:self.osVersion forKey:@"os_version"];
    }
    if (self.updateVersionCode) {
        [dataValue setValue:self.updateVersionCode forKey:@"update_version_code"];
    }
    if (self.sequenceNumber > 0) {
        [dataValue setValue:@(self.sequenceNumber) forKey:@"seq_no_type"];
    }
    [dataValue setValue:@(self.needUpload) forKey:@"enable_upload"];
    [dataValue setValue:@(self.customTag) forKey:@"custom_tag"];
    
    [dataValue setValue:self.traceParent forKey:@"traceparent"];
    [dataValue setValue:@(self.singlePointOnly) forKey:@"single_point_only"];
    
    return dataValue;
}

@end
