//
//  BDASplashView+Helper.h
//  TTAdSplashSDK
//
//  Created by boolchow on 2020/3/9.
//

#import "BDASplashView.h"
#import "TTAdSplashVideoView.h"
#import "BDASplashGestureRecognizer.h"

NS_ASSUME_NONNULL_BEGIN

extern float BDAdZeroIfNaN(float value);

/** 主要用于处理 BDASplashView 中的埋点、点击等非 view 布局相关事件。诣在将乱七八糟的东西和 view 布局渲染分离，不要去污染 BDASplashView */
@interface BDASplashView (Helper) <BDASplashVideoViewDelegate>

/// 点击背景 button 处理方法
/// @param sender 点击对象
/// @param event 点击事件元素
- (void)bgButtonTouched:(id)sender forEvent:(UIEvent* _Nullable)event;

- (void)bannerActionButtonClick:(id)sender point:(CGPoint)point;

- (void)skipButtonClicked;

- (void)skipAdWithSource:(NSString *)source;

/// 上滑手势的响应函数（关闭开屏）
- (void)onSplashViewScrolledUp;

/// 上滑退出视图被点击时的处理函数
- (void)onSwipeUpViewClicked:(BDASplashTapGestureRecognizer *)gesture;

- (BOOL)isVideoAd;

- (void)showedTimeOutWithAnimation:(BOOL)animation;

- (void)imageAdShowedCompleted;

- (void)invalidPerform;

- (BOOL)haveClickAction;

- (void)loadFirstPhaseBannerViewAnimation;

- (void)loadSecondPhaseBannerViewAnimation;

- (void)loadSecondPhaseBannerViewAnimationForNewUser;

- (void)trackImageAdShow;

- (void)trackBannerAdShow;

- (void)trackVideoAdPlay;

- (void)trackAdEventWithLabel:(NSString *)label extra:(NSDictionary * _Nullable)extra;

- (void)trackTouchNonInteractiveAreaAdWithPoint:(CGPoint)point;

- (void)sendPlayOverEvent;

// 添加无障碍模式下的聚焦元素，供摇一摇视图调用
- (void)addAccessibilityElement:(id)accessElement;

@end

NS_ASSUME_NONNULL_END
