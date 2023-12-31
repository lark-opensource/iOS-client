//
//  IWKPluginUIDelegateProxy.m
//  BDWebCore
//
//  Created by li keliang on 2019/7/19.
//

#import "IWKPluginUIDelegateProxy.h"
#import "WKWebView+Plugins.h"
#import "IWKUtils.h"
#import "IWKWebViewPluginHelper.h"
#import "IWKDelegateCompletionProbe.h"

#define run_plugins IWK_keywordify if (self.webView.IWK_pluginsEnable)

@implementation IWKPluginUIDelegateProxy

- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:webView createWebViewWithConfiguration:configuration forNavigationAction:navigationAction windowFeatures:windowFeatures];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return result.value;
        }
    }
    
    if ([self.proxy respondsToSelector:_cmd]) {
        return [self.proxy webView:webView createWebViewWithConfiguration:configuration forNavigationAction:navigationAction windowFeatures:windowFeatures];
    }
    return nil;
}

- (void)webViewDidClose:(WKWebView *)webView API_AVAILABLE(macosx(10.11), ios(9.0))
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webViewDidClose:webView];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return ;
        }
    }
    
    if ([self.proxy respondsToSelector:_cmd]) {
        return [self.proxy webViewDidClose:webView];
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:webView runJavaScriptAlertPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return ;
        }
    }
    
    if ([self.proxy respondsToSelector:_cmd]) {
        return [self.proxy webView:webView runJavaScriptAlertPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
    } else {
        !completionHandler ?: completionHandler();
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:webView runJavaScriptConfirmPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return ;
        }
    }
    
    if ([self.proxy respondsToSelector:_cmd]) {
        return [self.proxy webView:webView runJavaScriptConfirmPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
    } else {
        !completionHandler ?: completionHandler(NO);
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler
{
    IWKDelegateCompletionProbe *probe = [IWKDelegateCompletionProbe probeWithSelector:_cmd];
    void(^wrapperHandler)(NSString *) = ^(NSString * result) {
        [probe callOnce:result];
    };
    
    // the system completionHandler has no func signature, should type cast
    probe.completionHandler = ^(NSString *result){
        !completionHandler ?: completionHandler(result);
    };
    
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            probe.caller = plugin;
            return [plugin webView:webView runJavaScriptTextInputPanelWithPrompt:prompt defaultText:defaultText initiatedByFrame:frame completionHandler:wrapperHandler];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return ;
        }
    }
    
    if ([self.proxy respondsToSelector:_cmd]) {
        probe.caller = self.proxy;
        return [self.proxy webView:webView runJavaScriptTextInputPanelWithPrompt:prompt defaultText:defaultText initiatedByFrame:frame completionHandler:wrapperHandler];
    } else {
        probe.caller = self;
        !wrapperHandler ?: wrapperHandler(nil);
    }
}

- (BOOL)webView:(WKWebView *)webView shouldPreviewElement:(WKPreviewElementInfo *)elementInfo API_AVAILABLE(ios(10.0))
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:webView shouldPreviewElement:elementInfo];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return [result.value boolValue];
        }
    }
    
    if ([self.proxy respondsToSelector:_cmd]) {
        return [self.proxy webView:webView shouldPreviewElement:elementInfo];
    }
    
    return NO;
}

- (nullable UIViewController *)webView:(WKWebView *)webView previewingViewControllerForElement:(WKPreviewElementInfo *)elementInfo defaultActions:(NSArray<id <WKPreviewActionItem>> *)previewActions API_AVAILABLE(ios(10.0))
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:webView previewingViewControllerForElement:elementInfo defaultActions:previewActions];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return result.value;
        }
    }
    
    if ([self.proxy respondsToSelector:_cmd]) {
        return [self.proxy webView:webView previewingViewControllerForElement:elementInfo defaultActions:previewActions];
    }
    
    return nil;
}

- (void)webView:(WKWebView *)webView commitPreviewingViewController:(UIViewController *)previewingViewController API_AVAILABLE(ios(10.0))
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:webView commitPreviewingViewController:previewingViewController];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return ;
        }
    }
    
    if ([self.proxy respondsToSelector:_cmd]) {
        return [self.proxy webView:webView commitPreviewingViewController:previewingViewController];
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
