#import "BDWebForestPluginObject.h"

#import <IESForestKit/IESForestKit.h>
#import <IESForestKit/IESForestResponse.h>
#import <IESForestKit/IESForestEventTrackData.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import "BDWebForestURLProtocol.h"
#import "BDWebForestSchemeTaskDecorator.h"
#import "BDWebResourceMonitorEventType.h"
#import "BDWebForestUtil.h"

#import <BDWebKit/BDWebInterceptor.h>
#import <BDWebCore/WKWebView+Plugins.h>
#import <BDWebKit/WKWebView+BDInterceptor.h>
#import <BDWebKit/WKWebView+BDPrivate.h>
#import <BDWebKit/BDWebViewSchemeTaskHandler.h>
#import <BDWebKit/BDWebKitMainFrameModel.h>
#import <objc/runtime.h>

static NSString * const kObserverWebViewURLKeyPath = @"URL";
static NSString * const kForestAboutURLScheme = @"about";
static NSString * const kForestWaitFixURLHost = @"forestwaitfix";
static NSString * const kForestOriginURLQueryName = @"url";
static NSString * const kForestHandledHeader = @"x-custom-forest-handled";

@implementation WKWebViewConfiguration (BDWebForest)

- (BOOL)bdw_allowForestWaitFix
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setBdw_allowForestWaitFix:(BOOL)bdw_allowForestWaitFix
{
    if (bdw_allowForestWaitFix) {
        [self registerForestPluginObject];
    }
    objc_setAssociatedObject(self, @selector(bdw_allowForestWaitFix), @(bdw_allowForestWaitFix), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.bdw_skipFalconWaitFix = bdw_allowForestWaitFix;
}

- (BOOL)bdw_enableTTNetSchemeHandler
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setBdw_enableTTNetSchemeHandler:(BOOL)bdw_enableTTNetSchemeHandler
{
    if (bdw_enableTTNetSchemeHandler) {
        [[BDWebInterceptor sharedInstance] setupClassPluginForWebInterceptor];
        [self registerForestPluginObject];
    }
    objc_setAssociatedObject(self, @selector(bdw_enableTTNetSchemeHandler), @(bdw_enableTTNetSchemeHandler), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)bdw_enableForestInterceptorForTTNetSchemeHandler
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setBdw_enableForestInterceptorForTTNetSchemeHandler:(BOOL)bdw_enableForestInterceptorForTTNetSchemeHandler
{
    if (bdw_enableForestInterceptorForTTNetSchemeHandler) {
        [self registerForestPluginObject];
    }
    objc_setAssociatedObject(self, @selector(bdw_enableForestInterceptorForTTNetSchemeHandler), @(bdw_enableForestInterceptorForTTNetSchemeHandler), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -- private

- (void)registerForestPluginObject
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [WKWebView IWK_loadPlugin:[BDWebForestPluginObject new]];
    });
}

@end

@implementation WKWebView (BDWebForest)

- (BOOL)bdw_enableForestInterceptorForTTNetSchemeHandler
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setBdw_enableForestInterceptorForTTNetSchemeHandler:(BOOL)bdw_enableForestInterceptorForTTNetSchemeHandler
{
    if (bdw_enableForestInterceptorForTTNetSchemeHandler) {
        // this register method will ensure only register once
        [self bdw_registerURLProtocolClass:[BDWebForestURLProtocol class]];
    }
    objc_setAssociatedObject(self, @selector(bdw_enableForestInterceptorForTTNetSchemeHandler), @(bdw_enableForestInterceptorForTTNetSchemeHandler), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation NSURLRequest (BDWebForestPlugin)

- (BOOL)bdw_skipForest
{
    NSDictionary<NSString *, NSString *> *headers = self.allHTTPHeaderFields;
    NSString *skipFalcon = [headers objectForKey:kForestHandledHeader];
    if (skipFalcon) {
        return YES;
    } else {
        return NO;
    }
}

@end

@implementation NSMutableURLRequest (BDWebForestPlugin)

- (void)setBdw_skipForest:(BOOL)BDW_skipForest
{
    if (BDW_skipForest) {
        [self setValue:[NSString stringWithFormat:@"%@", @(YES)] forHTTPHeaderField:kForestHandledHeader];
    }
}

@end

@implementation NSURL (Falcon)

- (BOOL)forest_isWaitFixURL
{
    return [self.scheme isEqualToString:kForestAboutURLScheme] && [self.host isEqualToString:kForestWaitFixURLHost];
}

@end

@interface BDWForestNavigationDelegateProxy : NSObject<WKNavigationDelegate>

@property (nonatomic) dispatch_semaphore_t semaphore;
@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, weak) id navigationDelegateProxy;
@property (nonatomic, strong) NSCache *cache;
@property (nonatomic, copy) NSString *willLoadURLString;

@end

@implementation WKWebView (BDWAllowFixWKScheme)

- (BDWForestNavigationDelegateProxy *)forestProxy
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setForestProxy:(BDWForestNavigationDelegateProxy *)forestProxy
{
    objc_setAssociatedObject(self, @selector(forestProxy), forestProxy, OBJC_ASSOCIATION_RETAIN);
}

@end

@implementation BDWebForestPluginObject

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didInitWithFrame:(CGRect)rect configuration:(WKWebViewConfiguration *)configuration
{
    
    if (@available(iOS 12.0, *)) {

        if (configuration.bdw_enableTTNetSchemeHandler) {
            [webView bdw_registerSchemeHandlerClass:[BDWebViewSchemeTaskHandler class]];
        }

        if (configuration.bdw_enableForestInterceptorForTTNetSchemeHandler) {
            webView.bdw_enableForestInterceptorForTTNetSchemeHandler = @(YES);
            // This method will ensure decorator BDWebForestSchemeTaskDecorator only register once.
            [[BDWebInterceptor sharedInstance] registerCustomRequestDecorator:[BDWebForestSchemeTaskDecorator class]];
        }

        /// when bdw_enableInterceptor set, will enable URLSchemeHandler; Don't use waitfix for this situation
        if (configuration.bdw_enableInterceptor) {
            return IWKPluginHandleResultContinue;
        }
    }

    if (configuration.bdw_allowForestWaitFix) {
        webView.forestProxy = [BDWForestNavigationDelegateProxy new];
        webView.forestProxy.webView = webView;
        
        [webView addObserver:webView.forestProxy forKeyPath:kObserverWebViewURLKeyPath options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    }

    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webViewWillDealloc:(WKWebView *)webView
{
    if (webView.forestProxy) {
        [webView removeObserver:webView.forestProxy forKeyPath:kObserverWebViewURLKeyPath];
    }
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultObj<WKNavigation *> *)webView:(WKWebView *)webView loadRequest:(NSURLRequest *)request
{
    if (!webView.forestProxy || request.bdw_skipForest || request.URL.forest_isWaitFixURL) {
        return IWKPluginHandleResultContinue;
    }
    // 记录主文档加载过程信息
    BDWebKitMainFrameModel *mainFrameModel = [[BDWebKitMainFrameModel alloc] init];
    mainFrameModel.mainFrameStatus = BDWebKitMainFrameStatusUseForestPlugin;

    [[IESForestKit sharedInstance] fetchResourceAsync:request.URL.absoluteString parameters:nil completion:^(IESForestResponse * _Nullable response, NSError * _Nullable error) {
        if (response && response.eventTrackData) {
            NSMutableDictionary *monitorData = [[NSMutableDictionary alloc] init];
            [monitorData addEntriesFromDictionary:response.eventTrackData.loaderInfo];
            [monitorData addEntriesFromDictionary:response.eventTrackData.resourceInfo];
            [monitorData addEntriesFromDictionary:response.eventTrackData.metricInfo];
            [monitorData addEntriesFromDictionary:response.eventTrackData.errorInfo];
            monitorData[kBDWebviewResSceneKey] = @"web_main_document";
            mainFrameModel.mainFrameStatModel = [monitorData copy];
        }
        if (error || (response && response.data.length == 0)) {
            mainFrameModel.loadFinishWithLocalData = NO;
            NSURL *newURL = request.URL;
            if ([IESForestKit isCDNMultiVersionResource:request.URL.absoluteString]) {
                NSDictionary *commonParams = [IESForestKit cdnMultiVersionCommonParameters];
                newURL = [BDWebForestUtil urlWithURLString:request.URL.absoluteString queryParameters:commonParams];
            }

            NSMutableURLRequest* newRequest = [NSMutableURLRequest requestWithURL:newURL];
            newRequest.bdw_skipForest = @(YES);
            webView.forestProxy.willLoadURLString = newURL.absoluteString;
            webView.bdw_mainFrameModelRecord = mainFrameModel;
            [webView bdw_loadRequest:newRequest];
        } else {
            [webView.forestProxy.cache setObject:response forKey:request.URL.absoluteString];
            mainFrameModel.loadFinishWithLocalData = !(response.sourceType == IESForestDataSourceTypeCDNOnline || response.sourceType == IESForestDataSourceTypeGeckoUpdate);
            webView.bdw_mainFrameModelRecord = mainFrameModel;
            [webView bdw_loadRequest:[self convertToWaitFixRequest:request]];
        }
    }];
    return IWKPluginHandleResultBreak;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (webView.forestProxy) {
        if (navigationAction.request.URL.forest_isWaitFixURL) {
            decisionHandler(WKNavigationActionPolicyAllow);
            return IWKPluginHandleResultBreak;
        }

        if ([navigationAction.request.URL.absoluteString isEqualToString:webView.forestProxy.willLoadURLString]) {
            decisionHandler(WKNavigationActionPolicyAllow);
            return IWKPluginHandleResultBreak;
        }

        BOOL isRedirectForMainFrame = navigationAction.targetFrame.isMainFrame && (navigationAction.navigationType == WKNavigationTypeLinkActivated ||  navigationAction.navigationType == WKNavigationTypeOther);
        BOOL isReloadForMainFrame = navigationAction.targetFrame.isMainFrame && navigationAction.navigationType == WKNavigationTypeReload;

        if (isReloadForMainFrame || isRedirectForMainFrame) {
            decisionHandler(WKNavigationActionPolicyCancel);
            [webView bdw_loadRequest:navigationAction.request];
            return IWKPluginHandleResultBreak;
        }
    }
    
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    if (webView.URL.forest_isWaitFixURL && webView.forestProxy) {
        dispatch_semaphore_signal(webView.forestProxy.semaphore);
    }
    return IWKPluginHandleResultContinue;
}

#pragma mark - private

- (NSURLRequest *)convertToWaitFixRequest:(NSURLRequest *)request
{
    NSURLComponents *fixedComponent = [[NSURLComponents alloc] init];
    fixedComponent.scheme = kForestAboutURLScheme;
    fixedComponent.host = kForestWaitFixURLHost;
    fixedComponent.queryItems = @[[[NSURLQueryItem alloc] initWithName:kForestOriginURLQueryName value:request.URL.absoluteString]];
    return [NSURLRequest requestWithURL:fixedComponent.URL];
}

@end

@implementation BDWForestNavigationDelegateProxy

- (instancetype)init
{
    self = [super init];
    if (self) {
        _semaphore = dispatch_semaphore_create(0);
        _cache = [[NSCache alloc] init];
    }
    return self;
}

#pragma mark - KVO handlers

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    NSURL *url = change[NSKeyValueChangeNewKey];
    if ([keyPath isEqualToString:kObserverWebViewURLKeyPath] && [url isKindOfClass:NSURL.class] && url.forest_isWaitFixURL) {
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
        __block NSURL *fixedURL = nil;
        [components.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.name isEqualToString:kForestOriginURLQueryName]) {
                fixedURL = [NSURL URLWithString:obj.value];
                *stop = YES;
            }
        }];

        if ([self.willLoadURLString isEqualToString:fixedURL.absoluteString]) {
            return;
        }
        
        id<IESForestResponseProtocol> response = [self.cache objectForKey:fixedURL.absoluteString];
        if (response) {
            [self.cache removeObjectForKey:fixedURL.absoluteString];
        }

        NSString *falconHtml = [[NSString alloc] initWithData:response.data encoding:NSUTF8StringEncoding];
        
        void (^loadHTMLString)(WKWebView *, NSString *, NSURL *) = ^(WKWebView *webView, NSString *HTMLString, NSURL *baseURL){
            [webView loadHTMLString:HTMLString baseURL:baseURL];
        };

        if (falconHtml.length > 0) {
            self.willLoadURLString = fixedURL.absoluteString;
            if ([self.webView.backForwardList.currentItem.URL.absoluteString isEqualToString:url.absoluteString]) {
                loadHTMLString(self.webView, falconHtml, fixedURL);
            } else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
                    dispatch_semaphore_wait(self.semaphore, time);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        loadHTMLString(self.webView, falconHtml, fixedURL);
                    });
                });
            }
        } else {
            NSCAssert(NO, @"[GeckoForest] offline data disappeared!");
            [self.webView bdw_loadRequest:[NSURLRequest requestWithURL:fixedURL]];
        }
    }
}

@end
