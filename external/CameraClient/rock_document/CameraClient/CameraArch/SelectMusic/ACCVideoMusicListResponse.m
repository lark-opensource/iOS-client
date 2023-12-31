//
//  ACCVideoMusicListResponse.m
//  CameraClient
//
//  Created by xiangwu on 2017/6/14.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "ACCVideoMusicListResponse.h"

#import <CreativeKit/ACCServiceLocator.h>
#import <IESInject/IESInjectDefines.h>

#import "ACCMusicTransModelProtocol.h"

@interface ACCVideoMusicListResponse ()

@property (nonatomic, strong) NSArray *mc_list;
@property (nonatomic, strong) NSArray *music_list;

@end

@implementation ACCVideoMusicListResponse

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return [@{
              @"mc_list": @"mc_list",
              @"music_list": @"music_list",
              @"cursor": @"cursor",
              @"hasMore": @"has_more",
              @"titleModel" : @"mc_info",
              @"musicType" : @"music_type",
              } acc_apiPropertyKey];
}

- (NSArray *)mcList {
    if (self.mc_list) {
        return self.mc_list;
    } else {
        return self.music_list;
    }
}

+ (NSValueTransformer *)titleModelJSONTransformer {
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[ACCVideoMusicCategoryModel class]];
}

- (NSArray<id<ACCMusicModelProtocol>> *)musicList
{
    return [MTLJSONAdapter modelsOfClass:[IESAutoInline(ACCBaseServiceProvider(), ACCMusicTransModelProtocol) musicModelImplClass] fromJSONArray:self.mcList error:nil];
}

@end
