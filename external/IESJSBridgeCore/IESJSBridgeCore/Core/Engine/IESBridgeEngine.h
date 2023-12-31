//
//  IESBridgeEngine.h
//  IESWebKit
//
//  Created by li keliang on 2019/4/8.
//

#import <WebKit/WebKit.h>
#import <IESJSBridgeCore/IESBridgeMethod.h>
#import <BDJSBridgeAuthManager/IESBridgeAuthManager.h>
#import <IESJSBridgeCore/IESBridgeDefines.h>

NS_ASSUME_NONNULL_BEGIN

#define IES_EXPORT_BRIDGE_METHOD(js_name_, auth_type_, method_) _IES_EXPORT_BRIDGE_METHOD(js_name_, auth_type_, method_, __COUNTER__)

@class IESBridgeMethod, IESBridgeMessage, IESJSMethod, IESBridgeEngine;
@protocol IESBridgeEngineDelegate, IESBridgeEngineInterceptor, IESBridgeExecutor;

typedef void (^IESBridgeExecutorCompletion)(id _Nullable result, NSError * _Nullable error);

typedef void (^IESJSCallbackHandler)(id _Nullable result);

typedef NSDictionary * _Nullable (^IESJSCallHandler)(NSString * _Nullable callbackId, NSDictionary * _Nullable result, NSString * _Nullable JSSDKVersion, BOOL * _Nullable executeCallback);

#pragma mark - IESBridgeEngine

@interface IESBridgeEngine : NSObject

@property (nonatomic, weak) id<IESBridgeEngineDelegate> delegate;
@property (nonatomic, weak) id<IESBridgeEngineInterceptor> interceptor;
@property (nonatomic, weak, readonly) id<IESBridgeExecutor> executor;
@property (nonatomic, copy, readonly) NSArray<IESBridgeMethod *> *methods;

- (instancetype)initWithExecutor:(id<IESBridgeExecutor>)executor;

- (void)registerHandler:(IESJSCallHandler)handler forJSMethod:(NSString *)method authType:(IESPiperAuthType)authType;
- (void)registerHandler:(IESJSCallHandler)handler forJSMethod:(NSString *)method authType:(IESPiperAuthType)authType methodNamespace:(NSString *)methodNameSpace;
- (void)invokeJSWithCallbackID:(NSString *)callbackID statusCode:(IESPiperStatusCode)statusCode params:(nullable NSDictionary *)params;
- (void)invokeCallbackWithMessage:(IESBridgeMessage *)message statusCode:(IESPiperStatusCode)statusCode resultBlock:(nullable IESJSCallbackHandler)resultBlock;
- (void)fireEvent:(NSString *)eventID withParams:(NSDictionary *)params  status:(IESPiperStatusCode)status callback:(IESJSCallbackHandler)callback;
- (void)fireEvent:(NSString *)eventID withParams:(nullable NSDictionary *)params callback:(nullable IESJSCallbackHandler)callback;
- (void)fireEvent:(NSString *)eventID withParams:(nullable NSDictionary *)params;

- (void)handleBridgeMessage:(IESBridgeMessage *)message;
- (void)flushBridgeMessages;
- (void)deleteAllPipers;

// 如果需要添加多个 interceptor, 请使用 addInterceptor 方法
+ (void)addInterceptor:(id<IESBridgeEngineInterceptor>)interceptor;
+ (void)removeInterceptor:(id<IESBridgeEngineInterceptor>)interceptor;
@end


#pragma mark - IESBridgeEngineDelegate

@protocol IESBridgeEngineDelegate <NSObject>

@optional
- (void)bridgeEngine:(IESBridgeEngine *)engine didExcuteMethod:(IESBridgeMethod *)method;
- (void)bridgeEngine:(IESBridgeEngine *)engine didReceiveUnauthorizedMethod:(IESBridgeMethod *)method;
- (void)bridgeEngine:(IESBridgeEngine *)engine didReceiveUnregisteredMessage:(IESBridgeMessage *)bridgeMessage;

@end


#pragma mark - IESBridgeEngineInterceptor

@protocol IESBridgeEngineInterceptor <NSObject>

@optional
- (BOOL)bridgeEngine:(IESBridgeEngine *)engine shouldHandleBridgeMessage:(IESBridgeMessage *)bridgeMessage;
- (BOOL)bridgeEngine:(IESBridgeEngine *)engine shouldCallbackUnregisteredMessage:(IESBridgeMessage *)bridgeMessage;

- (void)bridgeEngine:(IESBridgeEngine *)engine willHandleBridgeMessage:(IESBridgeMessage *)bridgeMessage;
- (void)bridgeEngine:(IESBridgeEngine *)engine didHandleBridgeMessage:(IESBridgeMessage *)bridgeMessage;

- (void)bridgeEngine:(IESBridgeEngine *)engine willCallbackWithMessage:(IESBridgeMessage *)bridgeMessage;
- (void)bridgeEngine:(IESBridgeEngine *)engine didCallbackWithMessage:(IESBridgeMessage *)bridgeMessage;

- (void)bridgeEngine:(IESBridgeEngine *)engine willFireEventWithMessage:(IESBridgeMessage *)bridgeMessage;
- (void)bridgeEngine:(IESBridgeEngine *)engine didFireEventWithMessage:(IESBridgeMessage *)bridgeMessage;

- (void)bridgeEngine:(IESBridgeEngine *)engine willFetchQueueWithInfo:(NSMutableDictionary *)information;
- (void)bridgeEngine:(IESBridgeEngine *)engine didFetchQueueWithInfo:(NSMutableDictionary *)information;

@end


#pragma mark - IESBridgeExecutor

@protocol IESBridgeExecutor <NSObject>

@required
- (IESBridgeEngine *)ies_bridgeEngine;
- (nullable NSURL *)ies_url;
- (NSURL*)ies_commitURL;
- (void)set_iesCommitURL:(NSURL*)url;
- (void)ies_executeJavaScript:(NSString *)javaScriptString completion:(nullable IESBridgeExecutorCompletion)completion;

@optional
- (NSString *)ies_namespace;

@end


NS_ASSUME_NONNULL_END
