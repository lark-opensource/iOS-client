//
//  CJPayForgetPwdInfo.m
//  Pods
//
//  Created by wangxiaohong on 2021/7/28.
//

#import "CJPayForgetPwdInfo.h"

@implementation CJPayForgetPwdInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"action" : @"action",
                @"style" : @"show_style",
                @"desc" : @"desc",
                @"times" : @"times"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
