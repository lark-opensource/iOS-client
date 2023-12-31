//
//  CJPayBridgePlugin_getPhoneInfo.m
//  CJPay-Pods-Aweme
//
//  Created by 尚怀军 on 2020/11/21.
//

#import "CJPayBridgePlugin_getPhoneInfo.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPayProtocolManager.h"

@implementation CJPayBridgePlugin_getPhoneInfo

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_getPhoneInfo, getPhoneInfo), @"ttcjpay.getPhoneInfo");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)getPhoneInfoWithParam:(NSDictionary *)param
                     callback:(TTBridgeCallback)callback
                       engine:(id<TTBridgeEngine>)engine
                   controller:(UIViewController *)controller {
    CJ_DECLARE_ID_PROTOCOL(CJPayCarrierLoginProtocol);
    if (objectWithCJPayCarrierLoginProtocol) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayCarrierLoginProtocol) getCarrierPhoneNumWithCompletion:^(NSDictionary * _Nullable data, NSError * _Nullable error) {
            NSMutableDictionary *mutableResultDic = [NSMutableDictionary dictionaryWithDictionary:data ?: @{}];
            if (!error) {
                mutableResultDic[@"result"] = @(1);
            } else {
                mutableResultDic[@"result"] = @(0);
            }
            callback(TTBridgeMsgSuccess, mutableResultDic, nil);
        }];
    } else {
        TTBRIDGE_CALLBACK_WITH_MSG(TTBridgeMsgFailed, @"宿主未实现该能力")
    }
}


@end
