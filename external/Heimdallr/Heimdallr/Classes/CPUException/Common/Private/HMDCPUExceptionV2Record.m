//
//  HMDCPUExceptionRecord.m
//  AWECloudCommand
//
//  Created by zhangxiao on 2020/5/6.
//

#import "HMDCPUExceptionV2Record.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDDynamicCall.h"
#import "NSArray+HMDSafe.h"
#import "HMDMacro.h"
#import "HMDInfo+DeviceInfo.h"
#import "HMDInfo+AppInfo.h"
#import "HMDSessionTracker.h"
#import "HMDCPUThreadInfo.h"
#import "HMDCPUUtilties.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

static NSString *const HMDCPUExceptionRecordEventType = @"cpu_exception_v2";

@implementation HMDCPUExceptionV2Record

+ (HMDCPUExceptionV2Record *)record {
    HMDCPUExceptionV2Record *record = [[HMDCPUExceptionV2Record alloc] init];
    record.timestamp = [[NSDate date] timeIntervalSince1970];
    record.sessionID = [HMDSessionTracker currentSession].sessionID;
    record.inAppTime = [HMDSessionTracker currentSession].timeInSession;
    record.isReported = NO;
    record.updateVersionCode = [HMDInfo defaultInfo].buildVersion;
    record.appVersion = [HMDInfo defaultInfo].shortVersion;
    record.lastScene = DC_IS(DC_OB(DC_CL(HMDUITrackerManager, sharedManager), scene), NSString);
    record.isBackground = [HMDSessionTracker currentSession].backgroundStatus;
    record.uuid = [NSUUID UUID].UUIDString;
    record.timestamp = [[NSDate date] timeIntervalSince1970];
    if (record.uuid.length == 0) {
        record.uuid = [NSString stringWithFormat:@"%lld%u",(long long)([NSDate date].timeIntervalSince1970 * 1000), arc4random()%10000];
    }
    return record;
}

- (NSDictionary *)reportDictionary {
    long long time = MilliSecond(self.timestamp);
    NSMutableDictionary *reportDict = [NSMutableDictionary dictionary];
    [reportDict setValue:@(self.isLowPowerModel) forKey:@"is_low_power_model"];
    [reportDict setValue:@(self.thermalState) forKey:@"thermal_state"];
    [reportDict setValue:@(self.threadCount) forKey:@"thread_count"];
    [reportDict setValue:@(self.sampleCount) forKey:@"sample_count"];
    [reportDict setValue:@(self.processorCount) forKey:@"processor_count"];
    [reportDict setValue:@(self.startTime) forKey:@"start_time"];
    [reportDict setValue:@(self.endTime) forKey:@"end_time"];
    [reportDict setValue:@(self.peakUsage) forKey:@"peak_usage"];
    [reportDict setValue:@(self.averageUsage) forKey:@"average_usage"];
    [reportDict setValue:@(self.configUsage) forKey:@"config_usage"];
    [reportDict setValue:self.possibleScene forKey:@"possible_scene"];
    [reportDict setValue:self.lastScene forKey:@"last_scene"];
    [reportDict setValue:HMDCPUExceptionRecordEventType forKey:@"event_type"];
    [reportDict setValue:@(time) forKey:@"timestamp"];
    [reportDict setValue:@(self.inAppTime) forKey:@"inapp_time"];
    [reportDict setValue:self.osVersion?:@"unknown" forKey:@"os_full_version"];
    [reportDict setValue:self.bundleId?:@"unknown" forKey:@"bundle_id"];
    [reportDict setValue:@(self.isBackground) forKey:@"is_back"];
    if (self.appStates && self.appStates.count > 0) {
        [reportDict setValue:self.appStates forKey:@"app_states"];
    }
    NSArray *threadsReportDict = [self threadInfoReportDict];
    if (threadsReportDict) {
        [reportDict setValue:threadsReportDict forKey:@"threads_info"];
    }
    if (self.binaryImages && self.binaryImages.count > 0) {
        [reportDict setValue:self.binaryImages forKey:@"binary_images"];
    }

    if (hermas_enabled() && self.sequenceCode >= 0) {
        [reportDict setValue:@(self.sequenceCode) forKey:@"sequence_code"];
    }

    NSMutableDictionary *filters = [NSMutableDictionary dictionary];
    [filters setValue:@(self.isLowPowerModel) forKey:@"is_low_power_model"];
    if(self.customScene.length) {
        [filters setValue:self.customScene forKey:@"custom_scene"];
    }
    [reportDict setValue:filters forKey:@"filters"];

    return [reportDict copy];
}

- (NSArray<NSDictionary *> *)threadInfoReportDict {
    NSMutableArray *threadsReportInfo = [NSMutableArray array];
    for (HMDCPUThreadInfo *threadInfo in self.threadsInfo) {
        @autoreleasepool {
            if ([threadInfo isKindOfClass:[HMDCPUThreadInfo class]]) {
                NSDictionary *threadReportDict = [threadInfo reportDict];
                if (threadReportDict) {
                    [threadsReportInfo hmd_addObject:threadReportDict];
                }
            }
        }
    }
    return [threadsReportInfo copy];
}

+ (NSString *)tableName {
    return NSStringFromClass([HMDCPUExceptionV2Record class]);
}

- (NSUInteger)infoSize {
    return self.threadsInfo.count;
}

@end
 
