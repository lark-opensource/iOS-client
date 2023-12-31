//
//  TTBridgeDefines.h
//  TTBridgeUnify
//
//  Modified from TTRexxar of muhuai.
//  Created by lizhuopeng on 2018/10/30.
//

#import <Foundation/Foundation.h>
#import <Gaia/Gaia.h>

NS_ASSUME_NONNULL_BEGIN

#define TTRegisterBridgeGaiaKey "TTRegisterBridgeKey"
#define TTRegisterBridgeFunction GAIA_FUNCTION(TTRegisterBridgeGaiaKey)
#define TTRegisterBridgeMethod GAIA_METHOD(TTRegisterBridgeGaiaKey);

typedef NS_OPTIONS(NSInteger, TTBridgeRegisterEngineType) {
    TTBridgeRegisterRN = 1 << 0,
    TTBridgeRegisterWebView = 1 << 1,
    TTBridgeRegisterFlutter = 1 << 2,
    TTBridgeRegisterLynx = 1 << 3,
    TTBridgeRegisterJSWorker = 1 << 4,
    TTBridgeRegisterAll = TTBridgeRegisterRN | TTBridgeRegisterWebView | TTBridgeRegisterFlutter | TTBridgeRegisterLynx | TTBridgeRegisterJSWorker
};

#define TT_BRIDGE_EXPORT_HANDLER(NAME) - (void)NAME##WithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller;

/**
 This Macro can be used to ensure the existence of the native method when register a JSB.
 
 Examples：
 TTRegisterAllBridge(TTClassBridgeMethod(TTAppBridge, appInfo), @"app.getAppInfo");
 is equal to
 TTRegisterAllBridge(@"TTAppBridge.appInfo", @"app.getAppInfo");
 
 When the method doesn't exist, the compiler will throw an error!
 */
#define TTClassBridgeMethod(CLASS, METHOD) \
((void)(NO && ((void)[((CLASS *)(nil)) METHOD##WithParam:nil callback:nil engine:nil controller:nil], NO)), [NSString stringWithFormat:@"%@.%@", @(#CLASS), @(#METHOD)])


#define TTBRIDGE_CALLBACK_SUCCESS \
if (callback) {\
callback(TTBridgeMsgSuccess, @{}, nil);\
}\

#define TTBRIDGE_CALLBACK_FAILED \
if (callback) {\
callback(TTBridgeMsgFailed, @{}, nil);\
}\

#define TTBRIDGE_CALLBACK_FAILED_MSG(msg) \
if (callback) {\
callback(TTBridgeMsgFailed, @{@"msg": [NSString stringWithFormat:msg]? :@""}, nil);\
}\

#define TTBRIDGE_CALLBACK_WITH_MSG(status, msg) \
if (callback) {\
callback(status, @{@"msg": [NSString stringWithFormat:msg]? [NSString stringWithFormat:msg] :@""}, nil);\
}\

#define TTBRIDGE_CALLBACK_FAILED_MSG_FORMAT(format, ...) \
    if (callback) {\
        callback(TTBridgeMsgFailed, @{@"msg": [NSString stringWithFormat:format, ##__VA_ARGS__] ?: @""}, nil);\
    }\

#define TTBRIDGE_CALLBACK_WITH_MSG_FORMAT(status, format, ...) \
    if (callback) {\
        callback(status, @{@"msg": [NSString stringWithFormat:format, ##__VA_ARGS__] ?: @""}, nil);\
    }\

#ifndef isEmptyString
#define isEmptyString(str) (!str || ![str isKindOfClass:[NSString class]] || str.length == 0)
#endif

#ifndef tt_dispatch_async_safe
#define tt_dispatch_async_safe(queue, block)\
if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) {\
    block();\
} else {\
    dispatch_async(queue, block);\
}
#endif

#ifndef tt_dispatch_async_main_thread_safe
#define tt_dispatch_async_main_thread_safe(block) tt_dispatch_async_safe(dispatch_get_main_queue(), block)
#endif

#ifndef stringify
#define stringify(s) #s
#endif

typedef NS_ENUM(NSUInteger, TTBridgeInstanceType) {
    TTBridgeInstanceTypeNormal, //Different plugin Instance in different Piper call. (This type is default and recommended.)
    TTBridgeInstanceTypeGlobal, //A global singleton plugin, +(instance)sharedPlugin must be implemented.
    TTBridgeInstanceTypeAssociated, //A singleton plugin for the source object, the plugin is initialized in the initiation of the engine.
};

typedef NS_ENUM(NSUInteger, TTBridgeAuthType){
    TTBridgeAuthNotRegistered = 0, 
    TTBridgeAuthPublic = 1, // The bridge can be called by all domains.
    TTBridgeAuthProtected, // The bridge can be called by inner domains and domains from Allowlist.
    TTBridgeAuthPrivate, // The bridge can only be called by inner domains.
    TTBridgeAuthSecure // The bridge can only be called by adding domains into 'included' group on Gecko.
};

typedef NS_ENUM(NSInteger, TTBridgeMsg){
    TTBridgeMsgUnknownError   = -1000,
    TTBridgeMsgManualCallback = -999,
    TTBridgeMsgCodeUndefined      = -998,
    TTBridgeMsgCode404            = -997,
    TTBridgeMsgSuccess = 1,
    TTBridgeMsgFailed = 0,
    TTBridgeMsgParamError = -3,
    TTBridgeMsgNoHandler = -2,
    TTBridgeMsgNoPermission = -1
};

typedef void(^TTBridgeCallback)(TTBridgeMsg msg, NSDictionary * _Nullable params, void(^ _Nullable resultBlock)(NSString *result));

typedef NSString * TTBridgeName;

typedef void(^TTBridgePluginHandler)(NSDictionary * _Nullable params, TTBridgeCallback callback);
NS_ASSUME_NONNULL_END
