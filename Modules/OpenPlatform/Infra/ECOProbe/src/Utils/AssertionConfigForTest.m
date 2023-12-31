//
//  AssertionConfigForTest.m
//  ECOProbe
//
//  Created by baojianjun on 2022/12/16.
//

#import "AssertionConfigForTest.h"

@interface AssertionConfigForTest ()

@end

BOOL enable = NO;
@implementation AssertionConfigForTest

+ (BOOL)isEnable {
    return enable;
}

+ (void)reset {
    enable = YES;
}

+ (void)disableAssertWhenTesting {
    if (![self isTesting]) {
        NSAssert(NO, @"can not disable assert not being test");
        return;
    }
    enable = NO;
}

+ (BOOL)isTesting {
    return [[NSProcessInfo.processInfo.environment objectForKey:@"IS_TESTING_OPEN_PLATFORM_SDK"] isEqualToString:@"1"];
}

@end
