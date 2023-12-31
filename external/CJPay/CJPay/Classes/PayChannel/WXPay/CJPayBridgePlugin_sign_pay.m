//
//  CJPayBridgePlugin_sign_pay.m
//  CJPay
//
//  Created by liyu on 2020/2/16.
//

#import "CJPayBridgePlugin_sign_pay.h"
#import "NSDictionary+CJPay.h"

#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPayChannelManagerModule.h"
#import "CJPayProtocolManager.h"
#import "CJPayPrivacyMethodUtil.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "NSDictionary+CJPay.h"
#import "CJPayBridgeBlockRegister.h"

@implementation CJPayBridgePlugin_sign_pay


+ (void)registerBridge {
    TTRegisterBridgeMethod;
    //BPEA跨端改造，使用block方式注册"ttcjpay.sign_pay"的jsb
    [CJPayBridgeBlockRegister registerBridgeName:@"ttcjpay.sign_pay"
                                      engineType:TTBridgeRegisterAll
                                        authType:TTBridgeAuthProtected
                                         domains:nil
                               needBridgeCommand:YES
                                         handler:^(NSDictionary * _Nullable params, TTBridgeCallback callback, id<TTBridgeEngine> engine, UIViewController * _Nullable controller, TTBridgeCommand * _Nullable command) {
        
        TTBridgePlugin *pluginSignPay = [CJPayBridgeBlockRegister associatedPluginsOnEngine:engine pluginClassName:NSStringFromClass(self)];
        if ([pluginSignPay isKindOfClass:CJPayBridgePlugin_sign_pay.class]) {
            [(CJPayBridgePlugin_sign_pay *)pluginSignPay sign_payWithParam:params callback:callback engine:engine controller:controller command:command];
        } else {
            TTBRIDGE_CALLBACK_FAILED;
        }
    }];
}

- (void)sign_payWithParam:(NSDictionary *)data
                 callback:(TTBridgeCallback)callback
                   engine:(id<TTBridgeEngine>)engine
               controller:(UIViewController *)controller
                  command:(TTBridgeCommand *)command
{
    if (data && [data isKindOfClass:NSDictionary.class]) {
        NSDictionary *dic = [(NSDictionary *)data cj_dictionaryValueForKey:@"data"];
        NSDictionary *sdkInfo = [dic cj_dictionaryValueForKey:@"sdk_info"];
        NSString *refer = [data cj_stringValueForKey:@"referer"];
        if (sdkInfo && sdkInfo.count > 0) {
            if (sdkInfo[@"url"]) {
                // 预备好回调
                [CJ_OBJECT_WITH_PROTOCOL(CJPayChannelManagerModule) i_payActionWithChannel:CJPayChannelTypeCustom dataDict:@{@"refer" : CJString(refer)} completionBlock:^(CJPayChannelType channelType, CJPayResultType resultType, NSString *errCode) {
                    switch (resultType) {
                        case CJPayResultTypeSuccess:
                            CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"0", @"msg": @"支付成功",@"raw_code":CJString(errCode)}, nil);
                            break;
                        case CJPayResultTypeCancel:
                            CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"2", @"msg": @"支付取消",@"raw_code":CJString(errCode)}, nil);
                            break;
                        case CJPayResultTypeUnInstall:{
                            CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"3", @"msg": @"未安装微信",@"raw_code":CJString(errCode)}, nil);
                        }
                            break;
                        case CJPayResultTypeProcessing:
                            CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"5", @"msg": @"支付处理中",@"raw_code":CJString(errCode)}, nil);
                            break;
                        case CJPayResultTypeBackToForeground:
                            CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"6", @"msg": @"支付结果未知：用户手动切换App",@"raw_code":CJString(errCode)}, nil);
                            break;
                        default:
                            CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"1", @"msg": @"支付失败",@"raw_code":CJString(errCode)}, nil);
                            break;
                    }
                }];
                // 调用AppJump敏感方法，需走BPEA鉴权
                [CJPayPrivacyMethodUtil applicationOpenUrl:[NSURL URLWithString:[sdkInfo btd_stringValueForKey:@"url"]]
                                                withPolicy:@"bpea-caijing_jsb_open_sign_pay"
                                             bridgeCommand:command
                                                   options:@{}
                                         completionHandler:^(BOOL success, NSError * _Nullable error) {
                    
                    if (error) {
                        CJPayLogError(@"error in bpea-caijing_jsb_open_sign_pay");
                        TTBRIDGE_CALLBACK_FAILED;
                    }
                }];
                return;
            }
        }
    }
    TTBRIDGE_CALLBACK_FAILED;
}


@end
