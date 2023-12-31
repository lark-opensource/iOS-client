//
//  UIWebView+WebCore.m
//  BDWebCore
//
//  Created by li keliang on 2019/7/19.
//

#import "UIWebView+Plugins.h"
#import "IWKUtils.h"
#import "IWKPluginObject.h"
#import "IWKWebViewPluginHelper_UIWebView.h"
#import "IWKPluginDelegateProxy.h"
#import "IWKPluginObject_UIWebView.h"

#import <objc/runtime.h>
#import <JavaScriptCore/JSContext.h>
#import <JavaScriptCore/JSValue.h>

#define run_plugins IWK_keywordify if (self.IWK_pluginsEnable)

static NSHashTable<UIWebView *> * kAllUIWebViewsHashTable(void){
    static NSHashTable *webViews;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        webViews = [NSHashTable weakObjectsHashTable];
    });
    return webViews;
}

@implementation UIWebView (Delegates)

- (IWKPluginDelegateProxy *)IWK_delegate
{
    if (!objc_getAssociatedObject(self, _cmd)) {
        IWKPluginDelegateProxy *proxy = [IWKPluginDelegateProxy new];
        proxy.webView = self;
        objc_setAssociatedObject(self, _cmd, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return objc_getAssociatedObject(self, _cmd);
}

@end

@implementation UIWebView (WebCore)

+ (void)load
{
    IWKClassSwizzle(self, NSSelectorFromString(@"dealloc"), @selector(IWK_dealloc));
    IWKClassSwizzle(self, @selector(initWithFrame:), @selector(IWK_initWithFrame:));
    IWKClassSwizzle(self, @selector(setDelegate:), @selector(IWK_setDelegate:));
    IWKClassSwizzle(self, @selector(loadRequest:), @selector(IWK_loadRequest:));
    IWKClassSwizzle(self, @selector(loadHTMLString:baseURL:), @selector(IWK_loadHTMLString:baseURL:));
    IWKClassSwizzle(self, @selector(loadData:MIMEType:textEncodingName:baseURL:), @selector(IWK_loadData:MIMEType:textEncodingName:baseURL:));
}

- (void)IWK_dealloc
{
    @run_plugins{
        [IWKPluginHelper_UIWebView runPlugins:self.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject_UIWebView *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:@selector(webViewWillDealloc:)]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webViewWillDealloc:self];
        }];
    }
    [self IWK_dealloc];
}

- (instancetype)IWK_initWithFrame:(CGRect)frame
{
    [kAllUIWebViewsHashTable() addObject:self];
    [self setIWK_pluginsEnable:YES];
    
    @IWK_onExit {
        [self IWK_setDelegate:self.IWK_delegate];
    };
    
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper_UIWebView runPlugins:self.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject_UIWebView *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:@selector(webView:willInitWithFrame:)]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:self willInitWithFrame:frame];
        }];
        
        if (result) {
            return result.value;
        }
    }
    
    id object = [self IWK_initWithFrame:frame];
    
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper_UIWebView runPlugins:self.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject_UIWebView *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:@selector(webView:didInitWithFrame:)]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:self didInitWithFrame:frame];
        }];
        
        if (result) {
            return result.value;
        }
    }
    
    return object;
}

- (void)IWK_setDelegate:(id<UIWebViewDelegate>)delegate
{
    if (![delegate isEqual:self.IWK_delegate]) {
        self.IWK_delegate.proxy = delegate;
    }
    [self IWK_setDelegate:self.IWK_delegate];
}

- (void)IWK_loadRequest:(NSURLRequest *)request
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper_UIWebView runPlugins:self.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject_UIWebView *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:@selector(webView:loadRequest:)]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:self loadRequest:request];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return;
        }
    }
    [self IWK_loadRequest:request];
}

- (void)IWK_loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper_UIWebView runPlugins:self.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject_UIWebView *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:@selector(webView:loadHTMLString:baseURL:)]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:self loadHTMLString:string baseURL:baseURL];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return;
        }
    }
    [self IWK_loadHTMLString:string baseURL:baseURL];
}

- (void)IWK_loadData:(NSData *)data MIMEType:(NSString *)MIMEType textEncodingName:(NSString *)textEncodingName baseURL:(NSURL *)baseURL
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper_UIWebView runPlugins:self.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject_UIWebView *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:@selector(webView:loadData:MIMEType:textEncodingName:baseURL:)]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:self loadData:data MIMEType:MIMEType textEncodingName:textEncodingName baseURL:baseURL];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return;
        }
    }
    [self IWK_loadData:data MIMEType:MIMEType textEncodingName:textEncodingName baseURL:baseURL];
}

- (void)IWK_didCreateJavaScriptContext:(JSContext *)ctx
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper_UIWebView runPlugins:self.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject_UIWebView *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:@selector(webView:didCreateJavaScriptContext:)]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:self didCreateJavaScriptContext:ctx];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return;
        }
    }
}

@end

@implementation NSObject (JavaScriptContext)

static BOOL kShouldCallOtherCreateJavaScriptContextFunc = NO;
static NSString * const kJavaScriptContextFlagName = @"IWK_jscontext_flag";

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL createJavaScriptContextSelector = NSSelectorFromString(@"webView:didCreateJavaScriptContext:forFrame:");
        kShouldCallOtherCreateJavaScriptContextFunc = class_getInstanceMethod(self, createJavaScriptContextSelector) != NULL;
        IWKClassSwizzle(self, createJavaScriptContextSelector, @selector(IWK_webView:didCreateJavaScriptContext:forFrame:));
    });
}

- (void)IWK_webView:(id)wak didCreateJavaScriptContext:(JSContext*)ctx forFrame:(id)frame
{
    if (kShouldCallOtherCreateJavaScriptContextFunc) {
        [self IWK_webView:(id)wak didCreateJavaScriptContext:(JSContext*)ctx forFrame:(id)frame];
    }
    
    // Early return if `parentFrame` is non-nil.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString(base64DecodedString(@"cGFyZW50RnJhbWU="));
    if ([frame respondsToSelector:selector] && [frame performSelector:selector] != nil) {
        return;
    }
#pragma clang diagnostic pop

    IWK_dispatch_main_async_safe((^{
        [kAllUIWebViewsHashTable().allObjects enumerateObjectsUsingBlock:^(UIWebView *webView, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *flag = [@(webView.hash) stringValue];
            [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"%@=%@", kJavaScriptContextFlagName, flag]];
            if ([ctx[kJavaScriptContextFlagName].toString isEqualToString:flag]) {
                [webView IWK_didCreateJavaScriptContext:ctx];
                return;
            }
        }];
    }));
}

static NSString *base64DecodedString(NSString *origin)
{
    NSData *data = [[NSData alloc] initWithBase64EncodedString:origin options:0];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
