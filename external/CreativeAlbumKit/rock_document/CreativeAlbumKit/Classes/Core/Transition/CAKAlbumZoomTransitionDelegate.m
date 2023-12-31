//
//  CAKAlbumZoomTransitionDelegate.m
//  CreativeAlbumKit_Example
//
//  Created by yuanchang on 2020/12/4.
//  Copyright © 2020 lixingdong. All rights reserved.
//

#import "CAKAlbumZoomTransitionDelegate.h"
#import "CAKAlbumTransitionAnimationController.h"
#import "CAKAlbumTransitionInteractionController.h"
#import "CAKAlbumZoomTransition.h"
#import <CreativeKit/ACCMacros.h>

@interface CAKAlbumZoomTransitionDelegate()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIPercentDrivenInteractiveTransition *percentDrivenTransition;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, assign) CAKAlbumTransitionTriggerDirection triggerDirection;

@end

@implementation CAKAlbumZoomTransitionDelegate
@synthesize outterViewController, innerViewController, isAnimating, currentTransitioningContext, contextProvider;

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    id<CAKAlbumTransitionContextProvider> contextProvider = [[CAKMagnifyTransition alloc] init]; 
    self.contextProvider = contextProvider;
    return [CAKAlbumTransitionAnimationController instanceWithContextProvider:contextProvider transitionDelegate:self];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    id<CAKAlbumTransitionContextProvider> contextProvider = [[CAKShrinkTransition alloc] init];
    self.contextProvider = contextProvider;
    return [CAKAlbumTransitionAnimationController instanceWithContextProvider:contextProvider transitionDelegate:self];
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator
{
    return nil;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator
{
    id<CAKAlbumTransitionContextProvider> contextProvider = [[CAKInteractiveShrinkTransition alloc] initWithTransitionDelegate:self];
    self.contextProvider = contextProvider;
    return [CAKAlbumTransitionInteractionController instanceWithContextProvider:contextProvider transitionDelegate:self];
}

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source
{
    self.outterViewController = source;
    self.innerViewController = presented;
    [self.innerViewController.view addGestureRecognizer:self.panGestureRecognizer];
    
    UIPresentationController *presentation = [[UIPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
    return presentation;
}

#pragma mark - Action

- (void)handlePanGesture:(UIPanGestureRecognizer *)panGestureRecognizer
{
    static CGPoint startLocation;
    CGPoint currentLocation = [panGestureRecognizer locationInView:[UIApplication sharedApplication].keyWindow];
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            self.isAnimating = YES;
            startLocation = currentLocation;
            [self.innerViewController dismissViewControllerAnimated:YES completion:nil];
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            if ([self.contextProvider respondsToSelector:@selector(updateAnimationWithPosition:startPosition:)]) {
                [self.contextProvider updateAnimationWithPosition:currentLocation startPosition:startLocation];
            }
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            CGFloat progress = [self p_progressForDirection:self.triggerDirection startLocation:startLocation currentLocation:currentLocation];
            CGPoint vector = [self p_vectorForDirection:self.triggerDirection];
            CGPoint velocity = [self.panGestureRecognizer velocityInView:self.innerViewController.view];
            BOOL shouldComplete = YES;
            if (progress > 0.3 || (vector.x * velocity.x + vector.y * velocity.y)> 200) {
                // Vector codirectional
                shouldComplete = YES;
            } else {
                shouldComplete = NO;
            }
            if (!self.currentTransitioningContext) {
                self.isAnimating = NO;
                return;
            }
            if (shouldComplete) {
                @weakify(self);
                [self.contextProvider finishAnimationWithCompletionBlock:^{
                    @strongify(self);
                    [self.currentTransitioningContext finishInteractiveTransition];
                    [self.currentTransitioningContext completeTransition:YES];
                    self.isAnimating = NO;
                }];
            } else {
                @weakify(self);
                [self.contextProvider cancelAnimationWithCompletionBlock:^{
                    @strongify(self);
                    [self.currentTransitioningContext cancelInteractiveTransition];
                    [self.currentTransitioningContext completeTransition:NO];
                    self.isAnimating = NO;
                }];
            }
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (self.isAnimating) {
        return NO;
    }
    
    return [self p_zoomTransitionAllowedTrigger:gestureRecognizer];
}

#pragma mark - Utils

- (BOOL)p_zoomTransitionAllowedTrigger:(UIPanGestureRecognizer *)gestureRecognizer
{
    CAKAlbumTransitionTriggerDirection triggerDirection = [self p_directionForPan:gestureRecognizer];
    CAKAlbumTransitionTriggerDirection allowDirection = CAKAlbumTransitionTriggerDirectionAny;
    
    if ([self.innerViewController respondsToSelector:@selector(allowTriggerDirectionForContext:)]) {
        CAKAlbumTransitionContext *context = [[CAKAlbumTransitionContext alloc] init];
        context.fromViewController = self.innerViewController;
        context.fromContextProvider = self.innerViewController;
        allowDirection = [((id<CAKAlbumTransitionContextProvider>)self.innerViewController) allowTriggerDirectionForContext:context];
    }
    
    if (!(allowDirection & triggerDirection)) {
        return NO;
    }
    
    self.triggerDirection = triggerDirection;
    return YES;
}

- (CAKAlbumTransitionTriggerDirection)p_directionForPan:(UIPanGestureRecognizer *)pan
{
    CAKAlbumTransitionTriggerDirection direction = CAKAlbumTransitionTriggerDirectionNone;
    CGPoint velocity = [self.panGestureRecognizer velocityInView:self.innerViewController.view];
    if (velocity.x > 0) {
        if (velocity.y / velocity.x > 1) {
            direction = CAKAlbumTransitionTriggerDirectionDown;
        } else if (velocity.y / velocity.x < -1) {
            direction = CAKAlbumTransitionTriggerDirectionUp;
        } else {
            direction = CAKAlbumTransitionTriggerDirectionRight;
        }
    } else if (velocity.x < 0) {
        if (velocity.y / velocity.x > 1) {
            direction = CAKAlbumTransitionTriggerDirectionUp;
        } else if (velocity.y / velocity.x < -1) {
            direction = CAKAlbumTransitionTriggerDirectionDown;
        } else {
            direction = CAKAlbumTransitionTriggerDirectionLeft;
        }
    } else if (velocity.y > 0){
        direction = CAKAlbumTransitionTriggerDirectionDown;
    } else {
        direction = CAKAlbumTransitionTriggerDirectionUp;
    }
    
    return direction;
}

- (CGPoint)p_vectorForDirection:(CAKAlbumTransitionTriggerDirection)direction
{
    switch (direction) {
        case CAKAlbumTransitionTriggerDirectionUp:
            return CGPointMake(0, -1);
        case CAKAlbumTransitionTriggerDirectionDown:
            return CGPointMake(0, 1);
        case CAKAlbumTransitionTriggerDirectionLeft:
            return CGPointMake(-1, 0);
        case CAKAlbumTransitionTriggerDirectionRight:
            return CGPointMake(1, 0);
            
        default:
            break;
    }
    return CGPointZero;
}

- (CGFloat)p_progressForDirection:(CAKAlbumTransitionTriggerDirection)direction
                    startLocation:(CGPoint)startLocation
                  currentLocation:(CGPoint)currentLocation
{
    CGFloat progress = 0, total = 1;
    CGSize windowSize = [UIApplication sharedApplication].keyWindow.bounds.size;
    switch (direction) {
        case CAKAlbumTransitionTriggerDirectionUp:
            progress = startLocation.y - currentLocation.y;
            total = windowSize.height;
            break;
        case CAKAlbumTransitionTriggerDirectionDown:
            progress = currentLocation.y - startLocation.y;
            total = windowSize.height;
            break;
        case CAKAlbumTransitionTriggerDirectionLeft:
            progress = startLocation.x - currentLocation.x;
            total = windowSize.width;
            break;
        case CAKAlbumTransitionTriggerDirectionRight:
            progress = currentLocation.x - startLocation.x;
            total = windowSize.width;
            break;
            
        default:
            break;
    }
    CGFloat p = progress / total;
    if (p < 0) {
        p = 0;
    } else if (p > 1) {
        p = 1;
    }
    
    return p;
}

#pragma mark - Getter

- (UIPanGestureRecognizer *)panGestureRecognizer
{
    if (!_panGestureRecognizer) {
        _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        _panGestureRecognizer.maximumNumberOfTouches = 1;
        _panGestureRecognizer.delegate = self;
    }
    return _panGestureRecognizer;
}

@end
