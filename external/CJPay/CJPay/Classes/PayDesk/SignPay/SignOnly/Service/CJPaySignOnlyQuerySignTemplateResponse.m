//
//  CJPaySignOnlyQuerySignTemplateResponse.m
//  CJPay-a399f1d1
//
//  Created by wangxiaohong on 2022/9/15.
//

#import "CJPaySignOnlyQuerySignTemplateResponse.h"

@implementation CJPaySignOnlyQuerySignTemplateResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{
        @"tradeAmount" : @"response.trade_amount",
        @"promotionAmount" : @"response.promotion_amount",
        @"realTradeAmount" : @"response.real_trade_amount",
        @"signTemplateInfo" : @"response.sign_template_info",
        @"nextDeductDate" : @"response.next_deduct_date",
        @"userAccount" : @"response.user_account",
        @"hasBankCard" : @"response.is_set_pwd",
        @"protocolInfo" : @"response.protocol_info",
        @"protocolGroupNames" : @"response.protocol_group_names",
        @"guideMessage" : @"response.guide_message",
        @"deductOrderUrl" : @"response.deduct_order_url",
        @"dypayReturnUrl" : @"response.dypay_return_url",
        @"deductMethodDesc" : @"response.deduct_method_desc",
        @"verifyType" : @"response.verify_type",
        @"bindCardUrl" : @"response.bind_card_url",
        @"jumpType" : @"response.jump_type"
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
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
    return model;
}


@end
