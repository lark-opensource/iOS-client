//
//  ACCTransitioningDelegateProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/7/30.
//  设置 transitioningDelegate 执行自定义转场动画

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@protocol ACCSwipeInteractionProtocol;
@protocol ACCInteractiveTransitionProtocol <NSObject>
@property(nonatomic, strong) UIPercentDrivenInteractiveTransition <ACCSwipeInteractionProtocol> *swipeInteractionController;
@end


@protocol ACCSwipeInteractionProtocol <NSObject>
@property (nonatomic, assign) BOOL interactionInProgress;
@property (nonatomic, assign) BOOL forbidSimultaneousScrollViewPanGesture;
@property (nonatomic, assign) BOOL forbidTransitionGes;
- (void)wireToViewController:(UIViewController *)viewController;
@end


@protocol ACCTransitioningDelegateProtocol <NSObject>

/*
 * 大变小，类似选特效的转场
 */
- (nullable id <UIViewControllerTransitioningDelegate>)bigToSmallModalDelegate;

/*
 * 从下往上，类似拍摄页选音乐的转场
 */
- (nullable id <UIViewControllerTransitioningDelegate,ACCInteractiveTransitionProtocol>)modalTransitionDelegate;

/*
 * present like push 
 */
- (nullable id <UIViewControllerTransitioningDelegate>)modalLikePushTransitionDelegate;

@end

NS_ASSUME_NONNULL_END
