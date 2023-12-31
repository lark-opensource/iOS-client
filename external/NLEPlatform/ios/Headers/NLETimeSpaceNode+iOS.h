//
//  NLETimeSpaceNode+iOS.h
//  Pods
//
//  Created by bytedance on 2020/12/24.
//

#ifndef NLETimeSpaceNode_iOS_h
#define NLETimeSpaceNode_iOS_h

#import <Foundation/Foundation.h>
#import "NLENode+iOS.h"
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLETimeSpaceNode_OC : NLENode_OC

@property (nonatomic, assign) CMTime duration;

/// 位移（Z轴） 0~1000; 渲染层级，数值越大显示在越上面；取值范围：0~1000；
@property (nonatomic, assign) NSInteger layer;

@property (nonatomic, assign) CGFloat speed;

/// 坐标原点：屏幕中心
/// X轴正方向：用户视角：屏幕left -> 屏幕right
/// Y轴正方向：用户视角：屏幕bottom -> 屏幕top
/// Z轴正方向：用户视角：屏幕inside -> 屏幕outside
/// 位移 -1.0f~1.0f
- (float)transformX;

- (void)setTransformX:(float)transformX;

/// 位移 -1.0f~1.0f
- (float)transformY;

- (void)setTransformY:(float)transformY;

/// 位移（Z轴） 0~1000; 渲染层级，数值越大显示在越上面；取值范围：0~1000；
- (int32_t)transformZ;

- (void)setTransformZ:(int32_t)transformZ;

/// 基于Z轴正方向逆时针旋转，取值范围 0~359; （正值：逆时针旋转 负值：顺时针旋转）
- (float)rotation;

/// 基于Z轴正方向逆时针旋转，取值范围 0~359; （正值：逆时针旋转 负值：顺时针旋转）
/// @param rotation float
- (void)setRotation:(float)rotation;

/// 对于视频/图片：1.0f是视频/图片在画布中center inside时的比例
/// 对于文字/帖纸：1.0f是文字/贴纸首次渲染到VE的一个基准大小
/// 不应该过于依赖scale的数值，而应注重它的差值
- (float)scale;

- (void)setScale:(float)scale;

- (NSInteger)mirror;

- (void)setMirror:(NSInteger)mirror;

/// mirror 镜像状态 0表示正常状态, 1表示mirror_horizontal, 2表示mirror_vertical
- (NSInteger)Mirror_X;

- (void)setMirror_X:(NSInteger)mirrorx;

- (NSInteger)Mirror_Y;

- (void)setMirror_Y:(NSInteger)mirrory;

/// 起始时间
- (CMTime)startTime;

/// 设置起始时间
- (void)setStartTime:(CMTime)startTime;

/// 终止时间，假如未设置或者为-1，表示 WRAP_CONTENT，根据 segment 计算出时长
- (CMTime)endTime;

/// 设置终止时间
/// @param endTime CMTime
- (void)setEndTime:(CMTime)endTime;

- (BOOL)hadEndTime;

- (void)setRelativeWidth:(float)relativeWidth;

/// 宽，（相对于parent），默认等于 parent 尺寸
- (float)RelativeWidth;

- (void)setRelativeHeight:(float)relativeHeight;

/// 高，（相对于parent，比如parent高度1000，当前节点高度200，那么 RelativeHeight = 0.2f），默认等于 parent 尺寸
- (float)RelativeHeight;

/// 获取时长
- (CMTime)getDuration;

/// starttime + duration
- (CMTime)getMeasuredEndTime;

/// 和transformZ一样
- (NSInteger)getLayer;

- (NSArray<NSString *> *)processors;
- (void)setProcessors:(NSArray<NSString *> *)processors;

- (NSArray<NLETimeSpaceNode_OC *> *)collectProcessNodes;

@end

NS_ASSUME_NONNULL_END

#endif /* NLETimeSpaceNode_iOS_h */
