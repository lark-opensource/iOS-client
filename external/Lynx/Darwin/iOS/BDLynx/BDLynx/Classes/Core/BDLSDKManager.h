//
//  BDLSDKManager.h
//  BDLynx
//
//  Created by zys on 2020/2/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDLSDKManager : NSObject

/**
 * SDK 启动
 */
+ (void)setup;

/**
 * Lynx 版本号
 */
+ (NSString *)lynxVersionString;

+ (NSObject *)getSystemInfoByKey:(NSString *__nonnull)key;

+ (NSDictionary *)getAllSystemInfo;

/**
 * 绑定协议和协议的实现类
 * @param cls 协议实现类，实现了 sharedInstance，是单例
 * @param protocol 协议
 */
+ (void)bdl_bindServiceClass:(Class)cls toProtocol:(Protocol *)protocol;

/**
 * 通过协议获取实现，需要宿主判断是否实现协议方法
 * @param protocol 协议，实现了 sharedInstance，返回单例
 * @return 协议实现类的对象；如果没有绑定过协议，返回空
 */
+ (_Nullable id)bdl_serviceWithProtocol:(Protocol *)protocol;

/**
 * 通过协议获取实现
 * @param protocol 协议，实现了 sharedInstance，返回单例
 * @return 协议实现类的对象；如果没有绑定过协议或者对象没有实现方法 返回空
 */
+ (_Nullable id)bdl_serviceWithProtocol:(Protocol *)protocol selector:(SEL)selector;
#pragma mark - Macro

/**
 * 绑定协议
 */
#define BDL_BIND_SERVICE(cls, pro) \
  ([BDLSDKManager bdl_bindServiceClass:cls toProtocol:@protocol(pro)])

/**
 * 获取实现指定协议的对象
 */
#define BDL_SERVICE(pro) ((id<pro>)([BDLSDKManager bdl_serviceWithProtocol:@protocol(pro)]))

/**
 * 获取实现指定方法的对象
 */
#define BDL_SERVICE_WITH_SELECTOR(pro, sel) \
  ((id<pro>)([BDLSDKManager bdl_serviceWithProtocol:@protocol(pro) selector:sel]))

@end

NS_ASSUME_NONNULL_END
