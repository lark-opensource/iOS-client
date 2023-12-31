//
//  HMDTracingStartTracker.m
//  AFgzipRequestSerializer-iOS13.0
//
//  Created by zhangxiao on 2019/12/23.
//

#import "HMDLaunchTracingTracker.h"
#import "HMDOTTrace.h"
#import "HMDOTSpan.h"
#import "HMDAppLaunchTool.h"
#import "AppStartTracker.h"
#import "HMDOTManager.h"
#import "HMDALogProtocol.h"
#include "HMDAppLaunchTool.h"
#include <stdatomic.h>
#import "NSDictionary+HMDSafe.h"
#include "pthread_extended.h"
#import "NSDate+HMDAccurate.h"
#import "HMDOTTrace+Private.h"

#import "Heimdallr.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

static NSString * const kHMDLaunchTracingServiceName        = @"app_launch_trace";
// launch Span
static NSString * const kHMDLaunchTracingExecToRender       = @"from_exec_to_render";
static NSString * const kHMDLaunchTracingLoadToRender       = @"from_load_to_render";
// sub launch span
static NSString * const kHMDLaunchTracingExecToLoad         = @"from_exec_to_load";
static NSString * const kHMDLaunchTracingLoadToFinishLaunch = @"from_load_to_finishLaunching";
static NSString * const kHMDLaunchTracingFinishLaunchToRender = @"from_finishLaunching_to_render";
static NSNotificationName const kHMDFinishLaunchNotificationName = @"kHMDFinishLaunchNotificationName";

static NSDate *hmdLaunchTrackerLoadDate = nil;

@interface HMDLaunchTracingTracker ()

@property (nonatomic, strong) HMDOTTrace *launchTrace;
/// 优先用业务方传入的，用Heimdallr内部的兜底
@property (atomic, strong) NSDate *accurateLoadDate;
/// app 启动到 最终的渲染结束的时间
@property (nonatomic, strong) HMDOTSpan *appLanuchSpan;
/// app 进程启动到 +(void)load
@property (nonatomic, strong) HMDOTSpan *execToLoadSpan;
/// +(void)load 到 didfinishLaunch
@property (nonatomic, strong) HMDOTSpan *loadToFinishLaunchSpan;
/// didfinishLaunch 到  didfinish 之后的 下一次 runloop
@property (atomic, strong) HMDOTSpan *finishLaunchToRenderSpan;
/// 是否自定义启动耗时的终点
@property (nonatomic, assign, readwrite) BOOL needCustomFinish;
/// 写入模式
@property (nonatomic, assign, readwrite) HMDOTTraceInsertMode insertMode;
///  启动trace是否已经完成
@property (atomic, assign) BOOL isLanuchFinished;
@property (atomic, assign) BOOL isRunning;
@property (nonatomic, strong) NSMutableDictionary *customSpanDict;
@property (nonatomic, strong) dispatch_semaphore_t backgroundLaunchDetermined;
@property (nonatomic, strong) dispatch_queue_t backgroundLaunchWaitingDeteminedQueue;

@end

@implementation HMDLaunchTracingTracker {
    pthread_rwlock_t _spanDictLock;
}

+ (void)load {
    hmdLaunchTrackerLoadDate = [NSDate hmd_accurateDate];
}

+ (instancetype)sharedTracker {
    static HMDLaunchTracingTracker *sharedTracker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTracker = [[HMDLaunchTracingTracker alloc] init];
    });
    return sharedTracker;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        pthread_rwlock_init(&_spanDictLock, NULL);
        self.customSpanDict = [NSMutableDictionary dictionary];
        self.insertMode = HMDOTTraceInsertModeAllSpanBatch;
        self.backgroundLaunchDetermined = dispatch_semaphore_create(0);
        self.backgroundLaunchWaitingDeteminedQueue = dispatch_queue_create("hmd_background_launch_waiting_determined_queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark --- implement superclass method
- (void)start {
    if (!self.isRunning) {
        // 后台启动 直接忽略
        if (![NSThread isMainThread]) {
            NSAssert(NO, @"[HMDLaunchTracingTacker start] must be called on the main thread.");
            return;
        }

        NSTimeInterval moduleStart = 0;
        if (hmd_log_enable()) {
            moduleStart = [[NSDate hmd_accurateDate] timeIntervalSince1970] * 1000;
        } // 记录耗时~
        
        [self setupLaunchTraceOnlyOnce];
        
        if (!self.launchTrace) {
            return;
        }
        self.isRunning = YES; // 采样开关使用 trace 的采样开关
        [self setupLoadAndFinishLaunchSpan]; //初始化
        // 记录是否首次启动
        if (!appStartTrackerEnabled() && self.launchTrace) {
            [self.launchTrace setTag:@"is_first_launch" value:@"1"];
        } else if (appStartTrackerEnabled() && self.launchTrace) {
            [self.launchTrace setTag:@"is_first_launch" value:@"0"];
        }

        // 记录是否是自定义结束阶段
        if (self.needCustomFinish && self.launchTrace) {
            [self.launchTrace setTag:@"is_custom_finish" value:@"1"];
        } else if (!self.needCustomFinish && self.launchTrace) {
            [self.launchTrace setTag:@"is_custom_finish" value:@"0"];
        }

        if (hmd_log_enable()) { //记录耗时 ~
            NSTimeInterval moduleEnd = [[NSDate hmd_accurateDate] timeIntervalSince1970] * 1000;
            NSString *duration = [NSString stringWithFormat:@"Heimdallr HMDLaunchTracingTracker load time:%f ms", moduleEnd - moduleStart];
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"%@", duration);
        }
    }
}

