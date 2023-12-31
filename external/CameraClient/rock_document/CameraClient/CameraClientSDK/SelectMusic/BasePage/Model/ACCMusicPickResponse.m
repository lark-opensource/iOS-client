//
//  ACCMusicPickResponse.m
//  CameraClient
//
//  Created by 李彦松 on 2018/9/4.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "ACCMusicPickResponse.h"

#import "ACCVideoMusicCategoryModel.h"
#import <CreationKitInfra/NSDictionary+ACCAddBaseApiPropertyKey.h>

#import <CreativeKit/ACCServiceLocator.h>

@implementation ACCMusicPickResponse

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return [@{@"statusCode" : @"status_code",
              @"message"    : @"msg",
              @"banners"    : @"banner_list",
              @"categories" : @"mc_list",
              @"musicList"  : @"music_list",
              @"extraMusicList" : @"extra_music_list",
              @"musicListType"   : @"music_list_type",
              @"hasMore" : @"has_more",
              @"FMCursor"   : @"radio_cursor"} acc_apiPropertyKey];
}

+ (NSValueTransformer *)bannersJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[IESAutoInline(ACCBaseServiceProvider(), ACCMusicTransModelProtocol) bannerModelImplClass]];
}

+ (NSValueTransformer *)categoriesJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ACCVideoMusicCategoryModel class]];
}

+ (NSValueTransformer *)musicListJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[IESAutoInline(ACCBaseServiceProvider(), ACCMusicTransModelProtocol) musicModelImplClass]];
}

+ (NSValueTransformer *)extraMusicListJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[IESAutoInline(ACCBaseServiceProvider(), ACCMusicTransModelProtocol) musicModelImplClass]];
}

@end
