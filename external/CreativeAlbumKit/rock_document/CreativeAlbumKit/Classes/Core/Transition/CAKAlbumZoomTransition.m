//
//  CAKAlbumZoomTransition.m
//  CreativeAlbumKit_Example
//
//  Created by yuanchang on 2020/12/4.
//  Copyright © 2020 lixingdong. All rights reserved.
//

#import "CAKAlbumZoomTransition.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>

#pragma mark - Class CAKAlbumTransitionContext

@implementation CAKAlbumTransitionContext

@end

#pragma mark - Class CAKMagnifyTransition

@implementation CAKMagnifyTransition

- (BOOL)isForAppear
{
    return YES;
}

- (CAKAlbumTransitionInteractionType)interactionType
{
    return CAKAlbumTransitionInteractionTypeNone;
}

- (void)startDefaultAnimationWithFromVC:(UIViewController *)fromVC toVC:(UIViewController *)toVC fromContextProvider:(NSObject<CAKAlbumZoomTransitionOuterContextProvider> *)fromCP toContextProvider:(NSObject<CAKAlbumZoomTransitionInnerContextProvider> *)toCP containerView:(UIView *)containerView context:(id<UIViewControllerContextTransitioning>)context interactionType:(CAKAlbumTransitionInteractionType)type completionHandler:(void (^)(BOOL))completionHander
{
    [containerView addSubview:toVC.view];
    
    NSInteger offset = 0;
    if ([fromCP respondsToSelector:@selector(zoomTransitionItemOffset)]) {
        offset = fromCP.zoomTransitionItemOffset;
    }
    UIView *startView = [fromCP respondsToSelector:@selector(zoomTransitionStartViewForOffset:)] ? [fromCP zoomTransitionStartViewForOffset:offset] : nil;
    UIView *startViewMigrationContainer = nil;
    BOOL migrationMode = [toCP respondsToSelector:@selector(zoomTransitionWantsViewMigration)] && toCP.zoomTransitionWantsViewMigration;
    BOOL enableTabbarAnimation = [fromCP respondsToSelector:@selector(zoomTransitionWantsTabBarAnimation)] ? fromCP.zoomTransitionWantsTabBarAnimation : YES;
    BOOL enableTabbarAlphaAnimation = [fromCP respondsToSelector:@selector(zoomTransitionWantsTabBarAlphaAnimation)] ? fromCP.zoomTransitionWantsTabBarAlphaAnimation : NO;
    BOOL hideSpringAnimation = [toCP respondsToSelector:@selector(zoomTransitionWantsRemoveSpringAnimation)] && toCP.zoomTransitionWantsRemoveSpringAnimation;
    BOOL shouldAnimationFromVC = [fromCP respondsToSelector:@selector(zoomTransitionWantsFromVCAnimation)] ? fromCP.zoomTransitionWantsFromVCAnimation : YES;
    NSTimeInterval duration = 0.35;
    if ([toCP respondsToSelector:@selector(animationDuration)]) {
        duration = toCP.animationDuration;
    }
    if (migrationMode) {
        startViewMigrationContainer = startView;
        startView = startView.subviews.firstObject;
    }
    if ([toCP respondsToSelector:@selector(zoomTransitionWillStartForView:)] && startView) {
        [toCP zoomTransitionWillStartForView:startView];
    }
    if (migrationMode && startView) {
        CGRect frame = [startView acc_frameInView:containerView];
        [startView removeFromSuperview];
        [containerView addSubview:startView];
        startView.frame = frame;
    }
    
    UIView *endView = [toCP respondsToSelector:@selector(zoomTransitionEndView)] ? toCP.zoomTransitionEndView : toVC.view;
    
    UIView *fromVCSnapshot = migrationMode ? nil : [startView snapshotViewAfterScreenUpdates:NO];
    if (shouldAnimationFromVC && fromVCSnapshot) {
        [containerView addSubview:fromVCSnapshot];
    }
    fromVCSnapshot.frame = [startView acc_frameInView:containerView];
    
    UIView *toVCSnapshot = migrationMode ? nil : [endView acc_snapshotImageView];
    if ([fromCP respondsToSelector:@selector(targetViewControllerSnapshotView)]) {
        UIView *providedTargetVCSnapshotView = [fromCP targetViewControllerSnapshotView];
        if (providedTargetVCSnapshotView) {
            toVCSnapshot = providedTargetVCSnapshotView;
        }
    }
    toVCSnapshot.frame = fromVCSnapshot ? fromVCSnapshot.frame : CGRectMake(containerView.bounds.size.width / 2, containerView.bounds.size.height / 3, 1, 1);
    toVCSnapshot.alpha = 0;
    if (toVCSnapshot) {
        [containerView addSubview:toVCSnapshot];
    }
    
    toVC.view.alpha = 0.01;
    
    UIView *maskView = nil;
    
    UIView *snapshotTabbar = nil;
    
    if ((enableTabbarAnimation || enableTabbarAlphaAnimation) && fromVC.tabBarController.tabBar && !fromVC.tabBarController.tabBar.hidden) {
        snapshotTabbar = [fromVC.tabBarController.tabBar snapshotViewAfterScreenUpdates:NO];
        snapshotTabbar.frame = [fromVC.tabBarController.tabBar acc_frameInView:containerView];
        if (enableTabbarAlphaAnimation) {
            snapshotTabbar.frame = CGRectMake(0, snapshotTabbar.frame.origin.y, snapshotTabbar.frame.size.width, snapshotTabbar.frame.size.height);
            snapshotTabbar.alpha = 1.0;
        }
        fromVC.tabBarController.tabBar.hidden = YES;
        [containerView addSubview:snapshotTabbar];
    }
    
    if (![toCP respondsToSelector:@selector(zoomTransitionWantsBlackMaskView)] || toCP.zoomTransitionWantsBlackMaskView) {
        maskView = [[UIView alloc] initWithFrame:containerView.bounds];
        maskView.backgroundColor = [UIColor blackColor];
        if (migrationMode && startView) {
            [containerView insertSubview:maskView belowSubview:startView];
        } else {
            [containerView insertSubview:maskView belowSubview:toVC.view];
        }
        maskView.alpha = 0;
    }
    
    if (migrationMode) {
        startView.layer.cornerRadius = startViewMigrationContainer.layer.cornerRadius;
    }
    [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:hideSpringAnimation ? 1 : 0.8 initialSpringVelocity:hideSpringAnimation ? 0 : 0.3 options:0 animations:^{
        toVCSnapshot.alpha = 1;
        maskView.alpha = 1;
        if (migrationMode) {
            CGRect endViewFrame = endView.frame;
            if (@available(iOS 9.0, *)) {
                endViewFrame = [endView acc_frameInView:containerView];
            }
            startView.frame = endViewFrame;
            startView.layer.cornerRadius = endView.layer.cornerRadius;
        } else {
            CGRect endFrame = [endView acc_frameInView:containerView];
            if ([fromCP respondsToSelector:@selector(targetViewFrame)]) {
                CGRect frameForEndView = [fromCP targetViewFrame];
                if (!CGRectEqualToRect(frameForEndView, CGRectZero)) {
                    endFrame = frameForEndView;
                }
            }
            toVCSnapshot.frame = endFrame;
            fromVCSnapshot.frame = endFrame;
        }
        
        if (snapshotTabbar) {
            CGRect newFrame = snapshotTabbar.frame;
            newFrame.origin.y = enableTabbarAnimation ? containerView.frame.size.height : containerView.frame.size.height - snapshotTabbar.frame.size.height;
            snapshotTabbar.frame = newFrame;
            if (enableTabbarAlphaAnimation) {
                snapshotTabbar.alpha = 0.0;
            }
        }
    } completion:^(BOOL finished) {
        toVC.view.alpha = 1;
        [toVCSnapshot removeFromSuperview];
        [fromVCSnapshot removeFromSuperview];
        [maskView removeFromSuperview];
        if ([context transitionWasCancelled]) {
            [toVC.view removeFromSuperview];
        } else if (migrationMode) {
            [startView removeFromSuperview];
            [endView addSubview:startView];
            startView.frame = endView.bounds;
        }
        if (snapshotTabbar) {
            [snapshotTabbar removeFromSuperview];
            fromVC.tabBarController.tabBar.hidden = NO;
        }
        completionHander(![context transitionWasCancelled]);
    }];
}

