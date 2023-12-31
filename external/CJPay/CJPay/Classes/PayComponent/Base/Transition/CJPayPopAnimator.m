//
//  CJPayPopAnimatorV2.m
//  CJPay
//
//  Created by wangxiaohong on 2022/5/5.
//

#import "CJPayPopAnimator.h"

#import "CJPayUIMacro.h"
#import "CJPayTransitionUtil.h"
#import "CJPayPopUpBaseViewController.h"
#import "CJPayHalfPageBaseViewController.h"
#import "CJPayFullPageBaseViewController.h"
#import "UIViewController+CJTransition.h"
#import "UIViewController+CJPay.h"
#import "CJPaySettingsManager.h"

@interface CJPayPopAnimator()

@property (nonatomic, weak) id<UIViewControllerContextTransitioning> interactiveContext;
@property (nonatomic, weak) UIView *interactiveMaskView;

@end

@implementation CJPayPopAnimator

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    CJPayTransactionShareView *shareViews = [[CJPayTransactionShareView alloc] initWith:transitionContext];
    if ([CJPaySettingsManager shared].currentSettings.rdOptimizationConfig.isTransitionUseSnapshot) {
        [self p_popWithTransitionContext:transitionContext shareView:shareViews];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self p_popWithTransitionContext:transitionContext shareView:shareViews];
        });
    }
}

- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
    return [CJPayTransition animationDuration];
}

