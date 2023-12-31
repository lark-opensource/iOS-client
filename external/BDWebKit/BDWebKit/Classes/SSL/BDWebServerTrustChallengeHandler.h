//
//  BDServerTrustChallengeHandler.h
//  ByteWebView
//
//  Created by Nami on 2019/3/5.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <BDAlogProtocol/BDAlogProtocol.h>

#define BDWebKitSSLLogTag @"BDWebKit_SSL"
#define BDWebKitSSL_InfoLog(format, ...)  BDALOG_PROTOCOL_INFO_TAG(BDWebKitSSLLogTag, format, ##__VA_ARGS__)
#define BDWebKitSSL_ErrorLog(format, ...)  BDALOG_PROTOCOL_ERROR_TAG(BDWebKitSSLLogTag, format, ##__VA_ARGS__)

NS_ASSUME_NONNULL_BEGIN
/**
 主要负责证书受信相关处理逻辑
 1、设置了 bdw_skipAndPassAllServerTrust = YES，则信任所有证书。效率最高，不进行任何校验。但是有风险
 2、设置了 bdw_serverTrustDelegate，则根据 BDWebServerUntrustOperation 来处理：通过，拒绝，弹窗确认等
 3、默认情况：弹窗确认
 */

@interface BDWebServerTrustChallengeHandler : NSObject

- (instancetype)initWithWebView:(WKWebView *)webView;

// 用于WebView回调
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler;

// 用于TTNet代理
- (BOOL)shouldSkipSSLCertificateError;
- (void)handleSSLError:(NSURL *)errorURL WithComplete:(void (^)(BOOL trustSSL))complete;

@end

NS_ASSUME_NONNULL_END
