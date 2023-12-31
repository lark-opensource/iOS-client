//
//  CJPayMemberSignRequest.m
//  CJPay
//
//  Created by 尚怀军 on 2019/10/18.
//

#import "CJPayMemberSignRequest.h"
#import "CJPayMemberSignResponse.h"
#import <JSONModel/JSONModel.h>
#import "CJPayRequestParam.h"
#import "NSMutableDictionary+CJPay.h"
#import "CJPayCommonUtil.h"
#import "CJPaySDKMacro.h"

@implementation CJPayMemberSignRequest

// 三方支付验证短信签约绑卡
+ (void)startWithBDPayVerifySMSBaseParam:(NSDictionary *)baseParam
                                bizParam:(NSDictionary *)bizParam
                              completion:(void(^)(NSError *error, CJPaySignSMSResponse *response))completionBlock{
    NSDictionary *requestDic = [self buildRequestParamsWithULBDPayBaseParam:baseParam bizParam:bizParam];
    [self startRequestWithUrl:[self buildServerUrl]
                requestParams:requestDic
                     callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPaySignSMSResponse *response = [[CJPaySignSMSResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSDictionary *)buildRequestParamsWithULBDPayBaseParam:(NSDictionary *)baseParam
                                                bizParam:(NSDictionary *)bizParam{
    NSMutableDictionary *requestParams = [self buildBaseParams];
    //公共参数
    [requestParams addEntriesFromDictionary:baseParam];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    //业务参数
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionaryWithDictionary:bizParam];
   
    //风控信息
//    [bizContentParams cj_setObject:[CJPayRequestParam fingerPrintDict] forKey:@"risk_info"];
    NSDictionary *riskDict = [NSDictionary dictionaryWithObject:[CJPayRequestParam riskInfoDict] forKey:@"risk_str"];
    [bizContentParams cj_setObject:riskDict forKey:@"risk_info"];
    
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:bizContentParams] forKey:@"biz_content"];
    return requestParams;

}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/sign_card";
}

@end
