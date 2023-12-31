//
//  ACCBubbleAnimation.m
//  Aweme
//
//  Created by 熊典 on 2017/7/6.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/CALayer+ACCRTL.h>
#include <pthread.h>
#import "ACCBubbleAnimation+Private.h"
#import <pop/POPBasicAnimation.h>

@implementation ACCBubbleAnimation

- (instancetype)initWithBubble:(UIView *)bubble {
    self = [self init];
    if (self) {
        self.bubble = bubble;
        self.timingFunction = [ACCBubbleAnimationTimingFunction timingFunctionWithName:kACCBubbleAnimationTimingFunctionEaseInEaseOut];
        pthread_mutex_init(&_lock, NULL);
    }
    return self;
}

- (void)dealloc{
    pthread_mutex_destroy(&_lock);
}

- (ACCBubbleAnimation *)nextAnimationWithCurrentConfig {
    ACCBubbleAnimation *nextAnimation = [[ACCBubbleAnimation alloc] initWithBubble:self.bubble];
    nextAnimation.loopModeFlag = self.loopModeFlag;
    nextAnimation.previousAnimation = self;
    nextAnimation.timingFunction = self.timingFunction;
    return nextAnimation;
}

- (ACCBubbleAnimation *(^)(CGFloat, CGFloat, CGFloat))move {
    return ^id(CGFloat tx, CGFloat ty, CGFloat duration) {
        @weakify(self);
        self.animationBlock = ^(UIView *bubble, void(^completion)(void)) {
            @strongify(self);
            POPBasicAnimation *animation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewCenter];
            animation.toValue = [NSValue valueWithCGPoint:CGPointMake(bubble.center.x + tx, bubble.center.y + ty)];
            animation.duration = duration;
            animation.timingFunction = self.timingFunction;
            animation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
                ACCBLOCK_INVOKE(completion);
            };
            [bubble pop_addAnimation:animation forKey:@"center"];
            
            self.bubble = bubble;
        };
        self.nextAnimation = [self nextAnimationWithCurrentConfig];
        return self.nextAnimation;
    };
}

- (ACCBubbleAnimation *(^)(CGFloat))sleep {
    return ^id(CGFloat duration) {
        @weakify(self);
        self.animationBlock = ^(UIView *bubble, void(^completion)(void)) {
            @strongify(self);
            self.bubble = bubble;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                ACCBLOCK_INVOKE(completion);
            });
        };
        self.nextAnimation = [self nextAnimationWithCurrentConfig];
        return self.nextAnimation;
    };
}

- (ACCBubbleAnimation *(^)(CGFloat, CGFloat))rotateTo {
    return ^id(CGFloat degree, CGFloat duration) {
        @weakify(self);
        self.animationBlock = ^(UIView *bubble, void(^completion)(void)) {
            @strongify(self);
            POPBasicAnimation *animation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerRotation];
            animation.toValue = @(degree / 180.0f * M_PI);
            animation.duration = duration;
            animation.timingFunction = self.timingFunction;
            animation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
                ACCBLOCK_INVOKE(completion);
            };
            [bubble pop_addAnimation:animation forKey:@"rotation"];
            
            self.bubble = bubble;
        };
        self.nextAnimation = [self nextAnimationWithCurrentConfig];
        return self.nextAnimation;
    };
}

- (ACCBubbleAnimation *(^)(CGFloat))reveal {
    return ^id(CGFloat duration) {
        @weakify(self);
        self.animationBlock = ^(UIView *bubble, void(^completion)(void)) {
            @strongify(self);
            POPBasicAnimation *animation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
            animation.fromValue = @0;
            animation.toValue = @1;
            animation.duration = duration;
            animation.timingFunction = self.timingFunction;
            animation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
                ACCBLOCK_INVOKE(completion);
            };
            [bubble pop_addAnimation:animation forKey:@"alpha"];
            
            self.bubble = bubble;
        };
        self.nextAnimation = [self nextAnimationWithCurrentConfig];
        return self.nextAnimation;
    };
}

