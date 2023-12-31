//
//  BDPNetworking.h
//  Timor
//
//  Created by yinyuan on 2018/12/17.
//

#import <Foundation/Foundation.h>
#import "BDPUtils.h"
#import "BDPTimorClient.h"
#import "BDPNetworkPluginDelegate.h"
#import <ECOInfra/BDPHTTPRequestSerializer.h>
#import <ECOInfra/BDPNetworkRequestExtraConfiguration.h>

@interface BDPNetworking : NSObject

/// 小程序引擎相关网络请求共用的url session
+ (NSURLSession * _Nonnull)sharedSession;

/// 小程序引擎相关网络请求走RustHttpProtocol时的metrics
+ (NSDictionary *)rustMetricsForTask:(NSURLSessionTask *)task;

/// 小程序引擎相关网络请求是否使用RustHttpProtocol
+ (BOOL)isNetworkTransmitOverRustChannel;


// parameters的value如果是数组，请先把json格式变为字符串格式
+ (id<BDPNetworkTaskProtocol>)taskWithRequestUrl:(NSString *)URLString parameters:(id)parameters extraConfig:(BDPNetworkRequestExtraConfiguration*)extraConfig completion:(void (^)(NSError *error, id jsonObj, id<BDPNetworkResponseProtocol> response))completion;

/// 宿主定制是否需要存储小程序网络请求的cookie
+ (BOOL)HTTPShouldHandleCookies;

@end

@interface BDPNetworking (WebImage)

/**
*  为ImageView设置网络图片
*/
+ (void)setImageView:(UIImageView *)imageView url:(NSURL *)url placeholder:(UIImage *)placeholder;

@end

@interface BDPNetworking (Reachability)

/**
 *  获取当前网络的连接状态
 */
+ (BOOL)isNetworkConnected;

/**
 *  获取当前网络的类型
 */
+ (BDPNetworkType)networkType;

/**
 *  启用网络变化通知
 */
+ (void)startReachabilityChangedNotifier;

/**
 *  停用网络变化通知
 */
+ (void)stopReachabilityChangedNotifier;

/**
 *  网络状态变化的通知的名称
 */
+ (NSNotificationName)reachabilityChangedNotification;

@end
