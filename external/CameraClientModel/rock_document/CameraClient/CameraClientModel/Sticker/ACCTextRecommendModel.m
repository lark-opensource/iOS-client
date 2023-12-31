//
//  ACCTextRecommendModel.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/8/1.
//

#import "ACCTextRecommendModel.h"

@implementation ACCTextStickerRecommendItem

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"titleId" : @"id",
        @"content" : @"content"
    };
}

@end

@implementation ACCTextStickerLibItem

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"titles" : @"title",
        @"name" : @"tab_name"
    };
}

@end
