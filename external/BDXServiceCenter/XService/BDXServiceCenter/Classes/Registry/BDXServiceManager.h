//
//  BDXServiceManager.h
//  BDXServiceCenter-Pods-Aweme
//
//  Created by bill on 2021/3/1.
//

#import <Foundation/Foundation.h>
#import "BDXServiceDefines.h"

NS_ASSUME_NONNULL_BEGIN

@class BDXService;

@interface BDXServiceManager : NSObject

@property(class, nonatomic, copy, readonly) NSDictionary<NSString *, BDXService *> *registeredDefaultService;
@property(class, nonatomic, copy, readonly) NSDictionary<NSString *, BDXService *> *registeredCustomsizedService;
@property(class, nonatomic, copy, readonly) NSDictionary<NSString *, Class> *protocolToClassMap;
@property(nonatomic, copy, readonly) NSDictionary<NSString *, BDXService *> *registeredCustomsizeSessionService;

+ (void)registerDefaultSercice:(Class)cls;

+ (void)registerCustomsizedService:(Class)cls;
- (void)registerCustomsizedService:(Class)cls;

/**
 * 绑定协议和协议的实现类
 * @param cls 协议实现类，实现了 sharedInstance，是单例
 * @param protocol 协议
 */
+ (void)bindClass:(Class)cls toProtocol:(Protocol *)protocol;

/**
 * 通过协议获取实现
 * @param protocol 协议，实现了 sharedInstance，返回单例
 * @return 协议实现类的对象；如果没有绑定过协议，返回空
 */
+ (id)getObjectWithProtocol:(Protocol *)protocol;

/**
 * 通过协议获取实现
 * @param protocol 协议，实现了 sharedInstance，返回单例
 * @param bizID 业务ID
 * @return 协议实现类的对象；如果没有绑定过协议，返回空
 */
+ (id)getObjectWithProtocol:(Protocol *)protocol bizID:(NSString *__nullable)bizID;

/**
 * 通过协议获取类
 * @param protocol 协议
 * @return 协议的实现类；如果没有绑定过协议，返回空
 */
+ (Class)getClassWithProtocol:(Protocol *)protocol;

/**
 * 通过协议获取类
 * @param protocol 协议
 * @param bizID 业务ID
 * @return 协议实现类的对象；如果没有绑定过协议，返回空
 */
+ (Class)getClassWithProtocol:(Protocol *)protocol bizID:(NSString *__nullable)bizID;

@end

NS_ASSUME_NONNULL_END
