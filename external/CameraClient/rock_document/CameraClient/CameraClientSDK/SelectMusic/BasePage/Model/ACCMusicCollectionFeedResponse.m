//
//  ACCMusicCollectionFeedResponse.m
//  AWEStudio
//
//  Created by 李彦松 on 2018/9/4.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "ACCMusicCollectionFeedResponse.h"

#import "ACCMusicCollectionFeedModel.h"
#import "ACCVideoMusicCategoryModel.h"
#import <CreationKitInfra/NSDictionary+ACCAddBaseApiPropertyKey.h>

@implementation ACCMusicCollectionFeedResponse

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return [@{
        @"statusCode" : @"status_code",
        @"message"    : @"msg",
        @"musicCollection" : @"mcf_list",
        @"childrenCollections" : @"child_collections",
        @"hasMore"    : @"has_more",
        @"cursor"     : @"cursor",
        @"mcList"     : @"music_list"
    } acc_apiPropertyKey];
}

+ (NSValueTransformer *)musicCollectionJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ACCMusicCollectionFeedModel class]];
}

+ (NSValueTransformer *)childrenCollectionsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ACCVideoMusicCategoryModel class]];
}
@end
