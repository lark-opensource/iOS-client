//
//  CAKAlbumTransitionInteractionController.m
//  CreativeAlbumKit_Example
//
//  Created by yuanchang on 2020/12/4.
//  Copyright © 2020 lixingdong. All rights reserved.
//

#import "CAKAlbumTransitionInteractionController.h"

@interface CAKAlbumTransitionInteractionController ()

@property (nonatomic, strong) id<CAKAlbumTransitionContextProvider> contextProvider;
@property (nonatomic, weak) id<CAKAlbumTransitionDelegateProtocol> transitionDelegate;

@end

@implementation CAKAlbumTransitionInteractionController

+ (instancetype)instanceWithContextProvider:(id<CAKAlbumTransitionContextProvider>)provider transitionDelegate:(id<CAKAlbumTransitionDelegateProtocol>)transitionDelegate
{
    switch (provider.interactionType) {
        case CAKAlbumTransitionInteractionTypeNone:
        case CAKAlbumTransitionInteractionTypePercentageDriven:
            return nil;
            break;
            
        default:
            break;
    }
    CAKAlbumTransitionInteractionController *controller = [[CAKAlbumTransitionInteractionController alloc] init];
    controller.contextProvider = provider;
    controller.transitionDelegate = transitionDelegate;
    return controller;
}

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    self.transitionDelegate.currentTransitioningContext = transitionContext;
    switch (self.contextProvider.interactionType) {
        case CAKAlbumTransitionInteractionTypeCustomPanDriven:
            [self startCustomPanDrivenTransition:transitionContext];
            break;
        default:
            break;
    }
    
    if (!self.transitionDelegate.isAnimating) {
        [self.contextProvider finishAnimationWithCompletionBlock:^{
            [transitionContext finishInteractiveTransition];
            [transitionContext completeTransition:YES];
        }];
        return;
    }
}

- (void)startCustomPanDrivenTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    [self.contextProvider startCustomAnimationWithFromVC:fromViewController
                                                    toVC:toViewController
                                     fromContextProvider:self.transitionDelegate.innerViewController
                                       toContextProvider:self.transitionDelegate.outterViewController
                                           containerView:transitionContext.containerView
                                                 context:transitionContext];
}

@end
