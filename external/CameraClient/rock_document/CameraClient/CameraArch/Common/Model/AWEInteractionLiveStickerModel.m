//
//  AWEInteractionLiveStickerModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/4/20.
//

#import "AWEInteractionLiveStickerModel.h"

@implementation AWEInteractionLiveStickerModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    NSMutableDictionary *keyPathDict = [NSMutableDictionary dictionaryWithDictionary:[[[AWEInteractionLiveStickerModel class] superclass] JSONKeyPathsByPropertyKey]];
    [keyPathDict addEntriesFromDictionary:@{
        @"liveInfo" : @"live_preview_info"
    }];
    return keyPathDict;
}

+ (NSValueTransformer *)liveInfoJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:AWEInteractionLiveStickerInfoModel.class];
}

@end

@implementation AWEInteractionLiveStickerInfoModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"targetTime" : @"live_start_time",
        @"status" : @"status",
        @"btnClicked" : @"has_clicked_btn",
        @"roomID" : @"room_id"
    };
}

- (BOOL)liveTimeValid
{
    return (self.status != ACCLiveStickerViewStatusEnd && self.status != ACCLiveStickerViewStatusTimeout);
}

- (BOOL)showToSee
{
    return (self.status == ACCLiveStickerViewStatusDefault || self.status == ACCLiveStickerViewStatusNearby);
}

- (NSString *)liveStatusStr
{
    switch (self.status) {
        case ACCLiveStickerViewStatusLiving:
            return @"live";
        case ACCLiveStickerViewStatusEnd:
            return @"finish";
        case ACCLiveStickerViewStatusTimeout:
            return @"overdue";
        default:
            return @"trailer";
    }
    return @"";
}

- (NSInteger)indexFromType
{
    return 2;
}

@end
