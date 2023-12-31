//
//  BDPNetworkPluginDelegate.h
//  Timor
//
//  Created by 维旭光 on 2019/3/22.
//

#ifndef BDPNetworkPluginDelegate_h
#define BDPNetworkPluginDelegate_h

#import "BDPBasePluginDelegate.h"
#import <ECOInfra/BDPNetworkProtocol.h>
#import "BDPUniqueID.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSInteger, BDPNetworkType) {
    BDPNetworkTypeWifi   = 1 << 0,
    BDPNetworkType4G     = 1 << 1,
    BDPNetworkType3G     = 1 << 2,
    BDPNetworkType2G     = 1 << 3,
    BDPNetworkTypeMobile = 1 << 4
};

@protocol BDPNetworkPluginDelegate <BDPBasePluginDelegate>
@optional
- (NSString *)bdp_customReferWithUniqueID:(BDPUniqueID*)uniqueId;
- (NSString *)bdp_customUserAgent;
/**
 *  为ImageView设置网络图片
 *  @param imageView imageView
 *  @param url url
 *  @param placeholder 占位图
 */
- (void)bdp_setImageView:(UIImageView *)imageView url:(NSURL *)url placeholder:(UIImage *)placeholder;

/**
 *  返回当前网络的连接状态
 */
- (BOOL)bdp_isNetworkConnected;
/**
 *  返回当前网络的类型，其中BDPNetworkTypeMobile可以掩码的方式组合类型，例如 type = (BDPNetworkTypeMobile | BDPNetworkType2G/3G/4G)
 */
- (BDPNetworkType)bdp_networkType;
/**
 *  启用网络变化通知，在网络变化时，发送Notification(name:bdp_reachabilityChangedNotification)，需要宿主来实现监听网络变化并发送通知的能力
 */
- (void)bdp_startReachabilityChangedNotifier;
/**
 *  停用网络变化通知
 */
- (void)bdp_stopReachabilityChangedNotifier;
/**
 *  网络状态变化的通知的名称，由宿主决定并返回
 */
- (NSNotificationName)bdp_reachabilityChangedNotification;

/// 小程序引擎相关网络请求共用的url session
- (NSURLSession *)bdp_sharedSession;

/// 小程序引擎相关网络请求走RustHttpProtocol时的metrics
- (NSDictionary *)bdp_rustMetricsForTask:(NSURLSessionTask *)task;

/// 小程序引擎相关网络请求是否使用RustHttpProtocol
- (BOOL)bdp_isNetworkTransmitOverRustChannel;

/// 宿主定制是否需要存储小程序网络请求的cookie
- (BOOL)bdp_HTTPShouldHandleCookies;

-(NSString *)bdp_openAppInterfaceDomain;

@property(nonatomic,strong)id<BDPNetworkRequestProtocol> customNetworkManager;

@end

NS_ASSUME_NONNULL_END

#endif /* BDPNetworkPluginDelegate_h */
