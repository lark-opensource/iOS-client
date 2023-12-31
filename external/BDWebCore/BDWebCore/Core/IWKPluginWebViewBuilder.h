//
//  IWKPluginWebViewBuilder.h
//  BDWebCore
//
//  Created by li keliang on 2019/6/30.
//

#import <WebKit/WebKit.h>
#import <BDWebCore/IWKPluginHandleResultObj.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IWKPluginWebViewBuilder <NSObject>

@optional

- (IWKPluginHandleResultType)webView:(WKWebView *)webView willInitWithFrame:(CGRect)rect configuration:(WKWebViewConfiguration *)configuration;

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didInitWithFrame:(CGRect)rect configuration:(WKWebViewConfiguration *)configuration;

- (IWKPluginHandleResultType)webViewWillDealloc:(WKWebView *)webView;

@end

NS_ASSUME_NONNULL_END
