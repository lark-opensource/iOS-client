//
//  CJPayDismissAnimator.m
//  CJPay
//
//  Created by wangxiaohong on 2022/5/5.
//

#import "CJPayDismissAnimator.h"

#import "CJPayNavigationController.h"
#import "CJPaySDKMacro.h"
#import "CJPayHalfPageBaseViewController.h"
#import "CJPayPopUpBaseViewController.h"
#import "CJPayTransitionUtil.h"
#import "CJPaySettingsManager.h"

@interface CJPayDismissAnimator()

@property (nonatomic, weak) id<UIViewControllerContextTransitioning> transitionContext;
@property (nonatomic, weak) UIView *interactiveMaskView;

@end

@implementation CJPayDismissAnimator

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
    UIViewController *sourceVC = shareViews.fromVC;
    
    BOOL isDismissToHalfVC = NO;
    if ([shareViews.toVC isKindOfClass:CJPayNavigationController.class]) {
        CJPayNavigationController *navi = (CJPayNavigationController *)shareViews.toVC;
        isDismissToHalfVC = [[[navi viewControllers] lastObject] isKindOfClass:CJPayHalfPageBaseViewController.class];
    }
    if (isDismissToHalfVC && [self p_isSingleHalfPageCJPayNavi:shareViews.fromVC]) {
        
        CJPayNavigationController *toNavi = (CJPayNavigationController *)shareViews.toVC;
        CJPayNavigationController *fromNavi = (CJPayNavigationController *)shareViews.fromVC;

        CJPayHalfPageBaseViewController *fromHalfVC = [fromNavi.viewControllers firstObject];
        CJPayHalfPageBaseViewController *toHalfVC = [toNavi.viewControllers lastObject];
        
        @CJWeakify(self)
        void (^transitionVCCompletionBlock)(BOOL) = ^(BOOL isFinish) {
            @CJStrongify(self);
            [self p_finishTransitionWithContext:transitionContext];
        };
        
        if (fromHalfVC.animationType != HalfVCEntranceTypeFromRight) {
            [self p_dismissNaviController:(CJPayNavigationController *)fromHalfVC.navigationController withShareViews:shareViews transition:transitionContext completion:transitionVCCompletionBlock];
            return;
        }
        
        if (fromNavi.useNewHalfPageTransAnimation || toNavi.useNewHalfPageTransAnimation) {
            [self p_dismissHalfVCNewAnimationWithTransitionContext:transitionContext shareViews:shareViews fromVC:fromHalfVC toVC:toHalfVC completion:transitionVCCompletionBlock];
        } else {
            [self p_dismissHalfVCWithTransitionContext:transitionContext shareViews:shareViews fromVC:fromHalfVC toVC:toHalfVC completion:transitionVCCompletionBlock];
        }
        return;
    }
    
    if ([sourceVC isKindOfClass:CJPayNavigationController.class]) {
        @CJWeakify(self);
        [self p_dismissNaviController:(CJPayNavigationController *)sourceVC withShareViews:shareViews transition:transitionContext completion:^(BOOL isFinish) {
            @CJStrongify(self);
            [self p_finishTransitionWithContext:transitionContext];
        }];
        return;
    }
    
    [[transitionContext containerView] insertSubview:shareViews.toView belowSubview:shareViews.fromView];
    if ([sourceVC isKindOfClass:CJPayBaseViewController.class]) {
        @CJWeakify(self);
        [self p_dismissViewController:sourceVC
                           shareViews:shareViews
                           isShowMask:((CJPayBaseViewController *)sourceVC).isShowMask
                           completion:^(BOOL isFinish) {
            @CJStrongify(self);
            [self p_finishTransitionWithContext:transitionContext];
        }];
    } else {
        [self p_finishTransitionWithContext:transitionContext];
    }
}

