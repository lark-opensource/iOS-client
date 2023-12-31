//
//  CJPayCombinePayFund.m
//  Pods
//
//  Created by youerwei on 2021/4/16.
//

#import "CJPayCombinePayFund.h"

@implementation CJPayCombinePayFund

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"fundTypeDesc": @"fund_type_desc",
        @"fundType": @"fund_type",
        @"fundAmountDesc": @"fund_amount_desc",
        @"fundAmount": @"fund_amount"
    }];
}

@end
