//
//  IESLiveWKWebCoreTrigger.m
//  IESWebViewMonitor
//
//  Created by 蔡腾远 on 2020/1/9.
//

#import "IESLiveWKWebCoreTrigger.h"
#import "IESLiveWebViewMonitor+Private.h"
#import "BDWebViewGeneralReporter.h"
#import "IESLiveWebViewMonitor.h"
#import <objc/runtime.h>

void *pluginWKAssociatedKey = &pluginWKAssociatedKey;

@implementation IESLiveWKWebCoreTrigger

#pragma mark - IWKPluginWebViewLoader
//- (IWKPluginHandleResultObj<WKNavigation *> *)webView:(WKWebView *)webView loadRequest:(NSURLRequest *)request {
//    return continue;
//}

#pragma mark - IWKPluginNavigationDelegate

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [self updateMonitorOfWebView:webView statusCode:nil error:nil withType:BDRequestStartType];
     return [IWKPluginHandleResultObj continue];
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    [self updateMonitorOfWebView:webView statusCode:nil error:error withType:BDRequestFailType];
    return [IWKPluginHandleResultObj continue];
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    [self updateMonitorOfWebView:webView statusCode:nil error:nil withType:BDRedirectStartType];
    return [IWKPluginHandleResultObj continue];
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {
    [self updateMonitorOfWebView:webView statusCode:nil error:nil withType:BDNavigationStartType];
    return [IWKPluginHandleResultObj continue];
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    // A->B->A时，时常会触发A页面报错，原因是跳转后终止了webview对部分资源的加载，会触发canceled error @yangyi.peter https://www.jianshu.com/p/cbd866e59db0
    if (error.code != NSURLErrorCancelled) {
        [self updateMonitorOfWebView:webView statusCode:nil error:error withType:BDNavigationFailType];
    }
    
    return [IWKPluginHandleResultObj continue];
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    [self updateMonitorOfWebView:webView statusCode:nil error:nil withType:BDNavigationFinishType];
    return [IWKPluginHandleResultObj continue];
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    NSInteger statusCode = 0;
    if ([navigationResponse.response isKindOfClass:[NSHTTPURLResponse class]]) {
        statusCode = [(NSHTTPURLResponse*)navigationResponse.response statusCode];
    }
    [self updateMonitorOfWebView:webView statusCode:[NSNumber numberWithInteger:statusCode] error:nil withType:BDNavigationPreFinishType];
    return [IWKPluginHandleResultObj continue];
}

- (IWKPluginHandleResultType)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{@"message":@""}];
    [self updateMonitorOfWebView:webView statusCode:nil error:error withType:BDNavigationTerminateType];
    return [IWKPluginHandleResultObj continue];
}

#pragma mark - private
- (void)updateMonitorOfWebView:(WKWebView *)webView
                    statusCode:(NSNumber * __nullable)statusCode
                         error:(NSError * __nullable)error
                      withType:(BDWebViewGeneralType)type {
    Class nodeClass = [IESLiveWebViewMonitor getNodeClassWithWebView:[webView class]];
    if (objc_getAssociatedObject(self, pluginWKAssociatedKey) == nodeClass) {
        [BDWebViewGeneralReporter updateMonitorOfWKWebView:webView statusCode:statusCode error:error withType:type];
    }
}

@end
