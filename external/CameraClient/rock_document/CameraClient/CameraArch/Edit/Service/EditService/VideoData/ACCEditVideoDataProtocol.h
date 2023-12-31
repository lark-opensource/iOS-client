//
//  ACCEditVideoDataProtocol.h
//  CameraClient
//
//  Created by raomengyun on 2021/4/11.
//

#ifndef ACCEditVideoDataProtocol_h
#define ACCEditVideoDataProtocol_h

#import <AVFoundation/AVFoundation.h>
#import <TTVideoEditor/IESMMVideoDataClipRange.h>
#import <TTVideoEditor/IESMMAudioFilter.h>
#import <TTVideoEditor/IESDurationInfo.h>
#import <TTVideoEditor/IESMMTranscoderParam.h>
#import <TTVideoEditor/IESMMVideoTransformInfo.h>
#import <TTVideoEditor/IESMMCanvasConfig.h>
#import <TTVideoEditor/IESMMCanvasSource.h>
#import <TTVideoEditor/IESMediaInfo.h>
#import <TTVideoEditor/IESMMEffectStickerInfo.h>
#import <CoreMedia/CMTimeRange.h>

typedef NS_ENUM(NSUInteger, AWEAIVideoClipInfoResolveType) {
    AWEAIVideoClipInfoResolveTypeNone,
    AWEAIVideoClipInfoResolveTypeRandom,
    AWEAIVideoClipInfoResolveTypeAI,
};

typedef NS_ENUM(NSUInteger, ACCMVAudioType) {
    ACCMVAudioTypeNormal,
    ACCMVAudioTypeEffectMusic,
    ACCMVAudioTypeAudioBeatTracking,
};

@protocol ACCEditVideoDataProtocol;
typedef NSObject<ACCEditVideoDataProtocol> ACCEditVideoData;

/// Resouce Data Logic of video edit
@protocol ACCEditVideoDataProtocol <NSObject, NSCopying>

/// unique identifier
@property (nonatomic, copy, nullable) NSString *identifier;

/// whether write metadata for video, default is NO
@property (nonatomic, assign) BOOL disableMetadataInfo;

/// seconds of total video duration
@property (nonatomic, assign, readonly) CGFloat totalVideoDuration;
@property (nonatomic, assign, readonly) NSTimeInterval currentTotalDuration;
@property (nonatomic, assign, readonly) NSTimeInterval totalDurationWithTimeMachine;

@property (nonatomic, assign) BOOL isFastImport;
@property (nonatomic, assign) BOOL isRecordFromCamera;
@property (nonatomic, assign) BOOL isMicMuted;
@property (nonatomic, copy) NSDictionary<AVAsset *, NSNumber *> *_Nonnull movieInputFillType;
- (void)updateMovieInputFillTypeWithType:(NSNumber *)type asset:(AVAsset *)asset;
@property (nonatomic, assign) CGFloat maxTrackDuration;
@property (nullable, nonatomic, copy) NSDictionary *dataInfo;

@property (nonatomic, assign) CGAffineTransform importTransform;
@property (nonatomic, copy) NSDictionary * _Nullable metaRecordInfo;

@property (nonatomic, assign, readonly) BOOL isHDR;

/// seconds of total video duration after apply time machine effect
@property (nonatomic, assign, readonly) CGFloat totalVideoDurationAddTimeMachine;

@property (nonatomic, strong) IESMMTranscoderParam * _Nonnull transParam;

@property (nonatomic, copy) NSDictionary<AVAsset *, IESMMCurveSource *> *_Nonnull videoCurves;
- (void)updateVideoCurvesWithCurveSource:(IESMMCurveSource *)curveSource asset:(AVAsset *)asset;

#pragma mark - Video and Audio Assets

@property (nonatomic, strong) AVAsset * _Nullable videoHeader;
@property (nonatomic, copy) NSArray<AVAsset *> * _Nonnull videoAssets;
// video in video
@property (nonatomic, copy) NSArray<AVAsset *> * _Nonnull subTrackVideoAssets;
@property (nonatomic, assign) int32_t previewFrameRate;

/// video rate, NSNumber(CGFloat)
@property (nonatomic, copy) NSDictionary<AVAsset *, NSNumber *> *_Nonnull videoTimeScaleInfo;
- (void)updateVideoTimeScaleInfoWithScale:(NSNumber *)scale asset:(AVAsset *)asset;

