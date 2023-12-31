//
//  HMDThreadCountManager.m
//  Heimdallr
//
//  Created by zhangxiao on 2021/9/9.
//

#import "HMDThreadCountMonitorPlugin.h"
#import <pthread/introspection.h>
#import <mach/mach.h>
#import <stdatomic.h>
#import "HMDAsyncThread.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDAppleBacktracesLog.h"
#import "HMDGCD.h"
#import "HMDThreadMonitorTool.h"
#import <BDFishhook/BDFishhook.h>
#import <dispatch/introspection.h>
#import "pthread_extended.h"
#import "HMDALogProtocol.h"
#import "HMDUserExceptionTracker.h"
#import "HMDMacro.h"
// Utility
#import "HMDMacroManager.h"

static atomic_long hmd_thread_all_count;

pthread_introspection_hook_t hmd_thread_monitor_oldpthread_introspection_hook = NULL;
static void hmd_pthread_introspection_hook_func(unsigned int event, pthread_t thread, void *addr, size_t size) {
    if (hmd_thread_monitor_oldpthread_introspection_hook != NULL) {
        hmd_thread_monitor_oldpthread_introspection_hook(event, thread, addr, size);
    }

    if (event == PTHREAD_INTROSPECTION_THREAD_CREATE) {
        // create thread
        [[HMDThreadCountMonitorPlugin pluginInstance] threadCreated:thread];

    } else if (event == PTHREAD_INTROSPECTION_THREAD_START) {
        // start thread

    } else if (event == PTHREAD_INTROSPECTION_THREAD_TERMINATE) {
        // terminate thread -- start thread

    } else if (event == PTHREAD_INTROSPECTION_THREAD_DESTROY) {
        // destroy thread -- create thread
        [[HMDThreadCountMonitorPlugin pluginInstance] threadDestroy:thread];
    }
}


@interface HMDThreadCountMonitorPlugin () {
    pthread_rwlock_t _rwlock;
}

@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, strong) HMDThreadMonitorConfig *config;
@property (nonatomic, assign) NSTimeInterval nextUploadTime;
@property (nonatomic, strong) NSMutableDictionary *threadNameMap;
@property (nonatomic, strong) NSMutableDictionary *pthreadNameMap;
@property (nonatomic, strong) NSMutableDictionary *pthreadBacktraceMap;
@property (atomic, copy) NSString *specialThread;
@property (nonatomic, copy) NSDictionary *specialThreadWhiteList;

@end

@implementation HMDThreadCountMonitorPlugin

+ (instancetype)pluginInstance {
    static HMDThreadCountMonitorPlugin *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDThreadCountMonitorPlugin alloc] init];
    });

    return instance;
}

#pragma mark --- life cycle
- (instancetype)init {
    self = [super init];
    if (self) {
        _threadNameMap = [NSMutableDictionary dictionary];
        _pthreadNameMap = [NSMutableDictionary dictionary];
        _pthreadBacktraceMap = [NSMutableDictionary dictionary];
        rwlock_init_private(_rwlock);
    }
    return self;
}

- (void)start {
    if (!self.isRunning) {
        self.isRunning = YES;
        self.specialThread = nil;
        if (!HMD_IS_THREAD_SANITIZER) {
            [self initializeThreadCountMonitorEnv];
        }
    }
}

- (void)stop {
    self.isRunning = NO;
    self.specialThread = nil;
}

- (void)setupThreadConfig:(HMDThreadMonitorConfig *)config {
    if ([config isKindOfClass:[HMDThreadMonitorConfig class]]) {
        self.config = config;
        self.specialThreadWhiteList = config.specialThreadWhiteList;
    }
}

#pragma mark --- thread collect
- (void)initializeThreadCountMonitorEnv {
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    // get threads in the task
    kern_return_t kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr == KERN_SUCCESS) {
        hmd_thread_all_count = thread_count;
    }
    [self registerThreadCallback];
}

static void
(*orig_dispatch_introspection_hook_queue_item_enqueue)(dispatch_queue_t queue, dispatch_object_t item);

static void
hooked_dispatch_introspection_hook_queue_item_enqueue(__unsafe_unretained dispatch_queue_t queue,
                                                   __unsafe_unretained dispatch_object_t item) {

    orig_dispatch_introspection_hook_queue_item_enqueue(queue, item);
    // 短时间内大量创建这一名字的 queue 需要记录调用栈
    [[HMDThreadCountMonitorPlugin pluginInstance] getGCDBacktrace:queue];
    return;
}

static int
(*orig_pthread_setname_np)(const char* name);

