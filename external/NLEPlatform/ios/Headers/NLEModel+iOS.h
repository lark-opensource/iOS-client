//
//  NLEModel+iOS.h
//  NLEPlatform
//
//  Created by bytedance on 2020/12/7.
//

#ifndef NLEModel_iOS_h
#define NLEModel_iOS_h
#import <Foundation/Foundation.h>
#import "NLETimeSpaceNodeGroup+iOS.h"
#import "NLETrack+iOS.h"
#import "NLEFilter+iOS.h"
#import "NLESegmentImageVideoAnimation+iOS.h"
#import "NLEVideoFrameModel+iOS.h"
#import "NLENativeDefine.h"

@class NLEResourceNode_OC;

@interface NLEModel_OC : NLETimeSpaceNode_OC

/// 画布比例 默认 16:9（桌面端编辑器横屏的情况）；screen width / screen height；宽高比；
@property (nonatomic, assign) float canvasRatio;

/// 带画布size初始化，如果Size不合法，默认是16:9
/// @param canvasSize CGSize
- (instancetype)initWithCanvasSize:(CGSize)canvasSize;

/// 视频编辑封面模型
@property (nonatomic, strong) NLEVideoFrameModel_OC *coverModel;

@property (nonatomic, copy) NLEAlignModeOC alignMode;

- (uint32_t)getThousandFps;

- (void)setThousandFps:(uint32_t)fps;

/// 更新画布比例，同时修改 relativeWidth, relativeHeight 参数以确保原先的子元素布局不变
/// （调用 setCanvasRatio 不调节 relativeWidth, relativeHeight 参数的话，子元素会错乱）
/// @param canvasRatio float
- (void)setCanvasRatioWithUpdateRelativeLocation:(float)canvasRatio;

/// 添加轨道
/// @param track NLETrack_OC *
- (void)addTrack:(NLETrack_OC *)track;

/// 获取所有轨道
- (NSArray<NLETrack_OC*>*)getTracks;

/// 删除某个轨道
/// @param track NLETrack_OC *
- (void)removeTrack:(NLETrack_OC*)track;

/// 清空所有轨道
- (void)clearTracks;

/**
 * 获取所有轨道 最小的起始时间点, 起始点为0；
 * 返回 -1 表示当前没有任何轨道；
 * 单位微秒 （1s=1000000us）
 */
- (int64_t)getMinTargetStart;

/**
 * 获取所有轨道 最大的结束时间点, 起始点为0；
 * 返回 -1 表示当前没有任何轨道；
 * 单位微秒 （1s=1000000us）
 */
- (int64_t)getMaxTargetEnd;


/// 获取所有轨道 最大的结束时间点
/// @param excludeDisable BOOL 计算的时候是否排除disable 的track 和slot
- (CMTime)getMaxTargetEndExcludeDisabledNode:(BOOL)excludeDisable;

/// 获取slot的最大层级，遍历所有轨道里的slots
- (int32_t)getLayerMax;

/// 获取特效的最大层级
- (int32_t)getEffectLayerMax;

/**
 * @brief 设置对应类型轨道倒放
 * @param isRewind 是否倒放
 * @param exceptTrackTypes 不进行处理的轨道
 */
- (void)setRewind:(BOOL)isRewind withExceptTrackTypes:(NSArray<NSNumber *> *)exceptTrackTypes;
/**
 * @brief 设置对应类型轨道倒放
 * @param isRewind 是否倒放
 * @param exceptTrackTypes 不进行处理的轨道
 */
- (void)setRewind:(BOOL)isRewind withExceptTrackTypes:(NSArray<NSNumber *> *)exceptTrackTypes;

- (NSArray <NLEResourceNode_OC *> *)allResources;

@end

#endif /* NLEModel_iOS_h */
