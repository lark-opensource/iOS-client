//
//  BridgeModuleManager.h
//  FlutterIntergation
//
//  Created by bytedance on 2020/4/3.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BDBridgeHost.h"

NS_ASSUME_NONNULL_BEGIN

/// 用于管理多个Bridge与多个消息载体实例
@interface BDBridgeModuleManager : NSObject

+ (instancetype)sharedManager;

/// 添加特定bridge的消息载体管理实例
/// @param module       管理实例
/// @param clazz        类名
/// @param carrier      载体
- (void)addModule:(id<BDBridgeHost>)module key:(Class)clazz carrier:(NSObject *)carrier;

/// 获取特定类型的bridge消息载体处理实例
/// @param clazz        bridge类型的key
/// @param carrier      特定的消息载体
- (id<BDBridgeHost>)getModule:(Class)clazz carrier:(NSObject *)carrier;

/// 删除某个bridge中特定视图的实例
/// @param clazz        bridge类型的key
/// @param carrier      特定的消息载体
- (void)removeModule:(Class)clazz forCarrier:(NSObject *)carrier;

@end

NS_ASSUME_NONNULL_END
