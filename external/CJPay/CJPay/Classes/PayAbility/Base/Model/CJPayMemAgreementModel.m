//
//  CJPayMemAgreementModel.m
//  CJPay
//
//  Created by 尚怀军 on 2020/2/24.
//

#import "CJPayMemAgreementModel.h"

#import "CJPayQuickPayUserAgreement.h"


@implementation CJPayMemAgreementModel

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"group": @"group",
        @"name": @"name",
        @"url": @"template_url",
        @"isChoose": @"default_choose"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (CJPayQuickPayUserAgreement *)toQuickPayUserAgreement
{
    CJPayQuickPayUserAgreement *agreementModel =  [CJPayQuickPayUserAgreement new];
    agreementModel.title = self.name;
    agreementModel.contentURL = self.url;
    agreementModel.defaultChoose = self.isChoose;
    return agreementModel;
}

@end
