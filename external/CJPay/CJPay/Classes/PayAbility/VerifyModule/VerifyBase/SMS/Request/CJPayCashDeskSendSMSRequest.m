//
// Created by 张海阳 on 2020/2/20.
//

#import "CJPayCashDeskSendSMSRequest.h"
#import "CJPayCashDeskSendSMSResponse.h"
#import "CJPayUIMacro.h"
#import "CJPaySafeManager.h"
#import "CJPayRequestParam.h"
#import "CJPayBaseRequest+BDPay.h"

@implementation CJPayCashDeskSendSMSRequest

+ (void)startWithParams:(NSDictionary *)params
             bizContent:(NSDictionary *)bizContent
               callback:(void (^)(NSError *error, CJPayCashDeskSendSMSResponse *))callback {
    NSMutableDictionary *requestParams = [self buildBaseParamsWithVersion:@"1.0" needTimestamp:NO];
    [requestParams addEntriesFromDictionary:params ?: @{}];

    NSMutableDictionary *bizContentParams = [(bizContent ?: @{}) mutableCopy];
    [bizContentParams cj_setObject:@"cashdesk.wap.user.sendsms" forKey:@"method"];
    [bizContentParams cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    [bizContentParams addEntriesFromDictionary:self.secureParams];
    
    NSString *bizContentStr = [CJPayCommonUtil dictionaryToJson:bizContentParams];
    [requestParams cj_setObject:bizContentStr forKey:@"biz_content"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];

    [self startRequestWithUrl:[self buildServerUrl] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayCashDeskSendSMSResponse *res = [[CJPayCashDeskSendSMSResponse alloc] initWithDictionary:jsonObj error:&err];
        callback(error, res);
    }];
}

+ (NSString *)apiPath {
    return @"/bytepay/cashdesk/user_verify";
}

+ (NSDictionary *)secureParams {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:[CJPaySafeManager secureInfo]];
    [dict addEntriesFromDictionary:@{
        @"fields": @[
            @"card_item.card_no",
            @"card_item.true_name",
            @"card_item.true_name.certificate_num",
            @"pwd"
        ]
    }];
    return @{@"secure_request_params": dict};
}

@end
