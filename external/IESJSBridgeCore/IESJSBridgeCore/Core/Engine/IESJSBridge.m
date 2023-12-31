//
//  IESJSBridge.m
//
//  Created by willorfang on 2017/8/25.
//
//

#import "IESJSBridge.h"
#import "IESBridgeMessage+Private.h"
#import <BDJSBridgeAuthManager/IESBridgeAuthManager.h>
#import "IESBridgeEngine+Private.h"
#import "IESBridgeMethod.h"
#import "IESJSMethodManager.h"
#import "IESBridgeEngine.h"
#import "IESJSBridgeCoreABTestManager.h"
#import "WKWebView+IESBridgeExecutor.h"
#import <BDJSBridgeAuthManager/IESBridgeAuthModel.h>
#import <ByteDanceKit/ByteDanceKit.h>

// TODO: Deprecated
#import "IESBridgeEngine_Deprecated.h"
#import "IESBridgeEngine_Deprecated+Private.h"
#import "IESFastBridge_Deprecated.h"


@interface IESPiper ()

@property (nonatomic, strong, readonly) IESBridgeEngine *bridgeEngine;

// TODO: Deprecated
@property (nonatomic, strong) IESBridgeEngine_Deprecated *deprecatedBridgeEngine;
@property (nonatomic, strong) NSMutableDictionary *callbackHandlers;
@property (nonatomic, strong, readwrite) NSMutableSet *publicCallSet;
@property (nonatomic, strong, readwrite) NSMutableSet *protectedSet;
@property (nonatomic, strong, readwrite) NSMutableSet *privateSet;
@property (nonatomic, assign) int uniqueID;

@end

@implementation IESPiper

- (instancetype)initWithWebView:(UIView<IESBridgeExecutor> *)webView
{
    self = [super init];
    if (self) {
        _webView = webView;

        // TODO: Deprecated
        if (!IESPiperCoreABTestManager.sharedManager.shouldUseBridgeEngineV2) {
            _callbackHandlers = [NSMutableDictionary dictionary];
            _publicCallSet = [NSMutableSet set];
            _protectedSet = [NSMutableSet set];
            _privateSet = [NSMutableSet set];
            _deprecatedBridgeEngine = [[IESBridgeEngine_Deprecated alloc] init];
            
            if ([webView isKindOfClass:WKWebView.class]) {
                [IESFastBridge_Deprecated injectionBridge:_deprecatedBridgeEngine intoWKWebView:(WKWebView *)webView];
            }
        }
        
        // Invoke -registerConfigMethod if it exists.
        SEL selector = NSSelectorFromString(@"registerConfigMethod");
        if ([self respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self performSelector:selector];
#pragma clang diagnostic pop
        }
    }
    return self;
}

- (IESBridgeEngine *)bridgeEngine
{
    return self.webView.ies_bridgeEngine;
}

#pragma mark - Registration

- (void)registerHandlerBlock:(IESJSCallHandler)handler forJSMethod:(NSString *)method authType:(IESPiperAuthType)authType
{
    NSString *methodNamespace = IESPiperDefaultNamespace;
    [self registerHandlerBlock:handler forJSMethod:method authType:authType methodNamespace:methodNamespace];
}

- (void)registerHandlerBlock:(IESJSCallHandler)handler forJSMethod:(NSString *)method authType:(IESPiperAuthType)authType methodNamespace:(NSString *)methodNamespace
{
    // Register handlers in new bridge engine
    [self.bridgeEngine registerHandler:handler forJSMethod:method authType:authType methodNamespace:methodNamespace];
    
    // Register handlers in old bridge engine
    switch (authType) {
        case IESPiperAuthPublic: {
            [_publicCallSet addObject:method];
        }
            break;
        case IESPiperAuthPrivate: {
            [_privateSet addObject:method];
        }
            break;
        case IESPiperAuthProtected: {
            [_protectedSet addObject:method];
        }
            break;
    }
    IESBridgeMethod * bridgeMethod = [[IESBridgeMethod alloc] initWithMethodName:method methodNamespace:methodNamespace authType:authType handler:^(IESBridgeMessage * _Nonnull message, IESBridgeResponseBlock  _Nonnull responseBlock) {
        BOOL executeCallback = YES;
        NSDictionary *result = handler(message.callbackID, message.params, message.JSSDKVersion, &executeCallback);
        if(executeCallback && message.callbackID.length > 0) {
            responseBlock([result[@"code"] integerValue], result);
        } else {
            // 稍后业务方自己调用invokeJSWithCallbackID
            responseBlock(IESPiperStatusCodeManualCallback, nil);
        }
    }];
    [self.deprecatedBridgeEngine addMethod:bridgeMethod];
}

