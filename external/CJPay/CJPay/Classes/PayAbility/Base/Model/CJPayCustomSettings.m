//
//  CJPayCustomSettings.m
//  CJPay
//
//  Created by 王新华 on 10/21/19.
//

#import "CJPayCustomSettings.h"

@implementation CJPayCustomSettings

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"withdrawPageMiddleText" : @"withdraw_page_middle_text",
                @"withdrawPageTitle" : @"withdraw_page_title",
                @"withdrawPageBottomText" : @"withdraw_page_bottom_text",
                @"withdrawResultPageDescDict" : @"withdraw_result_page_desc",
                @"withdrawPageMiddleTextDict": @"withdraw_page_middle_text_by_type",
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
