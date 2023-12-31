//
//  TTBridgeRegister.m
//  DoubleConversion
//
//  Created by lizhuopeng on 2018/10/24.
//

#import "TTBridgeRegister.h"
#import "TTBridgeForwarding.h"
#import "TTBridgeCommand.h"
#import <BDAssert/BDAssert.h>
#import <BDMonitorProtocol/BDMonitorProtocol.h>
#import "TTBridgeAuthorization.h"
#import "TTBridgeThreadSafeMutableDictionary.h"
#import <BDJSBridgeAuthManager/IESBridgeAuthManager.h>
#import "NSObject+IESAuthManager.h"

void TTRegisterBridge(TTBridgeRegisterEngineType engineType,
                      NSString *pluginName,
                      TTBridgeName bridgeName,
                      TTBridgeAuthType authType,
                      NSArray<NSString *> *domains) {
    [[TTBridgeForwarding sharedInstance] registerPlugin:pluginName forBridge:bridgeName];
    [[TTBridgeRegister sharedRegister] registerMethod:bridgeName
                                           engineType:engineType
                                             authType:authType
                                              domains:domains];
    
}

void TTRegisterWebViewBridge(NSString *pluginName, TTBridgeName bridgeName) {
    TTRegisterBridge(TTBridgeRegisterWebView, pluginName, bridgeName, TTBridgeAuthProtected, nil);
}

void TTRegisterRNBridge(NSString *pluginName, TTBridgeName bridgeName) {
    TTRegisterBridge(TTBridgeRegisterRN, pluginName, bridgeName, TTBridgeAuthProtected, nil);
}

void TTRegisterJSWorkerBridge(NSString *pluginName, TTBridgeName bridgeName) {
    TTRegisterBridge(TTBridgeRegisterJSWorker, pluginName, bridgeName, TTBridgeAuthProtected, nil);
}

void TTRegisterAllBridge(NSString *pluginName, TTBridgeName bridgeName) {
    TTRegisterBridge(TTBridgeRegisterAll, pluginName, bridgeName, TTBridgeAuthProtected, nil);
}

static NSString *kRemoteInnerDomainsKey = @"kRemoteInnerDomainsKey";

@interface TTBridgeMethodInfo()

@property(nonatomic, strong) NSMutableDictionary<NSNumber*, NSNumber*> *authTypeMDic;

@property(nonatomic, copy) TTBridgeHandler handler;

@property(nonatomic, copy) NSDictionary *extraInfo;

- (instancetype)initWithEngineType:(TTBridgeRegisterEngineType)engineType authType:(TTBridgeAuthType)authType bridgeName:(TTBridgeName)bridgeName;
- (void)registerWithEngineType:(TTBridgeRegisterEngineType)engineType authType:(TTBridgeAuthType)authType bridgeName:(TTBridgeName)bridgeName;

@end

@implementation TTBridgeMethodInfo

- (instancetype)initWithEngineType:(TTBridgeRegisterEngineType)engineType authType:(TTBridgeAuthType)authType bridgeName:(TTBridgeName)bridgeName {
    if (self = [super init]) {
        _authTypeMDic = [NSMutableDictionary dictionary];
        [self registerWithEngineType:engineType authType:authType bridgeName:bridgeName];
    }
    return self;
}

- (void)registerWithEngineType:(TTBridgeRegisterEngineType)engineType authType:(TTBridgeAuthType)authType bridgeName:(TTBridgeName)bridgeName{
    void(^registerBlock)(TTBridgeRegisterEngineType) = ^(TTBridgeRegisterEngineType engineType) {
        NSNumber *key = @(engineType);
        if ([self.authTypeMDic objectForKey:key]) {
            BDAssert(NO, @"Bridge: %@ has been registered.", bridgeName);
            return;
        }
        self.authTypeMDic[key] = @(authType);
    };
    if (engineType & TTBridgeRegisterRN) {
        registerBlock(TTBridgeRegisterRN);
    }
    if (engineType & TTBridgeRegisterWebView) {
        registerBlock(TTBridgeRegisterWebView);
    }
    if (engineType & TTBridgeRegisterFlutter) {
        registerBlock(TTBridgeRegisterFlutter);
    }
    if (engineType & TTBridgeRegisterLynx) {
        registerBlock(TTBridgeRegisterLynx);
    }
    if (engineType & TTBridgeRegisterJSWorker) {
        registerBlock(TTBridgeRegisterJSWorker);
    }
}