- (ACCBubbleAnimation *(^)(CGFloat))dismiss {
    return ^id(CGFloat duration) {
        @weakify(self);
        self.animationBlock = ^(UIView *bubble, void(^completion)(void)) {
            @strongify(self);
            POPBasicAnimation *animation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
            animation.fromValue = @1;
            animation.toValue = @0;
            animation.duration = duration;
            animation.timingFunction = self.timingFunction;
            animation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
                ACCBLOCK_INVOKE(completion);
            };
            [bubble pop_addAnimation:animation forKey:@"alpha"];
            
            self.bubble = bubble;
        };
        self.nextAnimation = [self nextAnimationWithCurrentConfig];
        return self.nextAnimation;
    };
}

- (ACCBubbleAnimation *(^)(CGFloat, CGFloat))scale {
    return ^id(CGFloat scale, CGFloat duration) {
        @weakify(self);
        self.animationBlock = ^(UIView *bubble, void(^completion)(void)) {
            @strongify(self);
            //如果是阿拉伯语下，且bubble的transform.a为-1，则pop动画的scale应该是(-scale, -scale)
            double scaleFactor = 1;
            if (bubble.layer.accrtl_basicTransform.a == -1) {
                scaleFactor = -1;
            }
            POPBasicAnimation *animation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewScaleXY];
            animation.toValue = [NSValue valueWithCGPoint:CGPointMake(scale * scaleFactor, scale * scaleFactor)];
            animation.duration = duration;
            animation.timingFunction = self.timingFunction;
            animation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
                ACCBLOCK_INVOKE(completion);
            };
            [bubble pop_addAnimation:animation forKey:@"scaleXY"];
            
            self.bubble = bubble;
        };
        self.nextAnimation = [self nextAnimationWithCurrentConfig];
        return self.nextAnimation;
    };
}

- (ACCBubbleAnimation *(^)(NSInteger))loop {
    return ^id(NSInteger repeat) {
        @weakify(self);
        self.animationBlock = ^(UIView *bubble, void(^completion)(void)) {
            @strongify(self);
            if (!self.loopModeFlag) {
                self.loopRepeat = repeat - 1;
            }
            self.bubble = bubble;
            
            ACCBLOCK_INVOKE(completion);
        };
        self.nextAnimation = [self nextAnimationWithCurrentConfig];
        return self.nextAnimation;
    };
}

- (ACCBubbleAnimation *(^)(void))loopStart {
    return ^id() {
        @weakify(self);
        self.animationBlock = ^(UIView *bubble, void(^completion)(void)) {
            @strongify(self);
            self.loopStartFlag = YES;
            self.bubble = bubble;
            
            ACCBLOCK_INVOKE(completion);
        };
        self.nextAnimation = [self nextAnimationWithCurrentConfig];
        return self.nextAnimation;
    };
}

- (ACCBubbleAnimation *(^)(NSInteger))parallel {
    return ^id(NSInteger count) {
        @weakify(self);
        self.animationBlock = ^(UIView *bubble, void(^completion)(void)) {
            @strongify(self);
            self.parallelsCount = count;
            self.bubble = bubble;
            
            ACCBLOCK_INVOKE(completion);
        };
        self.nextAnimation = [self nextAnimationWithCurrentConfig];
        return self.nextAnimation;
    };
}

- (void (^)(void))run {
    return [self run:nil];
}

- (void (^)(void))run:(void (^)(void))completion {
    return [self run:completion inLoopMode:NO noForward:NO];
}

- (void (^)(void))run:(void (^)(void))completion inLoopMode:(BOOL)loopMode noForward:(BOOL)noForward{
    return ^{
        self.loopModeFlag = loopMode;
        if (!noForward && self.previousAnimation && (!loopMode || !self.loopStartFlag)) {
            [self.previousAnimation run:completion inLoopMode:loopMode noForward:noForward]();
        } else {
            [self _run:completion];
        }
    };
}

