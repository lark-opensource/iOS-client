//
//  CJPayBindCardBackgroundInfo.m
//  Pods
//
//  Created by xutianxi on 2022/12/12.
//

#import "CJPayBindCardBackgroundInfo.h"

@implementation CJPayBindCardBackgroundInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"backgroundImageUrl":@"background_image_url",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
