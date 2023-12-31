//
//  BDPPresentAnimation.m
//  Timor
//
//  Created by MacPu on 2018/10/10.
//

#import "BDPPresentAnimation.h"
#import <OPFoundation/BDPCommon.h>
#import <OPFoundation/BDPDeviceHelper.h>
#import <OPFoundation/UIView+BDPExtension.h>
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/EEFeatureGating.h>

#define BDPPRESENT_SCALE 0.98f

@interface BDPInnerPresentController : UIPresentationController

@end

@implementation BDPInnerPresentController

- (BOOL)shouldRemovePresentersView
{
    return YES;
}

@end


#pragma mark -
#pragma mark - BDPPresentAnimation

@interface BDPPresentAnimation () <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, UINavigationControllerDelegate>

@property (nonatomic, strong, readwrite) UIPercentDrivenInteractiveTransition *interactive;

@end

@implementation BDPPresentAnimation

- (UIPercentDrivenInteractiveTransition *)interactive
{
    if (!_interactive) {
        _interactive = [[UIPercentDrivenInteractiveTransition alloc] init];
    }
    return _interactive;
}

- (void)doPushAnimation:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView *containerView = [transitionContext containerView];
    
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
//    UIView *backgroundView = [[UIView alloc] initWithFrame:containerView.bounds];
//    backgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
//    [containerView addSubview:backgroundView];
    
//    backgroundView.alpha = 0.0;
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    [containerView insertSubview:fromView atIndex:0];
    
    if (self.style == BDPPresentAnimationStypeRightLeft) {
        toView.bdp_left = toView.bdp_width;
    } else {
        toView.bdp_top = toView.bdp_bottom;
    }
    [containerView addSubview:toView];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        fromView.transform = CGAffineTransformMakeScale(BDPPRESENT_SCALE, BDPPRESENT_SCALE);
        toView.frame = [transitionContext finalFrameForViewController:toVC];
//        backgroundView.alpha = 1.0;
    } completion:^(BOOL finished) {
        fromView.transform = CGAffineTransformIdentity;
//        [backgroundView removeFromSuperview];
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

- (void)doDismissAnimation:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView *containerView = [transitionContext containerView];
    
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
//    UIView *backgroundView = [[UIView alloc] initWithFrame:containerView.bounds];
//    backgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
//    [containerView addSubview:backgroundView];
    
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    [containerView insertSubview:toView atIndex:0];
    [containerView addSubview:fromView];
    
    toView.transform = CGAffineTransformMakeScale(BDPPRESENT_SCALE, BDPPRESENT_SCALE);
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        toView.transform = CGAffineTransformIdentity;
        toView.frame = [transitionContext finalFrameForViewController:toVC];
        if (self.style == BDPPresentAnimationStypeRightLeft) {
            fromView.bdp_left = fromView.bdp_width;
        } else {
            fromView.bdp_top = fromView.bdp_bottom;
        }
//        backgroundView.alpha = 0.0;
    } completion:^(BOOL finished) {
        
//        [backgroundView removeFromSuperview];
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

- (void)doScreenEdgePopAnimation:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView *containerView = [transitionContext containerView];

    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *backgroundView = [[UIView alloc] initWithFrame:containerView.bounds];
    backgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    [containerView addSubview:backgroundView];
    
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    [containerView insertSubview:toView atIndex:0];
    [containerView addSubview:fromView];
    
    UIView *shadowView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, fromView.bdp_height)];
    shadowView.backgroundColor = [UIColor blackColor];
    shadowView.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    shadowView.layer.shadowOffset = CGSizeMake(-3, 0);
    shadowView.layer.shadowRadius = 3.0;
    shadowView.layer.shadowOpacity = 0.5;
    shadowView.layer.masksToBounds = NO;
    shadowView.clipsToBounds = NO;
    [containerView insertSubview:shadowView belowSubview:fromView];
    
    toView.transform = CGAffineTransformMakeScale(BDPPRESENT_SCALE, BDPPRESENT_SCALE);
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        toView.transform = CGAffineTransformIdentity;
        toView.frame = [transitionContext finalFrameForViewController:toVC];
        fromView.bdp_left = fromView.bdp_width;
        shadowView.bdp_left = fromView.bdp_width;
        shadowView.alpha = 0.1;
        backgroundView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [backgroundView removeFromSuperview];
        [shadowView removeFromSuperview];
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
    
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    self.operation = UINavigationControllerOperationPush;
    return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    self.operation = UINavigationControllerOperationPop;
    return self;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator
{
    if (self.screenEdgePopMode) {
        return self.interactive;
    }
    return nil;
}

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented
                                                      presentingViewController:(UIViewController *)presenting
                                                          sourceViewController:(UIViewController *)source
{
    return [[BDPInnerPresentController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.2;
    
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    if (self.operation == UINavigationControllerOperationPush) {
        [self doPushAnimation:transitionContext];
    } else if (self.screenEdgePopMode && self.operation == UINavigationControllerOperationPop) {
        [self doScreenEdgePopAnimation:transitionContext];
        self.screenEdgePopMode = NO;
    } else if (self.operation == UINavigationControllerOperationPop) {
        [self doDismissAnimation:transitionContext];
    }
}


@end