- (NSDictionary<NSNumber *,NSNumber *> *)authTypes {
    return [_authTypeMDic copy];
}

@end

@interface TTBridgeRegister ()
{
    TTBridgeThreadSafeMutableDictionary<NSString*, TTBridgeMethodInfo*> *_methodDic;  //Auth infos of all bridges. method -> authInfo
    TTBridgeThreadSafeMutableDictionary<NSString*, NSMutableArray*> *_domain2PrivateMethods;   //Private method list. domain -> methods

}

@property(nonatomic, weak) id<TTBridgeInterceptor> interceptor;
@property(nonatomic, strong) NSHashTable *interceptors;
@property(nonatomic, weak) id<TTBridgeDocumentor> documentor;

@end

@interface TTBridgeRegisterMaker ()

@property(nonatomic, assign) TTBridgeAuthType authTypeValue;
@property(nonatomic, copy) NSString *pluginNameValue;
@property(nonatomic, copy) NSString *bridgeNameValue;
@property(nonatomic, assign) TTBridgeRegisterEngineType engineTypeValue;
@property(nonatomic, copy) NSArray<NSString *> *privateDomainsValue;
@property(nonatomic, copy) TTBridgeHandler handlerValue;
@property(nonatomic, copy) NSDictionary *extraInfoValue;

@end

#define TTBridgeMakerProperty(TYPE, NAME) - (TTBridgeRegisterMaker *(^)(TYPE))NAME {\
return ^TTBridgeRegisterMaker *(TYPE NAME) {\
    self.NAME##Value = NAME;\
    return self;\
};\
}\

@implementation TTBridgeRegisterMaker

TTBridgeMakerProperty(TTBridgeAuthType, authType)
TTBridgeMakerProperty(NSString *, pluginName)
TTBridgeMakerProperty(NSString *, bridgeName)
TTBridgeMakerProperty(TTBridgeRegisterEngineType, engineType)
TTBridgeMakerProperty(NSArray<NSString *> *, privateDomains)
TTBridgeMakerProperty(TTBridgeHandler, handler)
TTBridgeMakerProperty(NSDictionary *, extraInfo)

@end

@implementation TTBridgeRegister

+ (instancetype)sharedRegister {
    static TTBridgeRegister *s = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s = [[TTBridgeRegister alloc] init];
    });
    return s;
}

+ (void)_doRegisterIfNeeded {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [GAIAEngine startTasksForKey:@TTRegisterBridgeGaiaKey];
    });
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _methodDic = [[TTBridgeThreadSafeMutableDictionary alloc] init];
        _domain2PrivateMethods = [[TTBridgeThreadSafeMutableDictionary alloc] init];
    }
    return self;
}

- (void)registerMethod:(NSString *)bridgeName
            engineType:(TTBridgeRegisterEngineType)engineType
              authType:(TTBridgeAuthType)authType
               domains:(NSArray<NSString *> *)domains {
    
    [self _registerMethod:bridgeName handler:nil engineType:engineType authType:authType domains:domains extraInfo:nil];
}

- (void)registerMethod:(TTBridgeName)bridgeName handler:(TTBridgeHandler)handler engineType:(TTBridgeRegisterEngineType)engineType authType:(TTBridgeAuthType)authType domains:(NSArray<NSString *> *)domains{
    [self _registerMethod:bridgeName handler:handler engineType:engineType authType:authType domains:domains extraInfo:nil];
}

