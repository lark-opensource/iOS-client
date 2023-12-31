//
//  CJPayBridgePlugin_vipInfo.m
//  Aweme
//
//  Created by 尚怀军 on 2022/10/15.
//

#import "CJPayBridgePlugin_vipInfo.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"

@implementation CJPayBridgePlugin_vipInfo

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_vipInfo, vipInfo), @"ttcjpay.vipInfo");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)vipInfoWithParam:(NSDictionary *)param
                callback:(TTBridgeCallback)callback
                  engine:(id<TTBridgeEngine>)engine
              controller:(UIViewController *)controller
{
    NSDictionary *result = @{@"is_vip": @([CJPaySettingsManager shared].currentSettings.isVIP)};
    if (callback) {
        callback(TTBridgeMsgSuccess, result, nil);
    }
}


@end
