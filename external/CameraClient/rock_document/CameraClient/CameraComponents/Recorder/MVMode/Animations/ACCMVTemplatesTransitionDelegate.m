//
//  ACCMVTemplatesTransitionDelegate.m
//  CameraClient
//
//  Created by long.chen on 2020/3/4.
//

#import "ACCMVTemplatesTransitionDelegate.h"
#import "ACCZoomContextProviderProtocol.h"
#import "ACCZoomPushAnimator.h"
#import "ACCZoomPopAnimator.h"

typedef NS_ENUM(NSUInteger, ACCMVTransitionTriggerDirection) {
    ACCMVTransitionTriggerDirectionNone = 0,
    ACCMVTransitionTriggerDirectionRight,
    ACCMVTransitionTriggerDirectionLeft,
};

@interface ACCMVTemplatesTransitionDelegate () <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIViewController<ACCSlidePushContextProviderProtocol> *viewController;

@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong) UIPercentDrivenInteractiveTransition *percentDrivenTransition;
@property (nonatomic, strong) ACCZoomPopAnimator *popAnimator;
@property (nonatomic, assign) ACCMVTransitionTriggerDirection triggerDirection;


@end

@implementation ACCMVTemplatesTransitionDelegate

#pragma mark - ACCPanInteractionTransitionProtocol

- (void)wireToViewController:(UIViewController<ACCSlidePushContextProviderProtocol> *)viewController
{
    self.viewController = viewController;
    [self.viewController.view addGestureRecognizer:self.panGestureRecognizer];
}

#pragma mark - UINavigationControllerDelegate

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController *)fromVC
                                                 toViewController:(UIViewController *)toVC
{
    if (operation == UINavigationControllerOperationPush) {
        BOOL zoomTransiton = [fromVC conformsToProtocol:@protocol(ACCZoomContextOutterProviderProtocol)] && [toVC conformsToProtocol:@protocol(ACCZoomContextInnerProviderProtocol)];
        if (zoomTransiton) {
            return [ACCZoomPushAnimator new];
        }
    } else if (operation == UINavigationControllerOperationPop &&
               [fromVC conformsToProtocol:@protocol(ACCZoomContextInnerProviderProtocol)] &&
               [toVC conformsToProtocol:@protocol(ACCZoomContextOutterProviderProtocol)]) {
        return self.popAnimator;
    }
    return nil;
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                         interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController
{
    return self.percentDrivenTransition;
}

#pragma mark - Actions

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    CGFloat progress = [gestureRecognizer translationInView:self.viewController.view].x / self.viewController.view.bounds.size.width;
    progress = fabs(progress);
    progress = MIN(1.0, MAX(0.0, progress));
    
    CGPoint currentLocation = [gestureRecognizer locationInView:self.viewController.view];
    static CGPoint startLocation;
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        startLocation = currentLocation;
        self.percentDrivenTransition = [[UIPercentDrivenInteractiveTransition alloc]init];
        if (self.triggerDirection == ACCMVTransitionTriggerDirectionRight) {
            self.popAnimator.interactionInProgress = YES;
            [self.viewController.navigationController popViewControllerAnimated:YES];
        } else if (self.triggerDirection == ACCMVTransitionTriggerDirectionLeft) {
            [self.viewController.navigationController pushViewController:[self.viewController slidePushTargetViewController] animated:YES];
        }
    } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        [self.percentDrivenTransition updateInteractiveTransition:progress];
        if (self.triggerDirection == ACCMVTransitionTriggerDirectionRight) {
            [self.popAnimator updateAnimationWithLocation:currentLocation startLocation:startLocation];
        }
    } else if (gestureRecognizer.state == UIGestureRecognizerStateCancelled
              || gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if (progress > 0.3) {
            [self.percentDrivenTransition finishInteractiveTransition];
            if (self.triggerDirection == ACCMVTransitionTriggerDirectionRight) {
                [self.popAnimator finishAnimation];
            }
        } else {
            [self.percentDrivenTransition cancelInteractiveTransition];
            if (self.triggerDirection == ACCMVTransitionTriggerDirectionRight) {
                [self.popAnimator cancelAnimation];
            }
        }
        self.popAnimator.interactionInProgress = NO;
        self.percentDrivenTransition = nil;
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.panGestureRecognizer) {
        CGPoint velocity = [self.panGestureRecognizer velocityInView:self.viewController.view];
        if (velocity.x > 0) {
            if (velocity.y / velocity.x <= 1 && velocity.y / velocity.x >= -1) {
                self.triggerDirection = ACCMVTransitionTriggerDirectionRight;
                return YES;
            }
        } else if (velocity.x < 0) {
            if (velocity.y / velocity.x <= 1 && velocity.y / velocity.x >= -1) {
                if ([self.viewController slidePushTargetViewController]) {
                    self.triggerDirection = ACCMVTransitionTriggerDirectionLeft;
                    return YES;
                }
            }
        }
    }
    return NO;
}

#pragma mark - Getters

- (UIPanGestureRecognizer *)panGestureRecognizer
{
    if (!_panGestureRecognizer) {
        _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        _panGestureRecognizer.maximumNumberOfTouches = 1;
        _panGestureRecognizer.delegate = self;
    }
    return _panGestureRecognizer;
}

- (ACCZoomPopAnimator *)popAnimator
{
    if (!_popAnimator) {
        _popAnimator = [ACCZoomPopAnimator new];
    }
    return _popAnimator;
}

@end
