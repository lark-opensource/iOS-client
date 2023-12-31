//
//  HMDOCObjectAnalyzerTest.m
//  HMDOCObjectAnalyzerTest
//
//  Created by bytedance on 2020/8/4.
//  Copyright © 2020 bytedance. All rights reserved.
//

#include <malloc/malloc.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDSwizzle.h"
#import "HMDDynamicCall.h"
#import "HMDTaggedPointerAnalyzer.h"

@interface HMDOCObjectAnalyzerTest : XCTestCase

@end

@implementation HMDOCObjectAnalyzerTest

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

- (void)test_malloc_size_handle_tagged_pointer {
    NSNumber *number = @(1);
    size_t size = malloc_size((__bridge const void *)(number));
    XCTAssert(size == 0);
    
    XCTAssert(HMDTaggedPointerAnalyzer_initialization());
    HMDTaggedPointerAnalyzer_isTaggedPointer((__bridge void *)number);
}


@end
