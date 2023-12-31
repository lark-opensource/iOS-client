//
//  ACCBirthdayTemplateModel.m
//  AWEFriends-Pods-Aweme
//
//  Created by shaohua yang on 11/16/20.
//

#import "ACCBirthdayTemplateModel.h"

@implementation ACCBirthdayTemplateModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"effectId": @"effect_id",
        @"previewAddr": @"preview_picture",
        @"icon": @"icon",
        @"title": @"text",
    };
}

@end
