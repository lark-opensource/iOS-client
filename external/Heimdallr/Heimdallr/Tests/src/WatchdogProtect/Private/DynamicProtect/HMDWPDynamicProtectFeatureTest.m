//
//  HMDWPDynamicProtectFeatureTest.m
//  HMDWPDynamicProtectFeatureTest
//
//  Created by sunrunwang on anytime
//  Copyright © 2020 bytedance. All rights reserved.
//

#include <stdatomic.h>
#include <mach/machine/vm_param.h>
#include <pthread.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDDynamicCall.h"
#import "HMDSwizzle.h"
#import "HMDWatchdogProtectManager.h"
#import "HMDWatchdogProtectManager+Private.h"
#import "HMDTimeSepc.h"
#import "HMDWPCapture.h"
#include <dlfcn.h>
#import "HMDMacro.h"

#ifndef NSEC_PER_SEC
#define NSEC_PER_SEC 1000000000ull
#endif

extern bool HMDWPDispatchWorkItemEnabled;

static BOOL mockAtomicInfoZero = NO;

static NSTimeInterval globalSubThreadSuspendTime = 0.0;

static BOOL featureTestBegin = NO;

static BOOL stopAsyncProtection = NO;

struct timespec CFTimeInterval_to_timespec(CFTimeInterval interval);

static id<HMDWatchdogProtectDetectProtocol> savedDelegate;

@interface HMDWPDynamicProtectFeatureTest : XCTestCase

@end

@interface HMDWatchdogProtectManager (instance)

@property(class, readonly, nonnull) __kindof HMDWatchdogProtectManager *sharedInstance;

@end

typedef void(^HMDWPExceptionCallback)(HMDWPCapture *capture);

@implementation HMDWPDynamicProtectFeatureTest

+ (void)setUp {
    featureTestBegin = YES;
    
    HMD_mockClassTreeForClassMethod(HeimdallrUtilities, canFindDebuggerAttached, ^(Class aClass){return NO;});
    HMD_mockClassTreeForInstanceMethod(HMDInjectedInfo, appID, ^(id thisSelf){ return @"10086";});
    
    HMD_mockClassTreeForClassMethod(HMDWPUtility, protectSyncWaitTime:exceptionTimeout:exceptionCallback:protectBlock:skippedDepth:waitFlag:protectSelectorBlock:,
                                    ^(Class thisClass, NSTimeInterval syncWaitTime, NSTimeInterval exceptionTimeout, HMDWPExceptionCallback callback, dispatch_block_t block, NSUInteger skippedDepth, atomic_flag * _Nullable waitFlag, NSString*(^protectSelectorBlock)(void)) {
        if(featureTestBegin) block = [HMDWPDynamicProtectFeatureTest watchdogDispatchAsyncCalledWithBlock:block];
        
        ((void(*)(id, SEL, NSTimeInterval, NSTimeInterval, HMDWPExceptionCallback, dispatch_block_t, NSUInteger, atomic_flag *, NSString*(^)(void)))objc_msgSend)
        (thisClass, sel_registerName("MOCK_protectSyncWaitTime:exceptionTimeout:exceptionCallback:protectBlock:skippedDepth:waitFlag:protectSelectorBlock:"),
         syncWaitTime, exceptionTimeout, callback, block, skippedDepth, waitFlag, protectSelectorBlock);
        
    });
    
    
//    @interface StingerParams : NSObject <StingerParams>
//
//    - (instancetype)initWithType:(NSString *)types
//                     originalIMP:(IMP)imp
//                             sel:(SEL)sel
//                            args:(void **)args
//                   argumentTypes:(NSArray *)argumentTypes NS_DESIGNATED_INITIALIZER;
//
//    - (void)preGenerateInvocationIfNeed;
    
    Class stingerClass = objc_getClass("StingerParams");
    if(stingerClass != nil) {
        if(hmd_classHasInstanceMethod(stingerClass, sel_registerName("preGenerateInvocationIfNeed"))) {
            HMD_mockClassTreeForInstanceMethod(StingerParams, preGenerateInvocationIfNeed, ^(id thisSelf) {
                if(stopAsyncProtection) return;
                DC_OB(thisSelf, MOCK_preGenerateInvocationIfNeed);
            });
        }
    }
    
    HMD_mockClassTreeForInstanceMethod(HMDWPDynamicSafeData, atomicInfo, ^ uint64_t(id thisSelf) {
        if(mockAtomicInfoZero) return 0;
        return DC_IS(DC_OB(thisSelf, MOCK_atomicInfo), NSNumber).unsignedLongValue;
    });
    
    [HMDWatchdogProtectManager.sharedInstance
     setDynamicProtectOnMainThread:
         @[@"+[HMDWPDynamicProtectFeatureTest mainThreadProtectedMethod]"
          ]
     onAnyThread:
         @[@"+[HMDWPDynamicProtectFeatureTest anyThreadProtectedMethod]",
           @"+[HMDWPDynamicProtectFeatureTest stackWiredTestMethod]"
          ]
    ];
    HMDWPDispatchWorkItemEnabled = YES;
}

