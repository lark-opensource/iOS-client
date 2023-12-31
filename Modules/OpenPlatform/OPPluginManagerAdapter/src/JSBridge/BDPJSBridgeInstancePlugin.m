//
//  BDPJSBridgeInstancePlugin.m
//  Timor
//
//  Created by 王浩宇 on 2019/8/29.
//

#import "BDPJSBridgeInstancePlugin.h"
#import <objc/runtime.h>
@implementation BDPJSBridgeInstancePlugin

+ (instancetype)sharedPlugin
{
    id instance = objc_getAssociatedObject(self, @"kBDPSharedPlugin");
    if (!instance) {
        instance = [[self alloc] init];
        objc_setAssociatedObject(self, @"kBDPSharedPlugin", instance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return instance;
}

+ (BDPJSBridgePluginMode)pluginMode
{
    return BDPJSBridgePluginModeNewInstance;
}

@end

