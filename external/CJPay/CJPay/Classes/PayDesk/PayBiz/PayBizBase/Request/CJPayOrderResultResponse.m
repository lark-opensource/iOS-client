//
//  CJPayOrderResultResponse.m
//  Pods
//
//  Created by wangxinhua on 2020/8/23.
//

#import "CJPayOrderResultResponse.h"
#import "CJPaySDKDefine.h"

@implementation CJPayOrderResultResponse

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[self basicMapperWith:@{
            @"tradeInfo": @"data.trade_info",
            @"processInfoStr": @"response.process",
            @"remainTime": @"data.direct_pay_show_conf.remain_time_s",
            @"paymentInfo": @"data.payment_desc_infos",
            @"resultPageInfo": @"data.result_page_info",
            @"openSchema" : @"data.return_scheme",
            @"openUrl" : @"data.return_url"
    }]];
}

@end
