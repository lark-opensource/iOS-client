//
//  NLETrack_OC+Extension.h
//  CameraClient-Pods-Aweme
//
//  Created by geekxing on 2021/1/19.
//

#import <NLEPlatform/NLETrack+iOS.h>
#import <AVFoundation/AVFoundation.h>
#import <CameraClient/ACCSmartMovieDefines.h>

@class NLEResourceAV_OC;

NS_ASSUME_NONNULL_BEGIN

@interface NLETrack_OC (Extension)

@property (nonatomic, assign, readonly) BOOL isCutsame;
@property (nonatomic, assign) BOOL isBGMTrack;
@property (nonatomic, assign) BOOL isKaraokeTrack;
@property (nonatomic, assign) BOOL isTextRead;
@property (nonatomic, assign) NSInteger videoClipResolveType;
@property (nonatomic, assign) BOOL isLensHDRTrack;
@property (nonatomic, assign) BOOL isOneKeyHDRTrack;
@property (nonatomic, assign) BOOL isVideoSubTrack;
@property (nonatomic, assign) ACCSmartMovieSceneMode smartMovieVideoMode; // 仅适用于智照场景的轨道标记，使用请注意

/// 抖音特效轨道
@property (nonatomic, assign) BOOL isSpecialEffectTrack;

/// 时间特效轨道
@property (nonatomic, assign) BOOL isTimeEffectTrack;

- (NLETrackSlot_OC * _Nullable)slotOfID:(UInt64)slotId;
- (NLETrackSlot_OC * _Nullable)slotOfName:(NSString*)slotName;
- (void)adjustTargetStartTime;

/// 重新排序 slots 并且更新到当前的 Track 中
/// @param slots 有序的 slots
- (void)updateAndOrderSlots:(NSArray<NLETrackSlot_OC *> *)slots;

- (void)acc_replaceSlot:(NLETrackSlot_OC *)slot atIndex:(NSUInteger)index;

- (void)updateAudioSubType:(NLEResourceType)audioSubType;

@end

NS_ASSUME_NONNULL_END
