//
//  OPPerformanceUtil.m
//  OPSDK
//
//  Created by 尹清正 on 2021/3/29.
//  File copy from EEMicroAppSDK>EMAPerformanceUtil.m (origin author: yinyuan.0@bytedance.com)


#import "OPPerformanceUtil.h"
#include <mach/mach.h>
#import <UIKit/UIKit.h>
#import <Heimdallr/HMDMemoryUsage.h>

/// 代码拷贝于EEMicroAppSDK中的EMAPerformanceUtil，只添加部分注释，未修改逻辑
@interface OPPerformanceUtil ()

@property (strong, nonatomic) CADisplayLink * displayLink;
@property (assign, nonatomic) NSTimeInterval lastTimestamp;
@property (assign, nonatomic) NSInteger countPerFrame;
@property (assign, nonatomic) float fps;

@end

@implementation OPPerformanceUtil

+ (instancetype)sharedInstance{
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        _lastTimestamp = -1;
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(envokeDisplayLink:)];
        _displayLink.paused = YES;
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];

        //Notification
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationDidBecomeActiveNotification)
                                                     name: UIApplicationDidBecomeActiveNotification
                                                   object: nil];

        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationWillResignActiveNotification)
                                                     name: UIApplicationWillResignActiveNotification
                                                   object: nil];
    }
    return self;
}

- (void)dealloc{
    _displayLink.paused = YES;
    [_displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark - Private
vm_size_t usedMemory(void) {
    hmd_MemoryBytes memory = hmd_getMemoryBytes();
    return memory.appMemory;
}


float availableMemory(void)
{
    hmd_MemoryBytes memory = hmd_getMemoryBytes();
    return memory.availabelMemory/1024.0/1024.0;
}


float cpu_usage()
{
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;

    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }

    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;

    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;

    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0; // Mach threads

    basic_info = (task_basic_info_t)tinfo;

    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    if (thread_count > 0)
        stat_thread += thread_count;

    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;

    for (j = 0; j < thread_count; j++)
    {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }

        basic_info_th = (thread_basic_info_t)thinfo;

        bool ret = basic_info_th->flags & TH_FLAGS_IDLE;
        if (!ret) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->user_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }

    } // for each thread

    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);

    return tot_cpu;
}

- (void)_run{
    _displayLink.paused = NO;
}

- (void)_stop{
    _displayLink.paused = YES;
}

#pragma mark - DisplayLink hander
- (void)envokeDisplayLink:(CADisplayLink *)displayLink{
    if (_lastTimestamp == -1) {
        self.lastTimestamp = displayLink.timestamp;
        return;
    }
    _countPerFrame ++;
    NSTimeInterval interval = displayLink.timestamp - _lastTimestamp;
    if (interval < 1) {
        return;
    }
    self.lastTimestamp = displayLink.timestamp;
    self.fps = _countPerFrame / interval;
    self.countPerFrame = 0;
}

#pragma mark - Notification
- (void)applicationDidBecomeActiveNotification {
    _displayLink.paused = NO;
}

- (void)applicationWillResignActiveNotification {
    _displayLink.paused = YES;
}

#pragma mark - API

+ (void)runFPSMonitor {
    [[OPPerformanceUtil sharedInstance] _run];
}

+ (void)stopFPSMonitor {
    [[OPPerformanceUtil sharedInstance] _stop];
}

+ (float)fps {
    return [OPPerformanceUtil sharedInstance].fps;
}

+ (float)usedMemoryInMB {
    vm_size_t memory = usedMemory();
    return memory / 1024.0 / 1024.0;
}

+ (float)availableMemory {
    vm_size_t memory = availableMemory();
    return memory;
}


+ (float)cpuUsage {
    float cpu = cpu_usage();
    return cpu;
}

@end
