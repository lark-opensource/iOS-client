//
//  TTRexxarWebViewAdapter.m
//  TTBridgeUnify
//
//  Created by lizhuopeng on 2019/3/29.
//

#import "TTRexxarWebViewAdapter.h"
#import <objc/runtime.h>
#import "TTBridgeForwarding.h"
#import "TTWebViewBridgeEngine.h"
#import "TTBridgeAuthManager.h"
#import <BDMonitorProtocol/BDMonitorProtocol.h>

static NSString * kTTBridgeScheme = @"bytedance";
static NSString * kTTBridgeDomReadyHost = @"domReady";
static NSString * kTTBridgeHost = @"dispatch_message";
static NSString * kTTBridgeHandleMessageMethod = @"_handleMessageFromToutiao";
static NSString * kTTBridgeFetchQueueMethod = @"_fetchQueue";



@interface TTRexxarWebViewAdapter ()

+ (BOOL)handleBridgeRequest:(NSURLRequest *)request engine:(TTWebViewBridgeEngine *)engine;

@end


@interface _TTWKWebViewDynamicDelegate : NSProxy<WKNavigationDelegate>

@property(nonatomic, weak) id realDelegate;

@end

@implementation _TTWKWebViewDynamicDelegate

- (BOOL)respondsToSelector:(SEL)aSelector {
    return  class_respondsToSelector(object_getClass(self), aSelector) || [self.realDelegate respondsToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    if ([self.realDelegate methodSignatureForSelector:aSelector]) {
        return [self.realDelegate methodSignatureForSelector:aSelector];
    }
    else if (class_respondsToSelector(object_getClass(self), aSelector)) {
        return [object_getClass(self) methodSignatureForSelector:aSelector];
    }
    return [[NSObject class] methodSignatureForSelector:aSelector];
}


- (void)forwardInvocation:(NSInvocation *)invocation {
    if ([self.realDelegate respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:self.realDelegate];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (webView.tt_engine.schemaInterceptionEnabled && [TTRexxarWebViewAdapter handleBridgeRequest:navigationAction.request engine:webView.tt_engine] ) {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    id realDelegate = self.realDelegate;
    if (realDelegate && [realDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]) {
        [realDelegate webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
    }
    else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    webView.tt_commitURL = webView.URL;
}

@end

@implementation WKWebView (TTRexxarAdapter)


- (void)ttra_setNavigationDelegate:(id<WKNavigationDelegate>)navigationDelegate {
    _TTWKWebViewDynamicDelegate *dynamicDelegate = objc_getAssociatedObject(self, _cmd);
    if (!dynamicDelegate) {
        dynamicDelegate = _TTWKWebViewDynamicDelegate.alloc;
        objc_setAssociatedObject(self, _cmd, dynamicDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    dynamicDelegate.realDelegate = navigationDelegate;
    [self ttra_setNavigationDelegate:dynamicDelegate];
}

- (instancetype)ttra_initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    __auto_type r = [self ttra_initWithFrame:frame configuration:configuration];
    r.navigationDelegate = nil;
    return r;
}

+ (void)load {
    method_exchangeImplementations(class_getInstanceMethod(WKWebView.class,  @selector(setNavigationDelegate:)), class_getInstanceMethod(WKWebView.class, @selector(ttra_setNavigationDelegate:)));
    method_exchangeImplementations(class_getInstanceMethod(WKWebView.class,  @selector(initWithFrame:configuration:)), class_getInstanceMethod(WKWebView.class, @selector(ttra_initWithFrame:configuration:)));
}

- (void)tt_enableRexxarAdapter {
    
}

- (NSURL *)tt_commitURL {
    NSURL* commitUrl = objc_getAssociatedObject(self, _cmd);
    return commitUrl;
}

- (void)setTt_commitURL:(NSURL *)commitURL {
    objc_setAssociatedObject(self, @selector(tt_commitURL), commitURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@implementation TTRexxarWebViewAdapter


static void invokeJSBCallbackWithCommand(TTBridgeCommand *command,
                                         TTBridgeMsg msg,
                                         NSDictionary *response,
                                         TTWebViewBridgeEngine *engine,
                                         void (^resultBlock)(NSString *result, TTBridgeMsg resultMsg)) {
    if (!command) {
        return;
    }
    
    TTBridgeCommand *newCommand = [command copy];
    NSMutableDictionary *params = response.mutableCopy ?: NSMutableDictionary.dictionary;
    [params setValue:@"1" forKey:@"rexxar_adapter"];
    switch (msg) {
        case TTBridgeMsgSuccess:
            [params setValue:@"JSB_SUCCESS" forKey:@"ret"];
            break;
        case TTBridgeMsgFailed:
            [params setValue:@"JSB_FAILED" forKey:@"ret"];
            break;
        case TTBridgeMsgParamError:
            [params setValue:@"JSB_PARAM_ERROR" forKey:@"ret"];
            break;
        case TTBridgeMsgNoHandler:
            [params setValue:@"JSB_NO_HANDLER" forKey:@"ret"];
            break;
        case TTBridgeMsgNoPermission:
            [params setValue:@"JSB_NO_PERMISSION" forKey:@"ret"];
            break;
        default:
            [params setValue:@"JSB_UNKNOW_ERROR" forKey:@"ret"];
            break;
    }
    newCommand.messageType = @"callback";
    newCommand.params = params.copy;
    newCommand.endTime = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970] * 1000];
    
    NSString *jsonCommand = [newCommand toJSONString];
    NSString *kTTBridgeObject = [NSString stringWithFormat:@"ToutiaoJ%@",@"SBridge"];
    NSString *invokeJS = [NSString stringWithFormat:@";(function () { var result = JSON.stringify('no function'); if (window.%@ && window.%@.%@) { result = window.%@.%@(%@); } return result; })()", kTTBridgeObject, kTTBridgeObject, kTTBridgeHandleMessageMethod,  kTTBridgeObject, kTTBridgeHandleMessageMethod, jsonCommand];
    [engine evaluateJavaScript:invokeJS completionHandler:^(id result, NSError *error) {
        TTBridgeMsg resultMsg = TTBridgeMsgUnknownError;
        if ([result isKindOfClass:NSString.class]){
            NSString *resultStr = result;
            if ([resultStr containsString:@"no function"]) {
                  resultMsg = TTBridgeMsgCodeUndefined;
            }
            else if ([resultStr containsString:@"404"]) {
                resultMsg = TTBridgeMsgCode404;
            }
        }
        else if ([result isKindOfClass:NSDictionary.class]){
            NSDictionary *resultDic = result;
            NSString *errorCode = resultDic[@"__err_code"];
            if ([errorCode isKindOfClass:NSString.class] && [errorCode containsString:@"404"]) {
                resultMsg = TTBridgeMsgCode404;
            }
        }
        else {
            resultMsg = TTBridgeMsgUnknownError;
        }
        if (resultBlock) {
            resultBlock([result isKindOfClass:[NSString class]] ? result : nil, resultMsg);
        }
    }];
}

+ (BOOL)handleBridgeRequest:(NSURLRequest *)request engine:(TTWebViewBridgeEngine *)engine {
    NSURL *url = request.URL;
    if ((![url.scheme isEqualToString:kTTBridgeScheme] || ![url.host isEqualToString:kTTBridgeHost]) || ![engine isKindOfClass:NSClassFromString(@"BDTouTiaoWebViewBridgeEngine")]) {
        return NO;
    }
    NSString *kTTBridgeObject = [NSString stringWithFormat:@"ToutiaoJ%@",@"SBridge"];
    [engine evaluateJavaScript:[NSString stringWithFormat:@";window.%@ && %@.%@();", kTTBridgeObject, kTTBridgeObject, kTTBridgeFetchQueueMethod] completionHandler:^(NSString *result, NSError *error) {
        NSArray *messageData = nil;
        if ([result isKindOfClass:NSString.class] && result.length > 0) {
            __auto_type data = [result dataUsingEncoding:NSUTF8StringEncoding];
            if (data) {
                messageData = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            }
        }
        else {
            NSString *monitorName = [NSString stringWithFormat:@"%@%@_fetch_queue",@"js",@"bridge"];
            [BDMonitorProtocol hmdTrackService:monitorName
                                        metric:@{}
                                      category:@{@"status_code": @(TTBridgeMsgCodeUndefined),
                                                 @"engine_type" : @(engine.engineType),
                                                 @"version" : @"1.0",
                                      }
                                         extra:@{
                                                 @"webpage_url" : engine.sourceURL.absoluteString ?: @"",
                                                 }];
        }
        for(NSDictionary *message in messageData) {
            TTBridgeCommand *command = [[TTBridgeCommand alloc] initWithDictonary:message];
            command.protocolType = TTPiperProtocolSchemaInterception;
            command.bridgeType = TTBridgeTypeCall;
            // Use TTBridgeUnify to Handle the Bridge.
            command.startTime = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970] * 1000];
            if (![engine respondsToBridge:command.bridgeName]) {
                BOOL shouldCallbackUnregisteredCommand = [TTBridgeRegister bridgeEngine:engine shouldCallbackUnregisteredCommand:command];
                if (!shouldCallbackUnregisteredCommand) {
                    continue;
                }
            }
            __weak __auto_type weakEngine = engine;
            __auto_type completion = ^(TTBridgeMsg msg, NSDictionary *response, void (^resultBlock)(NSString *result)) {
                if (msg != TTBridgeMsgSuccess) {
                    NSString *monitorName = [NSString stringWithFormat:@"%@%@_invoke_method",@"js",@"bridge"];
                    [BDMonitorProtocol hmdTrackService:monitorName
                                                metric:@{}
                                              category:@{@"status_code": @(msg),
                                                         @"engine_type" : @(engine.engineType),
                                                         @"version" : @"1.0",
                                                         @"method_name" : command.bridgeName ?: @""
                                              }
                                                 extra:@{@"webpage_url" : engine.sourceURL.absoluteString ?: @"",}];
                }
                command.bridgeMsg = msg;
                [TTBridgeRegister bridgeEngine:engine willCallbackBridgeCommand:command];
                invokeJSBCallbackWithCommand(command, msg, response, weakEngine, ^(NSString *result, TTBridgeMsg resultMsg) {
                    if (resultMsg != TTBridgeMsgSuccess) {
                        NSString *monitorName = [NSString stringWithFormat:@"%@%@_callback",@"js",@"bridge"];
                        [BDMonitorProtocol hmdTrackService:monitorName
                                                          metric:@{}
                                                        category:@{@"status_code": @(resultMsg),
                                                                   @"engine_type" : @(engine.engineType),
                                                                   @"version" : @"1.0",
                                                                   @"method_name" : command.bridgeName ?: @""
                                                        }
                                                           extra:@{@"webpage_url" : engine.sourceURL.absoluteString ?: @"",}];
                    }
                    if (resultBlock) {
                        resultBlock(result);
                    }
                });
            };
            
            if ([engine.bridgeRegister respondsToBridge:command.bridgeName]) {
                BOOL shouldHandleBridge = [TTBridgeRegister bridgeEngine:engine shouldHandleLocalBridgeCommand:command];
                if (!shouldHandleBridge) {
                    continue;
                }
                [engine.bridgeRegister executeCommand:command engine:engine completion:completion];
            }
            else {
                BOOL shouldHandleBridge = [TTBridgeRegister bridgeEngine:engine shouldHandleGlobalBridgeCommand:command];
                if (!shouldHandleBridge) {
                    continue;
                }
                [TTBridgeRegister.sharedRegister executeCommand:command engine:engine completion:completion];
            }
        }
    }];
    
    return YES;
}



+ (void)fireEvent:(NSString *)eventName data:(NSDictionary *)data engine:(TTWebViewBridgeEngine *)engine {
    [engine fireEvent:eventName params:data resultBlock:nil];
}

@end
