//
//  CAKBouncePresentAnimationController.m
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/9.
//

#import <CreativeKit/ACCMacros.h>
#import "CAKBouncePresentAnimationController.h"

@interface CAKBouncePresentAnimationController ()

@property (nonatomic, strong) id<UIViewControllerContextTransitioning> transitionContext;

@end

@implementation CAKBouncePresentAnimationController

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.3;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    self.transitionContext = transitionContext;
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    CGFloat originY = ACC_STATUS_BAR_NORMAL_HEIGHT;
    CGFloat height = ACC_SCREEN_HEIGHT - ACC_STATUS_BAR_NORMAL_HEIGHT;

    // 判断是否在打电话、微信聊天，状态栏刚刚更改高度时，STATUS_BAR_HEIGHT值未更新，故用以下方法判断
    if (![UIDevice acc_isIPhoneX] && ACC_SCREEN_HEIGHT > fromVC.view.bounds.size.height) {
        originY = ACC_STATUS_BAR_HEIGHT - ACC_STATUS_BAR_NORMAL_HEIGHT;
    }
    if (originY < ACC_STATUS_BAR_NORMAL_HEIGHT) {
        originY = 0;
    }
    CGRect initialFrame = CGRectMake(0, ACC_SCREEN_HEIGHT, toVC.view.bounds.size.width, height);
    CGRect finalFrame = CGRectMake(0, originY, initialFrame.size.width, initialFrame.size.height);
    
    UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    view.backgroundColor = [UIColor blackColor];
    
    UIView *snapView = [fromVC.view snapshotViewAfterScreenUpdates:NO];
    [view addSubview:snapView];
    
    UIView *blackMaskView = [[UIView alloc] initWithFrame:view.bounds];
    blackMaskView.backgroundColor = [UIColor blackColor];
    blackMaskView.alpha = 0;
    
    [view addSubview:blackMaskView];
    
    CGFloat diff = 50;
    
    UIView *auxView = [[UIView alloc] initWithFrame:CGRectMake(initialFrame.origin.x, initialFrame.origin.y+diff, initialFrame.size.width, initialFrame.size.height+diff)];
    auxView.backgroundColor = [UIColor blackColor];
    
    toVC.view.frame = initialFrame;
    
    [containerView addSubview:view];
    [containerView addSubview:auxView];
    [containerView addSubview:toVC.view];
    
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^{
        snapView.transform = CGAffineTransformMakeScale(0.94, 0.94);
    } completion:^(BOOL finished) {
        [snapView removeFromSuperview];
    }];
    
    [UIView animateWithDuration:duration animations:^{
        blackMaskView.alpha = 0.95;
    } completion:^(BOOL finished) {
        [blackMaskView removeFromSuperview];
    }];
    
    [UIView animateWithDuration:0.49 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        auxView.frame = CGRectMake(finalFrame.origin.x, finalFrame.origin.y + diff, finalFrame.size.width, finalFrame.size.height + diff);
        toVC.view.frame = finalFrame;
    } completion:^(BOOL finished) {
        if (finished) {
            [auxView removeFromSuperview];
            [transitionContext completeTransition:YES];
        }
    }];
}

@end
