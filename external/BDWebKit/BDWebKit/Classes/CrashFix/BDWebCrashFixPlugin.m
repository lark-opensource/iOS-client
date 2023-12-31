//
//  BDWebCrashFixPlugin.m
//  BDWebKit
//
//  Created by 杨牧白 on 2020/3/18.
//

#import "BDWebCrashFixPlugin.h"
#import "BDFixWKWebViewCrash.h"
#import <WebKit/WebKit.h>
#import <BDWebCore/WKWebView+Plugins.h>

@implementation BDWebCrashFixPlugin

+ (void)load {
    [WKWebView IWK_loadPlugin:BDWebCrashFixPlugin.new];
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView willInitWithFrame:(CGRect)rect configuration:(WKWebViewConfiguration *)configuration {
    
    [WKWebView tryFixGetURLCrash];
    [WKWebView tryFixOfflineCrash];
    [WKWebView tryFixWKReloadFrameErrorRecoveryAttempter];
    [WKWebView tryFixBackGroundHang];
    [WKWebView tryFixAddupdateCrash];
    [BDFixWKWebViewCrash tryFixBlobCrash];
    [WKScriptMessage tryFixWKScriptMessageCrash];
    return IWKPluginHandleResultContinue;
}

@end
