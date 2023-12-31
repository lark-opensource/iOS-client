//
//  ACCBubbleAnimationTimingFunction.m
//  Aweme
//
//  Created by 熊典 on 2017/7/18.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "ACCBubbleAnimationTimingFunction.h"

static NSMutableDictionary *ACCBubbleAnimationTimingFunctionAnimations;

NSString * const kACCBubbleAnimationTimingFunctionDefault = @"kACCBubbleAnimationTimingFunctionDefault";
NSString * const kACCBubbleAnimationTimingFunctionLinear = @"kACCBubbleAnimationTimingFunctionLinear";

NSString * const kACCBubbleAnimationTimingFunctionEaseIn = @"kACCBubbleAnimationTimingFunctionEaseIn";
NSString * const kACCBubbleAnimationTimingFunctionEaseOut = @"kACCBubbleAnimationTimingFunctionEaseOut";
NSString * const kACCBubbleAnimationTimingFunctionEaseInEaseOut = @"kACCBubbleAnimationTimingFunctionEaseInEaseOut";

NSString * const kACCBubbleAnimationTimingFunctionQuadraticEaseIn = @"kACCBubbleAnimationTimingFunctionQuadraticEaseIn";
NSString * const kACCBubbleAnimationTimingFunctionQuadraticEaseOut = @"kACCBubbleAnimationTimingFunctionQuadraticEaseOut";
NSString * const kACCBubbleAnimationTimingFunctionQuadraticEaseInEaseOut = @"kACCBubbleAnimationTimingFunctionQuadraticEaseInEaseOut";

NSString * const kACCBubbleAnimationTimingFunctionCubicEaseIn = @"kACCBubbleAnimationTimingFunctionCubicEaseIn";
NSString * const kACCBubbleAnimationTimingFunctionCubicEaseOut = @"kACCBubbleAnimationTimingFunctionCubicEaseOut";
NSString * const kACCBubbleAnimationTimingFunctionCubicEaseInEaseOut = @"kACCBubbleAnimationTimingFunctionCubicEaseInEaseOut";

NSString * const kACCBubbleAnimationTimingFunctionQuarticEaseIn = @"kACCBubbleAnimationTimingFunctionQuarticEaseIn";
NSString * const kACCBubbleAnimationTimingFunctionQuarticEaseOut = @"kACCBubbleAnimationTimingFunctionQuarticEaseOut";
NSString * const kACCBubbleAnimationTimingFunctionQuarticEaseInEaseOut = @"kACCBubbleAnimationTimingFunctionQuarticEaseInEaseOut";

NSString * const kACCBubbleAnimationTimingFunctionQuinticEaseIn = @"kACCBubbleAnimationTimingFunctionQuinticEaseIn";
NSString * const kACCBubbleAnimationTimingFunctionQuinticEaseOut = @"kACCBubbleAnimationTimingFunctionQuinticEaseOut";
NSString * const kACCBubbleAnimationTimingFunctionQuinticEaseInEaseOut = @"kACCBubbleAnimationTimingFunctionQuinticEaseInEaseOut";

NSString * const kACCBubbleAnimationTimingFunctionSineEaseIn = @"kACCBubbleAnimationTimingFunctionSineEaseIn";
NSString * const kACCBubbleAnimationTimingFunctionSineEaseOut = @"kACCBubbleAnimationTimingFunctionSineEaseOut";
NSString * const kACCBubbleAnimationTimingFunctionSineEaseInEaseOut = @"kACCBubbleAnimationTimingFunctionSineEaseInEaseOut";

NSString * const kACCBubbleAnimationTimingFunctionCircularEaseIn = @"kACCBubbleAnimationTimingFunctionCircularEaseIn";
NSString * const kACCBubbleAnimationTimingFunctionCircularEaseOut = @"kACCBubbleAnimationTimingFunctionCircularEaseOut";
NSString * const kACCBubbleAnimationTimingFunctionCircularEaseInEaseOut = @"kACCBubbleAnimationTimingFunctionCircularEaseInEaseOut";

NSString * const kACCBubbleAnimationTimingFunctionExpoEaseIn = @"kACCBubbleAnimationTimingFunctionExpoEaseIn";
NSString * const kACCBubbleAnimationTimingFunctionExpoEaseOut = @"kACCBubbleAnimationTimingFunctionExpoEaseOut";
NSString * const kACCBubbleAnimationTimingFunctionExpoEaseInEaseOut = @"kACCBubbleAnimationTimingFunctionExpoEaseInEaseOut";