- (void)_registerMethod:(TTBridgeName)bridgeName handler:(TTBridgeHandler)handler engineType:(TTBridgeRegisterEngineType)engineType authType:(TTBridgeAuthType)authType domains:(NSArray<NSString *> *)domains extraInfo:(NSDictionary *)extraInfo{
    if (bridgeName.length) {
        BDAssert((domains.count > 0 && TTBridgeAuthPrivate == authType)
                 || 0 == domains.count , @"Bridge should be private when domains are not nil.");
        // Local bridge can be registered repeatedly.
        if (self != TTBridgeRegister.sharedRegister) {
            TTBridgeMethodInfo *methodInfo = [[TTBridgeMethodInfo alloc] initWithEngineType:engineType authType:authType bridgeName:bridgeName];
            methodInfo.handler = handler;
            methodInfo.extraInfo = extraInfo;
            [_methodDic setValue:methodInfo forKey:bridgeName];
        }
        else {
            TTBridgeMethodInfo *methodInfo = [_methodDic valueForKey:bridgeName];
            if (methodInfo) {
                [methodInfo registerWithEngineType:engineType authType:authType bridgeName:bridgeName];
            } else {
                methodInfo = [[TTBridgeMethodInfo alloc] initWithEngineType:engineType authType:authType bridgeName:bridgeName];
                methodInfo.handler = handler;
                [_methodDic setValue:methodInfo forKey:bridgeName];
            }
        }
        for (NSString *domain in domains) {
            NSMutableArray *methodsUnderDomain = [_domain2PrivateMethods valueForKey:domain];
            if (!methodsUnderDomain) {
                methodsUnderDomain = [NSMutableArray array];
                [_domain2PrivateMethods setValue:methodsUnderDomain forKey:domain];
            }
            [methodsUnderDomain addObject:bridgeName];
        }
    }
    if ([self.class.documentor respondsToSelector:@selector(documentizeBridge:authType:engineType:desc:)]) {
        [self.class.documentor documentizeBridge:bridgeName authType:authType engineType:engineType desc:nil];
    }
    if (engineType | TTBridgeRegisterWebView) {
        IESPiperAuthType iesAuthType;
        switch (authType) {
            case TTBridgeAuthPublic:
                iesAuthType = IESPiperAuthPublic;
                break;
                
            case TTBridgeAuthPrivate:
                iesAuthType = IESPiperAuthPrivate;
                break;
                
            case TTBridgeAuthProtected:
                iesAuthType = IESPiperAuthProtected;
                break;
            default:
                iesAuthType = IESPiperAuthProtected;
                break;
        }
        
        [ies_getAuthManagerFromEngine(self.engine) registerMethod:bridgeName withAuthType:iesAuthType];
    }
    
    [self.delegate didRegisterMethod:bridgeName handler:handler engineType:engineType authType:authType domains:domains inRegister:self];
}

- (TTBridgeMethodInfo *)methodInfoForBridge:(TTBridgeName)bridgeName {
    TTBridgeMethodInfo *methodInfo = [_methodDic valueForKey:bridgeName];
    return methodInfo;
}

- (NSMutableArray *)privateBridgesOfDomain:(NSString *)domain {
    NSMutableArray *domains = _domain2PrivateMethods[domain];
    return domains;
}

- (BOOL)respondsToBridge:(TTBridgeName)bridgeName {
    TTBridgeMethodInfo *methodInfo = [_methodDic valueForKey:bridgeName];
    return methodInfo != nil;
}

- (BOOL)respondsToBridge:(TTBridgeName)bridgeName engineType:(TTBridgeRegisterEngineType)engineType {
    TTBridgeMethodInfo *methodInfo = [_methodDic valueForKey:bridgeName];
    if (!methodInfo) {
        return NO;
    }
    TTBridgeAuthType authType = [[methodInfo.authTypes objectForKey:@(engineType)] unsignedIntegerValue];
    return authType != TTBridgeAuthNotRegistered;
}

- (void)registerBridge:(void (^)(TTBridgeRegisterMaker *))block {
    TTBridgeRegisterMaker *maker = TTBridgeRegisterMaker.new;
    !block ?: block(maker);
    if (maker.authTypeValue == 0) {
        maker.authTypeValue = TTBridgeAuthProtected;
    }
    if (maker.engineTypeValue == 0) {
        maker.engineTypeValue = TTBridgeRegisterAll;
    }
    if (maker.handlerValue && maker.pluginNameValue) {
        BDAssert(NO, @"You can only use TTBridgePlugin or TTBridgeHandler to register, not both.");
        return;
    }
    if (maker.pluginNameValue != nil && self != TTBridgeRegister.sharedRegister) {
        BDAssert(NO, @"TTBridgePlugin can only be registered by TTBridgeRegister.sharedRegister.");
        return;
    }
    if (maker.handlerValue) {
        [self _registerMethod:maker.bridgeNameValue handler:maker.handlerValue engineType:maker.engineTypeValue authType:maker.authTypeValue domains:maker.privateDomainsValue extraInfo:maker.extraInfoValue];
    }
    else {
        [[TTBridgeForwarding sharedInstance] registerPlugin:maker.pluginNameValue forBridge:maker.bridgeNameValue];
        [self registerMethod:maker.bridgeNameValue engineType:maker.engineTypeValue authType:maker.authTypeValue domains:maker.privateDomainsValue];
    }
}

