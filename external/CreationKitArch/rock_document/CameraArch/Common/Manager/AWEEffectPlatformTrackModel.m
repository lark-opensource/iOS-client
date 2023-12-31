//
//  AWEEffectPlatformTrackModel.m
//  CameraClient
//
//  Created by Howie He on 2021/3/18.
//

#import "AWEEffectPlatformTrackModel.h"
#import <CreationKitInfra/AWEModernStickerDefine.h>
#import <CreationKitArch/IESEffectModel+ACCSticker.h>

@implementation AWEEffectPlatformTrackModel

+ (instancetype)modernStickerTrackModel {
    AWEEffectPlatformTrackModel *item = [AWEEffectPlatformTrackModel new];
    item.trackName = AWE_STICKER_DOWNLOAD_KEY;
    item.successStatus = @0;
    item.failStatus = @1;
    item.effectIDKey = @"effect_id";
    item.effectNameKey = @"effect_name";
    item.extraTrackInfoDictBlock = ^NSDictionary *(IESEffectModel * effect, NSError * error) {
        return @{@"is_ar" : @([effect isTypeAR])};
    };
    return item;
}

@end
