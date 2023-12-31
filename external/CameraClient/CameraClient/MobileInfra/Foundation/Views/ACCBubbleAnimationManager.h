//
//  ACCBubbleAnimationManager.h
//  Aweme
//
//  Created by 熊典 on 2017/7/7.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACCBubbleAnimation.h"
#import "UIView+ACCBubbleAnimation.h"

@interface ACCBubbleAnimationManager : NSObject

+ (instancetype)sharedManager;

- (ACCBubbleAnimation *)runAnimationWithBubble:(UIView *)bubble
                                    animations:(void(^)(ACCBubbleAnimation * animation))animations
                                    completion:(void(^)(void))completion;

- (void)removeAnimationsForBubble:(UIView *)bubble;

@end
