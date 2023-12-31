//
//  CJPayTradeInfo.m
//  CJPay-Pay
//
//  Created by wangxiaohong on 2020/9/17.
//

#import "CJPayTradeInfo.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPaySDKMacro.h"

@implementation CJPayTradeInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"amount": @"amount",
        @"realAmount": @"real_amount",
        @"createTime": @"create_time",
        @"currency": @"currency",
        @"expireTime": @"expire_time",
        @"appID": @"app_id",
        @"merchantId": @"merchant_id",
        @"merchantName" : @"merchant_name",
        @"outTradeNo": @"out_trade_no",
        @"payTime": @"pay_time",
        @"payType": @"pay_type",
        @"ptCode": @"ptcode",
        @"tradeDesc": @"trade_desc",
        @"tradeName": @"trade_name",
        @"tradeNo": @"trade_no",
        @"uid": @"uid",
        @"statInfo": @"stat_info",
        @"bdpayResultDicStr": @"douyin_trade_info",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (CJPayBDOrderResultResponse *)bdpayResultResponse {
    if (!_bdpayResultResponse) {
        NSDictionary *tradeInfoDic = [self.bdpayResultDicStr cj_toDic];
        NSError *err = nil;
        NSDictionary *resultResponseDic = @{
            @"response": tradeInfoDic ?: @{}
        };
        _bdpayResultResponse = [[CJPayBDOrderResultResponse alloc] initWithDictionary:resultResponseDic error:&err];
    }
    return _bdpayResultResponse;
}

- (CJPayOrderStatus)tradeStatus {
    return CJPayOrderStatusFromString(self.status);
}

@end
