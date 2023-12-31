//
//  BDWPluginScriptMessageHandlerProxy.m
//  BDWebCore
//
//  Created by 李琢鹏 on 2020/1/16.
//

#import "BDWPluginScriptMessageHandlerProxy.h"
#import "WKWebView+Plugins.h"
#import "IWKUtils.h"
#import "IWKWebViewPluginHelper.h"

#define run_plugins IWK_keywordify if (self.webView.IWK_pluginsEnable)

@implementation BDWPluginScriptMessageHandlerProxy

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:@selector(bdw_userContentController:didReceiveScriptMessage:)]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin bdw_userContentController:userContentController didReceiveScriptMessage:message];
        }];

        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return ;
        }
    }

    if ([self.realHandler respondsToSelector:_cmd]) {
        return [self.realHandler userContentController:userContentController didReceiveScriptMessage:message];
    }
}

#pragma mark - Message Fowarding

- (BOOL)isProxy
{
    return YES;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([super respondsToSelector:aSelector] || [_realHandler respondsToSelector:aSelector]) {
        return YES;
    }
    
    return NO;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    __block NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:"@^v^c"];
    
    if ([_realHandler respondsToSelector:aSelector] && [_realHandler respondsToSelector:@selector(methodSignatureForSelector:)]) {
        methodSignature = [(NSObject *)_realHandler methodSignatureForSelector:aSelector];
    }
    
    return methodSignature;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    if ([_realHandler respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:_realHandler];
    }
    
    NSCAssert(_realHandler , @"Proxy got %@ when its target is still alive, which is unexpected.", NSStringFromSelector(invocation.selector));
}


@end
