//
//  HMDSubThreadRunloopInfo.m
//  Heimdallr
//
//  Created by wangyinhui on 2023/4/25.
//
#import <stdio.h>
#import <pthread.h>

#import "HMDSubThreadRunloopMonitorPlugin.h"
#import <BDFishhook/BDFishhook.h>
#import "HMDAsyncThread.h"
#import "hmd_thread_backtrace.h"
#import "HMDRunloopMonitor.h"
#import "HMDSwizzle.h"
#import "HMDUserExceptionTracker.h"

#define HMDSubRunloopMonitorMaxCount 5
#define HMDSubRunloopTimeoutRecordMaxCount 5


static pthread_key_t runloopMonitorKey;
static std::atomic_int runloopMonitorCount;
static std::atomic_int runloopTimeoutRecordCount;

#pragma mark - HMDSubThreadRunloopInfo private

@interface HMDSubThreadRunloopMonitorPlugin ()

-(void)addRunloop:(CFRunLoopRef)runloop thread:(hmd_thread)tid;

@end

@interface  NSRunLoop (HMDRunloopObserver)

- (BOOL)hmd_RunMode:(NSRunLoopMode)mode beforeDate:(NSDate *)limitDate;

@end

#pragma mark - NSRunloop hook

@implementation NSRunLoop (HMDRunloopObserver)

- (BOOL)hmd_RunMode:(NSRunLoopMode)mode beforeDate:(NSDate *)limitDate {
    hmd_thread tid = hmdthread_self();
    //Only monitor child threads, main thread should use HMDMainRunloopMonitor
    if (tid != hmdbt_main_thread) {
        CFRunLoopRef currentRunloop = CFRunLoopGetCurrent();
        
        [[HMDSubThreadRunloopMonitorPlugin pluginInstance] addRunloop:currentRunloop thread:tid];
    }
    return [self hmd_RunMode:mode beforeDate:limitDate];
}

@end


static CFRunLoopRunResult (*orig_CFRunLoopRunInMode) (CFRunLoopMode mode, CFTimeInterval seconds, Boolean returnAfterSourceHandled);

static CFRunLoopRunResult hmd_CFRunLoopRunInMode(CFRunLoopMode mode, CFTimeInterval seconds, Boolean returnAfterSourceHandled) {
    hmd_thread tid = hmdthread_self();
    //Only monitor child threads, main thread should use HMDMainRunloopMonitor
    if (tid != hmdbt_main_thread) {
        CFRunLoopRef currentRunloop = CFRunLoopGetCurrent();
        [[HMDSubThreadRunloopMonitorPlugin pluginInstance] addRunloop:currentRunloop thread:tid];
    }
    return orig_CFRunLoopRunInMode(mode, seconds, returnAfterSourceHandled);
}

void hmd_hook_runloop_run(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct bd_rebinding rebinding;
        rebinding.name = "CFRunLoopRunInMode";
        rebinding.replacement = (void *)hmd_CFRunLoopRunInMode;
        rebinding.replaced = (void **)&orig_CFRunLoopRunInMode;
        bd_rebind_symbols(&rebinding, 1);
        bd_rebind_symbols_patch(&rebinding, 1);
        
        hmd_swizzle_instance_method(NSRunLoop.class, @selector(runMode:beforeDate:), @selector(hmd_RunMode:beforeDate:));
    });
}

#pragma mark -Runloop monitor Callback

static NSTimeInterval monitorCallback(struct HMDRunloopMonitorInfo *info) {
    if(!HMDSubThreadRunloopMonitorPlugin.pluginInstance.isRunning) return -1;
    
    if(runloopTimeoutRecordCount >= HMDSubRunloopTimeoutRecordMaxCount) return -1;
    
    switch (info->status) {
        case HMDRunloopStatusBegin:
        {
            HMDLog(@"[sub-runloop]runloop for thread %ld begin", info->tid);
            return HMDSubThreadRunloopMonitorPlugin.pluginInstance.subThreadRunloopTimeoutDuration;
            break;
        }
        case HMDRunloopStatusDuration:
        {
            HMDLog(@"[sub-runloop]runloop for thread %ld Duration", info->tid);
            HMDUserExceptionParameter *param = [HMDUserExceptionParameter initAllThreadParameterWithExceptionType:@"sub_thread_runloop_timeout" customParams:nil filters:nil];
            param.keyThread = (thread_t)info->tid;
            [[HMDUserExceptionTracker sharedTracker] trackThreadLogWithParameter:param callback:^(NSError * _Nullable error) {
                HMDLog(@"[sub-runloop]upload report err, %@", error);
            }];
            runloopTimeoutRecordCount++;
            return -1;
            break;
        }
        case HMDRunloopStatusOver:
        {
            HMDLog(@"[sub-runloop]runloop for thread %ld Over", info->tid);
            return -1;
            break;
        }
        default:
        {
            return -1;
            break;
        }
    }
}

#pragma mark -PthreadKeyCleanup
static void cleanupSubThreadRunloopMonitor(void *monitor) {
    ((HMDRunloopMonitor *)monitor)->stop();
}

#pragma mark -HMDSubThreadRunloopInfo

@implementation HMDSubThreadRunloopMonitorPlugin

+ (instancetype)pluginInstance {
    static dispatch_once_t onceToken;
    static HMDSubThreadRunloopMonitorPlugin *subRunloopInfo;
    dispatch_once(&onceToken, ^{
        subRunloopInfo = [[HMDSubThreadRunloopMonitorPlugin alloc] init];
        pthread_key_create(&runloopMonitorKey, cleanupSubThreadRunloopMonitor);
    });
    
    return subRunloopInfo;
}

- (void)start {
    _isRunning = YES;
    hmd_hook_runloop_run();
}

- (void)stop {
    _isRunning = NO;
}

- (void)setupThreadConfig:(HMDThreadMonitorConfig *)config {
    _observerThreadList = config.subThreadRunloopNameList;
    _subThreadRunloopTimeoutDuration = config.subThreadRunloopTimeoutDuration;
}

- (void)addRunloop:(CFRunLoopRef)runloop thread:(hmd_thread)tid {
    if(!_isRunning) return;
    
    char thread_name_buf[256] = {0};
    hmdthread_getName(tid, thread_name_buf, sizeof(thread_name_buf));
    NSString *threadName = [NSString stringWithUTF8String:thread_name_buf];
    
    if (![self isThreadNeedObserver:threadName]) return;
    
    if (pthread_getspecific(runloopMonitorKey)) return;
    
    if (runloopMonitorCount >= HMDSubRunloopMonitorMaxCount) return;
    
    NSString *observerName = [NSString stringWithFormat:@"com.hmd.observer-%@-tid:%ld",threadName, tid];
    
    HMDRunloopMonitor *monitor =  new HMDRunloopMonitor(runloop, observerName.UTF8String, tid);
    monitor->addObserver(monitorCallback);
    pthread_setspecific(runloopMonitorKey, monitor);
    runloopMonitorCount++;
    
}

- (BOOL)isThreadNeedObserver:(NSString *)threadName {
    __block BOOL isThreadNeedObserver = NO;
    if (!_observerThreadList || _observerThreadList.count == 0){
        return NO;
    }
    [_observerThreadList enumerateObjectsUsingBlock:^(NSString  * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([threadName isEqual:obj]) {
            *stop = YES;
            isThreadNeedObserver = YES;
        }
    }];
    return isThreadNeedObserver;
}

@end
