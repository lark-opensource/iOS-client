//
//  CJPayDismissAnimator.h
//  CJPay
//
//  Created by wangxiaohong on 2022/5/5.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayNavigationController;
@interface CJPayDismissAnimator : UIPercentDrivenInteractiveTransition<UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) BOOL isInteractive;
@property (nonatomic, weak) CJPayNavigationController *naviViewController;

- (void)handleGesture:(UIPanGestureRecognizer *)panGesture;

@end

NS_ASSUME_NONNULL_END
