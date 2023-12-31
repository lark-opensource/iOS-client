//
//  HMDMainThreadDispatchTest.m
//  HMDMainThreadDispatchTest
//
//  Created by bytedance on 2020/8/4.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <sys/time.h>
#include <pthread.h>
#import <CoreFoundation/CoreFoundation.h>
#import <stdatomic.h>
#import <pthread.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDSwizzle.h"
#import "HMDDynamicCall.h"
#import "HMDMainThreadDispatch.h"

#define HMD_MAIN_THREAD_DISPATCH_TIMEOUT 3.0

static void timespec_getCurrent(struct timespec * restrict ts);

static void timespec_offset(struct timespec * restrict ts, time_t sec, long nanosec);

static struct timespec CFTimeInterval_to_timespec(CFTimeInterval interval);
    
static CFTimeInterval timespec_to_CFTimeInterval(struct timespec ts);
    
static struct timespec timespec_getTimeSinceNow(CFTimeInterval internval);

static CFTimeInterval timespec_differ(struct timespec ts1, struct timespec ts2);

@interface HMDMainThreadDispatchTest : XCTestCase

@end

@implementation HMDMainThreadDispatchTest

+ (void)setUp    { /* 在所有测试前调用一次 */ }
+ (void)tearDown { /* 在所有测试后调用一次 */ }
- (void)setUp    { /* 在每次 -[ test_xxx] 方法前调用 */ }
- (void)tearDown { /* 在每次 -[ test_xxx] 方法后调用 */ }

- (void)tools_used_when_test {
    // Expectation
    XCTestExpectation *expectation = [self expectationWithDescription:@"description"];
    [expectation fulfill];
    [self waitForExpectationsWithTimeout:3 handler:nil];
    
    // Assert
    XCTAssert(nil, @"NSLog format:%@", nil);
}

#pragma mark - 测试可以异步到主线程

- (void)test_method_could_dispatch_to_main_thread {
    HMDMainThreadDispatch.sharedInstance.enable = YES;
    [HMDMainThreadDispatch.sharedInstance dispatchMainThreadMethods:@[
        @"+[HMDMainThreadDispatchTest must_in_main_thread_class_method:]",
        @"-[HMDMainThreadDispatchTest must_in_main_thread_instance_method:]"
    ]];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"must_in_main_thread_class_method"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"must_in_main_thread_instance_method"];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [HMDMainThreadDispatchTest must_in_main_thread_class_method:^{
            [expectation1 fulfill];
        }];
        [HMDMainThreadDispatchTest.new must_in_main_thread_instance_method:^{
            [expectation2 fulfill];
        }];
    });
    [self waitForExpectationsWithTimeout:4 handler:nil];
}

+ (void)must_in_main_thread_class_method:(void(^)(void))block {
    XCTAssert(pthread_main_np(), @"class method must be dispatched to main thread");
    if(block != nil) block();
}

- (void)must_in_main_thread_instance_method:(void(^)(void))block {
    XCTAssert(pthread_main_np(), @"instance method must be dispatched to main thread");
    if(block != nil) block();
}

- (void)call_block:(void(^)(void))block {
    if(block != nil) block();
}

- (void)another_method {}

