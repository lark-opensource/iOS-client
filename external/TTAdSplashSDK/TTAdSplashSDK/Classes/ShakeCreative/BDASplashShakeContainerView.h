//
//  BDASplashShakeContainerView.h
//  TTAdSplashSDK
//
//  Created by boolchow on 2021/1/13.
//

#import <UIKit/UIKit.h>
#import "BDASplashViewProtocol.h"

@class BDASplashView;
@class TTAdSplashModel;
@class TTAdSplashControllerView;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDASplashShakeViewPlayBreakReason) {
    BDASplashShakeViewPlayBreakReasonUnknown = 0,
    BDASplashShakeViewPlayBreakReasonJumpToWeb = 1,
    BDASplashShakeViewPlayBreakReasonSkipAd = 2,
    BDASplashShakeViewPlayBreakReasonEnterBackground = 7,
    BDASplashShakeViewPlayBreakReasonNoSecondResource = 8,
    BDASplashShakeViewPlayBreakReasonNoTipResource = 9,
    BDASplashShakeViewPlayBreakReasonNoAllResource = 10,
};

@protocol BDASplashShakeProtocol <NSObject>

@required

/// 摇一摇视图非跳过区域被点击
- (void)adAreaClicked;

/// 摇一摇视图跳过按钮被点击
- (void)skipButtonClicked;

/// 摇一摇 展示/播放 结束
- (void)shakeViewShowFinished:(BOOL)animated;

/// 进入后台
- (void)enterBackground;

- (void)openWebAction;

@end

/// 摇一摇创意开屏，容器视图，将提示摇一摇的图片和二阶视图装在这个容器里面，加到开屏上面展示
@interface BDASplashShakeContainerView : UIView <BDASplashShakeProtocol>

@property (nonatomic, weak) id<BDASplashViewProtocol> delegate;
@property (nonatomic, assign, readonly) BOOL shakeIsShowing;

- (instancetype)initWithFrame:(CGRect)frame model:(TTAdSplashModel *)model targetView:(BDASplashView *)targetView mainSplashView:(TTAdSplashControllerView *)mainSplashView;

/// 是否展示摇一摇创意，这里面主要判断各个阶段的素材是否下载成功，有一个不成功则展示普通开屏。
/// @param model 广告数据 model
+ (BOOL)shouldShowShakeCreativeWithModel:(TTAdSplashModel *)model;

- (void)showShakeTipView;

@end

NS_ASSUME_NONNULL_END
