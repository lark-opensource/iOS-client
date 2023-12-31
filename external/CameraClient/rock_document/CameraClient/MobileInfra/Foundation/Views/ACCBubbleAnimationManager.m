//
//  ACCBubbleAnimationManager.m
//  Aweme
//
//  Created by 熊典 on 2017/7/7.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "ACCBubbleAnimationManager.h"
#import <CreativeKit/ACCMacros.h>

static ACCBubbleAnimationManager * ACCBubbleAnimationManagerSharedInstance;

@interface ACCBubbleAnimationManager ()

@property (nonatomic, strong) NSMutableArray *animations;

@end

@implementation ACCBubbleAnimationManager

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ACCBubbleAnimationManagerSharedInstance = [[[self class] alloc] init];
    });
    return ACCBubbleAnimationManagerSharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.animations = [NSMutableArray array];
    }
    return self;
}

- (ACCBubbleAnimation *)runAnimationWithBubble:(UIView *)bubble
                                    animations:(void (^)(ACCBubbleAnimation *))animations
                                    completion:(void (^)(void))completion{
    ACCBubbleAnimation *animation = [[ACCBubbleAnimation alloc] initWithBubble:bubble];
    ACCBLOCK_INVOKE(animations, animation);
    [self.animations addObject:animation];
    [self runAnimation:animation completion:completion];
    return animation;
}

- (void)runAnimation:(ACCBubbleAnimation *)animation
          completion:(void (^)(void))completion{
    [animation run:^{
        [self.animations removeObject:animation];
        ACCBLOCK_INVOKE(completion);
    }]();
}

- (void)removeAnimationsForBubble:(UIView *)bubble {
    NSMutableArray *animationsToBeRemoved = [NSMutableArray array];
    for (ACCBubbleAnimation *animation in self.animations) {
        if (animation.bubble == bubble) {
            [animationsToBeRemoved addObject:animation];
        }
    }
    
    for (ACCBubbleAnimation *animation in animationsToBeRemoved) {
        animation.stop();
        [self.animations removeObject:animation];
    }
    
}

@end
