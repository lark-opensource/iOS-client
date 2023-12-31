//
//  ACCBubbleAnimation+Private.h
//  Pods
//
//  Created by cppluwang on 2018/12/11.
//

#import "ACCBubbleAnimation.h"

@interface ACCBubbleAnimation ()

@property (nonatomic, copy) void (^animationBlock)(UIView *bubble, void(^completion)(void));

@property (nonatomic, strong) ACCBubbleAnimation *nextAnimation;
@property (nonatomic, weak) ACCBubbleAnimation *previousAnimation;

//Loop
@property (nonatomic, assign) NSInteger loopRepeat;
@property (nonatomic, assign) BOOL loopStartFlag;
@property (nonatomic, assign) BOOL loopModeFlag;

//Parallels
@property (nonatomic, assign) NSInteger parallelsCount;
@property (nonatomic, assign) pthread_mutex_t lock;

//Status
@property (nonatomic, assign) BOOL shouldStop;
@property (nonatomic, strong) CAMediaTimingFunction *timingFunction;

- (ACCBubbleAnimation *)nextAnimationWithCurrentConfig;

@end
