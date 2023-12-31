//
//  CJPayBridgePlugin_smsVerify.m
//  Aweme
//
//  Created by chenbocheng.moon on 2022/11/23.
//

#import "CJPayBridgePlugin_smsVerify.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPayUIMacro.h"
#import "CJPayBindCardManager.h"

@interface CJPayBridgePlugin_smsVerify()

@end

@implementation CJPayBridgePlugin_smsVerify

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_smsVerify, smsVerify), @"ttcjpay.smsVerify");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)smsVerifyWithParam:(NSDictionary *)param
            callback:(TTBridgeCallback)callback
              engine:(id<TTBridgeEngine>)engine
          controller:(UIViewController *)controller {
    if (callback) {
        [CJPayBindCardManager sharedInstance].verifySMSCompletionBlock = ^() {
            CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code":@(0), @"msg":@"success"}, nil);
        };
    }
    [[CJPayBindCardManager sharedInstance] createNormalOrderAndSendSMS:param];
}

@end
