//
//  HMDLauchPerfCollector.m
//  Heimdallr
//
//  Created by zhangxiao on 2021/6/7.
//

#import "HMDLaunchPerfCollector.h"
#import <mach/task.h>
#import <mach/mach.h>
#import <pthread/introspection.h>
#import "HMDAsyncThread.h"
#import "HMDGCD.h"
#import "NSArray+HMDSafe.h"
#import "NSDictionary+HMDSafe.h"

NSString *const kHMDLaunchPerfBaseDataKey = @"list_data";
NSString *const kHMDLaunchPerfThreadListKey = @"current_thread_list";
NSString *const kHMDLaunchPerfSleepTime = @"launch_perf_sleep_time";
NSString *const kHMDLaunchPerfRunnableTime = @"launch_perf_runnable_time";
NSString *const kHMDLaunchPerfThreadCount = @"launch_perf_all_thread_count";
NSString *const kHMDLaunchPerfCPUTime = @"launch_perf_cpu_time";
NSString *const kHMDLaunchPerfSuspendCount = @"launch_perf_suspend_times";
NSString *const kHMDLaunchPerfCPUUage = @"launch_perf_cpu_usage_percent";
NSString *const kHMDLaunchPerfMinforFault = @"launch_perf_minfor_fault";
NSString *const kHMDLaunchPerfMajorFault = @"launch_perf_major_fault";
NSString *const kHMDLaunchPerfVoluntarySwitches = @"launch_perf_voluntary_switches";
NSString *const kHMDLaunchPerfInvoluntarySwitches = @"launch_perf_involuntary_switches";

typedef void (^HMDLaunchPerfThreadHandle)(pthread_t thread, int event);
static HMDLaunchPerfThreadHandle commonHandler;
pthread_introspection_hook_t hmd_start_oldpthread_introspection_hook = NULL;

@interface HMDLaunchPerfCollector ()

@property (nonatomic, strong) NSMutableArray *launchTheads;
@property (nonatomic, strong) NSMutableArray *growthThread;
@property (nonatomic, strong) NSMutableDictionary *perfMap;
@property (nonatomic, assign) NSInteger allThreadCount;

@end

@implementation HMDLaunchPerfCollector

