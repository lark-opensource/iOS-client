//
//  BDFishhookTests.m
//  BDFishhookTests
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
#import <BDFishhook/BDFishhook.h>

@interface BDFishhookTests : XCTestCase

@end

@implementation BDFishhookTests

+ (void)setUp    { /* 在所有测试前调用一次 */ }
+ (void)tearDown { /* 在所有测试后调用一次 */ }
- (void)setUp    { /* 在每次 -[ test_xxx] 方法前调用 */ }
- (void)tearDown { /* 在每次 -[ test_xxx] 方法后调用 */ }

- (void)test_BDFishhook_patch {
#if __arm64__ && __LP64__
    if(@available(iOS 16.0, *)) {
    } else {
        return;
    }
    [self actual_patch_test];
#else
    return;
#endif
}

static BOOL enable_cxa_longjump = NO;

typedef void (*cxa_func_t)(void *, void *, void *);

static cxa_func_t origin_cxa_throw = NULL;

static jmp_buf long_jump_buffer;

static void my_cxa_throw(void *value1, void *value2, void *value3) {
    if(!enable_cxa_longjump) {
        XCTAssert(origin_cxa_throw != NULL);
        if(origin_cxa_throw == NULL)
            return;
        origin_cxa_throw(value1, value2, value3);
        XCTAssert(NO, "Heimdallr BDFishhook Patch Table Test reach unreachable code 01");
        return;
    }
    longjmp(long_jump_buffer, 666);
}

- (void)actual_patch_test {
    
    struct bd_rebinding binds[1] = {
        [0] = {
            .name = "__cxa_throw",
            .replacement = my_cxa_throw,
            .replaced = (void **)&origin_cxa_throw
        },
    };
    
    open_bdfishhook();
    open_bdfishhook_patch();
    bd_rebind_symbols_patch(binds, 1);
    
    int code = setjmp(long_jump_buffer);
    
    if(code != 0) {
        // success
        fprintf(stdout, "[CXA] patch table hook test complete with code %d\n", code);
        enable_cxa_longjump = NO;
        return;
    }
    
    NSException *exception =
        [NSException exceptionWithName:@"Heimdallr BDFishhook Patch Table Test"
                                reason:@"Heimdallr BDFishhook Patch Table Test"
                              userInfo:nil];
    
    enable_cxa_longjump = YES;
    void objc_exception_throw(id _Nonnull exception);
    objc_exception_throw(exception);
    enable_cxa_longjump = NO;
    XCTAssert(NO, "Heimdallr BDFishhook Patch Table Test reach unreachable code 02");
}

@end
