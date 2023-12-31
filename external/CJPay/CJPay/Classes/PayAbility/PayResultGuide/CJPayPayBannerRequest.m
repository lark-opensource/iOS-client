//
//  CJPayPayBannerRequest.m
//  Pods
//
//  Created by chenbocheng on 2021/8/3.
//

#import "CJPayPayBannerRequest.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"

@implementation CJPayPayBannerRequest

+ (void)startRequestWithAppId:(NSString *)appId
                   outTradeNo:(NSString *)outTradeNo
                   merchantId:(NSString *)merchantId
                          uid:(NSString *)uid
                       amount:(NSInteger)amount
                   completion:(void (^)(NSError * _Nonnull, CJPayPayBannerResponse * _Nonnull))completionBlock{
    [self startRequestWithUrl:[self deskServerUrlString] requestParams:[self p_buildRequestParamsWithAppId:appId      outTradeNo:outTradeNo merchantId:merchantId uid:uid amount:amount] callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayPayBannerResponse *bannerResponse = [[CJPayPayBannerResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, bannerResponse);
    }];
}

+ (NSDictionary *)p_buildRequestParamsWithAppId:(NSString *)appId
                                     outTradeNo:(NSString *)outTradeNo
                                     merchantId:(NSString *)merchantId
                                            uid:(NSString *)uid
                                         amount:(NSInteger)amount{
    NSMutableDictionary *requestParams = [self buildBaseParams];
    
    NSDictionary *bizParams = [self p_buildBizParamsWithOutTradeNo:outTradeNo merchantId:merchantId uid:uid amount:amount];
    
    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:bizParams];
    [requestParams cj_setObject:appId forKey:@"app_id"];
    [requestParams cj_setObject:bizContentString forKey:@"biz_content"];
    [requestParams cj_setObject:merchantId forKey:@"merchant_id"];
    [requestParams cj_setObject:@"bytepay.promotion_put.query_put_promotion_for_cashier_pay_success" forKey:@"method"];
    
    return [requestParams copy];
}

+ (NSDictionary *)p_buildBizParamsWithOutTradeNo: (NSString *)outTradeNo
                                      merchantId: (NSString *)merchantId
                                             uid: (NSString *)uid
                                          amount:(NSInteger)amount{
    NSDictionary *bizParam = @{
        @"uid":CJString(uid),
        @"placement_no":@"PP202211180001116311332062",
        @"origin_trade_no":CJString(outTradeNo),
        @"app_version":[CJPayRequestParam appVersion],
        @"order_amount":@(amount).stringValue,
        @"device_platform":@"ios",
        @"merchant_id": CJString(merchantId),
        @"aid":CJString([CJPayRequestParam gAppInfoConfig].appId),
        @"did":CJString([CJPayRequestParam gAppInfoConfig].deviceIDBlock()),
        @"pay_way":@"dypay",
        @"pay_timestamp" : [NSString stringWithFormat:@"%.0lf",[[NSDate date]timeIntervalSince1970]]
    };
    return bizParam;
}

@end
