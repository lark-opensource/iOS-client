//
//  CJPayQuickBindCardModel.m
//  Pods
//
//  Created by wangxiaohong on 2020/10/12.
//

#import "CJPayQuickBindCardModel.h"
#import "CJPayUIMacro.h"
#import "CJPayBindCardVoucherInfo.h"
#import "CJPayBindCardTitleInfoModel.h"

@implementation CJPayQuickBindCardModel

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                   @"bankCode" : @"bank_code",
                   @"cardType" : @"card_type",
                   @"bankName": @"bank_name",
                   @"orderAmount": @"order_amount",
                   @"iconUrl": @"icon_url",
                   @"backgroundUrl": @"icon_background",
                   @"bankCardId" : @"bank_card_id",
                   @"voucherInfoDict" : @"voucher_info_map",
                   @"selectedCardType" : @"card_type_chosen",
                   @"bankRank" : @"bank_rank",
                   @"jumpBankType": @"jump_bind_card_type",
                   @"rankType" : @"rank_type",
                   @"bankInitials" : @"bank_initials",
                   @"bankPopularFlag" : @"bank_popular_flag",
                   @"bankSortNum" : @"bank_sort_number",
                   @"isSupportOneKey" : @"is_support_one_key",
                   @"voucherMsg" : @"voucher_msg"
               }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (CJPayBindCardVoucherInfo *)debitBindCardVoucherInfo {
    return [[CJPayBindCardVoucherInfo alloc] initWithDictionary:[self.voucherInfoDict cj_dictionaryValueForKey:@"DEBIT"] error:nil];
}

- (CJPayBindCardVoucherInfo *)creditBindCardVoucherInfo {
    return [[CJPayBindCardVoucherInfo alloc] initWithDictionary:[self.voucherInfoDict cj_dictionaryValueForKey:@"CREDIT"] error:nil];
}

- (CJPayBindCardVoucherInfo *)unionBindCardVoucherInfo {
    return [[CJPayBindCardVoucherInfo alloc] initWithDictionary:[self.voucherInfoDict cj_dictionaryValueForKey:@"UPYSFBANK"] error:nil];
}

- (NSArray *)activityInfoWithCardType:(NSString *)cardType {
    NSMutableArray *activityInfos = [NSMutableArray array];
    
    if ([cardType isEqualToString:@"ALL"]) {
        if (self.debitBindCardVoucherInfo.vouchers.count > 0) {
            [activityInfos addObjectsFromArray:self.debitBindCardVoucherInfo.vouchers];
        }
        if (self.creditBindCardVoucherInfo.vouchers.count > 0) {
            [activityInfos addObjectsFromArray:self.creditBindCardVoucherInfo.vouchers];
        }
    } else if ([cardType isEqualToString:@"CREDIT"] && self.creditBindCardVoucherInfo.vouchers > 0) {
        [activityInfos addObjectsFromArray:self.creditBindCardVoucherInfo.vouchers];
    } else if ([cardType isEqualToString:@"DEBIT"] && self.debitBindCardVoucherInfo.vouchers > 0) {
        [activityInfos addObjectsFromArray:self.debitBindCardVoucherInfo.vouchers];
    } else if ([cardType isEqualToString:@"UPYSFBANK"] && self.unionBindCardVoucherInfo.vouchers > 0) {
        [activityInfos addObjectsFromArray:self.unionBindCardVoucherInfo.vouchers];
    }
    NSMutableArray *realActivityInfos = [NSMutableArray array];
    [activityInfos enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.count > 0) {
            [realActivityInfos btd_addObject:@{
                @"id" : CJString([obj cj_stringValueForKey:@"voucher_no"]),
                @"type": [[obj cj_stringValueForKey:@"voucher_type"] isEqualToString:@"discount_voucher"] ? @"0" : @"1",
                @"front_bank_code": CJString([obj cj_stringValueForKey:@"front_bank_code"]),
                @"reduce" : @([obj cj_intValueForKey:@"reduce_amount"]),
                @"label": CJString([obj cj_stringValueForKey:@"label"])
            }];
        }
    }];
    return [realActivityInfos copy];
}

- (BOOL)isUnionBindCard {
    return [self.bankCode isEqualToString:@"UPYSFBANK"];
}

@end