- (void)test_method_in_main_thread_should_not_dispatch_anyway {
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
        
        XCTestExpectation *expectation = [self expectationWithDescription:@"pass test"];
        
        HMDMainThreadDispatch.sharedInstance.enable = YES;
        [HMDMainThreadDispatch.sharedInstance dispatchMainThreadMethods:@[
            @"+[HMDMainThreadDispatchTest must_in_main_thread_class_method:]",
            @"-[HMDMainThreadDispatchTest must_in_main_thread_instance_method:]"
        ]];
        
        if(pthread_main_np()) {
            pthread_key_t key;
            pthread_key_create(&key, NULL);
            pthread_setspecific(key, (void *)0x10086);
            [HMDMainThreadDispatchTest must_in_main_thread_class_method:^{
                void *value = pthread_getspecific(key);
                XCTAssert(value == (void *)0x10086, @"should be the same");
                [expectation fulfill];
            }];
            pthread_setspecific(key, (void *)0x0);
        } else dispatch_async(dispatch_get_main_queue(), ^{
            pthread_key_t key;
            pthread_key_create(&key, NULL);
            pthread_setspecific(key, (void *)0x10086);
            [HMDMainThreadDispatchTest must_in_main_thread_class_method:^{
                void *value = pthread_getspecific(key);
                XCTAssert(value == (void *)0x10086, @"should be the same");
                [expectation fulfill];
            }];
            pthread_setspecific(key, (void *)0x0);
        });
        
        [self waitForExpectationsWithTimeout:4 handler:nil];
    }
}

- (void)test_turn_off_protection_should_not_protect {
    HMDMainThreadDispatch.sharedInstance.enable = YES;
    [HMDMainThreadDispatch.sharedInstance dispatchMainThreadMethods:@[
        @"-[HMDMainThreadDispatchTest call_block:]"
    ]];
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"description"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"description"];
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"description"];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        pthread_t this_thread = pthread_self();
        
        [self call_block:^{
            XCTAssert(pthread_self() != this_thread, @"must be in current thread");
            XCTAssert(pthread_main_np(), @"must be in main thread");
            [expectation2 fulfill];
        }];
        
        HMDMainThreadDispatch.sharedInstance.enable = NO;
        [self call_block:^{
            XCTAssert(pthread_self() == this_thread, @"must be in current thread");
            [expectation3 fulfill];
        }];
        
        [expectation1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:4 handler:nil];
}

- (void)test_update_config_should_not_protect {
    HMDMainThreadDispatch.sharedInstance.enable = YES;
    [HMDMainThreadDispatch.sharedInstance dispatchMainThreadMethods:@[
        @"-[HMDMainThreadDispatchTest call_block:]"
    ]];
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"description"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"description"];
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"description"];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        pthread_t this_thread = pthread_self();
        
        [self call_block:^{
            XCTAssert(pthread_self() != this_thread, @"must be in current thread");
            XCTAssert(pthread_main_np(), @"must be in main thread");
            [expectation2 fulfill];
        }];
        
        [HMDMainThreadDispatch.sharedInstance dispatchMainThreadMethods:@[
            @"-[HMDMainThreadDispatchTest another_method]"
        ]];
        
        [self call_block:^{
            XCTAssert(pthread_self() == this_thread, @"must be in current thread");
            [expectation3 fulfill];
        }];
        
        [expectation1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:4 handler:nil];
}

- (NSUInteger)return_NSUInteger_value:(NSUInteger)value waitTime:(NSTimeInterval)seconds {
    if(seconds > 0.0) {
        struct timespec requestTimeSleep = CFTimeInterval_to_timespec(seconds);
        nanosleep(&requestTimeSleep, NULL);
    }
    return value;
}

- (CGRect)return_CGRect_value:(CGRect)rect waitTime:(NSTimeInterval)seconds {
    if(seconds > 0.0) {
        struct timespec requestTimeSleep = CFTimeInterval_to_timespec(seconds);
        nanosleep(&requestTimeSleep, NULL);
    }
    return rect;
}

