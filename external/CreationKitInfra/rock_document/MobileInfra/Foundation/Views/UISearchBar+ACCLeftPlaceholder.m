//
//  UISearchBar+ACCLeftPlaceholder.m
//  CameraClient
//
//  Copyright © 2017 Bytedance. All rights reserved.
//

#import "UISearchBar+ACCLeftPlaceholder.h"

@implementation UISearchBar (ACCLeftPlaceholder)

- (void)acc_setLeftPlaceholder:(NSString *)placeholder
{
    self.placeholder = placeholder;
    SEL centerSelector = NSSelectorFromString([NSString stringWithFormat:@"%@%@", @"setCenter", @"Placeholder:"]);
    if ([self respondsToSelector:centerSelector]) {
        BOOL centeredPlaceholder = NO;
        NSMethodSignature *signature = [[UISearchBar class] instanceMethodSignatureForSelector:centerSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:self];
        [invocation setSelector:centerSelector];
        [invocation setArgument:&centeredPlaceholder atIndex:2];
        [invocation invoke];
    }
}

@end
