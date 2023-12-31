//
//  HMDUSELForwarderAssemblyTest.m
//  HMDUSELForwarderAssemblyTest
//
//  Created by bytedance on 2020/8/4.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDSwizzle.h"
#import "HMDDynamicCall.h"
#import "HMDUSELForwarder.h"

@interface HMDUSELForwarder (AnyReturn)

+ (int)intReturn;
+ (char)charReturn;
+ (void *)voidPointerReturn;
+ (unsigned long long)unsignedLongLongReturn;
+ (float)floatReturn;
+ (double)doubleReturn;
+ (long double)longDoubleReturn;
+ (CGSize)CGSizeReturn;
+ (NSRange)NSRangeReturn;
+ (CGRect)CGRectReturn;

//+ (<#type#>)<#typeReturn#>;

@end

@interface HMDUSELForwarderAssemblyTest : XCTestCase

@end

@implementation HMDUSELForwarderAssemblyTest

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

- (int)makeNoneZeroIntReturn { return 10086; }
- (char)makeNoneZeroCharReturn { return '6'; }
- (unsigned long)makeNoneZeroUnsignedLongLongReturn { return 10086ull; }
- (float)makeNoneZeroFloatReturn { return 10086.0f; }
- (double)makeNoneZeroDoubleReturn { return 10086.0; }
- (long double)makeNoneZeroLongDoubleReturn { return 10086.0l; }
- (CGSize)makeNoneZeroCGSize { return CGSizeMake(10086.0, 10086.0); }
- (NSRange)makeNoneZeroNSRange { return NSMakeRange(10086, 10086); }
- (CGRect)makeNoneZeroCGRect { return CGRectMake(10086.0, 10086.0, 10086.0, 10086.0); }

//- (type)makeNoneZero<#typeReturn#> { return <#zeroValue#>; }

- (void)testUSELForwarderReturn {
#ifdef __arm64__
    [self makeNoneZeroIntReturn];
    XCTAssert([HMDUSELForwarder intReturn] == 0, @"intReturn not zero");
    
    [self makeNoneZeroCharReturn];
    XCTAssert([HMDUSELForwarder charReturn] == 0, @"charReturn not zero");
    
    [self makeNoneZeroUnsignedLongLongReturn];
    XCTAssert([HMDUSELForwarder unsignedLongLongReturn] == 0ull, @"unsignedLongLongReturn not zero");
    
    [self makeNoneZeroFloatReturn];
    XCTAssert([HMDUSELForwarder floatReturn] == 0.0f, @"floatReturn not zero");
    
    [self makeNoneZeroDoubleReturn];
    XCTAssert([HMDUSELForwarder doubleReturn] == 0.0, @"doubleReturn not zero");
    
    [self makeNoneZeroLongDoubleReturn];
    XCTAssert([HMDUSELForwarder longDoubleReturn] == 0.0l, @"longDoubleReturn not zero");
    
    [self makeNoneZeroCGSize];
    XCTAssert(CGSizeEqualToSize([HMDUSELForwarder CGSizeReturn], CGSizeZero), @"CGSizeZeroReturn not zero");

    [self makeNoneZeroNSRange];
    XCTAssert(NSEqualRanges([HMDUSELForwarder NSRangeReturn], NSMakeRange(0, 0)), @"NSRangeReturn not zero");

    [self makeNoneZeroCGRect];
    XCTAssert(CGRectEqualToRect([HMDUSELForwarder CGRectReturn], CGRectZero), @"CGRectReturn not zero");

//    [self makeNoneZero<#typeReturn#>];
//    XCTAssert([HMDUSELForwarder <#typeReturn#>] == <#typeZero#>, @"<#typeReturn#> not zero");
#endif
    XCTAssert([HMDUSELForwarder voidPointerReturn] == (void *)0, @"voidPointerReturn not zero");
}

@end