static int
hooked_pthread_setname_np(const char* name) {
    if(name && strlen(name) > 0) {
        NSString *pthreadName = [HMDThreadMonitorTool preProcessThreadName:name];
        pthread_t pthread_id = pthread_self();
        dispatch_on_thread_monitor_queue(^{
            [[HMDThreadCountMonitorPlugin pluginInstance] addPthreadtoThreadNameMap:pthread_id pthreadName:pthreadName];
        });
    }
    return orig_pthread_setname_np(name);
}

#define HOOKED(func) hooked_##func
#define ORIG(func) orig_##func
#define REBINDING(func) \
    {#func, (void *)&HOOKED(func), (void **)&ORIG(func)}
- (void)registerThreadCallback {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hmd_thread_monitor_oldpthread_introspection_hook = pthread_introspection_hook_install(hmd_pthread_introspection_hook_func);
        struct bd_rebinding r[] = {
            REBINDING(dispatch_introspection_hook_queue_item_enqueue),
            REBINDING(pthread_setname_np)
        };
        int ret = bd_rebind_symbols(r, sizeof(r)/sizeof(struct bd_rebinding));
        if (ret < 0){
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDThreadMonitorCount] hook err");
        }
    });
}

- (void)getGCDBacktrace:(__unsafe_unretained dispatch_queue_t)queue {
    if (!self.isRunning || !self.config.enableSpecialThreadCount || NSProcessInfo.processInfo.systemUptime < self.nextUploadTime || !self.specialThread) {
        return;
    }

    const char *currentLabel = dispatch_queue_get_label(queue);
    NSString *queueName = [HMDThreadMonitorTool preProcessThreadName:currentLabel];

    if(self.specialThread && [self.specialThread isEqualToString:queueName]) {
        HMDThreadBacktrace *backtrace  = nil;
        if(self.config.enableBacktrace) {
            backtrace = [HMDThreadBacktrace backtraceOfThread:[HMDThreadBacktrace currentThread] symbolicate:NO skippedDepth:4 suspend:NO];
        }
        [self uploadSpecialThread:queueName backtrace:backtrace];
    }
}

- (void)getPthreadBacktrace:(pthread_t)pthread_id {
    if (!self.isRunning || !self.config.enableSpecialThreadCount || NSProcessInfo.processInfo.systemUptime < self.nextUploadTime || !self.config.enableBacktrace || !self.specialThread) {
        return;
    }

    HMDThreadBacktrace *backtrace = [HMDThreadBacktrace backtraceOfThread:[HMDThreadBacktrace currentThread] symbolicate:NO skippedDepth:5 suspend:NO];
    dispatch_on_thread_monitor_queue(^{
        [self.pthreadBacktraceMap hmd_setObject:backtrace forKey:@((unsigned long)pthread_id)];
    });
}

- (void)threadCreated:(pthread_t)pthread_id {
    if(!self.isRunning) {
        return ;
    }
    // pthread 线程在当前调用栈中调用 pthread_create，故会有 thread != pthread_self()
    if(!pthread_equal(pthread_id, pthread_self())) {
        [self getPthreadBacktrace:pthread_id];
    }
    // 此时 pthread_setname_np 可能还没执行，获取不到 pthread 的名字，故只在此只记录 GCD 线程。
    // pthread 线程在 hook_pthread_setname_np 中记录
    else {
        dispatch_on_thread_monitor_queue(^{
            [self addGCDtoThreadNameMap:pthread_id];
        });
    }
    dispatch_on_thread_monitor_queue(^{
        long cur_count = atomic_fetch_add_explicit(&hmd_thread_all_count, 1, memory_order_acq_rel);
        if (cur_count > self.config.threadCountThreshold) {
            [self reciveAllThreadCountException:cur_count];
        }
    });
}

- (void)threadDestroy:(pthread_t)pthread_id {
    if(!self.isRunning) {
        return ;
    }
    dispatch_on_thread_monitor_queue(^{
        atomic_fetch_sub_explicit(&hmd_thread_all_count, 1, memory_order_acq_rel);
        [self removeThreadNameMap:pthread_id];
    });
}

