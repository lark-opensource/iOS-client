//
//  NLETrack_OC+DVE.h
//  NLEPlatform
//
//  Created by bytedance on 2021/4/10.
//

#import <NLEPlatform/NLETrack+iOS.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLETrack_OC (DVE)

@property (nonatomic, copy) NSString *dve_trackId;

/// 由于目前只有Sticker轨道，但是编辑区需要区分文本还是贴纸轨道，包括空的，使用这个来表示
@property (nonatomic, assign) NLEResourceType dve_extraResourceType;

- (void)dve_insertSlot:(NLETrackSlot_OC *)targetSlot atTime:(CMTime)targetStartTime;
- (NLETrackSlot_OC * _Nullable)dve_slotOfId:(NSString *)slotId;
- (NLETrackSlot_OC * _Nullable)dve_slotAtTime:(CMTime)time;
- (NSArray<NLETrackSlot_OC *> *)dve_slotsStartTimeAt:(CMTimeRange)timeRange;
- (NSInteger)dve_indexOfSlotId:(NSString *)slotId;
- (CGFloat)dve_maxTransitionTimeForSlot:(NLETrackSlot_OC *)slot;
- (void)dve_rescheduleTrackForTransitionChanged;

@end

NS_ASSUME_NONNULL_END
