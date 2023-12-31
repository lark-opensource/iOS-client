//
//  ACCStickerDataProvider.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/7/31.
//

#ifndef ACCStickerDataProvider_h
#define ACCStickerDataProvider_h

@class AWEInteractionStickerModel, ACCTextStickerView, IESMMVideoDataClipRange, AVAsset, ACCGrootStickerView, ACCGrootStickerModel;

@protocol ACCStickerDataProvider <NSObject>

- (NSValue *)gestureInvalidFrameValue;

@end


@protocol ACCPOIStickerDataProvider <ACCStickerDataProvider>

- (NSString *)currentTaskId;

- (NSString *)poiStickerFolderForDraft;

- (NSString *)poiStickerImagePathForDraft;

- (BOOL)hasInfoStickerAddEdgeData;

- (NSArray<AWEInteractionStickerModel *> *)interactionStickers;

- (NSDictionary *)baseTrackData;

@end

@protocol ACCTextStickerDataProvider <ACCStickerDataProvider>

- (NSString *)textStickerFolderForDraft;

- (NSString *)textStickerImagePathForDraftWithIndex:(NSInteger)index;

- (void)storeTextInfoForAuditWith:(NSString *)imageText imageTextFonts:(NSString *)imageTextFonts imageTextFontEffectIds:(NSString *)imageTextFontEffectIds;

- (void)addTextReadForKey:(NSString *)key asset:(AVAsset *)audioAsset range:(IESMMVideoDataClipRange *)audioRange;

- (void)removeTextReadForKey:(NSString *)key;

- (BOOL)supportTextReading;

- (void)clearTextMode;

- (BOOL)isImageAlbumEdit;

- (void)showTextReaderSoundEffectsSelectionViewController;

@end

@protocol ACCSocialStickerDataProvider <ACCStickerDataProvider>

- (NSString *)socialStickerImagePathForDraftWithIndex:(NSInteger)index;

- (NSArray<AWEInteractionStickerModel *> *)interactionStickers;

@end

@protocol ACCGrootStickerDataProvider <ACCStickerDataProvider>

- (NSString *)grootStickerImagePathForDraftWithIndex:(NSInteger)index;

- (NSArray<AWEInteractionStickerModel *> *)interactionStickers;

- (nullable ACCGrootStickerView *)customGrootStickerView:(nullable ACCGrootStickerModel *)model;
@end

@protocol ACCPollStickerDataProvider <ACCStickerDataProvider>

- (BOOL)isDraftBefore710;

@end

@protocol ACCLiveStickerDataProvider <ACCStickerDataProvider>

- (BOOL)hasLived;
- (BOOL)isKaraokeMode;
- (NSString *)referString;

@end

@protocol ACCEditTagDataProvider

- (NSInteger)picLocation;

@end

#endif /* ACCStickerDataProvider_h */
