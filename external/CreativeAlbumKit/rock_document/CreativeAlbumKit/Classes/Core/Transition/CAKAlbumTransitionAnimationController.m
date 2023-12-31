//
//  CAKAlbumTransitionAnimationController.m
//  CreativeAlbumKit_Example
//
//  Created by yuanchang on 2020/12/4.
//  Copyright © 2020 lixingdong. All rights reserved.
//

#import "CAKAlbumTransitionAnimationController.h"

@interface CAKAlbumTransitionAnimationController ()

@property (nonatomic, strong) id<CAKAlbumTransitionContextProvider> contextProvider;
@property (nonatomic, weak) id<CAKAlbumTransitionDelegateProtocol> transitionDelegate;

@end

@implementation CAKAlbumTransitionAnimationController

+ (instancetype)instanceWithContextProvider:(id<CAKAlbumTransitionContextProvider>)provider transitionDelegate:(id<CAKAlbumTransitionDelegateProtocol>)transitionDelegate
{
    CAKAlbumTransitionAnimationController *controller = [[CAKAlbumTransitionAnimationController alloc] init];
    controller.contextProvider = provider;
    controller.transitionDelegate = transitionDelegate;
    return controller;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    if ([self.contextProvider respondsToSelector:@selector(transitionDuration:)]) {
        return [self.contextProvider transitionDuration];
    }
    
    return 0.35;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    self.transitionDelegate.currentTransitioningContext = transitionContext;
    CAKAlbumTransitionInteractionType type = CAKAlbumTransitionInteractionTypeNone;//self.contextProvider.interactionType;
    self.transitionDelegate.isAnimating = YES;
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if ([self.contextProvider isForAppear]) {
        [self.contextProvider startDefaultAnimationWithFromVC:fromViewController
                                                         toVC:toViewController
                                          fromContextProvider:self.transitionDelegate.outterViewController
                                            toContextProvider:self.transitionDelegate.innerViewController
                                                containerView:transitionContext.containerView
                                                      context:transitionContext
                                              interactionType:type
                                            completionHandler:^(BOOL completed) {
            [transitionContext completeTransition:completed];
            self.transitionDelegate.isAnimating = NO;
        }];
    } else {
        [self.contextProvider startDefaultAnimationWithFromVC:fromViewController
                                                         toVC:toViewController
                                          fromContextProvider:self.transitionDelegate.innerViewController
                                            toContextProvider:self.transitionDelegate.outterViewController
                                                containerView:transitionContext.containerView
                                                      context:transitionContext
                                              interactionType:type
                                            completionHandler:^(BOOL completed) {
            [transitionContext completeTransition:completed];
            self.transitionDelegate.isAnimating = NO;
        }];
    }
}

@end