- (void)unregisterBridge:(TTBridgeName)bridgeName {
    [_methodDic removeObjectForKey:bridgeName];
}

- (void)executeCommand:(TTBridgeCommand *)command engine:(id<TTBridgeEngine>)engine completion:(TTBridgeCallback)completion {
    [self executeCommand:command engine:engine completion:completion preExecuteHander:nil];
}

- (void)executeCommand:(TTBridgeCommand *)command engine:(id<TTBridgeEngine>)engine completion:(TTBridgeCallback)completion preExecuteHander:(TTBridgePreExecuteHandler)handler {

    // Add the extraInfo to the command if the bridgeName have an extraInfo.
    TTBridgeMethodInfo *methodInfo = [self methodInfoForBridge:command.bridgeName];
    if (methodInfo && methodInfo.extraInfo){
        command.extraInfo = methodInfo.extraInfo;
    }
    
    [self.class bridgeEngine:engine willExecuteBridgeCommand:command];
    TTBridgeCallback wrappedCompletion = ^(TTBridgeMsg msg, NSDictionary *params, void(^resultBlock)(NSString *result)){
        if (completion) {
            tt_dispatch_async_main_thread_safe(^{
                completion(msg, params, resultBlock);
            });
        }
    };
    if (![engine respondsToBridge:command.bridgeName]) {
        wrappedCompletion(TTBridgeMsgNoHandler, nil, nil);
        return;
    }
    
    TTBridgeAuthType authType = [[methodInfo.authTypes objectForKey:@([engine engineType])] unsignedIntegerValue];
    if(authType == TTBridgeAuthNotRegistered){
        wrappedCompletion(TTBridgeMsgNoHandler, nil, nil);
        return;
    }
    
    if ([engine respondsToSelector:@selector(authorization)] &&
        [engine.authorization respondsToSelector:@selector(engine:isAuthorizedBridge:URL:)]) {
        BOOL permitted = [engine.authorization engine:engine isAuthorizedBridge:command URL:engine.sourceURL];
        if (!permitted) {
            if (command.bridgeType == TTBridgeTypeCall) {
                wrappedCompletion(TTBridgeMsgNoPermission, nil, nil);
            }
            return;
        }
    }
    
    if (handler) {
        handler(methodInfo);
    }
    
    if (methodInfo.handler) {
        methodInfo.handler(command.params, wrappedCompletion, engine, engine.sourceController);
    }
    else {
        [[TTBridgeForwarding sharedInstance] forwardWithCommand:command weakEngine:engine completion:wrappedCompletion];
    }
    
}

- (NSHashTable *)interceptors {
    if (!_interceptors) {
        _interceptors = [NSHashTable weakObjectsHashTable];
    }
    return _interceptors;
}

+ (void)setDocumentor:(id<TTBridgeDocumentor>)documentor {
    [[self sharedRegister] setDocumentor:documentor];
}

+ (id<TTBridgeDocumentor>)documentor{
    return [self.sharedRegister documentor];
}

+ (void)setInterceptor:(id<TTBridgeInterceptor>)interceptor {
    [[self sharedRegister] setInterceptor:interceptor];
}

+ (id<TTBridgeInterceptor>)interceptor {
    return [[self sharedRegister] interceptor];
}

+ (void)addInterceptor:(id<TTBridgeInterceptor>)interceptor {
    [[[self sharedRegister] interceptors] addObject:interceptor];
}

+ (void)removeInterceptor:(id<TTBridgeInterceptor>)interceptor {
    [[[self sharedRegister] interceptors] removeObject:interceptor];
}
+ (void)bridgeEngine:(id<TTBridgeEngine>)engine willExecuteBridgeCommand:(TTBridgeCommand *)command {
    if (TTBridgeRegister.interceptor && [TTBridgeRegister.interceptor respondsToSelector:@selector(bridgeEngine:willExecuteBridgeCommand:)]) {
        [TTBridgeRegister.interceptor bridgeEngine:engine willExecuteBridgeCommand:command];

    }
    for (id<TTBridgeInterceptor> interceptor in [[self sharedRegister] interceptors]) {
        if ([interceptor respondsToSelector:@selector(bridgeEngine:willExecuteBridgeCommand:)]) {
            [interceptor bridgeEngine:engine willExecuteBridgeCommand:command];
        }
    }
}


