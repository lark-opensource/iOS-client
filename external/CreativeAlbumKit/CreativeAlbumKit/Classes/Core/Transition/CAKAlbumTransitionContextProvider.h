//
//  CAKAlbumTransitionContextProvider.h
//  CreativeAlbumKit_Example
//
//  Created by yuanchang on 2020/12/4.
//  Copyright © 2020 lixingdong. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CAKAlbumTransitionContext;

typedef NS_ENUM(NSUInteger, CAKAlbumTransitionInteractionType)
{
    CAKAlbumTransitionInteractionTypeNone,
    CAKAlbumTransitionInteractionTypePercentageDriven,
    CAKAlbumTransitionInteractionTypeCustomPanDriven,
};

typedef NS_ENUM(NSUInteger, CAKAlbumTransitionTriggerDirection)
{
    CAKAlbumTransitionTriggerDirectionNone = 0,
    CAKAlbumTransitionTriggerDirectionUp = 1,
    CAKAlbumTransitionTriggerDirectionDown = 1 << 1,
    CAKAlbumTransitionTriggerDirectionLeft = 1 << 2,
    CAKAlbumTransitionTriggerDirectionRight = 1 << 3,
    
    CAKAlbumTransitionTriggerDirectionAny = CAKAlbumTransitionTriggerDirectionUp | CAKAlbumTransitionTriggerDirectionDown | CAKAlbumTransitionTriggerDirectionLeft | CAKAlbumTransitionTriggerDirectionRight,
};

@protocol CAKAlbumTransitionContextProvider <NSObject>

@optional

- (BOOL)isForAppear;

- (CAKAlbumTransitionInteractionType)interactionType;

// Percentage driven animation
- (NSTimeInterval)transitionDuration;
- (void)startDefaultAnimationWithFromVC:(UIViewController * _Nullable)fromVC
                                   toVC:(UIViewController * _Nullable)toVC
                    fromContextProvider:(id _Nullable)fromCP
                      toContextProvider:(id _Nullable)toCP
                          containerView:(UIView * _Nullable)containerView
                                context:(id<UIViewControllerContextTransitioning> _Nullable)context
                        interactionType:(CAKAlbumTransitionInteractionType)type
                      completionHandler:(void(^ _Nullable)(BOOL completed))completionHander;

// Custom pan driven animation
- (CAKAlbumTransitionTriggerDirection)allowTriggerDirectionForContext:(CAKAlbumTransitionContext * _Nullable)context;
- (void)startCustomAnimationWithFromVC:(__kindof UIViewController * _Nullable)fromVC
                                  toVC:(__kindof UIViewController * _Nullable)toVC
                   fromContextProvider:(id _Nullable)fromCP
                     toContextProvider:(id _Nullable)toCP
                         containerView:(UIView * _Nullable)containerView
                               context:(id<UIViewControllerContextTransitioning> _Nullable)context;

- (void)updateAnimationWithPosition:(CGPoint)currentPosition
                      startPosition:(CGPoint)startPosition;

- (void)finishAnimationWithCompletionBlock:(void (^ _Nullable)(void))completionBlock;

- (void)cancelAnimationWithCompletionBlock:(void (^ _Nullable)(void))completionBlock;

@end

