//
//  BDASplashOMTrackDelegate.h
//  TTAdSplashSDK
//
//  Created by boolchow on 2020/1/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** OM SDK 事件上报 delegate，通过 delegate 承接给端上发送埋点 */
@protocol BDASplashOMTrackDelegate <NSObject>

/// OM 监测 impression 事件，展示广告时上报.
/// @param params 上报参数
/// @param adView 展示的 view
- (void)trackOMImpressionWithParams:(NSDictionary *)params adView:(UIView *)adView;

/// OM 监测 start 事件上报，开屏视频播放时上报。
/// @param params 上报参数
/// @param adView 展示的 view
- (void)trackOMVideoStartWithParams:(NSDictionary *)params adView:(UIView *)adView;

/// OM 监测 firstQuartile 事件上报，开屏视频播放 25% 时上报，误差 0.5s。
/// @param params 上报参数
/// @param adView 展示的 view
- (void)trackOMVideoFirstQuartileWithParams:(NSDictionary *)params adView:(UIView *)adView;

/// OM 监测 midPoint 事件上报，开屏视频播放 50% 时上报，误差 0.5s。
/// @param params 上报参数
/// @param adView 展示的 view
- (void)trackOMVideoMidpointWithParams:(NSDictionary *)params adView:(UIView *)adView;

/// OM 监测 thirdQuartile 事件上报，开屏视频播放 75% 时上报，误差 0.5s。
/// @param params 上报参数
/// @param adView 展示的 view
- (void)trackOMVideoThirdQuartileWithParams:(NSDictionary *)params adView:(UIView *)adView;

/// OM 监测 complete 事件上报，开屏视频播放完毕时上报。
/// @param params 上报参数
/// @param adView 展示的 view
- (void)trackOMVideoCompleteWithParams:(NSDictionary *)params adView:(UIView *)adView;

/// OM 监测 skip 事件上报，点击跳过，点击开屏跳转，进入后台中断展示时上报。
/// @param params 上报参数
/// @param adView 展示的 view
- (void)trackOMSkipWithParams:(NSDictionary *)params adView:(UIView *)adView;

/// OM 监测图片展示完成事件上报
/// @param params 上报参数
/// @param adView 展示 view
- (void)trackOMImageCompleteWithParams:(NSDictionary *)params adView:(UIView *)adView;

/// OM 监测开屏点击事件，用于点击事件的上报。当上报Skip时不再上报此事件
/// @param params 上报参数
/// @param adView 展示 view
- (void)trackOMClickEventWithParams:(NSDictionary *)params adView:(UIView *)adView;

@end


NS_ASSUME_NONNULL_END