@end

#pragma mark - Class CAKShrinkTransition

@implementation CAKShrinkTransition

- (BOOL)isForAppear
{
    return NO;
}

- (CAKAlbumTransitionInteractionType)interactionType
{
    return CAKAlbumTransitionInteractionTypePercentageDriven;
}

- (void)startDefaultAnimationWithFromVC:(UIViewController *)fromVC toVC:(UIViewController *)toVC fromContextProvider:(NSObject<CAKAlbumZoomTransitionInnerContextProvider> *)fromCP toContextProvider:(NSObject<CAKAlbumZoomTransitionOuterContextProvider> *)toCP containerView:(UIView *)containerView context:(id<UIViewControllerContextTransitioning>)context interactionType:(CAKAlbumTransitionInteractionType)type completionHandler:(void (^)(BOOL))completionHander
{
    [containerView insertSubview:[context viewForKey:UITransitionContextToViewKey] belowSubview:fromVC.view];
    
    UIView *maskView = nil;
    
    if (![fromCP respondsToSelector:@selector(zoomTransitionWantsBlackMaskView)] || fromCP.zoomTransitionWantsBlackMaskView) {
        maskView = [[UIView alloc] initWithFrame:containerView.bounds];
        maskView.backgroundColor = [UIColor blackColor];
        [containerView addSubview:maskView];
        maskView.alpha = 1;
    }
    BOOL hideSpringAnimation = [fromCP respondsToSelector:@selector(zoomTransitionWantsRemoveSpringAnimation)] && fromCP.zoomTransitionWantsRemoveSpringAnimation;
    NSTimeInterval duration = 0.35;
    if ([fromCP respondsToSelector:@selector(animationDuration)]) {
        duration = fromCP.animationDuration;
    }
    BOOL migrationMode = [fromCP respondsToSelector:@selector(zoomTransitionWantsViewMigration)] && fromCP.zoomTransitionWantsViewMigration;
    BOOL enableTabbarAnimation = [toCP respondsToSelector:@selector(zoomTransitionWantsTabBarAnimation)] ? toCP.zoomTransitionWantsTabBarAnimation : YES;
    BOOL enableTabbarAlphaAnimation = [toCP respondsToSelector:@selector(zoomTransitionWantsTabBarAlphaAnimation)] ? toCP.zoomTransitionWantsTabBarAlphaAnimation : NO;
    NSTimeInterval tabbarAnimationDuration = [toCP respondsToSelector:@selector(tabbarAnimationDuration)] ? toCP.tabbarAnimationDuration : 0.35;
    UIView *startViewMigrationContainer = nil;
    UIView *fromView = [fromCP respondsToSelector:@selector(zoomTransitionEndView)] ? fromCP.zoomTransitionEndView : fromVC.view;
    if (migrationMode) {
        startViewMigrationContainer = fromView;
        fromView = fromView.subviews.firstObject;
        CGRect frame = [fromView acc_frameInView:containerView];
        [fromView removeFromSuperview];
        [containerView addSubview:fromView];
        fromView.frame = frame;
    }
    NSInteger offset = 0;
    if ([fromCP respondsToSelector:@selector(zoomTransitionItemOffset)]) {
        offset = fromCP.zoomTransitionItemOffset;
    }
    UIView *focusView = [toCP respondsToSelector:@selector(zoomTransitionStartViewForOffset:)] ? [toCP zoomTransitionStartViewForOffset:offset] : nil;
    
    UIView *fromVCSnapshot = migrationMode ? nil : [fromView snapshotViewAfterScreenUpdates:NO];
    fromVCSnapshot.frame = [fromView acc_frameInView:containerView];
    
    BOOL forbidShowToVCSnapshot = [fromCP respondsToSelector:@selector(zoomTransitionForbidShowToVCSnapshot)] ? [fromCP zoomTransitionForbidShowToVCSnapshot] : NO;
    UIView *toVCSnapshot = (migrationMode || forbidShowToVCSnapshot) ? nil : [focusView acc_snapshotImageView];
    toVCSnapshot.frame = fromVCSnapshot.frame;
    
    if (toVCSnapshot) {
        [containerView addSubview:toVCSnapshot];
    }
    if (fromVCSnapshot) {
        [containerView addSubview:fromVCSnapshot];
    }
    
    fromVCSnapshot.alpha = 1;
    
    fromVC.view.alpha = 0.01;
    
    UIView *snapshotTabbar = nil;
    UITabBarController *tabBarController = [toVC isKindOfClass:[UITabBarController class]] ? (UITabBarController *)toVC : toVC.tabBarController;
    if ((enableTabbarAnimation || enableTabbarAlphaAnimation) && tabBarController.tabBar && !tabBarController.tabBar.hidden) {
        tabBarController.tabBar.alpha = 1;
        snapshotTabbar = [tabBarController.tabBar acc_snapshotImageView];
        [containerView addSubview:snapshotTabbar];
        CGFloat fromY = enableTabbarAnimation ? containerView.frame.size.height : containerView.frame.size.height - snapshotTabbar.frame.size.height;
        snapshotTabbar.frame = CGRectMake(0, fromY, snapshotTabbar.frame.size.width, snapshotTabbar.frame.size.height);
        if (enableTabbarAlphaAnimation) {
            snapshotTabbar.alpha = 0;
        }
        tabBarController.tabBar.alpha = 0;
        
        [UIView animateWithDuration:tabbarAnimationDuration animations:^{
            if (enableTabbarAlphaAnimation) {
                snapshotTabbar.alpha = 1.0;
            }
            snapshotTabbar.frame = CGRectMake(0, containerView.frame.size.height - snapshotTabbar.frame.size.height, snapshotTabbar.frame.size.width, snapshotTabbar.frame.size.height);
        } completion:^(BOOL finished) {
            if (snapshotTabbar) {
                [snapshotTabbar removeFromSuperview];
                tabBarController.tabBar.alpha = 1;
            }
        }];
    }
    
    if (migrationMode) {
        fromView.layer.cornerRadius = startViewMigrationContainer.layer.cornerRadius;
    }
    [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:hideSpringAnimation ? 1 : 0.8 initialSpringVelocity:hideSpringAnimation ? 0 : 0.3 options:0 animations:^{
        if (migrationMode) {
            fromView.frame = [focusView acc_frameInView:containerView];
            fromView.layer.cornerRadius = focusView.layer.cornerRadius;
        } else {
            fromVCSnapshot.alpha = 0;
            toVCSnapshot.frame = [focusView acc_frameInView:containerView];
            fromVCSnapshot.frame = [focusView acc_frameInView:containerView];
        }
        maskView.alpha = 0;
    } completion:^(BOOL finished) {
        fromVC.view.alpha = 1;
        [toVCSnapshot removeFromSuperview];
        [fromVCSnapshot removeFromSuperview];
        [maskView removeFromSuperview];
        if ([context transitionWasCancelled]) {
            [toVC.view removeFromSuperview];
        } else if (migrationMode) {
            [fromView removeFromSuperview];
            [focusView addSubview:fromView];
            fromView.frame = focusView.bounds;
            
            if ([toCP respondsToSelector:@selector(zoomTransitionMigrationDidEndForView:)]) {
                [toCP zoomTransitionMigrationDidEndForView:fromView];
            }
        }
        completionHander(![context transitionWasCancelled]);
    }];
}

