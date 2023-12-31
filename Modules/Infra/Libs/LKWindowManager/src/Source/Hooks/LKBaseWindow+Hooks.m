//
//  PushCard+Hooks.m
//  LarkPushCard
//
//  Created by 白镜吾 on 2022/10/26.
//

#import "LKBaseWindow+Hooks.h"
#import <objc/runtime.h>

@implementation LKBaseWindow

- (BOOL)shouldAffectStatusBarAppearance {
    return NO;
}

- (BOOL)canBecomeKeyWindow {
    return NO;
}

+ (void)initialize {
    [self swizzlingCanAffectStatusBarAppearance];
    [self swizzlingCanBecomeKeyWindow];
}

#pragma mark - Hook Funcs

/// Hook canAffectStatusBarAppearance
+ (void)swizzlingCanAffectStatusBarAppearance {
    NSString *canAffectSelectorString = [@[@"_can", @"Affect", @"Status", @"Bar", @"Appearance"] componentsJoinedByString:@""];
    SEL canAffectSelector = NSSelectorFromString(canAffectSelectorString);
    Method shouldAffectMethod = class_getInstanceMethod(self, @selector(shouldAffectStatusBarAppearance));
    IMP canAffectImplementation = method_getImplementation(shouldAffectMethod);
    class_addMethod(self, canAffectSelector, canAffectImplementation, method_getTypeEncoding(shouldAffectMethod));
}

/// Hook canBecomeKeyWindow
+ (void)swizzlingCanBecomeKeyWindow {
    NSString *canBecomeKeySelectorString = [NSString stringWithFormat:@"_%@", NSStringFromSelector(@selector(canBecomeKeyWindow))];
    SEL canBecomeKeySelector = NSSelectorFromString(canBecomeKeySelectorString);
    Method canBecomeKeyMethod = class_getInstanceMethod(self, @selector(canBecomeKeyWindow));
    IMP canBecomeKeyImplementation = method_getImplementation(canBecomeKeyMethod);
    class_addMethod(self, canBecomeKeySelector, canBecomeKeyImplementation, method_getTypeEncoding(canBecomeKeyMethod));
}

@end
