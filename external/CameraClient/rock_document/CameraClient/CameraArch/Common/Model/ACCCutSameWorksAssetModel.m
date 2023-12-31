//
//  ACCutSameWorksAssetModel.m
//  CameraClient-Pods-Aweme
//
//  Created by wanghongyu on 2020/6/9.
//

#import "ACCCutSameWorksAssetModel.h"

@implementation ACCCutSameWorksAssetModel

- (instancetype)initWithAssetModel:(AWEAssetModel * )assetModel
                         startTime:(CGFloat)startTime
                           endTime:(CGFloat)endTime
                        cropPoints:(NSArray<NSValue *> *)cropPoints {
    self = [super init];
    if (self) {
        self.assetModel = assetModel;
        self.cropPoints = cropPoints;
        CMTime startT = CMTimeMake(startTime, 1000);
        CMTime durationT = CMTimeMake((endTime - startTime), 1000);
        self.sourceTimeRange = CMTimeRangeMake(startT, durationT);
    }
    return self;
}

@end
