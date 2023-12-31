//
//  AWEInteractionEditTagStickerModel.m
//  CameraClient-Pods-AwemeCore
//
//  Created by 卜旭阳 on 2021/10/6.
//

#import "AWEInteractionEditTagStickerModel.h"
#import <Mantle/EXTKeyPathCoding.h>

@implementation AWEInteractionEditTagUserTagModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    AWEInteractionEditTagUserTagModel *model = nil;
    return @{
        @keypath(model, userID) : @"user_id",
        @keypath(model, secUID) : @"user_sec_id",
    };
}

@end

@implementation AWEInteractionEditTagCustomTagModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    AWEInteractionEditTagCustomTagModel *model = nil;
    return @{
        @keypath(model, name) : @"name",
    };
}

@end

@implementation AWEInteractionEditTagPOITagModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    AWEInteractionEditTagPOITagModel *model = nil;
    return @{
        @keypath(model, POIID) : @"poi_id",
    };
}

@end

@implementation AWEInteractionEditTagGoodsTagModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    AWEInteractionEditTagGoodsTagModel *model = nil;
    return @{
        @keypath(model, productID) : @"product_id",
        @keypath(model, schema) : @"schema",
    };
}

@end

@implementation AWEInteractionEditTagBrandTagModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    AWEInteractionEditTagBrandTagModel *model = nil;
    return @{
        @keypath(model, brandID) : @"brand_id",
        @keypath(model, schema) : @"schema",
    };
}

@end

@implementation AWEInteractionEditTagStickerInfoModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    AWEInteractionEditTagStickerInfoModel *model = nil;
    return @{
        @keypath(model, type) : @"type",
        @keypath(model, text) : @"title",
        @keypath(model, orientation) : @"orientation",
        @keypath(model, customTag) : @"custom_tag",
        @keypath(model, userTag) : @"user_tag",
        @keypath(model, POITag) : @"poi_tag",
        @keypath(model, goodsTag) : @"product_tag",
        @keypath(model, brandTag) : @"brand_tag"
    };
}

+ (NSValueTransformer *)customTagJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[AWEInteractionEditTagCustomTagModel class]];
}

+ (NSValueTransformer *)userTagJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[AWEInteractionEditTagUserTagModel class]];
}

+ (NSValueTransformer *)POITagJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[AWEInteractionEditTagPOITagModel class]];
}

+ (NSValueTransformer *)goodsTagJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[AWEInteractionEditTagGoodsTagModel class]];
}

+ (NSValueTransformer *)brandTagJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[AWEInteractionEditTagBrandTagModel class]];
}

- (NSString *)tagId
{
    switch (self.type) {
        case ACCEditTagTypeNone:
        case ACCEditTagTypeSelfDefine:
            return self.text;
        case ACCEditTagTypeUser:
            return self.userTag.userID;
        case ACCEditTagTypePOI:
            return self.POITag.POIID;
        case ACCEditTagTypeCommodity:
            return self.goodsTag.productID;
        case ACCEditTagTypeBrand:
            return self.brandTag.brandID;
    }
}

- (NSString *)tagType
{
    switch (self.type) {
        case ACCEditTagTypeNone:
        case ACCEditTagTypeSelfDefine:
            return @"custom";
        case ACCEditTagTypeUser:
            return @"user";
        case ACCEditTagTypePOI:
            return @"poi";
        case ACCEditTagTypeCommodity:
            return @"goods";
        case ACCEditTagTypeBrand:
            return @"brand";
    }
}

- (BOOL)interactional
{
    return self.type == ACCEditTagTypeUser || self.type == ACCEditTagTypePOI || self.type == ACCEditTagTypeCommodity || self.type == ACCEditTagTypeBrand;
}

@end

@implementation AWEInteractionEditTagStickerModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    NSMutableDictionary *keyPathDict = [NSMutableDictionary dictionaryWithDictionary:[[[AWEInteractionEditTagStickerModel class] superclass] JSONKeyPathsByPropertyKey]];
    [keyPathDict addEntriesFromDictionary:@{
        @"editTagInfo" : @"tag_interaction"
    }];
    return keyPathDict;
}

+ (NSValueTransformer *)editTagInfoJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:AWEInteractionEditTagStickerInfoModel.class];
}

@end
