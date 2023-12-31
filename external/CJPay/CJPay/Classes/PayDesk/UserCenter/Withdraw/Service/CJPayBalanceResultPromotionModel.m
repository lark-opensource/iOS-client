//
//  CJPayResultPromotionModel.m
//  CJPaySandBox-1
//
//  Created by youerwei on 2023/2/23.
//

#import "CJPayBalanceResultPromotionModel.h"

@implementation CJPayBalanceResultPromotionModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"leftDiscountAmount": @"left_discount_amount",
        @"leftDiscountDesc": @"left_discount_desc",
        @"rightTopDesc": @"right_top_desc",
        @"rightBottomDesc": @"right_buttom_desc",
        @"voucherEndTime": @"voucher_end_time",
        @"jumpUrl": @"jump_url"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
