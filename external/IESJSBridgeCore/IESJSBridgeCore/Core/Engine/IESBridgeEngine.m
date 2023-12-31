//
//  IESBridgeEngine.m
//  IESWebKit
//
//  Created by li keliang on 2019/4/8.
//

#import "IESBridgeEngine.h"
#import "IESBridgeMethod.h"
#import <BDJSBridgeAuthManager/IESBridgeAuthManager.h>
#import "IESBridgeMessage+Private.h"
#import "IESJSMethodManager.h"
#import "WKWebView+IESBridgeExecutor.h"
#import "IESJSBridgeCoreABTestManager.h"
#import "IESBridgeMessage.h"
#import "IESBridgeMonitor.h"
#import "IESBridgeDefines.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import <BDMonitorProtocol/BDMonitorProtocol.h>
#import <libkern/OSAtomic.h>
#import <mach-o/getsect.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <objc/runtime.h>

@interface IESBridgeDeallocFlag : NSObject

@property (nonatomic, copy) void(^deallocBlock)(void);

@end

@implementation IESBridgeDeallocFlag

- (void)dealloc
{
    !_deallocBlock ?: _deallocBlock();
}

@end

@interface IESBridgeEngine ()

@property (nonatomic, copy) NSMutableArray<IESBridgeMethod *> *bridgeMethods;

@property (nonatomic, strong) NSMutableDictionary *invokeMethodCallbacks;
@property (nonatomic, strong) NSMutableDictionary *methodNameMap;

@property (nonatomic, assign) NSInteger uniqueID;

@property (nonatomic, strong) NSMutableDictionary<NSString *, IESPiperProtocolVersion> *protocolVersions;

@property (nonatomic, assign) NSInteger bridgeObjectsDeleted;

@property(nonatomic, strong, class, readonly) NSHashTable *interceptors;

@end

@implementation IESBridgeEngine

static NSHashTable * _interceptors;

- (instancetype)initWithExecutor:(id<IESBridgeExecutor>)executor
{
    self = [super init];
    if (self) {
        _bridgeMethods = [[NSMutableArray alloc] init];
        _invokeMethodCallbacks = [NSMutableDictionary dictionary];
        _methodNameMap = [NSMutableDictionary dictionary];
        _protocolVersions = [NSMutableDictionary dictionary];
        _executor = executor;
    }
    return self;
}

- (void)addBridgeMethod:(IESBridgeMethod *)method
{
    if ([self.bridgeMethods containsObject:method]) {
        NSCAssert(NO, @"IESBridgeMethod %@ has been added already.", method);
        return;
    }
    
    [self.bridgeMethods enumerateObjectsUsingBlock:^(IESBridgeMethod * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([method.methodName isEqualToString:obj.methodName] && [method.methodNamespace isEqualToString:obj.methodNamespace]) {
            @synchronized (self) {
                NSLog(@"IESBridgeMethod %@ will be replaced with new handler %@.", method.methodName, method.handler);
                [self.bridgeMethods removeObject:obj];
            }
        }
    }];
    
    @synchronized (self) {
        [self.bridgeMethods addObject:method];
    }
}

- (void)registerHandler:(IESJSCallHandler)handler forJSMethod:(NSString *)method authType:(IESPiperAuthType)authType
{
    NSString *methodNamespace = IESPiperDefaultNamespace;
    [self registerHandler:handler forJSMethod:method authType:authType methodNamespace:methodNamespace];
}

- (void)registerHandler:(IESJSCallHandler)handler forJSMethod:(NSString *)method authType:(IESPiperAuthType)authType methodNamespace:(NSString *)methodNameSpace
{
    __weak __typeof(self) weakSelf = self;
    IESBridgeMethod *bridgeMethod = [[IESBridgeMethod alloc] initWithMethodName:method methodNamespace:methodNameSpace authType:authType handler:^(IESBridgeMessage *message, IESBridgeResponseBlock responseBlock) {
        BOOL executeCallback = YES;
        NSDictionary *result = handler(message.callbackID, message.params, message.JSSDKVersion, &executeCallback);
        if (executeCallback && message.callbackID.length > 0) {
            !responseBlock ?: responseBlock([result[@"code"] integerValue], result);
        } else {
            if (message.callbackID.length > 0) {
                weakSelf.methodNameMap[message.callbackID] = method;
            }

            // 稍后业务方自己调用 invokeJSWithCallbackID
            !responseBlock ?: responseBlock(IESPiperStatusCodeManualCallback, nil);
        }
    }];
    [self addBridgeMethod:bridgeMethod];
    [[IESBridgeAuthManager sharedManagerWithNamesapce:methodNameSpace] registerMethod:method withAuthType:authType];
}

