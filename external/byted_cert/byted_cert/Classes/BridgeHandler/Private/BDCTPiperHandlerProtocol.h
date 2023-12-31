//
//  BDCTPiperHandlerProtocol.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/7/5.
//

#import <Foundation/Foundation.h>
#import <WebKit/WKWebView.h>
#import <TTBridgeUnify/TTWebViewBridgeEngine.h>

@protocol BDCTPiperHandlerProtocol <NSObject>

- (void)registerHandlerWithWebView:(WKWebView *)webView;

@end