- (void)p_finishTransitionWithContext:(nonnull id<UIViewControllerContextTransitioning>)transitionContext {
    [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
}

- (void)p_dismissNaviWithOneViewController:(CJPayNavigationController *)naviVC
                                shareViews:(CJPayTransactionShareView *)shareViews
                                transition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext
                                completion:(void (^)(BOOL isFinish))completion {
    [[transitionContext containerView] insertSubview:shareViews.toView belowSubview:shareViews.fromView];
    
    UIViewController *transVC = naviVC.viewControllers.firstObject;
    if (![transVC isKindOfClass:CJPayBaseViewController.class]) {
        [CJPayTransition transitinNormalView:shareViews.fromView transitionType:CJPayTransitionV2TypeExit maskView:shareViews.toView completion:completion];
        return;
    }
    // navi中仅有半屏页面进行dismiss时，强制修改其AnimatedType
    CJPayBaseViewController *cjpayTransVC = (CJPayBaseViewController *)transVC;
    BOOL needShowMask = [naviVC.view isShowMask] || cjpayTransVC.isShowMask;
    
    UIColor *naviBGColor = naviVC.view.backgroundColor;
    naviVC.view.backgroundColor = UIColor.clearColor;
    if (cjpayTransVC.vcType == CJPayBaseVCTypeHalf) {
        [self p_forceDismissHalfVC:(CJPayHalfPageBaseViewController *)cjpayTransVC
                 maskContainerView:needShowMask ? shareViews.toVC.view : nil
                        completion:^(BOOL isFinish) {
            naviVC.view.backgroundColor = naviBGColor;
            CJ_CALL_BLOCK(completion, isFinish);
        }];
        return;
    }
    
    [self p_dismissViewController:transVC shareViews:shareViews isShowMask:needShowMask completion:^(BOOL isFinish) {
        naviVC.view.backgroundColor = naviBGColor;
        CJ_CALL_BLOCK(completion, isFinish);
    }];
}

- (void)p_dismissNaviWithMultiViewController:(CJPayNavigationController *)naviVC
                                  shareViews:(CJPayTransactionShareView *)shareViews
                                  transition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext
                                  completion:(void (^)(BOOL isFinish))completion {
    
    CJPayBaseViewController *dismissVC = [self p_needExitVCWithCJPayNavigationController:naviVC];
    UIViewController *oriLastVC = naviVC.viewControllers.lastObject;
    // 将navi背景色置为clear前先判断是否有蒙层
    BOOL needShowMask = [naviVC.view isShowMask];
    naviVC.view.backgroundColor = [UIColor clearColor];
    
    if (!dismissVC || !oriLastVC || ![oriLastVC isCJPayViewController]) {
        [[transitionContext containerView] insertSubview:shareViews.toView belowSubview:shareViews.fromView];
        [CJPayTransition transitinNormalView:shareViews.fromView transitionType:CJPayTransitionV2TypeExit maskView:shareViews.toView completion:completion];
        return;
    }
    
    CJPayBaseViewController *lastVC = (CJPayBaseViewController *)oriLastVC;
    
    void (^updateContainerViewBlock)(void) = ^(){
        UIView *containerView = [transitionContext containerView];
        [containerView addSubview:shareViews.toView];
        [containerView addSubview:dismissVC.view];
        [containerView addSubview:lastVC.view];
    };
    
    if (dismissVC == lastVC) {
        CJ_CALL_BLOCK(updateContainerViewBlock);
        needShowMask = needShowMask || dismissVC.isShowMask;
        if (dismissVC.vcType == CJPayBaseVCTypeHalf) {
            [self p_forceDismissHalfVC:(CJPayHalfPageBaseViewController *)dismissVC
                     maskContainerView:needShowMask ? shareViews.toVC.view : nil
                            completion:completion];
        } else {
            [self p_dismissViewController:dismissVC shareViews:shareViews isShowMask:needShowMask completion:completion];
        }
        return;
    }
    
    if (dismissVC.vcType == CJPayBaseVCTypePopUp && lastVC.vcType == CJPayBaseVCTypePopUp) {
        CJ_CALL_BLOCK(updateContainerViewBlock);
        [CJPayTransition transitionExitPopUpVC:(CJPayPopUpBaseViewController *)lastVC isShowMaskView:YES completion:completion];
        return;
    }
    
    if (dismissVC.vcType == CJPayBaseVCTypeHalf && lastVC.vcType == CJPayBaseVCTypeHalf) {
        CJ_CALL_BLOCK(updateContainerViewBlock);
        needShowMask = needShowMask || dismissVC.isShowMask;
        [self p_forceDismissHalfVC:(CJPayHalfPageBaseViewController *)dismissVC
                 maskContainerView:needShowMask ? shareViews.toVC.view : nil
                        completion:completion];
        return;
    }
    
    if (dismissVC.vcType == CJPayBaseVCTypeHalf && lastVC.vcType == CJPayBaseVCTypePopUp) {
        CJ_CALL_BLOCK(updateContainerViewBlock);
        [CJPayTransition transitionExitPopUpVC:(CJPayPopUpBaseViewController *)lastVC isShowMaskView:YES completion:nil];
        needShowMask = needShowMask || dismissVC.isShowMask;
        [self p_forceDismissHalfVC:(CJPayHalfPageBaseViewController *)dismissVC
                 maskContainerView:needShowMask ? shareViews.toVC.view : nil
                        completion:completion];
        return;
    }
    
    if (dismissVC.vcType == CJPayBaseVCTypeFull && lastVC.vcType == CJPayBaseVCTypeHalf) {
        CJ_CALL_BLOCK(updateContainerViewBlock);
        [self p_forceDismissHalfVC:(CJPayHalfPageBaseViewController *)lastVC
                 maskContainerView:dismissVC.view
                        completion:^(BOOL isFinish) {
            [lastVC.view removeFromSuperview];
            [CJPayTransition transitionExitFullVC:(CJPayFullPageBaseViewController *)dismissVC maskContainerView:shareViews.toVC.view completion:completion];
        }];
        return;
    }
    
    if (dismissVC.vcType == CJPayBaseVCTypeFull && lastVC.vcType == CJPayBaseVCTypePopUp) {
        CJ_CALL_BLOCK(updateContainerViewBlock);
        [CJPayTransition transitionExitPopUpVC:(CJPayPopUpBaseViewController *)lastVC isShowMaskView:YES completion:nil];
        [CJPayTransition transitionExitFullVC:dismissVC maskContainerView:shareViews.toVC.view completion:completion];
        return;
    }
    
    [CJPayTransition transitinNormalView:shareViews.fromView transitionType:CJPayTransitionV2TypeExit maskView:shareViews.toView completion:completion];
    return;
}

- (void)p_forceDismissHalfVC:(CJPayHalfPageBaseViewController *)cjpayVC maskContainerView:(UIView *)maskContainerView completion:(void (^)(BOOL isFinish))completion {
    if (![cjpayVC isKindOfClass:CJPayHalfPageBaseViewController.class] || ![cjpayVC.navigationController isKindOfClass:CJPayNavigationController.class]) {
        CJ_CALL_BLOCK(completion, YES);
        return;
    }
    CJPayDismissAnimatedType naviDismissType = ((CJPayNavigationController *)cjpayVC.navigationController).dismissAnimatedType;
    if (naviDismissType == CJPayDismissAnimatedTypeNone) {
        CJ_CALL_BLOCK(completion, YES);
        return;
    }
    
    CJPayHalfPageBaseViewController *halfVC = (CJPayHalfPageBaseViewController *)cjpayVC;
    halfVC.animationType = naviDismissType == CJPayDismissAnimatedTypeFromRight ? HalfVCEntranceTypeFromRight : HalfVCEntranceTypeFromBottom;
    [CJPayTransition transitionExitHalfVC:halfVC maskContainerView:maskContainerView completion:completion];
}

- (void)p_dismissNaviController:(CJPayNavigationController *)naviVC withShareViews:(CJPayTransactionShareView *)shareViews transition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext completion:(void (^)(BOOL isFinish))completion {
    if (![naviVC isKindOfClass:CJPayNavigationController.class]) {
        [CJPayTransition transitinNormalView:shareViews.fromView transitionType:CJPayTransitionV2TypeExit maskView:shareViews.toView completion:completion];
        return;
    }
    
    if (naviVC.viewControllers.count == 1) {
        [self p_dismissNaviWithOneViewController:naviVC shareViews:shareViews transition:transitionContext completion:completion];
    } else {
//        UIColor *bgColor = naviVC.view.backgroundColor;
//        naviVC.view.backgroundColor = [UIColor clearColor];
        [self p_dismissNaviWithMultiViewController:naviVC shareViews:shareViews transition:transitionContext completion:completion];
//        [self p_dismissNaviWithMultiViewController:naviVC shareViews:shareViews transition:transitionContext completion:^(BOOL isFinish) {
////            naviVC.view.backgroundColor = bgColor;
//            CJ_CALL_BLOCK(completion, isFinish);
//        }];
    }
    return;
}

- (void)p_dismissViewController:(UIViewController *)dismissVC
                     shareViews:(CJPayTransactionShareView *)shareViews
                     isShowMask:(BOOL)isShowMask
                     completion:(void (^)(BOOL isFinish))completion  {
    
    if (![dismissVC isKindOfClass:CJPayBaseViewController.class]) {
        CJ_CALL_BLOCK(completion, YES);
        return;
    }
    
    CJPayBaseViewController *cjpayVC = (CJPayBaseViewController *)dismissVC;
    
    if (cjpayVC.vcType == CJPayBaseVCTypeFull) {
        [CJPayTransition transitionExitFullVC:(CJPayFullPageBaseViewController *)cjpayVC
                              maskContainerView:isShowMask ? shareViews.toVC.view : nil
                                     completion:completion];
        return;
    }
    
    if (cjpayVC.vcType == CJPayBaseVCTypeHalf) {
        [CJPayTransition transitionExitHalfVC:(CJPayHalfPageBaseViewController *)cjpayVC
                              maskContainerView:isShowMask ? shareViews.toVC.view : nil
                                     completion:completion];
        return;
    }
    
    if (cjpayVC.vcType == CJPayBaseVCTypePopUp) {
        [CJPayTransition transitionExitPopUpVC:(CJPayPopUpBaseViewController *)cjpayVC isShowMaskView:YES completion:completion];
        return;
    }
    CJ_CALL_BLOCK(completion, YES);
}

- (void)p_dismissHalfVCWithTransitionContext:(id <UIViewControllerContextTransitioning>)transitionContext
                                  shareViews:(CJPayTransactionShareView *)shareViews
                                      fromVC:(CJPayHalfPageBaseViewController *)fromHalfVC
                                        toVC:(CJPayHalfPageBaseViewController *)toHalfVC
                                  completion:(void (^)(BOOL))completion {
    
    
    CGFloat fromContainerViewHeight = fromHalfVC.containerHeight;
    CGFloat toContainerViewHeight = toHalfVC.containerHeight;
    
    UIView *containerView = transitionContext.containerView;
    
    if (fabs(fromContainerViewHeight - toContainerViewHeight) < CGFLOAT_EPSILON) {
        [self p_dismissNaviController:(CJPayNavigationController *)fromHalfVC.navigationController withShareViews:shareViews transition:transitionContext completion:completion];
    } else {
        // 不同高度半屏退场动画
//        [containerView addSubview:fromHalfVC.view];
        [containerView insertSubview:shareViews.toView belowSubview:shareViews.fromView];

        CGFloat fromContainerHeight = fromHalfVC.containerHeight;
        CGFloat toContainerHeight = toHalfVC.containerHeight;

        UIView *containerBottomView;
        containerBottomView = [UIView new];
        [containerView insertSubview:containerBottomView atIndex:0];
        
        containerBottomView.backgroundColor = toHalfVC.containerView.backgroundColor;
        CGFloat containerBottomHeight = fromContainerHeight - toContainerHeight;
        containerBottomView.frame = CGRectMake(0, CJ_SCREEN_HEIGHT - containerBottomHeight, CJ_SCREEN_WIDTH, containerBottomHeight);
        
        [CJPayTransition transitionExitHalfVC:fromHalfVC
                                     toHalfVC:toHalfVC
                                containerView:containerView
                          containerBottomView:containerBottomView
                                   completion:^(BOOL finished){
            
            [containerBottomView removeFromSuperview];
            CJ_CALL_BLOCK(completion, finished);
        }];
    }
}

- (BOOL)p_isSingleHalfPageCJPayNavi:(UIViewController *)vc {
    if (![vc isKindOfClass:CJPayNavigationController.class]) {
        return NO;
    }
    CJPayNavigationController *navi = (CJPayNavigationController *)vc;
    return navi.viewControllers.count == 1 && [[navi.viewControllers firstObject] isKindOfClass:CJPayHalfPageBaseViewController.class];
}

// 半屏dismiss半屏转场 - 平移动画
- (void)p_dismissHalfVCNewAnimationWithTransitionContext:(id <UIViewControllerContextTransitioning>)transitionContext
                                              shareViews:(CJPayTransactionShareView *)shareViews
                                   fromVC:(CJPayHalfPageBaseViewController *)fromHalfVC
                                     toVC:(CJPayHalfPageBaseViewController *)toHalfVC
                              completion:(void (^)(BOOL))completion {
     
    CGFloat fromContainerViewHeight = fromHalfVC.containerHeight;
    CGFloat toContainerViewHeight = toHalfVC.containerHeight;
 
    UIView *containerView = transitionContext.containerView;
    [containerView insertSubview:shareViews.toView belowSubview:shareViews.fromView];

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


//返回导航栈中需要执行退出动画的viewController，优先级：全屏 > 半屏 > 弹框
- (CJPayBaseViewController *)p_needExitVCWithCJPayNavigationController:(CJPayNavigationController *)navigationController {
    __block CJPayBaseViewController *exitVC;
    [navigationController.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:CJPayBaseViewController.class]) {
            CJPayBaseViewController *currentVC = (CJPayBaseViewController *)obj;
            if (!exitVC) {
                exitVC = currentVC;
            }
            if (currentVC.vcType == CJPayBaseVCTypeFull) {
                exitVC = currentVC;
            }
            if (currentVC.vcType == CJPayBaseVCTypeHalf && exitVC.vcType != CJPayBaseVCTypeFull) {
                exitVC = currentVC;
            }
            if (currentVC.vcType == CJPayBaseVCTypePopUp && exitVC.vcType == CJPayBaseVCTypePopUp) {
                exitVC = currentVC;
            }
        }
    }];
    return exitVC;
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
            [self.naviViewController dismissViewControllerAnimated:YES completion:nil];
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
    self.transitionContext = transitionContext;
    CJPayTransactionShareView *shareViews = [[CJPayTransactionShareView alloc] initWith:transitionContext];
    
    [[transitionContext containerView] insertSubview:shareViews.toView belowSubview:shareViews.fromView];
    self.interactiveMaskView = [CJPayTransition addMaskViewForView:shareViews.toView];
}

