//
//  WKWebView+WebCore.m
//  BDWebCore
//
//  Created by li keliang on 2019/7/19.
//

#import "WKWebView+Plugins.h"
#import "IWKPluginObject.h"
#import "IWKUtils.h"
#import "IWKWebViewPluginHelper.h"
#import "IWKPluginNavigationDelegateProxy.h"
#import "IWKPluginUIDelegateProxy.h"
#import "BDWPluginScriptMessageHandlerProxy.h"
#import <objc/runtime.h>

#define run_plugins IWK_keywordify if (self.IWK_pluginsEnable)

@interface BDWebViewWeakWrapper : NSObject

- (instancetype)initWithWebView:(WKWebView *)webView NS_DESIGNATED_INITIALIZER;

@property(nonatomic, weak) WKWebView *webView;

@end

@implementation BDWebViewWeakWrapper

- (instancetype)init {
    return [self initWithWebView:nil];
}

- (instancetype)initWithWebView:(WKWebView *)webView {
    self = [super init];
    if (self) {
       self.webView = webView;
    }
    return self;
}

@end

@implementation WKWebView(Delegates)

- (IWKPluginNavigationDelegateProxy *)IWK_navigationDelegate
{
    if (!objc_getAssociatedObject(self, _cmd)) {
        IWKPluginNavigationDelegateProxy *proxy = [IWKPluginNavigationDelegateProxy new];
        proxy.webView = self;
        objc_setAssociatedObject(self, _cmd, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return objc_getAssociatedObject(self, _cmd);
}

- (IWKPluginUIDelegateProxy *)IWK_UIDelegate
{
    if (!objc_getAssociatedObject(self, _cmd)) {
        IWKPluginUIDelegateProxy *proxy = [IWKPluginUIDelegateProxy new];
        proxy.webView = self;
        objc_setAssociatedObject(self, _cmd, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return objc_getAssociatedObject(self, _cmd);
}


@end

@interface WKUserContentController (WebCore)

@property(nonatomic, strong) BDWebViewWeakWrapper *bdw_webViewWeakWrapper;

@end

@implementation WKUserContentController (WebCore)

+ (void)load {
    IWKClassSwizzle(self, @selector(addScriptMessageHandler:name:), @selector(bdw_addScriptMessageHandler:name:));
}

- (void)bdw_addScriptMessageHandler:(id<WKScriptMessageHandler>)scriptMessageHandler name:(NSString *)name {
    __auto_type handler = scriptMessageHandler;
    if (self.bdw_webViewWeakWrapper.webView.IWK_pluginsEnable){
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.bdw_webViewWeakWrapper.webView.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin addScriptMessageHandler:scriptMessageHandler name:name];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return;
        }
        
        __auto_type proxy = BDWPluginScriptMessageHandlerProxy.new;
        proxy.realHandler = scriptMessageHandler;
        proxy.webView = self.bdw_webViewWeakWrapper.webView;
        handler = proxy;
    }
    
    [self bdw_addScriptMessageHandler:handler name:name];
}

- (void)setBdw_webViewWeakWrapper:(BDWebViewWeakWrapper *)bdw_webViewWeakWrapper {
    objc_setAssociatedObject(self, @selector(bdw_webViewWeakWrapper), bdw_webViewWeakWrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BDWebViewWeakWrapper *)bdw_webViewWeakWrapper {
    return objc_getAssociatedObject(self, _cmd);
}

@end

@interface WKWebViewConfiguration (WebCore)

@property(nonatomic, strong) BDWebViewWeakWrapper *bdw_webViewWeakWrapper;

@end

@implementation WKWebViewConfiguration (WebCore)

+ (void)load {
    IWKClassSwizzle(self, @selector(setUserContentController:), @selector(bdw_setUserContentController:));
    IWKClassSwizzle(self, @selector(userContentController), @selector(bdw_userContentController));
    IWKClassSwizzle(self, @selector(copyWithZone:), @selector(bdw_copyWithZone:));
}

- (id)bdw_copyWithZone:(NSZone *)zone {
    WKWebViewConfiguration *configuration = [self bdw_copyWithZone:zone];
    configuration.bdw_webViewWeakWrapper = self.bdw_webViewWeakWrapper;
    return configuration;
}

- (void)bdw_setUserContentController:(WKUserContentController *)userContentController {
    userContentController.bdw_webViewWeakWrapper = [[BDWebViewWeakWrapper alloc] initWithWebView:self.bdw_webViewWeakWrapper.webView];
    [self bdw_setUserContentController:userContentController];
}

- (WKUserContentController *)bdw_userContentController {
    __auto_type userContentController = self.bdw_userContentController;
    userContentController.bdw_webViewWeakWrapper = [[BDWebViewWeakWrapper alloc] initWithWebView:self.bdw_webViewWeakWrapper.webView];
    return userContentController;
}

- (void)setBdw_webViewWeakWrapper:(BDWebViewWeakWrapper *)bdw_webViewWeakWrapper {
    objc_setAssociatedObject(self, @selector(bdw_webViewWeakWrapper), bdw_webViewWeakWrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BDWebViewWeakWrapper *)bdw_webViewWeakWrapper {
    return objc_getAssociatedObject(self, _cmd);
}

@end

@implementation WKWebView (WebCore)

+ (void)load
{
    IWKClassSwizzle(self, NSSelectorFromString(@"dealloc"), @selector(IWK_dealloc));
    IWKClassSwizzle(self, @selector(initWithFrame:configuration:), @selector(IWK_initWithFrame:configuration:));
    IWKClassSwizzle(self, @selector(setNavigationDelegate:), @selector(IWK_setNavigationDelegate:));
    IWKClassSwizzle(self, @selector(setUIDelegate:), @selector(IWK_setUIDelegate:));
    IWKClassSwizzle(self, @selector(loadRequest:), @selector(IWK_loadRequest:));
    IWKClassSwizzle(self, @selector(loadHTMLString:baseURL:), @selector(IWK_loadHTMLString:baseURL:));
    IWKClassSwizzle(self, @selector(evaluateJavaScript:completionHandler:), @selector(bdw_evaluateJavaScript:completionHandler:));

    if (@available(iOS 9.0, *)) {
        IWKClassSwizzle(self, @selector(loadFileURL:allowingReadAccessToURL:), @selector(IWK_loadFileURL:allowingReadAccessToURL:));
        IWKClassSwizzle(self, @selector(loadData:MIMEType:characterEncodingName:baseURL:), @selector(IWK_loadData:MIMEType:characterEncodingName:baseURL:));
    }
}

- (void)IWK_dealloc
{
    @run_plugins{
        [IWKPluginHelper runPlugins:self.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:@selector(webViewWillDealloc:)]) {
                return nil;
            }
            return [plugin webViewWillDealloc:self];
        }];
    }
    [self IWK_dealloc];
}

- (instancetype)IWK_initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration
{
    [self setIWK_pluginsEnable:YES];
    
    @IWK_onExit {
        [self IWK_setNavigationDelegate:self.IWK_navigationDelegate];
        [self IWK_setUIDelegate:self.IWK_UIDelegate];
    };
    
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:@selector(webView:willInitWithFrame:configuration:)]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:self willInitWithFrame:frame configuration:configuration];
        }];
        
        if (result) {
            return result.value;
        }
    }
    configuration.bdw_webViewWeakWrapper = [[BDWebViewWeakWrapper alloc] initWithWebView:self];
    id object = [self IWK_initWithFrame:frame configuration:configuration];
    
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:@selector(webView:didInitWithFrame:configuration:)]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:self didInitWithFrame:frame configuration:configuration];
        }];
        
        if (result) {
            return result.value;
        }
    }

    return object;
}