+ (void)tearDown {
    featureTestBegin = NO;
    mockAtomicInfoZero = NO;
    globalSubThreadSuspendTime = 0.0;
}

+ (void)wireStackMemory { // 把栈给写得乱七八糟
    size_t size = 512;
    uint32_t *stackMemory = __builtin_alloca(sizeof(uint32_t) * size);
    uint32_t wiredValue = arc4random();
    for(size_t index = 0; index < size; index++) stackMemory[index] = wiredValue;
}

- (void)setUp {
    HMDWPDispatchWorkItemEnabled = YES;
    savedDelegate = HMDWatchdogProtectManager.sharedInstance.delegate;
    HMDWatchdogProtectManager.sharedInstance.delegate = (id<HMDWatchdogProtectDetectProtocol>)self;
}

- (void)tearDown {
    HMDWatchdogProtectManager.sharedInstance.delegate = savedDelegate;
    savedDelegate = nil;
}

- (void)didProtectWatchdogWithCapture:(HMDWPCapture *)capture {}

#pragma mark - timeout SubThread Operation Failed

- (void)test_timeoutSubThreadOperationFailed {
    [self internalTest_timeoutSubThreadOperationFailed_protectorTimeout:2
                                                   subThreadSuspendTime:3
                                                   callMainThreadMethod:YES
                                                     calledOnMainThread:YES
                                                operationShouldHappened:NO];
}

- (void)test_timeoutSubThreadOperationFailed2 {
    [self internalTest_timeoutSubThreadOperationFailed_protectorTimeout:2
                                                   subThreadSuspendTime:3
                                                   callMainThreadMethod:YES
                                                     calledOnMainThread:NO
                                                operationShouldHappened:YES];
}


- (void)test_timeoutSubThreadOperationFailed3 {
    [self internalTest_timeoutSubThreadOperationFailed_protectorTimeout:2
                                                   subThreadSuspendTime:3
                                                   callMainThreadMethod:NO
                                                     calledOnMainThread:YES
                                                operationShouldHappened:NO];
}

- (void)test_timeoutSubThreadOperationFailed4 {
    [self internalTest_timeoutSubThreadOperationFailed_protectorTimeout:2
                                                   subThreadSuspendTime:3
                                                   callMainThreadMethod:NO
                                                     calledOnMainThread:NO
                                                operationShouldHappened:NO];
}

- (void)test_timeoutSubThreadOperationFailed5 {
    [self internalTest_timeoutSubThreadOperationFailed_protectorTimeout:3
                                                   subThreadSuspendTime:2
                                                   callMainThreadMethod:YES
                                                     calledOnMainThread:YES
                                                operationShouldHappened:YES];
}

- (void)test_timeoutSubThreadOperationFailed6 {
    [self internalTest_timeoutSubThreadOperationFailed_protectorTimeout:3
                                                   subThreadSuspendTime:2
                                                   callMainThreadMethod:YES
                                                     calledOnMainThread:NO
                                                operationShouldHappened:YES];
}

- (void)test_timeoutSubThreadOperationFailed7 {
    [self internalTest_timeoutSubThreadOperationFailed_protectorTimeout:3
                                                   subThreadSuspendTime:2
                                                   callMainThreadMethod:NO
                                                     calledOnMainThread:YES
                                                operationShouldHappened:YES];
}

- (void)test_timeoutSubThreadOperationFailed8 {
    [self internalTest_timeoutSubThreadOperationFailed_protectorTimeout:3
                                                   subThreadSuspendTime:2
                                                   callMainThreadMethod:NO
                                                     calledOnMainThread:NO
                                                operationShouldHappened:YES];
}

BOOL static stackWiredTestMethodSafelyCalled = NO;

