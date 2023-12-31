//
//  BDWebInterceptorPluginObject.m
//  BDWebKit
//
//  Created by li keliang on 2020/4/3.
//

#import "BDWebInterceptorPluginObject.h"
#import "BDWebInterceptor.h"
#import "BDWebURLSchemeTask.h"
#import "BDWebURLSchemeHandler.h"
#import "WKWebView+BDInterceptor.h"
#import "WKWebView+BDPrivate.h"
#import "BDWebKitMainFrameModel.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import <objc/runtime.h>

@implementation BDWebInterceptorPluginObject

- (IWKPluginHandleResultType)webView:(WKWebView *)webView willInitWithFrame:(CGRect)rect configuration:(WKWebViewConfiguration *)configuration
{
    webView.bdw_schemeHandlerInterceptionStatus = BDWebKitSchemeHandlerInterceptionStatusNone;
    if (@available(iOS 12.0, *)) {
        if (configuration.bdw_enableInterceptor) {
            [configuration bdw_installURLSchemeHandler];
            webView.bdw_schemeHandlerInterceptionStatus = BDWebKitSchemeHandlerInterceptionStatusHTTP;
        }
    }
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    // reset main frame model for schemehandler
    BOOL isTargetMainFrame = navigationAction.targetFrame && navigationAction.targetFrame.isMainFrame;
    if (isTargetMainFrame && [navigationAction.request.URL.scheme hasPrefix:@"http"]) {
        // reset mainFrameModel if needed
        if (!webView.bdw_mainFrameModelRecord ||
            (webView.bdw_mainFrameModelRecord.mainFrameStatus == BDWebKitMainFrameStatusUseSchemeHandler) ||
            (webView.bdw_mainFrameModelRecord.mainFrameStatus == BDWebKitMainFrameStatusUseFalconURLProtocol)) {
            BDWebKitMainFrameModel *mainFrameModel = [[BDWebKitMainFrameModel alloc] init];
            mainFrameModel.mainFrameStatus = BDWebKitMainFrameStatusNone;
            webView.bdw_mainFrameModelRecord = mainFrameModel;
        }
        BDWebKitMainFrameModel *model = webView.bdw_mainFrameModelRecord;
        model.latestWebViewURLString = navigationAction.request.URL.absoluteString;
        if (model.mainFramePerformanceTimingModel == nil) {
            model.mainFramePerformanceTimingModel = [[NSMutableDictionary alloc] init];
        }
        model.mainFramePerformanceTimingModel[kBDWMainFrameReceiveLoadRequestEvent] = @([[NSDate date] timeIntervalSince1970]*1000);
    }
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    if (webView.bdw_mainFrameModelRecord) {
        BDWebKitMainFrameModel *model = webView.bdw_mainFrameModelRecord;
        if (model.mainFramePerformanceTimingModel == nil) {
            model.mainFramePerformanceTimingModel = [[NSMutableDictionary alloc] init];
        }
        model.mainFramePerformanceTimingModel[kBDWMainFrameStartProvisionalNavigationEvent] = @([[NSDate date] timeIntervalSince1970]*1000);
        model.mainFramePerformanceTimingModel[kBDWMainFrameReceiveServerRedirectCount] = @(0);
    }
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation
{
    if (webView.bdw_mainFrameModelRecord) {
        BDWebKitMainFrameModel *model = webView.bdw_mainFrameModelRecord;
        if (model.mainFramePerformanceTimingModel == nil) {
            model.mainFramePerformanceTimingModel = [[NSMutableDictionary alloc] init];
        }
        model.mainFramePerformanceTimingModel[kBDWMainFrameReceiveServerRedirectForProvisionalNavigationEvent] = @([[NSDate date] timeIntervalSince1970]*1000);
        NSNumber *redirectCount = [model.mainFramePerformanceTimingModel btd_numberValueForKey:kBDWMainFrameReceiveServerRedirectCount default:@(0)];
        if (redirectCount) {
            redirectCount = @([redirectCount integerValue] + 1);
        } else {
            redirectCount = @(1);
        }
        model.mainFramePerformanceTimingModel[kBDWMainFrameReceiveServerRedirectCount] = redirectCount;
    }
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    if (webView.bdw_mainFrameModelRecord) {
        BDWebKitMainFrameModel *model = webView.bdw_mainFrameModelRecord;
        if (model.mainFramePerformanceTimingModel == nil) {
            model.mainFramePerformanceTimingModel = [[NSMutableDictionary alloc] init];
        }
        model.mainFramePerformanceTimingModel[kBDWMainFrameReceiveNavigationResponseEvent] = @([[NSDate date] timeIntervalSince1970]*1000);
    }
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    if (webView.bdw_mainFrameModelRecord) {
        BDWebKitMainFrameModel *model = webView.bdw_mainFrameModelRecord;
        if (model.mainFramePerformanceTimingModel == nil) {
            model.mainFramePerformanceTimingModel = [[NSMutableDictionary alloc] init];
        }
        model.mainFramePerformanceTimingModel[kBDWMainFrameCommitNavigationEvent] = @([[NSDate date] timeIntervalSince1970]*1000);
    }
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    if (webView.bdw_mainFrameModelRecord) {
        BDWebKitMainFrameModel *model = webView.bdw_mainFrameModelRecord;
        if (model.mainFramePerformanceTimingModel == nil) {
            model.mainFramePerformanceTimingModel = [[NSMutableDictionary alloc] init];
        }
        model.mainFramePerformanceTimingModel[kBDWMainFrameFinishNavigationEvent] = @([[NSDate date] timeIntervalSince1970]*1000);
    }
    return IWKPluginHandleResultContinue;
}

@end
