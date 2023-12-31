//
//  CJPayPresentAnimator.m
//  CJPay
//
//  Created by wangxiaohong on 2022/5/5.
//

#import "CJPayPresentAnimator.h"

#import "CJPayNavigationController.h"
#import "CJPaySDKMacro.h"
#import "CJPayHalfPageBaseViewController.h"
#import "CJPayPopUpBaseViewController.h"
#import "CJPayTransitionUtil.h"
#import "CJPaySettingsManager.h"

@implementation CJPayPresentAnimator

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return [CJPayTransition animationDuration];
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    if ([CJPaySettingsManager shared].currentSettings.rdOptimizationConfig.isTransitionUseSnapshot) {
        [self p_animateTransition:transitionContext];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self p_animateTransition:transitionContext];
        });
    }
}

#pragma mark - private Methods
- (void)p_animateTransition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext {
    CJPayTransactionShareView *shareViews = [[CJPayTransactionShareView alloc] initWith:transitionContext];
    
    [[transitionContext containerView] addSubview:shareViews.toView];
    
    UIViewController *fromVC = shareViews.fromVC;
    BOOL isPresentHalfPage = NO;
    if ([fromVC isKindOfClass:CJPayNavigationController.class]) {
        CJPayNavigationController *navi = (CJPayNavigationController *)fromVC;
        isPresentHalfPage = [[navi.viewControllers lastObject] isKindOfClass:CJPayHalfPageBaseViewController.class];
    }
    if (isPresentHalfPage && [self p_isSingleHalfPageCJPayNavi:shareViews.toVC]) {
        
        CJPayNavigationController *fromNavi = (CJPayNavigationController *)fromVC;
        CJPayNavigationController *toNavi = (CJPayNavigationController *)shareViews.toVC;

        CJPayHalfPageBaseViewController *fromHalfVC = [fromNavi.viewControllers lastObject];
        CJPayHalfPageBaseViewController *toHalfVC = [toNavi.viewControllers firstObject];

        @CJWeakify(self)
        void (^transitionVCCompletionBlock)(BOOL) = ^(BOOL isFinish) {
            @CJStrongify(self);
            [self p_finishTransitionWithContext:transitionContext];
        };
        
        if (toHalfVC.animationType != HalfVCEntranceTypeFromRight) { // 走普通present流程
            CJPayNavigationController *navi = (CJPayNavigationController *)toHalfVC.navigationController;
            BOOL needShowMask = [navi.view isShowMask] || toHalfVC.isShowMask;
            UIColor *bgColor = navi.view.backgroundColor;
            navi.view.backgroundColor = [UIColor clearColor];
            [self p_presentViewController:toHalfVC sourceView:shareViews.fromView isShowMask:needShowMask completion:^(BOOL isFinish) {
                navi.view.backgroundColor = bgColor;
                CJ_CALL_BLOCK(transitionVCCompletionBlock, isFinish);
            }];
            return;
        }
        
        if (fromNavi.useNewHalfPageTransAnimation || toNavi.useNewHalfPageTransAnimation) {
            [self p_presentHalfVCNewAnimationWithTransitionContext:transitionContext fromVC:fromHalfVC toVC:toHalfVC completion:transitionVCCompletionBlock];
        } else {
            [self p_presentHalfVCWithTransitionContext:transitionContext shareView:shareViews fromVC:fromHalfVC toVC:toHalfVC completion:transitionVCCompletionBlock];
        }
        return;
    }

    if ([shareViews.toVC isKindOfClass:CJPayNavigationController.class] && ((CJPayNavigationController *)shareViews.toVC).viewControllers.count == 1) {
        CJPayNavigationController *navi = (CJPayNavigationController *)shareViews.toVC;
        
        UIViewController *transVC = navi.viewControllers.firstObject;
        if (![transVC isKindOfClass:CJPayBaseViewController.class]) {
            [self p_finishTransitionWithContext:transitionContext];
            return;
        }
        CJPayBaseViewController *cjpayTransVC = (CJPayBaseViewController *)transVC;
        @CJWeakify(self);
        BOOL needShowMask = [navi.view isShowMask] || cjpayTransVC.isShowMask;
        
        UIColor *bgColor = navi.view.backgroundColor;
        navi.view.backgroundColor = [UIColor clearColor];

        [self p_presentViewController:cjpayTransVC sourceView:shareViews.fromView isShowMask:needShowMask completion:^(BOOL isFinish) {
            @CJStrongify(self);
            navi.view.backgroundColor = bgColor;
            [self p_finishTransitionWithContext:transitionContext];
        }];
        
        return;
    }
    
    if ([shareViews.toVC isKindOfClass:CJPayBaseViewController.class]) {
        @CJWeakify(self);
        CJPayBaseViewController *cjpayToVC = (CJPayBaseViewController *)shareViews.toVC;
        [self p_presentViewController:(CJPayBaseViewController *)shareViews.toVC sourceView:shareViews.fromView isShowMask:cjpayToVC.isShowMask completion:^(BOOL isFinish) {
            @CJStrongify(self);
            [self p_finishTransitionWithContext:transitionContext];
        }];
        return;
    }
    [self p_finishTransitionWithContext:transitionContext];
}

