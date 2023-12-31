//
//  HeimdallrDemoTests.m
//  HeimdallrDemoTests
//
//  Created by bytedance on 2020/8/4.
//  Copyright © 2020 bytedance. All rights reserved.
//

#include <mach/machine/vm_param.h>
//#include <mach/arm/vm_param.h>
#include <pthread.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDDynamicCall.h"
#import "HMDSwizzle.h"
#import "HMDWatchdogProtectManager.h"
#import "HMDWatchdogProtectManager+Private.h"
#import "HMDTimeSepc.h"
#import "HMDWPCapture.h"

@interface NSThread (DetachThreadWithBlock)
+ (void)MY_detachNewThreadWithBlock:(void (^)(void))block;
@end

@implementation NSThread (DetachThreadWithBlock)

+ (void)MY_detachNewThreadWithBlock:(void (^)(void))block {
    [NSThread detachNewThreadSelector:@selector(MY_performBlock:) toTarget:NSThread.class withObject:block];
}

+ (void)MY_performBlock:(void (^)(void))block {
    if(block != nil) block();
}

@end

static id<HMDWatchdogProtectDetectProtocol> savedDelegate;

@interface HMDWatchdogProtectManager (instance)
@property(class, readonly, nonnull) __kindof HMDWatchdogProtectManager *sharedInstance;
@end

@interface HMDWatchdogProtectManagerTest : XCTestCase <HMDWatchdogProtectDetectProtocol>

@end

@implementation HMDWatchdogProtectManagerTest

+ (void)setUp {
    HMD_mockClassTreeForClassMethod(HeimdallrUtilities, canFindDebuggerAttached, ^(Class aClass){return NO;});
    HMD_mockClassTreeForInstanceMethod(HMDInjectedInfo, appID, ^(id thisSelf){ return @"10086";});
    
    [HMDWatchdogProtectManager.sharedInstance
     setDynamicProtectOnMainThread:
         @[@"-[HMDWatchdogProtectManagerTest sleepLongFor20seconds_protectLevelOnlyMain]",
           @"-[HMDWatchdogProtectManagerTest sleepForOnly1Seconds_protectLevelOnlyMain]",
           @"-[HMDWatchdogProtectManagerTest sleepLongFor5seconds_protectLevelOnlyMain]",
           @"-[Chaos Chaos]",       // 测试传入奇怪的东西
           @"123456789",
          ]
     onAnyThread:
         @[@"-[HMDWatchdogProtectManagerTest sleepLongFor20seconds_protectLevelAny]",
           @"-[HMDWatchdogProtectManagerTest sleepForOnly1Seconds_protectLevelAny]",
           @"-[HMDWatchdogProtectManagerTest notExist]",
           @"-[HMDWatchdogProtectManagerTest not exist]",
           @"-[HMDWatchdogProtectManagerTest 泪大目]",
          ]
    ];
}

- (void)setUp {
    savedDelegate = HMDWatchdogProtectManager.sharedInstance.delegate;
    HMDWatchdogProtectManager.sharedInstance.delegate = self;
}

- (void)tearDown {
    HMDWatchdogProtectManager.sharedInstance.delegate = savedDelegate;
    savedDelegate = nil;
}

- (void)didProtectWatchdogWithCapture:(HMDWPCapture *)capture {}

#pragma mark - protect Level main Thread

- (void)testDynamicProtect_protectLevel_mainThread1 {
    [self dispatchSyncOnMainThreadAndTestWithTimeout:1.5];
}

- (void)testDynamicProtect_protectLevel_mainThread2 {
    [self dispatchSyncOnMainThreadAndTestWithTimeout:2.5];
}

- (void)dispatchSyncOnMainThreadAndTestWithTimeout:(NSTimeInterval)timeout {
    
    HMDWatchdogProtectManager.sharedInstance.timeoutInterval = timeout;
    
    CFTimeInterval beginTime = HMD_XNUSystemCall_timeSince1970();
    
    if(NSThread.isMainThread) [self sleepLongFor20seconds_protectLevelOnlyMain];
    else dispatch_sync(dispatch_get_main_queue(), ^{
        int value = [self sleepLongFor20seconds_protectLevelOnlyMain];
        XCTAssert(value == 0);
    });
    
    CFTimeInterval endTime = HMD_XNUSystemCall_timeSince1970();
    
    XCTAssert(endTime - beginTime <= (timeout + 0.5));
    fprintf(stdout, "[HuaQ][%s sleepLongFor20seconds_protectLevelOnlyMain] finished in %f\n",
            self.description.UTF8String, endTime - beginTime);
    
    beginTime = HMD_XNUSystemCall_timeSince1970();
    if(NSThread.isMainThread) [self sleepForOnly1Seconds_protectLevelOnlyMain];
    else dispatch_sync(dispatch_get_main_queue(), ^{
        int value = [self sleepForOnly1Seconds_protectLevelOnlyMain];
        XCTAssert(value == 1);
    });
    endTime = HMD_XNUSystemCall_timeSince1970();
    XCTAssert(endTime - beginTime <= (timeout + 0.5));
}

