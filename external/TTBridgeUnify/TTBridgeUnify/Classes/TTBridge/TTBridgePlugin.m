//
//  TTBridgePlugin.m
//  TTBridgeUnify
//
//  Modified from TTRexxar of muhuai.
//  Created by lizhuopeng on 2018/10/30.
//

#import "TTBridgePlugin.h"
#import <objc/runtime.h>
#import "TTBridgeDefines.h"
#import <BDAssert/BDAssert.h>

static const void *TTBridgeHandlersKey  = &TTBridgeHandlersKey;
static const void *TTBridgeSavedCallbacksKey  = &TTBridgeSavedCallbacksKey;

@interface TTBridgePlugin ()

@end

@implementation TTBridgePlugin

+ (instancetype)sharedPlugin {
    return nil;
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeNormal;
}

+ (TTBridgeAuthType)authType {
    return TTBridgeAuthPublic;
}

+ (void)registerHandlerBlock:(TTBridgePluginHandler)handler forEngine:(id<TTBridgeEngine>)engine selector:(SEL)selector {
    if (!engine) {
        return;
    }
    if (![[self new] respondsToSelector:selector]) {
        BDAssert(NO, @"%@ doesn't implement %@", NSStringFromClass(self), NSStringFromSelector(selector));
        return;
    }
    NSMutableDictionary *allHandlers = objc_getAssociatedObject(engine, TTBridgeHandlersKey);
    if (!allHandlers) {
        allHandlers = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(engine, TTBridgeHandlersKey, allHandlers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    NSMutableDictionary *handlers = allHandlers[NSStringFromClass(self.class)];
    if (!handlers) {
        handlers = [NSMutableDictionary dictionary];
        allHandlers[NSStringFromClass(self.class)] = handlers;
    }
    handlers[NSStringFromSelector(selector)] = handler;
}

+ (TTBridgePluginHandler)handlerWithMethod:(NSString *)method ofEngine:(id<TTBridgeEngine>)engine {
    NSString *selectorStr = [method stringByAppendingString:@"WithParam:callback:engine:controller:"];
    NSMutableDictionary *allHandlers = objc_getAssociatedObject(engine, TTBridgeHandlersKey);
    return allHandlers[NSStringFromClass(self.class)][selectorStr];
}

- (BOOL)hasExternalHandleForMethod:(NSString *)method params:(NSDictionary *)params callback:(TTBridgeCallback)callback {
    TTBridgePluginHandler handler = [self.class handlerWithMethod:method ofEngine:self.engine];
    if (handler) {
        handler(params, callback);
        return YES;
    }
    return NO;
}

@end
