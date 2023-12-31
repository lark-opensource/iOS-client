//
//  HMDCrashKitTest.m
//  HMDCrashKitTest
//
//  Created by bytedance on 2020/8/4.
//  Copyright © 2020 bytedance. All rights reserved.
//

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

@interface HMDCrashKitTest : XCTestCase

@end

@implementation HMDCrashKitTest

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

- (void)test_crash_vm_info {
    HMDInjectedInfo.defaultInfo.appID = @"492373";
    [HMDCrashDirectoryTest generateCrashDataInActiveFolder];
    if(!HMDCrashTracker.sharedTracker.isRunning)
        [HMDCrashTracker.sharedTracker start];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"wait for HMDExcludeModuleHelper to complete"];
    
    HMDExcludeModuleHelper *helper = [[HMDExcludeModuleHelper alloc] initWithSuccess:^{
        [self crashTrackerStatusDecided];
        [expectation fulfill];
    } failure:^{
        [self crashTrackerStatusDecided];
        [expectation fulfill];
    } timeout:^{
        [self crashTrackerStatusDecided];
        [expectation fulfill];
    }];
    
    [helper addRuntimeClassName:@"HMDCrashTracker" forDependency:HMDExcludeModuleDependencyFinish];
    
    [helper startDetection];
    
    [self waitForExpectationsWithTimeout:6 handler:nil];
}

- (void)crashTrackerStatusDecided {
    NSLog(@"HMDCrashKit.sharedInstance.lastCrashUsedVM: %@", @(HMDCrashKit.sharedInstance.lastCrashUsedVM));
    NSLog(@"HMDCrashKit.sharedInstance.lastCrashTotalVM: %@", @(HMDCrashKit.sharedInstance.lastCrashTotalVM));
    XCTAssert(HMDCrashKit.sharedInstance.lastCrashUsedVM != 0);
    XCTAssert(HMDCrashKit.sharedInstance.lastCrashTotalVM != 0);
}

@end