- (void)invokeJSWithCallbackID:(NSString *)callbackID statusCode:(IESPiperStatusCode)statusCode params:(nullable NSDictionary *)params
{
    if (!callbackID) {
        return;
    }
    
    IESBridgeMessage *message = [[IESBridgeMessage alloc] init];
    message.messageType = IESJSMessageTypeCallback;
    message.methodName = self.methodNameMap[callbackID];
    message.callbackID = callbackID;
    message.params = params;
    message.statusCode = statusCode;
    message.protocolVersion = self.protocolVersions[callbackID] ?: IESPiperProtocolVersionUnknown;
    self.protocolVersions[callbackID] = nil;
    self.methodNameMap[callbackID] = nil;

    [self _callbackWithBridgeMessage:message resultBlock:nil statusCode:statusCode];
}

- (void)invokeCallbackWithMessage:(IESBridgeMessage *)message statusCode:(IESPiperStatusCode)statusCode resultBlock:(nullable IESJSCallbackHandler)resultBlock
{
    IESBridgeMessage *callbackMessage = [[IESBridgeMessage alloc] init];
    callbackMessage.messageType = IESJSMessageTypeCallback;
    callbackMessage.callbackID = message.callbackID;
    callbackMessage.protocolVersion = message.protocolVersion;
    callbackMessage.params = message.params;
    callbackMessage.invokeParams = message.invokeParams;
    callbackMessage.statusCode = statusCode;
    callbackMessage.methodName = message.methodName;
    [self _callbackWithBridgeMessage:callbackMessage resultBlock:resultBlock statusCode:statusCode];
}

- (void)fireEvent:(NSString *)eventID withParams:(NSDictionary *)params  status:(IESPiperStatusCode)status callback:(IESJSCallbackHandler)callback {
    IESBridgeMessage *message = [[IESBridgeMessage alloc] init];
    message.messageType = IESJSMessageTypeEvent;
    message.eventID = eventID;
    message.params = params;
    message.statusCode = status;
    
    [self _willFireEventWithMessage:message];
    [self _invokeJSHandleMessageFromAppMethodWithMessage:message callback:callback];
}


- (void)fireEvent:(NSString *)eventID withParams:(NSDictionary *)params callback:(IESJSCallbackHandler)callback
{
    [self fireEvent:eventID withParams:params status:IESPiperStatusCodeSucceed callback:callback];
}

- (void)fireEvent:(NSString *)eventID withParams:(NSDictionary *)params
{
    [self fireEvent:eventID withParams:params callback:nil];
}

- (void)handleBridgeMessage:(IESBridgeMessage *)message
{
    [self _willHandleBridgeMessage:message];
    if ([message.messageType isEqualToString:IESJSMessageTypeCall]) {
        BOOL shouldHandle = YES;
        if ([self.interceptor respondsToSelector:@selector(bridgeEngine:shouldHandleBridgeMessage:)]) {
            shouldHandle = [self.interceptor bridgeEngine:self shouldHandleBridgeMessage:message];
        }
        if (shouldHandle) {
            message.beginTime = [IESBridgeMessage generateCurrentTimeString];
            
            if (message.methodNamespace.length == 0) {
                message.methodNamespace = [self.executor respondsToSelector:@selector(ies_namespace)] ? [self.executor ies_namespace] : IESPiperDefaultNamespace;
            }
            
            if (message.callbackID) {
                self.protocolVersions[message.callbackID] = message.protocolVersion ?: IESPiperProtocolVersionUnknown;
            }
            if (message.callback && message.callbackID) {
                self.invokeMethodCallbacks[message.callbackID] = message.callback;
            }
            [self executeMethodWithMessage:message];
        }
    }
}

