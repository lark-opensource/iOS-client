//
//  CJPayBridgePlugin_goWithdraw.m
//  CJPay
//
//  Created by 徐波 on 2020/4/3.
//

#import "CJPayBridgePlugin_goWithdraw.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPaySDKMacro.h"
#import "CJPayUserCenter.h"
#import "CJPayBDOrderResultResponse.h"

@implementation CJPayBridgePlugin_goWithdraw
+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_goWithdraw, goWithdraw), @"ttcjpay.goWithdraw");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)goWithdrawWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
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
    [[CJPayUserCenter sharedInstance] withdrawBalance:paramDic completion:^(BDUserCenterCode resultCode, CJPayBDOrderResultResponse * _Nullable response) {
        if (resultCode == BDUserCenterCodeSuccess) {
            callback(TTBridgeMsgSuccess, @{@"resultcode": @(resultCode), @"response": CJString([response toJSONString])}, nil);
        } else {
            CJPayLogInfo(@"提现失败， %ld, %@", resultCode, response);
        }
    }];
}
@end
