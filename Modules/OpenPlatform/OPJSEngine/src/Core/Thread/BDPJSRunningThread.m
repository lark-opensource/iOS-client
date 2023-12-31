//
//  BDPJSRunningThread.m
//  Timor
//
//  Created by dingruoshan on 2019/6/14.
//

#import "BDPJSRunningThread.h"
//#import "BDPUtils.h"
#import <ECOInfra/BDPLog.h>
#import "OPJSEngineMacroUtils.h"
#import <ECOInfra/OPMacroUtils.h>

#import <OPJSEngine/OPJSEngine-Swift.h>
#include <mach/mach_types.h>
#import <pthread.h>
#include <mach/mach.h>
#if PL_MACH64_EXC_API
#import "mach_exc.h"

typedef __Request__mach_exception_raise_t BDPRequest_exception_raise_t;
typedef __Reply__mach_exception_raise_t BDPReply_exception_raise_t;
#else
typedef __Request__exception_raise_t BDPRequest_exception_raise_t;
typedef __Reply__exception_raise_t BDPReply_exception_raise_t;
#endif

#define kProtectCrashReportTypeBadAccess @"MP_JSC_Crash EXC_BAD_ACCESS"
#define kProtectCrashReportTypeBreakPoint @"MP_JSC_Crash EXC_BREAKPOINT"
#define kProtectCrashReportTypeBadInstruction @"MP_JSC_Crash EXC_BAD_INSTRUCTION"
#define kProtectCrashReportTypeNSException @"MP_JSC_Crash NSException"

static BOOL gBDPEnableJSThreadProtect = YES;
static BDPJSThreadCrashHandler gBDPJSThreadCrashHandler = nil;

@interface BDPJSRunningThread ()
{
    dispatch_group_t _waitGroupStart;
    dispatch_group_t _waitGroupStop;
    BOOL _stopFlag;
    BOOL _isRunning;
}

@end

// 全局port，用于接收异常signal，做线程崩溃兜底
static mach_port_name_t gExceptionPort;
static BOOL gIsExceptionPortCreated = NO;
static void *exc_handler(void *ignore); // 看门狗线程执行函数,在这里拦住EXC_BREAKPOINT不做处理，从而防止crash
static NSMapTable<NSNumber*,BDPJSRunningThread*>* gThreadMap = nil; // 全局thread对象。
static dispatch_semaphore_t threadCreateSemaphore;
// 建立一个看门狗线程，拦住JSC的EXC_BREAKPOINT异常
static void createExceptionHandler() {
    if (gIsExceptionPortCreated) {
        return;
    }
    
    
    if (gBDPEnableJSThreadProtect) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            gThreadMap = [NSMapTable strongToWeakObjectsMapTable];
            
            gIsExceptionPortCreated = YES;
            
            kern_return_t rc = 0;
            
            rc = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &gExceptionPort);
            if (rc != KERN_SUCCESS) {
                BDPLogError(@"[BDPJSRunningThread] Fail to allocate exception port");
                return;
            }
            
            rc = mach_port_insert_right(mach_task_self(), gExceptionPort, gExceptionPort, MACH_MSG_TYPE_MAKE_SEND);
            if (rc != KERN_SUCCESS) {
                BDPLogError(@"[BDPJSRunningThread] Fail to insert right");
                return;
            }
            
            // 看门狗线程，用于处理signal异常
            threadCreateSemaphore = dispatch_semaphore_create(0);
            pthread_t thread;
            pthread_create(&thread, NULL, exc_handler, nil);
            dispatch_semaphore_wait(threadCreateSemaphore, DISPATCH_TIME_FOREVER);
        });
    }
    else {
        // debug 状态下不保护
        return;
    }
}

