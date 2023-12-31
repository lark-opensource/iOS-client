//
//  AWEInteractionStickerLocationModel+ACCSticker.h
//  CameraClient
//
//  Created by liuqing on 2020/6/19.
//

#import "AWEInteractionStickerModel.h"
#import <CreativeKitSticker/ACCStickerGeometryModel.h>
#import <CreativeKitSticker/ACCStickerTimeRangeModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEInteractionStickerLocationModel (ACCSticker)

- (instancetype)initWithGeometryModel:(ACCStickerGeometryModel * _Nullable)geometryModel andTimeRangeModel:(ACCStickerTimeRangeModel * _Nullable)timeRangeModel;

- (ACCStickerGeometryModel *)geometryModel;

- (ACCStickerGeometryModel *)ratioGeometryModel;

- (ACCStickerTimeRangeModel *)timeRangeModel;

@end

NS_ASSUME_NONNULL_END
