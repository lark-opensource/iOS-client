//
//  CJPayBridgeBlockRegister.h
//  Pods
//
//  Created by 利国卿 on 2022/8/11.
//

#import <TTBridgeUnify/TTBridgeRegister.h>

typedef void(^bridgeHandleBlock)(NSDictionary * _Nullable params, TTBridgeCallback _Nullable callback, id<TTBridgeEngine> _Nullable engine, UIViewController * _Nullable controller, TTBridgeCommand* _Nullable command);

@interface CJPayBridgeBlockRegister : NSObject

// 兼容不同版本的TTBridgeUnify block注册逻辑
+ (void)registerBridgeName:(nullable NSString *)bridgeName
                engineType:(TTBridgeRegisterEngineType)engineType
                  authType:(TTBridgeAuthType)authType
                   domains:(nullable NSArray<NSString *> *)domains
         needBridgeCommand:(BOOL)needBridgeCommand
                   handler:(nullable bridgeHandleBlock)handler;

// 关联plugin实例和engine，使plugin实例可以和前端页面的生命周期保持一致
+ (TTBridgePlugin * _Nullable)associatedPluginsOnEngine:(nullable id<TTBridgeEngine>)engine
                              pluginClassName:(nullable NSString *)className;
@end
