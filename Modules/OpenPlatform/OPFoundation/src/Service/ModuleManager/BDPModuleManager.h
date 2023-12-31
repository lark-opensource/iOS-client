//
//  BDPModuleManager.h
//  Timor
//
//  Created by houjihu on 2020/1/19.
//  Copyright © 2020 houjihu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDPModuleEngineType.h"

NS_ASSUME_NONNULL_BEGIN

/// 查找模块
#define BDPResolveModule(moduleVaiableName, protocolName, engineType) id<protocolName> moduleVaiableName = (id<protocolName>)[[BDPModuleManager moduleManagerOfType:engineType] resolveModuleWithProtocol:@protocol(protocolName)];

/// 获取查找到的模块实例
#define BDPGetResolvedModule(protocolName, engineType) ((id<protocolName>)[[BDPModuleManager moduleManagerOfType:engineType] resolveModuleWithProtocol:@protocol(protocolName)])

/// 注册模块
#define BDPRegisterModule(moduleClassName, protocolName, engineType) [[BDPModuleManager moduleManagerOfType:engineType] registerModuleWithProtocol:@protocol(protocolName) class:[moduleClassName class]];

@protocol BDPModuleProtocol;

/// 模块管理类
@interface BDPModuleManager : NSObject

/// 应用类型
@property (nonatomic, assign, readonly) BDPType type;

#pragma mark - life cycle

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

/// 模块管理类初始化
/// @param type 应用类型
+ (instancetype)moduleManagerOfType:(BDPType)type;

#pragma mark - register & resolve


/// 注册模块
/// @param protocol 模块对外暴露的协议
/// @param handler 模块实现类初始化block
- (void)registerModuleWithProtocol:(Protocol *)protocol handler:(id<BDPModuleProtocol> (^)(BDPModuleManager *moduleManager))handler;

/// 注册模块，自动调用模块实现类的init方法，并在模块注册完成后发送通知
/// @param protocol 模块对外暴露的协议
/// @param cls 模块实现类
- (void)registerModuleWithProtocol:(Protocol *)protocol class:(Class<BDPModuleProtocol>)cls;

/// 注册模块，并在模块注册完成后发送通知
/// @param protocol 模块对外暴露的协议
/// @param cls 模块实现类
/// @param handler 模块实现类初始化block
- (void)registerModuleWithProtocol:(Protocol *)protocol class:(nullable Class<BDPModuleProtocol>)cls handler:(nullable id<BDPModuleProtocol> (^)(BDPModuleManager *))handler;

/// 查找模块
/// @param protocol 模块对外暴露的协议
/// @return 模块实现类对象
- (nullable id<BDPModuleProtocol>)resolveModuleWithProtocol:(Protocol *)protocol;

@end

NS_ASSUME_NONNULL_END
