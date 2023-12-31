//
//  NLEModel_OC+DVE.h
//  NLEPlatform
//
//  Created by bytedance on 2021/4/10.
//

#import <NLEPlatform/NLEModel+iOS.h>
#import <AVFoundation/AVFoundation.h>
#import "DVETargetIndex.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLEModel_OC (DVE)

- (DVETargetIndex *)dve_targetIndexOfNodeId:(NSString *)nodeId
                                  trackType:(NLETrackType)trackType
                           excludeMainTrack:(BOOL)excludeMainTrack;

- (nullable NLETrack_OC *)dve_getMainVideoTrack;

- (NSArray<NLETrack_OC *> *)dve_allTracksOfType:(NLETrackType)trackType;

- (NSArray<NLETrack_OC *> *)dve_allTracksOfType:(NLETrackType)trackType
                                   resourceType:(NLEResourceType)resourceType;

- (NSArray<NLETrack_OC *> *)dve_allTracksOfType:(NLETrackType)trackType
                                  resourceTypes:(NSArray<NSNumber *> *)resourceTypes;

- (void)dve_addSlotsToMainTrack:(NSArray<NLETrackSlot_OC *> *)slots
                         atTime:(CMTime)time;
- (NSArray<NLETrackSlot_OC *> *)dve_slotsAtTime:(CMTime)time forType:(NLETrackType)type;

- (NLETrack_OC * _Nullable)dve_trackContainSlotId:(NSString *)slotID;

- (NSArray<NLETrackSlot_OC *> *)dve_videoSlotsAtTime:(CMTime)time;

- (void)dve_removeLastEmptyTracksForType:(NLETrackType)trackType;

- (void)dve_removeLastEmptyTracksForType:(NLETrackType)trackType
                            resourceType:(NLEResourceType)resourceType;

// 暂时只能给非主轨使用
- (void)dve_insertSlot:(NLETrackSlot_OC *)slot
 atTargetStartTime:(CMTime)targetStartTime
        trackIndex:(NSInteger)trackIndex
         trackType:(NLETrackType)trackType;

- (NSArray<NLETrack_OC *> *)dve_addEmptyTrackIfNeeded:(NLETrackType)trackType
                                         requireCount:(NSInteger)requireCount;

- (NSArray<NLETrack_OC *> *)dve_addEmptyTrackIfNeeded:(NLETrackType)trackType
                                         requireCount:(NSInteger)requireCount
                                         resourceType:(NLEResourceType)resourceType;

- (NSArray<NLETrackSlot_OC *> *)dve_removeSlots:(NSArray<NSString *> *)ids
                                    inTrackType:(NLETrackType)trackType;

//分割视频动画
- (void)dve_spliteVideoAnimation:(NLETrackSlot_OC *)slot copiedSlot:(NLETrackSlot_OC *)copiedSlot;

- (NSInteger)dve_getMaxEffectLayer;

- (NSInteger)dve_getMaxTrackLayer;

- (NSInteger)dve_getMaxTrackLayer:(NLETrackType)trackType;

- (NSInteger)dve_getMaxSlotLayerWithTrackType:(NLETrackType)trackType;

- (NSInteger)dve_getMaxTrackLayer:(NLETrackType)trackType resourceType:(NLEResourceType)resourceType;

- (NSArray<NLETrackSlot_OC *> *)dve_slotsOfType:(NLETrackType)trackType;

- (NLETrackSlot_OC * _Nullable)dve_slotOf:(NSString *)nodeId;

- (BOOL)dve_hasAudioOrPicInPicSegments;


/// 获取主视频轨道上所有的slot
- (NSArray<NLETrackSlot_OC *> *)dve_getMainVideoTrackSlots;

/// 获取画中画轨道上所有的slot
- (NSArray<NLETrackSlot_OC *> *)dve_getPipTrackSlots;

/// 获取文本贴纸上所有的slot（包括文本贴纸和文字模板）
- (NSArray<NLETrackSlot_OC *> *)dve_getTextTrackSlots;

/// 获取时间time对应主视频轨道上的slot，可能为nil；
/// @param time 时间
- (NLETrackSlot_OC *)dve_getMainVideoSlotAtTime:(CMTime)time;

@end

NS_ASSUME_NONNULL_END
