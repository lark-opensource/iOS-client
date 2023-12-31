//
//  CJPayBridgePlugin_getMegaObject.m
//  Aweme
//
//  Created by liutianyi on 2022/12/5.
//

#import "CJPayBridgePlugin_getMegaObject.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"

@implementation CJPayBridgePlugin_getMegaObject

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_getMegaObject, getMegaObject), @"ttcjpay.getMegaObject");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)getMegaObjectWithParam:(NSDictionary *)param
                     callback:(TTBridgeCallback)callback
                       engine:(id<TTBridgeEngine>)engine
                   controller:(UIViewController *)controller
{
    CJPayBizWebViewController *webViewController = (CJPayBizWebViewController *)controller;
    if (webViewController == nil || ![webViewController isKindOfClass:CJPayBizWebViewController.class]) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"webViewController初始化失败");
        return;
    }
    if (callback && Check_ValidString(webViewController.rifleMegaObject)) {
        callback(TTBridgeMsgSuccess, [webViewController.rifleMegaObject cj_toDic], nil);
    }
    TTBRIDGE_CALLBACK_SUCCESS
}

@end
