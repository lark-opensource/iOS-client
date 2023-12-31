//
//  CJPayAuthDisplayMultiContentModel.m
//  Pods
//
//  Created by 易培淮 on 2020/8/7.
//

#import "CJPayAuthDisplayMultiContentModel.h"

@implementation CJPayAuthDisplayMultiContentModel

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"oneDisplayDesc": @"one_display_desc",
        @"secondDisplayContents": @"second_display_contents"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end

