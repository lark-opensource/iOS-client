//
//  UIView+ACCBubbleAnimation.h
//  Aweme
//
//  Created by 熊典 on 2017/7/7.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACCBubbleAnimation.h"

@interface UIView (ACCBubbleAnimation)

- (void)acc_bubbleAnimate:(void (^)(ACCBubbleAnimation * animation))animations
           completion:(void(^)(void))completion;

- (void)acc_bubbleAnimate:(void (^)(ACCBubbleAnimation * animation))animations;

- (void)acc_removeBubbleAnimates;

@end
