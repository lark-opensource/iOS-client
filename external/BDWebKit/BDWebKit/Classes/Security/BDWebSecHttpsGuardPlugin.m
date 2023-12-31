//
//  BDWebSecHttpsGuardPlugin.m
//  BDWebKit-Pods-Aweme
//
//  Created by huangzhongwei on 2021/4/16.
//

#import "BDWebSecHttpsGuardPlugin.h"
#import "BDWebSecSettingManager.h"

@implementation BDWebSecHttpsGuardPlugin
-(IWKPluginHandleResultObj<WKNavigation *> *)webView:(WKWebView *)webView loadRequest:(NSURLRequest *)request {
    NSString *scheme = request.URL.scheme;
    NSString *host = request.URL.host;
    if ([scheme isEqualToString:@"http"] && [BDWebSecSettingManager shouldForceHttpsForURL:request.URL.absoluteString]) {
        
        NSMutableURLRequest *secRequest = [request mutableCopy];
        
        secRequest.URL = [NSURL URLWithString:[request.URL.absoluteString stringByReplacingCharactersInRange:NSMakeRange(0, 4) withString:@"https"]];
        
        IWKPluginHandleResultObj* result = IWKPluginHandleResultBreak;
        result.value = [webView loadRequest:secRequest];
        
        return result;
    }else {
        return IWKPluginHandleResultContinue;
    }
}
@end
