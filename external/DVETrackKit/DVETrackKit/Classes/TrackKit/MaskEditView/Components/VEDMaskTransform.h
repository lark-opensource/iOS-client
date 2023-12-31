//
//  VEDMaskTransform.h
//  NLEEditor
//
//  Created by bytedance on 2021/4/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VEDMaskTransform : NSObject

+ (CGAffineTransform)convertAffineWithRotation:(CGFloat)rotation;

/// 判断点是否在以endPoint为圆心的扇形区域内
/// - Parameters:
///   - point: 判断点
///   - startPoint: 扇形的中间分割线起点
///   - endPoint: 扇形的中间分割线终点
///   - maxAngle: 最大角度

+ (BOOL)judgePoint:(CGPoint)point inCircularSectorWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint maxAngle:(CGFloat)maxAngle;

/// 向量投影
/// - Parameters:
///   - u: 源向量
///   - v: 目标向量
+ (CGPoint)projectedVectorFromU:(CGPoint)u toV:(CGPoint)v;

/// 判断点是否在矩形中
/// - Parameters:
///   - point: 待判断的点
///   - tl: 左上点
///   - tr: 右上点
///   - bl: 左下点
///   - br: 右下点

+ (BOOL)judgePoint:(CGPoint)point inRectangleA:(CGPoint)A B:(CGPoint)B C:(CGPoint)C D:(CGPoint)D;


@end

NS_ASSUME_NONNULL_END