- (void)flushBridgeMessages
{
    IESJSMethodManager *jsMethodManager = [IESJSMethodManager managerWithBridgeExecutor:self.executor];
    NSDictionary<IESPiperProtocolVersion, IESJSMethod *> *methodsDic = [jsMethodManager allJSMethodsForKey:IESJSMethodKeyFetchQueue];
    IESJSMethod *method = methodsDic[IESPiperProtocolVersion1_0];
    IESPiperStatusCode statusCode = IESPiperStatusCodeSucceed;
    
    NSMutableDictionary *information = [NSMutableDictionary dictionaryWithCapacity:4];
    information[@"webpage_url"] = self.executor.ies_url.absoluteString ?: @"";
    information[@"version"] = IESPiperProtocolVersion1_0;
    information[@"status_code"] = @(statusCode);
    information[@"description"] = [IESBridgeMessage statusDescriptionWithStatusCode:statusCode];
    [self _willFetchQueueWithInfo:information];
    if (method) {
        NSString *js = [NSString stringWithFormat:@"%@()", method.fullName];
        [self.executor ies_executeJavaScript:js completion:^(id result, NSError *error) {
            NSString *resultString = [result description];
            NSArray *messagesData = [resultString btd_jsonArray];
            if (![messagesData isKindOfClass:NSArray.class]) {
                return;
            }
            for (NSDictionary *data in messagesData) {
                IESBridgeMessage *message = [[IESBridgeMessage alloc] init];
                message.methodName = data[@"func"];
                message.messageType = data[@"__msg_type"];
                message.callbackID = data[@"__callback_id"];
                message.JSSDKVersion = data[@"JSSDK"];
                message.methodNamespace = data[@"namespace"];
                message.from = IESBridgeMessageFromIframe;
                message.protocolVersion = IESPiperProtocolVersion1_0;
                id params = data[@"params"];
                if (params && ![params isKindOfClass:NSDictionary.class]) {
                    NSAssert(NO, @"The params field got from fetchQueue() should be nil or of type NSDictionary.");
                } else {
                    message.params = params;
                    message.invokeParams = params;
                }
                [self handleBridgeMessage:message];
            }
        }];
    } else {
        statusCode = IESPiperStatusCodeUndefined;
    }
    information[@"status_code"] = @(statusCode);
    information[@"description"] = [IESBridgeMessage statusDescriptionWithStatusCode:statusCode];
    [self _didFetchQueueWithInfo:information];

    NSString *serviceName = [@"anNicmlkZ2VfZmV0Y2hfcXVldWU=" btd_base64DecodedString];
    [self trackService:serviceName statusCode:statusCode category:nil version:IESPiperProtocolVersion1_0];
}

- (void)deleteAllPipers
{
    IESJSMethodManager *jsMethodManager = [IESJSMethodManager managerWithBridgeExecutor:self.executor];
    [jsMethodManager deleteAllPipers];
    self.bridgeObjectsDeleted = YES;
}

#pragma mark - Private Methods

- (void)executeMethodWithMessage:(IESBridgeMessage *)message
{
    NSParameterAssert(self.executor);

    if (![message.messageType isEqualToString:IESJSMessageTypeCall]) {
        NSAssert(NO, @"Execute methods with message %@ type error", message.methodName);
        return;
    }
        
    IESPiperStatusCode statusCode = IESPiperStatusCodeSucceed;
    __block IESBridgeMethod *method = nil;
    __block BOOL hasMethodRegardlessOfNamespace = NO;
    [self.bridgeMethods enumerateObjectsUsingBlock:^(IESBridgeMethod *obj, NSUInteger idx, BOOL *stop) {
        BOOL matchNamespace = message.methodNamespace.length > 0 && [obj.methodNamespace isEqualToString:message.methodNamespace];
        if ([obj.methodName isEqualToString:message.methodName]) {
            hasMethodRegardlessOfNamespace = YES;
        }
        if ([obj.methodName isEqualToString:message.methodName] && matchNamespace) {
            method = obj;
            *stop = YES;
        }
    }];
    if (method) {
        IESBridgeAuthManager *authManager = [IESBridgeAuthManager sharedManagerWithNamesapce:message.methodNamespace];
        BOOL authorized = [authManager isAuthorizedMethod:method.methodName forURL:self.executor.ies_commitURL];
        [IESBridgeMonitor monitorJSBInvokeEventWithBridgeMessage:message bridgeMethod:method url:self.executor.ies_url isAuthorized:authorized];
        if (!authorized) {
            statusCode = IESPiperStatusCodeNotAuthroized;
            [self invokeCallbackWithMessage:message statusCode:statusCode resultBlock:nil];
            if ([self.delegate respondsToSelector:@selector(bridgeEngine:didReceiveUnauthorizedMethod:)]) {
                [self.delegate bridgeEngine:self didReceiveUnauthorizedMethod:method];
            }
        } else {
            btd_dispatch_async_on_main_queue(^{
                [self executeMethod:method withMessage:message];
            });
        }
    } else if (hasMethodRegardlessOfNamespace) {
        statusCode = IESPiperStatusCodeNamespaceError;
        [self invokeCallbackWithMessage:message statusCode:statusCode resultBlock:nil];
    } else {
        statusCode = IESPiperStatusCodeNoHandler;
        BOOL shouldCallback = YES;
        if ([self.interceptor respondsToSelector:@selector(bridgeEngine:shouldCallbackUnregisteredMessage:)]) {
            shouldCallback =  [self.interceptor bridgeEngine:self shouldCallbackUnregisteredMessage:message];
        }
        if (shouldCallback) {
            [self invokeCallbackWithMessage:message statusCode:statusCode resultBlock:nil];
        }
        if ([self.delegate respondsToSelector:@selector(bridgeEngine:didReceiveUnregisteredMessage:)]) {
            [self.delegate bridgeEngine:self didReceiveUnregisteredMessage:message];
        }
    }
}

