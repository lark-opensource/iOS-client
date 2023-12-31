//
//  ADFGBridgeRegister.m
//  DoubleConversion
//
//  Created by iCuiCui on 2020/04/24.
//

#import "ADFGBridgeRegister.h"
#import "ADFGBridgeForwarding.h"
#import "ADFGBridgeCommand.h"

void ADFGRegisterBridge(NSString *pluginName,
                      ADFGBridgeName bridgeName) {
    [[ADFGBridgeForwarding sharedInstance] registerPlugin:pluginName forBridge:bridgeName];
    [[ADFGBridgeRegister sharedRegister] registerBridge:^(ADFGBridgeRegisterMaker * _Nonnull maker) {
        maker.bridgeName(bridgeName);
        maker.pluginName(pluginName);
    }];
}

@interface ADFGBridgeMethodInfo()

@property(nonatomic, copy) ADFGBridgeHandler handler;

- (instancetype)initWithBridgeName:(ADFGBridgeName)bridgeName handel:(ADFGBridgeHandler)handler;

@end

@implementation ADFGBridgeMethodInfo

- (instancetype)initWithBridgeName:(ADFGBridgeName)bridgeName handel:(ADFGBridgeHandler)handler {
    if (self = [super init]) {
        self.handler = handler;
    }
    return self;
}

@end

@interface ADFGBridgeRegisterMaker ()

@property(nonatomic, copy) NSString *pluginNameValue;
@property(nonatomic, copy) NSString *bridgeNameValue;
@property(nonatomic, copy) ADFGBridgeHandler handlerValue;

@end

#define ADFGBridgeMakerProperty(TYPE, NAME) - (ADFGBridgeRegisterMaker *(^)(TYPE))NAME {\
return ^ADFGBridgeRegisterMaker *(TYPE NAME) {\
    self.NAME##Value = NAME;\
    return self;\
};\
}\

@implementation ADFGBridgeRegisterMaker

ADFGBridgeMakerProperty(NSString *, pluginName)
ADFGBridgeMakerProperty(NSString *, bridgeName)
ADFGBridgeMakerProperty(ADFGBridgeHandler, handler)

@end

@interface ADFGBridgeRegister ()
{
    NSMutableDictionary<NSString*, ADFGBridgeMethodInfo*> *_methodDic;  //保存所有注册的方法权限信息 method -> authInfo
}

@end

@implementation ADFGBridgeRegister

+ (instancetype)sharedRegister {
    static ADFGBridgeRegister *s = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s = [[ADFGBridgeRegister alloc] init];
    });
    return s;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _methodDic = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)registerBridge:(void (^)(ADFGBridgeRegisterMaker *))block {
    ADFGBridgeRegisterMaker *maker = ADFGBridgeRegisterMaker.new;
    !block ?: block(maker);
    if (maker.handlerValue && maker.pluginNameValue) {
        NSAssert(NO, @"ADFGBridgePlugin 和 ADFGBridgeHandler 只能选一个.");
        return;
    }
    if (maker.pluginNameValue != nil && self != ADFGBridgeRegister.sharedRegister) {
        NSAssert(NO, @"只能使用 ADFGBridgeRegister.sharedRegister 注册 ADFGBridgePlugin.");
        return;
    }
    if (maker.handlerValue) {
        [self _registerBridge:maker.bridgeNameValue handler:maker.handlerValue];
    }
    else {
        [[ADFGBridgeForwarding sharedInstance] registerPlugin:maker.pluginNameValue forBridge:maker.bridgeNameValue];
        [self _registerBridge:maker.bridgeNameValue handler:nil];
    }
}

- (void)_registerBridge:(ADFGBridgeName)bridgeName handler:(ADFGBridgeHandler)handler {
    if (bridgeName.length) {
        if (self != ADFGBridgeRegister.sharedRegister) {
            ADFGBridgeMethodInfo *methodInfo = [[ADFGBridgeMethodInfo alloc] initWithBridgeName:bridgeName handel:handler];
            methodInfo.handler = handler;
            [_methodDic setValue:methodInfo forKey:bridgeName];
        }
        else {
            ADFGBridgeMethodInfo *methodInfo = [_methodDic valueForKey:bridgeName];
            if (methodInfo) {
                NSAssert(NO, @"bridgeName %@ 重复注册.",bridgeName);
            } else {
                methodInfo = [[ADFGBridgeMethodInfo alloc] initWithBridgeName:bridgeName handel:handler];
                methodInfo.handler = handler;
                [_methodDic setValue:methodInfo forKey:bridgeName];
            }
        }
    }
}

- (void)unregisterBridge:(ADFGBridgeName)bridgeName {
    [_methodDic removeObjectForKey:bridgeName];
}

- (ADFGBridgeMethodInfo *)methodInfoForBridge:(ADFGBridgeName)bridgeName {
    ADFGBridgeMethodInfo *methodInfo = [_methodDic valueForKey:bridgeName];
    return methodInfo;
}

- (BOOL)respondsToBridge:(ADFGBridgeName)bridgeName {
    ADFGBridgeMethodInfo *methodInfo = [_methodDic valueForKey:bridgeName];
    return methodInfo != nil;
}

- (void)executeCommand:(ADFGBridgeCommand *)command engine:(id<ADFGBridgeEngine>)engine completion:(ADFGBridgeCallback)completion {
    ADFGBridgeCallback wrappedCompletion = ^(ADFGBridgeMsg msg, NSDictionary *params, void(^resultBlock)(NSString *result)){
        if (completion) {
            adfg_dispatch_async_main_thread_safe(^{
                completion(msg, params, resultBlock);
            });
        }
    };
    if (![engine respondsToBridge:command.bridgeName]) {
        wrappedCompletion(ADFGBridgeMsgNoHandler, nil, nil);
        return;
    }
    ADFGBridgeMethodInfo *methodInfo = [self methodInfoForBridge:command.bridgeName];
    if (methodInfo.handler) {
        methodInfo.handler(command.params, wrappedCompletion, engine, engine.sourceController);
    }
    else {
        [[ADFGBridgeForwarding sharedInstance] forwardWithCommand:command weakEngine:engine completion:wrappedCompletion];
    }
    
}



@end
