//
//  IWKPluginNavigationDelegate_UIWebView.h
//  BDWebCore
//
//  Created by li keliang on 14/11/2019.
//

#import <UIKit/UIKit.h>
#import <BDWebCore/IWKPluginHandleResultObj.h>
#import <JavaScriptCore/JSContext.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IWKPluginNavigationDelegate_UIWebView <NSObject>

@optional
- (IWKPluginHandleResultType)webView:(UIWebView *)webView didCreateJavaScriptContext:(JSContext *)ctx;
- (IWKPluginHandleResultType)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType API_DEPRECATED("No longer supported.", ios(2.0, 12.0));
- (IWKPluginHandleResultType)webViewDidStartLoad:(UIWebView *)webView API_DEPRECATED("No longer supported.", ios(2.0, 12.0));
- (IWKPluginHandleResultType)webViewDidFinishLoad:(UIWebView *)webView API_DEPRECATED("No longer supported.", ios(2.0, 12.0));
- (IWKPluginHandleResultType)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error API_DEPRECATED("No longer supported.", ios(2.0, 12.0));

@end

NS_ASSUME_NONNULL_END