- (void)executeMethod:(IESBridgeMethod *)method withMessage:(IESBridgeMessage *)message
{
    IESBridgeDeallocFlag *debugFlag = [IESBridgeDeallocFlag new];
    debugFlag.deallocBlock = ^{
        NSAssert(NO, @"%@.%@ response handler was not called", method, method.methodName);
    };
    
    IESBridgeResponseBlock responseHandler = ^(IESPiperStatusCode status, NSDictionary *response) {
        if (!debugFlag.deallocBlock) {
            NSAssert(NO, @"%@.%@ response handler was called more than once", method, method.methodName);
        }
        debugFlag.deallocBlock = nil;
        
        if (status == IESPiperStatusCodeManualCallback) {
            return;
        }
        
        IESBridgeMessage *msg = [[IESBridgeMessage alloc] init];
        msg.messageType = IESJSMessageTypeCallback;
        msg.methodName = message.methodName;
        msg.beginTime = message.beginTime;
        msg.callbackID = message.callbackID;
        msg.invokeParams = message.invokeParams;
        msg.params = response;
        msg.statusCode = status;

        if (IESPiperCoreABTestManager.sharedManager.enableIFrameJSB) {
            msg.iframeURLString = message.iframeURLString;
            msg.protocolVersion = message.protocolVersion;
        }

        [self _callbackWithBridgeMessage:msg resultBlock:nil statusCode:status];
    };
    
    !method.handler ?: method.handler(message, responseHandler);
    
    if ([self.delegate respondsToSelector:@selector(bridgeEngine:didExcuteMethod:)]) {
        [self.delegate bridgeEngine:self didExcuteMethod:method];
    }
}

