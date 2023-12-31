//
//  CJPayBridgePlugin_authAlipay.m
//  CJPay
//
//  Created by 王新华 on 3/2/20.
//

#import "CJPayBridgePlugin_authAlipay.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPayAuthManager.h"
#import "CJPaySDKMacro.h"

@implementation CJPayBridgePlugin_authAlipay

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_authAlipay, authAlipay), @"ttcjpay.authAlipay");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)authAlipayWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    NSString *infoStr = [param cj_stringValueForKey:@"infoStr"];
    [[CJPayAuthManager shared] authAliPay:infoStr callback:^(NSDictionary * _Nonnull resultDic) {
        CJPayLogInfo(@"auth: %@", resultDic);
        if (callback) {
            callback(TTBridgeMsgSuccess, resultDic, nil);
        }
    }];
}

@end
