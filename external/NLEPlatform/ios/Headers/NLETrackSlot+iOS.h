//
//  NLETrackSlot+iOS.h
//  NLEPlatform
//
//  Created by bytedance on 2020/12/7.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import "NLESegment+iOS.h"
#import "NLESegmentAudio+iOS.h"
#import "NLESegmentEffect+iOS.h"
#import "NLESegmentFilter+iOS.h"
#import "NLESegmentPlay+iOS.h"
#import "NLESegmentSticker+iOS.h"
#import "NLESegmentImageSticker+iOS.h"
#import "NLESegmentTextSticker+iOS.h"
#import "NLESegmentTransition+iOS.h"
#import "NLESegmentVideo+iOS.h"
#import "NLESegmentImage+iOS.h"
#import "NLETimeSpaceNodeGroup+iOS.h"
#import "NLEVideoAnimation+iOS.h"
#import "NLEFilter+iOS.h"
#import "NLEEffect+iOS.h"
#import "NLEMask+iOS.h"
#import "NLEChromaChannel+iOS.h"
#import "NLESegmentTextTemplate+iOS.h"

NS_ASSUME_NONNULL_BEGIN

// 默认关键帧左右覆盖时间范围
FOUNDATION_EXTERN NSInteger const NLEKeyframeRange;

@interface NLETrackSlot_OC : NLETimeSpaceNode_OC

/// 主片段（Slot时长会基于主片段的时长进行计算）
/// 音频 NLESegmentAudio
/// 视频 NLESegmentVideo
/// 图片 NLESegmentImage
/// 贴纸 NLESegmentSticker
/// 滤镜 NLESegmentFilter（全局滤镜）
/// 特效 NLESegmentEffect
/// 时间特效 NLESegmentTimeEffect
/// 文字模板 NLESegmentTextTemplate
@property (nonatomic, strong) NLESegment_OC* segment;

/// PIN功能就是贴纸跟手跟脸效果，双端PIN功能是VE+Effect支持的，需要传递PIN算法文件
@property (nonatomic, strong, nullable) NLEResourceNode_OC* pinAlgorithmFile;

/// 转场，只能有一个，而且必须放在尾部
@property (nonatomic, strong, nullable) NLESegmentTransition_OC* endTransition;

- (nullable NLEFilter_OC *)getFilterByName:(NSString*) filterName;

- (NLEFilter_OC *)removeFilterByName:(NSString*) filterName;

- (void)setSegmentAudio:(NLESegmentAudio_OC*)segment;

- (void)setSegmentEffect:(NLESegmentEffect_OC*)segment;

- (void)setSegmentPlay:(NLESegmentPlay_OC*)segment;

- (void)setSegmentSticker:(NLESegmentSticker_OC*)segment;

- (void)setSegmentImageSticker:(NLESegmentImageSticker_OC*)segment;

- (void)setSegmentText:(NLESegmentTextSticker_OC*)segment;

- (void)setSegmentTransiton:(NLESegmentTransition_OC*)segment;

- (void)setSegmentVideo:(NLESegmentVideo_OC*)segment;

- (void)setSegmentTextTemplate:(NLESegmentTextTemplate_OC*)segment;

- (void)setSegmentImage:(NLESegmentImage_OC*)segment;

/// 滤镜
- (NSMutableArray<NLEFilter_OC*>*)getFilter;

- (void)addFilter:(NLEFilter_OC *)filter;

- (void)clearFilter;

- (void)removeFilter:(NLEFilter_OC *)filter;

/// 特效
- (NSMutableArray<NLEEffect_OC*>*)getEffect;

- (void)addEffect:(NLEEffect_OC *)filter;

- (void)clearEffect;

- (void)removeEffect:(NLEEffect_OC *)filter;

/// 视频动画
- (NSMutableArray<NLEVideoAnimation_OC*>*)getVideoAnims;

- (void)addVideoAnim:(NLEVideoAnimation_OC *)videoAnim;

- (void)clearVideoAnim;

- (void)removeVideoAnim:(NLEVideoAnimation_OC *)videoAnim;

/// 蒙板
- (NSMutableArray<NLEMask_OC*>*)getMask;

- (void)addMask:(NLEMask_OC *)mask;

- (void)clearMask;

- (void)removeMask:(NLEMask_OC *)mask;

/// 色度通道/色度抠图
- (NSMutableArray<NLEChromaChannel_OC*>*)GetChormaChannel;

- (void)addChormaChannel:(NLEChromaChannel_OC *)chormaChannel;

- (void)clearChormaChannel;

- (void)removeChormaChannel:(NLEChromaChannel_OC *)chormaChannel;


/// 变声
- (void)setAudioFilter:(NLEFilter_OC* __nullable)filter;

- (NLEFilter_OC*)audioFilter;

- (void)clearAudioFilter;

/// 关键帧
/// 获取所有关键帧（无序）
- (NSMutableArray<NLETrackSlot_OC*>*)getKeyframe;

/// 获取所有关键帧（按时间点排序）
- (NSMutableArray<NLETrackSlot_OC*>*)getSortKeyframe;

/// 添加关键帧
/// @param keyframe 关键帧
- (void)addKeyframe:(NLETrackSlot_OC *)keyframe;

/// 清除所有关键帧
- (void)clearKeyframe;

/// 移除关键帧
/// @param keyframe 关键帧
- (void)removeKeyframe:(NLETrackSlot_OC *)keyframe;

///设置StartTime并调整关键帧位置
/// @param startTime  开始时间
- (void)setStartTimeAndAdjustKeyframe:(CMTime)startTime;

///设置EndTime并移除超出范围的关键帧
/// @param endTime 结束时间
- (void)setEndTimeAndAdjustKeyframe:(CMTime)endTime;

///设置Slot中的VideoSegment/AudioSegment的Speed并调整关键帧位置
/// @param speed  速度
- (void)setSpeedAndAdjustKeyframe:(float)speed;

///设置Slot中的VideoSegment/AudioSegment的AbsSpeed并调整关键帧位置
/// @param absSpeed  绝对速度
- (void)setAbsSpeedAndAdjustKeyframe:(float)absSpeed;

///设置Slot中的VideoSegment/AudioSegment的SegCurveSpeedPoint并调整关键帧位置
/// @param points 曲线变速点
- (void)setSegCurveSpeedPointAndAdjustKeyframe:(NSArray<NSValue *> *)points;

///设置Slot中的VideoSegment/AudioSegment的倒放并调整关键帧位置
/// @param rewind 倒放
- (void)setRewindAndAdjustKeyframe:(bool)rewind;

///对当前Slot拷贝一份适合作为关键帧数据的Keyframe对象
-(NLETrackSlot_OC*)createKeyframe;

@end


NS_ASSUME_NONNULL_END