@property (nonatomic, copy) NSArray<AVAsset *> *_Nonnull audioAssets;
@property (nonatomic, copy) NSArray<AVAsset *> *_Nonnull bgAudioAssets;
@property (nonatomic, assign) CGFloat totalBGAudioDuration;

@property (nonatomic, assign) BOOL isDetectMode;
/// whether record audio
@property (nonatomic, assign, readonly) BOOL hasRecordAudio;

@property (nonatomic, copy) NSDictionary<AVAsset *, NSArray<IESMMAudioFilter *> *> *_Nonnull audioSoundFilterInfo;
- (void)updateSoundFilterInfoWithFilters:(NSArray<IESMMAudioFilter *> *)filters asset:(AVAsset *)asset;
- (void)removeSoundFilterWithFilter:(IESMMAudioFilter *)filter asset:(AVAsset *)asset;

@property (nonatomic, copy) NSDictionary<AVAsset *, NSArray<IESMMAudioFilter *> *> *_Nonnull videoSoundFilterInfo;
- (void)updateVideoSoundFilterInfoWithFilters:(NSArray<IESMMAudioFilter *> *)filters asset:(AVAsset *)asset;
- (void)removeVideoSoundFilterWithFilter:(IESMMAudioFilter *)filter asset:(AVAsset *)asset;

@property (nonatomic, assign, readonly) BOOL videoAssetsAllHaveAudioTrack;
@property (nonatomic, assign, readonly) BOOL videoAssetsAllMuted;

@property (nonatomic, strong) NSString *_Nullable musicID;

@property (nonatomic, copy) NSDictionary<AVAsset *, NSNumber *> *_Nonnull assetRotationsInfo;
- (void)updateAssetRotationsInfoWithRotateType:(NSNumber *)rotateType asset:(AVAsset *)asset;

@property (nonatomic, copy) NSDictionary<AVAsset *, IESMMVideoTransformInfo *> *_Nonnull assetTransformInfo;
- (void)updateAssetTransformInfoWithTransformInfo:(IESMMVideoTransformInfo *)transformInfo asset:(AVAsset *)asset;

@property (nonatomic, strong, nullable) AVAsset *endingWaterMarkAudio;

/// volumn info of video or audio
@property (nonatomic, copy) NSDictionary<AVAsset *, NSArray<NSNumber *> *> *_Nonnull volumnInfo;
- (void)updateVolumeInfoWithVolumes:(NSArray<NSNumber *> *)volumes asset:(AVAsset *)asset;

/// relation between Bingo assets and videokeys
@property (nonatomic, copy) NSDictionary *_Nullable bingoVideoKeys;

// get video play rate
- (CGFloat)videoRateForAsset:(AVAsset *_Nonnull)asset;

/**
*  change audio asset volumn
*  @param volume 0 ~ 1.0
*/
- (void)setVolumeForAudio:(float)volume;

/**
*  change video asset volumn
*  @param volume 0 ~ 1.0
*/
- (void)setVolumeForVideo:(float)volume;

// volumn for video or audio asset
- (NSArray<NSNumber *> * _Nullable)volumeForAsset:(AVAsset *_Nonnull)asset;

/// get audio time clip info
- (CMTimeRange)audioTimeClipRangeForAsset:(AVAsset *_Nonnull)asset;

/// audio asset operations
- (void)addAudioWithAsset:(AVAsset *_Nonnull)asset;
- (void)addAudioWithAssets:(NSArray<AVAsset *> *)asset;
- (void)removeAudioWithAssets:(NSArray<AVAsset *> *)asset;
- (void)removeAudioAsset:(AVAsset *_Nonnull)asset;
- (void)removeAllAudioAsset;
- (void)acc_addAudioAssetDict:(AVAsset *)asset
                fromVideoData:(ACCEditVideoData *)videoData;
/// video asset operations
- (AVAsset *)addVideoWithAsset:(AVAsset *)asset;
// 增加附轨道
- (AVAsset *)addSubTrackWithAsset:(AVAsset * _Nonnull)asset;


