//
//  BaseTestCase.m
//  LarkRustHTTPDevEEUnitTest
//
//  Created by SolaWing on 2019/7/21.
//

#import "BaseTestCase.h"

@implementation BaseTestCase

+ (NSArray<NSInvocation *> *)testInvocations {
    NSArray* selectors = [self testSelectors];
    if (selectors) {
        NSMutableArray* result = [[NSMutableArray alloc] initWithCapacity:selectors.count];
        for (NSString* name in selectors) {
            SEL sel = NSSelectorFromString(name);
            NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:[self instanceMethodSignatureForSelector:sel]];
            invocation.selector = sel;
            [result addObject:invocation];
        }
        return result;
    }
    return [super testInvocations];
}

+ (nullable NSArray<NSString*>*)testSelectors {
    return nil;
}

@end
