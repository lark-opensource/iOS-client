//
//  HMDThreadInversionMonitor.m
//  Heimdallr
//
//  Created by xushuangqing on 2022/3/15.
//

#import "HMDThreadInversionMonitorPlugin.h"
#import <BDFishhook/BDFishhook.h>
#import "HMDUserExceptionTracker.h"
#import "HMDALogProtocol.h"
#import "HMDAsyncThread.h"
#import <os/lock.h>
#include <pthread/pthread.h>
#include <mach-o/dyld.h>
#include <mach/semaphore.h>
#include <mach/mach_time.h>
#include <unordered_map>
#include <vector>

static int32_t current_thread_priority(void);
//优先级反转，wait 的时间超过阈值才抓栈和上报，3/60 丢 3 帧，也是流畅度监控的阈值
static const NSTimeInterval KHMDPriorityInverstionIntervalThreshold = 3.0 / 60.0;

struct HMDThreadSignalInfo {
    unsigned long semaphore;
    qos_class_t qos;
    int32_t cur_priority;
    CFArrayRef backtrace;
    
    HMDThreadSignalInfo(HMDThreadSignalInfo const &info) {
        this->semaphore = info.semaphore;
        this->qos = info.qos;
        this->backtrace = info.backtrace;
        this->cur_priority = info.cur_priority;
        CFRetain(this->backtrace);
    }
    
    HMDThreadSignalInfo(unsigned long semaphore, qos_class_t qos, int32_t priority, CFArrayRef backtrace) : semaphore(semaphore), qos(qos), cur_priority(priority), backtrace(backtrace)
    {
        CFRetain(this->backtrace);
    }
    ~HMDThreadSignalInfo() {
        CFRelease(this->backtrace);
    }
};

struct HMDThreadWaitInfo {
    unsigned long semaphore;
    unsigned long thread;
    unsigned long pthread;
    qos_class_t qos;
    int32_t cur_priority;
    uint64_t timestamp;
    std::vector<HMDThreadSignalInfo> signals;
    
    HMDThreadWaitInfo(unsigned long semaphore) : semaphore(semaphore) {
        this->thread = hmdthread_self();
        this->pthread = (unsigned long)pthread_self();
        this->qos = qos_class_self();
        this->cur_priority = current_thread_priority();
        this->timestamp = mach_absolute_time();
    }
};

#pragma mark - Utility

API_AVAILABLE(ios(10.0))
static os_unfair_lock HMDWaitInfoMapLock;

static void init_wait_info_map_lock() {
    if (@available(iOS 10.0, *)) {
        HMDWaitInfoMapLock = OS_UNFAIR_LOCK_INIT;
    }
}

static void wait_info_map_lock() {
    if (@available(iOS 10.0, *)) {
        os_unfair_lock_lock(&HMDWaitInfoMapLock);
    }
}
static void wait_info_map_unlock() {
    if (@available(iOS 10.0, *)) {
        os_unfair_lock_unlock(&HMDWaitInfoMapLock);
    }
}

static NSTimeInterval mach_time_to_seconds(uint64_t time) {
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);
    return (double)time * (double)timebase.numer /
    (double)timebase.denom / NSEC_PER_SEC;
}

