//
//  UIImageView+ACCAddtions.m
//  Pods
//
// Created by Hao Yipeng on December 10, 2019
//

#import "UIImageView+ACCAddtions.h"
#import "NSObject+ACCSwizzle.h"
#import <objc/runtime.h>

@implementation UIImageView (ACCAddtions)

+ (void)load
{
    [self acc_swizzleMethodsOfClass:self originSelector:@selector(pointInside:withEvent:) targetSelector:@selector(acc_pointInside:withEvent:)];
}

- (void)setAcc_hitTestEdgeInsets:(UIEdgeInsets)hitTestEdgeInsets
{
    NSValue *value = [NSValue valueWithUIEdgeInsets:hitTestEdgeInsets];
    objc_setAssociatedObject(self, @selector(acc_hitTestEdgeInsets), value, OBJC_ASSOCIATION_RETAIN);
}

- (UIEdgeInsets)acc_hitTestEdgeInsets
{
    NSValue *value = objc_getAssociatedObject(self, @selector(acc_hitTestEdgeInsets));
    if (value) {
        return [value UIEdgeInsetsValue];
    } else {
        return UIEdgeInsetsZero;
    }
}

- (BOOL)acc_pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    UIEdgeInsets hitTestEdgeInsets = self.acc_hitTestEdgeInsets;
    if (UIEdgeInsetsEqualToEdgeInsets(hitTestEdgeInsets, UIEdgeInsetsZero) || self.hidden || !self.alpha) {
        return [self acc_pointInside:point withEvent:event];
    }
    CGRect hitFrame = UIEdgeInsetsInsetRect(self.bounds, hitTestEdgeInsets);
    return CGRectContainsPoint(hitFrame, point);
}

@end
