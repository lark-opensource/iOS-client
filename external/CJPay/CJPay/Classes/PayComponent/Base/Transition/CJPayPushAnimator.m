//
//  CJPayPushAnimatorV2.m
//  CJPay
//
//  Created by wangxiaohong on 2022/5/5.
//

#import "CJPayPushAnimator.h"

#import "CJPayUIMacro.h"
#import "CJPayTransitionUtil.h"
#import "UIViewController+CJTransition.h"
#import "CJPayPopUpBaseViewController.h"
#import "CJPayHalfPageBaseViewController.h"
#import "CJPayFullPageBaseViewController.h"
#import "CJPayCommonUtil.h"
#import "CJPaySettingsManager.h"

@implementation CJPayPushAnimator

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    CJPayTransactionShareView *shareViews = [[CJPayTransactionShareView alloc] initWith:transitionContext];
    if ([CJPaySettingsManager shared].currentSettings.rdOptimizationConfig.isTransitionUseSnapshot) {
        [self p_pushWithTransitionContext:transitionContext shareView:shareViews];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self p_pushWithTransitionContext:transitionContext shareView:shareViews];
        });
    }
}

- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
    return [CJPayTransition animationDuration];
}

- (void)p_finishTransitionWithContext:(nonnull id<UIViewControllerContextTransitioning>)transitionContext {
    [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
}

- (void)p_pushWithTransitionContext:(id <UIViewControllerContextTransitioning>)transitionContext shareView:(CJPayTransactionShareView *)shareViews {
    
    UIView *containerView = transitionContext.containerView;

    if (![shareViews.fromVC isCJPayViewController] || ![shareViews.toVC isCJPayViewController] || CJ_Pad) {
        [containerView addSubview:shareViews.toView];
        [CJPayTransition transitionEnterFullVC:shareViews.toVC maskContainerView:shareViews.fromView completion:^(BOOL finished) {
            [self p_finishTransitionWithContext:transitionContext];
        }];
        return;
    }
    CJPayBaseViewController *cjpayFromVC = (CJPayBaseViewController *)shareViews.fromVC;
    CJPayBaseViewController *cjpayToVC = (CJPayBaseViewController *)shareViews.toVC;
    
    @CJWeakify(self)
    void (^transitionVCCompletionBlock)(void) = ^(){
        @CJStrongify(self)
        // 在完成转场前先截图，避免不同高度半屏截图错误
        UIImage *preViewSnapImage = [CJPayCommonUtil snapViewToImageView:shareViews.fromView];
        [self p_finishTransitionWithContext:transitionContext];
        if ([self p_isNeedInsertSnapshotForVC:cjpayToVC]) {
            [self p_insertBackViewWithShareView:shareViews snapImage:preViewSnapImage];
        }
    };
    if (cjpayToVC.vcType == CJPayBaseVCTypeFull) {
        [containerView addSubview:shareViews.toView];
        if (!cjpayToVC.cjNeedAnimation) {
            // 针对透明webview转场特殊处理
            CJ_CALL_BLOCK(transitionVCCompletionBlock);
            return;
        }
        [CJPayTransition transitionEnterFullVC:cjpayToVC maskContainerView:shareViews.fromView completion:^(BOOL finished) {
            [self p_finishTransitionWithContext:transitionContext];
        }];
        return;
    }
    
    if (cjpayToVC.vcType == CJPayBaseVCTypeHalf) {
        CJPayHalfPageBaseViewController *halfVC = (CJPayHalfPageBaseViewController *)cjpayToVC;
        if (cjpayFromVC.vcType == CJPayBaseVCTypeFull) {
            [containerView addSubview:shareViews.toView];
            [CJPayTransition transitionEnterHalfVC:halfVC isShowMaskView:YES maskViewHeight:0 completion:^(BOOL isFinish) {
                CJ_CALL_BLOCK(transitionVCCompletionBlock);
            }];
            return;
        }
        
        if (cjpayFromVC.vcType == CJPayBaseVCTypeHalf) {
            if ([cjpayFromVC.navigationController isKindOfClass:CJPayNavigationController.class] && ((CJPayNavigationController *)cjpayFromVC.navigationController).useNewHalfPageTransAnimation) {
                [self p_pushHalfVCNewAnimationWithTransitionContext:transitionContext fromVC:(CJPayHalfPageBaseViewController *)cjpayFromVC toVC:halfVC completion:^(BOOL isFinish) {
                    CJ_CALL_BLOCK(transitionVCCompletionBlock);
                }];
                return;
            }
            
            [self p_pushHalfVCWithTransitionContext:transitionContext shareView:shareViews fromVC:(CJPayHalfPageBaseViewController *)cjpayFromVC toVC:halfVC completion:^(BOOL isFinish) {
                CJ_CALL_BLOCK(transitionVCCompletionBlock);
            }];
            return;
        }
        
        if (cjpayFromVC.vcType == CJPayBaseVCTypePopUp) {
            [CJPayTransition transitionExitPopUpVC:(CJPayPopUpBaseViewController *)cjpayFromVC isShowMaskView:NO isRemoveBGImageView:NO completion:^(BOOL finished) {
                [containerView addSubview:shareViews.toView];
                [CJPayTransition transitionEnterHalfVC:halfVC isShowMaskView:NO maskViewHeight:0 completion:^(BOOL isFinish) {
                    CJ_CALL_BLOCK(transitionVCCompletionBlock);
                }];
            }];
            return;
        }
        
        [containerView addSubview:shareViews.toView];
        CJ_CALL_BLOCK(transitionVCCompletionBlock);
        return;
    }
    
    
    if (cjpayToVC.vcType == CJPayBaseVCTypePopUp) {
        
        void (^transitionPopUpVCBlock)(BOOL) = ^(BOOL isShowMask){
            [containerView addSubview:shareViews.toView];
            [CJPayTransition transitionEnterPopUpVC:(CJPayPopUpBaseViewController *)cjpayToVC isShowMaskView:isShowMask completion:^(BOOL finished) {
                CJ_CALL_BLOCK(transitionVCCompletionBlock);
            }];
        };
        
        if (cjpayFromVC.vcType == CJPayBaseVCTypeFull || cjpayFromVC.vcType == CJPayBaseVCTypeHalf) {
            CJ_CALL_BLOCK(transitionPopUpVCBlock, YES);
            return;
        }
        
        if (cjpayFromVC.vcType == CJPayBaseVCTypePopUp) {
            [CJPayTransition transitionExitPopUpVC:(CJPayPopUpBaseViewController *)cjpayFromVC isShowMaskView:NO isRemoveBGImageView:NO completion:^(BOOL finished) {
                CJ_CALL_BLOCK(transitionPopUpVCBlock, NO);
            }];
            return;
        }
        
        CJ_CALL_BLOCK(transitionPopUpVCBlock, YES);
        return;
    }
    [self p_finishTransitionWithContext:transitionContext];
}

- (void)p_pushHalfVCWithTransitionContext:(id <UIViewControllerContextTransitioning>)transitionContext
                                shareView:(CJPayTransactionShareView *)shareViews
                                   fromVC:(CJPayHalfPageBaseViewController *)fromHalfVC
                                     toVC:(CJPayHalfPageBaseViewController *)toHalfVC
                               completion:(void (^)(BOOL))completion {
    
    CGFloat fromContainerViewHeight = fromHalfVC.containerHeight;
    CGFloat toContainerViewHeight = toHalfVC.containerHeight;

    UIView *containerView = transitionContext.containerView;
    [containerView addSubview:toHalfVC.view];
    
    if (fabs(fromContainerViewHeight - toContainerViewHeight) < CGFLOAT_EPSILON) {
        [CJPayTransition transitionEnterHalfVC:toHalfVC isShowMaskView:YES maskViewHeight:fromContainerViewHeight completion:completion];
    } else {
        // 不同高度半屏进场动画
        CGFloat fromContainerHeight = fromHalfVC.containerHeight;
        CGFloat toContainerHeight = toHalfVC.containerHeight;
        
        UIView *containerBottomView;
        if (fromContainerHeight < toContainerHeight) {
            containerBottomView = [UIView new];
            [containerView insertSubview:containerBottomView atIndex:0];

            containerBottomView.backgroundColor = fromHalfVC.containerView.backgroundColor;
            CGFloat containerBottomHeight = toContainerHeight - fromContainerHeight;
            containerBottomView.frame = CGRectMake(0, CJ_SCREEN_HEIGHT - containerBottomHeight, CJ_SCREEN_WIDTH, containerBottomHeight);

        } else {
            // 高半屏push矮半屏 && navi中无全屏时，需使fromHalfVC.transitionBGImageView隐藏
            CJPayNavigationController *navi;
            if ([fromHalfVC.navigationController isKindOfClass:CJPayNavigationController.class]) {
                navi = (CJPayNavigationController *)fromHalfVC.navigationController;
                if (![navi hasFullPageInNavi]) {
                    fromHalfVC.transitionBGImageView.hidden = YES;
                }
            }
        }
        
        [CJPayTransition transitionEnterHalfVC:toHalfVC
                                      fromHalfVC:fromHalfVC
                                 containerView:containerView
                             containerBottomView:containerBottomView
                                      completion:^(BOOL finished) {
            [containerBottomView removeFromSuperview];
            CJ_CALL_BLOCK(completion, finished);
            fromHalfVC.transitionBGImageView.hidden = NO;
        }];
    }
    
}

// 半屏push半屏转场 - 平移动画
- (void)p_pushHalfVCNewAnimationWithTransitionContext:(id <UIViewControllerContextTransitioning>)transitionContext
                                               fromVC:(CJPayHalfPageBaseViewController *)fromHalfVC
                                                 toVC:(CJPayHalfPageBaseViewController *)toHalfVC
                                           completion:(void (^)(BOOL))completion {
    CGFloat fromContainerViewHeight = fromHalfVC.containerHeight;
    CGFloat toContainerViewHeight = toHalfVC.containerHeight;

    UIView *containerView = transitionContext.containerView;
    [containerView addSubview:toHalfVC.view];
    
    UIView *containerBottomView = nil;
    if (fabs(fromContainerViewHeight - toContainerViewHeight) >= CGFLOAT_EPSILON) {
        
        containerBottomView = [UIView new];
        [containerView insertSubview:containerBottomView belowSubview:toHalfVC.view];
    }
    
//    if ([fromHalfVC.navigationController isKindOfClass:CJPayNavigationController.class]) {
//        CJPayNavigationController *navi = (CJPayNavigationController *)fromHalfVC.navigationController;
//        if (![navi hasFullPageInNavi]) {
//            fromHalfVC.transitionBGImageView.hidden = YES;
//        }
//    }
    [CJPayTransition transitionTranslationEnterHalfVC:toHalfVC fromHalfVC:fromHalfVC containerView:containerView containerBottomView:containerBottomView completion:^(BOOL finished) {
        
        [containerBottomView removeFromSuperview];
        CJ_CALL_BLOCK(completion, finished);
//        fromHalfVC.transitionBGImageView.hidden = NO;
    }];
    
}

- (void)p_insertBackViewWithShareView:(CJPayTransactionShareView *)shareView snapImage:(UIImage *)preViewSnapImage{
    if (![shareView.toVC isKindOfClass:CJPayBaseViewController.class]) {
        return;
    }
    UIImageView *preViewSnapImageView = [[UIImageView alloc] initWithImage:preViewSnapImage];
    CJPayBaseViewController *cjpayVC = (CJPayBaseViewController *)shareView.toVC;
    if (cjpayVC.transitionBGImageView) {
        [cjpayVC.transitionBGImageView removeFromSuperview];
    }
    cjpayVC.transitionBGImageView = preViewSnapImageView;
    [cjpayVC.view insertSubview:cjpayVC.transitionBGImageView atIndex:0];
}

- (BOOL)p_isNeedInsertSnapshotForVC:(CJPayBaseViewController *)vc {
    if (![CJPaySettingsManager shared].currentSettings.rdOptimizationConfig.isTransitionUseSnapshot) {
        return YES;
    }
    UINavigationController *navi = vc.navigationController;
    if ((navi.modalPresentationStyle == UIModalPresentationCustom || navi.modalPresentationStyle == UIModalPresentationOverFullScreen) && [self p_isAllHalfPageInNavi:navi]) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)p_isAllHalfPageInNavi:(UINavigationController *)navi {
    if (![navi isKindOfClass:CJPayNavigationController.class]) {
        return NO;
    }
    CJPayNavigationController *cjpayNavi = (CJPayNavigationController *)navi;
    
    __block BOOL isAllHalfPage = NO;
    [cjpayNavi.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:CJPayHalfPageBaseViewController.class]) {
            isAllHalfPage = YES;
        } else {
            isAllHalfPage = NO;
            *stop = YES;
        }
    }];
    return isAllHalfPage;
}
@end
