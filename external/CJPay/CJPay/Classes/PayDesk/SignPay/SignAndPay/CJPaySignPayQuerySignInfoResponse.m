//
//  CJPaySignPayQuerySignInfoResponse.m
//  Pods
//
//  Created by chenbocheng on 2022/7/12.
//

#import "CJPaySignPayQuerySignInfoResponse.h"

@implementation CJPaySignPayQuerySignInfoResponse

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[self basicMapperWith:@{
        @"tradeAmount" : @"data.trade_amount",
        @"promotionAmount" : @"data.promotion_amount",
        @"realTradeAmount" : @"data.real_trade_amount",
        @"signTemplateInfo" : @"data.sign_template_info",
        @"nextDeductDate" : @"data.next_deduct_date",
        @"userAccount" : @"data.user_account",
        @"hasBankCard" : @"data.is_set_pwd",
        @"protocolInfo" : @"data.protocol_info",
        @"protocolGroupNames" : @"data.protocol_group_names",
        @"guideMessage" : @"data.guide_message",
        @"deductOrderUrl" : @"data.deduct_order_url",
        @"dypayReturnUrl" : @"data.dypay_return_url",
        @"deductMethodDesc" : @"data.deduct_method_desc",
        @"promotionDesc" : @"data.promotion_desc"
    }]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (CJPaySignModel *)toSignModel {
    CJPaySignModel *model = [CJPaySignModel new];
    model.realTradeAmount = self.realTradeAmount;
    model.promotionAmount = self.promotionAmount;
    model.signTemplateInfo = self.signTemplateInfo;
    model.nextDeductDate = self.nextDeductDate;
    model.userAccount = self.userAccount;
    model.hasBankCard = self.hasBankCard;
    model.protocolGroupNames = self.protocolGroupNames;
    model.protocolInfo = self.protocolInfo;
    model.guideMessage = self.guideMessage;
    model.deductMethodDesc = self.deductMethodDesc;
    model.promotionDesc = self.promotionDesc;
    return model;
}

@end
