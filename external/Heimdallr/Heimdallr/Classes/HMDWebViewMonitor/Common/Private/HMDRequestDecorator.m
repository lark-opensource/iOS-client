//
//  HMDRequestDecorator.m
//  Heimdallr
//
//  Created by zhangyuzhong on 2021/12/23.
//

#import "HMDRequestDecorator.h"
#import <WebKit/WKWebView.h>
#import "HMDDynamicCall.h"
#import "HMDHTTPRequestInfo.h"


@protocol BDWebURLSchemeTask;
@protocol BDWebURLProtocolTask;
@class BDWebKitMainFrameModel;

// <BDWebRequestDecorator>
@interface HMDRequestDecorator ()

@end

@implementation HMDRequestDecorator

- (void)bdw_decorateSchemeTask:(id<BDWebURLSchemeTask>)schemeTask {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:2];
    HMDHTTPRequestInfo *requestInfo = [[HMDHTTPRequestInfo alloc] init];
    
    NSDictionary *addInfo = DC_OB(schemeTask, bdw_additionalInfo);
    if(!addInfo || ![addInfo isKindOfClass:[NSDictionary class]]){
        requestInfo.webviewChannel = @"webview://schemehandler";
    }else {
        HMDHTTPRequestInfo *prevRequestInfo = DC_IS(addInfo[@"requestInfo"], HMDHTTPRequestInfo);
        requestInfo.webviewChannel = [NSString stringWithFormat:@"%@->%@", prevRequestInfo.webviewChannel?:@"null", @"webview://schemehandler"];
    }

    WKWebView *webview = DC_OB(schemeTask, bdw_webView);
    if(webview) {
        BDWebKitMainFrameModel *model = DC_OB(webview, bdw_mainFrameModelRecord);
        requestInfo.webviewURL = DC_IS(DC_OB(model, latestWebViewURLString), NSString);
    }
    [dic setObject:requestInfo forKey:@"requestInfo"];
    DC_OB(schemeTask, setBdw_additionalInfo:, [dic copy]);
}

- (NSURLRequest *)bdw_decorateRequest:(NSURLRequest *)request {
    return request;
}

- (void)bdw_decorateURLProtocolTask:(id<BDWebURLProtocolTask>)urlProtocolTask {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:2];
    HMDHTTPRequestInfo *requestInfo = [[HMDHTTPRequestInfo alloc] init];
    BOOL taskFromHookAjax = DC_IS(DC_OB(urlProtocolTask, taskFromHookAjax), NSNumber).boolValue;
    
    NSString *webviewChannel = taskFromHookAjax ? @"webview://hook_ajax" : @"webview://falcon_intercept";
         
    NSDictionary *addInfo = DC_OB(urlProtocolTask, bdw_additionalInfo);
    if(!addInfo || ![addInfo isKindOfClass:[NSDictionary class]]){
        requestInfo.webviewChannel = webviewChannel;
    }else {
        HMDHTTPRequestInfo *prevRequestInfo = DC_IS(addInfo[@"requestInfo"], HMDHTTPRequestInfo);
        requestInfo.webviewChannel = [NSString stringWithFormat:@"%@->%@", prevRequestInfo.webviewChannel?:@"null", webviewChannel];
    }

    WKWebView *webview = DC_OB(urlProtocolTask, bdw_webView);
    if(webview) {
        BDWebKitMainFrameModel *model = DC_OB(webview, bdw_mainFrameModelRecord);
        requestInfo.webviewURL = DC_IS(DC_OB(model, latestWebViewURLString), NSString);
    }
    [dic setObject:requestInfo forKey:@"requestInfo"];
    DC_OB(urlProtocolTask, setBdw_additionalInfo:, [dic copy]);
}

@end
