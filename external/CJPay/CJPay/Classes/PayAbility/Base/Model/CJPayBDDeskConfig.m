//
//  CJPayBDDeskConfig.m
//  CJPay
//
//  Created by wangxinhua on 2020/9/28.
//

#import "CJPayBDDeskConfig.h"

@implementation CJPayBDDeskConfig


+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"confirmBtnDesc" : @"confirm_btn_desc",
                @"showStyle" : @"show_style",
                @"themeString" : @"theme",
                @"agreementUrl" : @"user_agreement.content_url",
                @"agreementChoose" : @"user_agreement.default_choose",
                @"agreementTitle" : @"user_agreement.title",
                @"whetherShowLeftTime" : @"whether_show_left_time",
                @"leftTime" : @"left_time",
                @"noticeInfo" : @"notice_info",
                @"withdrawArrivalTime": @"withdraw_arrival_time",
                @"homePageAction" : @"home_page_action"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (CJPayDeskTheme *)theme {
    NSError *err = nil;
    return [[CJPayDeskTheme alloc] initWithString:self.themeString error:&err];
}

- (BOOL)isFastEnterBindCard {
    return self.homePageAction == 1;
}

@end