- (void)moveVideoAssetFromIndex:(NSInteger)fromIndex
                        toIndex:(NSInteger)toIndex;
- (void)acc_addVideoAssetDict:(AVAsset *)asset
                fromVideoData:(ACCEditVideoData *)videoData;
- (void)acc_replaceVideoAssetAtIndex:(NSInteger)index
                           withAsset:(AVAsset *)asset
                       fromVideoData:(ACCEditVideoData *)videoData;
- (void)acc_replaceVideoAssetsInRange:(NSRange)range
                           withAssets:(NSArray<AVAsset *> *)assets
                        fromVideoData:(ACCEditVideoData *)videoData;
- (AVAsset *)acc_videoAssetAtIndex:(NSUInteger)index;

- (void)removeAllVideoAsset;
- (void)removeVideoAsset:(AVAsset *_Nonnull)asset;
- (void)setMetaData:(AVAsset *_Nonnull)asset
         recordInfo:(IESMetaRecordInfo)recordInfo
                MD5:(nullable NSString *)MD5
          needStore:(BOOL)needStore;

- (CMTime)getVideoDuration:(AVAsset *_Nonnull)asset;

#pragma mark - Clip Info

/// video clip info
@property (nonatomic, copy) NSDictionary<AVAsset *, IESMMVideoDataClipRange *> *_Nonnull videoTimeClipInfo;
- (void)updateVideoTimeClipInfoWithClipRange:(IESMMVideoDataClipRange *)range asset:(AVAsset *)asset;
- (CMTimeRange)videoTimeClipRangeForAsset:(AVAsset *_Nonnull)asset;

/// audio clip info
@property (nonatomic, copy) NSDictionary<AVAsset *, IESMMVideoDataClipRange *> *_Nonnull audioTimeClipInfo;

- (void)addAudioTimeClipInfos:(NSDictionary<AVAsset *, IESMMVideoDataClipRange *> *)infos;
- (void)updateAudioTimeClipInfoWithClipRange:(IESMMVideoDataClipRange *)clipRange asset:(AVAsset *)asset;
- (void)removeAudioTimeClipInfoWithAsset:(AVAsset *)asset;

@property (nonatomic, assign) AWEAIVideoClipInfoResolveType studio_videoClipResolveType;

/// save metadata
- (void)setMetaData:(AVAsset *_Nonnull)asset recordInfo:(IESMetaRecordInfo)recordInfo;

#pragma mark - CrossPlatform

@property (nonatomic, assign) BOOL notSupportCrossplat;
@property (nonatomic, assign) BOOL crossplatCompile;
@property (nonatomic, assign, readwrite) BOOL crossplatInput;

#pragma mark - Canvas

// 是否用effect的视频动画接口来绘制画布，默认是YES，有些业务effect没有打包视频动画能力，需要设置成NO
@property (nonatomic, assign) BOOL enableVideoAnimation;

@property (nonatomic, copy) NSDictionary<AVAsset *, IESMMCanvasSource *> *_Nonnull canvasInfo;
- (void)updateCanvasInfoWithCanvasSource:(IESMMCanvasSource *)canvasSource asset:(AVAsset *)asset;

@property (nonatomic, copy) NSDictionary<AVAsset *, IESMMCanvasConfig *> *_Nonnull canvasConfigsMap;
- (void)updateCanvasConfigsMapWithConfig:(IESMMCanvasConfig *)config asset:(AVAsset *)asset;
@property (nonatomic, strong, nullable) IESMMCanvasConfig * preferCanvasConfig;

@property (nonatomic, assign) CGSize canvasSize;
/// Convert Universal size to absolute size, used for draft migrate
@property (nonatomic, assign) CGSize normalizeSize;
@property (nonatomic, assign) VEContentSource contentSource;

/// video transition animation
@property (nonatomic, copy) NSDictionary<AVAsset *, IESMediaFilterInfo *> *_Nonnull movieAnimationType;
- (void)updateMovieAnimationTypeWithFilter:(IESMediaFilterInfo *)filter asset:(AVAsset *)asset;

#pragma mark - Filter

@property (nonatomic, copy, nullable) IESMMEffectStickerInfo * _Nullable (^effectFilterPathBlock)(NSString *_Nullable effectPathId, IESEffectFilterType effectType);