static int32_t current_thread_priority(void) {
    thread_t cur_thread = (thread_t)hmdthread_self();
    mach_msg_type_number_t thread_info_count = THREAD_INFO_MAX;
    thread_info_data_t thinfo;
    kern_return_t kr = thread_info(cur_thread, THREAD_EXTENDED_INFO, (thread_info_t)thinfo, &thread_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    thread_extended_info_t extend_info = (thread_extended_info_t)thinfo;
    return extend_info->pth_curpri;
}

#pragma mark - Map

static std::unordered_map<unsigned long, HMDThreadWaitInfo> *HMDThreadWaitInfoMap;
static void hmd_semaphore_before_wait(unsigned long semaphore) {
    HMDThreadWaitInfo info(semaphore);
    wait_info_map_lock();
    HMDThreadWaitInfoMap->insert(std::pair <unsigned long, HMDThreadWaitInfo>(semaphore, info));
    wait_info_map_unlock();
}

static void hmd_semaphore_after_wait(unsigned long semaphore) {
    wait_info_map_lock();
    auto iterator = HMDThreadWaitInfoMap->find(semaphore);
    if (iterator == HMDThreadWaitInfoMap->end()) {
        wait_info_map_unlock();
    }
    else {
        HMDThreadWaitInfo waitInfo = iterator->second;
        HMDThreadWaitInfoMap->erase(iterator);
        wait_info_map_unlock();
        NSTimeInterval interval = mach_time_to_seconds(mach_absolute_time() - waitInfo.timestamp);
        
        if (waitInfo.signals.size() > 0 && interval > KHMDPriorityInverstionIntervalThreshold) {
            __block NSUInteger backtraceCount = 0;
            NSMutableArray<HMDThreadBacktrace *> *backtraces = [NSMutableArray array];
            for (auto signalInfo = waitInfo.signals.begin(); signalInfo != waitInfo.signals.end(); signalInfo++) {
                NSArray<HMDThreadBacktrace *> *array = (__bridge NSArray *)signalInfo->backtrace;
                [array enumerateObjectsUsingBlock:^(HMDThreadBacktrace * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    obj.crashed = NO;
                    obj.threadIndex = backtraceCount;
                    obj.name = [NSString stringWithFormat:@"%@ QoS:%d, priority:%d", obj.name, signalInfo->qos, signalInfo->cur_priority];
                    backtraceCount++;
                }];
                [backtraces addObjectsFromArray:array];
            }
            
            if (backtraces.count > 0) {
                HMDUserExceptionParameter *userExceptionParam = [HMDUserExceptionParameter initCurrentThreadParameterWithExceptionType:@"thread_inversion" debugSymbol:NO skippedDepth:2 customParams:nil filters:nil];;
                NSArray<HMDThreadBacktrace *> *inversionBacktrace = [[HMDUserExceptionTracker sharedTracker] getBacktracesWithParameter:userExceptionParam];
                [inversionBacktrace enumerateObjectsUsingBlock:^(HMDThreadBacktrace * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    obj.crashed = YES;
                    obj.threadIndex = backtraceCount;
                    obj.name = [NSString stringWithFormat:@"%@ QoS:%d, priority:%d, wait_interval: %fs", obj.name, waitInfo.qos, waitInfo.cur_priority, interval];
                    backtraceCount++;
                }];
                [backtraces addObjectsFromArray:inversionBacktrace];
                
                NSMutableDictionary *customParams = [NSMutableDictionary new];
                [customParams setValue:@([NSThread isMainThread]) forKey:@"is_main_thread_inversed"];
                [customParams setValue:@(interval) forKey:@"waiting_interval"];
                NSMutableDictionary *filters = [NSMutableDictionary new];
                [filters setValue:[@([NSThread isMainThread]) stringValue] forKey:@"is_main_thread_inversed"];
                [[HMDUserExceptionTracker sharedTracker] trackUserExceptionWithType:@"priority_inversion" backtracesArray:backtraces customParams:customParams filters:filters callback:^(NSError * _Nullable error) {
                    if (error) {
                        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[PriorityInversion] User Exception Error %@.", error);
                    }
                }];
            }
        }
    }
}

static void hmd_semaphore_before_signal(unsigned long semaphore, unsigned long thread) {
    wait_info_map_lock();
    auto iterator = HMDThreadWaitInfoMap->find(semaphore);
    if (iterator == HMDThreadWaitInfoMap->end()) {
        wait_info_map_unlock();
    }
    else {
        HMDThreadWaitInfo waitInfo = iterator->second;
        wait_info_map_unlock();
        
        qos_class_t currentQos = qos_class_self();
        int32_t currentPriority = current_thread_priority();
        NSTimeInterval interval = mach_time_to_seconds(mach_absolute_time() - waitInfo.timestamp);
        if (waitInfo.qos > currentQos && waitInfo.cur_priority > currentPriority && (thread == 0 || thread == waitInfo.thread || thread == waitInfo.pthread) && interval > KHMDPriorityInverstionIntervalThreshold) {
            //优先级反转
            HMDUserExceptionParameter *userExceptionParam = [HMDUserExceptionParameter initCurrentThreadParameterWithExceptionType:@"priority_inversion" debugSymbol:NO skippedDepth:2 customParams:nil filters:nil];
            NSArray<HMDThreadBacktrace *> *backtrace = [[HMDUserExceptionTracker sharedTracker] getBacktracesWithParameter:userExceptionParam];
            CFArrayRef arrayRef = (__bridge CFArrayRef)backtrace;
            HMDThreadSignalInfo signalInfo(semaphore, currentQos, currentPriority, arrayRef);
            wait_info_map_lock();
            auto iter = HMDThreadWaitInfoMap->find(semaphore);
            if (iter != HMDThreadWaitInfoMap->end()) {
                iter->second.signals.push_back(signalInfo);
            }
            wait_info_map_unlock();
        }
    }
    
}

#pragma mark - Hook semaphore

static std::atomic<bool> HMDThreadInversionCheckRunning;

static  kern_return_t   (*orig_semaphore_signal)(semaphore_t semaphore);
static  kern_return_t   hooked_semaphore_signal(semaphore_t semaphore) {
    if (HMDThreadInversionCheckRunning) {hmd_semaphore_before_signal(semaphore, 0);}
    return orig_semaphore_signal(semaphore);
}

static  kern_return_t   (*orig_semaphore_signal_all)(semaphore_t semaphore);
static  kern_return_t   hooked_semaphore_signal_all(semaphore_t semaphore) {
    if (HMDThreadInversionCheckRunning) {hmd_semaphore_before_signal(semaphore, 0);}
    return orig_semaphore_signal_all(semaphore);
}


static  kern_return_t   (*orig_semaphore_wait)(semaphore_t semaphore);
static  kern_return_t   hooked_semaphore_wait(semaphore_t semaphore) {
    if (HMDThreadInversionCheckRunning) {
        hmd_semaphore_before_wait(semaphore);
        kern_return_t res = orig_semaphore_wait(semaphore);
        hmd_semaphore_after_wait(semaphore);
        return res;
    }
    else {
        return orig_semaphore_wait(semaphore);
    }
}

static  kern_return_t   (*orig_semaphore_timedwait)(semaphore_t semaphore,
                                                      mach_timespec_t wait_time);
static  kern_return_t   hooked_semaphore_timedwait(semaphore_t semaphore,
                                                   mach_timespec_t wait_time) {
    if (HMDThreadInversionCheckRunning) {
        hmd_semaphore_before_wait(semaphore);
        kern_return_t res = orig_semaphore_timedwait(semaphore, wait_time);
        hmd_semaphore_after_wait(semaphore);
        return res;
    }
    else {
        return orig_semaphore_timedwait(semaphore, wait_time);
    }
}

static  kern_return_t   (*orig_semaphore_timedwait_signal)(semaphore_t wait_semaphore,
    semaphore_t signal_semaphore,
    mach_timespec_t wait_time);
static  kern_return_t   hooked_semaphore_timedwait_signal(semaphore_t       wait_semaphore,
    semaphore_t signal_semaphore,
                                                          mach_timespec_t wait_time) {
    if (HMDThreadInversionCheckRunning) {
        hmd_semaphore_before_wait(wait_semaphore);
        hmd_semaphore_before_signal(signal_semaphore, 0);
        kern_return_t res = orig_semaphore_timedwait_signal(wait_semaphore, signal_semaphore, wait_time);
        hmd_semaphore_after_wait(wait_semaphore);
        return res;
    }
    else {
        return orig_semaphore_timedwait_signal(wait_semaphore, signal_semaphore, wait_time);
    }
}

static  kern_return_t   (*orig_semaphore_wait_signal)(semaphore_t wait_semaphore,
    semaphore_t signal_semaphore);
static  kern_return_t   hooked_semaphore_wait_signal(semaphore_t wait_semaphore,
                                                     semaphore_t signal_semaphore) {
    if (HMDThreadInversionCheckRunning) {
        hmd_semaphore_before_wait(wait_semaphore);
        hmd_semaphore_before_signal(signal_semaphore, 0);
        kern_return_t res = orig_semaphore_wait_signal(wait_semaphore, signal_semaphore);
        hmd_semaphore_after_wait(wait_semaphore);
        return res;
    }
    else {
        return orig_semaphore_wait_signal(wait_semaphore, signal_semaphore);
    }
}

static  kern_return_t   (*orig_semaphore_signal_thread)(semaphore_t semaphore,
                                                        thread_t thread);
static  kern_return_t   hooked_semaphore_signal_thread(semaphore_t semaphore,
                                                thread_t thread) {
    if (HMDThreadInversionCheckRunning) {hmd_semaphore_before_signal(semaphore, thread);}
    return orig_semaphore_signal_thread(semaphore, thread);
}

#pragma mark Hook pthread_cond

int (*orig_pthread_cond_signal)(pthread_cond_t *);
int hooked_pthread_cond_signal(pthread_cond_t *cond) {
    if (HMDThreadInversionCheckRunning) {hmd_semaphore_before_signal((unsigned long)cond, 0);}
    return orig_pthread_cond_signal(cond);
}

int (*orig_pthread_cond_signal_thread_np)(pthread_cond_t *, pthread_t _Nullable);
int hooked_pthread_cond_signal_thread_np(pthread_cond_t *cond, pthread_t _Nullable pthread) {
    if (HMDThreadInversionCheckRunning) {hmd_semaphore_before_signal((unsigned long)cond, (unsigned long)pthread);}
    return orig_pthread_cond_signal_thread_np(cond, pthread);
}

int (*orig_pthread_cond_broadcast)(pthread_cond_t *);
int hooked_pthread_cond_broadcast(pthread_cond_t *cond) {
    if (HMDThreadInversionCheckRunning) {hmd_semaphore_before_signal((unsigned long)cond, 0);}
    return orig_pthread_cond_broadcast(cond);
}

int (*orig_pthread_cond_wait)(pthread_cond_t * __restrict,
                              pthread_mutex_t * __restrict);
int hooked_pthread_cond_wait(pthread_cond_t * cond,
                      pthread_mutex_t * mutex) {
    if (HMDThreadInversionCheckRunning) {
        hmd_semaphore_before_wait((unsigned long)cond);
        int res = orig_pthread_cond_wait(cond, mutex);
        hmd_semaphore_after_wait((unsigned long)cond);
        return res;
    }
    else {
        return orig_pthread_cond_wait(cond, mutex);
    }
}

int (*orig_pthread_cond_timedwait)(
        pthread_cond_t * __restrict cond, pthread_mutex_t * __restrict mutex,
                                   const struct timespec * _Nullable __restrict timespec);
int hooked_pthread_cond_timedwait(
        pthread_cond_t * __restrict cond, pthread_mutex_t * __restrict mutex,
                           const struct timespec * _Nullable __restrict timespec) {
    if (HMDThreadInversionCheckRunning) {
        hmd_semaphore_before_wait((unsigned long)cond);
        int res = orig_pthread_cond_timedwait(cond, mutex, timespec);
        hmd_semaphore_after_wait((unsigned long)cond);
        return res;
    }
    else {
        return orig_pthread_cond_timedwait(cond, mutex, timespec);
    }
}

int (*orig_pthread_cond_timedwait_relative_np)(pthread_cond_t *, pthread_mutex_t *,
        const struct timespec * _Nullable);
int hooked_pthread_cond_timedwait_relative_np(pthread_cond_t *cond, pthread_mutex_t *mutex,
                                       const struct timespec * _Nullable timespec) {
    if (HMDThreadInversionCheckRunning) {
        hmd_semaphore_before_wait((unsigned long)cond);
        int res = orig_pthread_cond_timedwait_relative_np(cond, mutex, timespec);
        hmd_semaphore_after_wait((unsigned long)cond);
        return res;
    }
    else {
        return orig_pthread_cond_timedwait_relative_np(cond, mutex, timespec);
    }
}

@interface HMDThreadInversionMonitorPlugin()

@property (atomic, assign) BOOL isRunning;
@property (nonatomic, strong) HMDThreadMonitorConfig *config;

@end

@implementation HMDThreadInversionMonitorPlugin

+ (instancetype)pluginInstance {
    static HMDThreadInversionMonitorPlugin *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDThreadInversionMonitorPlugin alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        init_wait_info_map_lock();
        HMDThreadWaitInfoMap = new std::unordered_map<unsigned long, HMDThreadWaitInfo>;
    }
    return self;
}

