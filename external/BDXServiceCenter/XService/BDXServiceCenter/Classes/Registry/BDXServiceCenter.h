//
//  BDXServiceCenter.h
//  BDXServiceCenter
//
//  Created by bill on 2021/3/1.
//

#import <Foundation/Foundation.h>
#import "BDXServiceManager.h"

/// Protocols
#import "BDXLynxKitProtocol.h"
#import "BDXMonitorProtocol.h"
#import "BDXOptimizeProtocol.h"
#import "BDXResourceLoaderProtocol.h"
#import "BDXRouterProtocol.h"
#import "BDXSchemaProtocol.h"
#import "BDXServiceProtocol.h"
#import "BDXViewContainerProtocol.h"
#import "BDXWebKitProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 绑定协议和类，如：BDXSERVICE_BIND_CLASS_TO_PROTOCOL（BDXResourceAdapter,
 * BDXResourceProtocol)
 */
#define BDXSERVICE_BIND_CLASS_TO_PROTOCOL(cls, pro) ([BDXServiceManager bindClass:cls toProtocol:@protocol(pro)])

/**
 * 获取实现指定协议的对象，如：BDXSERVICE(BDXResourceProtocol, ecom) ->
 * id<BDXResourceProtocol>
 * 获取实现指定协议的对象，如：BDXSERVICE_OBJECT_WITH_PROTOCOL(BDXResourceProtocol,
 * ecom) -> id<BDXResourceProtocol>
 */
#define BDXSERVICE(pro, bid) ((id<pro>)([BDXServiceManager getObjectWithProtocol:@protocol(pro) bizID:bid]))
#define BDXSERVICE_WITH_DEFAULT(pro, bid) (BDXSERVICE(pro, (bid)) ?: (!(bid) ? nil : BDXSERVICE(pro, nil)))
#define BDXSERVICE_OBJECT_WITH_PROTOCOL(pro, bid) ((id<pro>)([BDXServiceManager getObjectWithProtocol:@protocol(pro) bizID:bid]))

/**
 * 获取实现指定协议的类，如：BDXSERVICE_CLASS(BDXResourceProtocol) -> Class
 * 获取实现指定协议的类，如：BDXSERVICE_CLASS_WITH_PROTOCOL(BDXResourceProtocol)
 * -> Class
 */
#define BDXSERVICE_CLASS(pro, bid) [BDXServiceManager getClassWithProtocol:@protocol(pro) bizID:bid]
#define BDXSERVICE_CLASS_WITH_DEFAULT(pro, bid) (BDXSERVICE_CLASS(pro, bid) ?: (!(bid) ? nil : BDXSERVICE_CLASS(pro, nil)))
#define BDXSERVICE_CLASS_WITH_PROTOCOL(pro, bid) [BDXServiceManager getClassWithProtocol:@protocol(pro) bizID:bid]

@interface BDXServiceCenter : NSObject

@end

NS_ASSUME_NONNULL_END
