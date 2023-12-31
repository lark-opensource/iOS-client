//
//  CJPaySubPayTypeGroupInfo.m
//  CJPaySandBox
//
//  Created by 利国卿 on 2022/11/21.
//

#import "CJPaySubPayTypeGroupInfo.h"

@implementation CJPaySubPayTypeGroupInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"groupType": @"group_type",
        @"groupTitle": @"group_title",
        @"creditPayDesc": @"credit_pay_desc",
        @"displayNewBankCardCount": @"display_new_bank_card_count",
        @"addBankCardFoldDesc": @"new_bank_card_fold_desc",
        @"subPayTypeIndexList": @"sub_pay_type_index_list",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
