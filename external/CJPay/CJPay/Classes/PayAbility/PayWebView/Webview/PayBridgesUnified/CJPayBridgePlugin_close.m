//
//  CJPayBridgePlugin_close.m
//  CJPay
//
//  Created by liyu on 2020/1/13.
//

#import "CJPayBridgePlugin_close.h"

#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPayBizWebViewController.h"
#import "CJPayHybridPlugin.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"

@implementation CJPayBridgePlugin_close

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_close, close), @"ttcjpay.close");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)closeWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller
{
    if ([controller isKindOfClass:CJPayBizWebViewController.class]) {
        CJPayBizWebViewController *webViewController = (CJPayBizWebViewController *)controller;
        
        BOOL disablesAnimation = [param cj_boolValueForKey:@"disable_animation"];
        if (disablesAnimation) {
            [webViewController closeWebVCWithAnimation:NO completion:nil];
        } else {
            [webViewController closeWebVC];
        }
        TTBRIDGE_CALLBACK_SUCCESS;
    } else {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"调用的容器不是WebviewVC");
        return;
    }
    TTBRIDGE_CALLBACK_SUCCESS;
}

@end
