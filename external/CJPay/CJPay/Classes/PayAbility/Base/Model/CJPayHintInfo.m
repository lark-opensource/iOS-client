//
//  CJPayHintInfo.m
//  Pods
//
//  Created by 王新华 on 2021/6/7.
//

#import "CJPayHintInfo.h"
#import "CJPayMerchantInfo.h"
@implementation CJPayHintInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"iconUrl": @"icon_url",
        @"msg" : @"msg",
        @"statusMsg" : @"status_msg",
        @"subStatusMsg" : @"sub_status_msg",
        @"recPayType" : @"rec_pay_type",
        @"voucherBankIcons" : @"voucher_bank_icons",
        @"buttonText" : @"button_text",
        @"failType" : @"fail_type",
        @"subButtonText" : @"sub_button_text",
        @"retainInfo": @"retain_info",
        @"styleStr" : @"style",
        @"buttonInfo": @"button_info",
        @"voucherList" : @"voucher_list",
        @"topRightDescText" : @"top_right_desc_text",
        @"tradeAmount" : @"trade_amount",
        @"merchantInfo" : @"merchant_info",
        @"failPayTypeMsg" : @"fail_pay_type_msg",
        @"titleMsg" : @"title_msg",
        @"againReasonType" : @"again_reason_type"
    }];
}

- (CJPayHintInfoStyle)p_styleStyleStr:(NSString *)styleStr {
    if ([styleStr isEqualToString:@"OLD_HALF"]) {
        return CJPayHintInfoStyleOldHalf;
    } else if ([styleStr isEqualToString:@"NEW_HALF"]) {
        return CJPayHintInfoStyleNewHalf;
    } else if ([styleStr isEqualToString:@"WINDOW"]) {
        return CJPayHintInfoStyleWindow;
    } else if ([styleStr isEqualToString:@"VOUCHER_HALF"]) {
        return CJPayHintInfoStyleVoucherHalf;
    } else if ([styleStr isEqualToString:@"VOUCHER_HALF_V2"]) {
        return CJPayHintInfoStyleVoucherHalfV2;
    } else if ([styleStr isEqualToString:@"VOUCHER_HALF_V3"]) {
        return CJPayHintInfoStyleVoucherHalfV3;
    }
    return CJPayHintInfoStyleOldHalf;
}

- (CJPayHintInfoStyle)style {
    return [self p_styleStyleStr:self.styleStr];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
