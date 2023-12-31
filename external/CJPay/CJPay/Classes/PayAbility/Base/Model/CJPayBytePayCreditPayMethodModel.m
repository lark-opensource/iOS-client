//
//  CJPayCreditPayMethodModel.m
//  Pods
//
//  Created by bytedance on 2021/7/27.
//

#import "CJPayBytePayCreditPayMethodModel.h"

@implementation CJPayBytePayCreditPayMethodModel

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{
        @"index" : @"index",
        @"voucherMsg" : @"voucher_msg",
        @"payTypeDesc" : @"pay_type_desc",
        @"feeDesc" : @"fee_desc",
        @"orderSubFixedVoucherAmount" : @"voucher_info.order_sub_fixed_voucher_amount",
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dict];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
