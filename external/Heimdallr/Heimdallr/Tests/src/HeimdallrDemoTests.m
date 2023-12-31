//
//  HeimdallrBetterDemoTests.m
//  HeimdallrBetterDemoTests
//
//  Created by bytedance on 2020/8/4.
//  Copyright © 2020 bytedance. All rights reserved.
//

#include <objc/objc.h>
#include <objc/runtime.h>
#include <objc/message.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDMacro.h"
#import "HMDSwizzle.h"
#import "HMDDynamicCall.h"

@interface HeimdallrBetterDemoTests : XCTestCase

@end

@implementation HeimdallrBetterDemoTests

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

- (void)test_xxx_method {
    
}

@end
