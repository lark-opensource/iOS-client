//
//  IWKJSBridgePluginObject.m
//  IESWebKit
//
//  Created by Lizhen Hu on 2019/7/16.
//

#import "IWKJSBridgePluginObject.h"
#import "NSURL+IESBridgeAddition.h"
#import "IESJSBridge.h"
#import "IESJSBridgeCoreABTestManager.h"
#import "IESBridgeMessage.h"
#import "IESBridgeMessage+Private.h"
#import "IESBridgeEngine.h"
#import "IESBridgeEngine+Private.h"
#import "IESJSMethodManager.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <BDMonitorProtocol/BDMonitorProtocol.h>
#import <ByteDanceKit/ByteDanceKit.h>

static NSString * const IWKSyncInvokeMethod = @"SyncInvokeMethod";

@interface IWKPiperPluginObject () <WKScriptMessageHandler>

@property(nonatomic, assign) BOOL userScriptInjectSucceeded;
@property(nonatomic, assign) BOOL isCheckingUserScriptInject;

@end

@implementation IWKPiperPluginObject

- (instancetype)init
{
    self = [super init];
    if (self) {
        _protocolV1Enabled = YES;
    }
    return self;
}

- (void)onLoad:(id)container {
    WKWebView *webView = container;
    if (!webView || ![webView isKindOfClass:WKWebView.class]) {
        NSParameterAssert(webView);
        NSParameterAssert([webView isKindOfClass:WKWebView.class]);
        return;
    }
    
    [self assertIfOldTTEngineExistForWebView:webView];
    [self _doAddScriptIfNeeded:webView];
    [webView.configuration.userContentController removeScriptMessageHandlerForName:IESPiperOnMethodParamsHandler];
    [webView.configuration.userContentController addScriptMessageHandler:self name:IESPiperOnMethodParamsHandler];
    IESJSMethodManager *jsMethodManager = [IESJSMethodManager managerWithBridgeExecutor:webView];
    [jsMethodManager.allHandlerNames enumerateObjectsUsingBlock:^(IESPiperProtocolVersion  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [webView.configuration.userContentController removeScriptMessageHandlerForName:obj];
        [webView.configuration.userContentController addScriptMessageHandler:self name:obj];
    }];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    WKWebView *webView = message.webView;
    if (!webView) {
        NSParameterAssert(webView);
        return;
    }
    IESJSMethodManager *jsMethodManager = [IESJSMethodManager managerWithBridgeExecutor:webView];
    if (message.name.length > 0 && ![jsMethodManager.allHandlerNames containsObject:message.name]) {
        return;
    }

    NSDictionary *messageBody;
    if ([message.body isKindOfClass:NSString.class]) {
        messageBody = [message.body btd_jsonDictionary];
    } else if ([message.body isKindOfClass:NSDictionary.class]) {
        messageBody = message.body;
    }
    
    IESBridgeMessage *bridgeMessage = [[IESBridgeMessage alloc] initWithDictionary:messageBody];
    bridgeMessage.from = IESBridgeMessageFromJSCall;
    bridgeMessage.protocolVersion = message.name;
    [message.webView.ies_bridgeEngine handleBridgeMessage:bridgeMessage];
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURL *url = navigationAction.request.URL;
    if (self.protocolV1Enabled && [url jsb_isMatchedInBridgeSchemes] && [url.host isEqualToString:IESPiperCoreBridgeHostnameDispatchMessage]) {
        IESPiperCoreInfoLog(@"%@", @"Piper V1 invoked");
        [webView.ies_bridgeEngine flushBridgeMessages];
        decisionHandler(WKNavigationActionPolicyCancel);
        return IWKPluginHandleResultBreak;
    }
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [self assertIfOldTTEngineExistForWebView:webView];
    if (!self.userScriptInjectSucceeded && !self.isCheckingUserScriptInject && !webView.ies_bridgeEngine.bridgeObjectsDeleted) {
        NSString *js = @stringify
        (
            (function () {
              var noWindow = 1 << 0;
              var noCallMethodParams = 1 << 1;
              var noJS2NativeBridge = 1 << 2;
              var noInvokeMethod = 1 << 3;
              var noOnMethodParams = 1 << 4;
              var noV2Handler = 1 << 5;
              var noV3Handler = 1 << 6;

              if (typeof window !== 'object') {
                return noWindow;
              }

              var ret = 0;
              if (!window.callMethodParams) {
                ret = ret | noCallMethodParams;
              }

              if (!(window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.onMethodParams)) {
                ret = ret | noOnMethodParams;
              }
              if (!(window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.IESPiperProtocolVersion2_0)) {
                ret = ret | noV2Handler;
              }
              if (!(window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.IESPiperProtocolVersion3_0)) {
                ret = ret | noV3Handler;
              }
              if (!window.JS2NativeBridge) {
                ret = ret | noJS2NativeBridge;
              } else if (!window.JS2NativeBridge._invokeMethod) {
                ret = ret | noInvokeMethod;
              }

              return ret;
            })();
        );
        self.isCheckingUserScriptInject = YES;
        @weakify(webView);
        [webView evaluateJavaScript:js completionHandler:^(NSNumber * result, NSError * _Nullable error) {
            @strongify(webView);
            if (!error && [result isKindOfClass:NSNumber.class]) {
                if (result.integerValue == 0) {
                    self.userScriptInjectSucceeded = YES;
                }
                else {
                    NSString *serviceName = [@"anNicmlkZ2VfaW5qZWN0X2ZhaWxlZA==" btd_base64DecodedString];
                    [BDMonitorProtocol hmdTrackService:serviceName metric:@{
                    } category:@{
                        @"status" : @(result.integerValue).stringValue
                    } extra:@{
                        @"webpage_url" : webView.URL.absoluteString ?: @"",
                    }];
                }
            }
            self.isCheckingUserScriptInject = NO;
        }];
    }

    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString *))completionHandler
{
    NSError *error = nil;
    NSData *data = [defaultText dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if ([prompt isEqualToString:IWKSyncInvokeMethod] && dict && !error) {
        IESBridgeMessage *bridgeMessage = [[IESBridgeMessage alloc] initWithDictionary:dict callback:^(NSString *result) {
            !completionHandler ?: completionHandler(result);
        }];
        bridgeMessage.from = IESBridgeMessageFromJSCall;
        [webView.ies_bridgeEngine handleBridgeMessage:bridgeMessage];
        return IWKPluginHandleResultBreak;
    } else {
        return IWKPluginHandleResultContinue;
    }
}

- (void)assertIfOldTTEngineExistForWebView:(WKWebView *)webView
{
    SEL tt_engine = NSSelectorFromString(@"tt_engine");
    if (![webView respondsToSelector:tt_engine]) {
        return;
    }
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id bridgeEngine = [webView performSelector:tt_engine];
    #pragma clang diagnostic pop
    Class ttBridgeEngineClass = NSClassFromString(@"TTWebViewBridgeEngine");
    Class bdBridgeEngineClass = NSClassFromString(@"BDTouTiaoWebViewBridgeEngine");
    if ([bridgeEngine isMemberOfClass:ttBridgeEngineClass] ||
        [bridgeEngine isKindOfClass:bdBridgeEngineClass]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"TTWebViewBridgeEngine|BDTouTiaoWebViewBridgeEngine & IESBridgeEngine cannot be used in the same webview instance due to compatibility issue."
                                     userInfo:nil];
    }
}

