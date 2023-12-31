//
//  LVMediaSegment+Speed.h
//  BDABTestSDK
//
//  Created by kevin gao on 2019/12/13.
//

#import "LVMediaSegment.h"
#import <TTVideoEditor/IESMMCurveSource.h>

NS_ASSUME_NONNULL_BEGIN

@interface LVMediaSegment (Speed)

#pragma mark - seek & 更新坐标系seekpin 转换

/**
 播放时间点转视频时间点
 palyTime 当前时间线的时间
 */
+ (CMTime)convertPlayTimeToVideoTime:(CMTime)palyTime
                      sourceDuration:(CMTime)sourceDuration
                         valuePoints:(NSArray<NSValue*>*)valuePoints;

/**
视频时间点转换播放时间点
videoTime 当前时间线的时间
 */
+ (CMTime)convertVideoTimeToPlayTime:(CMTime)videoTime
                      sourceDuration:(CMTime)sourceDuration
                         valuePoints:(NSArray<NSValue*>*)valuePoints;

#pragma mark - 曲线变速计算

+ (NSArray<NSValue*>*)valuePointsWithSpeedPoints:(NSArray<LVPoint*>*)speedPoints;

/*
计算曲线变速后的视频时长
*/
+ (CGFloat)convertToCurveSpeedDurationWith:(CMTime)sourceDuration
                               valuePoints:(NSArray<NSValue*>*)valuePoints;

+ (CGFloat)convertToCurveSpeedDurationWith:(CMTime)sourceDuration
                                    points:(NSArray<LVPoint*>*)speedPoints;

/*
 计算曲线变速后 相对于原视频长度的速度变化
 获得曲线变速的平均值
 */
+ (CGFloat)avgRatioSpeedWith:(CMTime)sourceDuration points:(NSArray<LVPoint*>*)speedPoints;

/*
 计算曲线变速的平均速度值
 */
- (CGFloat)avgRatioSpeedValue:(LVDraftSpeedPayload*)payload;

#pragma mark - 曲线变速配置

/*
 IESMMCurveSource
 曲线变速配置
 */
- (nullable IESMMCurveSource *)curveSpeedSource;

@end

NS_ASSUME_NONNULL_END