- (void)addPthreadtoThreadNameMap:(pthread_t)pthread_id pthreadName:(NSString *)name {
    if(!self.config.enableSpecialThreadCount) {
        return ;
    }
    [self.pthreadNameMap hmd_setObject:name forKey:@((unsigned long)pthread_id)];
    NSInteger oldValue = [self.threadNameMap hmd_intForKey:name];
    NSInteger newValue = oldValue ? oldValue + 1 : 1;
    [self.threadNameMap hmd_setObject:@(newValue) forKey:name];
    NSInteger threshold = [self.specialThreadWhiteList hmd_integerForKey:name] ?: self.config.specialThreadThreshold;
    if(newValue >= threshold && NSProcessInfo.processInfo.systemUptime > self.nextUploadTime) {
        if(!self.specialThread) {
            self.specialThread = name;
        }
        else if([self.specialThread isEqualToString:name]){
            if(self.config.enableBacktrace) {
                HMDThreadBacktrace *backtrace = [self.pthreadBacktraceMap hmd_objectForKey:@((unsigned long)pthread_id) class:[HMDThreadBacktrace class]];
                if(backtrace) {
                    [self uploadSpecialThread:name backtrace:backtrace];
                    [self.pthreadBacktraceMap removeAllObjects];
                }
            }
            else {
                [self uploadSpecialThread:name backtrace:nil];
            }
        }
    }
}

- (void)addGCDtoThreadNameMap:(pthread_t)pthread_id {
    if(!self.config.enableSpecialThreadCount) {
        return ;
    }
    thread_t thread_mach_port = pthread_mach_thread_np(pthread_id);
    char cThreadName[256] = {0};
    hmdthread_getName(thread_mach_port, cThreadName, sizeof(cThreadName));
    NSString *threadNameStr = [HMDThreadMonitorTool preProcessThreadName:cThreadName];
    if (!HMDIsEmptyString(threadNameStr)) {
        [self.pthreadNameMap hmd_setObject:threadNameStr forKey:@((unsigned long)pthread_id)];
        NSInteger oldValue = [self.threadNameMap hmd_intForKey:threadNameStr];
        NSInteger newValue = oldValue ? oldValue + 1 : 1;
        [self.threadNameMap hmd_setObject:@(newValue) forKey:threadNameStr];
        NSInteger threshold = [self.specialThreadWhiteList hmd_integerForKey:threadNameStr] ?: self.config.specialThreadThreshold;
        if(newValue >= threshold && NSProcessInfo.processInfo.systemUptime > self.nextUploadTime && !self.specialThread) {
            self.specialThread = threadNameStr;
        }
    }
}

- (void)removeThreadNameMap:(pthread_t)pthread_id {
    if(!self.config.enableSpecialThreadCount) {
        return ;
    }
    NSString *threadNameStr = [self.pthreadNameMap hmd_stringForKey:@((unsigned long)pthread_id)];
    if(threadNameStr && pthread_id) {
        [self.pthreadNameMap removeObjectForKey:@((unsigned long)pthread_id)];
        [self.pthreadBacktraceMap removeObjectForKey:@((unsigned long)pthread_id)];
        NSInteger oldValue = [self.threadNameMap hmd_intForKey:threadNameStr];
        NSInteger newValue = oldValue ? oldValue - 1 : 0;
        if(newValue <= 0) {
            [self.threadNameMap removeObjectForKey:threadNameStr];
        } else {
            if(self.specialThread && [self.specialThread isEqualToString:threadNameStr] && newValue < self.config.specialThreadThreshold) {
                self.specialThread = nil;
            }
            [self.threadNameMap hmd_setObject:@(newValue) forKey:threadNameStr];
        }
    }
}

- (void)uploadSpecialThread:(NSString *)name backtrace:(HMDThreadBacktrace *)backtrace {
    NSTimeInterval curTS = NSProcessInfo.processInfo.systemUptime;
    self.nextUploadTime = curTS + (double)self.config.countAnalysisInterval;
    self.specialThread = nil;
    dispatch_on_thread_monitor_queue(^{
        NSInteger count = [self.threadNameMap hmd_intForKey:name];
        
        NSMutableDictionary *customParams = [NSMutableDictionary new];
        NSString *threadString = [NSString stringWithFormat:@"%@ : %ld", name?:@"", (long)count];
        [customParams hmd_setObject:threadString forKey:@"special_thread"];
        [customParams hmd_setObject:@"thread_create" forKey:@"special_thread_exception_type"];
        
        NSMutableDictionary *filters = [NSMutableDictionary new];
        [filters hmd_setObject:name forKey:@"special_thread_creator"];
        [filters hmd_setObject:name forKey:@"special_thread"];
        NSString *levelStr = [HMDThreadMonitorTool getSpecialThreadLevel:count];
        [filters hmd_setObject:levelStr forKey:@"special_thread_level"];
        
        if(self.config.enableBacktrace && backtrace) {
            NSMutableArray *uploadBacktraces = [NSMutableArray array];
            backtrace.name = [NSString stringWithFormat:@"%@ created %lu special_threads %@", backtrace.name, count, name];
            backtrace.crashed = YES;
            HMDThreadBacktraceParameter *bpara = [[HMDThreadBacktraceParameter alloc] init];
            NSArray<HMDThreadBacktrace *> *array = [HMDThreadBacktrace backtraceOfAllThreadsWithParameter:bpara];
            [uploadBacktraces addObject:backtrace];
            [uploadBacktraces addObjectsFromArray:array];
            
            HMDUserExceptionParameter *para = [HMDUserExceptionParameter initBacktraceParameterWithExceptionType:kHMDSPECIALTHREADCOUNTEXCEPTION
                                                                                                 backtracesArray:uploadBacktraces
                                                                                                    customParams:customParams
                                                                                                         filters:filters];
            
            [[HMDUserExceptionTracker sharedTracker] trackThreadLogWithBacktraceParameter:para callback:^(NSError * _Nullable error) {
                if (error) {
                    HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[SpecialThreadCount] User Exception Error %@.", error);
                }
            }];
            
        } else {
            HMDUserExceptionParameter *para = [HMDUserExceptionParameter initBaseParameterWithExceptionType:kHMDSPECIALTHREADCOUNTEXCEPTION
                                                                                                      title:name?:@"unknown"
                                                                                                   subTitle:kHMDSPECIALTHREADCOUNTEXCEPTION
                                                                                               customParams:customParams
                                                                                                    filters:filters];
            
            [[HMDUserExceptionTracker sharedTracker] trackBaseExceptionWithBacktraceParameter:para callback:^(NSError * _Nullable error) {
                if (error) {
                    HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[SpecialThreadCount] User Exception Error %@.", error);
                }
            }];
            
        }
        
        
    });
}

