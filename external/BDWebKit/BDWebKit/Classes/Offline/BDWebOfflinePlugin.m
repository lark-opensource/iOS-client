//
//  BDWebOfflinePlugin.m
//  BDWebKit
//
//  Created by wealong on 2019/12/5.
//

#import "BDWebOfflinePlugin.h"
#import "WKWebView+BDOffline.h"
#import "WKWebView+BDPrivate.h"
#import "BDPreloadCachedResponse+Falcon.h"
#import "BDWebViewOfflineStatusLogicControl.h"
#import "BDWebViewOfflineManager.h"
#import "BDWebKitSettingsManger.h"
#import <BDPreloadSDK/BDWebViewPreloadManager.h>
#import <BDWebKit/IESFalconManager.h>
#import <BDWebKit/IESFalconURLProtocol.h>
#import <BDWebKit/WKUserContentController+BDWebViewHookJS.h>

@interface BDWebOfflinePlugin ()

@end

@implementation BDWebOfflinePlugin

#pragma mark - WebView LifeCycle

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didInitWithFrame:(CGRect)rect configuration:(WKWebViewConfiguration *)configuration {
    if (webView.bdw_offlineType != BDWebViewOfflineTypeTaskScheme) {
        [BDWebViewOfflineStatusLogicControl addWebViewWhenCreate:webView];
    }
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultObj<WKNavigation *> *)webView:(WKWebView *)webView loadRequest:(NSURLRequest *)request {
    webView.didFinishOrFail = NO;
    webView.bdw_hitPreload = NO;
    if (webView.bdw_offlineType == BDWebViewOfflineTypeTaskSchemeResourLoader) {
        Class rlURLProtoclClz = NSClassFromString(@"BDWebResourceLoaderURLProtocol");
        NSCAssert(rlURLProtoclClz != nil,
                  @"could not find BDWebResourceLoaderURLProtocol, make sure you depend BDWebKit/ResourceLoader/TTNet");
        
        if (rlURLProtoclClz) {
            [webView bdw_registerURLProtocolClass:rlURLProtoclClz];
        }
    } else if (webView.bdw_offlineType == BDWebViewOfflineTypeTaskScheme) {
        if ([[BDWebViewPreloadManager sharedInstance] responseForURLString:request.URL.absoluteString] ||
            [IESFalconManager shouldInterceptForRequest:request]) {
            id<IESFalconMetaData> metaData = [IESFalconManager falconMetaDataForURLRequest:request];
            [IESFalconManager webView:webView loadRequest:request metaData:metaData];
            webView.bdw_hitPreload = YES;
            [webView bdw_registerURLProtocolClass:IESFalconURLProtocol.class];
        }
    } else if ([[BDWebViewPreloadManager sharedInstance] responseForURLString:request.URL.absoluteString] && webView.bdw_offlineType != BDWebViewOfflineTypeTaskScheme) {
        webView.bdw_hitPreload = YES;
        
        webView.bdw_offlineType = BDWebViewOfflineTypeBetweenStartAndFinishLoad;
    }
    
    if (webView.bdw_offlineType == BDWebViewOfflineTypeBetweenStartAndFinishLoad &&
        [BDWebKitSettingsManger checkOfflineWholeLife:request.URL.absoluteString]) {
        webView.bdw_offlineType = BDWebViewOfflineTypeWholeLife;
    }
    
    BOOL needHook = NO;
    // 配置当前离线化开关
    if (webView.bdw_offlineType == BDWebViewOfflineTypeBetweenStartAndFinishLoad
        || webView.bdw_offlineType == BDWebViewOfflineTypeWholeLife) {
        [self startOffline:webView];
        
        needHook = YES;
    } else if (webView.channelInterceptorList.count>0 && webView.bdw_offlineType == BDWebViewOfflineTypeChannelInterceptor  && [BDWebKitSettingsManger checkOfflineChannelInterceptor]) {
        if ([BDWebKitSettingsManger checkOfflineChannelInterceptorInjectJS]) {
            needHook = YES;
        }
        [BDWebViewOfflineManager registerCustomInterceptorList:webView.channelInterceptorList] ;
    } else {
        [self stopOffline:webView];
    }
        
    if (needHook) {
        [webView.configuration.userContentController bdw_installHookAjax];
    }
    
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *URL = navigationAction.request.URL;
    
    // 关闭离线化
    if ([URL.scheme isEqualToString:@"bytedance"] && [URL.host isEqualToString:@"disable_offline"]) {
        IESFalconManager.interceptionEnable = NO;
        [webView evaluateJavaScript:@";(function (){window._is_offline_closed=1;window._setbackXML_&&window._setbackXML_();})();" completionHandler:NULL];
        if (decisionHandler) {
            decisionHandler(WKNavigationActionPolicyCancel);
        }
        return IWKPluginHandleResultBreak;
    }

    return IWKPluginHandleResultContinue;
}


