//
//  HMDCPUExceptionPerf.m
//  Heimdallr
//
//  Created by zhangxiao on 2021/1/19.
//

#import "HMDCPUExceptionPerf.h"
#if !RANGERSAPM
#import "HMDTTMonitor.h"
#else
#import "RangersAPMSelfMonitor.h"
#endif

static NSString *const kHMDCPUExceptionPerfThreadBackTree = @"hmd_cpu_exception_thread_backtree";
static NSString *const kHMDCPUExceptionPerfThreadProcThread = @"hmd_cpu_exception_proc_thead";
static NSString *const kHMDCPUExceptionPerfRecordPrepare = @"hmd_cpu_exception_record_prepare";
static NSString *const kHMDCPUExceptionPerfRecordTransformDcit = @"hmd_cpu_exception_record_transform_dict";
static NSString *const kHMDCPUExceptionPerfRecordWriteLocal = @"hmd_cpu_exception_record_write_local";
static NSString *const kHMDCPUExceptionPerfMonitorUsageAbnormal = @"hmd_cpu_exception_monitor_usage_abnormal";


@interface HMDCPUExceptionPerf ()

@end

@implementation HMDCPUExceptionPerf

#pragma mark --- public method
- (void)threadBackTreeWithTimeUsage:(long long)timeUsage threadCount:(NSInteger)threadCount suspendThread:(BOOL)suspendThread {
    if (timeUsage < 0) { return; }
    [self collectPerformanceWithServiceName:kHMDCPUExceptionPerfThreadBackTree timeUsage:@(timeUsage) category:@{@"thread_count":@(threadCount), @"suspend": @(suspendThread)}];
}

- (void)exceptionThreadTimeUsage:(long long)timeUsage {
    if (timeUsage < 0) { return; }
    [self collectPerformanceWithServiceName:kHMDCPUExceptionPerfThreadProcThread timeUsage:@(timeUsage) category:nil];
}

- (void)recordTransformDictTimeUsage:(long long)timeUsag {
    if (timeUsag < 0) {return;}
    [self collectPerformanceWithServiceName:kHMDCPUExceptionPerfRecordTransformDcit timeUsage:@(timeUsag) category:nil];
}

- (void)exceptionRecordPrepareWithTimeUsage:(long long)timeUsage infoSize:(NSUInteger)infoSize {
    if (timeUsage < 0) { return; }
    [self collectPerformanceWithServiceName:kHMDCPUExceptionPerfRecordPrepare timeUsage:@(timeUsage) category:@{@"thread_count":@(infoSize)}];
}

- (void)recordWriteFileWithStartTS:(long long)startTS endTS:(long long)endTS infoCount:(NSUInteger)infoCount {
    long long usage = endTS - startTS;
    if (usage < 0) { return; }
    [self collectPerformanceWithServiceName:kHMDCPUExceptionPerfRecordWriteLocal timeUsage:@(usage) category:@{@"info_size": @(infoCount)}];
}

- (void)monitorThreadCPUUsgeOutOfThreshold:(float)usage {
    if (usage < 0) { return; }
    [self collectPerformanceWithServiceName:kHMDCPUExceptionPerfMonitorUsageAbnormal timeUsage:@(usage) category:nil];
}

- (void)collectPerformanceWithServiceName:(NSString *)serviceName
                                timeUsage:(NSNumber *)usage
                                 category:(nullable NSDictionary<NSString *,NSNumber *> *)catergory {
    if (!usage) { return; }
#if !RANGERSAPM
    if (!self.enablePerfWatch) { return; }
    
    [[HMDTTMonitor defaultManager] hmdTrackService:serviceName metric:@{@"usage": usage} category:catergory extra:nil];
#else
    NSMutableDictionary *metrics = [NSMutableDictionary dictionaryWithDictionary:catergory];
    [metrics setValue:usage forKey:@"usage"];
    [RangersAPMSelfMonitor trackEvent:serviceName metrics:metrics dimension:nil extraValue:nil];
#endif

}

@end