- (void)invokeJSWithCallbackID:(NSString*)callbackID parameters:(NSDictionary*)tParameters
{
    if (IESPiperCoreABTestManager.sharedManager.shouldUseBridgeEngineV2) {
        IESPiperStatusCode statusCode = tParameters[@"code"] ? [tParameters[@"code"] integerValue] : IESPiperStatusCodeSucceed;
        [self.bridgeEngine invokeJSWithCallbackID:callbackID statusCode:statusCode params:tParameters];
    } else {
        IESBridgeMessage *msg = [[IESBridgeMessage alloc] init];
        msg.messageType = IESJSMessageTypeCallback;
        msg.callbackID = callbackID;
        msg.params = ({
            NSMutableDictionary *params = tParameters ? [tParameters mutableCopy] : [NSMutableDictionary dictionary];
            params[@"code"] = tParameters[@"code"] ?: @(IESPiperStatusCodeSucceed);
            params.copy;
        });
        [self.deprecatedBridgeEngine sendBridgeMessage:msg];
    }
}

- (void)invokeJSWithEventID:(NSString *)eventID parameters:(NSDictionary *)tParameters finishBlock:(IESJSCallbackHandler)finishBlock
{
    if (IESPiperCoreABTestManager.sharedManager.shouldUseBridgeEngineV2) {
        [self.bridgeEngine fireEvent:eventID withParams:tParameters callback:finishBlock];
    } else {
        IESBridgeMessage *msg = [[IESBridgeMessage alloc] init];
        msg.messageType = IESJSMessageTypeEvent;
        msg.eventID = eventID;
        msg.params = tParameters;
        NSString *callbackID = [self getNewUnqiueID];
        msg.callbackID = callbackID;
        
        [_callbackHandlers setValue:finishBlock forKey:callbackID];
        [self.deprecatedBridgeEngine sendBridgeMessage:msg];
    }
}

// TODO: Deprecated
- (void)processIFrameMessage:(IESBridgeMessage*)msg
{
    if([msg.messageType isEqualToString:IESJSMessageTypeCallback]) {
        if(msg.callbackID.length > 0 && [_callbackHandlers objectForKey:msg.callbackID]) {
            IESJSCallbackHandler handler = [_callbackHandlers objectForKey:msg.callbackID];
            if(handler) {
                handler(msg.params);
            }
        }
    } else if([msg.messageType isEqualToString:IESJSMessageTypeCall]) {
        [self.deprecatedBridgeEngine executeMethodsWithMessage:msg];
    }
}

// TODO: Deprecated
- (NSString*)getNewUnqiueID
{
    @synchronized(self) {
        return [NSString stringWithFormat:@"ios_js_%d", _uniqueID++];
    }
}

// TODO: Deprecated
- (void)flushMessages
{
    NSString *jsString = [@"VG91dGlhb0pTQnJpZGdlLl9mZXRjaFF1ZXVlKCk=" btd_base64DecodedString]; //_canAffectStatusBarAppearance
    [self.deprecatedBridgeEngine.executor ies_executeJavaScript:jsString completion:^(id result, NSError *error) {
        NSString *resultString = [result description];
        NSArray *messagesData = [resultString btd_jsonArray];
        for(NSDictionary *messageData in messagesData) {
            IESBridgeMessage *msg = [[IESBridgeMessage alloc] init];
            msg.methodName = [messageData objectForKey:@"func"];
            msg.messageType = [messageData objectForKey:@"__msg_type"];
            msg.params = [messageData objectForKey:@"params"];
            msg.callbackID = [messageData objectForKey:@"__callback_id"];
            msg.JSSDKVersion = [messageData objectForKey:@"JSSDK"];
            msg.from = IESBridgeMessageFromIframe;
            [self processIFrameMessage:msg];
        }
    }];
}

- (BOOL)isAuthorizedForCall:(NSString *)functionName
{
    return [IESBridgeAuthManager.sharedManager isAuthorizedMethod:functionName forURL:self.webView.ies_url];
}

+ (NSString*)currentJSSDKVersion
{
    return @"2.0";
}

@end
