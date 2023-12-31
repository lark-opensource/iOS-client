//
//  TTAdSplashInterceptDelegate.h
//  TTAdSplashSDK
//
//  Created by resober on 2018/12/24.
//

#ifndef TTAdSplashInterceptDelegate_h
#define TTAdSplashInterceptDelegate_h

#import "TTAdSplashModel.h"

@protocol TTAdSplashInterceptDelegate <NSObject>
@optional

/**
 *  @brief 开屏SDK通过拉取预加载广告接口，提供给宿主过滤当前请求所有广告的机会
 *  @param splashModels 获取到的 splashModels
 *  原生广告根据 splashDisplayType == 1
 */
- (void)didFetchSplashModels:(NSArray<TTAdSplashModel *> *)splashModels;

/**
 *  @brief 开屏SDK回调宿主当前可以展示的原生开屏广告id数组，
 *  @param splashAdIds 当前可以展示的原生广告id数组
 *  @return 宿主挑选的可以展示的原生广告id，如果返回 nil 或者 @"" 则代表无可用展示
 *  e.g. 当前缓存队列  [A1, A2, B1, A3, B2, A4]
 *       其中A类型为普通广告 B类型为原生广告
 *       if 发现 A1 可用  = @[];
 *       if 发现 A2 可用  = @[];
 *       if 发现 A3 可用  = @[B1].isSuitable;
 *       if 发现 A4 可用  = @[B1, B2].isSuitable;
 *       if 发现 无可用 splashAdIds = @[B1, B2].isSuitable;
 *       SDK挑选可用广告时会过滤掉原生开屏类型的广告，但保证所有原生开屏也遵循display_after、expire_timestamp等控制
 */
- (NSString *)pickAwesomeSplashAdWithValidIds:(NSArray<NSString *> *)splashAdIds;

/**
 同`pickAwesomeSplashAdWithValidIds`，区别是传入传出的数据是model而不是splash_ad_id

 @param splashModels 当前有机会展示的原生开屏广告模型
 @return 宿主告知的可以展示的原生开屏广告模型
 */
- (TTAdSplashModel *)pickAwesomeSplashAdWithValidModels:(NSArray<TTAdSplashModel *> *)splashModels;

/// 原生开屏是否需要校验素材
- (BOOL)shouldOriginSplashCheckResource;

@end

#endif /* TTAdSplashInterceptDelegate_h */
