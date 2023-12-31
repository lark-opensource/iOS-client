//
//  CJPayBridgePlugin_goRecharge.m
//  Pods
//
//  Created by 王新华 on 3/15/20.
//

#import "CJPayBridgePlugin_goRecharge.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPaySDKMacro.h"
#import "CJPayUserCenter.h"
#import "CJPayBDOrderResultResponse.h"

@implementation CJPayBridgePlugin_goRecharge

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_goRecharge, goRecharge), @"ttcjpay.goRecharge");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)goRechargeWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    NSString *paramStr = [param cj_stringValueForKey:@"params"];
    if (!Check_ValidString(paramStr)) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"params 参数为空");
        return;
    }
    NSDictionary *paramDic = [CJPayCommonUtil jsonStringToDictionary:paramStr];
    if (!paramDic || paramDic.count < 1) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"params 转成map失败");
        return;
    }
    [[CJPayUserCenter sharedInstance] rechargeBalance:paramDic completion:^(BDUserCenterCode resultCode, CJPayBDOrderResultResponse * _Nullable response) {
        if (resultCode == BDUserCenterCodeSuccess) {
            callback(TTBridgeMsgSuccess, @{@"resultcode": @(resultCode), @"response": CJString([response toJSONString])}, nil);
        } else {
            CJPayLogInfo(@"充值失败， %ld, %@", resultCode, response);
        }
    }];
}

@end
