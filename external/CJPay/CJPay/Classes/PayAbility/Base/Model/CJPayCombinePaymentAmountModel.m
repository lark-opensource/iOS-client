//
//  CJPayCombinePaymentAmountModel.m
//  Pods
//
//  Created by xiuyuanLee on 2021/4/19.
//

#import "CJPayCombinePaymentAmountModel.h"

@implementation CJPayCombinePaymentAmountModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"totalAmount" : @"totalAmount",
        @"detailInfo" : @"detailInfo",
        @"cashAmount" : @"cashAmount",
        @"bankCardAmount" : @"bankCardAmount"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
