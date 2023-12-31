//
//  IWKPluginWebViewLoader_UIWebView.h
//  BDWebCore
//
//  Created by li keliang on 14/11/2019.
//

#import <UIKit/UIKit.h>
#import <BDWebCore/IWKPluginHandleResultObj.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IWKPluginWebViewLoader_UIWebView <NSObject>

@optional

- (IWKPluginHandleResultType)webView:(UIWebView *)webView loadRequest:(NSURLRequest *)request;

- (IWKPluginHandleResultType)webView:(UIWebView *)webView loadHTMLString:(NSString *)string baseURL:(nullable NSURL *)baseURL;

- (IWKPluginHandleResultType)webView:(UIWebView *)webView loadData:(NSData *)data MIMEType:(NSString *)MIMEType textEncodingName:(NSString *)textEncodingName baseURL:(NSURL *)baseURL;

@end

NS_ASSUME_NONNULL_END
