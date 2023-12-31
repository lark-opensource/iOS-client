//
//  HMDAnalyzerTests.m
//  HMDAnalyzerTests
//
//  Created by bytedance on 2020/8/4.
//  Copyright © 2020 bytedance. All rights reserved.
//

#include <objc/objc.h>
#include <objc/runtime.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDSwizzle.h"
#import "HMDDynamicCall.h"
#import "HMDObjectAnalyzer.h"
#import "HMDTaggedPointerAnalyzer.h"

#if __x86_64__
#   define ISA_TAG_MASK 1UL
#   define ISA_MASK     0x00007ffffffffff8UL
#elif defined(__arm64__)
#   define ISA_TAG_MASK 1UL
#   define ISA_MASK_OLD 0x00000001fffffff8UL
#   define ISA_MASK     0x0000000ffffffff8UL
#else
#   define ISA_TAG_MASK 0UL
#   define ISA_MASK     ~1UL
#endif

static void assert_class_match(Class aClass);
static void assert_object_match(id instance);
static void assert_tagged_object_match(id instance);

@interface HMDAnalyzerTests : XCTestCase

@end

@implementation HMDAnalyzerTests

+ (void)setUp    { /* 在所有测试前调用一次 */
    HMDObjectAnalyzer_initialization();
}
+ (void)tearDown { /* 在所有测试后调用一次 */ }

- (void)setUp    { /* 在每次 -[ test_xxx] 方法前调用 */
    XCTAssert(HMDObjectAnalyzer_isInitialized());
}
- (void)tearDown { /* 在每次 -[ test_xxx] 方法后调用 */ }

- (void)tools_used_when_test {
    // Expectation
    XCTestExpectation *expectation = [self expectationWithDescription:@"description"];
    [expectation fulfill];
    [self waitForExpectationsWithTimeout:3 handler:nil];
    
    // Assert
    XCTAssert(nil, @"NSLog format:%@", nil);
}

- (void)test_fetchClassSuccess {
    assert_class_match(NSObject.class);
    assert_class_match(NSNumber.class);
    assert_class_match(NSDate.class);
    assert_class_match(NSValue.class);
    assert_class_match(HMDAnalyzerTests.class);
}

- (void)test_taggedPointerClassSuccess {
#if !__LP64__
    
#else
    // assert_tagged_object_match([NSNumber numberWithInt:1]);
    // assert_tagged_object_match([NSDate date]);
    HMDTaggedPointerAnalyzer_initialization();
    XCTAssert(HMDTaggedPointerAnalyzer_isTaggedPointer((__bridge void *)[NSNumber numberWithInt:1]));
    XCTAssert(HMDTaggedPointerAnalyzer_isTaggedPointer((__bridge void *)[NSDate date]));
#endif
}

- (void)test_shouldNotCrash {
    for(size_t index = 0; index < 100; index++) {
        uint64_t *someValue = malloc(sizeof(uint64_t));
        uint64_t randValue1 = arc4random();
        uint64_t randValue2 = arc4random();
        uint64_t mixedRandValue = (randValue1 << 32) + randValue2;
        someValue[0] = mixedRandValue;
        mixedRandValue &= ISA_MASK;
        HMDObjectAnalyzer_unsafeObjectGetClass((HMDUnsafeObject)mixedRandValue);
        HMDObjectAnalyzer_unsafeObjectGetClass((HMDUnsafeObject)someValue);

        uint8_t className[512];
        HMDClassAnalyzer_unsafeClassGetName((HMDUnsafeClass)someValue, className, 512);
    }
}

@end

static void assert_tagged_object_match(id instance) {
    if(instance != nil) {
        XCTAssert(HMDTaggedPointerAnalyzer_isTaggedPointer((__bridge HMDUnsafeObject)instance));
        assert_object_match(instance);
    }
}

static void assert_class_match(Class aClass) {
    if(aClass != nil) {
        id instance = class_createInstance(aClass, 0);
        if(instance != nil) assert_object_match(instance);
    }
}

static void assert_object_match(id instance) {
    if(instance != nil) {
        uint8_t rawClassName[512];
        bool result = HMDObjectAnalyzer_unsafeObjectGetClassName((__bridge HMDUnsafeObject)instance, rawClassName, 512);
        XCTAssert(result);
        if(result) {
            NSString *analyzerClassName = [NSString stringWithUTF8String:(const char *)rawClassName];
            NSString *realClassName = NSStringFromClass(object_getClass(instance));
            XCTAssert([analyzerClassName isEqualToString:realClassName]);
        }
    }
}
