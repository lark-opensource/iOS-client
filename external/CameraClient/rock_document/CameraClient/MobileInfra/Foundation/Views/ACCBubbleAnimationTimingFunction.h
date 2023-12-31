//
//  ACCBubbleAnimationTimingFunction.h
//  Aweme
//
//  Created by 熊典 on 2017/7/18.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

typedef NSString kACCBubbleAnimationTimingFunctionName;

FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionDefault;
FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionLinear;

FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionEaseIn;
FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionEaseOut;
FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionEaseInEaseOut;

FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionQuadraticEaseIn;
FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionQuadraticEaseOut;
FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionQuadraticEaseInEaseOut;

FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionCubicEaseIn;
FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionCubicEaseOut;
FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionCubicEaseInEaseOut;

FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionQuarticEaseIn;
FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionQuarticEaseOut;
FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionQuarticEaseInEaseOut;

FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionQuinticEaseIn;
FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionQuinticEaseOut;
FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionQuinticEaseInEaseOut;

FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionSineEaseIn;
FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionSineEaseOut;
FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionSineEaseInEaseOut;

FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionExpoEaseIn;
FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionExpoEaseOut;
FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionExpoEaseInEaseOut;

FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionBackEaseIn;
FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionBackEaseOut;
FOUNDATION_EXTERN NSString * const kACCBubbleAnimationTimingFunctionBackEaseInEaseOut;


@interface ACCBubbleAnimationTimingFunction : NSObject

+ (CAMediaTimingFunction *)timingFunctionWithName:(kACCBubbleAnimationTimingFunctionName *)name;

@end
