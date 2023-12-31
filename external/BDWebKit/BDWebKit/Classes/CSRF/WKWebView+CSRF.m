//
//  WKWebView+CSRF.m
//
//  Created by huangzhongwei on 2021/2/22.
//

#import "WKWebView+CSRF.h"
#import <ByteDanceKit/NSObject+BTDAdditions.h>
#import <BDWebCore/WKWebView+Plugins.h>
#import <ByteDanceKit/BTDMacros.h>
#import "BDWebCsrfPlugin.h"

@implementation WKWebView (CSRF)
+(void)bd_tryFixCSRF:(BDCustomUARegister)block {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self btd_swizzleInstanceMethod:@selector(setCustomUserAgent:) with:@selector(bd_setCustomUserAgent:)];
        [WKWebView IWK_loadPlugin:[[BDWebCsrfPlugin alloc] initWithUARegister:block]];
    });
}

-(void)bd_setCustomUserAgent:(NSString*)ua {
    NSString *customUA = [self.class csrfUserAgent];
    
    if (ua && ua.length>0) {
        if ([ua rangeOfString:customUA].location == NSNotFound) {
            ua = [ua stringByAppendingFormat:@" %@", customUA];
        }
    }
    [self bd_setCustomUserAgent:ua];
}

+(NSString*)csrfUserAgent {
    /**Notice: THIS IS IMPORTANT !!!
     *This string is appended to webview UA to defend csrf attack
     *Do not delete or change it
     */
    return @"BytedanceWebview/d8a21c6";
}
@end
