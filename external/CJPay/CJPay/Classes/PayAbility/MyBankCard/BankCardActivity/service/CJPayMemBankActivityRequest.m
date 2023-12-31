//
//  CJPayMemBankActivityRequest.m
//  Pods
//
//  Created by xiuyuanLee on 2020/12/30.
//

#import "CJPayMemBankActivityRequest.h"
#import "CJPayMemBankActivityResponse.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayUIMacro.h"

@implementation CJPayMemBankActivityRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                completion:(void (^)(NSError * _Nonnull, CJPayMemBankActivityResponse * _Nonnull))completionBlock {
    NSDictionary *requestParams = [self p_buildRequestParamsWithBizParams:bizParams];
    
    [self startRequestWithUrl:[self deskServerUrlString] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayMemBankActivityResponse *response = [[CJPayMemBankActivityResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSDictionary *)p_buildRequestParamsWithBizParams:(NSDictionary *)bizParams {
    NSMutableDictionary *requestParams = [self buildBaseParams];
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    
    [bizContentParams cj_setObject:[bizParams cj_stringValueForKey:@"title_place_no"] forKey:@"title_place_no"];
    [bizContentParams cj_setObject:[bizParams cj_stringValueForKey:@"bankcard_place_no"] forKey:@"bankcard_place_no"];
    [bizContentParams cj_setObject:[bizParams cj_stringValueForKey:@"aid"] forKey:@"aid"];
    [bizContentParams cj_setObject:[bizParams cj_stringValueForKey:@"uid"] forKey:@"uid"];
    [bizContentParams cj_setObject:[bizParams cj_stringValueForKey:@"did"] forKey:@"did"];
    [bizContentParams cj_setObject:[bizParams cj_stringValueForKey:@"app_version"] forKey:@"app_version"];
    [bizContentParams cj_setObject:@"ios" forKey:@"device_system"];
    [requestParams cj_setObject:[bizContentParams cj_toStr] forKey:@"biz_content"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"app_id"] forKey:@"app_id"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"merchant_id"] forKey:@"merchant_id"];
    [requestParams cj_setObject:@"bytepay.promotion_put.bank_card_management" forKey:@"method"];
    
    return [requestParams copy];
}

@end
