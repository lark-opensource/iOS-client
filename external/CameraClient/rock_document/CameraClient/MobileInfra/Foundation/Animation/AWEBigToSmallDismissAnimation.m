//
//  AWEBigToSmallDismissAnimation.m
//  Aweme
//
//  Created by hanxu on 2018/3/7.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

#import "AWEBigToSmallDismissAnimation.h"
#import <CreationKitInfra/AWEMediaSmallAnimationProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/UIView+ACCRTL.h>

@implementation AWEBigToSmallDismissAnimation

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.3;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView *containerView = [transitionContext containerView];
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    UIView *smallMediaContainerSnapView = nil;
    CGRect smallMediaContainerSnapViewFrame = CGRectZero;
    CGAffineTransform smallMediaContainerSnapViewTransform = CGAffineTransformIdentity;
    
    UIView *toVcBottomView = nil;
    CGRect finalFrame = CGRectZero;
    BOOL isBottomViewFadeOut = NO;
    CGFloat bottomViewFadeHeight = [UIScreen mainScreen].bounds.size.height;
    
    if ([fromVC conformsToProtocol:@protocol(AWEMediaSmallAnimationProtocol)]) {
        UIView *mediaSmallMediaContainer = [(id <AWEMediaSmallAnimationProtocol>)fromVC mediaSmallMediaContainer];
        smallMediaContainerSnapView = [mediaSmallMediaContainer snapshotViewAfterScreenUpdates:NO];
        smallMediaContainerSnapView.accrtl_viewType = ACCRTLViewTypeNormal;
        mediaSmallMediaContainer.hidden = YES;
        smallMediaContainerSnapViewFrame = [(id <AWEMediaSmallAnimationProtocol>)fromVC mediaSmallMediaContainerFrame];
        if ([fromVC respondsToSelector:@selector(mediaSmallMediaContainerTransform)]) {
            smallMediaContainerSnapViewTransform = [(id <AWEMediaSmallAnimationProtocol>)fromVC mediaSmallMediaContainerTransform];
        }
        if ([fromVC respondsToSelector:@selector(doSomethingAfterSnap)]) {
            [(id <AWEMediaSmallAnimationProtocol>)fromVC doSomethingAfterSnap];
        }
        if ([fromVC respondsToSelector:@selector(isBottomViewFadeOut)]) {
            isBottomViewFadeOut = [(id <AWEMediaSmallAnimationProtocol>)fromVC isBottomViewFadeOut];
        }
        smallMediaContainerSnapView.transform = smallMediaContainerSnapViewTransform;
        toVcBottomView = [((id <AWEMediaSmallAnimationProtocol>)fromVC) mediaSmallBottomView];
        if ([fromVC respondsToSelector:@selector(bottomViewTransitionDist)]) {
            CGFloat dist = [((id <AWEMediaSmallAnimationProtocol>)fromVC) bottomViewTransitionDist];
            bottomViewFadeHeight = [UIScreen mainScreen].bounds.size.height - toVcBottomView.acc_height + dist;
        }
    }
    UIView *mediaBigButtonsContainerSnap = nil;
    UIView *mediaBigButtonsContainer = nil;
    if ([toVC isKindOfClass:[UINavigationController class]]) {
        if ([[(UINavigationController *)toVC topViewController] conformsToProtocol:@protocol(AWEMediaBigAnimationProtocol)]) {
            id<AWEMediaBigAnimationProtocol> publishVc = (id<AWEMediaBigAnimationProtocol>)[(UINavigationController *)toVC topViewController];
            mediaBigButtonsContainerSnap = [publishVc mediaBigButtonsContainerSnap];
            mediaBigButtonsContainer = [publishVc mediaBigButtonsContainer];
            finalFrame = [publishVc mediaBigMediaFrame];
        }
    } else if ([toVC conformsToProtocol:@protocol(AWEMediaBigAnimationProtocol)]) {
        mediaBigButtonsContainerSnap = [(id<AWEMediaBigAnimationProtocol>)toVC mediaBigButtonsContainerSnap];
        mediaBigButtonsContainer = [(id<AWEMediaBigAnimationProtocol>)toVC mediaBigButtonsContainer];
        finalFrame = [(id<AWEMediaBigAnimationProtocol>)toVC mediaBigMediaFrame];
    }
    mediaBigButtonsContainer.hidden = YES;
    smallMediaContainerSnapView.frame = smallMediaContainerSnapViewFrame;
    toVC.view.frame = [UIScreen mainScreen].bounds;

    [containerView addSubview:smallMediaContainerSnapView];
    [containerView addSubview:mediaBigButtonsContainerSnap];
    if (isBottomViewFadeOut) {
        [toVcBottomView removeFromSuperview];
        [containerView addSubview:toVcBottomView];
    }

    mediaBigButtonsContainerSnap.alpha = 0;
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        smallMediaContainerSnapView.frame = finalFrame;
        mediaBigButtonsContainerSnap.alpha = 1;
        toVcBottomView.acc_top = bottomViewFadeHeight;
        if (isBottomViewFadeOut) {
            toVcBottomView.alpha = 0;
        }
    } completion:^(BOOL finished) {
        mediaBigButtonsContainer.hidden = NO;
        [mediaBigButtonsContainerSnap removeFromSuperview];
        [smallMediaContainerSnapView removeFromSuperview];
        [transitionContext completeTransition:YES];
    }];
}

@end
