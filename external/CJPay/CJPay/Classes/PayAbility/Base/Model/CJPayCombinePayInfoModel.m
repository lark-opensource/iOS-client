//
//  CJPayCombinePayInfoModel.m
//  Pods
//
//  Created by 高航 on 2022/6/22.
//

#import "CJPayCombinePayInfoModel.h"


@implementation CJPayCombinePayInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"primaryPayInfoList": @"primary_combine_pay_info_list",
        @"secondaryPayInfo" : @"secondary_combine_pay_info",
        @"combinePayVoucherMsgList": @"voucher_msg_list",
        @"combinePayVoucherInfo": @"voucher_info",
        @"standardRecDesc" : @"standard_rec_desc",
        @"standardShowAmount" : @"standard_show_amount"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
