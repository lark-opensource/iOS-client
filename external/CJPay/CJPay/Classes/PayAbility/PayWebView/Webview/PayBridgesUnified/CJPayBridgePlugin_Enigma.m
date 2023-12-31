//
//  CJPayBridgePlugin_Enigma.m
//  CJPay
//
//  Created by liyu on 2020/1/14.
//

#import "CJPayBridgePlugin_Enigma.h"
#import "NSDictionary+CJPay.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPaySafeUtil.h"
#import "CJPaySDKMacro.h"

@implementation CJPayBridgePlugin_Enigma

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_Enigma, encrypt), @"ttcjpay.encrypt");
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_Enigma, decrypt), @"ttcjpay.decrypt");
    
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)encryptWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller
{
    NSDictionary *dic = (NSDictionary *)param;
    NSString *dataStr = [dic cj_stringValueForKey:@"data"];
    NSString *publicKey = [dic cj_stringValueForKey:@"public_key"];
    NSString *encryptData;
    if ([CJPaySafeManager isEngimaISec] ) {
        NSString *cfcaKey = [dic cj_stringValueForKey:@"isec_key"];
        encryptData = [CJPaySafeUtil encryptContentFromH5:dataStr token:cfcaKey];
    } else {
        if (Check_ValidString(publicKey)) {
            encryptData = [CJPaySafeUtil encryptContentFromH5:dataStr token:publicKey];
        } else {
            encryptData = [CJPaySafeUtil encryptContentFromH5:dataStr];
        }
    }
    TTBridgeMsg code = TTBridgeMsgSuccess;
    if (encryptData == nil || encryptData.length < 1) {
        code = TTBridgeMsgFailed;
        encryptData = @"";
    }
    
    if (callback) {
        callback(code, @{@"code": @([self innerCodeFrom:code]),
                         @"data": @{@"value": CJString(encryptData)}, @"version": [CJPaySafeManager secureInfoVersion]}, nil);
    }
}

- (void)decryptWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller
{
    NSDictionary *dic = (NSDictionary *)param;
    NSString *dataStr = [dic cj_stringValueForKey:@"data"];
    
    NSString *decryptData = [CJPaySafeUtil decryptContentFromH5:dataStr];
    TTBridgeMsg code = TTBridgeMsgSuccess;
    if (decryptData == nil || decryptData.length < 1) {
        code = TTBridgeMsgFailed;
        decryptData = @"";
    }
    
    if (callback) {
        callback(code, @{@"code": @([self innerCodeFrom:code]),
                         @"data": @{@"value": CJString(decryptData)}}, nil);
    }
}

- (NSInteger)innerCodeFrom:(TTBridgeMsg)outterCode
{
    return (outterCode == TTBridgeMsgSuccess) ? 0 : 2;
}

@end
