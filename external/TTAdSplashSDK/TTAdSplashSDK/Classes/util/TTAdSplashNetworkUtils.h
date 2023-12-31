//
//  TTAdSplashNetworkUtils.h
//  TTAdSplashSDK
//
//  Created by yin on 2017/8/2.
//  Copyright © 2017年 yin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSInteger, TTAdSplashNetworkFlags) {
    TTAdSplashNetworkFlagWifi   = 1,
    TTAdSplashNetworkFlag4G     = 1 << 1,
    TTAdSplashNetworkFlag3G     = 1 << 2,
    TTAdSplashNetworkFlag2G     = 1 << 3,
    TTAdSplashNetworkFlagMobile = 1 << 4,
    TTAdSplashNetworkFlag5G     = 1 << 5, ///< 之前设计的时候没考虑 5G，所以倒排的，为了兼容，这里排在了 mobile 后面。
};

/**
 网络工具类, 主要用于检测网络状态, 拼接 URL 等工作.
 */
@interface TTAdSplashNetworkUtils : NSObject

/**
 是否有网络连接
 */
BOOL TTAdSplashNetworkConnected(void);

/**
 是否有 WiFi 网络连接
 */
BOOL TTAdSplashNetworkWifiConnected(void);

/**
 获取当前具体网络状态
 */
TTAdSplashNetworkFlags TTAdSplashNetworkGetFlags(void);

/**
 将参数拼接到 URL 后面, 在这期间会进行 URL 合法性校验

 @param URLStr URL 字符串
 @param commonParams 需要拼接的参数
 @return 拼接完成的 URL 字符串
 */
+ (NSString*)URLString:(NSString *)URLStr appendCommonParams:(NSDictionary *)commonParams;
@end
