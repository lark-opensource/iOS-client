//
//  ACCShootSameStickerModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/16.
//

#import "ACCShootSameStickerModel.h"

@implementation ACCShootSameStickerModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"uuid" : @"uuid",
        @"stickerType" : @"stickerType",
        @"locationModel" : @"locationModel",
        @"stickerModelStr" : @"stickerModelStr",
        @"deleted" : @"deleted",
        @"referExtraParams" : @"referExtraParams",
    };
}

+ (NSValueTransformer *)locationModelJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[AWEInteractionStickerLocationModel class]];
}

- (NSString *)uuid
{
    if (!_uuid) {
        _uuid = [[NSUUID UUID] UUIDString];
    }
    return _uuid;
}

@end
