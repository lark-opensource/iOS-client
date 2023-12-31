//
//  ACCMusicCollectListsResponseModel.m
//  CameraClient
//
//  Created by hanxu on 2017/3/20.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "ACCMusicCollectListsResponseModel.h"
#import <CreationKitInfra/NSDictionary+ACCAddBaseApiPropertyKey.h>

#import <CreativeKit/ACCServiceLocator.h>

@implementation ACCMusicCollectListsResponseModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return [@{@"mcList": @"mc_list",
              @"cursor"   : @"cursor",
              @"hasMore"  : @"has_more",
              } acc_apiPropertyKey];
}

+ (NSValueTransformer *)mcListJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[IESAutoInline(ACCBaseServiceProvider(), ACCMusicTransModelProtocol) musicModelImplClass]];
}

+ (NSValueTransformer *)hasMoreJSONTransformer
{
    return [NSValueTransformer valueTransformerForName:MTLBooleanValueTransformerName];
}

@end