- (void)IWK_setNavigationDelegate:(id<WKNavigationDelegate>)navigationDelegate
{
    if (![navigationDelegate isEqual:self.IWK_navigationDelegate]) {
        self.IWK_navigationDelegate.proxy = navigationDelegate;
    }
    [self IWK_setNavigationDelegate:self.IWK_navigationDelegate];
}

- (void)IWK_setUIDelegate:(id<WKUIDelegate>)UIDelegate
{
    if (![UIDelegate isEqual:self.IWK_UIDelegate]) {
        self.IWK_UIDelegate.proxy = UIDelegate;
    }
    [self IWK_setUIDelegate:self.IWK_UIDelegate];
}

- (WKNavigation *)IWK_loadRequest:(NSURLRequest *)request
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:@selector(webView:loadRequest:)]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:self loadRequest:request];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return result.value;
        }
    }
    return [self IWK_loadRequest:request];
}

- (WKNavigation *)IWK_loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:@selector(webView:loadHTMLString:baseURL:)]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:self loadHTMLString:string baseURL:baseURL];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return result.value;
        }
    }
    return [self IWK_loadHTMLString:string baseURL:baseURL];
}

- (WKNavigation *)IWK_loadFileURL:(NSURL *)URL allowingReadAccessToURL:(NSURL *)readAccessURL API_AVAILABLE(macosx(10.11), ios(9.0))
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:@selector(webView:loadFileURL:allowingReadAccessToURL:)]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:self loadFileURL:URL allowingReadAccessToURL:readAccessURL];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return result.value;
        }
    }
    return [self IWK_loadFileURL:URL allowingReadAccessToURL:readAccessURL];
}

- (WKNavigation *)IWK_loadData:(NSData *)data MIMEType:(NSString *)MIMEType characterEncodingName:(NSString *)characterEncodingName baseURL:(NSURL *)baseURL API_AVAILABLE(macosx(10.11), ios(9.0))
{
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:@selector(webView:loadData:MIMEType:characterEncodingName:baseURL:)]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin webView:self loadData:data MIMEType:MIMEType characterEncodingName:characterEncodingName baseURL:baseURL];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            return result.value;
        }
    }
    return [self IWK_loadData:data MIMEType:MIMEType characterEncodingName:characterEncodingName baseURL:baseURL];
}

- (void)bdw_evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id _Nullable, NSError * _Nullable))completionHandler {
    __auto_type wrappedJavaScriptString = javaScriptString;
    __auto_type wrappedCompletionHandler = completionHandler;
    @run_plugins{
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:_cmd]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin evaluateJavaScript:javaScriptString completionHandler:completionHandler];
        }];
        
        if (result.flow == IWKPluginHandleResultFlowBreak) {
            if ([result.value isKindOfClass:NSArray.class]) {
                NSArray *retArr = result.value;
                if (retArr.count == 2) {
                    wrappedJavaScriptString = retArr[0];
                    wrappedCompletionHandler = retArr[1];
                }
            }
        }
    }
    [self bdw_evaluateJavaScript:wrappedJavaScriptString completionHandler:wrappedCompletionHandler];
}

@end


