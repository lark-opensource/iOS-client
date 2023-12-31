//
//  CJPayFaceRecogCommonRequest.m
//  Pods
//
//  Created by 尚怀军 on 2022/10/31.
//

#import "CJPayFaceRecogCommonRequest.h"
#import "CJPayBaseRequest+CJPayCustomHost.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"
#import "CJPayFaceRecogCommonResponse.h"

@implementation CJPayFaceRecogCommonRequest

+ (void)startFaceRecogRequestWithBizParams:(NSDictionary *)bizParams
                           completionBlock:(void(^)(NSError *error, CJPayFaceRecogCommonResponse *response))completionBlock {
    NSDictionary *requestParams = [self p_buildRequestParamsWithBizParams:bizParams];
    NSString *urlStr = [NSString stringWithFormat:@"%@/tp/cashier/transfer_pay_method", [self customDeskServerUrlString]];
    [self startRequestWithUrl:urlStr
                requestParams:requestParams
                     callback:^(NSError *error, id jsonObj) {
        NSError *err;
        CJPayFaceRecogCommonResponse *response = [[CJPayFaceRecogCommonResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, err, response);
    }];
}

//构造参数
+ (NSDictionary *)p_buildRequestParamsWithBizParams:(NSDictionary *)bizParams {
    NSMutableDictionary *requestParams = [self buildBaseParams];
    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:bizParams];
    [requestParams cj_setObject:CJString(bizContentString) forKey:@"biz_content"];
    [requestParams cj_setObject:@"tp.cashier.transfer_pay_method" forKey:@"method"];
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:[CJPayRequestParam riskInfoDict]] forKey:@"risk_info"];
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:[CJPayRequestParam commonDeviceInfoDic]] forKey:@"devinfo"];
    return [requestParams copy];
}

@end
