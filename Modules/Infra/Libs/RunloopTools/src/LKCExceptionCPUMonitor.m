//
//  LKCExceptionCPUMonitor.m
//  LarkMonitor
//
//  Created by sniperj on 2020/2/5.
//

#import "LKCExceptionCPUMonitor.h"
#import <os/lock.h>
#import <mach/mach.h>

static NSMutableDictionary *_regeistCallback;
static NSMutableDictionary *_recordCallback;
static os_unfair_lock _lock = OS_UNFAIR_LOCK_INIT;
static long long _counter = 0;
static dispatch_source_t _timer;

@interface LKCExceptionCPUMonitor()

@property (class, nonatomic, strong) NSMutableDictionary *regeistCallback;
@property (class, nonatomic, strong) NSMutableDictionary *recordCallback;

@end

@implementation LKCExceptionCPUMonitor

+ (void)setRegeistCallback:(NSMutableDictionary *)regeistCallback {
    _regeistCallback = regeistCallback;
}

+ (NSMutableDictionary *)regeistCallback {
    if (!_regeistCallback) {
        _regeistCallback = [NSMutableDictionary dictionary];
    }
    return _regeistCallback;
}

+ (void)setRecordCallback:(NSMutableDictionary *)recordCallback {
    _recordCallback = recordCallback;
}

+ (NSMutableDictionary *)recordCallback {
    if (!_recordCallback) {
        _recordCallback = [NSMutableDictionary dictionary];
    }
    return _recordCallback;
}

+ (id)registCallback:(LKCCPUCallBack)callback timeInterval:(int)interval {
    os_unfair_lock_lock(&_lock);
    if (interval <= 0) {
        assert("time interval 不应该是0");
        return (id)callback;
    }
    if (LKCExceptionCPUMonitor.recordCallback[(id)callback]) {
        return (id)callback;
    }
    LKCExceptionCPUMonitor.recordCallback[(id)callback] = @(interval);
    NSMutableArray *callbacks = [LKCExceptionCPUMonitor.regeistCallback valueForKey:[NSString stringWithFormat:@"%d",interval]];
    if (!callbacks) {
        callbacks = [NSMutableArray array];
    }
    [callbacks addObject:(id)callback];
    [LKCExceptionCPUMonitor.regeistCallback setValue:callbacks forKey:[NSString stringWithFormat:@"%d",interval]];
    if(_timer == nil) {     // request to start new timer
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_queue_create("com.larkException.cpu.monitor", 0));
        dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(_timer, ^{
            os_unfair_lock_lock(&_lock);
            [self processTimer];
            os_unfair_lock_unlock(&_lock);
        });
        dispatch_resume(_timer);
    }
    os_unfair_lock_unlock(&_lock);
    return (id)callback;
}

+ (void)processTimer {
    _counter++;
    double cpuUsage = [self cpuUsage];
    for (NSString *timeInterval in LKCExceptionCPUMonitor.regeistCallback.allKeys) {
        if (_counter % [timeInterval intValue] == 0) {
            NSArray *tempArray = [NSArray arrayWithArray:LKCExceptionCPUMonitor.regeistCallback[timeInterval]];
            for (LKCCPUCallBack callback in tempArray) {
                callback(cpuUsage);
            }
        }
    }
}

+ (double)cpuUsage {
    double cpuUsage = 0;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    thread_basic_info_t basic_info_th;
    // get threads in the task
    kern_return_t kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return 0;
    }

    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;

    // for each thread
    for (int idx = 0; idx < (int)thread_count; idx++) {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[idx], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return 0;
        }
        basic_info_th = (thread_basic_info_t)thinfo;
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            cpuUsage += basic_info_th->cpu_usage / (float)TH_USAGE_SCALE;
        }
    }
    for(size_t index = 0; index < thread_count; index++)
        mach_port_deallocate(mach_task_self(), thread_list[index]);

    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    NSAssert(kr == KERN_SUCCESS,@"返回值不合法");
    return cpuUsage;
}


+ (void)unRegistCallback:(id)callback {
    os_unfair_lock_lock(&_lock);
    if (LKCExceptionCPUMonitor.recordCallback[callback]) {
        int value = [LKCExceptionCPUMonitor.recordCallback[callback] intValue];
        [LKCExceptionCPUMonitor.recordCallback removeObjectForKey:callback];
        NSMutableArray *callbacks = LKCExceptionCPUMonitor.regeistCallback[[NSString stringWithFormat:@"%d",value]];
        [callbacks removeObject:callback];
    }
    if (LKCExceptionCPUMonitor.recordCallback.count <= 0) {
        if(_timer != nil) {
            dispatch_source_cancel(_timer);
            _timer = nil;
        }
        _counter = 0;
    }
    os_unfair_lock_unlock(&_lock);
}

@end
