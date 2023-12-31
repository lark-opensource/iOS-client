//
//  CJPayBindCardSetPasswordRetainInfo.m
//  CJPaySandBox
//
//  Created by wangxiaohong on 2022/11/22.
//

#import "CJPayBindCardSetPasswordRetainInfo.h"

#import <UIKit/UIKit.h>
#import "CJPayBindCardRetainPopUpViewController.h"

@implementation CJPayBindCardSetPasswordRetainInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"isNeedRetain" : @"is_need_retention",
        @"title": @"title",
        @"buttonType" : @"button_type",
        @"buttonMsg" : @"button_msg",
        @"buttonLeftMsg" : @"button_left_msg",
        @"buttonRightMsg" : @"button_right_msg"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
