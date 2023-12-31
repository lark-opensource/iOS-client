//
//  DVEMediaContext+SlotUtils.h
//  DVETrackKit
//
//  Created by bytedance on 2021/9/17.
//

#import "DVEMediaContext.h"

NS_ASSUME_NONNULL_BEGIN

@class NLETrackSlot_OC;

@interface DVEMediaContext (SlotUtils)

// 主轨-副轨
- (NLETrackSlot_OC * _Nullable)currentMainVideoSlot;

// 主轨-副轨-音轨
- (NLETrackSlot_OC * _Nullable)currentMainVideoSlotWithAudio;

// 音轨-主轨-副轨
- (NLETrackSlot_OC * _Nullable)currentMainVideoSlotWithAudioFirst;

// 主轨-副轨-当前时刻对应的主轨
- (NLETrackSlot_OC * _Nullable)currentMainVideoSlotWithTimelineMapping;

// 副轨-主轨
- (NLETrackSlot_OC * _Nullable)currentBlendVideoSlot;

// 副轨-主轨-滤镜轨
- (NLETrackSlot_OC * _Nullable)currentBlendVideoSlotWithFilter;

- (BOOL)isMainTrack:(NLETrackSlot_OC *)slot;

@end

NS_ASSUME_NONNULL_END
