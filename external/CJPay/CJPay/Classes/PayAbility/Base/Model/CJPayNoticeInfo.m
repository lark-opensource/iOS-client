//
//  CJPayNoticeInfo.m
//  CJPay
//
//  Created by 王新华 on 10/9/19.
//

#import "CJPayNoticeInfo.h"

@implementation CJPayNoticeInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"noticeType" : @"notice_type",
                @"notice" : @"notice",
                @"withdrawBtnStatus" : @"withdraw_btn_status"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
