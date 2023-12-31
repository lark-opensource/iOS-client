//
//  CJPayCombinePayLimitModel.m
//  Pods
//
//  Created by wangxiaohong on 2021/4/20.
//

#import "CJPayCombinePayLimitModel.h"

@implementation CJPayCombinePayLimitModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"title" : @"page_title",
                @"desc" : @"page_desc",
                @"highLightDesc" : @"high_light_desc",
                @"buttonDesc" : @"button_desc",
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
