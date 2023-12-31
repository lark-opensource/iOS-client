//
//  CJPayBizWebViewController+Payment.h
//  CJPay
//
//  Created by liyu on 2020/2/20.
//


#import "CJPayBizWebViewController.h"

#import <WebKit/WKNavigationDelegate.h>

@class WKNavigationAction;

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBizWebViewController (Payment)

- (BOOL)payment_hasDecidedPolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;

@end

NS_ASSUME_NONNULL_END
