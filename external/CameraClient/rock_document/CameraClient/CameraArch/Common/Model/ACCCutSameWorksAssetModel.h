//
//  ACCCutSameWorksAssetModel.h
//  CameraClient-Pods-Aweme
//
//  Created by wanghongyu on 2020/6/9.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CMTimeRange.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEAssetModel;

@interface ACCCutSameWorksAssetModel : NSObject

@property (nonatomic, strong) AWEAssetModel * assetModel;
@property (nonatomic, assign) CMTimeRange sourceTimeRange;
@property (nonatomic, copy) NSArray<NSValue *> *cropPoints;

- (instancetype)initWithAssetModel:(AWEAssetModel * )assetModel
                         startTime:(CGFloat)startTime
                           endTime:(CGFloat)endTime
                        cropPoints:(NSArray<NSValue *> *)cropPoints;

@end

NS_ASSUME_NONNULL_END
