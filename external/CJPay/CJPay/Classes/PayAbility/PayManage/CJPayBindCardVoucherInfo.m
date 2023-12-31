//
//  CJPayBindCardVoucherInfo.m
//  Pods
//
//  Created by wangxiaohong on 2021/6/6.
//

#import "CJPayBindCardVoucherInfo.h"

@implementation CJPayBindCardVoucherInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"voucherMsg" : @"voucher_msg",
        @"vouchers" : @"vouchers",
        @"binVoucherMsg" : @"bin_voucher_msg",
        @"aggregateVoucherMsg" : @"home_page_voucher_msg",
        @"isNotShowPromotion" : @"is_not_show_promotion"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
