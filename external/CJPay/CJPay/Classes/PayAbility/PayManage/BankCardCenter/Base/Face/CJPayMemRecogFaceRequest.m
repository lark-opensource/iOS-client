//
//  CJPayMemRecogFaceRequest.m
//  Pods
//
//  Created by 尚怀军 on 2020/12/30.
//

#import "CJPayMemRecogFaceRequest.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayMemberFaceVerifyResponse.h"
#import "CJPaySafeUtilsHeader.h"

@implementation CJPayMemRecogFaceRequest

+ (void)startRequestWithParams:(NSDictionary *)params
                    completion:(void(^)(NSError *error, CJPayMemberFaceVerifyResponse *response))completionBlock {
    NSDictionary *requestParams = [self p_buildRequestParamsWithBizParams:params];
    [self startRequestWithUrl:[self buildServerUrl]
                requestParams:requestParams
                     callback:^(NSError *error, id jsonObj) {
        CJPayMemberFaceVerifyResponse *response = [[CJPayMemberFaceVerifyResponse alloc] initWithDictionary:jsonObj error:nil];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}


+ (NSString *)apiPath {
    return @"/bytepay/member_product/verify_live_detection_result";
}

+ (NSDictionary *)p_buildRequestParamsWithBizParams:(NSDictionary *)bizParams
{
    NSMutableDictionary *requestParams = [self buildBaseParams];
    
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionaryWithDictionary:bizParams];
    [bizContentParams cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    [bizContentParams cj_setObject:[self p_secureRequestParams:bizParams] forKey:@"secure_request_params"];

    [requestParams cj_setObject:[bizContentParams cj_toStr] forKey:@"biz_content"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"app_id"] forKey:@"app_id"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"merchant_id"] forKey:@"merchant_id"];
    
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    return [requestParams copy];
}

+ (NSDictionary *)p_secureRequestParams:(NSDictionary *)contentDic {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic addEntriesFromDictionary:[CJPaySafeManager secureInfo]];
    NSMutableArray *fields = [NSMutableArray array];
    if ([contentDic valueForKeyPath:@"live_detect_data"]) {
        [fields addObject:@"live_detect_data"];
    }
    
    [dic cj_setObject:fields forKey:@"fields"];
    return dic;
}

@end
