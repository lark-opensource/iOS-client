//
//  CJPayBridgePlugin_pay.m
//  CJPay
//
//  Created by liyu on 2020/1/15.
//

#import "CJPayBridgePlugin_pay.h"

#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPayChannelManagerModule.h"
#import "CJPaySDKMacro.h"
#import "CJPayProtocolManager.h"

@implementation CJPayBridgePlugin_pay

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_pay, pay), @"ttcjpay.pay");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)payWithParam:(NSDictionary *)data
            callback:(TTBridgeCallback)callback
              engine:(id<TTBridgeEngine>)engine
          controller:(UIViewController *)controller
{
    if (!(data && [data isKindOfClass: NSDictionary.class])) {
        CJ_CALL_BLOCK(callback, TTBridgeMsgFailed, @{@"code": @"1", @"msg": @"jsb data数据有误",@"raw_code":@""}, nil);
        return;
    }
    
    NSDictionary *dic = [(NSDictionary *)data cj_dictionaryValueForKey:@"data"];
    NSDictionary *sdkInfo = [dic cj_dictionaryValueForKey:@"sdk_info"];
    NSDictionary *tradeInfo = [dic cj_dictionaryValueForKey:@"trade_info"];
    if (sdkInfo && sdkInfo.count > 0) {
        int payType = 0; // 2：支付宝， 1： 微信
        if (tradeInfo && tradeInfo.count > 0) {
            payType = [tradeInfo cj_intValueForKey:@"way"];
        }
        
        NSString *unInstallMsg = @"支付失败，未引入相应支付能力";
        CJPayChannelType payChannelType = CJPayChannelTypeNone;
        if (payType == 2) {
            payChannelType = CJPayChannelTypeTbPay;
            unInstallMsg = @"支付失败，未引入支付宝";
        } else if (payType == 1) {
            payChannelType = CJPayChannelTypeWX;
            unInstallMsg = @"支付失败，未引入微信";
        }
        
        [CJ_OBJECT_WITH_PROTOCOL(CJPayChannelManagerModule) i_payActionWithChannel:payChannelType
                                                                          dataDict:[sdkInfo copy]
                                                                   completionBlock:^ (CJPayChannelType channelType, CJPayResultType resultType, NSString *errCode) {
            switch (resultType) {
                case CJPayResultTypeSuccess:
                    CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"0", @"msg": @"支付成功", @"raw_code":CJString(errCode)}, nil);
                    CJPayLogInfo(@"支付成功");
                    break;
                case CJPayResultTypeCancel:
                    CJ_CALL_BLOCK(callback, TTBridgeMsgFailed, @{@"code": @"2", @"msg": @"支付取消",@"raw_code":CJString(errCode)}, nil);
                    break;
                case CJPayResultTypeUnInstall:
                    CJ_CALL_BLOCK(callback, TTBridgeMsgFailed, @{@"code": @"3", @"msg": unInstallMsg, @"raw_code":CJString(errCode)}, nil);
                    break;
                case CJPayResultTypeProcessing:
                    CJ_CALL_BLOCK(callback, TTBridgeMsgFailed, @{@"code": @"5",@"msg":@"支付处理中",@"raw_code":CJString(errCode)}, nil);
                    break;
                case CJPayResultTypeBackToForeground:
                    CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"6", @"msg": @"支付结果未知：用户手动切换App",@"raw_code":CJString(errCode)}, nil);
                    break;
                default:
                    CJ_CALL_BLOCK(callback, TTBridgeMsgFailed, @{@"code": @"1", @"msg": @"支付失败",@"raw_code":CJString(errCode)}, nil);
                    break;
            }
        }];
    } else {
        CJ_CALL_BLOCK(callback, TTBridgeMsgFailed, @{@"code": @"1", @"msg": @"sdk_info数据有误",@"raw_code":@""}, nil);
    }
    
}

@end