@end

#pragma mark - Class CAKInteractiveShrinkTransition

@interface CAKInteractiveShrinkTransition()

@property (nonatomic, strong) UIView *fromVCSnapshot;
@property (nonatomic, strong) UIView *toVCSnapshot;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *focusView;
@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) UIView *tabbar;
@property (nonatomic, strong) UITabBarController *tabBarController;
@property (nonatomic, strong) UIView *snapshotTabbar;
@property (nonatomic, strong) UIView *fromView;
@property (nonatomic, strong) UIView *fromViewMigrationContainer;

@property (nonatomic, assign) CGRect startFrame;
@property (nonatomic, assign) CGRect endFrame;
@property (nonatomic, assign) BOOL migrationMode;
@property (nonatomic, assign) NSTimeInterval currentTransitionTabbarAnimationDuration;

@property (nonatomic, weak) UIViewController<CAKAlbumZoomTransitionInnerContextProvider> *fromCP;
@property (nonatomic, weak) UIViewController<CAKAlbumZoomTransitionOuterContextProvider> *toCP;

@property (nonatomic, weak) id<CAKAlbumTransitionDelegateProtocol> transitionDelegate;

@end

@implementation CAKInteractiveShrinkTransition

- (instancetype)initWithTransitionDelegate:(id<CAKAlbumTransitionDelegateProtocol>)transitionDelegate
{
    self = [super init];
    if (self) {
        self.transitionDelegate = transitionDelegate;
    }
    
    return self;
}

