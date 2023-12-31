//
//  CJPayBizURLBuilder.m
//  Pods
//
//  Created by 王新华 on 2021/9/7.
//

#import "CJPayBizURLBuilder.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPaySDKMacro.h"

@implementation CJPayBizURLBuilder

+ (NSString *)generateURLForType:(CJPayURLSceneType) urlSceneType withAppId:(NSString *)appId withMerchantId:(NSString *)merchantId otherParams:(NSDictionary *)otherParams {
    NSString *url = @"";
    switch (urlSceneType) {
        case CJPayURLSceneWebCardList:
            url = [NSString stringWithFormat:@"%@/usercenter/cards",[CJPayBaseRequest bdpayH5DeskServerHostString]];
            break;
        case CJPayURLSceneWebTradeRecord:
            url = [NSString stringWithFormat:@"%@/usercenter/transaction/list",[CJPayBaseRequest bdpayH5DeskServerHostString]];
            break;
        case CJPayURLSceneWebBalanceWithdraw:
            url = [NSString stringWithFormat:@"%@/cashdesk_withdraw",[CJPayBaseRequest bdpayH5DeskServerHostString]];
            break;
            
        default:
            CJPayLogAssert(NO, @"传入不能识别的URLScene");
            break;
    }
    NSMutableDictionary *mutableParams = [NSMutableDictionary new];
    [mutableParams addEntriesFromDictionary:otherParams];
    [mutableParams cj_setObject:appId forKey:@"app_id"];
    [mutableParams cj_setObject:merchantId forKey:@"merchant_id"];

    return [CJPayCommonUtil appendParamsToUrl:url params:[mutableParams copy]];
}

@end
