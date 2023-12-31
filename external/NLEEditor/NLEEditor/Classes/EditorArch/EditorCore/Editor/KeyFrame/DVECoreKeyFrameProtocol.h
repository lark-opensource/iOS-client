//
//   DVECoreKeyFrameProtocol.h
//   NLEEditor
//
//   Created  by ByteDance on 2021/8/18.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "DVECoreProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DVECoreKeyFrameProtocol <DVECoreProtocol>


/// 添加或更新关键帧
///  函数内部会clone当前time时间点上的“快照”keyframe，当slot的time上已存在关键帧，就会更新该关键帧，否则就插入新关键帧
/// @param slot 被添加到Slot
/// @param time 时间轴绝对时间
/// @param commit 提交NLE
-(NSString*)addOrUpdateKeyFrame:(NLETrackSlot_OC*)slot forTime:(CMTime)time commit:(BOOL)commit;


/// 从指定Slot中拷贝关键帧
/// @param slot 被添加到Slot
-(NLETrackSlot_OC*)cloneKeyframeSlot:(NLETrackSlot_OC*)slot;


/// 移除关键帧
/// @param slot 被移除的Slot
/// @param time 时间轴绝对时间
-(BOOL)removeKeyframe:(NLETrackSlot_OC*)slot forTime:(CMTime)time;


/// 是否存在关键帧
/// @param slot 指定Slot
-(BOOL)hasKeyframe:(NLETrackSlot_OC*)slot;


/// 是否存在关键帧
/// @param slot 指定Slot
/// @param time 时间轴绝对时间
-(BOOL)hasKeyframe:(NLETrackSlot_OC*)slot forTime:(CMTime)time;



/// 获取Slot指定时间戳到关键帧
/// @param slot 指定Slot
/// @param time 时间轴绝对时间
-(NLETrackSlot_OC*)keyframeInSlot:(NLETrackSlot_OC*)slot forTime:(CMTime)time;

@end

NS_ASSUME_NONNULL_END
