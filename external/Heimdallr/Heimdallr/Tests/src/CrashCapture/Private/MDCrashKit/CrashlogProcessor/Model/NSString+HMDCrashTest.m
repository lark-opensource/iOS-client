//
//  NSStringHMDCrashTests.m
//  NSStringHMDCrashTests
//
//  Created by bytedance on 2020/8/4.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDTimeSepc.h"
#import "HMDSwizzle.h"
#import "HMDDynamicCall.h"
#import "NSString+HMDCrash.h"

@interface NSString (HMDCrashOld)

- (NSString * _Nullable)hmdcrash_stringWithHex_old;

@end

@interface NSStringHMDCrashTests : XCTestCase

@end

@implementation NSStringHMDCrashTests

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

- (void)test_hmdcrash_stringWithHex_decode_success {
    NSString *rawString = @"E68891E4BBACE697A2E784B6E69BBEE7BB8FE68BA5E69C89EFBD9E";
    NSString *resultString = [rawString hmdcrash_stringWithHex];
    XCTAssert(resultString != nil);
    XCTAssert([resultString isEqualToString:@"我们既然曾经拥有～"]);
}

- (void)test_hmdcrash_stringWithHex_decode_large_length {
    NSString *rawString = @"E68891E4BBACE697A2E784B6E69BBEE7BB8FE68BA5E69C89EFBD9E";
    
    NSMutableString *combinedString = NSMutableString.string;
    for(NSUInteger index = 0; index < 50; index++)
        [combinedString appendString:rawString];
    
    NSMutableString *shouldBeString = NSMutableString.string;
    for(NSUInteger index = 0; index < 50; index++)
        [shouldBeString appendString:@"我们既然曾经拥有～"];
    
    
    NSString *resultString = [combinedString hmdcrash_stringWithHex];
    XCTAssert(resultString != nil);
    XCTAssert([resultString isEqualToString:shouldBeString]);
}

- (void)test_hmdcrash_stringWithHex_decode_large_length_2 {
    NSString *rawString = @"E68891E4BBACE697A2E784B6E69BBEE7BB8FE68BA5E69C89EFBD9E";
    
    NSMutableString *combinedString = NSMutableString.string;
    for(NSUInteger index = 0; index < 150; index++)
        [combinedString appendString:rawString];
    
    NSMutableString *shouldBeString = NSMutableString.string;
    for(NSUInteger index = 0; index < 150; index++)
        [shouldBeString appendString:@"我们既然曾经拥有～"];
    
    
    NSString *resultString = [combinedString hmdcrash_stringWithHex];
    XCTAssert(resultString != nil);
    XCTAssert([resultString isEqualToString:shouldBeString]);
}

- (void)test_hmdcrash_stringWithHex_decode_large_length_3 {
    NSString *rawString = @"E68891E4BBACE697A2E784B6E69BBEE7BB8FE68BA5E69C89EFBD9E";
    
    NSMutableString *combinedString = NSMutableString.string;
    for(NSUInteger index = 0; index < 1500; index++)
        [combinedString appendString:rawString];
    
    NSMutableString *shouldBeString = NSMutableString.string;
    for(NSUInteger index = 0; index < 1500; index++)
        [shouldBeString appendString:@"我们既然曾经拥有～"];
    
    
    NSString *resultString = [combinedString hmdcrash_stringWithHex];
    XCTAssert(resultString != nil);
    XCTAssert([resultString isEqualToString:shouldBeString]);
}

- (void)test_hmdcrash_stringWithHex_decode_large_length_4 {
    NSString *rawString = @"E68891E4BBACE697A2E784B6E69BBEE7BB8FE68BA5E69C89EFBD9E";
    
    NSMutableString *combinedString = NSMutableString.string;
    for(NSUInteger index = 0; index < 10000; index++)
        [combinedString appendString:rawString];
    
    NSMutableString *shouldBeString = NSMutableString.string;
    for(NSUInteger index = 0; index < 10000; index++)
        [shouldBeString appendString:@"我们既然曾经拥有～"];
    
    
    NSString *resultString = [combinedString hmdcrash_stringWithHex];
    XCTAssert(resultString == nil);
}

- (void)test_hmdcrash_stringWithHex_decode_efficiency_1 {
    NSString *rawString = @"E68891E4BBACE697A2E784B6E69BBEE7BB8FE68BA5E69C89EFBD9E";
    
    NSTimeInterval begin = HMD_XNUSystemCall_timeSince1970();
    
    for(NSUInteger index = 0; index < 10000; index++)
        [rawString hmdcrash_stringWithHex_old];
    
    NSTimeInterval middle = HMD_XNUSystemCall_timeSince1970();
    
    for(NSUInteger index = 0; index < 10000; index++)
        [rawString hmdcrash_stringWithHex];
    
    NSTimeInterval end = HMD_XNUSystemCall_timeSince1970();
    
    NSTimeInterval originalTimeCost = (middle - begin) * 1000;
    NSTimeInterval currentTimeCost = (end - middle) * 1000;
    
    fprintf(stdout, "Original Time Cost:%f ms\n", originalTimeCost);
    fprintf(stdout, " Current Time Cost:%f ms\n", currentTimeCost);
    
    XCTAssert(originalTimeCost >= 2 * currentTimeCost);
}

@end

@implementation NSString (HMDCrashOld)

- (NSString * _Nullable)hmdcrash_stringWithHex_old {
    NSUInteger len = self.length;
    char buffer[len/2 + 2];
    memset(buffer, 0, sizeof(buffer));
    int i = 0;
    for (;;) {
        if (i + 1 >= len) {
            break;
        }
        
        uint8_t value0 = [self hmdcrash_valueWithHexChar:[self characterAtIndex:i]];
        if (value0 > 15) {
            return nil;
        }
        
        uint8_t value1 = [self hmdcrash_valueWithHexChar:[self characterAtIndex:i+1]];
        if (value1 > 15) {
            return nil;
        }
        
        uint8_t val = value1 + (value0 << 4);
        
        
        buffer[i/2] = val;

        
        i += 2;
    }
    
    if (strlen(buffer) > 0) {
        NSString *str = [[NSString alloc] initWithUTF8String:buffer];
        return str;
    }
    
    return @"";
}

- (uint8_t)hmdcrash_valueWithHexChar:(char)c {
    if (c >= '0' && c <= '9') {
        return c - '0';
    } else if (c >= 'a' && c <= 'f') {
        return c - 'a' + 10;
    } else if (c >= 'A' && c <= 'F') {
        return c - 'A' + 10;
    }
    return UINT8_MAX;
}

@end
