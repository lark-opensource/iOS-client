//
//  NSArray+AnimatedType.m
//  Modeo
//
//  Created by 马超 on 2020/12/30.
//

#import "NSArray+AnimatedType.h"
#import <objc/runtime.h>

@implementation NSArray (AnimatedType)

- (BOOL)animationTypeReciprocating
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setAnimationTypeReciprocating:(BOOL)animationTypeReciprocating
{
    objc_setAssociatedObject(self, @selector(animationTypeReciprocating), @(animationTypeReciprocating), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)animationImageVID
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setAnimationImageVID:(NSString *)animationImageVID
{
    objc_setAssociatedObject(self, @selector(animationImageVID), animationImageVID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)animatedImage
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setAnimatedImage:(BOOL)animatedImage
{
    objc_setAssociatedObject(self, @selector(animatedImage), @(animatedImage), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end
