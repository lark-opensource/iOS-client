//
//  CJPayBankActivityInfoModel.m
//  Pods
//
//  Created by xiuyuanLee on 2020/12/30.
//

#import "CJPayBankActivityInfoModel.h"
#import "CJPayUIMacro.h"

@implementation CJPayBankActivityInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"iconUrl" : @"icon_url",
        @"bankCardName" : @"bank_card_name",
        @"benefitDesc": @"benefit_desc",
        @"benefitAmount": @"benefit_amount",
        @"activityPageUrl": @"activity_page_url",
        @"buttonDesc": @"button_desc",
        @"jumpUrl": @"jump_url"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
