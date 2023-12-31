//
//  CJWebViewHelper.h
//  CJPay
//
//  Created by 王新华 on 2018/12/13.
//

#import <Foundation/Foundation.h>

@class WKWebView;
@class CJPayWKWebView;
@class WKWebViewConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface CJWebViewHelper : NSObject

+ (instancetype)shared;

+ (WKWebView *)buildWebView:(NSString *)forUrl;
+ (CJPayWKWebView *)buildWebView:(NSString *)forUrl httpMethod:(NSString *)httpMethod;
+ (WKWebViewConfiguration *)buildWebviewConfig:(NSString *)forUrl httpMethod:(NSString *)httpMethod;

+ (BOOL)isBlankWeb:(UIView *)view;

+ (BOOL)injectSecLinkTO:(WKWebView *)webView withScene:(NSString *)scene withOriginalUrl:(NSString *)originalUrl;
+ (void)secLinkGoBackFrom:(WKWebView *)webView reachEndBlock:(void(^)(void))block;
+ (BOOL)isInShowErrorViewDomains:(nullable NSString *)url;

@end

NS_ASSUME_NONNULL_END
