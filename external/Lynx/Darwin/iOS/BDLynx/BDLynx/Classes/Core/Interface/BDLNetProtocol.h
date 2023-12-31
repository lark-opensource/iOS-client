//
//  BDLNetProtocol.h
//  BDLynx
//
//  Created by zys on 2020/2/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDLNetWorkType) {
  BDLNetWorkTypeNoNet,     // 无网络
  BDLNetWorkTypeDataFlow,  // 数据流量
  BDLNetWorkTypeWifi,      // wifi
  BDLNetWorkTypeUnKnow     // 未知
};

/**
 * 调用宿主网络请求功能
 */
@protocol BDLNetProtocol <NSObject>

typedef void (^BDLynxTemplateLoadBlock)(NSData *data, NSError *error);

/**
 * 单例对象
 */
+ (instancetype)sharedInstance;

- (void)downloadTaskWithRequest:(NSURL *)url
                     parameters:(NSDictionary *)parameters
                    headerField:(NSDictionary *)headerField
                    destination:(NSURL *)destUrl
              completionHandler:(void (^)(NSString *path, NSError *error))completionHandler;

/**
 *  返回当前网络的连接状态
 */
- (BOOL)isNetworkConnected;
/**
 *  返回当前网络的类型，其中BDPNetworkTypeMobile可以掩码的方式组合类型，例如 type =
 * (BDPNetworkTypeMobile | BDPNetworkType2G/3G/4G)
 */
- (BDLNetWorkType)networkType;
/**
 *  启用网络变化通知，在网络变化时，发送Notification(name:bdp_reachabilityChangedNotification)，需要宿主来实现监听网络变化并发送通知的能力
 */
- (void)startReachabilityChangedNotifier;
/**
 *  停用网络变化通知
 */
- (void)stopReachabilityChangedNotifier;
/**
 *  网络状态变化的通知的名称，由宿主决定并返回
 */
- (NSNotificationName)reachabilityChangedNotification;

@end

NS_ASSUME_NONNULL_END
