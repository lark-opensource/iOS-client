//
//  ACCZoomPopAnimator.m
//  CameraClient
//
//  Created by long.chen on 2020/3/4.
//

#import "ACCZoomPopAnimator.h"

#import "ACCZoomContextProviderProtocol.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>

@interface ACCZoomPopAnimator ()

@property (nonatomic, strong) UIView *startViewSnapshot;
@property (nonatomic, strong) UIView *endViewSnapshot;
@property (nonatomic, strong) UIView *endView;

@property (nonatomic, assign) CGRect containerViewFrame;
@property (nonatomic, assign) CGRect startFrame;
@property (nonatomic, assign) CGRect endFrame;

@property (nonatomic, weak) id<UIViewControllerContextTransitioning> transitionContext;

@end

@implementation ACCZoomPopAnimator

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.35f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    self.transitionContext = transitionContext;
    UIViewController<ACCZoomContextInnerProviderProtocol> *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController<ACCZoomContextOutterProviderProtocol> *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    
    self.containerViewFrame = containerView.frame;
    self.startViewSnapshot = [fromVC.view snapshotViewAfterScreenUpdates:NO];
    self.startFrame = [containerView convertRect:fromVC.view.bounds fromView:fromVC.view];
    self.startViewSnapshot.frame = self.startFrame;
    
    NSUInteger itemOffset = 0;
    if ([fromVC respondsToSelector:@selector(acc_zoomTransitionItemOffset)]) {
        itemOffset = [fromVC acc_zoomTransitionItemOffset];
    }
    self.endView = [toVC acc_zoomTransitionStartViewForItemOffset:itemOffset];
    self.endViewSnapshot = [self.endView acc_snapshotImageView];
    self.endViewSnapshot.frame = self.startFrame;
    self.endFrame = [containerView convertRect:self.endView.bounds fromView:self.endView];
    if (CGRectEqualToRect(self.endFrame, CGRectZero)) {
        self.endFrame = CGRectMake(containerView.acc_width / 2, containerView.acc_height / 2, 0, 0); 
    }
    
    [containerView insertSubview:toVC.view belowSubview:fromVC.view];
    [containerView addSubview:self.endViewSnapshot];
    [containerView addSubview:self.startViewSnapshot];
    fromVC.view.alpha = 0.f;
    self.endView.hidden = YES;
    
    if (!self.interactionInProgress) {
        [UIView animateWithDuration:[self transitionDuration:transitionContext]
                              delay:0.f
             usingSpringWithDamping:0.8f
              initialSpringVelocity:0.3f
                            options:0
                         animations:^{
            self.startViewSnapshot.alpha = 0.f;
            self.startViewSnapshot.frame = self.endFrame;
            self.endViewSnapshot.frame = self.endFrame;
        } completion:^(BOOL finished) {
            self.endView.hidden = NO;
            [self.startViewSnapshot removeFromSuperview];
            [self.endViewSnapshot removeFromSuperview];
            [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
        }];
    }
}

- (void)updateAnimationWithLocation:(CGPoint)currentLocation startLocation:(CGPoint)startLocation
{
    CGFloat percentage = [self progressForCurrentPosition:currentLocation startPosition:startLocation];
    percentage = MIN(1.0, MAX(0, percentage));
    CGFloat scale = 1 - 0.5 * pow(percentage, 1.3);
    
    CGPoint oriFingerOffset = CGPointMake(startLocation.x - self.startFrame.origin.x,
                                          startLocation.y - self.startFrame.origin.y);
    CGPoint fingerOffset = CGPointMake(oriFingerOffset.x * scale,
                                       oriFingerOffset.y * scale);
    
    CGRect newFrame = CGRectMake(currentLocation.x - fingerOffset.x,
                                 currentLocation.y - fingerOffset.y,
                                 self.startFrame.size.width * scale,
                                 self.startFrame.size.height * scale);
    self.startViewSnapshot.frame = newFrame;
    self.endViewSnapshot.frame = newFrame;
}

- (void)finishAnimation
{
    [UIView animateWithDuration:[self transitionDuration:self.transitionContext]
                          delay:0.f
         usingSpringWithDamping:0.8f
          initialSpringVelocity:0.3f
                        options:0
                     animations:^{
        self.startViewSnapshot.alpha = 0.f;
        self.startViewSnapshot.frame = self.endFrame;
        self.endViewSnapshot.frame = self.endFrame;
    } completion:^(BOOL finished) {
        self.endView.hidden = NO;
        [self.startViewSnapshot removeFromSuperview];
        [self.endViewSnapshot removeFromSuperview];
        [self.transitionContext completeTransition:YES];
    }];
}

- (void)cancelAnimation
{
    [UIView animateWithDuration:[self transitionDuration:self.transitionContext]
                          delay:0.f
         usingSpringWithDamping:0.8f
          initialSpringVelocity:0.3f
                        options:0
                     animations:^{
        self.startViewSnapshot.frame = self.startFrame;
        self.endViewSnapshot.frame = self.startFrame;
    } completion:^(BOOL finished) {
        self.endView.hidden = NO;
        [self.transitionContext viewForKey:UITransitionContextFromViewKey].alpha = 1.f;
        [self.startViewSnapshot removeFromSuperview];
        [self.endViewSnapshot removeFromSuperview];
        [self.transitionContext completeTransition:NO];
    }];
}

- (CGFloat)progressForCurrentPosition:(CGPoint)position startPosition:(CGPoint)startPoint
{
    CGFloat distance_x = fabs(position.x - startPoint.x) / self.containerViewFrame.size.width;
    CGFloat distance_y = fabs(position.y - startPoint.y) / self.containerViewFrame.size.height;
    
    return sqrt(pow(distance_x, 2) + pow(distance_y, 2));
}

@end
