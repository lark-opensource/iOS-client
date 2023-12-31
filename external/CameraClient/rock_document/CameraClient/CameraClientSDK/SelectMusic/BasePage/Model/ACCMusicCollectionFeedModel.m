//
//  ACCMusicCollectionFeedModel.m
//  CameraClient
//
//  Created by 李彦松 on 2018/9/4.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "ACCMusicCollectionFeedModel.h"
#import "ACCVideoMusicCategoryModel.h"

#import <IESInject/IESInjectDefines.h>
#import <CreativeKit/ACCServiceLocator.h>

@implementation ACCMusicCollectionFeedModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"category" : @"collection",
        @"musicList" : @"music_list",
    };
}

+ (NSValueTransformer *)categoryJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[ACCVideoMusicCategoryModel class]];
}

+ (NSValueTransformer *)musicListJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[IESAutoInline(ACCBaseServiceProvider(), ACCMusicTransModelProtocol) musicModelImplClass]];
}

@end
