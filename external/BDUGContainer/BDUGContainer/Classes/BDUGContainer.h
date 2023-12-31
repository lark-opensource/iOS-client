//
//  BDUGContainer.h
//  Pods
//
//  Created by shuncheng on 2018/12/27.
//

#import <Foundation/Foundation.h>

#define BDUG_CONTAINER_OBJECT(theProtocol) \
    [[BDUGContainer sharedInstance] createObjectForProtocol:@protocol(theProtocol)]
#define BDUG_BIND_CLASS_PROTOCOL(theClass, theProtocol) \
    [[BDUGContainer sharedInstance] setClass:theClass forProtocol:@protocol(theProtocol)]

NS_ASSUME_NONNULL_BEGIN

@interface BDUGContainer : NSObject

/**
 BDUGContainer单例
 
 @return 单例
 */
+ (instancetype)sharedInstance;

/**
 建立class protocol 映射
 
 @param cls 类
 @param protocol 协议
 */
- (void)setClass:(Class)cls forProtocol:(Protocol *)protocol;


/**
 通过protocol创建对应class的实例或者单例
 
 @param protocol 协议
 @return 实例或者单例
 */
- (id)createObjectForProtocol:(Protocol *)protocol;


@end

NS_ASSUME_NONNULL_END
