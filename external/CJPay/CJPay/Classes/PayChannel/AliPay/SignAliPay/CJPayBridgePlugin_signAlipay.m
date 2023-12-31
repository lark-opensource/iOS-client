//
//  CJPayBridgePlugin_signAlipay.m
//  Pods
//
//  Created by mengxin on 2021/3/8.
//

#import "CJPayBridgePlugin_signAlipay.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPaySignChannel.h"

@implementation CJPayBridgePlugin_signAlipay

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_signAlipay, signAlipay), @"ttcjpay.signAlipay");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)signAlipayWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    CJPaySignChannel *signChannel = [CJPaySignChannel new];
    [signChannel signActionWithDataDict:param completionBlock:^(NSDictionary * _Nonnull resultDic) {
        CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, resultDic, nil);
    }];
}

@end