- (instancetype)init {
    self = [super init];
    if (self) {
        _launchTheads = [NSMutableArray array];
        _growthThread = [NSMutableArray array];
        _perfMap = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark --- get peformance info
- (NSArray *)launchTheadNames {
    return [[self launchTheadNames] copy];
}

- (NSDictionary *)launchPer {
    return [self.perfMap copy];
}

- (NSDictionary *)collectLaunchStagePerf {
//    dispatch_sync(self.targetQueue, ^{
//        [self getBaseMainThreadPerf];
//    });
    NSArray *threads = [[self threadInfoWhileLaunch] copy];
    NSDictionary *perfDict = [[self getBaseMainThreadPerf] copy];
    return @{
        kHMDLaunchPerfBaseDataKey: perfDict?:@{},
        kHMDLaunchPerfThreadListKey: threads?:@[]
    };
}

#pragma mark--- thread information collector
- (void)installThreadCountMonitor {
    mach_msg_type_number_t thread_count = 0;
    [self getCurrentThreadNames:self.launchTheads count:&thread_count];
    [self registerThreadOperationHandler];
}

- (NSArray *)threadInfoWhileLaunch {
    mach_msg_type_number_t thread_count = 0;
    [self getCurrentThreadNames:self.launchTheads count:&thread_count];
    self.allThreadCount = thread_count;
    if (self.growthThread.count > 0) {
        [self.launchTheads addObjectsFromArray:self.growthThread];
    }

    return [self.launchTheads copy];
}

#pragma mark--- thread uitilty
- (void)getCurrentThreadNames:(NSMutableArray *)threads count:(mach_msg_type_number_t *)count {
    thread_array_t thread_list;
    mach_msg_type_number_t thread_count;
    // get threads in the task
    kern_return_t kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return;
    }
    *count = thread_count;
    // for each thread
    for (int idx = 0; idx < (int) thread_count; idx++) {
        thread_t thread = thread_list[idx];
        char thread_name_buffer[256];
        NSString *threadNameStr = nil;
        bool queue_res = hmdthread_getQueueName(thread, thread_name_buffer, sizeof(thread_name_buffer));
        if (queue_res) {
            threadNameStr = [NSString stringWithUTF8String:thread_name_buffer];
        } else {
            bool thread_res = hmdthread_getThreadName(thread, thread_name_buffer, sizeof(thread_name_buffer));
            if (thread_res) {
                threadNameStr = [NSString stringWithUTF8String:thread_name_buffer];
            }
        }
        if (threadNameStr) {
            threadNameStr = threadNameStr.length == 0 ? @"null" : threadNameStr;
            [threads hmd_addObject:threadNameStr];
        }
    }

    for (size_t index = 0; index < thread_count; index++) {
        mach_port_deallocate(mach_task_self(), thread_list[index]);
    }

    kr = vm_deallocate(mach_task_self(), (vm_offset_t) thread_list, thread_count * sizeof(thread_t));
    NSAssert(kr == KERN_SUCCESS, @"The return value is illegal!");
}

- (void)registerThreadOperationHandler {
    commonHandler = ^(pthread_t thread, int event) {
        if (!self.disable && !self.isLaunchEnd) {
            if (event == PTHREAD_INTROSPECTION_THREAD_CREATE) {
                int mach_thread = pthread_mach_thread_np(thread);
                char thread_name_buffer[256];
                NSString *threadNameStr = nil;
                bool queue_res = hmdthread_getQueueName(mach_thread, thread_name_buffer, sizeof(thread_name_buffer));
                if (queue_res) {
                    threadNameStr = [NSString stringWithUTF8String:thread_name_buffer];
                } else {
                    bool thread_res = hmdthread_getThreadName(mach_thread, thread_name_buffer, sizeof(thread_name_buffer));
                    if (thread_res) {
                        threadNameStr = [NSString stringWithUTF8String:thread_name_buffer];
                    }
                }
                if (threadNameStr) {
                    threadNameStr = threadNameStr.length == 0 ? @"null" : threadNameStr;
                    hmd_safe_dispatch_async(self.targetQueue, ^{
                        [self.growthThread addObject:threadNameStr];
                    });
                }
            }
        }
    };
    hmd_start_oldpthread_introspection_hook = pthread_introspection_hook_install(hmd_pthread_introspection_hook_func);
}

void hmd_pthread_introspection_hook_func(unsigned int event, pthread_t thread, void *addr, size_t size) {
    if (hmd_start_oldpthread_introspection_hook != NULL) {
        hmd_start_oldpthread_introspection_hook(event, thread, addr, size);
    }
    if (commonHandler) {
        commonHandler(thread, event);
    }
}

#pragma mark--- base perf
- (NSDictionary *)getBaseMainThreadPerf {
    thread_t cur_thread = (thread_t)hmdthread_self();
    mach_msg_type_number_t thread_info_count = THREAD_INFO_MAX;
    thread_info_data_t thinfo;
    kern_return_t kr = thread_info(cur_thread, THREAD_BASIC_INFO, (thread_info_t)thinfo, &thread_info_count);
    if (kr != KERN_SUCCESS) {
        return nil;
    }
    thread_basic_info_t basic_info = (thread_basic_info_t)thinfo;
    NSMutableDictionary *perfDict = [NSMutableDictionary dictionary];
    if (!(basic_info->flags & TH_FLAGS_IDLE)) {
        // cpu user time
        time_value_t user_time = basic_info->user_time;
        // cpu system time
//        time_value_t system_time = basic_info->system_time;
        // ms
        integer_t user_all_ms = (user_time.seconds * 1000) + (user_time.microseconds / 1000);
//        integer_t sys_all_ms = (system_time.seconds * 1000) + (system_time.seconds / 1000);
        // cpu usage
//        float cpu_usage = basic_info->cpu_usage / (float)TH_USAGE_SCALE;
        // sleep sec
//        integer_t sleep_sec = basic_info->sleep_time;
//        integer_t suspend_count = basic_info->suspend_count;
        [perfDict hmd_setObject:@(user_all_ms) forKey:kHMDLaunchPerfCPUTime];
        [perfDict hmd_setObject:@(self.allThreadCount) forKey:kHMDLaunchPerfThreadCount];
    }
    struct rusage usage;
    int ret = getrusage(RUSAGE_SELF, &usage);
    if(ret == 0){
        [perfDict hmd_setObject:@(usage.ru_nvcsw) forKey:kHMDLaunchPerfVoluntarySwitches];
        [perfDict hmd_setObject:@(usage.ru_nivcsw) forKey:kHMDLaunchPerfInvoluntarySwitches];
        [perfDict hmd_setObject:@(usage.ru_minflt) forKey:kHMDLaunchPerfMinforFault];
        [perfDict hmd_setObject:@(usage.ru_majflt) forKey:kHMDLaunchPerfMajorFault];
    }
    return perfDict.count ? perfDict : nil;
}

@end
