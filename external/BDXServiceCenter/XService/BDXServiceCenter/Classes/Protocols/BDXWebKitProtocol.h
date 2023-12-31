//
//  BDXWebKitProtocol.h
//  BDXServiceCenter-Pods-Aweme
//
//  Created by bill on 2021/3/3.
//

#import <Foundation/Foundation.h>
#import <WebKit/WKNavigationDelegate.h>
#import <WebKit/WebKit.h>

#import "BDXKitProtocol.h"
#import "BDXServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDXWebViewProtocol;
@protocol BDXKitViewProtocol;

@interface BDXWebKitParams : BDXKitParams

@property(nonatomic, copy) Class bridgeClass;
@property(nonatomic, assign) BOOL enableSecureLink;

@end

@protocol BDXWebKitProtocol <BDXServiceProtocol>

/// 创建一个符合 BDXWebViewProtocol 协议的 View
/// @param frame frame
/// @param params 参数
/// @param url url
- (UIView<BDXWebViewProtocol> *)createViewWithFrame:(CGRect)frame params:(BDXWebKitParams *)params url:(NSURL *)url;

@end

@protocol BDXWebViewProtocol <BDXKitViewProtocol>

/// 加载 url request
/// @param request request
- (WKNavigation *)loadRequest:(NSURLRequest *)request;

/// 获取webview
- (WKWebView *)webView;

/// 运行 js
/// @param javaScriptString 需要运行的js代码
/// @param completionHandler 完成回调
- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *error))completionHandler;

/// 设置 webView delegate
/// @param delegate WKNavigationDelegate
- (void)addDelegate:(id<WKNavigationDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
