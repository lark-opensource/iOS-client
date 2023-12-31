//
//  IWKPluginWebViewBuilder_UIWebView.h
//  BDWebCore
//
//  Created by li keliang on 14/11/2019.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IWKPluginWebViewBuilder_UIWebView <NSObject>

@optional

- (IWKPluginHandleResultType)webView:(UIWebView *)webView willInitWithFrame:(CGRect)rect;

- (IWKPluginHandleResultType)webView:(UIWebView *)webView didInitWithFrame:(CGRect)rect;

- (IWKPluginHandleResultType)webViewWillDealloc:(UIWebView *)webView;

@end

NS_ASSUME_NONNULL_END
