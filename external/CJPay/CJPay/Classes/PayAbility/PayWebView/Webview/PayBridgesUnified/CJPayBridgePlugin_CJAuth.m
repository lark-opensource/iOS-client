//
//  CJPayBridgePlugin_CJAuth.m
//  BDAlogProtocol
//
//  Created by bytedance on 2020/7/22.
//

#import "CJPayBridgePlugin_CJAuth.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPayBizWebViewController.h"
#import "CJPayAuthService.h"
#import "CJPayAPI.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"

@interface CJPayBridgePlugin_CJAuth() <CJPayAPIDelegate>

@property (nonatomic, strong) TTBridgeCallback callback;

@end

@implementation CJPayBridgePlugin_CJAuth

+ (void)registerBridge
{
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_CJAuth, CJAuth), @"ttcjpay.CJAuth");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)CJAuthWithParam:(NSDictionary *)data
                      callback:(TTBridgeCallback)callback
                        engine:(id<TTBridgeEngine>)engine
                    controller:(UIViewController *)controller
{
    self.callback = callback;
    NSMutableDictionary *authData = [NSMutableDictionary new];
    NSMutableDictionary *authStyleData = [NSMutableDictionary new];
    [authData cj_setObject:[data valueForKey:@"app_id"] forKey:@"app_id"];
    [authData cj_setObject:[data valueForKey:@"merchant_id"] forKey:@"merchant_id"];
    [authStyleData cj_setObject:[data valueForKey:@"theme"] forKey:@"theme"];
    [authStyleData cj_setObject:[data valueForKey:@"scene"] forKey:@"scene"];
    NSDictionary *styleDic =[data cj_dictionaryValueForKey:@"style"];
    [authStyleData cj_setObject:styleDic forKey:@"style"];
    [authData cj_setObject:authStyleData forKey:@"data"];
//    [CJPayAPI requestAuth:authData withDelegate:self];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayAuthService) i_authWith:authData delegate:self]; //TODO: 测试一下

}

- (void)onResponse:(CJPayAPIBaseResponse *)response
{
    NSInteger resCode = 0;

    switch (response.error.code) {
        case CJPayErrorCodeSuccess:
            resCode = 0;
            break;
        case CJPayErrorCodeFail:
            resCode = 1;
            break;
        case CJPayErrorCodeCancel:
            resCode = 2;
            break;
        case CJPayErrorCodeUnLogin:
            resCode = 3;
            break;
        case CJPayErrorCodeAuthrized:
            resCode = 4;
            break;
        case CJPayErrorCodeUnnamed:
            resCode = 5;
            break;
        case CJPayErrorCodeAuthQueryError:
            resCode = 6;
            break;
        default:
            break;
    }
    if (self.callback) {
        self.callback(TTBridgeMsgSuccess, @{ @"code": @(resCode)}, nil);
    }
}


@end
