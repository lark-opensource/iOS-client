//
//  PNSServiceCenter.h
//  PNSServiceKit
//
//  Created by chirenhua on 2022/6/14.
//

#import <Foundation/Foundation.h>

#define PNS_BIND_CLASS(cls_name, protocol_name)\
[[PNSServiceCenter sharedInstance] bindClass:cls_name.class toProtocol:@protocol(protocol_name)];

#define PNS_BIND_INSTANCE(instance, protocol_name)\
[[PNSServiceCenter sharedInstance] bindInstance:instance toProtocol:@protocol(protocol_name)];

#define PNS_GET_CLASS(protocol_name)\
((Class<protocol_name>)[[PNSServiceCenter sharedInstance] getClass:@protocol(protocol_name)])

#define PNS_GET_INSTANCE(protocol_name)\
((id<protocol_name>)[[PNSServiceCenter sharedInstance] getInstance:@protocol(protocol_name)])

NS_ASSUME_NONNULL_BEGIN

@interface PNSServiceCenter : NSObject

/**
 PNSServiceCenter 单例
 
 @return 单例
 */
+ (instancetype)sharedInstance;

/**
 绑定 Class 和 Protocol 映射关系
 
 @param cls 类
 @param protocol 协议
 */
- (void)bindClass:(Class)cls toProtocol:(Protocol *)protocol;

/**
 绑定 Instance 和 Protocol 映射关系
 
 @param instance 类
 @param protocol 协议
 */
- (void)bindInstance:(id)instance toProtocol:(Protocol *)protocol;

/**
通过 Protocol 获取对应 Class 的实例，多次获取拿到的是同一个实例

@param protocol 协议
@return 实例，可能为空
*/
- (nullable id)getInstance:(Protocol *)protocol;

/**
通过 Protocol 获取对应的 Class

@param protocol 协议
@return Class
*/
- (Class)getClass:(Protocol *)protocol;

@end

NS_ASSUME_NONNULL_END
