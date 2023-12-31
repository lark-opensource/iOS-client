//
//  CJPayTransitionManager.m
//  CJPay
//
//  Created by 王新华 on 2019/6/19.
//

#import "CJPayTransitionManager.h"

#import "CJPayPresentAnimator.h"
#import "CJPayDismissAnimator.h"
#import "CJPayPushAnimator.h"
#import "CJPayPopAnimator.h"
#import "CJPayUIMacro.h"

@interface CJPayTransitionManager()

@property (nonatomic, weak) CJPayNavigationController *navi;

@property (nonatomic, strong) CJPayPresentAnimator *presentAnimator;
@property (nonatomic, strong) CJPayDismissAnimator *dismissAnimator;
@property (nonatomic, strong) CJPayPushAnimator *pushAnimator;
@property (nonatomic, strong) CJPayPopAnimator *popAnimator;

@end

@implementation CJPayTransitionManager

+ (instancetype)shared {
    static CJPayTransitionManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [CJPayTransitionManager new];
    });
    return manager;
}

+ (instancetype)transitionManagerWithNavi:(CJPayNavigationController *)navi {
    CJPayTransitionManager *manager = [CJPayTransitionManager new];
    manager.navi = navi;
    return manager;
}

- (CJPayPresentAnimator *)presentAnimator {
    if (CJ_Pad) {
        return nil;
    }
    if (!_presentAnimator) {
        _presentAnimator = [CJPayPresentAnimator new];
    }
    return _presentAnimator;
}

- (CJPayDismissAnimator *)dismissAnimator {
    if (CJ_Pad) {
        return nil;
    }
    if (!_dismissAnimator) {
        _dismissAnimator = [CJPayDismissAnimator new];
        _dismissAnimator.naviViewController = self.navi;
    }
    return _dismissAnimator;
}

- (CJPayPushAnimator *)pushAnimator {
    if (!_pushAnimator) {
        _pushAnimator = [CJPayPushAnimator new];
    }
    return _pushAnimator;
}

- (CJPayPopAnimator *)popAnimator {
    if (!_popAnimator) {
        _popAnimator = [CJPayPopAnimator new];
        _popAnimator.naviViewController = self.navi;
    }
    return _popAnimator;
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {
    
    if (operation == UINavigationControllerOperationPush) {
        return self.pushAnimator;
    } else {
        return self.popAnimator;
    }
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {

    return self.popAnimator.isInteractive ? self.popAnimator : nil;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {

    return self.presentAnimator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {

    return self.dismissAnimator;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator {
    
    return self.dismissAnimator.isInteractive ? self.dismissAnimator : nil;
}

- (void)handleGesture:(UIPanGestureRecognizer *)panGesture {
    switch (panGesture.state) {
        case UIGestureRecognizerStateBegan:
            if (self.dismissAnimator.isInteractive) {
                return;
            }
            if (self.navi.viewControllers.count <= 1) {
                [self.dismissAnimator handleGesture:panGesture];
            } else {
                [self.popAnimator handleGesture:panGesture];
            }
            break;
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded:{
            if (self.dismissAnimator.isInteractive) {
                [self.dismissAnimator handleGesture:panGesture];
                CJPayLogDebug(@"---tansition: end present");
            } else if (self.popAnimator.isInteractive) {
                [self.popAnimator handleGesture:panGesture];
                CJPayLogDebug(@"---tansition: end transition");
            } else {
                CJPayLogDebug(@"---tansition: end others, %@ %@", self.dismissAnimator, self.popAnimator);
            }
            break;
        }
        default:
            CJPayLogDebug(@"---tansition: default %ld, %@ %@", panGesture.state, self.dismissAnimator, self.popAnimator);
            break;
    }
}

@end
