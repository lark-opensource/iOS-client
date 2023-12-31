//
//  CJPayBalancePromotionModel.m
//  CJPaySandBox-1
//
//  Created by youerwei on 2023/2/16.
//

#import "CJPayBalancePromotionModel.h"

@implementation CJPayBalancePromotionModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"promotionDescription": @"promotion_description",
        @"resourceNo": @"resource_no",
        @"planNo": @"plan_no",
        @"materialNo": @"material_no",
        @"bizType": @"biz_type",
        @"hasBindCardLottery": @"has_bind_card_lottery",
        @"bindCardInfo": @"bind_card_info"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
