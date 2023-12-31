//
//  WKWebView+BDCookie.m
//  BDWebKit
//
//  Created by wealong on 2019/12/17.
//

#import "WKWebView+BDCookie.h"
#import <BDAlogProtocol/BDAlogProtocol.h>
#import "NSObject+BDWRuntime.h"

@implementation WKWebView (BDCookie)

- (void)bdw_syncCookie {
    if (self.URL == nil) {
        return ;
    }
    NSArray<NSHTTPCookie *> *URLCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:self.URL];
    if (URLCookies.count <= 0) {
        return ;
    }
    NSString *jsScript = [self bdw_cookiesScriptFromCookies:URLCookies];
    jsScript = [NSString stringWithFormat:@"try{%@}catch(e){}", jsScript];
    [self evaluateJavaScript:jsScript completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if (error) {
            BDALOG_PROTOCOL_ERROR(@"Cookie Sync error %@", error);
        }
    }];
}

- (NSString *)bdw_cookiesScriptFromCookies:(NSArray<NSHTTPCookie *> *)cookies {
    NSMutableString *str = [[NSMutableString alloc] init];
    
    for (NSHTTPCookie *cookie in cookies) {
        NSString *name = [cookie.name stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
        NSString *value = [cookie.value stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
        NSString *path = [cookie.path stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
        NSString *domain = [cookie.domain stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
        if (name.length > 0 && value.length > 0) {
            [str appendFormat:@";document.cookie=\"%@=%@;path=%@;domain=%@\"", name, value, path, domain];
        }
    }
    
    return [str copy];
}

- (void)bdw_syncCookiesWithCompletion:(void (^)(void))completion {
    if (!completion) {
        return;
    }
    
    if (@available(iOS 11.0, *)) {
        __block int handleCount = 0;
        NSArray<NSHTTPCookie *> *httpCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies copy];
        if (httpCookies.count > 0) {
            WKWebViewConfiguration *config = self.configuration;
            for (NSHTTPCookie *cookie in httpCookies) {
                [config.websiteDataStore.httpCookieStore setCookie:cookie completionHandler:^{
                    handleCount ++;
                    if (handleCount == httpCookies.count && completion) {
                        completion();
                    }
                }];
            }
            return;
        }
    }
    completion();
}

- (void)bdw_loadRequestWithSyncCookie:(NSURLRequest *)request {
    __weak typeof(self) wself = self;
    [self bdw_syncCookiesWithCompletion:^{
        [wself loadRequest:request];
    }];
}

- (BOOL)bdw_allowAddCookieInHeader {
    return [[self bdw_getAttachedObjectForKey:@"bdw_allowAddCookieInHeader"] boolValue];
}

- (void)setBdw_allowAddCookieInHeader:(BOOL)bdw_allowAddCookieInHeader {
    [self bdw_attachObject:@(bdw_allowAddCookieInHeader) forKey:@"bdw_allowAddCookieInHeader"];
}

- (BOOL)bdw_allowFix30xCORSCookie {
    return [[self bdw_getAttachedObjectForKey:@"bdw_allowFix30xCORSCookie"] boolValue];
}

- (void)setBdw_allowFix30xCORSCookie:(BOOL)bdw_allowFix30xCORSCookie {
    [self bdw_attachObject:@(bdw_allowFix30xCORSCookie) forKey:@"bdw_allowFix30xCORSCookie"];
}

- (NSURLRequest *)bdw_originRequest {
    return [self bdw_getAttachedObjectForKey:@"bdw_originRequest"];
}

- (void)setBdw_originRequest:(NSURLRequest *)bdw_originRequest {
    [self bdw_attachObject:bdw_originRequest forKey:@"bdw_originRequest"];
}

- (BOOL)bdw_isAddedCookieInHeader {
    return [[self bdw_getAttachedObjectForKey:@"bdw_isAddedCookieInHeader"] boolValue];
}

- (void)setBdw_isAddedCookieInHeader:(BOOL)bdw_isAddedCookieInHeader {
    [self bdw_attachObject:@(bdw_isAddedCookieInHeader) forKey:@"bdw_isAddedCookieInHeader"];
}

@end
