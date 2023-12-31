//
//  WKWebView+TTNet.h
//  BDWebKit
//
//  Created by Nami on 2019/11/27.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <TTNetworkManager/TTNetworkManager.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WKWebViewNetworkDelegate <NSObject>

- (void)webView:(WKWebView *)webview willStartLoadURL:(NSURL *)url;
- (void)webView:(WKWebView *)webview didStartLoadURL:(NSURL *)url;
- (void)webView:(WKWebView *)webview didReceiveResponse:(NSURLResponse *)response;
- (void)webView:(WKWebView *)webview didReceiveData:(NSData *)data forURL:(NSURL *)url;
- (void)webView:(WKWebView *)webview didPerformRedirection:(NSURLResponse *)response newRequest:(NSURLRequest *)request;
- (void)webView:(WKWebView *)webview didFinishLoadURL:(NSURL *)url;
- (void)webView:(WKWebView *)webview didFailLoadURL:(NSURL *)url withError:(NSError *)error;
- (BOOL)webView:(WKWebView *)webview shouldUsePrefetchResponse:(NSHTTPURLResponse *)response withRequest:(NSURLRequest *)request;

- (float)webView:(WKWebView *)webview priorityForRequest:(NSURLRequest *)request;
- (NSDictionary*)webview:(WKWebView *)webview extraHeaderDictionaryForRequest:(NSURLRequest*)request;
@end

@interface WKWebView (TTNet)

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration useTTNet:(BOOL)useTTNet;

@property (nonatomic, assign) BOOL bdw_enableFreeFlow;
@property (nonatomic, assign, readonly) BOOL bdw_requestByTTNet;
@property (nonatomic, weak) id<WKWebViewNetworkDelegate> bdw_networkDelegate;

@end

NS_ASSUME_NONNULL_END
