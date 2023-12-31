//
//  CJPayMemGetOneKeySignBankUrlRequest.m
//  Pods
//
//  Created by renqiang on 2021/6/3.
//

#import "CJPayMemGetOneKeySignBankUrlRequest.h"
#import "CJPayMemGetOneKeySignBankUrlResponse.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPaySDKMacro.h"

@implementation CJPayMemGetOneKeySignBankUrlRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams completion:(void (^)(NSError * _Nonnull, CJPayMemGetOneKeySignBankUrlResponse * _Nonnull))completionBlock {
    NSDictionary *requestParams = [self p_buildRequestParamsWithBizParams:bizParams];
    
    [self startRequestWithUrl:[self buildServerUrl] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayMemGetOneKeySignBankUrlResponse *response = [[CJPayMemGetOneKeySignBankUrlResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/get_one_key_sign_bank_url";
}

+ (NSDictionary *)p_buildRequestParamsWithBizParams:(NSDictionary *)bizParams {
    NSMutableDictionary *requestParams = [self buildBaseParams];
    
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionaryWithDictionary:@{
        @"member_biz_order_no" : CJString([bizParams cj_stringValueForKey:@"member_biz_order_no"])
    }];
    
    [requestParams cj_setObject:[bizContentParams cj_toStr] forKey:@"biz_content"];
    [requestParams cj_setObject:[bizParams cj_objectForKey:@"app_id"] forKey:@"app_id"];
    [requestParams cj_setObject:[bizParams cj_objectForKey:@"merchant_id"] forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    
    return [requestParams copy];
}

@end
