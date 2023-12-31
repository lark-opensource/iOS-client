//
//  CJPayBalanceModel.m
//  CJPay
//
//  Created by wangxinhua on 2018/10/23.
//

#import "CJPayBalanceModel.h"
#import "CJPayUIMacro.h"
#import "CJPayChannelModel.h"

@implementation CJPayBalanceModel

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"balanceAmount": @"balance_amount",
                @"title": @"title",
                @"balanceQuota": @"balance_quota",
                @"freezedAmount": @"freezed_amount",
                @"mark": @"mark",
                @"msg": @"msg",
                @"iconUrl": @"icon_url",
                @"status": @"status",
                @"mobile": @"mobile_mask",
                @"identityVerifyWay": @"identity_verify_way",
                @"isShowCombinePay": @"show_combine_pay",
                @"primaryCombinePayAmount" : @"primary_combine_pay_amount"
            }];
}

- (NSArray<CJPayDefaultChannelShowConfig *> *)buildShowConfig {
    CJPayDefaultChannelShowConfig *configModel = [CJPayDefaultChannelShowConfig new];
    configModel.iconUrl = self.iconUrl;
    configModel.title = CJString(self.title);
    configModel.subTitle = CJString(self.msg);
    configModel.status = self.status;
    configModel.payChannel = self;
    configModel.mobile = self.mobile;
    configModel.mark = self.mark;
    configModel.type = BDPayChannelTypeBalance;
    configModel.cjIdentify = @"balance";
    configModel.showCombinePay = self.isShowCombinePay;
    configModel.payAmount = [NSString stringWithFormat:@"%0.2f", self.balanceAmount/100.0];//self.balanceAmount;
    if (self.isShowCombinePay) {
        configModel.primaryCombinePayAmount = self.primaryCombinePayAmount;
    }
    return @[configModel];
}

- (NSDictionary *)requestNeedParams{
    return [NSDictionary new];
}

@end
