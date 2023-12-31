//
//  ACCStickerPannelAnimationVC.m
//  Pods
//
//  Created by liyingpeng on 2020/8/20.
//

#import "ACCStickerPannelAnimationVC.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCSlidingScrollView.h>

static const CGFloat kAWEVideoEditStickerSpacePadding = 6.0f;

@interface ACCStickerPannelAnimationVC () <UIGestureRecognizerDelegate>

@property (nonatomic, assign) BOOL needSpacePadding;

@end

@implementation ACCStickerPannelAnimationVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = ACCResourceColor(ACCColorConstBGInverse2);
    self.topOffset = self.view.bounds.size.height * 0.11;
    
    // iOS 10 https://forums.developer.apple.com/message/211640#211640
    // back up：iOS 10 M black panel
    [self.view acc_addSystemBlurEffect:UIBlurEffectStyleDark];
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, ACC_SCREEN_WIDTH, self.view.bounds.size.height) byRoundingCorners:UIRectCornerTopRight | UIRectCornerTopLeft cornerRadii:CGSizeMake(12, 12)];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = [path CGPath];
    self.view.layer.mask = maskLayer;
    
    // gesture
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    pan.minimumNumberOfTouches = 1;
    pan.maximumNumberOfTouches = 1;
    pan.delegate = self;
    [self.view addGestureRecognizer:pan];
}

#pragma mark - Show & Hide

- (void)showWithCompletion:(nullable void (^)(void))completion
{
    self.view.alpha = 1;
    self.needSpacePadding = YES;
    [self.containerVC addChildViewController:self];
    UIView *containerView = self.containerVC.view;
    self.view.frame = CGRectMake(0, containerView.acc_height - kAWEVideoEditStickerSpacePadding, containerView.acc_width, containerView.acc_height - self.topOffset + kAWEVideoEditStickerSpacePadding);
    [containerView addSubview:self.view];
    [self didMoveToParentViewController:self.containerVC];
    self.view.userInteractionEnabled = NO;

    [UIView animateWithDuration:0.49 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.view.frame = CGRectMake(0, self.topOffset - kAWEVideoEditStickerSpacePadding, containerView.acc_width, containerView.acc_height - self.topOffset + kAWEVideoEditStickerSpacePadding);
        self.animationView.alpha = 0;
    } completion:^(BOOL finished) {
        if (finished) {
            self.view.userInteractionEnabled = YES;
            ACCBLOCK_INVOKE(completion);
        }
    }];
}

- (void)showAlphaWithCompletion:(nullable void (^)(void))completion
{
    self.view.alpha = 0;
    [self.containerVC addChildViewController:self];
    UIView *containerView = self.containerVC.view;
    self.view.frame = CGRectMake(0, 0, containerView.acc_width, containerView.acc_height);
    [containerView addSubview:self.view];
    [self didMoveToParentViewController:self.containerVC];
    self.view.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.view.alpha = 1;
        self.view.frame = CGRectMake(0, self.topOffset, containerView.acc_width, containerView.acc_height - self.topOffset);
        self.animationView.alpha = 0;
    } completion:^(BOOL finished) {
        self.view.userInteractionEnabled = YES;
        
        if (completion) {
            completion();
        }
    }];
}

- (void)showWithoutAnimation
{
    self.view.alpha = 1;
    self.needSpacePadding = YES;
    [self.containerVC addChildViewController:self];
    UIView *containerView = self.containerVC.view;
    self.view.frame = CGRectMake(0, self.topOffset - kAWEVideoEditStickerSpacePadding, containerView.acc_width, containerView.acc_height - self.topOffset + kAWEVideoEditStickerSpacePadding);
    [containerView addSubview:self.view];
    [self didMoveToParentViewController:self.containerVC];
}

- (void)removeWithCompletion:(nullable void (^)(void))completion
{
    [self p_willClose];
    self.view.userInteractionEnabled = NO;
    self.view.alpha = 1;
    self.animationView.alpha = 0;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.view.center = CGPointMake(self.view.center.x, CGRectGetMaxY(self.view.superview.bounds) + self.view.bounds.size.height / 2);
        self.animationView.alpha = 1;
    } completion:^(BOOL finished) {
        
        [self willMoveToParentViewController:nil];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
        
        if (completion) {
            completion();
        }
    }];
}

- (void)removeAlphaWithCompletion:(nullable void (^)(void))completion
{
    [self p_willClose];
    self.view.alpha = 1;
    self.view.userInteractionEnabled = NO;
    self.animationView.alpha = 0;
    [UIView animateWithDuration:0.25 animations:^{
        self.view.alpha = 0;
        self.animationView.alpha = 1;
        self.view.acc_top = 0;
    } completion:^(BOOL finished) {
        [self willMoveToParentViewController:nil];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
        
        if (completion) {
            completion();
        }
    }];
}

- (void)removeWithoutAnimation
{
    [self p_willClose];
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

#pragma mark - Event Hanlding

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        const CGPoint translation = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:self.view];
        return translation.y > 0 && fabs(translation.y) > fabs(translation.x);
    }

    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([otherGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)otherGestureRecognizer.view;
        if ([scrollView isKindOfClass:[ACCSlidingScrollView class]]) {
            return NO;
        }
        if (scrollView.contentOffset.y <= fabs(scrollView.contentInset.top)) {
            if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
                UIPanGestureRecognizer *panGes = (UIPanGestureRecognizer *)gestureRecognizer;
                CGPoint velocity = [panGes velocityInView:panGes.view];
                if (velocity.y > 0) {
                    scrollView.bounces = NO;
                } else {
                    scrollView.bounces = YES;
                }
            } else {
                scrollView.bounces = NO;
            }
            return YES;
        } else {
            scrollView.bounces = YES;
            return NO;
        }
    }
    return NO;
}

- (void)handlePan:(UIPanGestureRecognizer *)pan
{
    const CGPoint translation = [pan translationInView:self.view];
    CGFloat topSpacePadding = self.needSpacePadding ? kAWEVideoEditStickerSpacePadding : 0.f;
    if (pan.state == UIGestureRecognizerStateChanged) {
        if (translation.y >= 0) {
            self.view.frame = CGRectMake(0, self.topOffset + translation.y - topSpacePadding, self.view.frame.size.width, self.view.frame.size.height);
        } else {
            self.view.frame = CGRectMake(0, self.topOffset - topSpacePadding, self.view.frame.size.width, self.view.frame.size.height);
            [pan setTranslation:CGPointZero inView:self.view];
        }
    } else if (pan.state == UIGestureRecognizerStateEnded ||
               pan.state == UIGestureRecognizerStateCancelled) {
        const CGFloat distanceThreshold = self.view.bounds.size.height * 0.25;
        const BOOL shouldDismiss = [pan velocityInView:self.view].y > 0 || translation.y > distanceThreshold;
        if (shouldDismiss) {
            [self.transitionDelegate stickerPannelVCDidDismiss];
            [self removeWithCompletion:nil];
        } else {
            // restore
            self.view.userInteractionEnabled = NO;
            [UIView animateWithDuration:0.1 animations:^{
                self.view.frame = CGRectMake(0, self.topOffset - topSpacePadding, self.view.frame.size.width, self.view.frame.size.height);
            } completion:^(BOOL finished) {
                self.view.userInteractionEnabled = YES;
            }];
        }
    }
}

#pragma mark - Private Methods

- (void)p_willClose
{
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

@end