#pragma mark --- process thread count
- (void)reciveAllThreadCountException:(NSInteger)curCount {
    // 触发这个判断条件是在 pthread create 的线程内,为了不阻塞其他线程这里将 operation thread 切换到 线程监控自己的线程内, 可能有些线程在任务添加到队列到任务执行这个过程中释放了但是误差不会很大.(权衡误差和性能)
    dispatch_on_thread_monitor_queue(^{
        NSTimeInterval curTS = NSProcessInfo.processInfo.systemUptime;
        if (curTS < self.nextUploadTime) {
            return;
        }
        self.nextUploadTime = curTS + (double)self.config.countAnalysisInterval;
        if(self.config.enableBacktrace) {
            HMDUserExceptionParameter *para = [HMDUserExceptionParameter initAllThreadParameterWithExceptionType:kHMDTHREADCOUNTEXCEPTION customParams:nil filters:nil];
            NSMutableDictionary *filters = [NSMutableDictionary new];
            NSUInteger level = curCount / 50;
            NSString *levelStr = [NSString stringWithFormat:@"%lu~%lu", level * 50, (level + 1) * 50];
            [filters hmd_setObject:levelStr forKey:@"total_thread_level"];
            para.filters = filters;
            
            [[HMDUserExceptionTracker sharedTracker] trackThreadLogWithParameter:para callback:^(NSError * _Nullable error) {
                if (error) {
                    HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[TotalThreadCount] User Exception Error %@.", error);
                }
            }];
        } else {
            HMDThreadMonitorInfo *info = [[HMDThreadMonitorTool shared] getAllThreadInfo];
            if(!info) {
                return ;
            }
            
            NSMutableDictionary *customParams = [NSMutableDictionary new];
            NSString *allThreadString = [HMDThreadMonitorTool stringFromDictionary:info.allThreadDic];
            [customParams hmd_setObject:allThreadString forKey:@"threads_all"];
            [customParams hmd_setObject:@(info.allThreadCount) forKey:@"threads_all_count"];
            [customParams hmd_setObject:info.mostThread forKey:@"most_thread"];
            [customParams hmd_setObject:@(info.mostThreadCount) forKey:@"most_thread_count"];
            
            NSMutableDictionary *filters = [NSMutableDictionary new];
            NSUInteger level = info.allThreadCount / 50;
            NSString *levelStr = [NSString stringWithFormat:@"%lu~%lu", level * 50, (level + 1) * 50];
            [filters hmd_setObject:levelStr forKey:@"total_thread_level"];
            
            HMDUserExceptionParameter *para = [HMDUserExceptionParameter initBaseParameterWithExceptionType:kHMDTHREADCOUNTEXCEPTION
                                                                                                      title:info.mostThread?:@"unknown"
                                                                                                   subTitle:kHMDTHREADCOUNTEXCEPTION
                                                                                               customParams:customParams
                                                                                                    filters:filters];
            [[HMDUserExceptionTracker sharedTracker] trackBaseExceptionWithBacktraceParameter:para callback:^(NSError * _Nullable error) {
                if (error) {
                    HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[TotalThreadCount] User Exception Error %@.", error);
                }
            }];
        }
    });
}

@end
