//
//  HMDProtectUnrecognizedSelectorTest.m
//  HeimdallrDemoTests
//
//  Created by bytedance on 2020/8/4.
//  Copyright © 2020 sunrunwang. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HMDProtector.h"
#import "HMDDynamicCall.h"
#import "HMDSwizzle.h"
#import "HMDProtect_Private.h"

@interface HMDProtectUnrecognizedSelectorTest : XCTestCase

@end

@implementation HMDProtectUnrecognizedSelectorTest

+ (void)setUp {
    HMDProtectTestEnvironment = YES;
    [HMDProtector.sharedProtector turnProtectionsOn:HMDProtectionTypeUnrecognizedSelector];
    HMDProtector.sharedProtector.ignoreTryCatch = NO;
}

+ (void)tearDown {
    HMDProtectTestEnvironment = NO;
    HMDProtector.sharedProtector.ignoreTryCatch = YES;
}

// 测试正常的 USEL 保护安全性
- (void)testNormalUSELProtect {
    NSValue *value = [NSValue valueWithCGRect:CGRectZero];
    NSString *notString = (NSString *)value;
    id mustNil = [notString stringByAppendingString:@"good"];
    XCTAssert(mustNil == nil);
}

- (void)testMemoryRangeOutFitForUSEL {
    NSString *str = [NSString stringWithFormat:@"HuaQ %p", self];
    
    vm_address_t address = 0x0;
    kern_return_t kr = vm_allocate(mach_task_self(), &address, vm_page_size * 2, VM_FLAGS_ANYWHERE);
    XCTAssert(kr == KERN_SUCCESS);
    
    kr = vm_protect(mach_task_self(), address + vm_page_size, vm_page_size, false, VM_PROT_WRITE);
    XCTAssert(kr == KERN_SUCCESS);
    
    uint8_t *storage = (uint8_t *)address;
    
    storage[vm_page_size - 2] = '1';
    storage[vm_page_size - 1] = '\0';
    
    id mustNil = ((id (*)(id, SEL))objc_msgSend)(str, (SEL)(storage + vm_page_size - 2));
    XCTAssert(mustNil == nil);
}

@end
