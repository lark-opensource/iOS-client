//
//  ACCBubbleAnimation.h
//  Aweme
//
//  Created by 熊典 on 2017/7/6.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ACCBubbleDefinition.h"

#import "ACCBubbleAnimationTimingFunction.h"

@interface ACCBubbleAnimation : NSObject

@property (nonatomic, strong) UIView *bubble;

// Initializations
- (instancetype)initWithBubble:(UIView *)bubble;


// Animations
- (ACCBubbleAnimation * (^)(CGFloat offsetX, CGFloat offsetY, CGFloat duration))move;

- (ACCBubbleAnimation * (^)(CGFloat duration))reveal;

- (ACCBubbleAnimation * (^)(CGFloat scale, CGFloat duration))scale;

- (ACCBubbleAnimation * (^)(CGFloat duration))dismiss;

- (ACCBubbleAnimation * (^)(CGFloat duration))sleep;

- (ACCBubbleAnimation * (^)(CGFloat degree, CGFloat duration))rotateTo;

- (ACCBubbleAnimation * (^)(NSInteger repeat))loop;

- (ACCBubbleAnimation *(^)(void))loopStart;

- (ACCBubbleAnimation * (^)(NSInteger count))parallel;

- (ACCBubbleAnimation *(^)(kACCBubbleAnimationTimingFunctionName *timingFunctionName))timing;

- (ACCBubbleAnimation *(^)(float c1x, float c1y, float c2x, float c2y))bezierTiming;
   
// Run
- (void(^)(void))run;

- (void(^)(void))run:(void(^)(void))completion;

- (void(^)(void))stop;

@end
