//
//  CJPayMemCardBinInfoRequest.m
//  Pods
//
//  Created by 尚怀军 on 2020/2/20.
//

#import "CJPayMemCardBinInfoRequest.h"
#import "CJPayUIMacro.h"
#import "CJPayRequestParam.h"
#import "CJPayPassKitSafeUtil.h"
#import "CJPayBaseRequest+BDPay.h"

@implementation CJPayMemCardBinInfoRequest

+ (void)startWithAppId:(NSString *)appId
            merchantId:(NSString *)merchantId
     specialMerchantId:(NSString *)specialMerchantId
           signOrderNo:(NSString *)signOrderNo
               cardNum:(NSString *)cardNum
          isFuzzyMatch:(BOOL)isFuzzyMatch
        cardBindSource:(CJPayCardBindSourceType)cardBindSource
            completion:(void(^)(NSError * _Nullable error,CJPayMemCardBinResponse  *response))completionBlock {
    NSDictionary *requestParam = [self p_buildRequestParams:appId
                                                 merchantId:merchantId
                                          specialMerchantId:specialMerchantId
                                                signOrderNo:signOrderNo
                                                    cardNum:cardNum
                                               isFuzzyMatch:isFuzzyMatch
                                             cardBindSource:cardBindSource];
    
    [self startRequestWithUrl:[self buildServerUrl] requestParams:requestParam callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayMemCardBinResponse *response = [[CJPayMemCardBinResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

//构造参数
+ (NSDictionary *)p_buildRequestParams:(NSString *)appId
                            merchantId:(NSString *)merchantId
                     specialMerchantId:(NSString *)specialMerchantId
                           signOrderNo:(NSString *)signOrderNo
                               cardNum:(NSString *)cardNum
                          isFuzzyMatch:(BOOL)isFuzzyMatch
                        cardBindSource:(CJPayCardBindSourceType)cardBindSource {
    
    NSMutableDictionary *requestParams = [self buildBaseParams];
    [requestParams cj_setObject:CJString(appId) forKey:@"app_id"];
    [requestParams cj_setObject:CJString(merchantId) forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    
    NSMutableDictionary *bizParams = [NSMutableDictionary dictionary];
    [bizParams cj_setObject:CJString(signOrderNo) forKey:@"sign_order_no"];
    [bizParams cj_setObject:CJString(specialMerchantId) forKey:@"smch_id"];
    [bizParams cj_setObject:CJString(cardNum) forKey:@"card_no"];
    [bizParams cj_setObject:@(isFuzzyMatch) forKey:@"is_fuzzy_match"];

    //风控相关参数
    [bizParams cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    
    [bizParams cj_setObject:[CJPayPassKitSafeUtil pMemberSecureRequestParams:bizParams] forKey:@"secure_request_params"];
    NSString * bizContent = [CJPayCommonUtil dictionaryToJson:bizParams];
    [requestParams cj_setObject:bizContent forKey:@"biz_content"];
    
    return [requestParams copy];
}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/get_card_bin";
}

@end
