//
//  CJPayBridgeBlockRegister.m
//  Pods
//
//  Created by 利国卿 on 2022/8/11.
//

#import "CJPayBridgeBlockRegister.h"
#import "CJPaySDKMacro.h"
#import <objc/runtime.h>

@implementation CJPayBridgeBlockRegister

// 兼容不同版本的TTBridgeUnify block注册逻辑
+ (void)registerBridgeName:(NSString *)bridgeName
                engineType:(TTBridgeRegisterEngineType)engineType
                  authType:(TTBridgeAuthType)authType
                   domains:(nullable NSArray<NSString *> *)domains
         needBridgeCommand:(BOOL)needBridgeCommand
                   handler:(bridgeHandleBlock)handler {

    TTBridgeRegister *bridgeRegister = [TTBridgeRegister sharedRegister];
    SEL sel = NSSelectorFromString(@"registerMethod:handlerWithCommand:engineType:authType:domains:");
    if (needBridgeCommand && [bridgeRegister respondsToSelector:sel]) {
        [bridgeRegister btd_performSelectorWithArgs:sel, bridgeName, handler, engineType, authType, domains];
    } else {
        [bridgeRegister registerMethod:bridgeName handler:^(NSDictionary * _Nullable params, TTBridgeCallback  _Nonnull callback, id<TTBridgeEngine>  _Nonnull engine, UIViewController * _Nullable controller) {

            CJ_CALL_BLOCK(handler, params, callback, engine, controller, nil);
        } engineType:engineType authType:authType domains:domains];
    }
}

// 关联plugin实例和engine，使plugin实例可以和前端页面的生命周期保持一致
+ (TTBridgePlugin *)associatedPluginsOnEngine:(id<TTBridgeEngine>)engine
                              pluginClassName:(NSString *)className {
    
    TTBridgePlugin *plugin;
    Class cls = NSClassFromString(className);
    if (![cls isSubclassOfClass:[TTBridgePlugin class]]) {
        return plugin;
    }
    //取得与engine关联的plugin实例
    NSString *associatedKey = [NSString stringWithFormat:@"ttcjpay_%@", className];
    plugin = objc_getAssociatedObject(engine, NSSelectorFromString(associatedKey));
    if (!plugin) {
        plugin = [[cls alloc] init];
        plugin.engine = engine;
        objc_setAssociatedObject(engine, NSSelectorFromString(associatedKey), plugin, OBJC_ASSOCIATION_RETAIN);
    }
    return plugin;
}

@end