- (void)p_finishTransitionWithContext:(nonnull id<UIViewControllerContextTransitioning>)transitionContext {
    [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
}

- (void)p_popWithTransitionContext:(id <UIViewControllerContextTransitioning>)transitionContext shareView:(CJPayTransactionShareView *)shareViews {
    UIView *containerView = transitionContext.containerView;
    
    void (^normalExitBlock)(void) = ^(){
        [containerView insertSubview:shareViews.toView belowSubview:shareViews.fromView];
        [CJPayTransition transitionExitFullVC:shareViews.fromVC maskContainerView:shareViews.toView completion:^(BOOL finished) {
            [self p_finishTransitionWithContext:transitionContext];
        }];
    };
   
    if (![shareViews.fromVC isCJPayViewController] || ![shareViews.toVC isCJPayViewController] || CJ_Pad) {
        CJ_CALL_BLOCK(normalExitBlock);
        return;
    }
    
    CJPayBaseViewController *cjpayFromVC = (CJPayBaseViewController *)shareViews.fromVC;
    CJPayBaseViewController *cjpayToVC = (CJPayBaseViewController *)shareViews.toVC;
    
    if (cjpayFromVC.vcType == CJPayBaseVCTypeFull) {
        if (!cjpayFromVC.cjNeedAnimation) {
            // 针对透明webview转场特殊处理
            [containerView insertSubview:shareViews.toView belowSubview:shareViews.fromView];
            [self p_finishTransitionWithContext:transitionContext];
            return;
        }
        CJ_CALL_BLOCK(normalExitBlock);
        return;
    }
    
    if (cjpayFromVC.vcType == CJPayBaseVCTypeHalf) {

        if (cjpayToVC.vcType == CJPayBaseVCTypeFull) {
            [containerView insertSubview:shareViews.toView belowSubview:shareViews.fromView];
            @CJWeakify(self);
            [CJPayTransition transitionExitHalfVC:(CJPayHalfPageBaseViewController *)cjpayFromVC maskContainerView:shareViews.toView completion:^(BOOL finished) {
                @CJStrongify(self);
                [self p_finishTransitionWithContext:transitionContext];
            }];
            
            return;
        }
        
        if (cjpayToVC.vcType == CJPayBaseVCTypeHalf) {
            @CJWeakify(self);
            if ([cjpayToVC.navigationController isKindOfClass:CJPayNavigationController.class] && ((CJPayNavigationController *)cjpayToVC.navigationController).useNewHalfPageTransAnimation) {
                [self p_popHalfVCNewAnimationWithTransitionContext:transitionContext
                                                            fromVC:(CJPayHalfPageBaseViewController *)cjpayFromVC
                                                              toVC:(CJPayHalfPageBaseViewController *)cjpayToVC
                                                        completion:^(BOOL isFinish) {
                    @CJStrongify(self);
                    [self p_finishTransitionWithContext:transitionContext];
                }];
                return;
            }
            
            [self p_popHalfVCWithTransitionContext:transitionContext
                                            fromVC:(CJPayHalfPageBaseViewController *)cjpayFromVC
                                              toVC:(CJPayHalfPageBaseViewController *)cjpayToVC
                                        completion:^(BOOL isFinish) {
                @CJStrongify(self);
                [self p_finishTransitionWithContext:transitionContext];
            }];
            return;
        }

        if (cjpayToVC.vcType == CJPayBaseVCTypePopUp) {
            @CJWeakify(self);
            [CJPayTransition transitionExitHalfVC:(CJPayHalfPageBaseViewController *)cjpayFromVC maskContainerView:shareViews.toView maskViewHeight:0 isRemoveBGImageView:NO completion:^(BOOL finished) {
                @CJStrongify(self);
                cjpayFromVC.transitionBGImageView.hidden = YES;
                [containerView insertSubview:shareViews.toView belowSubview:shareViews.fromView];
                [CJPayTransition transitionEnterPopUpVC:(CJPayPopUpBaseViewController *)cjpayToVC isShowMaskView:NO completion:^(BOOL finished) {
                    [self p_finishTransitionWithContext:transitionContext];
                }];
            }];
            return;
        }
        return;
    }
    
    if (cjpayFromVC.vcType == CJPayBaseVCTypePopUp) {
        @CJWeakify(self);
        [self p_popPopUpVCWithShareView:shareViews transitionContext:transitionContext completion:^(BOOL finished) {
            @CJStrongify(self);
            [self p_finishTransitionWithContext:transitionContext];
        }];
        return;
    }
    
    [self p_finishTransitionWithContext:transitionContext];
}

- (void)p_popPopUpVCWithShareView:(CJPayTransactionShareView *)shareViews
                transitionContext:(id <UIViewControllerContextTransitioning>)transitionContext
                       completion:(void (^ __nullable)(BOOL finished))completion {
    
    if (![shareViews.fromVC isKindOfClass:CJPayPopUpBaseViewController.class]) {
        CJ_CALL_BLOCK(completion, YES);
        return;
    }
    
    CJPayPopUpBaseViewController *popupVC = (CJPayPopUpBaseViewController *)shareViews.fromVC;
    UIView *containerView = transitionContext.containerView;
    UIView *sourceView = shareViews.fromView;
    
    if (![shareViews.toVC isCJPayViewController]) {
        [containerView insertSubview:shareViews.toView belowSubview:sourceView];
        [CJPayTransition transitionExitPopUpVC:popupVC isShowMaskView:YES completion:completion];
        return;
    }
    
    CJPayBaseViewController *toCJPayVC = (CJPayBaseViewController *)shareViews.toVC;
    if (toCJPayVC.vcType == CJPayBaseVCTypeFull) {
        [containerView insertSubview:shareViews.toView belowSubview:sourceView];
        [CJPayTransition transitionExitPopUpVC:popupVC isShowMaskView:YES completion:completion];
        return;
    }
    
    if (toCJPayVC.vcType == CJPayBaseVCTypeHalf) {
        [containerView insertSubview:shareViews.toView belowSubview:sourceView];
        [CJPayTransition transitionExitPopUpVC:popupVC isShowMaskView:YES completion:completion];
        return;
    }
    
    if (toCJPayVC.vcType == CJPayBaseVCTypePopUp) {
        [CJPayTransition transitionExitPopUpVC:popupVC isShowMaskView:NO isRemoveBGImageView:NO completion:^(BOOL finished) {
            popupVC.transitionBGImageView.hidden = YES;
            [containerView insertSubview:shareViews.toView belowSubview:sourceView];
            [CJPayTransition transitionEnterPopUpVC:(CJPayPopUpBaseViewController *)toCJPayVC isShowMaskView:NO completion:completion];
        }];
    }
}

- (void)p_popHalfVCWithTransitionContext:(id <UIViewControllerContextTransitioning>)transitionContext
                                   fromVC:(CJPayHalfPageBaseViewController *)fromHalfVC
                                     toVC:(CJPayHalfPageBaseViewController *)toHalfVC
                               completion:(void (^)(BOOL))completion {
    
    CGFloat fromContainerViewHeight = fromHalfVC.containerHeight;
    CGFloat toContainerViewHeight = toHalfVC.containerHeight;
    
    UIView *containerView = transitionContext.containerView;
    
    if (fabs(fromContainerViewHeight - toContainerViewHeight) < CGFLOAT_EPSILON) {
        UIView *containerView = transitionContext.containerView;
        [containerView insertSubview:toHalfVC.view belowSubview:fromHalfVC.view];
        [CJPayTransition transitionExitHalfVC:fromHalfVC maskContainerView:toHalfVC.view maskViewHeight:fromContainerViewHeight completion:completion];
    } else {
        // 不同高度半屏退场动画
        [containerView addSubview:toHalfVC.view];
        [containerView addSubview:fromHalfVC.view];
        CGFloat fromContainerHeight = fromHalfVC.containerHeight;
        CGFloat toContainerHeight = toHalfVC.containerHeight;

        UIView *containerBottomView;  
        if (toContainerHeight < fromContainerHeight) {
            containerBottomView = [UIView new];
            [containerView insertSubview:containerBottomView atIndex:0];
    
            containerBottomView.backgroundColor = toHalfVC.containerView.backgroundColor;
            CGFloat containerBottomHeight = fromContainerHeight - toContainerHeight;
            containerBottomView.frame = CGRectMake(0, CJ_SCREEN_HEIGHT - containerBottomHeight, CJ_SCREEN_WIDTH, containerBottomHeight);
        } else {
            // 矮半屏pop到高半屏 && navi中无全屏时，需使fromHalfVC.transitionBGImageView隐藏
            CJPayNavigationController *navi;
            if ([toHalfVC.navigationController isKindOfClass:CJPayNavigationController.class]) {
                navi = (CJPayNavigationController *)toHalfVC.navigationController;
                if (![navi hasFullPageInNavi]) {
                    toHalfVC.transitionBGImageView.hidden = YES;
                }
            }
        }
        
        [CJPayTransition transitionExitHalfVC:fromHalfVC
                                     toHalfVC:toHalfVC
                                containerView:containerView
                          containerBottomView:containerBottomView
                                   completion:^(BOOL finished){
            
            [containerBottomView removeFromSuperview];
            CJ_CALL_BLOCK(completion, finished);
            toHalfVC.transitionBGImageView.hidden = NO;
        }];
    }
}

// 半屏pop半屏转场 - 平移动画
- (void)p_popHalfVCNewAnimationWithTransitionContext:(id <UIViewControllerContextTransitioning>)transitionContext
                                   fromVC:(CJPayHalfPageBaseViewController *)fromHalfVC
                                     toVC:(CJPayHalfPageBaseViewController *)toHalfVC
                              completion:(void (^)(BOOL))completion {
    
    CGFloat fromContainerViewHeight = fromHalfVC.containerHeight;
    CGFloat toContainerViewHeight = toHalfVC.containerHeight;

    UIView *containerView = transitionContext.containerView;
    [containerView insertSubview:toHalfVC.view belowSubview:fromHalfVC.view];
    
    UIView *containerBottomView = nil;
    if (fabs(fromContainerViewHeight - toContainerViewHeight) >= CGFLOAT_EPSILON) {

        containerBottomView = [UIView new];
        [containerView insertSubview:containerBottomView belowSubview:fromHalfVC.view];
    }
    
    [CJPayTransition transitionTranslationExitHalfVC:fromHalfVC
                                            toHalfVC:toHalfVC
                                       containerView:containerView
                                 containerBottomView:containerBottomView
                                          completion:^(BOOL finished) {
        [containerBottomView removeFromSuperview];
        CJ_CALL_BLOCK(completion, finished);
    }];
    
}

// 判断导航栈中是否有全屏页面
- (BOOL)p_navHasFullPageVC:(CJPayBaseViewController *)vc {
    UINavigationController *nav = vc.navigationController;
    __block BOOL hasFullPageVC = NO;
    [nav.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:CJPayFullPageBaseViewController.class]) {
            hasFullPageVC = YES;
            *stop = YES;
        }
    }];
    return hasFullPageVC;
}


