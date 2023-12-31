//
//  CJPayTradeQueryContentList.m
//  Pods
//
//  Created by chenbocheng on 2022/7/14.
//

#import "CJPayTradeQueryContentList.h"

@implementation CJPayTradeQueryContentList

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"subTitle" : @"sub_title",
                @"subContent" : @"sub_content",
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