// effectOperationManager/timeMachine
@property (nonatomic, assign) HTSPlayerTimeMachineType effect_timeMachineType;
@property (nonatomic, strong, nullable) AVAsset *effect_reverseAsset;
@property (nonatomic, copy, readonly, nullable) NSArray<IESMMEffectTimeRange *> *effect_timeRange;
@property (nonatomic, copy, nullable) NSArray<IESMMEffectTimeRange *> * effect_operationTimeRange;
@property (nonatomic, assign) CGFloat effect_timeMachineBeginTime;
@property (nonatomic, assign) CGFloat effect_newTimeMachineDuration;
@property (nonatomic, assign, readonly) CGFloat effect_videoDuration;
@property (nonatomic, copy, readonly, nullable) NSDictionary *effect_dictionary;

- (void)removeAllPitchAudioFilters;

- (void)clearAllEffectAndTimeMachine;

- (void)clearReverseAsset;

- (void)effect_cleanOperation;
- (void)effect_reCalculateEffectiveTimeRange;
- (CGFloat)effect_currentTimeMachineDurationWithType:(HTSPlayerTimeMachineType)timeMachineType;

#pragma mark - Extra Info

@property (nonatomic, copy) NSDictionary<NSString *, id<NSCoding>> *_Nonnull extraInfo;
// will write to 'com.apple.quicktime.information(AVMetadataQuickTimeMetadataKeyInformation)'
@property (nonatomic, strong) NSString *_Nullable extraMetaInfo;

@property (nonatomic, copy, readonly) NSString *getReverseVideoDataMD5;

#pragma mark - Photo Video

@property (nonatomic, copy) NSDictionary<AVAsset *, NSURL *> *_Nonnull photoAssetsInfo;
- (void)updatePhotoAssetInfoWithURL:(NSURL *)url asset:(AVAsset *)asset;
- (void)updatePhotoAssetsImageInfoWithImage:(UIImage *)image asset:(AVAsset *)asset;

/// Photo Video Assets
@property (nonatomic, copy) NSArray<AVAsset *> *_Nonnull photoMovieAssets;

// whether is new photo video
@property (nonatomic, assign, readonly) BOOL isNewImageMovie;

//新照片电影
@property (nonatomic, strong) IESMMImageMovieInfo * _Nullable imageMovieInfo;

// New Photo Video, edit based on UIImage object
- (void)setImageMovieInfoWithUIImages:(NSArray<UIImage *> *)images
                    imageShowDuration:(NSDictionary<NSString *, IESMMVideoDataClipRange *> *)imageShowDuration;

#pragma mark - Stickers

/// Info Sticker
@property (nonatomic, copy, nullable) NSArray<IESInfoSticker *> *infoStickers;
/// info sticker edge data
@property (nonatomic, strong, nullable) IESVideoAddEdgeData *infoStickerAddEdgeData;

- (void)setSticker:(NSInteger)stickerId
           offsetX:(CGFloat)offsetX
           offsetY:(CGFloat)offsetY;

#pragma mark - Audio Mute

- (void)awe_muteOriginalAudio;
- (void)awe_setMutedWithAsset:(AVAsset *_Nonnull)asset;
- (void)muteMicrophone:(BOOL)enable;

#pragma mark - Video Compare

- (void)acc_convertCanvasSizeFromSize:(CGSize)fromSize toSize:(CGSize)toSize;
- (void)acc_getRestoreVideoDurationWithSegmentCompletion:(void(^)(CMTime segmentDuration))segmentCompletion;
- (IESMMVideoDataClipRange *)acc_safeAudioTimeClipInfo:(AVAsset *)asset;
- (Float64)acc_totalVideoDuration;
- (BOOL)acc_audioAssetEqualTo:(ACCEditVideoData *)anotherVideoData;
- (BOOL)acc_videoAssetEqualTo:(ACCEditVideoData *)anotherVideoData;

#pragma mark - DraftFolder

@property (nonatomic, copy) NSString *draftFolder;

#pragma mark - CacheDirPath
@property (nonatomic, copy, readonly) NSString *cacheDirPath;

#pragma mark - Prepare

// prepare to edit
- (void)prepareWithCompletion:(void (^)(void))completion;

@end

#endif /* ACCEditVideoDataProtocol_h */
