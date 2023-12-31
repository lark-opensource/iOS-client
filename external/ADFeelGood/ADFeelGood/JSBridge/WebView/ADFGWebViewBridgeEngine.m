//
//  ADFGWebViewBridgeEngine.m
//  NewsInHouse
//
//  Created by iCuiCui on 2020/04/23.
//

#import "ADFGWebViewBridgeEngine.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "ADFGUserAgentHelper.h"
#import "ADFGCommonMacros.h"

static NSString * kJSObject= @"DpSdk2JSBridge";
static NSString * kJSHandleMessageMethod = @"_handleMessageFromApp";
static NSString * kJSCallMethodParams= @"callMethodParams";
static NSString * kJSOnMethodParams= @"onMethodParams";

@implementation ADFGBridgeCommand (ADFGBridgeExtension)

+ (instancetype)commandWithMethod:(NSString *)method params:(NSDictionary *)params {
    NSMutableDictionary *mutableParams = [params mutableCopy];
    mutableParams[@"func"] = method;
    mutableParams[@"__msg_type"] = params[@"__msg_type"] ?: @"call";
    ADFGBridgeCommand *command = [[ADFGBridgeCommand alloc] initWithDictonary:[mutableParams copy]];
    return command;
}

@end

@interface ADFGWebViewBridgeEngine ()<WKScriptMessageHandler>

@property(nonatomic, strong) ADFGBridgeRegister *bridgeRegister;

@property (nonatomic, weak) NSObject *sourceObject;

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id result, NSError *error))completionHandler;

@end

static void invokeJSBCallbackWithCommand(ADFGBridgeCommand *command,
                                         ADFGBridgeMsg msg,
                                         NSDictionary *response,
                                         ADFGWebViewBridgeEngine *engine,
                                         void (^resultBlock)(NSString *result, ADFGBridgeMsg resultMsg)) {
    if (!command) {
        return;
    }
    command.bridgeMsg = msg;
    command.params = response;
    NSString *jsonCommand = [command wrappedParamsString];
    NSString *invokeJS = [NSString stringWithFormat:@";window.%@ && %@.%@ && %@.%@(%@)", kJSObject, kJSObject, kJSHandleMessageMethod, kJSObject, kJSHandleMessageMethod, jsonCommand];
    void (^invockBlock)(void) = ^{
        [engine evaluateJavaScript:invokeJS completionHandler:^(id result, NSError *error) {
            NSString *resultStr = nil;
            ADFGBridgeMsg resultMsg = ADFGBridgeMsgSuccess;
            if (!result) {
                resultMsg = ADFGBridgeMsgCodeUndefined;
            }
            else {
                if ([result isKindOfClass:NSString.class]){
                    resultStr = result;
                    if ([resultStr containsString:@"404"]) {
                        resultMsg = ADFGBridgeMsgCode404;
                    }
                }
                else if ([result isKindOfClass:NSDictionary.class]){
                    NSDictionary *resultDic = result;
                    NSString *errorCode = resultDic[@"__err_code"];
                    if ([errorCode isKindOfClass:NSString.class] && [errorCode containsString:@"404"]) {
                        resultMsg = ADFGBridgeMsgCode404;
                    }
                    NSData * data = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
                    resultStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                }
                else {
                    resultMsg = ADFGBridgeMsgUnknownError;
                }
            }

            if (resultBlock) {
                resultBlock(resultStr, resultMsg);
            }
        }];
    };
    adfg_dispatch_async_main_thread_safe(invockBlock);
}

static void call(ADFGWebViewBridgeEngine *engine, NSString *method, NSDictionary *params) {
    if (!engine) {
        return;
    }
    __weak typeof(engine) weakEngine = engine;
    void (^invockBlock)(void) = ^{
        ADFGBridgeCommand *command = [ADFGBridgeCommand commandWithMethod:method params:params];
        command.bridgeType = ADFGBridgeTypeCall;
  
        __auto_type completion = ^(ADFGBridgeMsg msg, NSDictionary *response, void (^resultBlock)(NSString *result)) {
            invokeJSBCallbackWithCommand(command, msg, response, weakEngine, ^(NSString *result, ADFGBridgeMsg resultMsg) {
                if (resultBlock) {
                    resultBlock(result);
                }
            });
        };
        if ([engine.bridgeRegister respondsToBridge:method]) {
            [engine.bridgeRegister executeCommand:command engine:engine completion:completion];
        }
        else {
            [ADFGBridgeRegister.sharedRegister executeCommand:command engine:engine completion:completion];
        }
    };
    adfg_dispatch_async_main_thread_safe(invockBlock);
}

