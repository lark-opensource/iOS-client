//
//  CJPayBridgePlugin_setBounce.m
//  CJPay
//
//  Created by liyu on 2020/1/13.
//

#import "CJPayBridgePlugin_setBounce.h"
#import "NSDictionary+CJPay.h"

#import <TTBridgeUnify/TTBridgeRegister.h>
#import <WebKit/WKWebView.h>

#import "CJPayBizWebViewController.h"
#import "NSDictionary+CJPay.h"
#import "CJPayWKWebView.h"

@implementation CJPayBridgePlugin_setBounce

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_setBounce, setBounce), @"ttcjpay.setBounce");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)setBounceWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller
{
    
    CJPayBizWebViewController *webViewController = (CJPayBizWebViewController *)controller;
    if (webViewController == nil || ![webViewController isKindOfClass:CJPayBizWebViewController.class]) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"webViewController初始化失败");
        return;
    }

    NSDictionary *dic = (NSDictionary *)param;
    NSString *status = [dic cj_stringValueForKey:@"status"];
    if ([status isEqualToString:@"1"]) {
        [self setBounce:YES webviewController:webViewController];
        TTBRIDGE_CALLBACK_SUCCESS
        
    } else if ([status isEqualToString:@"0"]) {
        [self setBounce:NO webviewController:webViewController];
        TTBRIDGE_CALLBACK_SUCCESS
        
    } else {
        TTBRIDGE_CALLBACK_FAILED
    }

}

- (void)setBounce:(BOOL)enable
webviewController:(CJPayBizWebViewController *)webviewController {
    [webviewController setBounce:enable];
}

@end