- (void)dealloc {
    wait_info_map_lock();
    delete HMDThreadWaitInfoMap;
    HMDThreadWaitInfoMap = NULL;
    wait_info_map_unlock();
}

- (void)start {
    if (!self.isRunning) {
        if (@available(iOS 10.0, *)) {
            self.isRunning = YES;
            HMDThreadInversionCheckRunning = self.isRunning && self.config.enableThreadInversionCheck;
            [self startFishhook];
        }
    }
}

- (void)stop {
    self.isRunning = NO;
    HMDThreadInversionCheckRunning = self.isRunning && self.config.enableThreadInversionCheck;
}

- (void)setupThreadConfig:(HMDThreadMonitorConfig *)config {
    if ([config isKindOfClass:[HMDThreadMonitorConfig class]]) {
        self.config = config;
        HMDThreadInversionCheckRunning = self.isRunning && self.config.enableThreadInversionCheck;
    }
}

#define HOOKED(func) hooked_##func
#define ORIG(func) orig_##func
#define REBINDING(func) \
    {#func, (void *)&HOOKED(func), (void **)&ORIG(func)}
static void image_add_callback (const struct mach_header *mh, intptr_t vmaddr_slide) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        struct bd_rebinding r[] = {
            REBINDING(semaphore_signal),
            REBINDING(semaphore_signal_all),
            REBINDING(semaphore_wait),
            REBINDING(semaphore_timedwait),
            REBINDING(semaphore_timedwait_signal),
            REBINDING(semaphore_wait_signal),
            REBINDING(semaphore_signal_thread),
            REBINDING(pthread_cond_signal),
            REBINDING(pthread_cond_signal_thread_np),
            REBINDING(pthread_cond_broadcast),
            REBINDING(pthread_cond_wait),
            REBINDING(pthread_cond_timedwait),
            REBINDING(pthread_cond_timedwait_relative_np),
        };
        bd_rebind_symbols_image((void *)mh, vmaddr_slide, r, sizeof(r)/sizeof(struct bd_rebinding));
    });
}

- (void)startFishhook {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dyld_register_func_for_add_image(image_add_callback);
    });
}

@end