- (BOOL)isForAppear
{
    return NO;
}

- (CAKAlbumTransitionInteractionType)interactionType
{
    return CAKAlbumTransitionInteractionTypeCustomPanDriven;
}

- (CAKAlbumTransitionTriggerDirection)allowTriggerDirectionForContext:(CAKAlbumTransitionContext *)context
{
    NSObject<CAKAlbumZoomTransitionInnerContextProvider> *fromCP = (NSObject<CAKAlbumZoomTransitionInnerContextProvider> *)context.fromContextProvider;
    if ([fromCP respondsToSelector:@selector(zoomTransitionAllowedTriggerDirection)]) {
        return fromCP.zoomTransitionAllowedTriggerDirection;
    }
    
    return CAKAlbumTransitionTriggerDirectionRight;
}

- (void)startCustomAnimationWithFromVC:(__kindof UIViewController *)fromVC toVC:(__kindof UIViewController *)toVC fromContextProvider:(UIViewController<CAKAlbumZoomTransitionInnerContextProvider> *)fromCP toContextProvider:(UIViewController<CAKAlbumZoomTransitionOuterContextProvider> *)toCP containerView:(UIView *)containerView context:(id<UIViewControllerContextTransitioning>)context
{
    [containerView insertSubview:[context viewForKey:UITransitionContextToViewKey] belowSubview:fromVC.view];
    
    self.maskView = nil;
    
    if (![fromCP respondsToSelector:@selector(zoomTransitionWantsBlackMaskView)] || fromCP.zoomTransitionWantsBlackMaskView) {
        self.maskView = [[UIView alloc] initWithFrame:containerView.bounds];
        self.maskView.backgroundColor = [UIColor blackColor];
        [containerView addSubview:self.maskView];
        [containerView insertSubview:self.maskView aboveSubview:toVC.view];
        self.maskView.alpha = 1;
    }
    self.migrationMode = [fromCP respondsToSelector:@selector(zoomTransitionWantsViewMigration)] && fromCP.zoomTransitionWantsViewMigration;
    BOOL enableTabbarAnimation = [toCP respondsToSelector:@selector(zoomTransitionWantsTabBarAnimation)] ? toCP.zoomTransitionWantsTabBarAnimation : YES;
    BOOL enableTabbarAlphaAnimation = [toCP respondsToSelector:@selector(zoomTransitionWantsTabBarAlphaAnimation)] ? toCP.zoomTransitionWantsTabBarAlphaAnimation : NO;
    self.currentTransitionTabbarAnimationDuration = [toCP respondsToSelector:@selector(tabbarAnimationDuration)] ? toCP.tabbarAnimationDuration : 0.35;
    self.fromView = [fromCP respondsToSelector:@selector(zoomTransitionEndView)] ? fromCP.zoomTransitionEndView : fromCP.view;
    if (self.migrationMode) {
        self.fromViewMigrationContainer = self.fromView;
        self.fromView = self.fromView.subviews.firstObject;
        CGRect frame = [self.fromView acc_frameInView:containerView];
        [self.fromView removeFromSuperview];
        [containerView addSubview:self.fromView];
        self.fromView.frame = frame;
        self.fromView.layer.cornerRadius = self.fromViewMigrationContainer.layer.cornerRadius;
    }
    
    NSInteger offset = 0;
    if ([fromCP respondsToSelector:@selector(zoomTransitionItemOffset)]) {
        offset = fromCP.zoomTransitionItemOffset;
    }
    self.focusView = [toCP respondsToSelector:@selector(zoomTransitionStartViewForOffset:)] ? [toCP zoomTransitionStartViewForOffset:offset] : nil;
    
    self.startFrame = [self.fromView acc_frameInView:containerView];
    self.endFrame = self.focusView ? [self.focusView acc_frameInView:containerView] : CGRectMake(containerView.bounds.size.width / 2, containerView.bounds.size.height / 3, 1, 1);
    
    self.fromVCSnapshot = self.migrationMode ? nil : [self.fromView snapshotViewAfterScreenUpdates:NO];
    self.fromVCSnapshot.frame = self.startFrame;
    
    BOOL forbidShowToVCSnapshot = [fromCP respondsToSelector:@selector(zoomTransitionForbidShowToVCSnapshot)] ? [fromCP zoomTransitionForbidShowToVCSnapshot] : NO;
    self.toVCSnapshot = (self.migrationMode || forbidShowToVCSnapshot) ? nil : [self.focusView acc_snapshotImageView];
    self.toVCSnapshot.frame = self.startFrame;
    self.toVCSnapshot.alpha = 0;
    
    [containerView addSubview:self.toVCSnapshot];
    [containerView addSubview:self.fromVCSnapshot];
    
    self.containerView = containerView;
    
    self.fromVCSnapshot.alpha = 1;
    
    fromVC.view.alpha = 0.01;
    self.focusView.alpha = 0.01;
    
    self.tabBarController = [toVC isKindOfClass:[UITabBarController class]] ? (UITabBarController *)toVC : toVC.tabBarController;
    self.tabbar = self.tabBarController.tabBar;
    if ((enableTabbarAnimation || enableTabbarAlphaAnimation) && self.tabbar && !self.tabbar.hidden) {
        self.tabbar.alpha = 1;
        self.snapshotTabbar = [self.tabbar acc_snapshotImageView];
        [containerView addSubview:self.snapshotTabbar];
        CGFloat fromY = enableTabbarAnimation ? containerView.frame.size.height : containerView.frame.size.height - self.snapshotTabbar.frame.size.height;
        self.snapshotTabbar.frame = CGRectMake(0, fromY, self.snapshotTabbar.frame.size.width, self.snapshotTabbar.frame.size.height);
        if (enableTabbarAlphaAnimation) {
            self.snapshotTabbar.alpha = 0;
        }
        self.tabbar.alpha = 0;
    }
    
    self.fromCP = fromCP;
    self.toCP = toCP;
}