- (void)p_finishTransitionWithContext:(nonnull id<UIViewControllerContextTransitioning>)transitionContext {
    [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
}

- (void)p_presentViewController:(CJPayBaseViewController *)viewController sourceView:(UIView *)sourceView isShowMask:(BOOL)isShowMask completion:(void (^)(BOOL isFinish))completion  {
    
    if (![viewController isKindOfClass:CJPayBaseViewController.class]) {
        CJ_CALL_BLOCK(completion, YES);
        return;
    }
    
    CJPayBaseViewController *cjpayVC = (CJPayBaseViewController *)viewController;
    
    if (cjpayVC.vcType == CJPayBaseVCTypeFull) {
        [CJPayTransition transitionEnterFullVC:(CJPayFullPageBaseViewController *)cjpayVC maskContainerView:sourceView completion:completion];
        return;
    }
    
    if (cjpayVC.vcType == CJPayBaseVCTypeHalf) {
        [CJPayTransition transitionEnterHalfVC:(CJPayHalfPageBaseViewController *)cjpayVC isShowMaskView:isShowMask completion:completion];
        return;
    }
    
    if (cjpayVC.vcType == CJPayBaseVCTypePopUp) {
        [CJPayTransition transitionEnterPopUpVC:(CJPayPopUpBaseViewController *)cjpayVC isShowMaskView:isShowMask completion:completion];
        return;
    }
    CJ_CALL_BLOCK(completion, YES);
}

- (BOOL)p_isSingleHalfPageCJPayNavi:(UIViewController *)vc {
    if (![vc isKindOfClass:CJPayNavigationController.class]) {
        return NO;
    }
    CJPayNavigationController *navi = (CJPayNavigationController *)vc;
    return navi.viewControllers.count == 1 && [[navi.viewControllers firstObject] isKindOfClass:CJPayHalfPageBaseViewController.class];
}

- (void)p_presentHalfVCWithTransitionContext:(id <UIViewControllerContextTransitioning>)transitionContext
                                   shareView:(CJPayTransactionShareView *)shareViews
                                      fromVC:(CJPayHalfPageBaseViewController *)fromHalfVC
                                        toVC:(CJPayHalfPageBaseViewController *)toHalfVC
                                  completion:(void (^)(BOOL isFinish))completion {

    CGFloat fromContainerViewHeight = fromHalfVC.containerHeight;
    CGFloat toContainerViewHeight = toHalfVC.containerHeight;

    UIView *containerView = transitionContext.containerView;

    if (fabs(fromContainerViewHeight - toContainerViewHeight) < CGFLOAT_EPSILON) {

        [CJPayTransition transitionEnterHalfVC:toHalfVC isShowMaskView:YES maskViewHeight:fromContainerViewHeight completion:completion];
    } else {
        // 不同高度半屏进场动画
        CGFloat fromContainerHeight = fromHalfVC.containerHeight;
        CGFloat toContainerHeight = toHalfVC.containerHeight;
        
        UIView *containerBottomView;
        containerBottomView = [UIView new];
        [containerView insertSubview:containerBottomView atIndex:0];
        containerBottomView.backgroundColor = fromHalfVC.containerView.backgroundColor;
        CGFloat containerBottomHeight = toContainerHeight - fromContainerHeight;
        containerBottomView.frame = CGRectMake(0, CJ_SCREEN_HEIGHT - containerBottomHeight, CJ_SCREEN_WIDTH, containerBottomHeight);
        [CJPayTransition transitionEnterHalfVC:toHalfVC
                                    fromHalfVC:fromHalfVC
                                 containerView:containerView
                           containerBottomView:containerBottomView
                                    completion:^(BOOL finished) {
            [containerBottomView removeFromSuperview];
            CJ_CALL_BLOCK(completion, finished);
        }];
    }
}

// 半屏present半屏转场 - 平移动画
- (void)p_presentHalfVCNewAnimationWithTransitionContext:(id <UIViewControllerContextTransitioning>)transitionContext
                                                  fromVC:(CJPayHalfPageBaseViewController *)fromHalfVC
                                                    toVC:(CJPayHalfPageBaseViewController *)toHalfVC
                                              completion:(void (^)(BOOL isFinish))completion {
    
    CGFloat fromContainerViewHeight = fromHalfVC.containerHeight;
    CGFloat toContainerViewHeight = toHalfVC.containerHeight;

    UIView *containerView = transitionContext.containerView;
//    [containerView addSubview:toHalfVC.view];
    
    UIView *containerBottomView = nil;
    if (fabs(fromContainerViewHeight - toContainerViewHeight) >= CGFLOAT_EPSILON) {
        
        containerBottomView = [UIView new];
        [containerView insertSubview:containerBottomView belowSubview:toHalfVC.view];
    }

    [CJPayTransition transitionTranslationEnterHalfVC:toHalfVC fromHalfVC:fromHalfVC containerView:containerView containerBottomView:containerBottomView completion:^(BOOL finished) {
        
        [containerBottomView removeFromSuperview];
        CJ_CALL_BLOCK(completion, finished);
    }];
}


@end
