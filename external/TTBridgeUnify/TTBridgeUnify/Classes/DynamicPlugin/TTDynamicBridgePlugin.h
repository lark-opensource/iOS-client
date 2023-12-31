//
//  TTDynamicBridgePlugin.h
//  TTBridgeUnify
//
//  Created by 李琢鹏 on 2019/3/3.
//

#import "TTBridgePlugin.h"

NS_ASSUME_NONNULL_BEGIN
__attribute__((deprecated("此类已经废弃，使用 -[TTBridgeRegister registerBridge:] 替代")))
@interface TTDynamicBridgePlugin : TTBridgePlugin

/**
 TTDynamicBridgePlugin 这个类可以相应任何 bridge 事件,并提供 block api 提供更方便的 birdge 实现方式
 */
+ (void)registerHandlerBlock:(TTBridgePluginHandler)handler forEngine:(id<TTBridgeEngine>)engine bridgeName:(TTBridgeName)bridgeName engineType:(TTBridgeRegisterEngineType)engineType authType:(TTBridgeAuthType)authType;


/**
 为 TTBridgeRegisterAll 注册一个 TTBridgeAuthProtected
 */
+ (void)registerHandlerBlock:(TTBridgePluginHandler)handler forEngine:(id<TTBridgeEngine>)engine bridgeName:(TTBridgeName)bridgeName;

@end

NS_ASSUME_NONNULL_END
