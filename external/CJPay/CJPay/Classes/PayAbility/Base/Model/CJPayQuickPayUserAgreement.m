//
//  CJPayQuickPayUserAgreement.m
//  CJPay
//
//  Created by 王新华 on 11/5/19.
//

#import "CJPayQuickPayUserAgreement.h"

@implementation CJPayQuickPayUserAgreement

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"contentURL": @"content_url",
                @"defaultChoose": @"default_choose",
                @"title": @"title"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
