//
//  NLECurveSpeedCalculator+iOS.h
//  NLEPlatform
//
//  Created by bytedance on 2021/7/29.
//

#import <Foundation/Foundation.h>

/**
 * 有两个概念需要明确：
 * 1. Segment Point / Trim Point : 素材时间坐标系中的锚点；
 *      比如一段视频时长10秒，PointA(0.5, 2.0) 表示播放视频的第5秒的位置时是2倍速播放；
 * 2. Sequence Point : 播放时间坐标系中的锚点；
 *      比如一段视频时长10秒，假设曲线变速导致实际播放时长变为4秒，PointA(0.5, 2.0) 表示播放到第2秒的时候是2倍速播放；
 *
 * 代码中参数缩写非常接近，请注意分辨！
 * SegmentPoint : S e g Point : SEGPoint
 * SequencePoint : S e q Point : SEQPoint
 */
@interface NLECurveSpeedCalculator_OC: NSObject

/// segment points -> sequence points
+ (NSArray<NSValue *> *)segmentPToSequenceP:(NSArray<NSValue *> *)segPoints;

- (instancetype)initWithSeqPoints:(NSArray<NSValue *> *)seqPoints;
- (instancetype)initWithSegPoints:(NSArray<NSValue *> *)segPoints;

/**
 * 平均速度
 */
- (double)getAveCurveSpeedRatio;

/**
 * @param seqDurationUs 变速后该段素材播放时长us
 */
- (double)getSpeedRatioBySeqDelta:(int64_t)sequenceDeltaUs seqDurationUs:(int64_t)seqDurationUs;

/**
 * @param seqDurationUs 变速后该段素材播放时长
 */
- (int64_t)sequenceDelToSegmentDel:(int64_t)sequenceDeltaUs  seqDurationUs:(int64_t)seqDurationUs;

/**
 * @param seqDurationUs 变速后该段素材播放时长
 */
- (int64_t)segmentDelToSequenceDel:(int64_t)segmentDeltaUs seqDurationUs:(int64_t)seqDurationUs;

/// 生成3阶贝塞尔曲线的起始点、控制点（两个）、终点
/// @param points 两个归一化坐标点
+ (NSArray<NSValue *>*)generateThirdBezierPathPoints:(NSArray<NSValue *>*)points;

/// 生成所有的贝塞尔曲线点
/// @param points 四个贝塞尔曲线点
+ (NSArray<NSValue *>*)generateBezierPathLookupTable:(NSArray<NSValue *>*)points;

/// 计算当前progress下的拟合贝塞尔曲线点
/// @param points 3阶贝塞尔曲线的起始点、控制点（两个）、终点
/// @param progress [0, 1]
+ (NSArray<NSValue *>*)recursiveCalculateCubePoint:(NSArray<NSValue *>*)points progress:(float)progress;

/// 根据两个点坐标，以及这
/// @param left CGPoint
/// @param right CGPoint
/// @param duration 整个贝塞尔曲线对应的x轴时长
/// @param offset 当前要计算的点所在的x轴偏移位置
+ (CGPoint)getBezierPointsWithLeft:(CGPoint)left right:(CGPoint)right duration:(int64_t)duration offet:(int64_t)offset;

/// 计算当前时间t下的拟合贝塞尔曲线点，这个是通过公式直接计算所得
/// @param t [0, 1]
/// @param start 起始点
/// @param control1 控制点1
/// @param control2 控制点2
/// @param end 终点
+ (CGPoint)calculateCubePointWithT:(float)t start:(CGPoint)start control1:(CGPoint)control1 control2:(CGPoint)control2 end:(CGPoint)end;

@end

