//
//  ACCEditTagsModel.m
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/10/11.
//

#import "ACCEditTagsModel.h"

@implementation ACCEditTagsURLModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{@"URI"     : @"uri",
             @"urlList" : @"url_list",
             @"imageWidth" : @"width",
             @"imageHeight" : @"height",
    };
}

@end

@implementation ACCEditCommerceTagsModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"imageURL" : @"image",
        @"type" : @"type",
        @"itemID" : @"id",
        @"categories" : @"category",
        @"title" : @"title",
        @"importCount" : @"import_num",
        @"schema" : @"schema",
    };
}

@end

@implementation ACCEditCommerceSearchResponse

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return [@{
        @"commerceTags" : @"tag_list",
        @"hasMore" : @"has_more",
        @"cursor" : @"cursor",
    } acc_apiPropertyKey];
}

+ (NSValueTransformer *)commerceTagsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:ACCEditCommerceTagsModel.class];
}

+ (NSValueTransformer *)categoriesJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:NSString.class];
}


@end
