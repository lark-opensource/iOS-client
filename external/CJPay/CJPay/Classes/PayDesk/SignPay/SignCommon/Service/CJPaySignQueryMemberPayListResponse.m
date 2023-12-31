//
//  CJPaySignQueryMemberPayListResponse.m
//  Pods
//
//  Created by wangxiaohong on 2022/9/8.
//

#import "CJPaySignQueryMemberPayListResponse.h"

#import "CJPaySDKMacro.h"

@implementation QueryMemberPayTypeItem

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"name" : @"name",
        @"payMode" : @"pay_mode",
        @"iconUrl" : @"icon_url",
        @"cardNoMask" : @"card_no_mask",
        @"bankCardId" : @"bank_card_id",
        @"cardType" : @"card_type",
        @"notSupportMsg": @"not_support_msg"
    }];
}

- (NSString *)p_title {
    CJPayChannelType channelType = [self p_getChannelType];
    if (channelType == BDPayChannelTypeBalance || channelType == BDPayChannelTypeAddBankCard) {
        return CJString(self.name);
    }
    if (!Check_ValidString(self.cardType)) {
        return CJString(self.name);
    }
    NSString *cardType = [self.cardType isEqualToString:@"DEBIT"] ? @"储蓄卡" : @"信用卡";
    NSString *cardMask = @"";
    if (self.bankCardId.length >= 4) {
        cardMask = [self.bankCardId substringFromIndex:self.bankCardId.length - 4];
    }
    return [NSString stringWithFormat:@"%@%@(%@)", CJString(self.name), CJString(cardType), CJString(cardMask)];
}

- (CJPayChannelType)p_getChannelType {
    NSString *payModeStr = self.payMode;
    if ([payModeStr isEqualToString:@"1"]) {
        return BDPayChannelTypeBalance;
    } else if ([payModeStr isEqualToString:@"2"]) {
        return BDPayChannelTypeBankCard;
    } else if ([payModeStr isEqualToString:@"3"])  {
        return BDPayChannelTypeAddBankCard;
    } else {
        CJPayLogWarn(@"unknown pay mode %@", CJString(self.payMode));
        [CJMonitor trackServiceAllInOne:@"wallet_rd_sign_card_list_pay_mode_exception"
                                 metric:@{}
                               category:@{@"pay_mode": CJString(self.payMode)}
                                  extra:@{}];
        return CJPayChannelTypeNone;
    }
}

- (NSString *)p_getMethodIdentity {
    CJPayChannelType channelType = [self p_getChannelType];
    switch (channelType) {
        case BDPayChannelTypeBalance:
            return @"balance";
        case BDPayChannelTypeAddBankCard:
            return @"add_bank_card";
        case BDPayChannelTypeBankCard:
            return self.bankCardId;
        default:
            return @"unknown";;
    }
}

- (NSArray<CJPayDefaultChannelShowConfig *> *)buildShowConfig {
    CJPayDefaultChannelShowConfig *showConfig = [CJPayDefaultChannelShowConfig new];
    showConfig.iconUrl = self.iconUrl;
    showConfig.title = [self p_title];
    showConfig.payChannel = self;
    showConfig.type = [self p_getChannelType];
    showConfig.bankCardId = self.bankCardId;
    showConfig.cardTailNumStr = self.cardNoMask;
    showConfig.status = Check_ValidString(self.notSupportMsg) ? @"0" : @"1";
    showConfig.subTitle = self.notSupportMsg;
    showConfig.cjIdentify = [self p_getMethodIdentity];
    return @[showConfig];
}

@end

@implementation CJPaySignQueryMemberPayListResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{
        @"payType" : @"response.pay_type",
        @"payTypeList" : @"response.pay_type_list",
        @"firstPayTypeItem" : @"response.first_pay_type_item",
        @"displayName" : @"response.display_name",
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (NSArray<CJPayDefaultChannelShowConfig *> *)memberPayListShowConfigs {
    NSMutableArray *configArray = [NSMutableArray new];
    [self.payTypeList enumerateObjectsUsingBlock:^(QueryMemberPayTypeItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [configArray addObjectsFromArray:[obj buildShowConfig]];
    }];
    return configArray;
}

@end
