//
//  BDJSBridgeSimpleExecutor.m
//  BDJSBridgeCore
//
//  Created by 李琢鹏 on 2020/1/5.
//

#import "BDJSBridgeSimpleExecutor.h"
#import "BDJSBridgePluginObject.h"
#import <BDWebCore/WKWebView+Plugins.h>
#import <objc/runtime.h>

@interface _BDJSBridgeSimpleInfo : NSObject

@property(nonatomic, assign) BDJSSimpleBridgeCompatibility compatibility;
@property(nonatomic, copy) BDJSBridgeSimpleHandler handler;
@property(nonatomic, copy) NSString *namespace;

@end

@implementation _BDJSBridgeSimpleInfo



@end

@interface BDJSBridgeSimpleExecutor ()

@property(nonatomic, strong) NSMutableDictionary<NSString *, _BDJSBridgeSimpleInfo *> *registeredBridges;

@end

@implementation BDJSBridgeSimpleExecutor

@synthesize sourceWebView;

static NSMutableDictionary<NSString *, _BDJSBridgeSimpleInfo *> *_registereGlobaldBridges;
static id<BDJSBridgeAuthenticator> _authenticator;

- (instancetype)init
{
    self = [super init];
    if (self) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [GAIAEngine startTasksForKey:@BDRegisterSimpleBridgeGaiaKey];
        });
    }
    return self;
}

+ (void)setAuthenticator:(id<BDJSBridgeAuthenticator>)authenticator {
    _authenticator = authenticator;
}

+ (id<BDJSBridgeAuthenticator>)authenticator {
    return  _authenticator;
}

- (void)dealloc {
    if (self.class.authenticator && [self.class.authenticator respondsToSelector:@selector(unregisterBridge:namespace:)]) {
        [self.registeredBridges enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, _BDJSBridgeSimpleInfo * _Nonnull obj, BOOL * _Nonnull stop) {
            [self.class.authenticator unregisterBridge:key namespace:obj.namespace];
        }];
    }
}

- (void)registerBridge:(NSString *)bridgeName compatibility:(BDJSSimpleBridgeCompatibility)compatibility authType:(BDJSBridgeAuthType)authType handler:(BDJSBridgeSimpleHandler)handler {
    [self _registerBridge:bridgeName compatibility:compatibility namespace:BDJSBridgeMessage.defaultNamespace authType:authType handler:handler];
}

- (void)registerBridge:(NSString *)bridgeName namespace:(NSString *)namespace authType:(BDJSBridgeAuthType)authType handler:(BDJSBridgeSimpleHandler)handler  {
    [self _registerBridge:bridgeName compatibility:BDJSSimpleBridgeCompatibilityOverride namespace:namespace authType:authType handler:handler];
}

- (void)_registerBridge:(NSString *)bridgeName compatibility:(BDJSSimpleBridgeCompatibility)compatibility  namespace:(NSString *)namespace authType:(BDJSBridgeAuthType)authType handler:(BDJSBridgeSimpleHandler)handler {
    if (self.class.authenticator && [self.class.authenticator respondsToSelector:@selector(registerBridge:authType:namespace:)]) {
        [self.class.authenticator registerBridge:bridgeName authType:authType namespace:namespace];
    }
    self.registeredBridges[bridgeName] = ({
        _BDJSBridgeSimpleInfo *info = _BDJSBridgeSimpleInfo.new;
        info.compatibility = compatibility;
        info.handler = handler;
        info.namespace = namespace;
        info;
    });
}

+ (void)registerGlobalBridge:(NSString *)bridgeName compatibility:(BDJSSimpleBridgeCompatibility)compatibility authType:(BDJSBridgeAuthType)authType handler:(BDJSBridgeSimpleHandler)handler {
    [self _registerGlobalBridge:bridgeName compatibility:compatibility namespace:BDJSBridgeMessage.defaultNamespace authType:authType handler:handler];
}

+ (void)registerGlobalBridge:(NSString *)bridgeName namespace:(NSString *)namespace authType:(BDJSBridgeAuthType)authType handler:(BDJSBridgeSimpleHandler)handler {
    [self _registerGlobalBridge:bridgeName compatibility:BDJSSimpleBridgeCompatibilityOverride namespace:namespace authType:authType handler:handler];
}