- (void)updateInteractiveTransition:(CGFloat)percentComplete
{
    [super updateInteractiveTransition:percentComplete];
    UIViewController *fromVC = [self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    [CJPayTransition updateInteractiveFullVC:fromVC maskView:self.interactiveMaskView percentComplete:percentComplete completion:nil];
}

- (void)finishInteractiveTransition
{
    [super finishInteractiveTransition];
    UIViewController *fromVC = [self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    @CJWeakify(fromVC);
    @CJWeakify(self);
    [CJPayTransition finishInteractiveFullVC:fromVC isCancel:NO maskView:self.interactiveMaskView completion:^(BOOL finished) {
        @CJStrongify(fromVC);
        @CJStrongify(self);
        if (fromVC.modalPresentationStyle == UIModalPresentationCustom) {
            [toVC endAppearanceTransition];
        }
        [self.transitionContext completeTransition:YES];
    }];
}

- (void)cancelInteractiveTransition
{
    [super cancelInteractiveTransition];
    UIViewController *fromVC = [self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    @CJWeakify(fromVC);
    @CJWeakify(self);
    [CJPayTransition finishInteractiveFullVC:fromVC isCancel:YES maskView:self.interactiveMaskView completion:^(BOOL finished) {
        @CJStrongify(fromVC);
        @CJStrongify(self);
        [self.transitionContext completeTransition:NO];
        if (fromVC.modalPresentationStyle == UIModalPresentationFullScreen) {
            [toVC.view removeFromSuperview];
        }
    }];
}


@end
