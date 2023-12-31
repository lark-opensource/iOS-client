//
//  OPVideoFullScreenEdgeSwipeTransition.m
//  OPPluginBiz
//
//  Created by zhujingcheng on 2/24/23.
//

#import "OPVideoFullScreenEdgeSwipeTransition.h"

@interface OPVideoFullScreenInteractiveTranstion ()

@property (nonatomic, assign, readwrite) BOOL isInteracting;

@end

@implementation OPVideoFullScreenInteractiveTranstion

- (void)addScreenEdgePanGesture {
    UIScreenEdgePanGestureRecognizer *gesture = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(onScreenEdgePanGestureRecognized:)];
    gesture.edges = UIRectEdgeLeft;
    [self.vc.view addGestureRecognizer:gesture];
}

- (void)onScreenEdgePanGestureRecognized:(UIScreenEdgePanGestureRecognizer *)recognizer {
    if (!UIDeviceOrientationIsPortrait(UIDevice.currentDevice.orientation)) {
        return;
    }
    CGPoint translation = [recognizer translationInView:self.vc.view];
    CGFloat percent = translation.x / self.vc.view.bounds.size.width;
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            self.isInteracting = YES;
            [self.vc dismissViewControllerAnimated:YES completion:nil];
            break;
        case UIGestureRecognizerStateChanged:
            [self updateInteractiveTransition:percent];
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            [self cancelInteractiveTransition];
            self.isInteracting = NO;
            break;
        case UIGestureRecognizerStateEnded: {
            CGPoint velocity = [recognizer velocityInView:self.vc.view];
            if (percent > 0.5 || velocity.x > 0) {
                [self finishInteractiveTransition];
            } else {
                [self cancelInteractiveTransition];
            }
            self.isInteracting = NO;
        }
            break;
        default:
            break;
    }
}

@end

@interface OPVideoFullScreenEdgeSwipeTransition ()

@property (nonatomic, strong, readwrite) OPVideoFullScreenInteractiveTranstion *interactiveTransition;
@property (nonatomic, copy) dispatch_block_t dismissCompletion;

@end

@implementation OPVideoFullScreenEdgeSwipeTransition

- (instancetype)initWithVC:(UIViewController *)vc dismissCompletion:(dispatch_block_t)dismissCompletion {
    self = [super init];
    if (self) {
        _dismissCompletion = dismissCompletion;
        _interactiveTransition = [[OPVideoFullScreenInteractiveTranstion alloc] init];
        _interactiveTransition.vc = vc;
        [_interactiveTransition addScreenEdgePanGesture];
    }
    return self;
}

- (void)animateTransition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    CGRect initFrame = [transitionContext initialFrameForViewController:fromVC];
    CGRect targetFrame = CGRectOffset(initFrame, self.interactiveTransition.vc.view.bounds.size.width, 0);
    [transitionContext.containerView insertSubview:toVC.view atIndex:0];
    
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    [UIView animateWithDuration:duration animations:^{
        fromVC.view.frame = targetFrame;
    } completion:^(BOOL finished) {
        if (transitionContext.transitionWasCancelled) {
            [toVC.view removeFromSuperview];
        }
        [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
        if (!transitionContext.transitionWasCancelled) {
            !self.dismissCompletion ?: self.dismissCompletion();
        }
    }];
}

- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.25;
}

@end