- (void)test_callerReturnAndStackWired {
    // 注释掉这行会崩溃 => 符合预期
    // stopAsyncProtection = YES;
    mockAtomicInfoZero = YES;
    stackWiredTestMethodSafelyCalled = NO;
    globalSubThreadSuspendTime = 3.0;
    HMDWatchdogProtectManager.sharedInstance.timeoutInterval = 1.0;
    [HMDWPDynamicProtectFeatureTest stackWiredTestMethod_basic0];
    [HMDWPDynamicProtectFeatureTest wireStackMemory];
    struct timespec sleepTime = CFTimeInterval_to_timespec(3.0);
    nanosleep(&sleepTime, NULL);
    XCTAssert(stackWiredTestMethodSafelyCalled);
    mockAtomicInfoZero = NO;
}

+ (void)stackWiredTestMethod_basic0 {
    [HMDWPDynamicProtectFeatureTest stackWiredTestMethod_basic1];
}

+ (void)stackWiredTestMethod_basic1 {
    [HMDWPDynamicProtectFeatureTest stackWiredTestMethod_basic2];
}

+ (void)stackWiredTestMethod_basic2 {
    [HMDWPDynamicProtectFeatureTest stackWiredTestMethod];
}

+ (void)stackWiredTestMethod {
    stackWiredTestMethodSafelyCalled = YES;
}

static BOOL operationSuccess = NO;

- (void)internalTest_timeoutSubThreadOperationFailed_protectorTimeout:(NSTimeInterval)protectorTimeout
                                                 subThreadSuspendTime:(NSTimeInterval)subThreadSuspendTime
                                                 callMainThreadMethod:(BOOL)callMainThreadMethod
                                                   calledOnMainThread:(BOOL)calledOnMainThread
                                              operationShouldHappened:(BOOL)operationShouldHappened {
    HMDWatchdogProtectManager.sharedInstance.timeoutInterval = protectorTimeout;
    globalSubThreadSuspendTime = subThreadSuspendTime;
    operationSuccess = NO;
    
    BOOL callShouldWork;
    if(callMainThreadMethod) {
        if(calledOnMainThread) {
            if(protectorTimeout < subThreadSuspendTime) {
                callShouldWork = NO;
            } else {
                callShouldWork = YES;
            }
        } else {
            // it is not protected for mainMethod not on mainThread
            callShouldWork = YES;
        }
    } else {
        if(protectorTimeout < subThreadSuspendTime) {
            callShouldWork = NO;
        } else {
            callShouldWork = YES;
        }
    }
    
    XCTAssert(callShouldWork == operationShouldHappened);
    
    dispatch_block_t operation = ^{
        if(callMainThreadMethod) [HMDWPDynamicProtectFeatureTest mainThreadProtectedMethod];
        else [HMDWPDynamicProtectFeatureTest anyThreadProtectedMethod];
    };
    
    BOOL syncCalled = NO;
    
    if(calledOnMainThread) {
        if(pthread_main_np()) {
            syncCalled = YES;
            operation();
        } else dispatch_async(dispatch_get_main_queue(), operation);
    } else dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), operation);
    
    if(syncCalled) {
        struct timespec sleepTime = CFTimeInterval_to_timespec(1.0);
        nanosleep(&sleepTime, NULL);
        if(callShouldWork) XCTAssert(operationSuccess);
        else XCTAssert(!operationSuccess);
    } else {
        struct timespec sleepTime = CFTimeInterval_to_timespec(globalSubThreadSuspendTime + 1.0);
        nanosleep(&sleepTime, NULL);
        if(callShouldWork) XCTAssert(operationSuccess);
        else XCTAssert(!operationSuccess);
    }
}

+ (void)mainThreadProtectedMethod {
    operationSuccess = YES;
}

+ (void)anyThreadProtectedMethod {
    operationSuccess = YES;
}

+ (dispatch_block_t)watchdogDispatchAsyncCalledWithBlock:(dispatch_block_t)block {
    if(globalSubThreadSuspendTime > 0.0) {
        dispatch_block_t anotherBlock = ^{
            struct timespec sleepTime = CFTimeInterval_to_timespec(globalSubThreadSuspendTime);
            nanosleep(&sleepTime, NULL);
            block();
        };
        block = anotherBlock;
    }
    return block;
}

@end

struct timespec CFTimeInterval_to_timespec(CFTimeInterval interval) {
    double sec;
    double frac = modf(interval, &sec);
    return (struct timespec){.tv_sec = sec, .tv_nsec = frac * NSEC_PER_SEC};
}