- (void)test_timeout_should_return_zero_NSUInteger {
    NSUInteger result = [self return_NSUInteger_value:10086 waitTime:0.0];
    XCTAssert(10086 == result);
    HMDMainThreadDispatch.sharedInstance.enable = YES;
    [HMDMainThreadDispatch.sharedInstance dispatchMainThreadMethods:@[
        @"-[HMDMainThreadDispatchTest return_NSUInteger_value:waitTime:]",
        @"-[HMDMainThreadDispatchTest return_CGRect_value:waitTime:]"
    ]];
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"description"];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSUInteger value = [self return_NSUInteger_value:10086 waitTime:1.0];
        XCTAssert(value == 10086);
        value = [self return_NSUInteger_value:10086 waitTime:HMD_MAIN_THREAD_DISPATCH_TIMEOUT + 1.0];
        XCTAssert(value == 0);
        
        [expectation1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_timeout_should_return_zero_CGRect {
    CGRect resultRect = [self return_CGRect_value:CGRectMake(1, 1, 1, 1) waitTime:0.0];
    XCTAssert(CGRectEqualToRect(resultRect, CGRectMake(1, 1, 1, 1)));
    HMDMainThreadDispatch.sharedInstance.enable = YES;
    [HMDMainThreadDispatch.sharedInstance dispatchMainThreadMethods:@[
        @"-[HMDMainThreadDispatchTest return_NSUInteger_value:waitTime:]",
        @"-[HMDMainThreadDispatchTest return_CGRect_value:waitTime:]"
    ]];
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"description"];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        CGRect value = [self return_CGRect_value:CGRectMake(1, 1, 1, 1) waitTime:1.0];
        XCTAssert(CGRectEqualToRect(CGRectMake(1, 1, 1, 1), value));
        value = [self return_CGRect_value:CGRectMake(1, 1, 1, 1) waitTime:HMD_MAIN_THREAD_DISPATCH_TIMEOUT + 1.0];
        XCTAssert(CGRectEqualToRect(CGRectZero, value));
        
        [expectation1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

@end

static void timespec_getCurrent(struct timespec * restrict ts) {
    if(ts == NULL) return;
    struct timeval tv;
    gettimeofday(&tv, NULL);
    ts->tv_sec = tv.tv_sec;
    ts->tv_nsec = tv.tv_usec * 1000ul;
}

static void timespec_offset(struct timespec * restrict ts, time_t sec, long nanosec) {
    if(ts == NULL) return;
    
    if(ts->tv_nsec > LONG_MAX - nanosec) return;
    long add_sec = (ts->tv_nsec + nanosec) / NSEC_PER_SEC;
    long re_nano = (ts->tv_nsec + nanosec) % NSEC_PER_SEC;
    time_t new_sec = ts->tv_sec + add_sec + sec;
    ts->tv_sec = new_sec;
    ts->tv_nsec = re_nano;
}

static struct timespec CFTimeInterval_to_timespec(CFTimeInterval interval) {
    double sec;
    double frac = modf(interval, &sec);
    return (struct timespec){.tv_sec = sec, .tv_nsec = frac * NSEC_PER_SEC};
}

static CFTimeInterval timespec_to_CFTimeInterval(struct timespec ts) {
    return ts.tv_sec + (CFTimeInterval) ts.tv_nsec / NSEC_PER_SEC;
}

static struct timespec timespec_getTimeSinceNow(CFTimeInterval internval) {
    struct timespec result;
    struct timespec offset = CFTimeInterval_to_timespec(internval);
    timespec_getCurrent(&result);
    timespec_offset(&result, offset.tv_sec, offset.tv_nsec);
    return result;
}

static CFTimeInterval timespec_differ(struct timespec ts1, struct timespec ts2) {
    if(ts1.tv_sec >= 0 && ts2.tv_sec >= 0 && ts1.tv_nsec >= 0 && ts1.tv_nsec >= 0) {
        int64_t  sec = ts1.tv_sec  - ts2.tv_sec;
        int64_t nsec = ts1.tv_nsec - ts2.tv_nsec;
        CFTimeInterval nsec_to_sec = (CFTimeInterval) nsec / NSEC_PER_SEC;
        return sec + nsec_to_sec;
    }
    return -1.0;
}

static struct timespec timespec_create(time_t sec, long nanosec) {
    return (struct timespec){.tv_sec = sec, .tv_nsec = nanosec};
}
