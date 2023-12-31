//
//  AWEBigToSmallPresentAnimation.m
//  Aweme
//
//  Created by hanxu on 2018/3/7.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

#import "AWEBigToSmallPresentAnimation.h"
#import <CreationKitInfra/AWEMediaSmallAnimationProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>

@implementation AWEBigToSmallPresentAnimation

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.3;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView *containerView = [transitionContext containerView];
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    CGRect finalFrame = toVC.view.frame;
    CGFloat bottomViewHeight = 0;
    BOOL mediaDisplayImmediately = NO;
    NSArray<UIView *> *topViews = nil;
    if ([toVC conformsToProtocol:@protocol(AWEMediaSmallAnimationProtocol)]) {
        finalFrame = [(id <AWEMediaSmallAnimationProtocol>)toVC mediaSmallMediaContainerFrame];
        if ([toVC respondsToSelector:@selector(mediaDisplayImmediately)]) {
            mediaDisplayImmediately = [(id <AWEMediaSmallAnimationProtocol>)toVC mediaDisplayImmediately];
        }
        if ([toVC respondsToSelector:@selector(displayTopViews)]) {
            topViews = [(id<AWEMediaSmallAnimationProtocol>)toVC displayTopViews];
        }
    }

    UIView *bigMediaSnapView = nil;
    CGRect bigMediaSnapViewFrame = CGRectZero;
    UIView *mediaBigButtonsContainerSanpView = nil;
    UIView *toVcBottomView = nil;
    UIView *toVcPlayerContainer = nil;
    BOOL isBottomViewFadeOut = NO;
    if ([fromVC isKindOfClass:[UINavigationController class]]) {
        if ([[(UINavigationController *)fromVC topViewController] conformsToProtocol:@protocol(AWEMediaBigAnimationProtocol)]) {
            id<AWEMediaBigAnimationProtocol> publishVc = (id<AWEMediaBigAnimationProtocol>)[(UINavigationController *)fromVC topViewController];
            bigMediaSnapView = [publishVc mediaBigMediaSnap];
            mediaBigButtonsContainerSanpView = [publishVc mediaBigButtonsContainerSnap];
            bigMediaSnapViewFrame = [publishVc mediaBigMediaFrame];
        }
    } else if ([fromVC conformsToProtocol:@protocol(AWEMediaBigAnimationProtocol)]){
        bigMediaSnapView = [(id<AWEMediaBigAnimationProtocol>)fromVC mediaBigMediaSnap];
        mediaBigButtonsContainerSanpView = [(id<AWEMediaBigAnimationProtocol>)fromVC mediaBigButtonsContainerSnap];
        bigMediaSnapViewFrame = [(id<AWEMediaBigAnimationProtocol>)fromVC mediaBigMediaFrame];
    } else {
        bigMediaSnapView = [fromVC.view snapshotViewAfterScreenUpdates:NO];
    }

    bigMediaSnapView.frame = bigMediaSnapViewFrame;
    toVC.view.frame = [UIScreen mainScreen].bounds;

    if ([toVC conformsToProtocol:@protocol(AWEMediaSmallAnimationProtocol)]) {
        toVcBottomView = [((id <AWEMediaSmallAnimationProtocol>)toVC) mediaSmallBottomView];
        bottomViewHeight = toVcBottomView.acc_height;
        if (!mediaDisplayImmediately) {
            toVcPlayerContainer = [((id <AWEMediaSmallAnimationProtocol>)toVC) mediaSmallMediaContainer];
            toVcPlayerContainer.alpha = 0;
        }
        if ([toVC respondsToSelector:@selector(bottomViewTransitionDist)]) {
            CGFloat dist = [((id <AWEMediaSmallAnimationProtocol>)toVC) bottomViewTransitionDist];
            toVcBottomView.acc_top = [UIScreen mainScreen].bounds.size.height - bottomViewHeight + dist;
        }
        if ([toVC respondsToSelector:@selector(isBottomViewFadeOut)]) {
            isBottomViewFadeOut = [((id <AWEMediaSmallAnimationProtocol>)toVC) isBottomViewFadeOut];
        }
    }

    [containerView addSubview:toVC.view];
    if (!mediaDisplayImmediately) {
        [containerView addSubview:bigMediaSnapView];
    }
    [containerView addSubview:mediaBigButtonsContainerSanpView];
    
    [UIView animateWithDuration:0.49 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        bigMediaSnapView.frame = finalFrame;
        //文字、poi、投票贴纸在视频编辑页还没有打进视频，所以是subview的方式add在bigMediaSnapView
        [bigMediaSnapView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.frame = CGRectMake(0, 0, finalFrame.size.width, finalFrame.size.height);
        }];
        [topViews enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.alpha = 1;
            obj.hidden = NO;
        }];
        mediaBigButtonsContainerSanpView.alpha = 0;
        toVcBottomView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - bottomViewHeight, [UIScreen mainScreen].bounds.size.width, bottomViewHeight);
        if (isBottomViewFadeOut) {
            toVcBottomView.alpha = 1;
        }
    } completion:^(BOOL finished) {
        toVcPlayerContainer.alpha = 1;
        [bigMediaSnapView removeFromSuperview];
        [mediaBigButtonsContainerSanpView removeFromSuperview];
        [transitionContext completeTransition:YES];
    }];
}

@end
