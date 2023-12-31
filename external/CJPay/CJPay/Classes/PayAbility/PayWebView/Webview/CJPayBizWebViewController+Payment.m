//
//  CJPayBizWebViewController+Payment.m
//  CJPay
//
//  Created by liyu on 2020/2/20.
//

#import "CJPayBizWebViewController+Payment.h"

#import <WebKit/WKNavigationAction.h>
#import <UIKit/UIApplication.h>
#import <Foundation/Foundation.h>
#import "CJPayPrivacyMethodUtil.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"

@implementation CJPayBizWebViewController (Payment)

- (BOOL)payment_hasDecidedPolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURL *url = navigationAction.request.URL;
    NSString *absoluteString = [url.absoluteString stringByRemovingPercentEncoding];
    NSString *wxprefix = [NSString stringWithFormat:@"%@://", EN_WX];
    if ([absoluteString hasPrefix:wxprefix]) {
        CJPayLogInfo(@"跳转%@支付： %@", CN_WX, absoluteString);
        decisionHandler(WKNavigationActionPolicyCancel);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                NSString *policy = [NSString stringWithFormat:@"bpea-caijing_webview_open_%@", EN_WX];
                // 调用AppJump敏感方法，需走BPEA鉴权
                [CJPayPrivacyMethodUtil applicationOpenUrl:url
                                                withPolicy:policy
                                           completionBlock:^(NSError * _Nullable error) {
                    
                    if (error) {
                        CJPayLogError(@"error in %@", policy);
                    }
                }];
            } else {
                CJPayLogInfo(@"无法跳转%@支付： %@", CN_WX, absoluteString);
            }
        });
        
        return YES;
    }
    
    if ([absoluteString hasPrefix:[EN_zfb stringByAppendingString:@"s://"]] || [absoluteString hasPrefix:[EN_zfb stringByAppendingString:@"://"]]) {
        CJPayLogInfo(@"跳转%@： %@", CN_zfb, absoluteString);
        decisionHandler(WKNavigationActionPolicyCancel);

        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            NSString *policy = [NSString stringWithFormat:@"bpea-caijing_webview_open_%@s", EN_zfb];
            // 调用AppJump敏感方法，需走BPEA鉴权
            [CJPayPrivacyMethodUtil applicationOpenUrl:url
                                            withPolicy:policy
                                       completionBlock:^(NSError * _Nullable error) {
                
                if (error) {
                    CJPayLogError(@"error in %@", policy);
                }
            }];
        } else {
            CJPayLogInfo(@"无法跳转%@： %@", CN_zfb, absoluteString);
        }

        return YES;
    }
    
    if ([self _openURL:url scheme:@"snssdk1128" decisionHandler:decisionHandler]) {
        return YES;
    }
    
    return NO;
}

- (BOOL)_openURL:(NSURL *)url scheme:(NSString *)scheme decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSString *absoluteString = [url.absoluteString stringByRemovingPercentEncoding];
    NSString *prefix = [scheme stringByAppendingString:@"://"];
    if ([absoluteString hasPrefix:prefix]) {
        decisionHandler(WKNavigationActionPolicyCancel);
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            NSString *policy = [NSString stringWithFormat:@"bpea-caijing_webview_open_%@", scheme];
            // 调用AppJump敏感方法，需走BPEA鉴权
            [CJPayPrivacyMethodUtil applicationOpenUrl:url
                                            withPolicy:policy
                                       completionBlock:^(NSError * _Nullable error) {
                if (error) {
                    CJPayLogError(@"BPEA鉴权失败，错误信息：policy:%@, error:%@", policy, error.localizedDescription);
                }
            }];
        } else {
            CJPayLogError(@"无法跳转%@： %@", scheme, [url.absoluteString stringByRemovingPercentEncoding]);
        }
        return YES;
    }
    return NO;
}

@end
