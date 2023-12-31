//
//  LVEffectManager.h
//  LVTemplate
//
//  Created by lxp on 2020/2/18.
//

#import <Foundation/Foundation.h>
#import "EffectPlatform+LV.h"
#import "LVEffectDownloadProxy.h"
#import "LVEffectPlatformSDKProxy.h"
NS_ASSUME_NONNULL_BEGIN

@interface LVEffectManager : NSObject

/// 注册特效下载能力和参数
/// @param delegate EffectPlatformSDK的网络代理
/// @param channel BDTracker的channel，"App Store" 或 "local_test"
/// @param region 地区 ocale.current.regionCode，如cn、us
/// @param domain 特效平台域名，必须设置！
/// @param language 语言
/// @param deviceID 设备ID
/// @param appID APPID，必须传
/// @param extraConfig 额外的参数设置
/// @param autoUpdateAllEffectList 自动更新，剪映传YES，其他传NO
/// @param isAbroad 是否拉取剪映海外的特效资源
+ (void)setup:(id<EffectPlatformRequestDelegate>)delegate
      channel:(NSString *)channel
       region:(NSString *)region
       domain:(NSString *)domain
     language:(NSString *)language
     deviceID:(NSString *)deviceID
devicePlatform:(NSString *)devicePlatform
        appID:(NSString *)appID
  extraConfig:(nullable void(^)(EffectPlatform *effectPlatform))extraConfig
autoUpdateAllEffectList:(BOOL)autoUpdateAllEffectList
     isAbroad:(BOOL)isAbroad
    needCache:(BOOL)needCache;

+ (EffectPlatform *)defaultInstance;
/// 热切换语言
+ (BOOL)switchLanguage:(NSString *)language;

+ (LVEffectDownloadProxy *)proxy;

+ (LVEffectPlatformSDKProxy *)lokiPlatformProxy;

+ (void)setEnvironment:(BOOL)isBOE;

+ (void)setRegion:(NSString *)region;

+ (EffectPlatform *)lvEffectPlatform;

@end

NS_ASSUME_NONNULL_END
