//
//  HMDWatchdogTest.m
//  Heimdallr-Unit-Tests
//
//  Created by ByteDance on 2023/5/12.
//

#include <stdatomic.h>
#import "HMDWatchDog.h"
#import "HMDWatchDogTracker.h"
#import "pthread_extended.h"

#import <XCTest/XCTest.h>


@interface HMDWatchdogTest : XCTestCase

@end

@implementation HMDWatchdogTest

static NSTimeInterval before_timeoutInterval = 0;

+ (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    before_timeoutInterval = HMDWatchDog.sharedInstance.timeoutInterval;
    HMDWatchDog.sharedInstance.timeoutInterval = 4;
    HMDWatchDog.sharedInstance.enableRunloopMonitorV2 = YES;
    HMDWatchDog.sharedInstance.enableMonitorCompleteRunloop = YES;
    [HMDWatchDogTracker.sharedTracker start];
    
}

+ (void)tearDown {
    
    HMDWatchDog.sharedInstance.timeoutInterval = before_timeoutInterval;
}

- (void)test_watchdog {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    {
        XCTestExpectation *expectation = [self expectationWithDescription:@"HMDWatchDogMaybeHappenNotification"];
        [NSNotificationCenter.defaultCenter addObserverForName:HMDWatchDogMaybeHappenNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            static atomic_flag onceToken = ATOMIC_FLAG_INIT;
            if(atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) return;
            [expectation fulfill];
        }];
    }
    {
        XCTestExpectation *expectation = [self expectationWithDescription:@"HMDWatchDogTimeoutNotification"];
        [NSNotificationCenter.defaultCenter addObserverForName:HMDWatchDogTimeoutNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            static atomic_flag onceToken = ATOMIC_FLAG_INIT;
            if(atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) return;
            [expectation fulfill];
            dispatch_semaphore_signal(semaphore);
            
        }];
    }
    {
        XCTestExpectation *expectation = [self expectationWithDescription:@"HMDWatchDogRecoverNotification"];
        [NSNotificationCenter.defaultCenter addObserverForName:HMDWatchDogRecoverNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            static atomic_flag onceToken = ATOMIC_FLAG_INIT;
            if(atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) return;
            [expectation fulfill];
        }];
    }
    
    {
        XCTestExpectation *mainThreadWakeUp = [self expectationWithDescription:@"description"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
            [mainThreadWakeUp fulfill];
        });
    }
    
    [self waitForExpectationsWithTimeout:6 handler:nil];
    
}

@end
