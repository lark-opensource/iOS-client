//
//  FixWKWebView.h
//  LarkWebViewContainer
//
//  Created by yinyuan on 2022/5/6.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FixWKWebView : NSObject

/// 如果一个 WebView 在 deinit 时被赋给weak指针，将会crash，因此这种场景都需要判断是否在 deinit，避免 crash
+(BOOL)isWebViewDeallocating:(WKWebView *)webView;

+(void)tryFixWKWebView:(WKWebView *)webView;

@end

@interface NSObject (LKFixWKWebView)

+(void)lk_tryFixWKReloadFrameErrorRecoveryAttempter;

@end

NS_ASSUME_NONNULL_END
