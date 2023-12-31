//
//  ACCNewYearWishEditModel.m
//  Aweme
//
//  Created by 卜旭阳 on 2021/11/1.
//

#import "ACCNewYearWishEditModel.h"

@implementation ACCNewYearWishEditModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"effectId" : @"effectId",
        @"officialText" : @"officialText",
        @"text" : @"text",
        @"images" : @"images",
        @"avatarPath" : @"avatarPath",
        @"originAvatarPath" : @"originAvatarPath",
        @"avatarURI" : @"avatarURI"
    };
}

@end
