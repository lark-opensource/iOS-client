//
//  CJPayBridgePlugin_login.m
//  CJPay
//
//  Created by liyu on 2020/1/14.
//

#import "CJPayBridgePlugin_login.h"

#import <TTBridgeUnify/TTBridgeRegister.h>

#import "CJPayWebViewUtil.h"
#import "CJPayBizWebViewController.h"

@implementation CJPayBridgePlugin_login

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_login, login), @"ttcjpay.login");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)loginWithParam:(NSDictionary *)param
              callback:(TTBridgeCallback)callback
                engine:(id<TTBridgeEngine>)engine
            controller:(UIViewController *)controller
{
    CJPayBizWebViewController *webViewController = (CJPayBizWebViewController *)controller;
    if (webViewController == nil || ![webViewController isKindOfClass:CJPayBizWebViewController.class]) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"webViewController初始化失败");
        return;
    }
    
    [[CJPayWebViewUtil sharedUtil] needLogin:^(CJBizWebCode code) {
        NSString *codeStr = @"0";
        TTBridgeMsg bridgeCode = TTBridgeMsgSuccess;
        if (code != CJBizWebCodeLoginSuccess) {
            bridgeCode = TTBridgeMsgFailed;
            codeStr = @"1";
        }

        if (callback) {
            callback(bridgeCode, @{@"code": codeStr}, nil);
        }

    }];

}

@end
