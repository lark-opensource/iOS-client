//
//  CJPaySecondaryCombinePayInfoModel.m
//  Pods
//
//  Created by 高航 on 2022/6/21.
//

#import "CJPaySecondaryCombinePayInfoModel.h"

@implementation CJPaySecondaryCombinePayInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"tradeAmount" : @"trade_amount",
        @"primaryAmount" : @"primary_amount",
        @"secondaryAmount" : @"secondary_amount",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
