//
//  ACCVideoMusicCategoryModel.m
//  CameraClient
//
//  Created by xiangwu on 2017/6/14.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "ACCVideoMusicCategoryModel.h"
#import "ACCMusicTransModelProtocol.h"

#import <CreativeKit/ACCServiceLocator.h>
#import <IESInject/IESInjectDefines.h>


@implementation ACCVideoMusicCategoryModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
              @"idStr": @"id_str",
              @"name": @"name",
              @"cover": @"cover",
              @"awemeCover": @"aweme_cover",
              @"isHot": @"is_hot",
              @"level" : @"level",
              };
}

+ (NSValueTransformer *)coverJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[IESAutoInline(ACCBaseServiceProvider(), ACCMusicTransModelProtocol) urlModelImplClass]];
}

+ (NSValueTransformer *)awemeCoverJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[IESAutoInline(ACCBaseServiceProvider(), ACCMusicTransModelProtocol) urlModelImplClass]];
}

@end
