//
//  WKWebView+IESFalconWebView.m
//  IESWebKit
//
//  Created by li keliang on 2018/12/27.
//

#import "IWKFalconPluginObject.h"
#import "IESFalconManager.h"
#import "IESFalconManager+InterceptionDelegate.h"
#import "IESFalconStatRecorder.h"
#import "IWKFalconPluginObject.h"
#import "IESFalconDebugLogger.h"
#import "BDWebInterceptor.h"
#import "WKWebView+BDPrivate.h"
#import "BDWebKitMainFrameModel.h"
#import "BDWebResourceMonitorEventType.h"

#import <objc/runtime.h>

static NSString * const kObserverWebViewURLKeyPath = @"URL";
static NSString * const kFalconAboutURLScheme = @"about";
static NSString * const kFalconWaitFixURLHost = @"waitfix";
static NSString * const kFalconOriginURLQueryName = @"url";
static NSString * const kFalconHTTPURLScheme = @"http";
static const void * kFalconRecursiveURLKey;

@implementation WKWebView(QI)

- (IWKFalconInnerHandle)falcon_innerHandle
{
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (void)setFalcon_innerHandle:(IWKFalconInnerHandle)falcon_innerHandle
{
    objc_setAssociatedObject(self, @selector(falcon_innerHandle), @(falcon_innerHandle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation NSURLRequest (IWKFalconPlugin)

- (BOOL)IWK_skipFalcon
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setIWK_skipFalcon:(BOOL)IWK_skipFalcon
{
    objc_setAssociatedObject(self, @selector(IWK_skipFalcon), @(IWK_skipFalcon), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation NSURL (Falcon)

- (BOOL)falcon_isWaitFixURL
{
    return [self.scheme isEqualToString:kFalconAboutURLScheme] && [self.host isEqualToString:kFalconWaitFixURLHost];
}

@end

@interface IESFalconNavigationDelegateProxy : NSObject<WKNavigationDelegate>

@property (nonatomic) dispatch_semaphore_t semaphore;
@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, weak) id navigationDelegateProxy;

@end

@implementation WKWebView (IESAllowFixWKScheme)

+ (BOOL)falcon_allowFixWKScheme
{
    return IESFalconManager.interceptionEnable && !IESFalconManager.interceptionWKHttpScheme;
}

#pragma mark - Helpers

- (IESFalconNavigationDelegateProxy *)falconProxy
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setFalconProxy:(IESFalconNavigationDelegateProxy *)falconProxy
{
    objc_setAssociatedObject(self, @selector(falconProxy), falconProxy, OBJC_ASSOCIATION_RETAIN);
}

@end

@implementation IWKFalconPluginObject

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didInitWithFrame:(CGRect)rect configuration:(WKWebViewConfiguration *)configuration
{
    if (@available(iOS 12.0, *)) {
        if (configuration.bdw_enableInterceptor) {
            return IWKPluginHandleResultContinue;
        }
    }

    if (configuration.bdw_skipFalconWaitFix) {
        return IWKPluginHandleResultContinue;
    }
    
    webView.falconProxy = [[IESFalconNavigationDelegateProxy alloc] init];
    webView.falconProxy.webView = webView;
    
    [webView addObserver:webView.falconProxy forKeyPath:kObserverWebViewURLKeyPath options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webViewWillDealloc:(WKWebView *)webView
{
    if (webView.falconProxy) {
        [webView removeObserver:webView.falconProxy forKeyPath:kObserverWebViewURLKeyPath];
    }
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultObj<WKNavigation *> *)webView:(WKWebView *)webView loadRequest:(NSURLRequest *)request
{
    if (webView.falconProxy) {
        [IESFalconManager decoratedFalconUserAgentWithWebView:webView];
    }
    
    if (!WKWebView.falcon_allowFixWKScheme || !webView.falconProxy || request.IWK_skipFalcon) {
        return IWKPluginHandleResultContinue;
    }
    
    // record main frame model
    BDWebKitMainFrameModel *mainFrameModel = nil;
    if (!request.URL.falcon_isWaitFixURL) {
        mainFrameModel = [[BDWebKitMainFrameModel alloc] init];
        mainFrameModel.mainFrameStatus = BDWebKitMainFrameStatusUseFalconPlugin;
        mainFrameModel.latestWebViewURLString = request.URL.absoluteString;
    }
    
    id<IESFalconMetaData> falconMetaData = [IESFalconManager falconMetaDataForURLRequest:request
                                                                                 webView:webView];
    NSString *html = [[NSString alloc] initWithData:falconMetaData.falconData encoding:NSUTF8StringEncoding];
    BOOL hasFalconHtml = (html.length > 0);
    
    if (mainFrameModel) {
        mainFrameModel.loadFinishWithLocalData = hasFalconHtml;
        
        NSMutableDictionary *falconPluginData = [[NSMutableDictionary alloc] init];
        if (request.bdw_falconProcessInfoRecord) {
            [falconPluginData addEntriesFromDictionary:[request.bdw_falconProcessInfoRecord copy]];
        }
        falconPluginData[kBDWebviewResSceneKey] = @"web_main_document";
        falconPluginData[kBDWebviewResLoaderNameKey] = @"falconPlugin";
        mainFrameModel.mainFrameStatModel = [falconPluginData copy];
        
        webView.bdw_mainFrameModelRecord = mainFrameModel;
    }
    
    if (webView.falcon_innerHandle & IWKFalconInnerHandleFixAssociate) {
        if ([request.URL.scheme hasPrefix:@"http"]) {
            objc_setAssociatedObject(webView.falconProxy, kFalconRecursiveURLKey, nil, OBJC_ASSOCIATION_COPY);
        }
    }
    
    [IESFalconManager callingOutFalconInterceptedRequest:request willLoadFromCache:hasFalconHtml];
    
    if (hasFalconHtml) {
        // encode for URLPath
        NSURLComponents *fixedComponent = [[NSURLComponents alloc] init];
        fixedComponent.scheme = kFalconAboutURLScheme;
        fixedComponent.host = kFalconWaitFixURLHost;
        fixedComponent.queryItems = @[[[NSURLQueryItem alloc] initWithName:kFalconOriginURLQueryName value:request.URL.absoluteString]];
        IESFalconDebugLog(@"Load request 【URL => %@】", fixedComponent.URL.absoluteString);
        return IWKPluginHandleResultWrapValue([webView bdw_loadRequest:[NSURLRequest requestWithURL:fixedComponent.URL]]);
    } else {
        if (falconMetaData) {
            IESFalconStatModel *statModel = falconMetaData.statModel;
            statModel.resourceURLString = request.URL.absoluteString;
            [IESFalconStatRecorder recordFalconStat:[statModel statDictionary]];
        }
        IESFalconDebugLog(@"Load request 【URL => %@】", request.URL.absoluteString);
        return IWKPluginHandleResultContinue;
    }
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (webView.falconProxy) {
        if (navigationAction.request.URL.falcon_isWaitFixURL) {
            decisionHandler(WKNavigationActionPolicyAllow);
            return IWKPluginHandleResultBreak;
        }
        
        if ([navigationAction.request.URL.absoluteString isEqualToString:objc_getAssociatedObject(webView.falconProxy, kFalconRecursiveURLKey)]) {
            
            if (!(webView.falcon_innerHandle & IWKFalconInnerHandleFixAssociate)) {
                objc_setAssociatedObject(webView.falconProxy, kFalconRecursiveURLKey, nil, OBJC_ASSOCIATION_COPY);
            }
            
            decisionHandler(WKNavigationActionPolicyAllow);
            return IWKPluginHandleResultBreak;
        }
    }
    
    if (WKWebView.falcon_allowFixWKScheme && webView.falconProxy) {
        
        BOOL isRedirectForMainFrame = navigationAction.targetFrame.isMainFrame && (navigationAction.navigationType == WKNavigationTypeLinkActivated ||  navigationAction.navigationType == WKNavigationTypeOther);
        BOOL isReloadForMainFrame = navigationAction.targetFrame.isMainFrame && navigationAction.navigationType == WKNavigationTypeReload;
        BOOL allowedFalconFilter = isRedirectForMainFrame || isReloadForMainFrame;
        
        if (allowedFalconFilter) {
            if ([IESFalconManager falconMetaDataForURLRequest:navigationAction.request
                                                      webView:webView].falconData.length > 0) {
                decisionHandler(WKNavigationActionPolicyCancel);
                [webView bdw_loadRequest:navigationAction.request];
                return IWKPluginHandleResultBreak;
            }
        }
    }
    
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    if (webView.URL.falcon_isWaitFixURL && webView.falconProxy) {
        dispatch_semaphore_signal(webView.falconProxy.semaphore);
    }
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void(^)(WKNavigationResponsePolicy))decisionHandler
{
    if (!WKWebView.falcon_allowFixWKScheme || !webView.falconProxy) {
        return IWKPluginHandleResultContinue;
    }

    if (webView.bdw_mainFrameModelRecord.mainFrameStatModel) {
        NSMutableDictionary *mainFrameStateModel = [webView.bdw_mainFrameModelRecord.mainFrameStatModel mutableCopy];
        mainFrameStateModel[kBDWebviewResStateKey] = @"success";
        if ([mainFrameStateModel[kBDWebviewResFromKey] isEqualToString:@"cdn"]) {
            mainFrameStateModel[kBDWebviewResLoadFinishKey] = @([NSDate date].timeIntervalSince1970 * 1000);
        }
        webView.bdw_mainFrameModelRecord.mainFrameStatModel = mainFrameStateModel;
    }
    return IWKPluginHandleResultContinue;
}

@end

@implementation IESFalconNavigationDelegateProxy

- (instancetype)init
{
    self = [super init];
    if (self) {
        _semaphore = dispatch_semaphore_create(0);
    }
    return self;
}

#pragma mark - KVO handlers

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    NSURL *url = change[NSKeyValueChangeNewKey];
    if ([keyPath isEqualToString:kObserverWebViewURLKeyPath] && [url isKindOfClass:NSURL.class] && url.falcon_isWaitFixURL) {
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
        __block NSURL *fixedURL = nil;
        [components.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.name isEqualToString:kFalconOriginURLQueryName]) {
                fixedURL = [NSURL URLWithString:obj.value];
                *stop = YES;
            }
        }];
        
        if (objc_getAssociatedObject(self, kFalconRecursiveURLKey)) {
            return;
        }
        
        NSDate *start = [NSDate date];
        id<IESFalconMetaData> falconMetaData = [IESFalconManager falconMetaDataForURLRequest:[NSURLRequest requestWithURL:fixedURL]
                                                                                     webView:self.webView];
        NSString *falconHtml = [[NSString alloc] initWithData:falconMetaData.falconData encoding:NSUTF8StringEncoding];
        
        void (^loadHTMLString)(WKWebView *, NSString *, NSURL *) = ^(WKWebView *webView, NSString *HTMLString, NSURL *baseURL){
            IESFalconDebugLog(@"Load HTML 【baseURL => %@】", baseURL.absoluteString);
            [webView loadHTMLString:HTMLString baseURL:baseURL];
            
            IESFalconStatModel *statModel = falconMetaData.statModel;
            statModel.resourceURLString = baseURL.absoluteString;
            statModel.offlineDuration = (NSInteger)([[NSDate date] timeIntervalSinceDate:start] * 1000);
            [IESFalconStatRecorder recordFalconStat:[statModel statDictionary]];
        };
        
        if (falconHtml.length > 0) {
            objc_setAssociatedObject(self, kFalconRecursiveURLKey, fixedURL.absoluteString, OBJC_ASSOCIATION_COPY);
            if ([self.webView.backForwardList.currentItem.URL.absoluteString isEqualToString:url.absoluteString]) {
                loadHTMLString(self.webView, falconHtml, fixedURL);
            } else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    dispatch_time_t time = self.webView.falcon_innerHandle & IWKFalconInnerHandleWaitTimeforever ? DISPATCH_TIME_FOREVER : dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
                    dispatch_semaphore_wait(self.semaphore, time);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        loadHTMLString(self.webView, falconHtml, fixedURL);
                    });
                });
            }
        } else {
            NSCAssert(NO, @"[Falcon] An inner error occurred.");
            
            [self.webView bdw_loadRequest:[NSURLRequest requestWithURL:fixedURL]];
        }
    }
}

@end
