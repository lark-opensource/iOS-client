//
//  CJPaySubPayTypeSumInfo.m
//  Pods
//
//  Created by wangxiaohong on 2021/4/12.
//

#import "CJPaySubPayTypeSumInfoModel.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"

@implementation CJPaySubPayTypeSumInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"homePageShowStyle": @"home_page_show_style",
        @"homePageGuideText": @"home_page_guide_text",
        @"homePageBanner": @"home_page_banner",
        @"subPayTypeInfoList": @"sub_pay_type_info_list",
        @"subPayTypePageSubtitle": @"sub_pay_type_page_subtitle",
        @"priceZoneShowStyle": @"price_zone_show_style",
        @"bytepayVoucherMsgMap": @"bytepay_voucher_msg_map",
        @"homePageRedDot": @"home_page_red_dot",
        @"cardStyleIndexList":@"card_style_index_list",
        @"useSubPayListVoucherMsg" :@"use_sub_pay_list_voucher_msg",
        @"zoneSplitInfoModel" :@"zone_split_info",
        @"freqSuggestStyleInfo" : @"freq_suggest_style_info"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (CJPaySubPayTypeData *)balanceTypeData {
    __block CJPaySubPayTypeData *balanceData;
    [self.subPayTypeInfoList enumerateObjectsUsingBlock:^(CJPaySubPayTypeInfoModel *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.subPayType isEqualToString:@"balance"]) {
            balanceData = obj.payTypeData;
            *stop = YES;
        }
    }];
    return balanceData;
}

- (CJPaySubPayTypeData *)incomeTypeData {
    __block CJPaySubPayTypeData *balanceData;
    [self.subPayTypeInfoList enumerateObjectsUsingBlock:^(CJPaySubPayTypeInfoModel *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.subPayType isEqualToString:@"income"]) {
            balanceData = obj.payTypeData;
            *stop = YES;
        }
    }];
    return balanceData;
}

- (BOOL)isBindedCard {
    __block BOOL isBindedCard = NO;
    [self.subPayTypeInfoList enumerateObjectsUsingBlock:^(CJPaySubPayTypeInfoModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.subPayType isEqualToString:@"bank_card"]) {
            isBindedCard = YES;
            *stop = YES;
        }
    }];
    return isBindedCard;
}

@end
