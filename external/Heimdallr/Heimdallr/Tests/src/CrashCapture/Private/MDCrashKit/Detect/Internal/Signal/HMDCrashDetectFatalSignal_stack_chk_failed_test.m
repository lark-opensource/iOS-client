//
//  HMDCrashDetectFatalSignal_stack_chk_failed_test.m
//  HMDCrashDetectFatalSignal_stack_chk_failed_test
//
//  Created by bytedance on 2020/8/4.
//  Copyright © 2020 bytedance. All rights reserved.
//

#include <setjmp.h>
#include <objc/objc.h>
#include <objc/runtime.h>
#include <objc/message.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDMacro.h"
#import "HMDSwizzle.h"
#import "HMDDynamicCall.h"

#ifdef DEBUG

// 用于 DEBUG 环境单元测试校验正常运行

// stack_chk_failed_called 是否被正常调用
bool HMDSignal_debug_stack_chk_failed_called = false;

// stack_chk_failed_ignore 是否忽略此次崩溃
typedef void (*HMDSignal_debug_callback_t)(void);
HMDSignal_debug_callback_t HMDSignal_debug_stack_chk_failed_callback = NULL;

#endif

@interface HMDCrashDetectFatalSignal_stack_chk_failed_test : XCTestCase

@end

@implementation HMDCrashDetectFatalSignal_stack_chk_failed_test

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

static bool stack_check_failed_caught = false;

- (void)test_stack_check_failed_called {
    
#ifdef DEBUG
    HMDSignal_debug_stack_chk_failed_called = false;
    HMDSignal_debug_stack_chk_failed_callback = stack_chk_failed_callback;
#else
    return;
#endif
    
    stack_check_failed_caught = false;
    
    jump_location();
    
    XCTAssert(stack_check_failed_caught);
    
    GCC_FORCE_NO_OPTIMIZATION
}

static jmp_buf current_environment;

static void jump_location(void) {
    
    int code = setjmp(current_environment);
    
    if(code == 0) {
        fprintf(stdout, "[CSF] first time, now try to detect\n");
        previous_stack_guard_content();
    } else {
        fprintf(stdout, "[CSF] next time, finished with code: %d\n", code);
    }
    
    GCC_FORCE_NO_OPTIMIZATION
}

static void previous_stack_guard_content(void) {
    uint8_t *content = __builtin_alloca(1024 * 2);
    memset(content, '6', 1024 * 2);
    
    create_stack_chk_failed();
    
    GCC_FORCE_NO_OPTIMIZATION
}

static void create_stack_chk_failed(void) {
    
    int four = strlen("1234");
    
    int length = 200 + four;
    
    void *pointerArray[length];
    
    stack_write_down_flow(pointerArray);
    
    fprintf(stderr, "[SCF] will check stack down flow\n");
    
    GCC_FORCE_NO_OPTIMIZATION
}

static void stack_write_down_flow(void *pointerArray[]) {
    
    int four = strlen("1234");
    
#if __arm64__ && __LP64__
    
    int length = 200 + four + 10;
    
    for(int index = 0; index < length; index++) {
        uint64_t value = UINT64_C(0xFEDCBA9876543210);
        pointerArray[index] = (void *)value;
    }
    
#else
    
    int length = 200 + four;
    
    for(int index = 0; index < length; index++) {
        uint64_t value = UINT64_C(0xFEDCBA9876543210);
        pointerArray[index] = (void *)value;
    }
    
    pointerArray[200 + four + 3] = (void *)UINT64_C(0xFEDCBA9876543210);
    // pointerArray[200 + four + 4] = UINT64_C(0xFEDCBA9876543210); stack cracked
    
#endif
    
    fprintf(stderr, "[SCF] now stack cracked\n");

    GCC_FORCE_NO_OPTIMIZATION
}

static void stack_chk_failed_callback(void) {
    stack_check_failed_caught = true;
    
    longjmp(current_environment, 10086);
    
    GCC_FORCE_NO_OPTIMIZATION
}

@end
