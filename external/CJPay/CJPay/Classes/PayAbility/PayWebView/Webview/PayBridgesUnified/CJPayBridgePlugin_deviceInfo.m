//
//  CJPayBridgePlugin_deviceInfo.m
//  CJPay
//
//  Created by liyu on 2020/1/7.
//

#import "CJPayBridgePlugin_deviceInfo.h"

#import "CJPayRequestParam.h"

#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPaySDKMacro.h"

@implementation CJPayBridgePlugin_deviceInfo

+ (void)registerBridge
{
    TTRegisterBridgeMethod
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_deviceInfo, deviceInfo), @"ttcjpay.deviceInfo");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)deviceInfoWithParam:(NSDictionary *)param
                   callback:(TTBridgeCallback)callback
                     engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller
{
    NSInteger type = [param cj_integerValueForKey:@"type"];
    NSDictionary *result = @{};
    if (type == 1) {
        result = @{
            @"dev_info": [CJPayRequestParam riskInfoDict] ?: @{},
            @"fin_info": [[CJPayRequestParam getFinanceRisk:nil] cj_objectForKey:@"finance_risk"] ?: @{}
        };
    } else {
        if ([CJPayRequestParam riskInfoDict].count > 0) {
            result = [CJPayRequestParam riskInfoDict];
        }
    }
    if (callback) {
        callback(TTBridgeMsgSuccess, result, nil);
    }

}

@end
