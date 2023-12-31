//
//  HMDLaunchDataCollector.m
//  AWECloudCommand
//
//  Created by zhangxiao on 2021/5/27.
//

#import "HMDLaunchDataCollector.h"
#import "NSArray+HMDSafe.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDLaunchTimingRecord.h"
#import "HMDLaunchTaskSpan.h"
#import "HMDGCD.h"

static void *hmd_launch_queue_key = &hmd_launch_queue_key;
static void *hmd_launch_queue_context = &hmd_launch_queue_context;

dispatch_queue_t hmd_get_launch_monitor_queue(void)
{
    static dispatch_queue_t monitor_queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        monitor_queue = dispatch_queue_create("com.hmd.heimdallr.launchtiming.monitor", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(monitor_queue, hmd_launch_queue_key, hmd_launch_queue_context, 0);
    });
    return monitor_queue;
}

void hmd_on_launch_monitor_queue(dispatch_block_t block)
{
    if (block == NULL) {
        return;
    }
    if (dispatch_get_specific(hmd_launch_queue_key) == hmd_launch_queue_key) {
        block();
    } else {
        hmd_safe_dispatch_async(hmd_get_launch_monitor_queue(), block);
    }
}

@interface HMDLaunchDataCollector ()

@property (nonatomic, strong, readwrite) HMDLaunchTraceTimingInfo *trace;
@property (nonatomic, strong, readwrite) NSDictionary *perfData;

@end

@implementation HMDLaunchDataCollector

- (instancetype)init {
    self = [super init];
    if (self) {

    }
    return self;
}

#pragma mark --- storage launch data
- (void)recordOnceLaunchData {
    HMDLaunchTimingRecord *record = [HMDLaunchTimingRecord newRecord];

    record.perfData = self.perfData;
    [record hmd_insertTraceModel:self.trace];

    if (self.datasource &&
        [self.datasource respondsToSelector:@selector(hmdLaunchCollectRecord:)]) {
        [self.datasource hmdLaunchCollectRecord:record];
    }
}

#pragma mark --- insert launch stage info
- (void)insertOnceCompleteTrace:(HMDLaunchTraceTimingInfo *)lauchTrace {
    self.trace = lauchTrace;
}

#pragma mark--- inset launch perf
- (void)insertNormalPerfData:(NSDictionary *)perfDict {
    if (perfDict) {
        self.perfData = perfDict;
    }
}

@end
