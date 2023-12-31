//
//  AWEInteractionStickerLocationModel+ACCSticker.m
//  CameraClient
//
//  Created by liuqing on 2020/6/19.
//

#import "AWEInteractionStickerLocationModel+ACCSticker.h"

@implementation AWEInteractionStickerLocationModel (ACCSticker)

- (instancetype)initWithGeometryModel:(ACCStickerGeometryModel *)geometryModel andTimeRangeModel:(ACCStickerTimeRangeModel *)timeRangeModel
{
    self = [self init];
    
    if (self) {
        self.isRatioCoord = geometryModel.preferredRatio;
        if (geometryModel.preferredRatio) {
            self.x = geometryModel.xRatio;
            self.y = geometryModel.yRatio;
        } else {
            self.x = geometryModel.x;
            self.y = geometryModel.y;
        }
        
        self.width = geometryModel.width;
        self.height = geometryModel.height;
        self.rotation = geometryModel.rotation;
        self.scale = geometryModel.scale;
        self.pts = timeRangeModel.pts;
        self.startTime = timeRangeModel.startTime;
        self.endTime = timeRangeModel.endTime;
    }
    
    return self;
}

- (ACCStickerGeometryModel *)geometryModel
{
    if (self.isRatioCoord) {
        return [self ratioGeometryModel];
    } else {
        return [self absoluteGeometryModel];
    }
}

- (ACCStickerGeometryModel *)absoluteGeometryModel
{
    ACCStickerGeometryModel *geometryModel = [[ACCStickerGeometryModel alloc] init];
    geometryModel.x = self.x;
    geometryModel.y = self.y;
    geometryModel.width = self.width;
    geometryModel.height = self.height;
    geometryModel.rotation = self.rotation;
    geometryModel.scale = self.scale;
    geometryModel.preferredRatio = NO;
    
    return geometryModel;
}

- (ACCStickerGeometryModel *)ratioGeometryModel
{
    ACCStickerGeometryModel *geometryModel = [[ACCStickerGeometryModel alloc] init];
    geometryModel.xRatio = self.x;
    geometryModel.yRatio = self.y;
    geometryModel.width = self.width;
    geometryModel.height = self.height;
    geometryModel.rotation = self.rotation;
    geometryModel.scale = self.scale;
    geometryModel.preferredRatio = YES;
    
    return geometryModel;
}

- (ACCStickerTimeRangeModel *)timeRangeModel
{
    ACCStickerTimeRangeModel *timeRangeModel = [[ACCStickerTimeRangeModel alloc] init];
    timeRangeModel.pts = self.pts;
    timeRangeModel.startTime = self.startTime;
    timeRangeModel.endTime = self.endTime;
    
    return timeRangeModel;
}

@end