static void *exc_handler(void *ignore) {
    pthread_setname_np("com.bytedance.bdpjscontext.jsrunningthread_protector");
    
    // Exception handler – runs a message loop. Refactored into a standalone function
    // so as to allow easy insertion into a thread (can be in same program or different)
    mach_msg_return_t rc;
    dispatch_semaphore_signal(threadCreateSemaphore);
    
    BDPRequest_exception_raise_t *request = NULL;
    size_t request_size;
    kern_return_t kr;
    
    /* Initialize the received message with a default size */
    request_size = round_page(sizeof(*request));
    kr = vm_allocate(mach_task_self(), (vm_address_t *) &request, request_size, VM_FLAGS_ANYWHERE);
    request->Head.msgh_size = (mach_msg_size_t)request_size;
    
    while(YES) {
        // Message Loop: Block indefinitely until we get a message, which has to be
        // 这里会阻塞，直到接收到exception message，或者线程被中断。
        // an exception message (nothing else arrives on an exception port)
        rc = mach_msg( &request->Head,
                      MACH_RCV_MSG,
                      0,
                      (mach_msg_size_t)request_size,
                      gExceptionPort, // Remember this was global – that's why.
                      MACH_MSG_TIMEOUT_NONE,
                      MACH_PORT_NULL);
        
        if(rc != MACH_MSG_SUCCESS) {
            BDPLogError(@"[mach_msg] GOT faild msg rc=%@",@(rc));
            continue ;
        };
        
        
        // Normally we would call exc_server or other. In this example, however, we wish
        // to demonstrate the message contents:
        
        //printf("Got message %d. Exception : %d Flavor: %d. Code %d/%d. State count is %d\\\\\\\\n" ,
        //       exc.Head.msgh_id, exc.exception, exc.flavor,
        //       exc.code[0], exc.code[1], // can also print as 64-bit quantity
        //       exc.old_stateCnt);
        
        BDPLogError(@"[mach_msg] GOT msg exception=%@",@(request->exception));
        printf("[mach_msg] GOT msg exception=%d\n",request->exception);
        if (gBDPEnableJSThreadProtect) {
            // 这里兜住了，上报到自定义crash并关闭实例
            if (request->exception == EXC_BREAKPOINT
                || request->exception == EXC_BAD_ACCESS
                || request->exception == EXC_BAD_INSTRUCTION) {
                NSNumber* threadKey = @(request->thread.name);
                BDPJSRunningThread* thread = [gThreadMap objectForKey:threadKey];
                // 崩溃上报
                NSString* crashType = kProtectCrashReportTypeBadAccess;
                if (request->exception == EXC_BREAKPOINT) {
                    crashType = kProtectCrashReportTypeBreakPoint;
                }
                if (request->exception == EXC_BAD_INSTRUCTION) {
                    crashType = kProtectCrashReportTypeBadInstruction;
                }
                if (gBDPJSThreadCrashHandler != nil) {
                    gBDPJSThreadCrashHandler(crashType, thread.threadId, 0, nil, nil, nil);
                }
                // 结束已经崩溃的线程
                if (thread) {
                    [[[OPJSEngineService shared] utils] executeOnMainQueue:^{
                        [thread forceStopThread:crashType];
                    }];
//                    BDPExecuteOnMainQueue(^{
//                        [thread forceStopThread:crashType];
//                    });
                }
            }
        }
        else {
            // 没兜住，给系统给一个反馈，该断点断点，该crash就crash
            BDPReply_exception_raise_t reply;
            /* Initialize the reply */
            memset(&reply, 0, sizeof(reply));
            reply.Head.msgh_bits = MACH_MSGH_BITS(MACH_MSGH_BITS_REMOTE(request->Head.msgh_bits), 0);
            reply.Head.msgh_local_port = MACH_PORT_NULL;
            reply.Head.msgh_remote_port = request->Head.msgh_remote_port;
            reply.Head.msgh_size = sizeof(reply);
            reply.NDR = request->NDR;
            reply.RetCode = KERN_SUCCESS;
            
            /*
             * Mach uses reply id offsets of 100. This is rather arbitrary, and in theory could be changed
             * in a future iOS release (although, it has stayed constant for nearly 24 years, so it seems unlikely
             * to change now). See the top-level file warning regarding use on iOS.
             *
             * On Mac OS X, the reply_id offset may be considered implicitly defined due to mach_exc.defs and
             * exc.defs being public.
             */
            reply.Head.msgh_id = request->Head.msgh_id + 100;
            mach_msg(&reply.Head,
                     MACH_SEND_MSG,
                     reply.Head.msgh_size,
                     0,
                     MACH_PORT_NULL,
                     MACH_MSG_TIMEOUT_NONE,
                     MACH_PORT_NULL);
        }
        
        continue;
    }
    
    return  NULL;
} // end exc_handler

@implementation BDPJSRunningThread

static volatile int32_t gRunningThreadCount = 0;
static NSLock* gRunningThreadCountLock = nil;

- (instancetype)initWithName:(NSString*)threadName
{
    self = [super init];
    if (self) {
        self.name = threadName;
        [self _initSelf];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self _initSelf];
    }
    return self;
}

- (void)_initSelf
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gRunningThreadCountLock = [[NSLock alloc] init];
    });
    
    _waitGroupStart = dispatch_group_create();
    _waitGroupStop = dispatch_group_create();
    dispatch_group_enter(_waitGroupStart);
    
    createExceptionHandler();
    
    OPDebugNSLog(@"[JSAsync Debug] BDPJSRunningThread init %@",@([self hash]));
}

