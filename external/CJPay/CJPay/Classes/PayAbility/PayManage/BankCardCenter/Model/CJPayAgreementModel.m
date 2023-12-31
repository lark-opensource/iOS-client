//
//  CJPayAgreementModel.m
//  CJPay
//
//  Created by 尚怀军 on 2019/10/31.
//

#import "CJPayAgreementModel.h"
#import "CJPayQuickPayUserAgreement.h"

@implementation CJPayBankAgreementModel

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"bankCode": @"front_bank_code",
        @"agreementLists" : @"user_agreements"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