NSString * const kACCBubbleAnimationTimingFunctionBackEaseIn = @"kACCBubbleAnimationTimingFunctionBackEaseIn";
NSString * const kACCBubbleAnimationTimingFunctionBackEaseOut = @"kACCBubbleAnimationTimingFunctionBackEaseOut";
NSString * const kACCBubbleAnimationTimingFunctionBackEaseInEaseOut = @"kACCBubbleAnimationTimingFunctionBackEaseInEaseOut";

@implementation ACCBubbleAnimationTimingFunction

+ (void)setupAnimationsIfNeeded {
    if (!ACCBubbleAnimationTimingFunctionAnimations) {
        ACCBubbleAnimationTimingFunctionAnimations = [NSMutableDictionary dictionary];
        
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionDefault] = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionLinear] = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionEaseIn] = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionEaseOut] = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionEaseInEaseOut] = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionQuadraticEaseIn] = [[CAMediaTimingFunction alloc] initWithControlPoints:0.26 :0 :0.6 :0.2];
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionQuadraticEaseOut] = [[CAMediaTimingFunction alloc] initWithControlPoints:0.4 :0.8 :0.74 :1];
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionQuadraticEaseInEaseOut] = [[CAMediaTimingFunction alloc] initWithControlPoints:0.48 :0.04 :0.52 :0.96];
        
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionCubicEaseIn] = [[CAMediaTimingFunction alloc] initWithControlPoints:0.4 :0 :0.68 :0.06];
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionCubicEaseOut] = [[CAMediaTimingFunction alloc] initWithControlPoints:0.32 :0.94 :0.6 :1];
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionCubicEaseInEaseOut] = [[CAMediaTimingFunction alloc] initWithControlPoints:0.66 :0 :0.34 :1];
        
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionQuarticEaseIn] = [[CAMediaTimingFunction alloc] initWithControlPoints:0.52 :0 :0.74 :0];
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionQuarticEaseOut] = [[CAMediaTimingFunction alloc] initWithControlPoints:0.26 :1 :0.48 :1];
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionQuarticEaseInEaseOut] = [[CAMediaTimingFunction alloc] initWithControlPoints:0.76 :0 :0.24 :1];
        
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionQuinticEaseIn] = [[CAMediaTimingFunction alloc] initWithControlPoints:0.64 :0 :0.78 :0];
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionQuinticEaseOut] = [[CAMediaTimingFunction alloc] initWithControlPoints:0.22 :1 :0.36 :1];
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionQuinticEaseInEaseOut] = [[CAMediaTimingFunction alloc] initWithControlPoints:0.84 :0 :0.16 :1];
        
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionSineEaseIn] = [[CAMediaTimingFunction alloc] initWithControlPoints:0.47 :0 :0.745 :0.715];
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionSineEaseOut] = [[CAMediaTimingFunction alloc] initWithControlPoints:0.39 :0.575 :0.565 :1];
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionSineEaseInEaseOut] = [[CAMediaTimingFunction alloc] initWithControlPoints:0.445 :0.05 :0.55 :0.95];
        
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionCircularEaseIn] = [[CAMediaTimingFunction alloc] initWithControlPoints:0.54 :0 :1 :0.44];
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionCircularEaseOut] = [[CAMediaTimingFunction alloc] initWithControlPoints:0 :0.56 :0.46 :1];
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionCircularEaseInEaseOut] = [[CAMediaTimingFunction alloc] initWithControlPoints:0.88 :0.14 :0.12 :0.86];
        
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionExpoEaseIn] = [[CAMediaTimingFunction alloc] initWithControlPoints:0.66 :0 :0.86 :0];
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionExpoEaseOut] = [[CAMediaTimingFunction alloc] initWithControlPoints:0.14 :1 :0.34 :1];
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionExpoEaseInEaseOut] = [[CAMediaTimingFunction alloc] initWithControlPoints:0.9 :0 :0.1 :1];
        
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionBackEaseIn] = [[CAMediaTimingFunction alloc] initWithControlPoints:0.6 :-0.28 :0.73 :0.04];
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionBackEaseOut] = [[CAMediaTimingFunction alloc] initWithControlPoints:0.17 :0.89 :0.32 :1.27];
        ACCBubbleAnimationTimingFunctionAnimations[kACCBubbleAnimationTimingFunctionBackEaseInEaseOut] = [[CAMediaTimingFunction alloc] initWithControlPoints:0.68 :-0.55 :0.27 :1.55];
    }
}

+ (CAMediaTimingFunction *)timingFunctionWithName:(kACCBubbleAnimationTimingFunctionName *)name {
    [self setupAnimationsIfNeeded];
    return ACCBubbleAnimationTimingFunctionAnimations[name];
}

@end