- (void)handleGesture:(UIPanGestureRecognizer *)panGesture {
    CGPoint  translation = [panGesture translationInView:panGesture.view];
    CGFloat percentComplete = 0.0;
    
    //左右滑动的百分比
    percentComplete = translation.x / (self.naviViewController.view.frame.size.width);
    percentComplete = MAX(0, percentComplete);
    
    switch (panGesture.state) {
        case UIGestureRecognizerStateBegan:
            if ([panGesture locationInView:panGesture.view].x > gCJTransitionMaxX) {
                return;
            }
            self.isInteractive = YES;
            [self.naviViewController popViewControllerAnimated:YES];
            break;
        case UIGestureRecognizerStateChanged:{
            //手势过程中，通过updateInteractiveTransition设置转场过程动画进行的百分比，然后系统会根据百分比自动布局动画控件，不用我们控制了
            if (self.isInteractive) {
                [self updateInteractiveTransition:percentComplete];
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:{
            //手势完成后结束标记, 且滑动超过屏幕四分之一或速度超过500，过则finishInteractiveTransition完成转场操作，否则取消转场操作，转场失败
            if (self.isInteractive) {
                if (percentComplete > 0.25 || [panGesture velocityInView:panGesture.view].x > 500) {
                    [self finishInteractiveTransition];
                } else {
                    [self cancelInteractiveTransition];
                }
            }
            self.isInteractive = NO;
            break;
        }
        default:
            break;
    }
}

#pragma mark - UIViewControllerInteractiveTransitioning

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    self.interactiveContext = transitionContext;
    CJPayTransactionShareView *shareViews = [[CJPayTransactionShareView alloc] initWith:transitionContext];
    
    [[transitionContext containerView] insertSubview:shareViews.toView belowSubview:shareViews.fromView];
    
    self.interactiveMaskView = [CJPayTransition addMaskViewForView:shareViews.toView];
}

- (void)updateInteractiveTransition:(CGFloat)percentComplete
{
    [super updateInteractiveTransition:percentComplete];
    UIViewController *fullVC = [self.interactiveContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    [CJPayTransition updateInteractiveFullVC:fullVC maskView:self.interactiveMaskView percentComplete:percentComplete completion:nil];
}

- (void)finishInteractiveTransition
{
    [super finishInteractiveTransition];
    UIViewController *fromVC = [self.interactiveContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [self.interactiveContext viewControllerForKey:UITransitionContextToViewControllerKey];
    @CJWeakify(fromVC);
    @CJWeakify(self);
    [CJPayTransition finishInteractiveFullVC:fromVC isCancel:NO maskView:self.interactiveMaskView completion:^(BOOL finished) {
        @CJStrongify(fromVC);
        @CJStrongify(self);
        if (fromVC.modalPresentationStyle == UIModalPresentationCustom) {
            [toVC endAppearanceTransition];
        }
        [self.interactiveContext completeTransition:YES];
    }];
}

- (void)cancelInteractiveTransition
{
    [super cancelInteractiveTransition];
    UIViewController *fromVC = [self.interactiveContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [self.interactiveContext viewControllerForKey:UITransitionContextToViewControllerKey];
    @CJWeakify(fromVC);
    @CJWeakify(self);
    [CJPayTransition finishInteractiveFullVC:fromVC isCancel:YES maskView:self.interactiveMaskView completion:^(BOOL finished) {
        @CJStrongify(fromVC);
        @CJStrongify(self);
        [self.interactiveContext completeTransition:NO];
        if (fromVC.modalPresentationStyle == UIModalPresentationFullScreen) {
            [toVC.view removeFromSuperview];
        }
    }];
}

@end
