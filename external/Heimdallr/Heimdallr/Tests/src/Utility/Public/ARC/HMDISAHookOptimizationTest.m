//
//  HMDISAHookOptimizationTest.m
//  HMDISAHookOptimizationTest
//
//  Created by bytedance on 2020/8/4.
//  Copyright © 2020 bytedance. All rights reserved.
//

#include <dlfcn.h>
#include <objc/objc.h>
#include <objc/runtime.h>
#include <objc/message.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDMacro.h"
#import "HMDSwizzle.h"
#import "HMDDynamicCall.h"
#import "HMDISAHookOptimization.h"

#if   __has_include("Heimdallr_Unit_Tests-Swift.h")
#import "Heimdallr_Unit_Tests-Swift.h"
#elif __has_include("Heimdallr-Unit-Tests-Swift.h")
#import "Heimdallr-Unit-Tests-Swift.h"
#else
#error swift bridge header not found
#endif

#if __arm64__ && __LP64__

static void make_x7_happy(void);

__asm__(
"_make_x7_happy:\n"
"mov    x7, #64207\n"
"movk   x7, #65261, lsl #16\n"
"movk   x7, #64207, lsl #32\n"
"movk   x7, #65261, lsl #48\n"
"ret\n"
);

#else

static void make_x7_happy(void) {
    
}


#endif

@interface HMDISAHookOptimizationTest : XCTestCase

@property(readonly) const char *randomClassName;

@end

@implementation HMDISAHookOptimizationTest

@dynamic randomClassName;

- (const char *)randomClassName {
    static const char * classNameCollection[] = {
        "_TtGC20Heimdallr_Unit_Tests6MyViewGCS_7ContentGS1_CSo8NSStringCSo12NSDictionary_CSo8NSNumber__",
        "_TtGC20Heimdallr_Unit_Tests6MyViewGCS_7ContentGS1_CSo8NSStringCSo12NSDictionary_CSo8NSNumber__",
        "_TtGC20Heimdallr_Unit_Tests6MyViewGCS_7ContentGS1_CSo8NSNumberS2__S2___",
        "_TtGC20Heimdallr_Unit_Tests6MyViewGCS_7ContentGS1_CSo7NSValueCSo8NSString_CSo8NSObject__",
        "_TtGC20Heimdallr_Unit_Tests6MyViewGCS_7ContentGS1_CSo8NSObjectCSo6NSUUID_CSo5NSSet__",
        "_TtGC20Heimdallr_Unit_Tests6MyViewGCS_7ContentGS1_CSo6NSUUIDCSo18NSAttributedString_CSo8NSNumber__",
        "_TtGC20Heimdallr_Unit_Tests6MyViewGCS_7ContentGS1_CSo6NSUUIDCSo6NSNull_CSo8NSNumber__",
        "_TtGC20Heimdallr_Unit_Tests6MyViewGCS_7ContentGS1_CSo6NSUUIDCSo6NSLock_CSo8NSObject__",
        "_TtGC20Heimdallr_Unit_Tests6MyViewGCS_7ContentGS1_CSo6NSUUIDCSo7NSError_CSo5NSSet__",
        "_TtGC20Heimdallr_Unit_Tests6MyViewGCS_7ContentGS1_CSo18NSLayoutConstraintCSo18NSAttributedString_CSo8NSNumber__",
        "_TtGC20Heimdallr_Unit_Tests6MyViewGCS_7ContentGS1_CSo18NSLayoutConstraintCSo6NSNull_CSo8NSNumber__",
        "_TtGC20Heimdallr_Unit_Tests6MyViewGCS_7ContentGS1_CSo18NSLayoutConstraintCSo6NSLock_CSo8NSObject__",
        "_TtGC20Heimdallr_Unit_Tests6MyViewGCS_7ContentGS1_CSo18NSLayoutConstraintCSo7NSError_CSo5NSSet__",
        "_TtGC20Heimdallr_Unit_Tests6MyViewGCS_7ContentGS1_CSo18NSLayoutConstraintCSo5NSSet_CSo7NSError__",
        "_TtGC20Heimdallr_Unit_Tests6MyViewGCS_7ContentGS1_CSo18NSLayoutConstraintCSo8NSNumber_CSo5NSSet__",
        "_TtGC20Heimdallr_Unit_Tests6MyViewGCS_7ContentGS1_CSo18NSLayoutConstraintCSo7NSError_CSo8NSNumber__",
    };
    static bool initialized = false;
    static size_t index = 0;
    size_t currentIndex = 0;
    
    size_t count = sizeof(classNameCollection) / sizeof(classNameCollection[0]);
    @synchronized (HMDISAHookOptimizationTest.class) {
        if(!initialized) {
            initialized = true;
            index = arc4random() % count;
        }
        currentIndex = index++ % count;
    }
    return classNameCollection[currentIndex];
}

