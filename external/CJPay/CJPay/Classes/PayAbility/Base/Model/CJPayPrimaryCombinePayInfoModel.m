//
//  CJPayPrimaryCombinePayInfoModel.m
//  Pods
//
//  Created by 高航 on 2022/6/21.
//

#import "CJPayPrimaryCombinePayInfoModel.h"

#import "CJPaySDKMacro.h"

@implementation CJPayPrimaryCombinePayInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"secondaryPayTypeIndex" : @"secondary_pay_type_index",
        @"primaryAmount" : @"primary_amount",
        @"secondaryAmount" : @"secondary_amount",
        @"secondaryPayTypeStr" : @"secondary_pay_type",
        @"primaryAmountString" : @"primary_pay_type_msg",
        @"secondaryAmountString" : @"secondary_pay_type_msg"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (CJPayChannelType)channelType {
    if ([self.secondaryPayTypeStr isEqualToString:@"income"]) {
        return BDPayChannelTypeIncomePay;
    }
    if ([self.secondaryPayTypeStr isEqualToString:@"balance"]) {
        return BDPayChannelTypeBalance;
    }
    CJPayLogAssert(NO, @"secondary_pay_type 数据异常%@", CJString(self.secondaryPayTypeStr));
    return BDPayChannelTypeBalance; //兜底为零钱
}

@end