- (void)_doAddScriptIfNeeded:(WKWebView *)webView {
    // Build script.
    IESJSMethodManager *jsMethodManager = [IESJSMethodManager managerWithBridgeExecutor:webView];
    NSMutableDictionary<IESPiperProtocolVersion, IESJSMethod *> *methodsDic = [jsMethodManager allJSMethodsForKey:IESJSMethodKeyInvokeMethod].mutableCopy;
    NSMutableString *source = [NSMutableString string];

    [methodsDic enumerateKeysAndObjectsUsingBlock:^(IESPiperProtocolVersion _Nonnull key, IESJSMethod * _Nonnull obj, BOOL * _Nonnull stop) {
      NSString *messageHandler = [NSString stringWithFormat:@"webkit.messageHandlers.%@.postMessage", key];
      [source appendString:[IESJSMethodManager injectionScriptWithJSMethod:obj messageHandler:messageHandler]];
    }];
    
    BOOL onlyMainFrame = !IESPiperCoreABTestManager.sharedManager.shouldEnableIFrameJSB;
    WKUserScript *script = [[WKUserScript alloc] initWithSource:source injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:onlyMainFrame];

    // Inject script if needed.
    __block BOOL needAddScript = YES;
    [webView.configuration.userContentController.userScripts enumerateObjectsUsingBlock:^(WKUserScript *obj, NSUInteger idx, BOOL *stop) {
       if ([script.source isEqualToString:obj.source]) {
           needAddScript = NO;
           *stop = YES;
       }
    }];
    if (needAddScript) {
       [webView.configuration.userContentController addUserScript:script];
    }
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {
    self.commitURL = webView.URL;
    return IWKPluginHandleResultContinue;
}

@end
