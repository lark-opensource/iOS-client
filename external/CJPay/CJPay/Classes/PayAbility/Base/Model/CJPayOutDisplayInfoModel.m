//
//  CJPayOutDisplayInfoModel.m
//  SandBox
//
//  Created by ZhengQiuyu on 2023/7/24.
//

#import "CJPayOutDisplayInfoModel.h"

@implementation CJPayOutDisplayInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"payAndSignCashierStyle" : @"pay_and_sign_cashier_style",
        @"serviceDescName" : @"service_desc_name",
        @"serviceDescText" : @"service_desc_text",
        @"realTradeAmount" : @"real_trade_amount",
        @"promotionDesc" : @"promotion_desc",
        @"deductMethodSubDesc" : @"deduct_method_sub_desc",
        @"afterPaySuccessText" : @"after_pay_success_text",
        @"payTypeText" : @"pay_type_text",
        @"templateId" : @"template_id",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (CJPaySignPayCashierStyleType)obtainSignPayCashierStyle {
    if ([self.payAndSignCashierStyle isEqualToString:@"front_sign_deduct_complex"]) {
        return CJPaySignPayCashierStyleTypeFrontSignDeductComplex;
    }
    if ([self.payAndSignCashierStyle isEqualToString:@"front_sign_pay_complex"]) {
        return CJPaySignPayCashierStyleTypeFrontSignPayComplex;
    }
    if ([self.payAndSignCashierStyle isEqualToString:@"front_sign_deduct_simple"]) {
        return CJPaySignPayCashierStyleTypeFrontSignDeductSimple;
    }
    return CJPaySignPayCashierStyleTypeFrontSignPaySimple;
}

- (BOOL)isShowDeductDetailViewMode {
    CJPaySignPayCashierStyleType cashierStyle = [self obtainSignPayCashierStyle];
    if (cashierStyle == CJPaySignPayCashierStyleTypeFrontSignPayComplex || cashierStyle == CJPaySignPayCashierStyleTypeFrontSignDeductSimple) {
        return YES;
    }
    return NO;
}

- (BOOL)isDeductPayMode {
    CJPaySignPayCashierStyleType cashierStyle = [self obtainSignPayCashierStyle];
    if (cashierStyle == CJPaySignPayCashierStyleTypeFrontSignDeductSimple || cashierStyle == CJPaySignPayCashierStyleTypeFrontSignDeductComplex) {
        return YES;
    }
    return NO;
}

@end
