//
//  HMDLaunchTimingRecord.m
//  Heimdallr
//
//  Created by zhangxiao on 2021/5/31.
//

#import "HMDLaunchTimingRecord.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDSessionTracker.h"
#import "HMDNetworkHelper.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

NSString *const kHMDLaunchTimingKeyLogType = @"log_type";
NSString *const kHMDLaunchTimingKeySessionId = @"session_id";
NSString *const kHMDLaunchTimingKeyNetworkQuality = @"network_quality";
NSString *const kHMDLaunchTimingKeyNetworkType = @"network_type";
NSString *const kHMDLaunchTimingKeyLogID = @"log_id";
NSString *const kHMDlaunchTimingKeyService = @"service";
NSString *const kHMDLaunchTimingValueLogType = @"performance_monitor";
NSString *const kHMDLaunchTimingValueService = @"start_trace";
NSString *const kHMDLaunchTimingKeyName = @"name";
NSString *const kHMDLaunchTimingKeyPageType = @"page_type";
NSString *const kHMDLaunchTimingKeyStart = @"start";
NSString *const kHMDlaunchTimingKeyEnd = @"end";
NSString *const kHMDLaunchTimingKeySpans = @"spans";
NSString *const kHMDLaunchTimingModuleName = @"module_name";
NSString *const kHMDLaunchTimingSpanName = @"span_name";
NSString *const kHMDLaunchTimingKeyCollectFrom = @"collect_from";
NSString *const kHMDLaunchTimingKeyPageName = @"page_name";
NSString *const kHMDLaunchTimingKeyCustomModel = @"custom_launch_mode";
NSString *const kHMDLaunchTimingKeyTrace = @"trace";
NSString *const kHMDLaunchTimingKeyPerfData = @"perf_data";
NSString *const kHMDLaunchTimingKeyListData = @"list_data";
NSString *const kHMDLaunchTimingKeyThreadList = @"current_thread_list";
NSString *const kHMDLaunchTimingKeyModuleName = @"module_name";
NSString *const kHMDLaunchTimingKeySpanName = @"span_name";
NSString *const kHMDLaunchTimingKeyThread = @"thread";
NSString *const kHMDLaunchTimingKeyTimestampe = @"timestamp";
NSString *const kHMDLaunchTimingKeyPrewarm = @"prewarm";

@implementation HMDLaunchTimingRecord

+ (instancetype)newRecord
{
    HMDLaunchTimingRecord *record = [[self alloc] init];
    record.timestamp = [[NSDate date] timeIntervalSince1970];
    record.sessionID = [HMDSessionTracker currentSession].sessionID;
    record.netQualityType = [HMDNetworkHelper currentNetQuality];
    record.netType = [HMDNetworkHelper connectTypeCode];
    
    return record;
}

+ (NSString * _Nonnull)tableName {
    return @"HMDLaunchTimingRecord";
}

+ (NSUInteger)cleanupWeight {
    return 20;
}

#pragma mark --- report
- (NSDictionary *)reportDictWithDebugReal:(BOOL)debugReal {
    NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
    [dataValue setValue:self.trace forKey:kHMDLaunchTimingKeyTrace];
    if (self.perfData) {
        [dataValue setValue:self.perfData forKey:kHMDLaunchTimingKeyPerfData];
    }
    [dataValue setValue:kHMDLaunchTimingValueLogType forKey:kHMDLaunchTimingKeyLogType];
    [dataValue setValue:kHMDLaunchTimingValueService forKey:kHMDlaunchTimingKeyService];
    [dataValue setValue:self.sessionID forKey:kHMDLaunchTimingKeySessionId];
    [dataValue setValue:@(self.netType) forKey:kHMDLaunchTimingKeyNetworkType];
    [dataValue setValue:@(self.netQualityType) forKey:kHMDLaunchTimingKeyNetworkQuality];
    [dataValue setValue:@(self.timestamp * 1000) forKey:kHMDLaunchTimingKeyTimestampe];
    [dataValue setValue:@(self.localID) forKey:kHMDLaunchTimingKeyLogID];
    
    [dataValue hmd_setObject:@(self.enableUpload) forKey:@"enable_upload"];
    if (hermas_enabled() && self.sequenceCode >= 0) {
        [dataValue setValue:@(self.sequenceCode) forKey:@"sequence_code"];
    }
    return [dataValue copy];
}

- (NSDictionary *)reportDictionary {
    return [self reportDictWithDebugReal:NO];
}


@end
