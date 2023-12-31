//
//  NLETrackSlot_OC+Extension.h
//  CameraClient-Pods-Aweme
//
//  Created by geekxing on 2021/1/19.
//

#import <NLEPlatform/NLETrackSlot+iOS.h>
#import <AVFoundation/AVFoundation.h>

@class NLESegmentSubtitleSticker_OC,
NLESegmentInfoSticker_OC,
NLESegmentMV_OC,
NLESegmentTimeEffect_OC,
NLEInterface_OC,
NLEModel_OC;

@class IESMMVideoDataClipRange,
IESMMVideoTransformInfo,
IESMMAudioBeatTracking,
IESMMCanvasConfig,
IESMMCanvasSource,
IESMediaFilterInfo,
IESMMMVResource,
IESInfoSticker,
IESMMEffectTimeRange;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT CMTime ACCCMTimeMakeSeconds(float seconds);
FOUNDATION_EXPORT const CGFloat kACCMVDefaultSecond;

@interface NLETrackSlot_OC (Extension)

+ (instancetype)videoTrackSlotWithAsset:(AVAsset *)asset nle:(NLEInterface_OC *)nle;
+ (instancetype)audioTrackSlotWithAsset:(AVAsset *)asset nle:(NLEInterface_OC *)nle;
+ (instancetype)videoTrackSlotWithPictureURL:(NSURL *)pictureURL nle:(NLEInterface_OC *)nle;
+ (instancetype)videoTrackSlotWithPictureURL:(NSURL *)pictureURL duration:(CGFloat)duration nle:(NLEInterface_OC *)nle;

- (BOOL)isRelatedWithVideoAsset:(AVAsset *)asset;
- (BOOL)isRelatedWithAudioAsset:(AVAsset *)asset;

- (void)resetAudioClipRange;
- (void)resetVideoClipRange;

@property (nonatomic, strong) IESMMVideoDataClipRange *audioClipRange;
@property (nonatomic, strong) IESMMVideoDataClipRange *videoClipRange;

// 视频内部动画
@property (nonatomic, strong, nullable) IESMMVideoTransformInfo *videoTransform;
// 视频转场动画
@property (nonatomic, strong, nullable) IESMediaFilterInfo *videoTransition;

@property (nonatomic, strong, readonly, nullable) NLESegmentVideo_OC *videoSegment;
@property (nonatomic, strong, readonly, nullable) NLESegmentAudio_OC *audioSegment;

#pragma mark - Clip

@property (nonatomic, copy, nullable) NSNumber *movieInputFillType;
@property (nonatomic, copy, nullable) NSNumber *assetRotationInfo;
@property (nonatomic, copy, nullable) NSString *bingoKey;

#pragma mark - Canvas

// 画布配置
@property (nonatomic, strong, readonly, nullable) IESMMCanvasConfig *canvasConfig;
- (void)setCanvasConfig:(nullable IESMMCanvasConfig *)canvasConfig draftFolder:(NSString *)draftFolder;

@property (nonatomic, strong, nullable) IESMMCanvasSource *canvasSource;

#pragma mark - Sticker

/// 根据 VE 数据结构恢复贴纸
+ (nullable instancetype)stickerTrackSlotWithSticker:(IESInfoSticker *)sticker
                                         draftFolder:(NSString *)draftFolder;
/// 自动字幕贴纸
+ (instancetype)captionStickerTrackSlot;
/// 文字贴纸
+ (instancetype)textStickerTrackSlot;
/// 歌词贴纸
+ (instancetype)lyricsStickerWithResoucePath:(NSString *)resoucePath
                                  effectInfo:(nullable NSArray *)effectInfo
                                    userInfo:(nullable NSDictionary *)userInfo
                                 draftFolder:(NSString *)draftFolder;
/// 图片贴纸
+ (instancetype)imageStickerWithResoucePath:(NSString *)resoucePath
                                 effectInfo:(nullable NSArray *)effectInfo
                                   userInfo:(nullable NSDictionary *)userInfo
                                draftFolder:(NSString *)draftFolder;
/// 信息化贴纸
+ (instancetype)infoStickerWithResoucePath:(NSString *)resoucePath
                                effectInfo:(nullable NSArray *)effectInfo
                                  userInfo:(nullable NSDictionary *)userInfo
                               draftFolder:(NSString *)draftFolder;

@property (nonatomic, strong, readonly, nullable) NLESegmentSticker_OC *sticker;
@property (nonatomic, strong, readonly, nullable) NLESegmentInfoSticker_OC *infoSticker;
@property (nonatomic, strong, readonly, nullable) NLESegmentImageSticker_OC *imageSticker;
@property (nonatomic, strong, readonly, nullable) NLESegmentSubtitleSticker_OC *lyricSticker;
@property (nonatomic, strong, readonly, nullable) NLESegmentSubtitleSticker_OC *captionSticker;
@property (nonatomic, strong, readonly, nullable) NLESegmentTextSticker_OC *textSticker;
@property (nonatomic, strong, readonly, nullable) NLESegmentTimeEffect_OC *timeEffect;

// 设置贴纸坐标
- (void)setStickerOffset:(CGPoint)offset normalizeConverter:(CGPoint(^)(CGPoint))normalizeConverter;

// 设置置顶
- (void)setStickerAboveWithNLEModel:(NLEModel_OC *)nleModel;

// 设置歌词字符串
- (void)setSrtString:(NSString *)srtString draftFolder:(NSString *)draftFolder;

// 设置歌词贴纸颜色
- (void)setSrtColorWithR:(CGFloat)r g:(CGFloat)g b:(CGFloat)b a:(CGFloat)a;
- (UIColor *)getSrtColor;

// 设置贴纸动画
- (NSInteger)setStickerAnimationType:(NSInteger)animationType
                            filePath:(NSString *)filePath
                         draftFolder:(NSString *)draftFolder
                            duration:(CGFloat)duration;

// 设置文字贴纸信息
- (void)setTextStickerTextParams:(NSString *)textParams;

#pragma mark - MV

+ (instancetype)mvTrackSlotWithResouce:(IESMMMVResource *)resource
                           draftFolder:(NSString *)draftFolder;

+ (instancetype)slotWithBeatsTracking:(IESMMAudioBeatTracking *)beatsTracking
                          draftFolder:(NSString *)draftFolder;

+ (instancetype)mvMusicSlotWithMusicPath:(NSString *)musicPath
                          audioClipRange:(IESMMVideoDataClipRange *)audioClipRange
                             draftFolder:(NSString *)draftFolder;

+ (instancetype)placeHolderAudioSlotForResourceType:(NLEResourceType)resourceType;

@property (nonatomic, strong, readonly, nullable) NLESegmentMV_OC *mv;
@property (nonatomic, strong, readonly, nullable) IESMMMVResource *mvResouce;

@end

NS_ASSUME_NONNULL_END
