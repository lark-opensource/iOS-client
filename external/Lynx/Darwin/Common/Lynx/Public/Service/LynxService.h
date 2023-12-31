//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICE_H_
#define DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICE_H_
#import <Foundation/Foundation.h>
#import "LynxDefines.h"
#import "LynxServiceMonitorProtocol.h"
#import "LynxServiceProtocol.h"
#import "LynxServiceTrailProtocol.h"
#ifdef OS_IOS
#import "LynxServiceImageProtocol.h"
#import "LynxServiceTrackEventProtocol.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/*
 * You can use @LynxServiceRegister to specify a LynxService will be
 * registered into LynxServices instance automatically. This annotation
 * should only be used for LynxServices subclasses, and before the
 * @implementation code fragment in the .m file. e.g.: LynxMonitorService
 * is a subclass of LynxServices, in LynxMonitorService.m
 * // ...import headers...
 * @LynxServiceRegister(LynxMonitorService)
 * @implmentation LynxMonitorService
 * //...
 * @end
 */

#ifndef LynxServiceRegister
#define LynxServiceRegister(clsName)                                                   \
  interface LynxServices(clsName) @end @implementation LynxServices(clsName)           \
  +(NSString *)LYNX_CONCAT(__lynx_auto_register_serivce__,                             \
                           LYNX_CONCAT(clsName, LYNX_CONCAT(__LINE__, __COUNTER__))) { \
    return @ #clsName;                                                                 \
  }                                                                                    \
  @end
#endif

/**
 * 绑定协议和类，如：LYNX_SERVICE_BIND（LynxMonitorService,
 * LynxMonitorProtocol)
 */
#define LynxServiceBind(cls, pro) ([LynxServices bindClass:cls toProtocol:@protocol(pro)])

/**
 * 获取实现指定协议的默认对象，如：LYNX_SERVICE(LynxMonitorProtocol) ->
 * id<LynxMonitorProtocol>
 */
#define LynxService(pro) \
  ((id<pro>)([LynxServices getInstanceWithProtocol:@protocol(pro) bizID:DEFAULT_LYNX_SERVICE]))
/**
 * 获取实现指定协议的对象，如：LYNX_SERVICE(LynxMonitorProtocol, default) ->
 * id<LynxMonitorProtocol>
 */
#define LynxServiceBID(pro, bid) \
  ((id<pro>)([LynxServices getInstanceWithProtocol:@protocol(pro) bizID:bid]))

/**
 * Get LynxTrail Instance
 * LynxTrail
 */
#define LynxTrail LynxService(LynxServiceTrailProtocol)

@interface LynxServices : NSObject

/**
 * 注册默认服务
 * @param cls 协议实现类，实现了 sharedInstance，是单例
 */
+ (void)registerService:(Class)cls;

/**
 * 绑定协议和协议的实现类
 * @param cls 协议实现类，实现了 sharedInstance，是单例
 * @param protocol 协议
 */
+ (void)bindClass:(Class)cls toProtocol:(Protocol *)protocol;

/**
 * 通过协议获取实现
 * @param protocol 协议，实现了 sharedInstance，返回单例
 * @param bizID 业务ID
 * @return 协议实现类的对象；如果没有绑定过协议，返回空
 */
+ (id)getInstanceWithProtocol:(Protocol *)protocol bizID:(NSString *__nullable)bizID;

@end

NS_ASSUME_NONNULL_END
#endif  // DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICE_H_
