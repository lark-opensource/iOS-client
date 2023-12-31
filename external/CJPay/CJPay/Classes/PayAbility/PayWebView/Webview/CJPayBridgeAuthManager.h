//
//  CJPayBridgeAuthManager.h
//  CJPay
//
//  Created by 王新华 on 2022/7/2.
//

#import <Foundation/Foundation.h>
#import <WebKit/WKWebView.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBridgeAuthManager : NSObject

+ (CJPayBridgeAuthManager *)shared;

- (NSSet<NSString *> *)allowedDomainsForSDK;

- (void)installEngineOn:(WKWebView *)webview;

- (void)installIESAuthOn:(WKWebView *)webview;


@end

NS_ASSUME_NONNULL_END
