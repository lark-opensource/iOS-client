//
//  CJPayBridgePlugin_loading.m
//  CJPay
//
//  Created by liyu on 2020/1/13.
//

#import "CJPayBridgePlugin_loading.h"

#import <TTBridgeUnify/TTBridgeRegister.h>

#import "CJPayBizWebViewController.h"
#import "CJPayLoadingManager.h"

#import "CJPayUIMacro.h"

#import "CJPaySDKMacro.h"

@implementation CJPayBridgePlugin_loading

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_loading, showLoading), @"ttcjpay.showLoading");    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_loading, hideLoading), @"ttcjpay.hideLoading");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)showLoadingWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller
{
    CJPayBizWebViewController *webViewController = (CJPayBizWebViewController *)controller;
    if (webViewController == nil || ![webViewController isKindOfClass:CJPayBizWebViewController.class]) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"webViewController初始化失败");
        return;
    }
    if ([UIViewController cj_foundTopViewControllerFrom:controller] == webViewController) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading vc:webViewController];
    }
    TTBRIDGE_CALLBACK_SUCCESS;
}

- (void)hideLoadingWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller
{
    CJPayBizWebViewController *webViewController = (CJPayBizWebViewController *)controller;
    if (webViewController == nil || ![webViewController isKindOfClass:CJPayBizWebViewController.class]) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"webViewController初始化失败");
        return;
    }
    [[CJPayLoadingManager defaultService] stopLoading];
    TTBRIDGE_CALLBACK_SUCCESS;
}

@end