+ (void)setUp    {
//    for(UIView *eachView in HMDSimpleSwiftObject.new.rootView.subviews) {
//        const char *tempSwiftClassName = object_getClassName(eachView);
//        printf("ClassName is: %s\n", tempSwiftClassName);
//    }
    HMDISAHookOptimization_initialization();
}
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

- (void)testCanSearchSwiftClass {
    Class aClass = objc_lookUpClass(self.randomClassName);
    XCTAssert(aClass != nil);
}

- (void)testAllocateClassPairWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testAllocateClassPairWork"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        Class NSObjectClass = NSObject.class;
        
        {
            Class aClass = objc_allocateClassPair(NSObjectClass, self.randomClassName, 0);
            XCTAssert(aClass == nil);
        }
        
        {
            
            const char *className = self.randomClassName;
            int value = HMDISAHookOptimization_before_objc_allocate_classPair();
            Class aClass = objc_allocateClassPair(NSObjectClass, className, 0);
            HMDISAHookOptimization_after_objc_allocate_classPair(value);
            XCTAssert(value != 0);
            XCTAssert(aClass != nil);
        }
        
        {
            Class aClass = objc_allocateClassPair(NSObjectClass, self.randomClassName, 0);
            XCTAssert(aClass == nil);
        }
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:6 handler:nil];
}

- (void)testMainThreadDoNotSearchSwiftClass {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"mainThreadDoNotSearchSwiftClass"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        {
            Class aClass = objc_lookUpClass(self.randomClassName);
            XCTAssert(aClass != nil);
        }
        
        {
            
            const char *className = self.randomClassName;
            int value = HMDISAHookOptimization_before_objc_allocate_classPair();
            Class aClass = objc_lookUpClass(className);
            HMDISAHookOptimization_after_objc_allocate_classPair(value);
            XCTAssert(value != 0);
            XCTAssert(aClass == nil);
        }
        
        {
            Class aClass = objc_lookUpClass(self.randomClassName);
            XCTAssert(aClass != nil);
        }
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:6 handler:nil];
}

- (void)testMainThreadDoSearchSwiftClass {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"mainThreadDoNotSearchSwiftClass"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        Class aClass = objc_lookUpClass(self.randomClassName);
        XCTAssert(aClass != nil);
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:6 handler:nil];
}

- (void)testMainThreadFakeX7DoNotSearchSwiftClass {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testMainThreadFakeX7DoNotSearchSwiftClass"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        const char *className = self.randomClassName;
        make_x7_happy();
        Class aClass = objc_lookUpClass(className);
        XCTAssert(aClass != nil);
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:6 handler:nil];
}

- (void)testOtherThreadDoNotSearchSwiftClass {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testOtherThreadDoNotSearchSwiftClass"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        XCTAssert(!NSThread.isMainThread);
        
        {
            Class aClass = objc_lookUpClass(self.randomClassName);
            XCTAssert(aClass != nil);
        }
        
        {
            
            const char *className = self.randomClassName;
            make_x7_happy();
            Class aClass = objc_lookUpClass(className);
            HMDISAHookOptimization_after_objc_allocate_classPair(0);
            XCTAssert(aClass != nil);
        }
        
        {
            Class aClass = objc_lookUpClass(self.randomClassName);
            XCTAssert(aClass != nil);
        }
        
        
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:6 handler:nil];
}

@end
