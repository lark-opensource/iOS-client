//
//  NLETrack+iOS.h
//  NLEPlatform
//
//  Created by bytedance on 2020/12/7.
//

#import <Foundation/Foundation.h>
#import "NLETrackSlot+iOS.h"
#import "NLEFilter+iOS.h"
#import "NLETimeSpaceNodeGroup+iOS.h"
#import "NLETimeEffect+iOS.h"
#import "NLEEffect+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLETrack_OC : NLETimeSpaceNode_OC

/// 是否是主轨，只有一个主轨
@property (nonatomic, assign, getter=isMainTrack) BOOL mainTrack;
@property (nonatomic, assign) CGFloat volume;
@property (nonatomic, strong) NLETimeEffect_OC* timeEffect;

/// 获取 track 上的所有 slot
@property (nonatomic, copy, readonly) NSArray<NLETrackSlot_OC *> *slots;

/// 获取 track 上的所有 filters
@property (nonatomic, copy) NSArray<NLEFilter_OC *> *filters;

/// 区别于trackType，这个类型不以轨道上的slot类型来判断，是独立值属性
/// 在强编辑场景中，会有特定类型的空轨道，比如用户从层级1移动slot到层级2轨
/// 道上，那么层级1会变成空轨道存在，有类型的空轨道
@property (nonatomic, assign) NLETrackType extraTrackType;

/// slot 按首尾相接的方式排序
- (void)timeSort;

/// 仅按 slot 的 startTime 排序
- (void)sort;

/// 切片
/// @param splitTime NSTimeInterval
- (NLETrackSlot_OC *)splitFromTime:(NSTimeInterval)splitTime;

/// 获取时间轴上最开始的slot的start time
- (CMTime)getMinStart;

/// 获取时间轴上最末尾的slot的end time
- (CMTime)getMaxEnd;

- (NLEFilter_OC*)getFilterByName:(NSString*)filterName;

- (NLEFilter_OC*)removeFilterByName:(NSString*)filterName;

/// 播放速率 变速参数；absSpeed = 2 表示2倍速快播；不可以设置为 0；
- (void)setAbsSpeed:(float)absSpeed;

/// 播放速率 变速参数；absSpeed = 2 表示2倍速快播；
-(float)getAbsSpeed;

/// 倒播
-(void)setRewind:(bool)rewind;

/// 倒播
-(bool)getRewind;

- (void)setLayer:(NSInteger)layer;

/// 轨道层级
- (NSInteger)layer;

- (int32_t)layerIndex;
- (void)setLayerIndex:(int32_t)layerIndex;

- (NLETrackSlot_OC*)getSlotByIndex:(NSInteger)index;

- (NSInteger)getSlotIndex:(NLETrackSlot_OC*)slot;

- (NSMutableArray<NLETrackSlot_OC*>*)getSortedSlots;

/// 对比两个track的时间轴是否变化
- (bool)isTimelineChange:(NLETrack_OC*)other;

- (NLEResourceType)getResourceType;

/// 轨道类型，会获取第一个slot的segment，通过判断segment的类型，来决定轨道类型
/// 一个轨道只能添加包含同类型segment的slot，如果一个轨道是空的，会返回 NLETrackNONE
- (NLETrackType)getTrackType;

/// 尾部添加片段
/// @param objects NLETrackSlot_OC *
- (void)addSlot:(NLETrackSlot_OC *)objects;

/// 在轨道头部插入，自动调节各个Slot时间
/// @param child NLETrackSlot_OC *
- (void)addSlotAtStart:(NLETrackSlot_OC*)child;

/// 在轨道尾部插入，自动调节各个Slot时间
/// 注意：会修改slot 的starttime
/// @param child NLETrackSlot_OC
- (void)addSlotAtEnd:(NLETrackSlot_OC*)child;

/// 指定位置插入片段
/// @param child NLETrackSlot_OC *
/// @param index int32_t
- (void)addSlot:(NLETrackSlot_OC*)child atIndex:(NSInteger)index;

- (void)addSlot:(NLETrackSlot_OC *)slot afterSlot:(NLETrackSlot_OC *)anchor;

/// 移除slot
/// @param slot NLETrackSlot_OC *
- (void)removeSlot:(NLETrackSlot_OC *)slot;

/// 清空所有slot
- (void)clearSlots;

/// 尾部添加滤镜
/// @param filter NLEFilter_OC *
- (void)addFilter:(NLEFilter_OC *)filter;

- (void)removeFilter:(NLEFilter_OC *)filter;

- (void)clearFilters;

/// 添加特效，track 可以添加特效；slot也可以添加特效，特效也可以单独作为轨道添加到model上
/// @param effect NLETrackSlot_OC *
- (void)addEffect:(NLETrackSlot_OC *)effect;

- (void)removeEffect:(NLETrackSlot_OC *)effect;

/// 获取该轨道上的所有特效
- (NSMutableArray<NLETrackSlot_OC *> *)getEffect;
                                 
/// 获取 track 上的所有关键帧
@property (nonatomic, copy) NSArray<NLETrackSlot_OC *> *keyframeSlots;

/// 添加关键帧
/// @param keyframe  关键帧Slot
- (void)addKeyframe:(NLETrackSlot_OC *)keyframe;

/// 移除关键帧
/// @param keyframe  关键帧Slot
- (void)removeKeyframe:(NLETrackSlot_OC *)keyframe;

/// 清除关键帧
- (void)clearKeyframes;
@end

NS_ASSUME_NONNULL_END