- (void)_callbackWithBridgeMessage:(IESBridgeMessage *)message resultBlock:(IESJSCallbackHandler)resultBlock statusCode:(IESPiperStatusCode)statusCode
{
    message.statusCode = statusCode;
    
    [self _didHandleBridgeMessage:message];
    [self _willCallbackWithMessage:message];
    
    NSString *serviceName = [@"anNicmlkZ2VfaW52b2tlX21ldGhvZA==" btd_base64DecodedString];
    [self trackService:serviceName statusCode:statusCode category:({
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        params[@"method_name"] = message.methodName;
        [params copy];
    }) version:message.protocolVersion];
    
    // Generate callback timestamp.
    message.endTime = [IESBridgeMessage generateCurrentTimeString];
    
    BOOL shouldSendBridgeMessage = YES;
    if (message.callbackID) {
        IESBridgeMessageCallback callback = self.invokeMethodCallbacks[message.callbackID];
        if (callback) {
            shouldSendBridgeMessage = NO;
            callback(message.wrappedParamsString);
        }
    }
    if (shouldSendBridgeMessage) {
        IESJSMethodManager *jsMethodManager = [IESJSMethodManager managerWithBridgeExecutor:self.executor];
        NSDictionary<IESPiperProtocolVersion, IESJSMethod *> *methodsDic = [jsMethodManager allJSMethodsForKey:IESJSMethodKeyHandleMessageFromNative];
        IESPiperCoreInfoLog(@"Piper callback with %@", message.protocolVersion ?: IESPiperProtocolVersionUnknown);
        if ([message.protocolVersion isEqualToString:IESPiperProtocolVersionUnknown]) {
            [self _invokeJSHandleMessageFromAppMethodWithMessage:message callback:resultBlock];
        }
        else {
            IESJSMethod *method = methodsDic[message.protocolVersion];
            NSString *js = nil;
            if (IESPiperCoreABTestManager.sharedManager.shouldEnableIFrameJSB &&    message.iframeURLString.length > 0) {
                // Execute this script only if the web side passes the `__iframe_url` parameter when invoking JSB in an iframe.
                // This script forwards the data via `postMessage` to the iframe, which is identified by the `__iframe_url`.
                js = [NSString stringWithFormat:@stringify(
                    ;(function(){
                        var iframe = document.querySelector('iframe[src="%@"]');
                        iframe && iframe.contentWindow && iframe.contentWindow.postMessage(%@, "%@");
                    })();
                ), message.iframeURLString, message.wrappedParamsString, message.iframeURLString];
            } else {
                js = [NSString stringWithFormat:@";window.%@ && %@ && %@(%@)", method.bridgeName, method.fullName, method.fullName, message.wrappedParamsString];
            }
            [self.executor ies_executeJavaScript:js completion:^(NSString *result, NSError *error) {
                IESPiperStatusCode statusCode = IESPiperStatusCodeSucceed;
                if (error) {
                    statusCode = IESPiperStatusCodeFail;
                }
                else if ([result isKindOfClass:NSString.class]) {
                    NSData *data = [result dataUsingEncoding:NSUTF8StringEncoding];
                    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    NSString *description = dict[@"__err_code"];
                    BOOL is404 = [description isEqualToString:@"cb404"] || [description isEqualToString:@"ev404"];
                    statusCode = is404 ? IESPiperStatusCode404 : IESPiperStatusCodeSucceed;
                }
                else if ([result isKindOfClass:NSNumber.class] && result.boolValue) {
                    statusCode = IESPiperStatusCodeSucceed;
                }
                else {
                    statusCode = IESPiperStatusCodeUnknownError;
                }
                if (!result) {
                    NSString *checkJS = [NSString stringWithFormat:@"!!(window.%@ && %@);", method.bridgeName, method.fullName];
                    [self.executor ies_executeJavaScript:checkJS completion:^(NSNumber *result, NSError *error) {
                        IESPiperStatusCode statusCode = IESPiperStatusCodeUndefined;
                        if ([result isKindOfClass:NSNumber.class] && result.boolValue) {
                            statusCode = IESPiperStatusCodeSucceed;
                        }
                        !resultBlock ?: resultBlock(nil);
                        message.statusCode = statusCode;
                        [self _didCallbackWithMessage:message];
                    }];
                }
                else{
                    !resultBlock ?: resultBlock(statusCode == IESPiperStatusCodeSucceed ? result : nil);
                    message.statusCode = statusCode;
                    [self _didCallbackWithMessage:message];
                }
            }];
        }
    }
}

