//
//  CJPayVoucherBankInfo.m
//  Pods
//
//  Created by chenbocheng.moon on 2022/10/17.
//

#import "CJPayVoucherBankInfo.h"
#import "CJPaySDKMacro.h"

@implementation CJPayVoucherBankInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"iconUrl": @"icon_url",
        @"cardVoucherMsg": @"card_voucher_list.card_voucher_msg",
        @"cardBinVoucherMsg": @"card_voucher_list.card_bin_voucher_msg",
        @"voucherBank": @"voucher_bank"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (BOOL)hasVoucher {
    return Check_ValidString(self.cardVoucherMsg) || Check_ValidString(self.cardBinVoucherMsg);
}

@end
