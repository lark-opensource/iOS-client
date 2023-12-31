//
//  ACCZoomPushAnimation.m
//  CameraClient
//
//  Created by long.chen on 2020/3/4.
//

#import "ACCZoomPushAnimator.h"
#import "ACCZoomContextProviderProtocol.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>

@implementation ACCZoomPushAnimator

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.35f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController<ACCZoomContextOutterProviderProtocol> *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController<ACCZoomContextInnerProviderProtocol> *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    
    UIView *startView = [fromVC acc_zoomTransitionStartViewForItemOffset:0];
    UIView *startViewSnapshot = [startView snapshotViewAfterScreenUpdates:NO];
    startViewSnapshot.frame = [containerView convertRect:startView.bounds fromView:startView];
    startView.hidden = YES;
    
    UIView *endViewSnapshot = [toVC.view acc_snapshotImageView];
    endViewSnapshot.frame = startViewSnapshot.frame;
    endViewSnapshot.alpha = 0.0f;
    
    [containerView addSubview:toVC.view];
    [containerView addSubview:startViewSnapshot];
    [containerView addSubview:endViewSnapshot];
    
    toVC.view.alpha = 0.0f;
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                          delay:0.f
         usingSpringWithDamping:0.8f
          initialSpringVelocity:0.3f
                        options:0
                     animations:^{
        startViewSnapshot.alpha = 0.f;
        startViewSnapshot.frame = [transitionContext finalFrameForViewController:toVC];
        
        endViewSnapshot.alpha = 1.f;
        endViewSnapshot.frame = [transitionContext finalFrameForViewController:toVC];
    } completion:^(BOOL finished) {
        startView.hidden = NO;
        toVC.view.alpha = 1.f;
        [startViewSnapshot removeFromSuperview];
        [endViewSnapshot removeFromSuperview];
        [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
    }];
}

@end
