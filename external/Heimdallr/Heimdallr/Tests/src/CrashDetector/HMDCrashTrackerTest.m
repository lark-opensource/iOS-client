//
//  HMDCrashTrackerTest.m
//  HMDCrashTrackerTest
//
//  Created by bytedance on 2020/8/4.
//  Copyright © 2020 bytedance. All rights reserved.
//

#include <pthread.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDSwizzle.h"
#import "HMDDynamicCall.h"
#import "HMDCrashDirectory.h"
#import "HMDCrashKit.h"
#import "HMDCrashKit+Internal.h"
#import "HMDCrashDirectoryTest.h"
#import "HMDCrashTracker.h"
#import "HMDExcludeModuleHelper.h"
#import "HMDInjectedInfo.h"

@interface HMDCrashTrackerTest : XCTestCase

@end

@implementation HMDCrashTrackerTest

+ (void)setUp    { /* 在所有测试前调用一次 */ }
+ (void)tearDown { /* 在所有测试后调用一次 */ }
- (void)setUp    { /* 在每次 -[ test_xxx] 方法前调用 */ }
- (void)tearDown { /* 在每次 -[ test_xxx] 方法后调用 */ }

static BOOL foundCrashLog = NO;
static XCTestExpectation *shared_expectation;
static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

- (void)tools_used_when_test {
    // Expectation
    XCTestExpectation *expectation = [self expectationWithDescription:@"description"];
    [expectation fulfill];
    [self waitForExpectationsWithTimeout:3 handler:nil];
    
    // Assert
    XCTAssert(nil, @"NSLog format:%@", nil);
}

+ (void)load {
    [HMDCrashTracker.sharedTracker addCrashDetectCallBack:^(HMDCrashRecord * _Nullable record) {
        [self receiveRecord:record];
    }];
    if(objc_getClass("HMDTTNetManager") != nil) {
        HMD_mockClassTreeForInstanceMethod(HMDNetworkManager, ttnetManager, ^id(id self){
            return nil;
        });
    }
}

- (void)test_CrashTrackerCallbackWithRecord {
    HMDInjectedInfo.defaultInfo.appID = @"492373";
    [HMDCrashDirectoryTest generateCrashDataInActiveFolder];
    
    if(!HMDCrashTracker.sharedTracker.isRunning)
        [HMDCrashTracker.sharedTracker start];
    
    XCTestExpectation *expectation = nil;
    
    pthread_mutex_lock(&mutex);
    if(!foundCrashLog) {
        expectation = [self expectationWithDescription:@"wait for crash log callback"];
        shared_expectation = expectation;
    }
    pthread_mutex_unlock(&mutex);
    
    if(expectation != nil) [self waitForExpectationsWithTimeout:8 handler:nil];
}

+ (void)receiveRecord:(HMDCrashRecord * _Nullable)record {
    NSLog(@"record.crashLog: %@", record.crashLog);
    
    XCTestExpectation *expectation = nil;
    
    pthread_mutex_lock(&mutex);
    foundCrashLog = record.crashLog.length > 0;
    if(shared_expectation != nil) {
        XCTAssert(foundCrashLog);
        if(foundCrashLog) expectation = shared_expectation;
    }
    pthread_mutex_unlock(&mutex);
    
    if(expectation != nil)
        [shared_expectation fulfill];
}

@end
