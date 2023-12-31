//
//  IWKPluginDelegateProxy.m
//  BDWebCore
//
//  Created by li keliang on 2019/7/19.
//

#import "IWKPluginDelegateProxy.h"
#import "IWKUtils.h"
#import "IWKWebViewPluginHelper_UIWebView.h"
#import "UIWebView+Plugins.h"
#import "IWKPluginObject_UIWebView.h"

#define run_plugins IWK_keywordify if (self.webView.IWK_pluginsEnable)

@implementation IWKPluginDelegateProxy

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper_UIWebView runPlugins:webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject_UIWebView *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
        }];
        
        if (result) {
            return result.value;
        }
    }
    
    if ([self.proxy respondsToSelector:_cmd]) {
        return [self.proxy webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper_UIWebView runPlugins:self.webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject_UIWebView *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webViewDidStartLoad:webView];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return;
        }
    }
    
    if ([self.proxy respondsToSelector:_cmd]) {
        [self.proxy webViewDidStartLoad:webView];
        return;
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper_UIWebView runPlugins:self.webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject_UIWebView *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webViewDidFinishLoad:webView];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return;
        }
    }
    
    if ([self.proxy respondsToSelector:_cmd]) {
        [self.proxy webViewDidFinishLoad:webView];
        return;
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper_UIWebView runPlugins:self.webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject_UIWebView *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:webView didFailLoadWithError:error];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return;
        }
    }
    
    if ([self.proxy respondsToSelector:_cmd]) {
        [self.proxy webView:webView didFailLoadWithError:error];
        return;
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

