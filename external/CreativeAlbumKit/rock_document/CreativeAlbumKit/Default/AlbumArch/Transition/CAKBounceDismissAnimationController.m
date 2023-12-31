//
//  CAKBounceDismissAnimationController.m
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/9.
//

#import "CAKBounceDismissAnimationController.h"
#import <CreativeKit/ACCMacros.h>

@implementation CAKBounceDismissAnimationController

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    return 0.15;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    CGRect initialFrame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, toVC.view.bounds.size.width, toVC.view.bounds.size.height);
    
    CGRect finalFrame = [transitionContext finalFrameForViewController:toVC];
    finalFrame.origin.y = ACC_STATUS_BAR_HEIGHT;
    finalFrame.size.height = [UIScreen mainScreen].bounds.size.height - ACC_STATUS_BAR_HEIGHT;
    
    UIView *snapshotView = [toVC.view snapshotViewAfterScreenUpdates:NO];
    [containerView addSubview:snapshotView];
    [containerView insertSubview:snapshotView belowSubview:fromVC.view];
    
    UIView *blackMaskView = [[UIView alloc] initWithFrame:containerView.bounds];
    blackMaskView.backgroundColor = [UIColor blackColor];
    [containerView insertSubview:blackMaskView aboveSubview:snapshotView];
    
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    snapshotView.transform = CGAffineTransformMakeScale(0.94, 0.94);
    [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:5 initialSpringVelocity:10 options:UIViewAnimationOptionCurveLinear animations:^{
        snapshotView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [snapshotView removeFromSuperview];
    }];
    
    blackMaskView.alpha = 0.95;
    [UIView animateWithDuration:duration animations:^{
        blackMaskView.alpha = 0;
    } completion:^(BOOL finished) {
        [blackMaskView removeFromSuperview];
    }];
    
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        fromVC.view.frame = initialFrame;
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:YES];
    }];
}


@end