- (void)main
{
    @autoreleasepool {
        // 计数器+1
        [gRunningThreadCountLock lock];
        gRunningThreadCount++;
        [gRunningThreadCountLock unlock];
        
        
        if (gBDPEnableJSThreadProtect) {
            // 设置该线程的signal处理，防止jsc自己内存分配失败导致的crash，进行兜底，可能导致内存泄漏等其他问题，但好过直接crash，debug版本还是直接crash：https://slardar.bytedance.net/node/app_detail/?aid=13&os=iOS&region=cn#/abnormal/detail/crash/13_fcb7f147a89749cd522e80d3339e2788?params=%7B%0A++%22start_time%22%3A+1556359200%2C%0A++%22end_time%22%3A+1556445600%2C%0A++%22filters%22%3A+%7B%0A++++%22update_version_code%22%3A+null%2C%0A++++%22os_version%22%3A+%5B%5D%2C%0A++++%22device_model%22%3A+%5B%5D%0A++%7D%0A%7D
            kern_return_t rc = 0;
            exception_mask_t excMask = EXC_MASK_BREAKPOINT|EXC_MASK_BAD_ACCESS|EXC_MASK_BAD_INSTRUCTION;
            
            thread_act_t this_mach_thread = mach_thread_self();
            rc = thread_set_exception_ports(this_mach_thread, excMask, gExceptionPort, EXCEPTION_DEFAULT, MACHINE_THREAD_STATE);
            if (rc != KERN_SUCCESS) {
                BDPLogError(@"[BDPJSRunningThread] Fail to insert right");
            }
            [gThreadMap setObject:self forKey:@(this_mach_thread)];
            self.threadId = this_mach_thread;
        }
        else {
            // debug 状态下不保护
        }
        
        // 线程主体
        dispatch_group_leave(_waitGroupStart);
        
        while (!_stopFlag) {
            @autoreleasepool {
                self.weakRunLoop = [NSRunLoop currentRunLoop];
                if (gBDPEnableJSThreadProtect) {
                    @try {
                        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
                    }
                    @catch (NSException *exception) {
                        // 崩溃上报
                        NSString* expName = exception.name;
                        if (expName == nil) {
                            expName = @"";
                        }
                        NSArray* callStack = [exception callStackSymbols];
                        if (callStack == nil) {
                            callStack = @[];
                        }
                        _forceStopped = YES;
                        if (gBDPJSThreadCrashHandler != nil) {
                            gBDPJSThreadCrashHandler(kProtectCrashReportTypeNSException, self.threadId, 0, @{@"Name":expName,@"CallStack":callStack}, nil, nil);
                        }
                        // 已崩溃，结束当前线程
                        WeakSelf;
                        [[[OPJSEngineService shared] utils] executeOnMainQueue:^{
                            StrongSelfIfNilReturn;
                            [self _callbackDelegateForceStopped:exception.description];
                        }];
//                        BDPExecuteOnMainQueue(^{
//                            StrongSelfIfNilReturn;
//                            [self _callbackDelegateForceStopped:exception.description];
//                        });
                        break;
                    }
                }
                else {
                    // debug 状态不保护
                    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
                    
                }
            }
        }
        
        @autoreleasepool {
            _jsContext = nil;
            _jsVM = nil;
        }
        
        _isRunning = NO;
        if (!_forceStopped) {
            dispatch_group_leave(_waitGroupStop);
        }
        
        // 计数器-1
        [gRunningThreadCountLock lock];
        gRunningThreadCount--;
        [gRunningThreadCountLock unlock];
    }
}

- (void)_waitUntilStarted
{
    dispatch_group_wait(_waitGroupStart, DISPATCH_TIME_FOREVER);
}

- (void)_waitUntilStoped
{
    dispatch_group_wait(_waitGroupStop, DISPATCH_TIME_FOREVER);
}

- (void)startThread:(BOOL)waitUntilStarted
{
    if (_isRunning) {
        return;
    }
    _isRunning = YES;
    _stopFlag = NO;
    [self start];
    if (waitUntilStarted) {
        [self _waitUntilStarted];
    }
}
- (void)stopThread:(BOOL)waitUntilDone
{
    if (!_isRunning || _stopFlag || _forceStopped) {
        return;
    }
    dispatch_group_enter(_waitGroupStop);
    _stopFlag = YES;
    if (waitUntilDone) {
        [self _waitUntilStoped];
    }
}

- (void)dealloc
{
    [self stopThread:YES];
    
    OPDebugNSLog(@"[JSAsync Debug] BDPJSRunningThread dealloc %@",@([self hash]));
}

- (BOOL)isRunning
{
    return _isRunning;
}

- (NSRunLoop *)runLoop
{
    return self.weakRunLoop;
}

- (void)forceStopThread:(NSString * _Nullable)exceptionMsg
{
    _forceStopped = YES;
    if (_threadId != 0) {
        thread_terminate(_threadId);
    }
    _jsContext = nil;
    _jsVM = nil;
    [self _callbackDelegateForceStopped:exceptionMsg];
}

+ (NSInteger)runningThreadCount
{
    return (NSInteger)gRunningThreadCount;
}

+ (void)enableThreadProtection:(BOOL)enabled
{
    gBDPEnableJSThreadProtect = enabled;
}

+ (BOOL)isThreadProtectionEnabled
{
    return gBDPEnableJSThreadProtect;
}

+ (void)setCrashHandler:(BDPJSThreadCrashHandler)handler
{
    gBDPJSThreadCrashHandler = handler;
}

#pragma mark Private Methods
- (void)_callbackDelegateForceStopped:(NSString * _Nullable)exceptionMsg
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onBDPJSRunningThreadForceStopped:exceptionMsg:)]) {
        [self.delegate onBDPJSRunningThreadForceStopped:self exceptionMsg:exceptionMsg];
    }
}

@end