- (void)_invokeJSHandleMessageFromAppMethodWithMessage:(IESBridgeMessage *)message callback:(IESJSCallbackHandler)callback {
    if (message.callbackID.length == 0 && message.eventID.length == 0 && message.params.allKeys.count != 0) {
        return;
    }
    __auto_type jsFormat = @stringify(
          (function(data) {
              function checkResultFailed(res) {
                  try {
                      res = JSON.parse(res);
                  } catch(e) {
                  }
                  if (res === 'no function') return true;
                  if (typeof res === 'object') {
                      if (res.__err_code === 'cb404') return true;
                      if (res.__err_code === 'ev404') return true;
                  }
                  return false;
              }
              function updateData(data) {
                  if (data.__params.__data) {
                      data.__params.data = data.__params.__data;
                      delete data.__params.__data;
                  }
              }
              var result = JSON.stringify('no function');
              var _tmpData = JSON.parse(JSON.stringify(data));
              if (window.%@ && window.%@._handleMessageFromApp) {
                  updateData(_tmpData);
                  result = window.%@._handleMessageFromApp(_tmpData);
              }
              if (checkResultFailed(result) && window.Native2%@ && window.Native2%@._handleMessageFromApp) {
                  updateData(_tmpData);
                  result = window.Native2%@._handleMessageFromApp(_tmpData);
              }
              if (checkResultFailed(result) && window.Toutiao%@ && window.Toutiao%@._handleMessageFromToutiao) {
                  result = window.Toutiao%@._handleMessageFromToutiao(data);
              }
              return result;
          })(%@)
    );
    NSString *piperString = [@"SlNCcmlkZ2U=" btd_base64DecodedString];  // 'JSBridge'
    __auto_type jsData = message.wrappedParamsString;
    __auto_type jsString = [NSString stringWithFormat:jsFormat, piperString, piperString, piperString, piperString, piperString, piperString, piperString, piperString, piperString, jsData];
    IESPiperCoreInfoLog(@"invokeJSHandleMessageFromAppMethod: %@", jsData);
    [self.executor ies_executeJavaScript:jsString completion:^(NSString *  _Nullable result, NSError * _Nullable error) {
        IESPiperStatusCode statusCode = IESPiperStatusCodeSucceed;
        if (error) {
            IESPiperCoreErrorLog(@"invokeJSHandleMessageFromAppMethod failed: %@", error.localizedDescription);
            statusCode = IESPiperStatusCodeUnknownError;
        }
        else {
            NSDictionary *dict = nil;
            if ([result isKindOfClass:NSString.class]) {
                if ([result containsString:@"no function"]) {
                    statusCode = IESPiperStatusCodeUndefined;
                }
                else {
                    NSData *data = [result dataUsingEncoding:NSUTF8StringEncoding];
                    dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                }
            }
            else if ([result isKindOfClass:NSDictionary.class]) {
                dict = (NSDictionary *)result;
            }
            if (dict) {
                NSString *description = dict[@"__err_code"];
                  BOOL is404 = [description isEqualToString:@"cb404"] || [description isEqualToString:@"ev404"];
                  statusCode = is404 ? IESPiperStatusCode404 : IESPiperStatusCodeSucceed;
            }
        }
        message.statusCode = statusCode;
        if ([message.messageType isEqualToString:IESJSMessageTypeEvent]) {
            [self _didFireEventWithMessage:message];

            NSString *serviceName = [@"anNicmlkZ2VfZmlyZV9ldmVudA==" btd_base64DecodedString];
            [self trackService:serviceName statusCode:statusCode category:({
                NSMutableDictionary *params = [NSMutableDictionary dictionary];
                params[@"event_id"] = message.eventID;
                [params copy];
            }) version:message.protocolVersion];
        } else if ([message.messageType isEqualToString:IESJSMessageTypeCallback]) {
            [self _didCallbackWithMessage:message];

            NSString *serviceName = [@"anNicmlkZ2VfY2FsbGJhY2s=" btd_base64DecodedString];
            [self trackService:serviceName statusCode:statusCode category:({
                NSMutableDictionary *params = [NSMutableDictionary dictionary];
                params[@"method_name"] = message.methodName;
                [params copy];
            }) version:message.protocolVersion];
        }
        !callback ?: callback(result);
    }];
}

#pragma mark - Helpers

- (void)trackService:(NSString *)service statusCode:(IESPiperStatusCode)statusCode category:(NSDictionary *)category version:(IESPiperProtocolVersion)version
{
    if (statusCode == IESPiperStatusCodeSucceed) {
        return;
    }
    NSString *recordVersion = version;
    if ([version isEqualToString:IESPiperProtocolVersion1_0]) {
        recordVersion = @"1.0";
    }
    else if ([version isEqualToString:IESPiperProtocolVersion2_0]) {
        recordVersion = @"2.0";
    }
    else if ([version isEqualToString:IESPiperProtocolVersion3_0]) {
        recordVersion = @"3.0";
    }
    [BDMonitorProtocol hmdTrackService:service
                                metric:@{}
                              category:({
                                  NSMutableDictionary *dict = category ? [category mutableCopy] : [NSMutableDictionary dictionary];
                                  dict[@"status_code"] = @(statusCode);
                                  dict[@"description"] = [IESBridgeMessage statusDescriptionWithStatusCode:statusCode];
                                  dict[@"version"] = version;
                                  // 兼容 TTBridgeUnify 的埋点
                                  dict[@"engine_type"] = @(1 << 1);
                                  [dict copy];
                              })
                                 extra:@{
                                     @"webpage_url" : self.executor.ies_url.absoluteString ?: @""
                                 }];
}

