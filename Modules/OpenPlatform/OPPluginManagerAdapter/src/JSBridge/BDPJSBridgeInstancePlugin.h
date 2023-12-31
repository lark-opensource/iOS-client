//
//  BDPJSBridgeInstancePlugin.h
//  Timor
//
//  Created by 王浩宇 on 2019/8/29.
//

#import "BDPJSBridgeBase.h"

/**
 JSBridge 类实例插件基础类，[JSBridge registerInstanceMethod] 方法注册的 Class 应该基于此类
 */
@interface BDPJSBridgeInstancePlugin : NSObject

+ (instancetype)sharedPlugin;
+ (BDPJSBridgePluginMode)pluginMode;

@end