+ (void)_registerGlobalBridge:(NSString *)bridgeName compatibility:(BDJSSimpleBridgeCompatibility)compatibility namespace:(NSString *)namespace authType:(BDJSBridgeAuthType)authType handler:(BDJSBridgeSimpleHandler)handler {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _registereGlobaldBridges = NSMutableDictionary.dictionary;
    });
    if (self.authenticator && [self.authenticator respondsToSelector:@selector(registerBridge:authType:namespace:)]) {
        [self.authenticator registerBridge:bridgeName authType:authType namespace:namespace];
    }
    _registereGlobaldBridges[bridgeName] = ({
        _BDJSBridgeSimpleInfo *info = _BDJSBridgeSimpleInfo.new;
        info.compatibility = compatibility;
        info.handler = handler;
        info.namespace = namespace;
        info;
    });
}

- (BDJSBridgeExecutorPriority)priority {
    return BDJSBridgeExecutorPriorityHigh;
}

- (BDJSBridgeExecutorFlowShouldContinue)invokeBridgeWithMessage:(BDJSBridgeMessage *)message callback:(nonnull BDJSBridgeCallback)callback isForced:(BOOL)isForced{
    __auto_type bridgeInfo = self.registeredBridges[message.bridgeName] ?: _registereGlobaldBridges[message.bridgeName];
    if ((isForced || bridgeInfo.compatibility == BDJSSimpleBridgeCompatibilityOverride)) {
        if(self.class.authenticator && [self.class.authenticator respondsToSelector:@selector(isAuthorizedBridge:inURLString:namespace:)]) {
            if (![self.class.authenticator isAuthorizedBridge:message.bridgeName inURLString:self.sourceWebView.URL.absoluteString namespace:message.namespace]) {
                callback(BDJSBridgeStatusNotAuthroized, nil, nil);
                return NO;
            }
        }
        if (bridgeInfo && ![message.namespace isEqualToString:bridgeInfo.namespace]) {
            callback(BDJSBridgeStatusNamespaceError, nil, nil);
            return NO;
        }
        if (bridgeInfo.handler) {
            bridgeInfo.handler(self.sourceWebView, message.params, callback);
            return NO;
        }
        else {
            return YES;
        }
    }
    return YES;
}

- (BDJSBridgeExecutorFlowShouldContinue)willCallbackBridgeWithMessage:(BDJSBridgeMessage *)message callback:(nonnull BDJSBridgeCallback)callback{
    __auto_type bridgeInfo = self.registeredBridges[message.bridgeName] ?: _registereGlobaldBridges[message.bridgeName];
    if (!bridgeInfo) {
        return YES;
    }
    if (bridgeInfo.compatibility == BDJSSimpleBridgeCompatibilityRequireNoHandler && bridgeInfo.handler) {
        bridgeInfo.handler(self.sourceWebView, message.params, callback);
        return NO;
    }
    return YES;
}

- (NSMutableDictionary<NSString *, _BDJSBridgeSimpleInfo *> *)registeredBridges {
    if (!_registeredBridges) {
        _registeredBridges = NSMutableDictionary.dictionary;
    }
    return _registeredBridges;
}

@end

@interface _BDJSBridgeSimpleExecutorWrapper : NSObject

@property(nonatomic, weak) BDJSBridgeSimpleExecutor *executor;

@end

@implementation _BDJSBridgeSimpleExecutorWrapper



@end

@implementation WKWebView (BDSimpleExecutor)

- (BDJSBridgeSimpleExecutor *)bdw_bridgeSimpleExecutor {
    _BDJSBridgeSimpleExecutorWrapper *wrapper = objc_getAssociatedObject(self, _cmd);
    if (!wrapper) {
        objc_setAssociatedObject(self, _cmd, wrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    __auto_type executor = wrapper.executor;
    if (executor) {
        return executor;
    }
    __block BDJSBridgePluginObject *plugin = nil;
    [self.IWK_plugins enumerateObjectsUsingBlock:^(IWKPluginObject<IWKInstancePlugin> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:BDJSBridgePluginObject.class]) {
            plugin = (BDJSBridgePluginObject *)obj;
            *stop = YES;
        }
    }];
    if (!plugin) {
        wrapper.executor = nil;
        return nil;
    }
    executor = [plugin.executorManager executorForClass:BDJSBridgeSimpleExecutor.class];
    executor.sourceWebView = self;
    wrapper.executor = executor;
    return executor;
}

@end
