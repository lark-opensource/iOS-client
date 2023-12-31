//
//  CJPayMemberSendSMSRequest.m
//  CJPay
//
//  Created by 尚怀军 on 2019/10/17.
//

#import "CJPayMemberSendSMSRequest.h"
#import "CJPayMemberSignResponse.h"
#import <JSONModel/JSONModel.h>
#import "CJPayRequestParam.h"
#import "CJPayPassKitSafeUtil.h"
#import "NSMutableDictionary+CJPay.h"
#import "CJPayCommonUtil.h"
#import "CJPaySDKMacro.h"


@implementation CJPayMemberSendSMSRequest


// 三方支付绑卡发短信接口
+ (void)startWithBDPaySendSMSBaseParam:(NSDictionary *)baseParam
                                bizParam:(NSDictionary *)bizParam
                          completion:(void(^)(NSError *error, CJPaySendSMSResponse *response))completionBlock{
    NSDictionary *requestDic = [self buildRequestParamsWithULBDPaySendSMSBaseParam:baseParam bizParam:bizParam];
       [self startRequestWithUrl:[self buildServerUrl]
                   requestParams:requestDic
                        callback:^(NSError *error, id jsonObj) {
           NSError *err = nil;
           CJPaySendSMSResponse *response = [[CJPaySendSMSResponse alloc] initWithDictionary:jsonObj error:&err];
           CJ_CALL_BLOCK(completionBlock, error, response);
       }];
}

+ (NSDictionary *)buildRequestParamsWithULBDPaySendSMSBaseParam:(NSDictionary *)baseParam bizParam:(NSDictionary *)bizParam{
    NSMutableDictionary *requestParams = [self buildBaseParams];
    //公共参数
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    [requestParams addEntriesFromDictionary:baseParam];
    //业务参数
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionaryWithDictionary:bizParam];
    //风控信息
//    [bizContentParams cj_setObject:[CJPayRequestParam fingerPrintDict] forKey:@"risk_info"];
    NSDictionary *riskDict = [NSDictionary dictionaryWithObject:[CJPayRequestParam riskInfoDict] forKey:@"risk_str"];
    [bizContentParams cj_setObject:riskDict forKey:@"risk_info"];
    
    [bizContentParams cj_setObject:[CJPayPassKitSafeUtil pMemberSecureRequestParams:bizContentParams] forKey:@"secure_request_params"];
    
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:bizContentParams] forKey:@"biz_content"];
    return requestParams;
}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/send_sign_sms";
}

@end