void ADFGWebViewBridgeEngineSwapInstanceMethods(Class cls, SEL original, SEL replacement)
{
    Method originalMethod = class_getInstanceMethod(cls, original);
    IMP originalImplementation = method_getImplementation(originalMethod);
    const char *originalArgTypes = method_getTypeEncoding(originalMethod);
    
    Method replacementMethod = class_getInstanceMethod(cls, replacement);
    IMP replacementImplementation = method_getImplementation(replacementMethod);
    const char *replacementArgTypes = method_getTypeEncoding(replacementMethod);
    
    if (class_addMethod(cls, original, replacementImplementation, replacementArgTypes)) {
        class_replaceMethod(cls, replacement, originalImplementation, originalArgTypes);
    } else {
        method_exchangeImplementations(originalMethod, replacementMethod);
    }
}

@interface ADFGWKWebView ()<WKNavigationDelegate>

@property (nonatomic, strong) ADFGWebViewBridgeEngine *adfg_engine;

@end

@implementation ADFGWKWebView

- (void)dealloc {
    [self adfg_uninstallBridgeEngine];
}

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    configuration.processPool = [self.class shareProcessPool];
    configuration.preferences.javaScriptCanOpenWindowsAutomatically = true;
    //是否支持JavaScript
    configuration.preferences.javaScriptEnabled = true;
    configuration.allowsInlineMediaPlayback = YES;
    BOOL mediaPlaybackRequiresUserAction = NO;
    if (@available(iOS 10.0, *)) {
        configuration.mediaTypesRequiringUserActionForPlayback = mediaPlaybackRequiresUserAction ? WKAudiovisualMediaTypeAll : WKAudiovisualMediaTypeNone;
    } else if (@available (iOS 9.0, *)){
        configuration.requiresUserActionForMediaPlayback = mediaPlaybackRequiresUserAction;
    } 
    self = [super initWithFrame:frame configuration:configuration];
    if (self) {
        self.navigationDelegate = self;
        if (@available(iOS 11.0, *)) {
            self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
       if (@available(iOS 9.0, *)) {
            NSString *originUA = [[ADFGUserAgentHelper sharedInstance] userAgent];
            self.customUserAgent = [originUA stringByAppendingFormat:@" adfgsdk/%@",ADFGSDKVersion];
        }
    }
    return self;
}

+ (WKProcessPool *)shareProcessPool {
    static WKProcessPool *shareProcessPool;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareProcessPool = [[WKProcessPool alloc] init];
    });
    return shareProcessPool;
}

#pragma mark WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if (self.slaveDelates && [self.slaveDelates respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [self.slaveDelates webViewDidStartLoad:self];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (self.slaveDelates && [self.slaveDelates respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [self.slaveDelates webViewDidFinishLoad:self];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (self.slaveDelates && [self.slaveDelates respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.slaveDelates webView:self didFailLoadWithError:error];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (self.slaveDelates && [self.slaveDelates respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.slaveDelates webView:self didFailLoadWithError:error];
    }
}

- (void)adfg_installBridgeEngine:(ADFGWebViewBridgeEngine *)bridge {
    [bridge installOnWKWebView:self];
}

- (void)adfg_uninstallBridgeEngine {
    [self.adfg_engine uninstallFromWKWebView:self];
}

@end


@implementation ADFGWebViewBridgeEngine

@synthesize sourceObject = _sourceObject;

- (void)dealloc {
    
}

- (void)_doRegisterIfNeeded {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{// 全局方法注册
        [ADFGBridgePlugin _doRegisterIfNeeded];
    });
}

- (instancetype)initWithBridgeRegister:(ADFGBridgeRegister *)bridgeRegister {
    self = [super init];
    if (self) {
        [self _doRegisterIfNeeded];
        _bridgeRegister = bridgeRegister;
    }
    return self;
}

- (void)installOnWKWebView:(ADFGWKWebView *)webView {
    if (webView.adfg_engine) {
        NSAssert(NO, @"%@ already has a bridge engine.", webView);
        return;
    }
    NSParameterAssert(webView != nil);
    self.sourceObject = webView;
    webView.adfg_engine = self;
    [webView.configuration.userContentController addScriptMessageHandler:self name:kJSCallMethodParams];
    [webView.configuration.userContentController addScriptMessageHandler:self name:kJSOnMethodParams];
}

