//
//  CJPaySubPayTypeIconTipModel.m
//  Pods
//
//  Created by bytedance on 2021/6/25.
//

#import "CJPaySubPayTypeIconTipModel.h"

@implementation CJPaySubPayTypeIconTipModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"title": @"title",
        @"contentList": @"content_list",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end

