 //
//  TTBridgeForwarding.m
//  TTBridgeUnify
//
//  Modified from TTRexxar of muhuai.
//  Created by lizhuopeng on 2018/10/30.
//


#import "TTBridgeForwarding.h"
#import "TTBridgePlugin.h"
#import "TTBridgeAuthorization.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <BDAssert/BDAssert.h>
#import "TTBridgeThreadSafeMutableDictionary.h"

@interface TTBridgeForwarding ()
@property (nonatomic, strong) TTBridgeThreadSafeMutableDictionary<NSString *, NSString *> *aliasDic;
@end
@implementation TTBridgeForwarding

+ (instancetype)sharedInstance {
    static TTBridgeForwarding *forwarding;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        forwarding = [[TTBridgeForwarding alloc] init];
    });
    return forwarding;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _aliasDic = [[TTBridgeThreadSafeMutableDictionary alloc] init];
    }
    return self;
}

- (void)forwardWithCommand:(TTBridgeCommand *)command engine:(id<TTBridgeEngine>)engine completion:(TTBridgeCallback)completion {
    TTBridgeCommand *amendCommand = [self amendAliasWith:command];
    [self forwardPluginWithCommand:amendCommand engine:engine completion:^(TTBridgeMsg msg, NSDictionary *dic, void (^resultBlock)(NSString *result)) {
        if (completion) {
            completion(msg, dic, resultBlock);
        }
    }];
}

- (void)forwardWithCommand:(TTBridgeCommand *)command weakEngine:(id<TTBridgeEngine>)engine completion:(TTBridgeCallback)completion {
    TTBridgeCommand *amendCommand = [self amendAliasWith:command];
    id<TTBridgeEngine> __weak weakEngine = engine;
    [self forwardPluginWithCommand:amendCommand engine:weakEngine completion:^(TTBridgeMsg msg, NSDictionary *dic, void (^resultBlock)(NSString *result)) {
        if (completion) {
            completion(msg, dic, resultBlock);
        }
    }];
}

- (void)invoke:(TTBridgeCommand *)command completion:(TTBridgeCallback)completion engine:(id<TTBridgeEngine>)engine {
    NSString *selectorStr = [command.methodName stringByAppendingString:@"WithParam:callback:engine:controller:"];
    SEL selector = NSSelectorFromString(selectorStr);
    
    TTBridgePlugin *plugin = [self _generatePluginWithCommand:command engine:engine];
    if (![plugin respondsToSelector:selector]) {
        if (completion && command.bridgeType == TTBridgeTypeCall) {
            completion(TTBridgeMsgNoHandler, nil, nil);
        }
        return;
    }
  
    NSDictionary *params = command.params;

    if ([plugin hasExternalHandleForMethod:command.methodName params:params callback:completion]) {
        return;
    }
    NSMethodSignature *signature = [plugin methodSignatureForSelector:selector];
    if (!signature) {
        if (completion) {
            completion(TTBridgeMsgNoHandler, nil, nil);
        }
        return;
    }
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = plugin;
    invocation.selector = selector;
    [invocation setArgument:&params atIndex:2];
    [invocation setArgument:&completion atIndex:3];
    [invocation setArgument:&engine atIndex:4];
    UIViewController *source = engine.sourceController;
    [invocation setArgument:&source atIndex:5];
    [invocation invoke];
}

- (void)forwardPluginWithCommand:(TTBridgeCommand *)command engine:(id<TTBridgeEngine>)engine completion:(TTBridgeCallback)completion {
    if (isEmptyString(command.className) || isEmptyString(command.methodName)) {
        if (completion) {
            completion(TTBridgeMsgNoHandler, nil, nil);
        }
        return;
    }
    [self invoke:command completion:completion engine:engine];
}

- (void)_installAssociatedPluginsOnEngine:(id<TTBridgeEngine>)engine {
    if (!engine) {
        return;
    }
    [self.aliasDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull pluginName, BOOL * _Nonnull stop) {
        NSArray<NSString *> *components = [pluginName componentsSeparatedByString:@"."];
        if (components.count < 2) {
            return;
        }
        NSMutableString *className = [[NSMutableString alloc] init];
        for (int i=0; i<components.count-1; i++) {
            [className appendString:components[i]];
            if (i != components.count-2) {
                [className appendString:@"."];
            }
        }
        Class cls = NSClassFromString(className);
        if (![cls isSubclassOfClass:[TTBridgePlugin class]]) {
            return;
        }
        TTBridgeInstanceType instanceType = [cls instanceType];
        if (instanceType == TTBridgeInstanceTypeAssociated) {
            TTBridgePlugin *plugin = objc_getAssociatedObject(engine, NSSelectorFromString(className));
            if (!plugin) {
                plugin = [[cls alloc] init];
                plugin.engine = engine;
                objc_setAssociatedObject(engine, NSSelectorFromString(className), plugin, OBJC_ASSOCIATION_RETAIN);
            }
        }
    }];
}



- (TTBridgePlugin *)_generatePluginWithCommand:(TTBridgeCommand *)command engine:(id<TTBridgeEngine>)engine {
    Class cls = NSClassFromString(command.className);
    if (![cls isSubclassOfClass:[TTBridgePlugin class]]) {
        return nil;
    }
    
    TTBridgeInstanceType instanceType = [cls instanceType];
    TTBridgePlugin *plugin;
    
    if (instanceType == TTBridgeInstanceTypeNormal) {
        plugin = [[cls alloc] init];
        
    } else if (instanceType == TTBridgeInstanceTypeGlobal) {
        plugin = [cls sharedPlugin];
        
    } else {// Use the associated object to ensure a engine have only one plugin instance of a bridge name.
        if (engine != nil) {
            plugin = objc_getAssociatedObject(engine, NSSelectorFromString(command.className));
            if (!plugin) {
                plugin = [[cls alloc] init];
                objc_setAssociatedObject(engine, NSSelectorFromString(command.className), plugin, OBJC_ASSOCIATION_RETAIN);
            }
        } else {
            plugin = [[cls alloc] init];
        }
    }
    plugin.engine = engine;
    
    return plugin;
}

#pragma mark - alias
- (TTBridgeCommand *)amendAliasWith:(TTBridgeCommand *)command {
    NSString *pluginName = self.aliasDic[command.bridgeName];
    if (isEmptyString(pluginName)) {
        return command;
    }
    command.pluginName = pluginName;
    return command;
}

- (void)registerPlugin:(NSString *)alias forBridge:(NSString *)orig {
     [self.aliasDic setValue:alias forKey:orig];
}

- (void)unregisterPluginForBridge:(TTBridgeName)bridgeName {
    [self.aliasDic removeObjectForKey:bridgeName];
}

- (NSString *)aliasForOrig:(NSString *)orig {
    return self.aliasDic[orig];
}
@end