#pragma mark - Level main Thread

- (void)testDynamicProtect_protectLevel_anyThread1 {
    [self dispatchSyncOnAnyThreadAndTestWithTimeout:1.5];
}

- (void)testDynamicProtect_protectLevel_anyThread2 {
    [self dispatchSyncOnAnyThreadAndTestWithTimeout:2.5];
}

- (void)dispatchSyncOnAnyThreadAndTestWithTimeout:(NSTimeInterval)timeout {
    HMDWatchdogProtectManager.sharedInstance.timeoutInterval = timeout;
    
    CFTimeInterval beginTime = HMD_XNUSystemCall_timeSince1970();
    
    if(!NSThread.isMainThread) [self sleepLongFor20seconds_protectLevelAny];
    else {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [NSThread MY_detachNewThreadWithBlock:^{
            int value = [self sleepLongFor20seconds_protectLevelAny];
            XCTAssert(value == 0);
            dispatch_semaphore_signal(semaphore);
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    CFTimeInterval endTime = HMD_XNUSystemCall_timeSince1970();
    
    XCTAssert(endTime - beginTime <= (timeout + 0.5));
    fprintf(stdout, "[HuaQ][%s sleepLongFor20seconds_protectLevelAny] finished in %f\n",
            self.description.UTF8String, endTime - beginTime);
    
    beginTime = HMD_XNUSystemCall_timeSince1970();
    if(!NSThread.isMainThread) [self sleepForOnly1Seconds_protectLevelAny];
    else {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [NSThread MY_detachNewThreadWithBlock:^{
            int value = [self sleepForOnly1Seconds_protectLevelAny];
            XCTAssert(value == 1);
            dispatch_semaphore_signal(semaphore);
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    endTime = HMD_XNUSystemCall_timeSince1970();
    XCTAssert(endTime - beginTime <= (timeout + 0.5));
}

- (void)testDynamicProtect_mainThreadLevelProtect_shouldNotHappenOnChild {
    
    HMDWatchdogProtectManager.sharedInstance.timeoutInterval = 2;
    
    CFTimeInterval beginTime = HMD_XNUSystemCall_timeSince1970();
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [NSThread MY_detachNewThreadWithBlock:^{
        int value = [self sleepLongFor5seconds_protectLevelOnlyMain];
        XCTAssert(value == 1);
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    CFTimeInterval endTime = HMD_XNUSystemCall_timeSince1970();
    
    XCTAssert(endTime - beginTime > 5);
    
    HMDWatchdogProtectManager.sharedInstance.timeoutInterval = 2;
    
    beginTime = HMD_XNUSystemCall_timeSince1970();
    
    if(NSThread.isMainThread) [self sleepLongFor5seconds_protectLevelOnlyMain];
    else dispatch_sync(dispatch_get_main_queue(), ^{
        int value = [self sleepLongFor5seconds_protectLevelOnlyMain];
        XCTAssert(value == 0);
    });
    
    endTime = HMD_XNUSystemCall_timeSince1970();
    
    XCTAssert(endTime - beginTime <= (2 + 0.5));
}

#pragma mark - 保护的方法

- (int)sleepLongFor20seconds_protectLevelOnlyMain {
    XCTAssert(!NSThread.isMainThread);  // protected on child thread
    sleep(20);
    return 1;
}

- (int)sleepForOnly1Seconds_protectLevelOnlyMain {
    XCTAssert(!NSThread.isMainThread);  // protected on child thread
    sleep(1);
    return 1;
}

- (int)sleepLongFor20seconds_protectLevelAny {
    XCTAssert(!NSThread.isMainThread);  // protected on child thread
    sleep(20);
    return 1;
}

- (int)sleepForOnly1Seconds_protectLevelAny {
    XCTAssert(!NSThread.isMainThread);  // protected on child thread
    sleep(1);
    return 1;
}

- (int)sleepLongFor5seconds_protectLevelOnlyMain {
    sleep(5);
    return 1;
}

@end