- (void)updateAnimationWithPosition:(CGPoint)currentPosition startPosition:(CGPoint)startPosition
{
    CGFloat percentage = [self progressForCurrentPosition:currentPosition startPosition:startPosition];
    percentage = MIN(1.0, MAX(0, percentage));
    CGFloat scale = 1 - 0.5 * pow(percentage, 1.3);
    
    CGPoint oriFingerOffset = CGPointMake(startPosition.x - self.startFrame.origin.x, startPosition.y - self.startFrame.origin.y);
    CGPoint fingerOffset = CGPointMake(oriFingerOffset.x * scale, oriFingerOffset.y * scale);
    
    CGRect newFrame = CGRectMake(currentPosition.x - fingerOffset.x, currentPosition.y - fingerOffset.y, self.startFrame.size.width * scale, self.startFrame.size.height * scale);
    if (self.migrationMode) {
        self.fromView.frame = newFrame;
    } else {
        self.fromVCSnapshot.frame = newFrame;
        self.toVCSnapshot.frame = newFrame;
    }
    self.maskView.alpha = 1 - percentage;
}

- (void)finishAnimationWithCompletionBlock:(void (^)(void))completionBlock
{
    __block BOOL completionBlockCalled = NO;
    void (^animationCompletionBlock)(void) = ^{
        if (completionBlockCalled) {
            return;
        }
        completionBlockCalled = YES;
        self.transitionDelegate.innerViewController.view.alpha = 1;
        [self.toVCSnapshot removeFromSuperview];
        [self.fromVCSnapshot removeFromSuperview];
        [self.maskView removeFromSuperview];
        [self.transitionDelegate.innerViewController.view removeFromSuperview];
        self.focusView.alpha = 1;
        
        if (self.migrationMode) {
            [self.fromView removeFromSuperview];
            [self.focusView addSubview:self.fromView];
            self.fromView.frame = self.focusView.bounds;
            
            if ([self.toCP respondsToSelector:@selector(zoomTransitionMigrationDidEndForView:)]) {
                [self.toCP zoomTransitionMigrationDidEndForView:self.fromView];
            }
        }
        
        if (self.snapshotTabbar) {
            [self.snapshotTabbar removeFromSuperview];
            self.tabbar.alpha = 1;
            [self.tabbar.layer removeAllAnimations];
        }
        completionBlock();
    };
    [UIView animateWithDuration:self.currentTransitionTabbarAnimationDuration animations:^{
        self.snapshotTabbar.frame = CGRectMake(0, self.containerView.frame.size.height - self.snapshotTabbar.frame.size.height, self.snapshotTabbar.frame.size.width, self.snapshotTabbar.frame.size.height);
        self.snapshotTabbar.alpha = 1;
    }];
    self.currentTransitionTabbarAnimationDuration = 0.35;
    BOOL hideSpringAnimation = [self.fromCP respondsToSelector:@selector(zoomTransitionWantsRemoveSpringAnimation)] && self.fromCP.zoomTransitionWantsRemoveSpringAnimation;
    [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:(self.focusView && !hideSpringAnimation) ? 0.8 : 1 initialSpringVelocity:hideSpringAnimation ? 0 : 0.3 options:0 animations:^{
        if (self.migrationMode) {
            self.fromView.frame = self.endFrame;
            self.fromView.layer.cornerRadius = self.focusView.layer.cornerRadius;
        } else {
            self.fromVCSnapshot.alpha = 0;
            self.toVCSnapshot.frame = self.endFrame;
            self.fromVCSnapshot.frame = self.endFrame;
        }
        self.maskView.alpha = 0;
        self.toVCSnapshot.alpha = 1;
    } completion:^(BOOL finished) {
        animationCompletionBlock();
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), animationCompletionBlock);
}

