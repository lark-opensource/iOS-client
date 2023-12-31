//
//  BDASplashView.h
//  TTAdSplashSDK
//
//  Created by boolchow on 2020/3/9.
//

#import <UIKit/UIKit.h>
#import "BDASplashViewTargetActionProtocol.h"

@class BDASplashView;
@class TTAdSplashModel;
@class BDASplashImageView;
@class BDASplashBannerView;
@class BDASplashVideoContainer;
@class TTAdSplashHittestButton;
@class BDImageView;
@class BDASplashAddFansView;

NS_ASSUME_NONNULL_BEGIN

#define AD_LABEL_RIGHT_MARGIN 13
#define AD_SKIP_BUTTON_RIGHT_MARGIN 15
#define AD_SKIP_BUTTON_WIDTH 64
#define AD_SKIP_BUTTON_HEIGHT 32

/** 控制广告样式 */
typedef NS_ENUM(NSInteger, BDALabelPositionStyle) {
    BDALabelPositionStyleDefault = 0,         ///< 默认样式，与旧样式相同
    BDALabelPositionStyleSkipOnTop = 1,       ///< 样式1，跳过按钮在右上方
    BDALabelPositionStyleSkipOnBottom  = 2,   ///< 样式2，跳过按钮在右下
    BDALabelPositionStyleAdLabelOnBottom = 4, ///< 因为 ‘3’ 被其他业务占用，这里是 ‘4’，广告 label 在左下角。
};

/** 开屏广告 view。主视图，所有的 view 元素都会加到这个视图上面，然后将这个视图加到 vc 上面展示. 此 view 的设计文档：https://bytedance.feishu.cn/docs/doccnjso9zWQYL3lUvHGaDFTLsf */
@interface BDASplashView : UIView<BDASplashViewTargetActionProtocol>
@property (nonatomic, strong, readonly) TTAdSplashModel *model;
@property (nonatomic, strong, nullable) NSDate *adStartTime;
@property (nonatomic, strong, readonly) UIView *bannerActionButton;
@property (nonatomic, strong, readonly) BDASplashBannerView *bannerView;
@property (nonatomic, strong, readonly) BDASplashAddFansView *addFansView;    ///< 加粉视图
@property (nonatomic, strong, readonly) TTAdSplashHittestButton *bgButton;
@property (nonatomic, strong, readonly) BDASplashVideoContainer *videoView;
@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, strong, readonly) BDImageView *bdImageView;
@property (nonatomic, assign) CFAbsoluteTime srcBeginShowTime;
@property (nonatomic, assign) CFAbsoluteTime srcLoadDuration;
@property (nonatomic, weak) id<BDASplashViewProtocol> delegate;
@property (nonatomic, assign) BOOL shakeViewIsShowing;
@property (nonatomic, assign) BOOL shakeViewIsReady;
@property (nonatomic, assign) BOOL btnAnimationHasShown;

- (void)updateModel:(TTAdSplashModel *)model;

- (void)willAppear;

- (void)didAppear;

- (void)didDisappear;

- (void)willDisappear;

- (void)showAdVideo;

- (CGRect)skipButtonFrame;

- (void)cleanTimer;

- (CGFloat)topIconCenterY;

//暴露接口，hook用，请勿随意更改名字
- (void)setupAudioSession;

@end

NS_ASSUME_NONNULL_END
