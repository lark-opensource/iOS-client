//
//  ACCRecognitionTrackModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/21.
//

#import "ACCRecognitionTrackModel.h"
#import "ACCGrootStickerModel.h"
#import "ACCRecognitionGrootConfig.h"

// 动植物道具Id
NSString * const kACCGrootRecognitionPropIdKeyInhouse = @"1165571";
NSString * const kACCGrootRecognitionPropIdKeyOnline = @"1165572";

@interface ACCRecognitionTrackModel()

@end

@implementation ACCRecognitionTrackModel

- (instancetype)copyWithZone:(NSZone *)zone
{
    ACCRecognitionTrackModel *model = [ACCRecognitionTrackModel new];
    model.realityId = _realityId;
    model.realityType = _realityType;
    model.enterMethod = _enterMethod;
    model.begin = _begin;
    model.duration = _duration;
    model.isSuccess = _isSuccess;
    model.propIndex = _propIndex;
    model.effect = _effect;
    model.grootModel = _grootModel;
    return model;
}

- (BOOL)isWikiType
{
    return [self.realityType isEqualToString:@"wiki_reality"];
}

#pragma mark - ACCRepositoryTrackContextProtocol

- (NSDictionary *)acc_referExtraParams
{
    NSMutableDictionary *params = [@{
        @"content_type": @"reality",
        @"reality_id": _realityId ?:@"",
        @"prop_selected_from": _realityType ?:@"",
    } mutableCopy];

    if (self.grootModel) {
        [params addEntriesFromDictionary:@{
            @"is_authorized":@(self.grootModel.stickerModel.allowGrootResearch),
            @"baike_id": self.grootModel.stickerModel.selectedGrootStickerModel.baikeId ?:@"",
            @"species_name": self.grootModel.stickerModel.selectedGrootStickerModel.speciesName ?:@"",
            @"is_sticker": @1,
            @"prop_id": [ACCRecognitionGrootConfig grootStickerId],
        }];
    }

    return params.copy;
}

@end

@implementation ACCRecognitionGrootModel
- (instancetype)copyWithZone:(NSZone *)zone
{
    ACCRecognitionGrootModel *model = [ACCRecognitionGrootModel new];
//    model.locationModel = _locationModel;
    model.stickerModel = _stickerModel;
    model.index = _index;
    model.scale = _scale;
    
    return model;
}

- (void)setIndex:(NSInteger)index
{
    if (index < 0 || index != _index ||
        index >= self.stickerModel.grootDetailStickerModels.count){
        return;
    }
    _index = index;
    self.stickerModel.selectedGrootStickerModel = self.stickerModel.grootDetailStickerModels[index];
}
@end
