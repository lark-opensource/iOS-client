//
//  CJPayLynxShowInfo.m
//  Aweme
//
//  Created by youerwei on 2023/6/6.
//

#import "CJPayLynxShowInfo.h"

@implementation CJPayLynxShowInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"url": @"url",
        @"needJump": @"need_jump",
        @"type": @"type",
        @"exts": @"exts"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