+ (NSHashTable *)interceptors {
    if (!_interceptors) {
        _interceptors = [NSHashTable weakObjectsHashTable];
    }
    return _interceptors;
}

+ (void)addInterceptor:(id<IESBridgeEngineInterceptor>)interceptor {
    @synchronized (self) {
        [IESBridgeEngine.interceptors addObject:interceptor];
    }
}

+ (void)removeInterceptor:(id<IESBridgeEngineInterceptor>)interceptor {
    @synchronized (self) {
        [IESBridgeEngine.interceptors removeObject:interceptor];
    }
}

- (void)_enumerateInterceptorsUsingSelector:(SEL)selector WithBridgeMessage:(IESBridgeMessage *)bridgeMessage{
    if (self.interceptor && [self.interceptor respondsToSelector:selector]) {
        NSObject<IESBridgeEngineInterceptor> *interceptor = self.interceptor;
        [interceptor btd_performSelectorWithArgs:selector, self, bridgeMessage];
    }
    for (NSObject<IESBridgeEngineInterceptor> *interceptor in IESBridgeEngine.interceptors){
        if ([interceptor respondsToSelector:selector]){
            [interceptor btd_performSelectorWithArgs:selector, self, bridgeMessage];
        }
    }
}

- (void)_willHandleBridgeMessage:(IESBridgeMessage *)bridgeMessage{
    [self _enumerateInterceptorsUsingSelector:@selector(bridgeEngine:willHandleBridgeMessage:)
                            WithBridgeMessage:bridgeMessage];
}
- (void)_didHandleBridgeMessage:(IESBridgeMessage *)bridgeMessage{
    [self _enumerateInterceptorsUsingSelector:@selector(bridgeEngine:didHandleBridgeMessage:)
                            WithBridgeMessage:bridgeMessage];
}
- (void)_willCallbackWithMessage:(IESBridgeMessage *)bridgeMessage{
    [self _enumerateInterceptorsUsingSelector:@selector(bridgeEngine:willCallbackWithMessage:)
                            WithBridgeMessage:bridgeMessage];
}
- (void)_didCallbackWithMessage:(IESBridgeMessage *)bridgeMessage{
    [self _enumerateInterceptorsUsingSelector:@selector(bridgeEngine:didCallbackWithMessage:)
                            WithBridgeMessage:bridgeMessage];
}
- (void)_willFireEventWithMessage:(IESBridgeMessage *)bridgeMessage{
    [self _enumerateInterceptorsUsingSelector:@selector(bridgeEngine:willFireEventWithMessage:)
                            WithBridgeMessage:bridgeMessage];
}
- (void)_didFireEventWithMessage:(IESBridgeMessage *)bridgeMessage{
    [self _enumerateInterceptorsUsingSelector:@selector(bridgeEngine:didFireEventWithMessage:)
                            WithBridgeMessage:bridgeMessage];
}

- (void)_willFetchQueueWithInfo:(NSMutableDictionary *)information{
    if (self.interceptor && [self.interceptor respondsToSelector:@selector(bridgeEngine:willFetchQueueWithInfo:)]) {
        [self.interceptor bridgeEngine:self willFetchQueueWithInfo:information];
    }
    for (id<IESBridgeEngineInterceptor> interceptor in IESBridgeEngine.interceptors){
        if ([interceptor respondsToSelector:@selector(bridgeEngine:willFetchQueueWithInfo:)]){
            [interceptor bridgeEngine:self willFetchQueueWithInfo:information];
        }
    }
}
- (void)_didFetchQueueWithInfo:(NSMutableDictionary *)information{
    if (self.interceptor && [self.interceptor respondsToSelector:@selector(bridgeEngine:didFetchQueueWithInfo:)]) {
        [self.interceptor bridgeEngine:self didFetchQueueWithInfo:information];
    }
    for (id<IESBridgeEngineInterceptor> interceptor in IESBridgeEngine.interceptors){
        if ([interceptor respondsToSelector:@selector(bridgeEngine:didFetchQueueWithInfo:)]){
            [interceptor bridgeEngine:self didFetchQueueWithInfo:information];
        }
    }
}
@end