- (void)stop {
    if (self.isRunning) {
        self.isRunning = NO;
    }
}

- (void)setFirstRenderCompletion:(void (^)(void))firstRenderCompletion {
    NSAssert(!self.finishLaunchToRenderSpan.isFinished, @"HMDLaunchTracingTracker render finished. Please set it before render finished");
    NSAssert([NSThread isMainThread], @"This method can only be called on the main thread!");
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
        _firstRenderCompletion = [firstRenderCompletion copy];
        if (self.finishLaunchToRenderSpan.isFinished && _firstRenderCompletion) {
          _firstRenderCompletion();
        }
    } else {
       NSAssert(NO, @"HMDLaunchTracingTracker setFirstRenderCompletion can be used only once!");
       HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDLaunchTracingTracker setFirstRenderCompletion can be used only once!");
    }

}
#pragma mark --- tracing init
- (void)setupLaunchTraceOnlyOnce {
    // 第一次调用该方法 并且 +load 方法没有执行
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if (hermas_enabled()) {
            self.launchTrace = [HMDOTTrace startTrace:kHMDLaunchTracingServiceName];
        } else {
            self.launchTrace = [HMDOTTrace startTrace:kHMDLaunchTracingServiceName startDate:nil insertMode:self.insertMode];
        }

#ifdef DEBUG
        [self.launchTrace ignoreUnfinishedTraceAssert];
#endif
        NSDate *execDate = [[self class] processExecDate];
        self.appLanuchSpan = [HMDOTSpan startSpanOfTrace:self.launchTrace
                                           operationName:kHMDLaunchTracingExecToRender];
        
        if (execDate) {
            //如果exec方法有效，重置trace起点，新增一个exec到load的span
            [self.launchTrace resetTraceStartDate:execDate];
            [self.appLanuchSpan resetSpanStartDate:execDate];
            self.execToLoadSpan = [HMDOTSpan startSpan:kHMDLaunchTracingExecToLoad
                                               childOf:self.appLanuchSpan
                                         spanStartDate:execDate];
        }
    });
}

- (void)setupLoadToFinishTraceOnlyOnceWithLoadDate:(NSDate *)loadDate {
    if (!loadDate) {  return; }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.loadToFinishLaunchSpan = [HMDOTSpan startSpan:kHMDLaunchTracingLoadToFinishLaunch
                                                   childOf:self.appLanuchSpan
                                             spanStartDate:loadDate];
    });
}

- (void)setupLoadAndFinishLaunchSpan {
    NSAssert(self.launchTrace, @"launchTrace cannot be nil");
    if (!self.launchTrace) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDLanuchTracing run while launchTracing is nil!");
        }
        return;
    }
    [self setLoadDateIfNeeded];
    [self setupDidFinishLaunchDate];
    //如果不自定义终点，那么首次渲染完成就是启动耗时的终点
    [self finishStandardLaunchTraceIfNeeded];
}

- (void)setLoadDateIfNeeded {
    //如果已经有外部注入loadDate，则忽略
    if (self.accurateLoadDate) return;
    
    NSAssert(hmdLaunchTrackerLoadDate, @"The start time of loading must be obtained.");
    // 如果拿不到 +load 的时间, 不计算启动 直接返回
    if (!hmdLaunchTrackerLoadDate) { return;}
    NSDate *defaultLoadDate = hmdLaunchTrackerLoadDate;
    // 从 +load 到 finishlaunch 的时间
    [self setupLoadToFinishTraceOnlyOnceWithLoadDate:defaultLoadDate];
    [self updateLoadDateIfNeeded:defaultLoadDate];
}

