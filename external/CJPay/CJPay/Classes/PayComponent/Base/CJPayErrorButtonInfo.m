//
// Created by 张海阳 on 2019-07-01.
//

#import "CJPayErrorButtonInfo.h"

@implementation CJPayErrorButtonInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"page_desc": @"page_desc",
                @"button_desc": @"button_desc",
                @"button_type": @"button_type",
                @"action": @"action",
                @"left_button_desc": @"left_button_desc",
                @"left_button_action": @"left_button_action",
                @"right_button_desc": @"right_button_desc",
                @"right_button_action": @"right_button_action",
                @"button_status": @"button_status",
                @"findPwdUrl": @"find_pwd_url",
                @"mainTitle" : @"main_title",
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
