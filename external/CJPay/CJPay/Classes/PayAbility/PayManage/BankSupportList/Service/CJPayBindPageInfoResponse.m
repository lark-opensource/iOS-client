//
//  CJPayBindPageInfom
//  Pods
//
//  Created by 徐天喜 on 2022/8/18.
//

#import "CJPayBindPageInfoResponse.h"
#import "CJPayBindCardTitleInfoModel.h"
#import "NSArray+CJPay.h"

@implementation CJPayBindPageInfoResponse

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                     @"creditBanks" : @"credit_banks",
                                     @"debitBanks" : @"debit_banks",
                                     @"oneKeyBanks" : @"one_key_banks", //
                                     @"title" : @"one_key_copywriting_info.title",
                                     @"subTitle" : @"one_key_copywriting_info.sub_title",
                                     @"noPwdBindCardDisplayDesc" : @"one_key_copywriting_info.display_desc",
                                     @"bindCardTitleModel" : @"card_bind_copywriting_info",
                                     @"voucherMsg" : @"voucher_msg",
                                     @"voucherBank" : @"voucher_bank",
                                     @"voucherBankIcon" : @"voucher_bank_info.icon_url",
                                     @"isSupportOneKey" : @"voucher_bank_info.is_support_one_key",
                                     @"retainInfo": @"retention_msg",
                                     @"oneKeyBanksLength" : @"one_key_banks_lenth",
                                     @"recommendBanksLenth" : @"recommend_banks_lenth",
                                     @"recommendBindCardTitleModel" :@"recommend_copywriting_info",
                                     @"recommendBanks" : @"recommend_banks",
                                     @"cardNoInputTitle" : @"card_no_input_copywriting_info.title",
                                     @"bankListSignature" : @"bank_list_signature",
                                     @"exts" : @"exts"
                                     }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
