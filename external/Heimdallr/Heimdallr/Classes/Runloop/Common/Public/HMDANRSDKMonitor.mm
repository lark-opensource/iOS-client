//
//  HMDANRSDKMonitor.m
//  AWECloudCommand
//
//  Created by maniackk on 2020/7/6.
//

#import "HMDANRSDKMonitor.h"
#import <pthread/pthread.h>
#import "HMDMainRunloopMonitor.h"
#import "HMDGCD.h"
#import "HMDTimeSepc.h"

#ifdef DEBUG
#define DEBUG_C_LOG(format, ...) printf("[%f]" format "\n", HMD_XNUSystemCall_timeSince1970(), ##__VA_ARGS__);
#else
#define DEBUG_C_LOG(format, ...)
#endif

static dispatch_queue_t g_SerialQueue;

// default value
static NSTimeInterval kHMDANRDefaultTimeoutInterval = 0.3; // default timeoutInterval 300ms
static NSTimeInterval const kHMDANRTimeoutIntervalMin = 0.1; // min timeoutInterval 100ms
static NSTimeInterval const kHMDANRMilliSecond = 0.001; // 1ms
static NSHashTable *g_monitor_table = nil; // access in gSerialQueue
static BOOL g_Start_Monitor_flag = false; // access in gSerialQueue


@implementation HMDANRSDKMonitor

+ (void)initialize {
    if (self == [HMDANRSDKMonitor class]) {
       g_SerialQueue = dispatch_queue_create("com.heimdallr.sdkanr", DISPATCH_QUEUE_SERIAL);
    }
}

// default timeoutInterval 300ms
- (instancetype)initWithANRSDKMonitorDelegate:(id<HMDANRSDKMonitorDelegate>)delegate
{
    return [self initWithANRSDKMonitorDelegate:delegate timeInterval:kHMDANRDefaultTimeoutInterval];
}

- (instancetype)initWithANRSDKMonitorDelegate:(id<HMDANRSDKMonitorDelegate>)delegate timeInterval:(NSTimeInterval)timeoutInterval
{
    if (!delegate) return nil;
    self = [super init];
    if (self) {
        _timeoutInterval = timeoutInterval<kHMDANRTimeoutIntervalMin ? kHMDANRTimeoutIntervalMin : timeoutInterval;
        _delegate = delegate;
    }
    return self;
}

#pragma mark - Monitor

static void _start(void) {
    if (!g_Start_Monitor_flag && g_monitor_table && g_monitor_table.allObjects.count > 0) {
        HMDMainRunloopMonitor::getInstance()->addObserver(monitorCallback);
        g_Start_Monitor_flag = true;
        DEBUG_C_LOG("SDK ANR start");
    }
}

static void _stop(void) {
    if (g_Start_Monitor_flag &&(!g_monitor_table || g_monitor_table.allObjects.count == 0)) {
        HMDMainRunloopMonitor::getInstance()->removeObserver(monitorCallback);
        g_Start_Monitor_flag = false;
        DEBUG_C_LOG("SDK ANR stop");
    }
}

- (void)start {
    __weak typeof(self) weakSelf = self;
    dispatch_async(g_SerialQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf addSelfElement];
             _start();
        }
    });
}

- (void)stop {
    __weak typeof(self) weakSelf = self;
    dispatch_async(g_SerialQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf removeSelfElement];
            _stop();
        }
        
    });
}

static NSTimeInterval monitorCallback(struct HMDRunloopMonitorInfo *info) {
    if (info->status == HMDRunloopStatusOver) {
        return timeoutOver(info);
    }
    return -1;
}

static NSTimeInterval timeoutOver(struct HMDRunloopMonitorInfo *info) {
    NSTimeInterval duration = info->duration;
    if (duration+kHMDANRMilliSecond >= kHMDANRTimeoutIntervalMin) {
        hmd_safe_dispatch_async(g_SerialQueue, ^{
            if (g_monitor_table) {
                for (HMDANRSDKMonitor *obj in g_monitor_table.objectEnumerator) {
                    if (duration+kHMDANRMilliSecond >= obj.timeoutInterval && [obj.delegate respondsToSelector:@selector(didBlockWithDuration:)]) {
                        [obj.delegate didBlockWithDuration:duration];
                    }
                }
            }
        });
    }
    return -1;
}

# pragma mark - support

- (void)addSelfElement
{
    if (!g_monitor_table) {
        g_monitor_table = [NSHashTable hashTableWithOptions:NSHashTableWeakMemory];
    }
    [g_monitor_table addObject:self];
}

- (void)removeSelfElement
{
    if (g_monitor_table) {
        [g_monitor_table removeObject:self];
        if (g_monitor_table.allObjects.count == 0) {
            g_monitor_table = nil;
        }
    }
}

- (void)dealloc
{
    dispatch_async(g_SerialQueue, ^{
        _stop();
    });
}

@end
