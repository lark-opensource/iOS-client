 //
//  ADFGBridgeForwarding.m
//  ADFGBridgeUnify
//
//  Modified from TTRexxar of muhuai.
//  Created by iCuiCui on 2020/04/30.
//


#import "ADFGBridgeForwarding.h"
#import "ADFGBridgePlugin.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface ADFGBridgeForwarding ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *aliasDic;
@end
@implementation ADFGBridgeForwarding

+ (instancetype)sharedInstance {
    static ADFGBridgeForwarding *forwarding;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        forwarding = [[ADFGBridgeForwarding alloc] init];
    });
    return forwarding;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _aliasDic = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)forwardWithCommand:(ADFGBridgeCommand *)command engine:(id<ADFGBridgeEngine>)engine completion:(ADFGBridgeCallback)completion {
    ADFGBridgeCommand *amendCommand = [self amendAliasWith:command];
    [self forwardPluginWithCommand:amendCommand engine:engine completion:^(ADFGBridgeMsg msg, NSDictionary *dic, void (^resultBlock)(NSString *result)) {
        if (completion) {
            completion(msg, dic, resultBlock);
        }
    }];
}

- (void)forwardWithCommand:(ADFGBridgeCommand *)command weakEngine:(id<ADFGBridgeEngine>)engine completion:(ADFGBridgeCallback)completion {
    ADFGBridgeCommand *amendCommand = [self amendAliasWith:command];
    id<ADFGBridgeEngine> __weak weakEngine = engine;
    [self forwardPluginWithCommand:amendCommand engine:weakEngine completion:^(ADFGBridgeMsg msg, NSDictionary *dic, void (^resultBlock)(NSString *result)) {
        if (completion) {
            completion(msg, dic, resultBlock);
        }
    }];
}

- (void)invoke:(ADFGBridgeCommand *)command completion:(ADFGBridgeCallback)completion engine:(id<ADFGBridgeEngine>)engine {
    NSString *selectorStr = [command.methodName stringByAppendingString:@"WithParam:callback:engine:controller:"];
    SEL selector = NSSelectorFromString(selectorStr);
    
    ADFGBridgePlugin *plugin = [self _generatePluginWithCommand:command engine:engine];
    if (![plugin respondsToSelector:selector]) {
        if (completion && command.bridgeType == ADFGBridgeTypeCall) {
            completion(ADFGBridgeMsgNoHandler, nil, nil);
        }
        return;
    }

    NSMethodSignature *signature = [plugin methodSignatureForSelector:selector];
    if (!signature) {
        if (completion) {
            completion(ADFGBridgeMsgNoHandler, nil, nil);
        }
        return;
    }
    NSDictionary *params = command.params;
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

- (void)forwardPluginWithCommand:(ADFGBridgeCommand *)command engine:(id<ADFGBridgeEngine>)engine completion:(ADFGBridgeCallback)completion {
    if (ADFG_isEmptyString(command.className) || ADFG_isEmptyString(command.methodName)) {
        if (completion) {
            completion(ADFGBridgeMsgNoHandler, nil, nil);
        }
        return;
    }
    [self invoke:command completion:completion engine:engine];
}

- (ADFGBridgePlugin *)_generatePluginWithCommand:(ADFGBridgeCommand *)command engine:(id<ADFGBridgeEngine>)engine {
    if (![command.className isEqualToString:NSStringFromClass([ADFGBridgePlugin class])]) {
        return nil;
    }
    
    ADFGBridgePlugin *plugin = [[ADFGBridgePlugin alloc] init];
    plugin.engine = engine;
    
    return plugin;
}

#pragma mark - 别名相关
- (ADFGBridgeCommand *)amendAliasWith:(ADFGBridgeCommand *)command {
    NSString *pluginName = self.aliasDic[command.bridgeName];
    if (ADFG_isEmptyString(pluginName)) {
        return command;
    }
    command.pluginName = pluginName;
    return command;
}

- (void)registerPlugin:(NSString *)alias forBridge:(NSString *)orig {
     [self.aliasDic setValue:alias forKey:orig];
}

- (void)unregisterPluginForBridge:(ADFGBridgeName)bridgeName {
    [self.aliasDic removeObjectForKey:bridgeName];
}

- (NSString *)aliasForOrig:(NSString *)orig {
    return self.aliasDic[orig];
}
@end
