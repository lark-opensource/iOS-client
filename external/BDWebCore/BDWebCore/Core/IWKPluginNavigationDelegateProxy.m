//
//  IWKPluginNavigationDelegateProxy.m
//  BDWebCore
//
//  Created by li keliang on 2019/7/19.
//

#import "IWKPluginNavigationDelegateProxy.h"
#import "WKWebView+Plugins.h"
#import "IWKUtils.h"
#import "IWKWebViewPluginHelper.h"

#define run_plugins IWK_keywordify if (self.webView.IWK_pluginsEnable)

@implementation IWKPluginNavigationDelegateProxy

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return;
        }
    }
    
    if ([self.proxy respondsToSelector:_cmd]) {
        [self.proxy webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
    } else {
        !decisionHandler ?: decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:webView decidePolicyForNavigationResponse:navigationResponse decisionHandler:decisionHandler];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return;
        }
    }
    
    if ([self.proxy respondsToSelector:_cmd]) {
        [self.proxy webView:webView decidePolicyForNavigationResponse:navigationResponse decisionHandler:decisionHandler];
    } else {
        !decisionHandler ?: decisionHandler(WKNavigationResponsePolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return ;
        }
    }
    
    if ([self.proxy respondsToSelector:_cmd]) {
        return [self.proxy webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation];
    }
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return ;
        }
    }
    
    if ([self.proxy respondsToSelector:_cmd]) {
        return [self.proxy webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return ;
        }
    }
    
    if ([self.proxy respondsToSelector:_cmd]) {
        return [self.proxy webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error];
    }
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return ;
        }
    }
    
    if ([self.proxy respondsToSelector:_cmd]) {
        return [self.proxy webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:(WKWebView *)webView didFinishNavigation:( WKNavigation *)navigation];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return ;
        }
    }
    
    if ([self.proxy respondsToSelector:_cmd]) {
        return [self.proxy webView:(WKWebView *)webView didFinishNavigation:( WKNavigation *)navigation];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return ;
        }
    }
    
    if ([self.proxy respondsToSelector:_cmd]) {
        return [self.proxy webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error];
    }
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return ;
        }
    }
    
    if ([self.proxy respondsToSelector:_cmd]) {
        return [self.proxy webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler];
    } else {
        !completionHandler ?: completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView API_AVAILABLE(macosx(10.11), ios(9.0))
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webViewWebContentProcessDidTerminate:(WKWebView *)webView];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return ;
        }
    }
    
    if ([self.proxy respondsToSelector:_cmd]) {
        return [self.proxy webViewWebContentProcessDidTerminate:(WKWebView *)webView];
    }
}

#pragma mark - Message Fowarding

- (BOOL)isProxy
{
    return YES;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([super respondsToSelector:aSelector] || [_proxy respondsToSelector:aSelector]) {
        return YES;
    }
    
    return NO;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    __block NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:"@^v^c"];
    
    if ([_proxy respondsToSelector:aSelector] && [_proxy respondsToSelector:@selector(methodSignatureForSelector:)]) {
        methodSignature = [(NSObject *)_proxy methodSignatureForSelector:aSelector];
    }
    
    return methodSignature;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    if ([_proxy respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:_proxy];
    }
    
    NSCAssert(_proxy , @"Proxy got %@ when its target is still alive, which is unexpected.", NSStringFromSelector(invocation.selector));
}

@end