- (void)setupDidFinishLaunchDate {
    NSDate *currentDate = [NSDate hmd_accurateDate];
    //如果外部没手动finish则在didfinishlaunch这里finish
    if(!self.loadToFinishLaunchSpan.isFinished) {
        [self.loadToFinishLaunchSpan finishWithEndDate:currentDate];
    }
    // 从 finishlaunch 到 render 的时间
    self.finishLaunchToRenderSpan = [HMDOTSpan startSpan:kHMDLaunchTracingFinishLaunchToRender
                                                 childOf:self.appLanuchSpan
                                           spanStartDate:currentDate];
}

- (void)finishStandardLaunchTraceIfNeeded {
    [self observeFirstRenderWithBlock:^{
        [self.finishLaunchToRenderSpan finish];
        if (!self.needCustomFinish) {
            [self finishedTrace];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            dispatch_semaphore_signal(self.backgroundLaunchDetermined);
        });
        void (^tempFirstRenderCompletion)(void) = self.firstRenderCompletion;
        if (tempFirstRenderCompletion) {
            tempFirstRenderCompletion();
        }
    }];
}

- (void)observeFirstRenderWithBlock:(dispatch_block_t)block {
    if(@available(iOS 13.0, *)) {
        CFRunLoopRef mainRunloop = [[NSRunLoop mainRunLoop] getCFRunLoop];
        CFRunLoopActivity activities = kCFRunLoopBeforeTimers;
        CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, activities, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
            if (activity == kCFRunLoopBeforeTimers) {
                CFRunLoopRemoveObserver(mainRunloop, observer, kCFRunLoopCommonModes);
                //CoreFoundation框架中，通过Copy、Retain、Create 创建出来的对象都要主动释放掉
                CFRelease(observer);
                if (block) block();
            }
        });
        CFRunLoopAddObserver(mainRunloop, observer, kCFRunLoopCommonModes);
    } else {
        CFRunLoopRef mainRunloop = [[NSRunLoop mainRunLoop] getCFRunLoop];
        CFRunLoopPerformBlock(mainRunloop,NSDefaultRunLoopMode,block);
    }
}

- (void)customFinish {
    if (!self.needCustomFinish) {
        NSAssert(NO, @"make sure set isUsedCustomerFinish YES when you need custom finish");
        return;
    }
    NSAssert(!self.isLanuchFinished, @"trace has already finished");
    if(self.isLanuchFinished) {
        return;
    }
    [self finishedTrace];
}

- (void)finishedTrace {
    // 从 +load 到 finishlaunch 的时间
    [[NSNotificationCenter defaultCenter] postNotificationName:kHMDFinishLaunchNotificationName object:nil];
    if (!self.launchTrace) { return;}
    [self.appLanuchSpan finish];
    self.isLanuchFinished = YES;
    NSDate *finishDate = [NSDate date];
    if (UIApplication.sharedApplication.applicationState != UIApplicationStateBackground) {
        [self.launchTrace finish];
    }
    else {
        static atomic_flag onceToken = ATOMIC_FLAG_INIT;
        if(atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) return;
        dispatch_async(self.backgroundLaunchWaitingDeteminedQueue, ^{
            dispatch_semaphore_wait(self.backgroundLaunchDetermined, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)));
            dispatch_async(dispatch_get_main_queue(), ^{
                if (UIApplication.sharedApplication.applicationState != UIApplicationStateBackground) {
                    [self.launchTrace finishWithDate:finishDate];
                }
                else {
                    [self.launchTrace abandonCurrentTrace];
                }
            });
        });
    }
}

#pragma mark --- public method
- (void)startWithCustomFinish:(BOOL)needCustomFinish  {
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
        self.needCustomFinish = needCustomFinish;
        [self start];
    } else {
        NSAssert(NO, @"HMDLaunchTracingTracker can be started only once!");
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDLaunchTracingTracker can be started only once!");
    }
}

- (HMDOTSpan * _Nullable)loadToDidFinishLaunchSpan {
    [self setupLaunchTraceOnlyOnce];
    if(!self.launchTrace) return nil;

    [self setupLoadToFinishTraceOnlyOnceWithLoadDate:hmdLaunchTrackerLoadDate];
    [self updateLoadDateIfNeeded:hmdLaunchTrackerLoadDate];
    
    return self.loadToFinishLaunchSpan;
}

- (void)resetLoadDate:(NSDate *_Nullable)loadDate {
    [self setupLaunchTraceOnlyOnce];
    NSAssert(self.launchTrace, @"launchTrace cannot be nil");
    NSAssert(self.appLanuchSpan, @"appLanuchSpan cannot be nil");
    [self setupLoadToFinishTraceOnlyOnceWithLoadDate:loadDate];
    [self updateLoadDateIfNeeded:loadDate];
}

