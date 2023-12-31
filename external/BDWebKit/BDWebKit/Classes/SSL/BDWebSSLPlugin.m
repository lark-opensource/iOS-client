//
//  BDWebSSLPlugin.m
//  BDWebKit
//
//  Created by 温宇涛 on 2020/2/21.
//

#import "BDWebSSLPlugin.h"
#import "WKWebView+BDWebServerTrust.h"
#import <BDWebKit/WKWebView+BDPrivate.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>

@interface BDWebSSLPlugin ()

@end

@implementation BDWebSSLPlugin

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    if (![webView bd_isPageValid]) {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        BDWebKitSSL_InfoLog(@"wkwebview no page");
        [BDTrackerProtocol eventV3:@"wkwebview_page_is_unvalid" params:@{@"exception":@"didReceiveAuthenticationChallenge"}];
        return IWKPluginHandleResultBreak;
    }
    
    [webView.bdw_serverTrustChallengeHandler webView:webView didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
    
    return IWKPluginHandleResultBreak;
}

@end
