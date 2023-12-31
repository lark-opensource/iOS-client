//
//  UIView+BubbleAnimation.m
//  Aweme
//
//  Created by 熊典 on 2017/7/7.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "ACCBubbleAnimationManager.h"

@implementation UIView (ACCBubbleAnimation)

- (void)acc_bubbleAnimate:(void (^)(ACCBubbleAnimation *))animations
           completion:(void (^)(void))completion{
    [[ACCBubbleAnimationManager sharedManager] runAnimationWithBubble:self
                                                           animations:animations
                                                           completion:completion];
}

- (void)acc_bubbleAnimate:(void (^)(ACCBubbleAnimation *))animations {
    [self acc_bubbleAnimate:animations completion:nil];
}

- (void)acc_removeBubbleAnimates {
    [[ACCBubbleAnimationManager sharedManager] removeAnimationsForBubble:self];
}

@end