- (void)cancelAnimationWithCompletionBlock:(void (^)(void))completionBlock
{
    __block BOOL completionBlockCalled = NO;
    void (^animationCompletionBlock)(void) = ^{
        if (completionBlockCalled) {
            return;
        }
        completionBlockCalled = YES;
        self.transitionDelegate.innerViewController.view.alpha = 1;
        [self.toVCSnapshot removeFromSuperview];
        [self.fromVCSnapshot removeFromSuperview];
        [self.maskView removeFromSuperview];
        [[self.transitionDelegate.currentTransitioningContext viewForKey:UITransitionContextToViewKey] removeFromSuperview];
        self.focusView.alpha = 1;
        
        if (self.migrationMode) {
            [self.fromView removeFromSuperview];
            [self.fromViewMigrationContainer addSubview:self.fromView];
            self.fromView.frame = self.fromViewMigrationContainer.bounds;
        }
        
        if (self.snapshotTabbar) {
            [self.snapshotTabbar removeFromSuperview];
            self.tabbar.alpha = 1;
            [self.tabbar.layer removeAllAnimations];
        }
        completionBlock();
    };
    [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.3 options:0 animations:^{
        self.fromVCSnapshot.alpha = 1;
        if (self.migrationMode) {
            self.fromView.frame = self.startFrame;
            self.fromView.layer.cornerRadius = self.fromViewMigrationContainer.layer.cornerRadius;
        } else {
            self.toVCSnapshot.frame = self.startFrame;
            self.fromVCSnapshot.frame = self.startFrame;
        }
        self.maskView.alpha = 1;
    } completion:^(BOOL finished) {
        animationCompletionBlock();
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), animationCompletionBlock);
}

- (CGFloat)progressForCurrentPosition:(CGPoint)position startPosition:(CGPoint)startPoint
{
    if (!self.containerView) {
        return 0;
    }
    
    CGFloat distance_x = 0.0;
    if (!ACC_FLOAT_EQUAL_ZERO(self.containerView.bounds.size.width)) {
        distance_x = fabs(position.x - startPoint.x) / self.containerView.bounds.size.width;
    }
    
    CGFloat distance_y = 0.0;
    if (!ACC_FLOAT_EQUAL_ZERO(self.containerView.bounds.size.height)) {
        distance_y = fabs(position.y - startPoint.y) / self.containerView.bounds.size.height;
    }
    
    return sqrt(pow(distance_x, 2) + pow(distance_y, 2));
}

@end
