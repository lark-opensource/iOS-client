//
//  CJPayMemCardBinResponse.m
//  Pods
//
//  Created by 尚怀军 on 2020/2/20.
//

#import "CJPayMemCardBinResponse.h"

#import "CJPayQuickPayUserAgreement.h"
#import "CJPayMemAgreementModel.h"
#import "CJPayErrorButtonInfo.h"
#import "CJPayMemBankInfoModel.h"
#import "NSString+CJPay.h"
#import "CJPaySDKMacro.h"
#import "CJPayCreditPayMethodModel.h"
#import "CJPayBindCardVoucherInfo.h"

@implementation CJPayMemCardBinResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{@"cardBinInfoModel" : @"response.bank_info",
                                     @"agreements" : @"response.card_protocol_list",
                                     @"guideMessage" : @"response.guide_message",
                                     @"protocolCheckBox" : @"response.protocol_check_box",
                                     @"protocolGroupNames" : @"response.protocol_group_names",
                                     @"buttonInfo" : @"response.button_info"
                                    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

- (NSDictionary *)toActivityInfoTracker {
    
    CJPayBindCardVoucherInfo *voucherInfoModel = nil;
    if ([self.cardBinInfoModel.cardType isEqualToString:@"CREDIT"]) {
        voucherInfoModel = self.cardBinInfoModel.creditBindCardVoucherInfo;
    } else if ([self.cardBinInfoModel.cardType isEqualToString:@"DEBIT"]) {
        voucherInfoModel = self.cardBinInfoModel.debitBindCardVoucherInfo;
    }
    
    CJPayVoucherModel *voucherModel = voucherInfoModel.vouchers.firstObject;
    if (!voucherModel) {
        return @{};
    }
    return @{
        @"id" : CJString(voucherModel.voucherNo),
        @"type": [voucherModel.voucherType isEqualToString:@"discount_voucher"] ? @"0" : @"1",
        @"front_bank_code": CJString(self.cardBinInfoModel.bankCode),
        @"reduce" : @(voucherModel.reduceAmount),
        @"label": CJString(voucherModel.label)
    };
}

@end
