//
//  EMAPreviewAnimateImageView.h
//  PacketImgBackAnimation
//
//  Created by tyh on 2017/5/9.
//  Copyright © 2017年 tyh. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    EMAPreviewAnimateStateWillBegin,
    EMAPreviewAnimateStateDidBegin,
    EMAPreviewAnimateStateChange,
    EMAPreviewAnimateStateWillFinish,
    EMAPreviewAnimateStateDidFinish,
    EMAPreviewAnimateStateWillCancel,
    EMAPreviewAnimateStateDidCancel,
} EMAPreviewAnimateState;


@protocol  EMAPreviewPanBackDelegate <NSObject>

@required
//scale仅仅在 EMAPreviewAnimateStateChange下 有正确的值，其他都为0
- (void)ttPreviewPanBackStateChange:(EMAPreviewAnimateState)currentState scale:(float)scale;

- (UIView *)ttPreviewPanBackGetOriginView;

- (UIView *)ttPreviewPanBackGetBackMaskView;

- (CGRect)ttPreviewPanBackTargetViewFrame;

- (CGFloat)ttPreviewPanBackTargetViewCornerRadius;

@optional

//最终的画布，用于解决遮挡的问题，一个理想的view。- -!
- (UIView *)ttPreviewPanBackGetFinishBackgroundView;

//可以在finish和cancel一起动画
- (void)ttPreviewPanBackFinishAnimationCompletion;
- (void)ttPreviewPanBackCancelAnimationCompletion;


//针对微头条的图片裁剪，提供的返回动画，不提供或者为nil则按默认动画执行
- (UIImage *)ttPreviewPanBackImageForSwitch;
- (UIView *)ttPreviewPanBackViewForSwitch;
- (UIViewContentMode)ttPreViewPanBackImageViewForSwitchContentMode;
//手势代理

- (BOOL)ttPreviewPanGestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer;
- (BOOL)ttPreviewPanGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;
- (BOOL)ttPreviewPanGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;
- (BOOL)ttPreviewPanGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;
@end




@interface EMAImagePreviewAnimateManager : NSObject


@property (nonatomic, weak)id<EMAPreviewPanBackDelegate> panDelegate;

@property (nonatomic, readonly)CGFloat minScale;
//在原本的位置盖上一个白色的view，默认为yes
@property (nonatomic, assign)BOOL whiteMaskViewEnable;

- (instancetype)initWithController:(UIViewController *)controller;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype _Nonnull)new NS_UNAVAILABLE;

+ (BOOL)interativeExitEnable;

- (void)registeredPanBackWithGestureView:(UIView *)gestureView;

@end