- (void)_run:(void (^)(void))completion {
    if (self.shouldStop) {
        ACCBLOCK_INVOKE(completion);
        return;
    }
    if (self.animationBlock) {
        self.animationBlock(self.bubble, ^{
            if (self.loopRepeat) {
                self.loopRepeat--;
                [self run:completion inLoopMode:YES noForward:NO]();
            } else {
                if (self.parallelsCount > 1) {
                    NSMutableArray *animations = [NSMutableArray arrayWithCapacity:self.parallelsCount];
                    ACCBubbleAnimation *currentAnimation = self;
                    for (NSInteger i = 0; i < self.parallelsCount; i++) {
                        currentAnimation = currentAnimation.nextAnimation;
                        if (currentAnimation) {
                            [animations addObject:currentAnimation];
                        } else {
                            break;
                        }
                    }
                    [self _runParallel:animations
                            afterwards:^{
                                ACCBubbleAnimation *nextAnimation = currentAnimation.nextAnimation;
                                if (nextAnimation) {
                                    [nextAnimation _run:completion];
                                } else {
                                    ACCBLOCK_INVOKE(completion);
                                }
                            }];
                } else {
                    if (self.nextAnimation) {
                        self.nextAnimation.timingFunction = self.timingFunction;
                        [self.nextAnimation _run:completion];
                    } else {
                        ACCBLOCK_INVOKE(completion);
                    }
                }
            }
        });
    } else {
        ACCBLOCK_INVOKE(completion);
    }
}

- (void)_runParallel:(NSArray<ACCBubbleAnimation *> *)animations
          afterwards:(void(^)(void))afterwards{
    NSMutableArray *completed = [NSMutableArray array];
    void (^checkFinish)(void) = ^{
        for (NSInteger i = 0; i < completed.count; i++) {
            if ([completed[i] integerValue] == 0) {
                return;
            }
        }
        ACCBLOCK_INVOKE(afterwards);
    };
    for (NSInteger i = 0; i < animations.count; i++) {
        [completed addObject:@0];
        animations[i].animationBlock(animations[i].bubble, ^{
            completed[i] = @1;
            pthread_mutex_lock(&self->_lock);
            checkFinish();
            pthread_mutex_unlock(&self->_lock);
        });
    }
}

- (ACCBubbleAnimation *(^)(NSString *))timing {
    return ^id(NSString *functionName) {
        @weakify(self);
        self.animationBlock = ^(UIView *bubble, void(^completion)(void)) {
            @strongify(self);
            self.timingFunction = [ACCBubbleAnimationTimingFunction timingFunctionWithName:functionName];
            self.bubble = bubble;
            
            ACCBLOCK_INVOKE(completion);
        };
        self.nextAnimation = [self nextAnimationWithCurrentConfig];
        return self.nextAnimation;
    };
};

- (ACCBubbleAnimation *(^)(float c1x, float c1y, float c2x, float c2y))bezierTiming
{
    return ^id(float c1x, float c1y, float c2x, float c2y) {
        @weakify(self);
        self.animationBlock = ^(UIView *bubble, void(^completion)(void)) {
            @strongify(self);
            self.timingFunction = [[CAMediaTimingFunction alloc] initWithControlPoints:c1x :c1y :c2x :c2y];
            self.bubble = bubble;
            
            ACCBLOCK_INVOKE(completion);
        };
        self.nextAnimation = [self nextAnimationWithCurrentConfig];
        return self.nextAnimation;
    };
};

- (void (^)(void))stop {
    return ^{
        [self.bubble pop_removeAllAnimations];
        ACCBubbleAnimation *animation = self;
        while (animation) {
            animation.shouldStop = YES;
            animation = animation.nextAnimation;
        }
    };
}

@end
