//
//  CJPayBridgePlugin_setShareInfo.m
//  CJPay-Pods-AwemeCore
//
//  Created by liutianyi on 2022/8/18.
//

#import "CJPayBridgePlugin_setShareInfo.h"
#import "CJPayBizWebViewController.h"
#import <WebKit/WKWebView.h>
#import <TTBridgeUnify/TTBridgeRegister.h>

@implementation CJPayBridgePlugin_setShareInfo

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_setShareInfo, setShareInfo), @"ttcjpay.setShareInfo");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)setShareInfoWithParam:(NSDictionary *)param
                     callback:(TTBridgeCallback)callback
                       engine:(id<TTBridgeEngine>)engine
                   controller:(UIViewController *)controller
{
    CJPayBizWebViewController *webViewController = (CJPayBizWebViewController *)controller;
    if (webViewController == nil || ![webViewController isKindOfClass:CJPayBizWebViewController.class]) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"webViewController初始化失败");
        return;
    }
    webViewController.shareParam = param;
    TTBRIDGE_CALLBACK_SUCCESS
}

@end
