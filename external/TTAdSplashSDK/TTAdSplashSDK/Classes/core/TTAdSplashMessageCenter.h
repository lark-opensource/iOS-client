//
//  TTAdSplashMessageCenter.h
//  TTAdSplashSDK
//
//  Created by yin on 2017/8/8.
//  Copyright © 2017年 yin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTAdSplashHeader.h"
#import "TTAdSplashDelegate.h"
#import "TTAdSplashURLTracker.h"
#import "BDASplashOMTrackDelegate.h"
#import "TTAdSplashInterceptDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTAdSplashMessageCenter : NSObject

@property (nonatomic, weak) id<TTAdSplashDelegate> delegate;
@property (nonatomic, weak) id<TTAdSplashInterceptDelegate> splashInterceptDelegate;
@property (nonatomic, weak) id<BDASplashOMTrackDelegate> omTrackDelegate;   ///< OM SDK 事件上报 delegate
+ (instancetype)shareInstance;

- (void)requestWithUrl:(NSString *)urlString resultBlock:(TTAdSplashResultBlock)resultBlock;

- (void)requestWithUrl:(NSString *)urlString
                method:(BDAdSplashRequestMethod)method
               headers:(NSDictionary *)headers
                  body:(NSDictionary *)body
                 param:(NSDictionary *)param
           resultBlock:(BDAdSplashResultBlock)resultBlock;

- (NSString *)splashBaseUrl;

- (NSString *)splashPathUrl;

- (NSString *)deviceId;

- (NSString *)installId;

- (NSString *)splashNetwokType;

- (NSNumber *)ntType;

- (UIImage *)splashBgImage;

- (nullable UIView *)splashFakeLaunchView;

- (UIImage *)splashVideoLogo;

- (UIImage *)splashWifiImage;

- (UIImage *)splashViewMoreImage;

- (UIImage *)splashArrowImage;

- (UIView *)splashBGViewWithFrame:(CGRect)frame;

- (UIView *)splashLogoViewWithColor:(BDASplashLogoColor)color;

- (UIView *)splashWifiView;

- (UIView *)splashReadMoreView;

- (NSString *)splashSkipBtnName;

- (BOOL)isSplashSkipBtnInBottom;

- (NSString *)splashOpenAppString;

- (NSString *)splashReadMoreString;

- (NSUInteger)logoAreaHeight;

- (NSUInteger)skipButtonBottomOffsetWithBannerMode:(TTAdSplashBannerMode)mode;

- (TTAdSplashPreloadPolicy)preloadPolicy;

- (TTAdSplashDisplayContentMode)displayContentMode;

- (void)downloadCanvasResource:(NSDictionary *)dict;

- (BOOL)enableSplashLog;

- (BOOL)enableSplashGifKadunOptimize;

- (BOOL)enableShowBDImageView;

- (BOOL)enableSplashAudioSessionStalledOptimization;

- (BOOL)enablePreloadReconsitution;

- (void)splashViewWillAppear;

- (void)splashViewWillAppearWithAdModel:(TTAdSplashModel *)model;

- (void)splashViewAppearWithAdInfo:(NSDictionary *)adInfo;

- (void)splashViewAppearWithAdModel:(TTAdSplashModel *)model;

- (void)splashViewDidDisappearWithAdModel:(TTAdSplashModel *)model;

/// 开屏广告向上滑动完成
- (void)splashViewDidScrollCompleted;

- (BOOL)isNewUserForSplashSecondPhaseAnimation;

// 是否支持横屏模式
- (BOOL)isSupportLandscape;

- (void)splashActionWithCondition:(NSDictionary *)condition;

- (void)reportInfoWithAdInfo:(NSDictionary *)param;

- (BOOL)realTimeRequestUseTTNet;

- (void)trackURLs:(NSArray *)URLs model:(TTAdSplashURLTrackerModel *)trackModel;

- (void)trackWithTag:(NSString *)tag label:(NSString *)label adId:(NSString *)adId logExtra:(NSString*)logExtra extra:(NSDictionary *)extra;

- (void)trackWithTag:(NSString *)tag label:(NSString *)label extra:(NSDictionary *)extra;

- (void)trackWithAllTag:(NSString *)tag label:(NSString *)label adId:(NSString *)adId logExtra:(NSString*)logExtra extra:(NSDictionary *)extra;

- (void)trackV3WithEvent:(NSString *)event params:(NSDictionary *_Nullable)params isDoubleSending:(BOOL)isDoubleSending;

- (void)monitorService:(NSString *)serviceName status:(NSUInteger)status extra:(NSDictionary *)extra;

- (void)monitorService:(NSString *)serviceName value:(NSDictionary *)params extra:(NSDictionary *)extra;

//预加载小程序
- (void)preloadSplashAdMpURLList:(NSArray<NSString *> *)mpURLList;

//预加载落地页
- (void)preloadSplashAdWebSplashList:(NSArray *)splashList;

/// 获取开屏广告调试日志
/// @param log 调试日志
- (void)splashDebugLog:(NSString *)log;

- (BOOL)shouldDisplayPersonalizedAd;
//预加载小程序
- (void)preloadSplashAdMpURLList:(NSArray<NSString *> *)mpURLList;

//预加载落地页
- (void)preloadSplashAdWebSplashList:(NSArray *)splashList;

- (BOOL)splashShouldContainCoordinateInParams;

- (void)shakeViewSkipButtonClicked;

- (UIView *)splashSwipeGuideView:(BOOL)needShadow;

#pragma mark - TTAdSplashInterceptDelegateMediator

/// 主要用于宿主 预加载 readonly
/// @param splashModels 本次预加载获取的 广告数据列表
- (void)didFetchSplashModels:(NSArray<TTAdSplashModel *> *)splashModels;

- (NSString *)pickAwesomeSplashAdWithValidIds:(NSArray<NSString *> *)splashAdIds;
- (TTAdSplashModel *)pickAwesomeSplashAdWithValidModels:(NSArray<TTAdSplashModel *> *)splashModels;

- (BOOL)topViewSDKPreloadEnable;

- (BOOL)isVideoPreloadSuccess:(NSString *)key videoId:(NSString *)vid;

- (void)removeTopViewResource:(NSString *)key;

- (void)preloadVideoWithCondition:(NSDictionary *)condition completionBlock:(TTAdSplashPreloadVideoFinishBlock)completionBlock;

- (BOOL)shouldOriginSplashCheckResource;

#pragma mark - OM SDK 上报事件

- (void)trackOMImpressionWithParams:(NSDictionary *)params adView:(UIView *)adView;

- (void)trackOMVideoStartWithParams:(NSDictionary *)params adView:(UIView *)adView;

- (void)trackOMVideoFirstQuartileWithParams:(NSDictionary *)params adView:(UIView *)adView;

- (void)trackOMVideoMidpointWithParams:(NSDictionary *)params adView:(UIView *)adView;

- (void)trackOMVideoThirdQuartileWithParams:(NSDictionary *)params adView:(UIView *)adView;

- (void)trackOMVideoCompleteWithParams:(NSDictionary *)params adView:(UIView *)adView;

- (void)trackOMSkipWithParams:(NSDictionary *)params adView:(UIView *)adView;

- (void)trackOMImageCompleteWithParams:(NSDictionary *)params adView:(UIView *)adView;

- (void)trackOMClickEventWithParams:(NSDictionary *)params adView:(UIView *)adView;

@end

NS_ASSUME_NONNULL_END