- (HMDOTSpan * _Nullable)didFinishLaunchToRenderSpan {
    if(!self.isRunning || !self.launchTrace) return nil;

    HMDOTSpan *finishToRenderSpan = self.finishLaunchToRenderSpan;

    return finishToRenderSpan;
}

- (HMDOTSpan * _Nullable)addRootSpanAfterFirstRenderWithName:(NSString *)spanName {
    NSAssert(!self.isLanuchFinished, @"please call this method before trace finish");

    if (!self.isRunning || !self.launchTrace || self.isLanuchFinished) {
        return nil;
    }

    HMDOTSpan *rootSpan = [HMDOTSpan startSpan:spanName childOf:self.appLanuchSpan];
    pthread_rwlock_wrlock(&_spanDictLock);
    [self.customSpanDict hmd_setSafeObject:rootSpan forKey:spanName];
    pthread_rwlock_unlock(&_spanDictLock);
    
    return rootSpan;
}

- (void)updateLoadDateIfNeeded:(NSDate *)loadDate {
    NSAssert(loadDate, @"loadDate must be valid");
    NSAssert(self.launchTrace, @"launchTrace cannot be nil");
    NSAssert(!self.isLanuchFinished, @"please call this method before trace finish");
    if (!loadDate || !self.launchTrace || self.isLanuchFinished) return;
    
    //只有accurateLoadDate首次设置
    if (!self.accurateLoadDate) {
        [self updateAccurateLoadDate:loadDate];
    }
}

- (void)updateAccurateLoadDate:(NSDate *)loadDate {
    self.accurateLoadDate = loadDate;
    NSDate *execDate = [[self class] processExecDate];
    //if execDate is invalid,use loadDate instead
    if (!execDate) {
        [self.launchTrace resetTraceStartDate:loadDate];
        [self.appLanuchSpan resetSpanStartDate:loadDate];
    }
    //if exectoload valid,finish it
    HMDPrewarmSpan isPrewarmFlag = isPrewarm();
    [self.launchTrace setTag:@"is_prewarm" value:(isPrewarmFlag != HMDPrewarmNone) ? @"1" : @"0"];
    if (isPrewarmFlag == HMDPrewarmLoadToDidFinishLaunching) {
        if (self.launchTrace) {
            [self.launchTrace resetTraceStartDate:HMDWillFinishLaunchingAccurateDate];
        }
        if (self.appLanuchSpan){
            [self.appLanuchSpan resetSpanStartDate:HMDWillFinishLaunchingAccurateDate];
        }
        if (self.execToLoadSpan) {
            [self.execToLoadSpan resetSpanStartDate:HMDWillFinishLaunchingAccurateDate];
            [self.execToLoadSpan finishWithEndDate:HMDWillFinishLaunchingAccurateDate];
        }
        if (self.loadToFinishLaunchSpan) {
            [self.loadToFinishLaunchSpan resetSpanStartDate:HMDWillFinishLaunchingAccurateDate];
        }
    } else if (isPrewarmFlag == HMDPrewarmExecToLoad) {
        if (self.launchTrace) {
            [self.launchTrace resetTraceStartDate:loadDate];
        }
        if (self.appLanuchSpan){
            [self.appLanuchSpan resetSpanStartDate:loadDate];
        }
        if (self.execToLoadSpan) {
            [self.execToLoadSpan resetSpanStartDate:loadDate];
        }
    }
    if (self.execToLoadSpan) {
        [self.execToLoadSpan finishWithEndDate:loadDate];
    }
}

- (void)addFilterTag:(NSString * _Nonnull)tagName value:(id _Nonnull)value {
    NSAssert(self.launchTrace, @"launchTrace cannot be nil");
    NSAssert(!self.isLanuchFinished, @"please call this method before trace finish");
    if (!self.launchTrace || self.isLanuchFinished) return;
    
    [self.launchTrace setTag:tagName value:value];
}

- (HMDOTSpan * _Nullable)fetchCustomRootSpanWithOperationName:(NSString *)operationName {
    HMDOTSpan *span = nil;
    if (self.isRunning && self.launchTrace && operationName) {
        pthread_rwlock_rdlock(&_spanDictLock);
        span = [self.customSpanDict valueForKey:operationName];
        pthread_rwlock_unlock(&_spanDictLock);
    }
    return span;
}

#pragma mark helper

+ (NSDate *)processExecDate {
    static NSDate *execDate = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        long long execTime = hmdTimeWithProcessExec();
        if (execTime > 0) {
            //这里分母必须是浮点数，否则精度会丢失，不准确
            execDate = [NSDate dateWithTimeIntervalSince1970:(execTime / 1000.0)];
        }
    });
    
    return execDate;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
