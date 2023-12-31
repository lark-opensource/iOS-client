//
//  WKWebView+BDCookie.h
//  BDWebKit
//
//  Created by wealong on 2019/12/17.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWebView (BDCookie)

// 同步 Cookie，调用该方法会同步一次 Cookie
- (void)bdw_syncCookie;

// 是否写入 cookie 到 request header 中，用于兼容 WKWebView 首次请求不带 Cookie 的问题，默认 YES
@property (nonatomic) BOOL bdw_allowAddCookieInHeader;

// 是否修复写入 Cookie 后 30x 二跳带 cookie 的漏洞，默认 YES
@property (nonatomic) BOOL bdw_allowFix30xCORSCookie;

// 最终走 loadRequest 的源请求
@property (strong, nonatomic) NSURLRequest *bdw_originRequest;

- (void)bdw_syncCookiesWithCompletion:(void (^)(void))completion;

- (void)bdw_loadRequestWithSyncCookie:(NSURLRequest *)request;

// private

@property (nonatomic) BOOL bdw_isAddedCookieInHeader;

@end

NS_ASSUME_NONNULL_END