- (void)uninstallFromWKWebView:(ADFGWKWebView *)webView {
    if (webView.adfg_engine != self) {
        NSAssert(NO, @"%@ is not from %@.", self, webView);
        return;
    }
    [webView.configuration.userContentController removeScriptMessageHandlerForName:kJSCallMethodParams];
    [webView.configuration.userContentController removeScriptMessageHandlerForName:kJSOnMethodParams];
    webView.adfg_engine = nil;
}

- (void)fireEvent:(ADFGBridgeName)eventName params:(nullable NSDictionary *)params {
    [self fireEvent:eventName msg:ADFGBridgeMsgSuccess params:params resultBlock:nil];
}

- (void)fireEvent:(ADFGBridgeName)eventName params:(nullable NSDictionary *)params resultBlock:(void (^)(NSString * _Nullable))resultBlock {
    [self fireEvent:eventName msg:ADFGBridgeMsgSuccess params:params resultBlock:resultBlock];
}

- (void)fireEvent:(ADFGBridgeName)eventName msg:(ADFGBridgeMsg)msg params:(NSDictionary *)params resultBlock:(void (^)(NSString * _Nullable))resultBlock {
    ADFGBridgeCommand *command = [ADFGBridgeCommand new];
    command.callbackID = eventName;
    command.bridgeName = eventName;
    command.messageType = @"event";
    command.bridgeType = ADFGBridgeTypeOn;
    command.params = params;
    command.bridgeMsg = msg;
    invokeJSBCallbackWithCommand(command, msg, params, self, ^(NSString *result, ADFGBridgeMsg resultMsg) {
        if (resultBlock) {
            resultBlock(result);
        }
    });
}

- (void)registerBridge:(void(^)(ADFGBridgeRegisterMaker *maker))block {
    if (self.bridgeRegister) {
        [self.bridgeRegister registerBridge:block];
    } else {
        [ADFGBridgeRegister.sharedRegister registerBridge:block];
    }
}

- (void)unregisterBridge:(ADFGBridgeName)bridgeName {
    if (self.bridgeRegister) {
        [self.bridgeRegister unregisterBridge:bridgeName];
    } else {
        [ADFGBridgeRegister.sharedRegister unregisterBridge:bridgeName];
    }
}

- (BOOL)respondsToBridge:(ADFGBridgeName)bridgeName {
    return [self.bridgeRegister respondsToBridge:bridgeName] ?: [ADFGBridgeRegister.sharedRegister respondsToBridge:bridgeName];
}

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id result, NSError *error))completionHandler {
    if (![NSThread isMainThread]) {
        NSAssert(NO, @"注入JS必须在主线程");
        return;
    }
    if ([self.sourceObject isKindOfClass:[WKWebView class]]) {
        [self.wkWebView evaluateJavaScript:javaScriptString completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            if (completionHandler) {
                completionHandler(result, nil);
            }
        }];
    }
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    NSDictionary *body = [message.body isKindOfClass:NSDictionary.class] ? message.body : nil;
    if (!body) {
        return;
    }
    if ([message.name isEqualToString:kJSCallMethodParams]) {
        call(self, body[@"func"], body);
    }
}

- (ADFGWKWebView *)wkWebView {
    return [self.sourceObject isKindOfClass:[ADFGWKWebView class]] ? (ADFGWKWebView *)self.sourceObject : nil;
}

- (NSURL *)sourceURL {
    if ([self.sourceObject isKindOfClass:[ADFGWKWebView class]]) {
        return self.wkWebView.URL;
    }
    return nil;
}

- (UIViewController *)sourceController {
    return [self.class correctTopViewControllerFor:(UIView *)self.sourceObject];
}

+ (UIViewController*)correctTopViewControllerFor:(UIResponder*)responder
{
    UIResponder *topResponder = responder;
    for (; topResponder; topResponder = [topResponder nextResponder]) {
        if ([topResponder isKindOfClass:[UIViewController class]]) {
            UIViewController *viewController = (UIViewController *)topResponder;
            while (viewController.parentViewController && viewController.parentViewController != viewController.navigationController && viewController.parentViewController != viewController.tabBarController) {
                viewController = viewController.parentViewController;
            }
            return viewController;
        }
    }
    if(!topResponder && [[[UIApplication sharedApplication] delegate] respondsToSelector:@selector(window)])
    {
        topResponder = [[[UIApplication sharedApplication] delegate].window rootViewController];
    }
    
    return (UIViewController*)topResponder;
}

@end
