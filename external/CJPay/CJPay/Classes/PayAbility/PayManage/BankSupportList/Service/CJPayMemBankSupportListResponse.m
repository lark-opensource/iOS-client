//
//  CJPayMemBankSupportListResponse.m
//  Pods
//
//  Created by 尚怀军 on 2020/2/20.
//

#import "CJPayMemBankSupportListResponse.h"
#import "CJPayBindCardTitleInfoModel.h"
#import "NSArray+CJPay.h"

@implementation CJPayMemBankSupportListResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{@"creditBanks" : @"response.credit_banks",
                                     @"debitBanks" : @"response.debit_banks",
                                     @"oneKeyBanks" : @"response.one_key_banks",
                                     @"title" : @"response.one_key_copywriting_info.title",
                                     @"subTitle" : @"response.one_key_copywriting_info.sub_title",
                                     @"noPwdBindCardDisplayDesc" : @"response.one_key_copywriting_info.display_desc",
                                     @"bindCardTitleModel" : @"response.card_bind_copywriting_info",
                                     @"voucherMsg" : @"response.voucher_msg",
                                     @"voucherList" : @"response.voucher_list",
                                     @"voucherBank" : @"response.voucher_bank",
                                     @"voucherBankInfo" : @"response.voucher_bank_info",
                                     @"isSupportOneKey" : @"response.voucher_bank_info.is_support_one_key",
                                     @"retainInfo": @"response.retention_msg",
                                     @"oneKeyBanksLength" : @"response.one_key_banks_lenth",
                                     @"recommendBanksLenth" : @"response.recommend_banks_lenth",
                                     @"recommendBindCardTitleModel" :@"response.recommend_copywriting_info",
                                     @"recommendBanks" : @"response.recommend_banks",
                                     @"cardNoInputTitle" : @"response.card_no_input_copywriting_info.title",
                                     @"exts" : @"response.exts"
                                     }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
