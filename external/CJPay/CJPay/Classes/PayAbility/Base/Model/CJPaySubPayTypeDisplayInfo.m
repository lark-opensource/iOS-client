//
//  CJPaySubPayTypeDisplayInfo.m
//  CJPaySandBox
//
//  Created by 利国卿 on 2022/11/21.
//

#import "CJPaySubPayTypeDisplayInfo.h"
#import "CJPayDefaultChannelShowConfig.h"

@implementation CJPaySubPayTypeDisplayInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"index": @"index",
        @"subPayType": @"sub_pay_type",
        @"iconUrl": @"icon_url",
        @"title": @"title",
        @"paymentInfo": @"payment_info"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (CJPayDefaultChannelShowConfig *)buildShowConfig {
    CJPayDefaultChannelShowConfig *config = [CJPayDefaultChannelShowConfig new];
    config.title = self.title;
    config.iconUrl = self.iconUrl;
    config.paymentInfo = self.paymentInfo;
    config.type = [self p_channelTypeWithSubPayTypeStr:self.subPayType];
    return config;
}

- (CJPayChannelType)p_channelTypeWithSubPayTypeStr:(NSString *)subPayTypeStr {
    if ([subPayTypeStr isEqualToString:@"bank_card"]) {
        return BDPayChannelTypeBankCard;
    } else if ([subPayTypeStr isEqualToString:@"balance"]) {
        return BDPayChannelTypeBalance;
    } else if ([subPayTypeStr isEqualToString:@"new_bank_card"]) {
        return BDPayChannelTypeAddBankCard;
    } else if ([subPayTypeStr isEqualToString:@"income"]) {
        return BDPayChannelTypeIncomePay;
    } else if ([subPayTypeStr isEqualToString:@"credit_pay"]) {
        return BDPayChannelTypeCreditPay;
    } else if ([subPayTypeStr isEqualToString:@"combinepay"]) {
        return BDPayChannelTypeCombinePay;
    }
    return CJPayChannelTypeNone;
}
@end
