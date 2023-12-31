//
//  NLEModel_OC+Extension.h
//  CameraClient-Pods-Aweme
//
//  Created by geekxing on 2021/1/19.
//

#import <NLEPlatform/NLEModel+iOS.h>
#import <NLEPlatform/NLETrackMV+iOS.h>

NS_ASSUME_NONNULL_BEGIN

@class IESVideoAddEdgeData, IESMMAudioFilter, IESMMCanvasConfig, AVAsset;
@class NLEInterface_OC;

// 判断 PreviewEdge 是否相等
FOUNDATION_EXPORT BOOL NLEPreviewEdgeEqual(IESVideoAddEdgeData *l, IESVideoAddEdgeData *r);

@interface NLEModel_OC (Extension)

- (NLETrack_OC *)getMainVideoTrack;

- (NLETrack_OC *)getSubVideoTrack;

// Caption Sticker
- (NLETrack_OC *)captionStickerTrack;

// Special Effect
- (NLETrack_OC *)specialEffectTrack;

// Time Effect Track
- (NLETrack_OC *)timeEffectTrack;

// BGAudioAsset track for karaoke
- (NLETrack_OC *)bgAudioAssetTrack;

- (NSArray<NLETrack_OC *> *)tracksWithType:(NLETrackType)type;
- (void)removeTracksWithType:(NLETrackType)type;
- (NSArray<NLETrack_OC *> *)subTracksWithType:(NLETrackType)type;

- (NLETrackSlot_OC *_Nullable)slotOfName:(NSString*)slotId withTrackType:(NLETrackType)trackType;
- (NSArray<NLETrackSlot_OC *>*)removeSlots:(NSArray<NLETrackSlot_OC *> *)slots trackType:(NLETrackType)trackType;
- (NSArray<NLETrackSlot_OC *> *)slotsWithType:(NLETrackType)type;

#pragma mark - Resources

// 获取当前所有的资源
@property (nonatomic, copy, readonly) NSArray<NLEResourceNode_OC *> *acc_allResouces;

/// 将视频以及音频等私有资源移动到草稿目录内，已经在草稿目录内的不做处理，返回资源是否有变化
- (BOOL)acc_moveMainResourceToDraftFolder:(NSString *)draftFolder;

#pragma mark - Assets

- (NLETrackSlot_OC *)videoSlotOfAsset:(AVAsset *)asset nle:(NLEInterface_OC *)nle;

- (NLETrackSlot_OC *)audioSlotOfAsset:(AVAsset *)asset nle:(NLEInterface_OC *)nle;

- (NLETrack_OC *)videoTrackOfAsset:(AVAsset *)asset nle:(NLEInterface_OC *)nle;

- (NLETrack_OC *)audioTrackOfAsset:(AVAsset *)asset nle:(NLEInterface_OC *)nle;

#pragma mark - 音量

@property (nonatomic, copy, readonly, nullable) NSString *bgmURLString;

// 音量接口统一
- (void)acc_setAudioVolumn:(float)volume forTrackCondition:(BOOL (^)(NLETrack_OC *track))trackCondition;
- (void)acc_setVideoVolumn:(float)volume forTrackCondition:(BOOL (^)(NLETrack_OC *track))trackCondition;
- (void)acc_setVideoVolumn:(float)volume forTrackSlotCondition:(BOOL (^)(NLETrackSlot_OC *trackSlot))trackSlotCondition;

#pragma mark - MV

// MV
- (void)replaceMainTrackWithMV:(NLETrackMV_OC *)mvTrack;
- (nullable NLETrackMV_OC *)mvTrack;

#pragma mark - AudioEffect

- (NSArray<NLEFilter_OC *> *)voiceChangerFilters;

- (void)removeAllVoiceChangerFilters;

- (void)removeAllSpecialEffects;

- (void)removeAllAudioFiltersForAudioAsset:(BOOL)isAudioAsset;

- (void)removeAudioFilter:(IESMMAudioFilter *)filter forTrack:(NLETrack_OC *)track;

- (void)setAudioFilter:(IESMMAudioFilter *)audioFilter
              forTrack:(NLETrack_OC *)track
           draftFolder:(NSString *)draftFolder;

- (void)addAudioFilter:(IESMMAudioFilter *)audioFilter
              forTrack:(NLETrack_OC *)track
           draftFolder:(NSString *)draftFolder;

- (void)setAudioFilters:(NSArray<IESMMAudioFilter *> *)audioFilters
               forTrack:(NLETrack_OC *)track
            draftFolder:(NSString *)draftFolder;

@end

#pragma mark - NLEModel_OC+VEConfig

// 以下数据需要客户端自行保存，然后再传递给 VE
@interface NLEModel_OC (VEConfig)

@property (nonatomic, assign) BOOL isFastImport;
@property (nonatomic, assign) BOOL isRecordFromCamera;
@property (nonatomic, assign) BOOL isMicMuted;
@property (nonatomic, copy) NSDictionary *_Nonnull metaRecordInfo;
@property (nonatomic, copy) NSDictionary *_Nonnull dataInfo;
@property (nonatomic, assign) CGSize normalizeSize;
@property (nonatomic, copy, nullable) NSString *identifier;
@property (nonatomic, copy) NSDictionary<NSString *, id<NSCoding>> *_Nonnull extraInfo;
@property (nonatomic, strong, nullable) IESVideoAddEdgeData *infoStickerAddEdgeData;
@property (nonatomic, assign) CGAffineTransform importTransform;
@property (nonatomic, strong, nullable) IESMMCanvasConfig *preferCanvasConfig;

@end

NS_ASSUME_NONNULL_END