+ (BOOL)bridgeEngine:(id<TTBridgeEngine>)engine shouldHandleGlobalBridgeCommand:(TTBridgeCommand *)command {
    BOOL shouldHandleBridge = YES;
    if (TTBridgeRegister.interceptor && [TTBridgeRegister.interceptor respondsToSelector:@selector(bridgeEngine:shouldHandleGlobalBridgeCommand:)]) {
        shouldHandleBridge = [TTBridgeRegister.interceptor bridgeEngine:engine shouldHandleGlobalBridgeCommand:command];
        if (!shouldHandleBridge) {
            return shouldHandleBridge;
        }
    }
    for (id<TTBridgeInterceptor> interceptor in [[self sharedRegister] interceptors]) {
        if ([interceptor respondsToSelector:@selector(bridgeEngine:shouldHandleGlobalBridgeCommand:)]) {
            shouldHandleBridge = [interceptor bridgeEngine:engine shouldHandleGlobalBridgeCommand:command];
        }
        if (!shouldHandleBridge) {
            return shouldHandleBridge;
        }
    }
    
    return shouldHandleBridge;
}

+ (BOOL)bridgeEngine:(id<TTBridgeEngine>)engine shouldHandleLocalBridgeCommand:(TTBridgeCommand *)command {
    BOOL shouldHandleBridge = YES;
    if (TTBridgeRegister.interceptor && [TTBridgeRegister.interceptor respondsToSelector:@selector(bridgeEngine:shouldHandleLocalBridgeCommand:)]) {
        shouldHandleBridge = [TTBridgeRegister.interceptor bridgeEngine:engine shouldHandleLocalBridgeCommand:command];
        if (!shouldHandleBridge) {
            return shouldHandleBridge;
        }
    }
    for (id<TTBridgeInterceptor> interceptor in [[self sharedRegister] interceptors]) {
        if ([interceptor respondsToSelector:@selector(bridgeEngine:shouldHandleLocalBridgeCommand:)]) {
            shouldHandleBridge = [interceptor bridgeEngine:engine shouldHandleLocalBridgeCommand:command];
        }
        if (!shouldHandleBridge) {
            return shouldHandleBridge;
        }
    }
    
    return shouldHandleBridge;
}

+ (BOOL)bridgeEngine:(id<TTBridgeEngine>)engine shouldCallbackUnregisteredCommand:(TTBridgeCommand *)command {
    BOOL shouldCallbackUnregisteredCommand = YES;
    if (TTBridgeRegister.interceptor && [TTBridgeRegister.interceptor respondsToSelector:@selector(bridgeEngine:shouldCallbackUnregisteredCommand:)]) {
        shouldCallbackUnregisteredCommand = [TTBridgeRegister.interceptor bridgeEngine:engine shouldCallbackUnregisteredCommand:command];
    }
    if (!shouldCallbackUnregisteredCommand) {
        return shouldCallbackUnregisteredCommand;
    }
    for (id<TTBridgeInterceptor> interceptor in [[self sharedRegister] interceptors]) {
        if ([interceptor respondsToSelector:@selector(bridgeEngine:shouldCallbackUnregisteredCommand:)]) {
            shouldCallbackUnregisteredCommand = [interceptor bridgeEngine:engine shouldCallbackUnregisteredCommand:command];
        }
        if (!shouldCallbackUnregisteredCommand) {
            return shouldCallbackUnregisteredCommand;
        }
    }
    
    return shouldCallbackUnregisteredCommand;
}

+ (void)bridgeEngine:(id<TTBridgeEngine>)engine willCallbackBridgeCommand:(TTBridgeCommand *)command {
    if (TTBridgeRegister.interceptor && [TTBridgeRegister.interceptor respondsToSelector:@selector(bridgeEngine:willCallbackBridgeCommand:)]) {
        [TTBridgeRegister.interceptor bridgeEngine:engine willCallbackBridgeCommand:command];
    }

    for (id<TTBridgeInterceptor> interceptor in [[self sharedRegister] interceptors]) {
        if ([interceptor respondsToSelector:@selector(bridgeEngine:willCallbackBridgeCommand:)]) {
            [interceptor bridgeEngine:engine willCallbackBridgeCommand:command];
        }
    }
}

#pragma deprecated
- (BOOL)bridgeHasRegistered:(TTBridgeName)bridgeName {
    return [self respondsToBridge:bridgeName];
}

@end
