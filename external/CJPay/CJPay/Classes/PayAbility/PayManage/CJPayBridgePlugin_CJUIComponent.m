//
//  CJPayBridgePlugin_CJUIComponent.m
//  CJPay
//
//  Created by liyu on 2020/1/14.
//

#import "CJPayBridgePlugin_CJUIComponent.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "NSDictionary+CJPay.h"
#import "CJPayVerifyPasswordRequest.h"
#import "CJPayBizWebViewController.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayCardManageModule.h"

@implementation CJPayBridgePlugin_CJUIComponent

+ (void)registerBridge {
    TTRegisterBridgeMethod;

    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_CJUIComponent, CJUIComponent), @"ttcjpay.CJUIComponent");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)CJUIComponentWithParam:(NSDictionary *)data
                      callback:(TTBridgeCallback)callback
                        engine:(id <TTBridgeEngine>)engine
                    controller:(UIViewController *)controller {
    CJPayBizWebViewController *webViewController = (CJPayBizWebViewController *)controller;
    if (webViewController == nil || ![webViewController isKindOfClass:CJPayBizWebViewController.class]) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"webViewController初始化失败");
        return;
    }

    NSDictionary *dic = (NSDictionary *)data;
    NSString *compID = [dic cj_stringValueForKey:@"id"];
    NSString *uid = [dic cj_stringValueForKey:@"uid"];
    NSString *merchantID = [dic cj_stringValueForKey:@"merchant_id"];
    NSString *appID = [dic cj_stringValueForKey:@"app_id"];

    if (!(compID && compID.length > 0)) {
        TTBRIDGE_CALLBACK_FAILED
        return;
    }

    CJPayPassKitBizRequestModel *model = [CJPayPassKitBizRequestModel new];
    model.appID = appID;
    model.merchantID = merchantID;
    model.uid = uid;
    model.sessionKey = uid;

    if ([compID isEqualToString:@"ResetPass"]) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"不支持该能力");
    } else if ([compID isEqualToString:@"CardList"]) {
        // 银行卡列表
        [CJ_OBJECT_WITH_PROTOCOL(CJPayCardManageModule) i_openBankCardListWithMerchantId:model.merchantID appId:model.appID userId:model.sessionKey];
    }

    TTBRIDGE_CALLBACK_SUCCESS

}

@end
