//
//  HMDWeakRetainDeallocatingTests.m
//  HMDWeakRetainDeallocatingTests
//
//  Created by bytedance on 2020/8/4.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDSwizzle.h"
#import "HMDDynamicCall.h"
#import "HMDWeakRetainDeallocating.h"
#import <BDFishhook/BDFishhook.h>
#import "HMDObjcRuntime.h"

@interface WRDTestObject : NSObject
@end

@implementation WRDTestObject

- (void)dealloc {
    id __weak weakStorage = nil;
    weakStorage = self;
    id __strong strongStorage = nil;
    strongStorage = weakStorage;
    XCTAssert(strongStorage == nil);
}

@end

@interface HMDWeakRetainDeallocatingTests : XCTestCase

@end

extern BOOL HMDProtectTestEnvironment;
static BOOL capturedMark = NO;
static BOOL before_HMDProtectTestEnvironment;

@implementation HMDWeakRetainDeallocatingTests

+ (void)setUp    { /* 在所有测试前调用一次 */
    open_bdfishhook();
    HMD_Protect_toggle_weakRetainDeallocating_protection(^(HMDProtectCapture * _Nonnull capture) {
        capturedMark = YES;
    });
    before_HMDProtectTestEnvironment = HMDProtectTestEnvironment;
    HMDProtectTestEnvironment = YES;
}
+ (void)tearDown { /* 在所有测试后调用一次 */
    HMDProtectTestEnvironment = before_HMDProtectTestEnvironment;
}

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

- (void)test_weakRetainDeallocatingProtection_method {
#if __arm64__ && __LP64__
    capturedMark = NO;
    
    id object = [[WRDTestObject alloc] init];
    object = [[NSObject alloc] init];
    XCTAssert(capturedMark);
#endif
}

- (void)test_taggedPointer_method {
    NSNumber *number = @(1);
    XCTAssert(hmd_objc_is_tag_pointer((__bridge void *)(number)));
    id __weak weakStorage = nil;
    weakStorage = number;
    weakStorage = nil;
}

@end
