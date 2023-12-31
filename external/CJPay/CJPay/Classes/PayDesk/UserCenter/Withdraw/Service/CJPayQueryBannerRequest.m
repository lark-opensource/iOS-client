//
//  CJPayQueryBannerRequest.m
//  Pods
//
//  Created by mengxin on 2020/12/24.
//

#import "CJPayQueryBannerRequest.h"
#import "CJPayBannerResponse.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"
#import "CJPayBaseRequest+BDPay.h"

@implementation CJPayQueryBannerRequest

+ (void)startWithAppId:(NSString *)appId
            merchantId:(NSString *)merchantId
              bizParam:(NSDictionary *)bizParam
                completion:(void(^)(NSError * _Nullable error, CJPayBannerResponse *response))completionBlock{
    NSDictionary *requestParams = [self p_buildRequestParamsWithAppId:appId merchntId:merchantId bizParam:bizParam];
    [self startRequestWithUrl:[self deskServerUrlString] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayBannerResponse *response = [[CJPayBannerResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSDictionary *)p_buildRequestParamsWithAppId: (NSString *)appId
                                      merchntId: (NSString *)merchantId
                                       bizParam:(NSDictionary *)bizParam {
    
    NSMutableDictionary *requestParams = [self buildBaseParams];
    NSMutableDictionary *bizParams = [self p_buildBizParamsWithAppId:appId merchantId:merchantId].mutableCopy;
    [bizParams addEntriesFromDictionary:bizParam];
    
    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:bizParams];
    [requestParams cj_setObject:appId forKey:@"app_id"];
    [requestParams cj_setObject:bizContentString forKey:@"biz_content"];
    [requestParams cj_setObject:merchantId forKey:@"merchant_id"];
    [requestParams cj_setObject:@"bytepay.promotion_put.withdraw_success_page_place" forKey:@"method"];
    
    return [requestParams copy];
}

+ (NSDictionary *)p_buildBizParamsWithAppId: (NSString *)appId
                                 merchantId: (NSString *)merchantId {
    NSDictionary *bizParam = @{
        @"place_no": @"PP202012221000251153431234",
        @"aid": CJString([CJPayRequestParam gAppInfoConfig].appId),
        @"merchant_id": CJString(merchantId),
        @"merchant_app_id": CJString(appId),
        @"device_system": @"ios"
    };
    
    return bizParam;
}

@end
