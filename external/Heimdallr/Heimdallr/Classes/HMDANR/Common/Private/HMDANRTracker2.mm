//
//  HMDANRTracker2.m
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 7/4/2022.
//

#import "HMDANRTracker2.h"
#import "HMDANRMonitor.h"
#import "HMDANRRecord.h"
#import "HMDMemoryUsage.h"
#import "HMDALogProtocol.h"
#import "HMDDiskUsage.h"
#import "HMDMacro.h"
#import "HMDInjectedInfo.h"
#import "HMDNetworkHelper.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

#import "HMDHermasHelper.h"
// PrivateServices
#import "HMDServerStateService.h"

@interface HMDANRTracker2 ()
@property (nonatomic, strong) HMInstance *instance;
@end

@implementation HMDANRTracker2
SHAREDTRACKER(HMDANRTracker2)

- (HMInstance *)instance {
    if (!_instance) {
        _instance = [[HMEngine sharedEngine] instanceWithModuleId:kModuleExceptionName aid:[HMDInjectedInfo defaultInfo].appID];
    }
    return _instance;
}

- (BOOL)exceptionDataSource {
    return YES;
}

#pragma mark - DataReporterDelegate
- (NSArray *)pendingExceptionData {
    return nil;
}

- (void)didBlockWithInfo:(HMDANRMonitorInfo *)info {
    if (hermas_drop_data(kModuleExceptionName)) return;

    HMDANRMonitor *instance = [HMDANRMonitor sharedInstance];
    HMDANRRecord *record = [HMDANRRecord newRecord];
    record.anrTime = info.anrTime;
    record.blockDuration = (long)(info.duration * 1000);
    record.inAppTime = info.inAppTime;
    record.anrLogStr = [record generateANRLogStringWithStack:info.stackLog];
    hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
    record.memoryUsage = memoryBytes.appMemory/HMD_MB;
    record.freeMemoryUsage = memoryBytes.availabelMemory/HMD_MB;
    record.freeDiskBlockSize = [HMDDiskUsage getFreeDisk300MBlockSize];
    record.business = [HMDInjectedInfo defaultInfo].business ?: @"unknown";
    record.access = [HMDNetworkHelper connectTypeName];
    record.lastScene = [HMDTracker getLastSceneIfAvailable];
    record.operationTrace = [HMDTracker getOperationTraceIfAvailable];
    record.isLaunch = info.isLaunch;
    record.isSampleHit = info.sampleFlag;
    record.isBackground = info.background;
    record.isScrolling = info.isUITrackingRunloopMode;
    NSMutableDictionary *custom = [NSMutableDictionary dictionary];
    [custom setValue:[HMDInjectedInfo defaultInfo].userID forKey:@"user_id"];
    if ([HMDInjectedInfo defaultInfo].scopedUserID) {
        [custom setValue:[HMDInjectedInfo defaultInfo].scopedUserID forKey:@"scoped_user_id"];
    }
    [custom setValue:[HMDInjectedInfo defaultInfo].userName forKey:@"user_name"];
    [custom setValue:[HMDInjectedInfo defaultInfo].email forKey:@"email"];
    [custom addEntriesFromDictionary:[HMDInjectedInfo defaultInfo].customContext];
    record.customParams =  [custom copy];
    NSMutableDictionary *filters = nil;
    if ([HMDInjectedInfo defaultInfo].filters) {
        filters = [[NSMutableDictionary alloc] initWithDictionary:[HMDInjectedInfo defaultInfo].filters];
    }
    else {
        filters = [[NSMutableDictionary alloc] init];
    }
    
    [filters setValue:info.sampleFlag ? @"1" : @"0" forKey:@"sample_flag"];
    [filters setValue:info.background ? @"1" : @"0" forKey:@"background"];
    [filters setValue:info.isUITrackingRunloopMode ? @"1" : @"0" forKey:@"isScrolling"];
    [filters setValue:@(info.mainThreadCPUUsage) forKey:@"main_thread_cpu_usage"];
    record.filters = [filters copy];
    
    NSMutableDictionary *settings = [NSMutableDictionary new];
    [settings setValue:@((int)(1000*instance.timeoutInterval)) forKey:@"timeout_interval"];
    [settings setValue:@(instance.enableSample) forKey:@"enable_sample"];
    [settings setValue:@((int)(1000*instance.sampleInterval)) forKey:@"sample_interval"];
    [settings setValue:@((int)(1000*instance.sampleTimeoutInterval)) forKey:@"sample_timeout_interval"];
    [settings setValue:@(instance.ignoreBackground) forKey:@"ignore_background"];
    [settings setValue:@(instance.ignoreDuplicate) forKey:@"ignore_duplicate"];
    [settings setValue:@(instance.ignoreBacktrace) forKey:@"ignore_backtrace"];
    [settings setValue:@(instance.suspend) forKey:@"threads_suspend"];
    [settings setValue:@(instance.launchThreshold) forKey:@"launch_threshold"];
    record.settings = [settings copy];
    
    HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"[ANR] blockDuration: %f", info.duration);
    
    [self updateRecordWithConfig:record];
    
    BOOL recordImmediately = [HMDHermasHelper recordImmediately];
    HMRecordPriority priority = recordImmediately ? HMRecordPriorityRealTime : HMRecordPriorityHigh;
    [self.instance recordData:record.reportDictionary priority:priority];
}

- (void)exceptionReporterDidReceiveResponse:(BOOL)isSuccess {
    // do nothing
}

- (void)dropExceptionData {
    // do nothing
}

@end
