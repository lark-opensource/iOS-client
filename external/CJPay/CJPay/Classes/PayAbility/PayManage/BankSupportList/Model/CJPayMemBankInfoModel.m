//
//  CJPayMemBankInfoModel.m
//  Pods
//
//  Created by 尚怀军 on 2020/2/20.
//

#import "CJPayMemBankInfoModel.h"
#import "CJPayUIMacro.h"
#import "CJPayBindCardVoucherInfo.h"

@implementation CJPayMemBankInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"bankCardID": @"bank_card_id",
                @"bankCode": @"bank_code",
                @"cardType" : @"card_type",
                @"bankName" : @"bank_name",
                @"iconURL" : @"icon_url",
                @"cardNoMask": @"card_no_mask",
                @"perpayLimit" : @"perpay_limit",
                @"perdayLimit" : @"perday_limit",
                @"voucherInfoDict" : @"voucher_info_map"
            }];
}

- (CGFloat)cellHeight{
    if (Check_ValidString(self.perdayLimit) || Check_ValidString(self.perpayLimit)) {
        return 60;
    } else {
        return 56;
    }
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (CJPayBindCardVoucherInfo *)debitBindCardVoucherInfo {
    return [[CJPayBindCardVoucherInfo alloc] initWithDictionary:[self.voucherInfoDict cj_dictionaryValueForKey:@"DEBIT"] error:nil];
}

- (CJPayBindCardVoucherInfo *)creditBindCardVoucherInfo {
    return [[CJPayBindCardVoucherInfo alloc] initWithDictionary:[self.voucherInfoDict cj_dictionaryValueForKey:@"CREDIT"] error:nil];
}

- (CJPayQuickPayCardModel *)toQuickPayCardModel {
    CJPayQuickPayCardModel *model = [CJPayQuickPayCardModel new];
    model.bankCardID = self.bankCardID;
    model.cardType = self.cardType;
    model.frontBankCode = self.bankCode;
    model.frontBankCodeName = self.bankName;
    model.cardNoMask = self.cardNoMask;
    model.iconUrl = self.iconURL;
    model.perDayLimit = self.perdayLimit;
    model.perPayLimit = self.perpayLimit;
    model.cardBinVoucher = self.cardBinVoucher;
    return model;
}

@end
