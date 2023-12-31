//
//  CJPayBankCardModel.m
//  BDPay
//
//  Created by 易培淮 on 2020/5/28.
//

#import "CJPayBankCardModel.h"

@implementation CJPayBankCardModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"bankCardId":@"bank_card_id",
                @"signNo":@"sign_no",
                @"bankCode":@"bank_code",
                @"bankName":@"bank_name",
                @"iconUrl":@"icon_url",
                @"cardType":@"card_type",
                @"cardNoMask":@"card_no_mask",
                @"mobileMask":@"mobile_mask",
                @"nameMask":@"name_mask",
                @"identityType":@"identity_type",
                @"identityCodeMask":@"identity_code_mask",
                @"perdayLimit":@"perday_limit",
                @"perpayLimit":@"perpay_limit",
                @"status":@"status",
                @"quickPayMark":@"quickpay_mark",
                @"cardBackgroundColor":@"background_color",
                @"channelIconUrl":@"channel_icon_url",
                @"needResign":@"need_resign",
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

+ (BOOL)propertyIsIgnored:(NSString *)propertyName {
    if ([propertyName isEqualToString:@"isSmallStyle"]) {
        return YES;
    }
    return NO;
}

@end

