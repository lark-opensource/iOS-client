//
//  HMDProtectCaptureTest.m
//  HMDProtectCaptureTest
//
//  Created by bytedance on 2020/8/4.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDSwizzle.h"
#import "HMDDynamicCall.h"
#import "HMDProtectCapture.h"

@interface HMDProtectCaptureTest : XCTestCase

@end

@implementation HMDProtectCaptureTest

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

- (void)test_creationSuccess {
    HMDProtectCapture *capture = [HMDProtectCapture captureException:@"exceptionName"
                                                              reason:@"reasonName"
                                                            crashKey:@"crashKeyName"];
    
    
    XCTAssert([capture.exception isEqualToString:@"exceptionName"]);
    XCTAssert([capture.reason isEqualToString:@"reasonName"]);
    XCTAssert([capture.crashKey isEqualToString:@"crashKeyName"]);
}

- (void)test_deleteNewLineSuccess {
    NSString *reasonString = @"hello\n" "world";
    NSString *expectString = @"hello " "world";
    
    HMDProtectCapture *capture = [HMDProtectCapture captureException:@"exceptionName"
                                                              reason:reasonString
                                                            crashKey:@"crashKeyName"];
    
    
    XCTAssert([capture.exception isEqualToString:@"exceptionName"]);
    XCTAssert([capture.reason isEqualToString:expectString]);
    XCTAssert([capture.crashKey isEqualToString:@"crashKeyName"]);
}

@end
