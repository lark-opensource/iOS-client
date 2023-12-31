//
//  CJPayCardOCRRequest.m
//  CJPay
//
//  Created by 尚怀军 on 2020/5/18.
//

#import "CJPayCardOCRRequest.h"
#import "CJPayCardOCRResponse.h"
#import "CJPayRequestParam.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayUIMacro.h"
#import "CJPaySafeManager.h"

@implementation CJPayCardOCRRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams completion:(void (^)(NSError * _Nonnull, CJPayCardOCRResponse * _Nonnull))completionBlock {
    NSDictionary *requestParams = [self p_buildRequestParamsWithBizParams:bizParams];
    
    [self startRequestWithUrl:[self buildServerUrl] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayCardOCRResponse *response = [[CJPayCardOCRResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/get_card_no_by_ocr";
}

//构造参数
+ (NSDictionary *)p_buildRequestParamsWithBizParams:(NSDictionary *)bizParams {
    NSMutableDictionary *requestParams = [self buildBaseParams];
    
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    [bizContentParams cj_setObject:[CJPayRequestParam getMergeRiskInfoWithBizParams:bizParams] forKey:@"risk_info"];
    [bizContentParams cj_setObject:[bizParams cj_stringValueForKey:@"img_data"] forKey:@"img_data"];
    [bizContentParams cj_setObject:[bizParams cj_stringValueForKey:@"ext"] forKey:@"ext"];
    [bizContentParams cj_setObject:[self p_secureRequestParams] forKey:@"secure_request_params"];
    
    [requestParams cj_setObject:[bizContentParams cj_toStr] forKey:@"biz_content"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"app_id"] forKey:@"app_id"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"merchant_id"] forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    return [requestParams copy];
}

+ (NSDictionary *)p_secureRequestParams{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic addEntriesFromDictionary:[CJPaySafeManager secureInfo]];
    [dic cj_setObject:@[@"ext",@"img_data"]
               forKey:@"fields"];
    return dic;
}

@end