- (IWKPluginHandleResultType)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    webView.didFinishOrFail = YES;
    if (webView.bdw_offlineType == BDWebViewOfflineTypeBetweenStartAndFinishLoad) {
        [self stopOffline:webView];
        [webView evaluateJavaScript:@";(function (){window._is_offline_closed=1;window._setbackXML_&&window._setbackXML_();})();" completionHandler:NULL];
    }else if(webView.bdw_offlineType == BDWebViewOfflineTypeChannelInterceptor && webView.channelInterceptorList.count > 0){
        if ([BDWebKitSettingsManger checkOfflineChannelInterceptorInjectJS]) {
            [self stopOffline:webView];
            [webView evaluateJavaScript:@";(function (){window._is_offline_closed=1;window._setbackXML_&&window._setbackXML_();})();" completionHandler:NULL];
        }
        [BDWebViewOfflineManager unregisterCustomInterceptorList:webView.channelInterceptorList];
    }
    [IESFalconManager webView:webView didFinishNavigation:navigation];
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    webView.didFinishOrFail = YES;
    if (webView.bdw_offlineType == BDWebViewOfflineTypeBetweenStartAndFinishLoad) {
        [self stopOffline:webView];
        [webView evaluateJavaScript:@";(function (){window._is_offline_closed=1;window._setbackXML_&&window._setbackXML_();})();" completionHandler:NULL];
    }else if(webView.bdw_offlineType == BDWebViewOfflineTypeChannelInterceptor && webView.channelInterceptorList.count > 0){
        if ([BDWebKitSettingsManger checkOfflineChannelInterceptorInjectJS]) {
            [self stopOffline:webView];
            [webView evaluateJavaScript:@";(function (){window._is_offline_closed=1;window._setbackXML_&&window._setbackXML_();})();" completionHandler:NULL];
        }
        [BDWebViewOfflineManager unregisterCustomInterceptorList:webView.channelInterceptorList];
    }
    [IESFalconManager webView:webView didFinishNavigation:navigation];
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webViewWillDealloc:(WKWebView *)webView {
    if (webView.bdw_offlineType == BDWebViewOfflineTypeTaskScheme) { //如果网络请求走ttnet，那protocol是跟webView实例走的，不用全局管理
        [webView bdw_unregisterURLProtocolClass:IESFalconURLProtocol.class];
    }else if(webView.bdw_offlineType == BDWebViewOfflineTypeChannelInterceptor && webView.channelInterceptorList.count > 0){
        [BDWebViewOfflineManager unregisterCustomInterceptorList:webView.channelInterceptorList];
        if ([BDWebKitSettingsManger checkOfflineChannelInterceptorInjectJS]) {
            WKWebView *lastVisibleWebView = [BDWebViewOfflineStatusLogicControl lastVisibleWebViewWhenDestroy:webView];
            if(lastVisibleWebView && lastVisibleWebView.didFinishOrFail) {
                [self stopOffline:lastVisibleWebView];
            }
        }
    } else {
        WKWebView *lastVisibleWebView = [BDWebViewOfflineStatusLogicControl lastVisibleWebViewWhenDestroy:webView];
        if (lastVisibleWebView && lastVisibleWebView.bdw_offlineType == BDWebViewOfflineTypeWholeLife) {
            [self startOffline:lastVisibleWebView];
        } else {
            if(lastVisibleWebView && lastVisibleWebView.didFinishOrFail) {
                [self stopOffline:lastVisibleWebView];
            }
        }
    }
    
    return IWKPluginHandleResultContinue;
}

- (void)startOffline:(WKWebView *)webView {
    BDWebViewOfflineManager.interceptionEnable = YES;
    [webView.configuration.userContentController bdw_installHookAjax];
}

- (void)stopOffline:(WKWebView *)webView {
    BDWebViewOfflineManager.interceptionEnable = NO;
    if (webView.bdw_hitPreload && webView.bdw_offlineType != BDWebViewOfflineTypeTaskScheme) {
        webView.bdw_offlineType = BDWebViewOfflineTypeNone;
    }
}

@end
