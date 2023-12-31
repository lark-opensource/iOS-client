//
//  TTDynamicBridgePlugin.m
//  TTBridgeUnify
//
//  Created by 李琢鹏 on 2019/3/3.
//

#import "TTDynamicBridgePlugin.h"
#import <TTBridgeRegister.h>
#import <objc/runtime.h>

@implementation TTDynamicBridgePlugin

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    NSString *selString = NSStringFromSelector(aSelector);
    NSString *regex = @"^\\w+WithParam:callback:engine:controller:$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [predicate evaluateWithObject:selString] || [super respondsToSelector:aSelector];
}

+ (void)registerHandlerBlock:(TTBridgePluginHandler)handler forEngine:(id<TTBridgeEngine>)engine bridgeName:(TTBridgeName)bridgeName engineType:(TTBridgeRegisterEngineType)engineType authType:(TTBridgeAuthType)authType{
    TTBridgeName name = [bridgeName stringByReplacingOccurrencesOfString:@"." withString:@""];
    if (![[TTBridgeRegister sharedRegister] respondsToBridge:bridgeName]) {
        TTRegisterBridge(engineType, [NSString stringWithFormat:@"%@.%@", NSStringFromClass(self.class), name], bridgeName, authType, nil);
    }
    [self registerHandlerBlock:handler forEngine:engine selector:NSSelectorFromString([name stringByAppendingString:@"WithParam:callback:engine:controller:"])];
}

+ (void)registerHandlerBlock:(TTBridgePluginHandler)handler forEngine:(id<TTBridgeEngine>)engine bridgeName:(TTBridgeName)bridgeName {
    [self registerHandlerBlock:handler forEngine:engine bridgeName:bridgeName engineType:TTBridgeRegisterAll authType:TTBridgeAuthProtected];
}

@end
