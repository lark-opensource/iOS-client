//
//  CJPayOrderResponse.m
//  CJPay-655ba357
//
//  Created by wangxinhua on 2020/8/20.
//

#import "CJPayOrderResponse.h"
#import "CJPaySDKMacro.h"

@implementation CJPayOrderResponse

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[self basicMapperWith:@{
        @"channelData": @"data.pay_params.data",
        @"ptCode": @"data.pay_params.ptcode",
        @"tradeType": @"data.pay_params.trade_type"
    }]];
}

- (NSDictionary *)payDataDict {
    return [CJPayCommonUtil jsonStringToDictionary:self.channelData];
}

@end

