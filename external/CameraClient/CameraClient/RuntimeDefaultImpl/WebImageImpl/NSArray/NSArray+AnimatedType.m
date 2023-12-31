//
//  NSArray+AnimatedType.m
//  Modeo
//
//  Created by 马超 on 2020/12/30.
//

#import "NSArray+AnimatedType.h"
#import <objc/runtime.h>

@implementation NSArray (AnimatedType)

- (BOOL)acc_animationTypeReciprocating
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setAcc_animationTypeReciprocating:(BOOL)acc_animationTypeReciprocating
{
    objc_setAssociatedObject(self, @selector(acc_animationTypeReciprocating), @(acc_animationTypeReciprocating), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)acc_animationImageVID
{
    return objc_getAssociatedObject(self, _cmd);
}
- (void)setAcc_animationImageVID:(NSString *)acc_animationImageVID
{
    objc_setAssociatedObject(self, @selector(acc_animationImageVID), acc_animationImageVID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)acc_animatedImage
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setAcc_animatedImage:(BOOL)acc_animatedImage
{
    objc_setAssociatedObject(self, @selector(acc_animatedImage), @(acc_animatedImage), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end
