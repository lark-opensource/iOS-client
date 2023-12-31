//
//  ACCVEVideoData.m
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/4/26.
//

#import "ACCVEVideoData.h"
#import <TTVideoEditor/HTSVideoData.h>

#import "HTSVideoData+Capability.h"

@implementation ACCVEVideoData
@synthesize draftFolder = _draftFolder;

+ (instancetype)videoDataWithDraftFolder:(NSString *)draftFolder
{
    return [[self alloc] initWithVideoData:[HTSVideoData videoData] draftFolder:draftFolder];
}

+ (instancetype)videoDataWithVideoAsset:(AVAsset *)videoAsset draftFolder:(NSString *)draftFolder
{
    ACCVEVideoData *videoData = [self videoDataWithVideoData:[HTSVideoData videoData] draftFolder:draftFolder];
    [videoData addVideoWithAsset:videoAsset];
    return videoData;
}

+ (instancetype)videoDataWithVideoData:(HTSVideoData *)videoData draftFolder:(NSString *)draftFolder
{
    return [[self alloc] initWithVideoData:videoData draftFolder:draftFolder];
}

- (instancetype)initWithVideoData:(HTSVideoData *)videoData draftFolder:(NSString *)draftFolder
{
    if (videoData == nil) {
        self = nil;
        return self;
    }
    
    self = [super init];
    if (self) {
        _videoData = videoData;
        _draftFolder = [draftFolder copy];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _videoData = [HTSVideoData videoData];
    }
    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    return [[ACCVEVideoData allocWithZone:zone] initWithVideoData:[self.videoData copy] draftFolder:self.draftFolder];
}

- (void)setIdentifier:(NSString *)identifier
{
    self.videoData.identifier = identifier;
}

- (NSString *)identifier
{
    return self.videoData.identifier;
}

- (NSDictionary<AVAsset *,IESMMVideoDataClipRange *> *)audioTimeClipInfo
{
    return [self.videoData.audioTimeClipInfo copy];
}

- (void)setAudioTimeClipInfo:(NSDictionary<AVAsset *,IESMMVideoDataClipRange *> *)audioTimeClipInfo
{
    self.videoData.audioTimeClipInfo = [audioTimeClipInfo mutableCopy];
}

- (void)updateAudioTimeClipInfoWithClipRange:(IESMMVideoDataClipRange *)clipRange asset:(AVAsset *)asset
{
    self.videoData.audioTimeClipInfo[asset] = clipRange;
}

- (void)removeAudioTimeClipInfoWithAsset:(AVAsset *)asset
{
    [self.videoData.audioTimeClipInfo removeObjectForKey:asset];
}

- (void)addAudioTimeClipInfos:(NSDictionary<AVAsset *,IESMMVideoDataClipRange *> *)infos
{
    [self.videoData.audioTimeClipInfo addEntriesFromDictionary:infos];
}

- (IESMMTimeMachine *)timeMachine
{
    return self.videoData.timeMachine;
}

- (CGFloat)totalVideoDuration
{
    return self.videoData.totalVideoDuration;
}

- (NSTimeInterval)currentTotalDuration
{
    return self.videoData.currentTotalDuration;
}

- (NSTimeInterval)totalDurationWithTimeMachine
{
    return self.videoData.totalDurationWithTimeMachine;
}

- (BOOL)isFastImport
{
    return self.videoData.isFastImport;
}

- (void)setIsFastImport:(BOOL)isFastImport
{
    self.videoData.isFastImport = isFastImport;
}

- (BOOL)isRecordFromCamera
{
    return self.videoData.isRecordFromCamera;
}

- (void)setIsRecordFromCamera:(BOOL)isRecordFromCamera
{
    self.videoData.isRecordFromCamera = isRecordFromCamera;
}

- (BOOL)isMicMuted
{
    return self.videoData.isMicMuted;
}

- (void)setIsMicMuted:(BOOL)isMicMuted
{
    [self.videoData muteMicrophone:isMicMuted];
}

- (NSDictionary<AVAsset *,NSNumber *> *)movieInputFillType
{
    return [self.videoData.movieInputFillType copy];
}

- (void)setMovieInputFillType:(NSDictionary<AVAsset *,NSNumber *> *)movieInputFillType
{
    self.videoData.movieInputFillType = [movieInputFillType mutableCopy];
}

- (void)updateMovieInputFillTypeWithType:(NSNumber *)type asset:(AVAsset *)asset
{
    self.videoData.movieInputFillType[asset] = type;
}

- (CGFloat)maxTrackDuration
{
    return self.videoData.maxTrackDuration;
}

- (void)setMaxTrackDuration:(CGFloat)maxTrackDuration
{
    self.videoData.maxTrackDuration = maxTrackDuration;
}

- (NSDictionary *)dataInfo
{
    return self.videoData.dataInfo;
}

- (void)setDataInfo:(NSDictionary *)dataInfo
{
    self.videoData.dataInfo = dataInfo;
}

- (CGAffineTransform)importTransform
{
    return self.videoData.importTransform;
}

- (void)setImportTransform:(CGAffineTransform)importTransform
{
    self.videoData.importTransform = importTransform;
}

- (BOOL)disableMetadataInfo
{
    return self.videoData.disableMetadataInfo;
}

- (void)setDisableMetadataInfo:(BOOL)disableMetadataInfo
{
    self.videoData.disableMetadataInfo = disableMetadataInfo;
}

- (NSDictionary *)metaRecordInfo
{
    return self.videoData.metaRecordInfo;
}

- (void)setMetaRecordInfo:(NSDictionary *)metaRecordInfo
{
    self.videoData.metaRecordInfo = metaRecordInfo;
}

- (BOOL)isHDR
{
    return self.videoData.colorSpaceInfo.transferFunction == VETransferFunctionType_ARIB_STD_B67 || self.videoData.colorSpaceInfo.transferFunction == VETransferFunctionType_SMPTEST2084;
}

- (CGFloat)totalVideoDurationAddTimeMachine
{
    return self.videoData.totalVideoDurationAddTimeMachine;
}

- (IESMMTranscoderParam *)transParam
{
    return self.videoData.transParam;
}

- (void)setTransParam:(IESMMTranscoderParam *)transParam
{
    self.videoData.transParam = transParam;
}

- (NSDictionary<AVAsset *,IESMMCurveSource *> *)videoCurves
{
    return [self.videoData.videoCurves copy];
}

- (void)setVideoCurves:(NSDictionary<AVAsset *,IESMMCurveSource *> *)videoCurves
{
    self.videoData.videoCurves = [videoCurves mutableCopy];
}

- (void)updateVideoCurvesWithCurveSource:(IESMMCurveSource *)curveSource asset:(AVAsset *)asset
{
    self.videoData.videoCurves[asset] = curveSource;
}

- (NSString *)cacheDirPath
{
    return self.videoData.cacheDirectoryPath;
}

#pragma mark - 音视频资源

- (AVAsset *)videoHeader
{
    return self.videoData.videoHeader;
}

- (void)setVideoHeader:(AVAsset *)videoHeader
{
    self.videoData.videoHeader = videoHeader;
}

- (NSArray<AVAsset *> *)videoAssets
{
    return [self.videoData.videoAssets copy];
}

- (void)setVideoAssets:(NSArray<AVAsset *> *)videoAssets
{
    self.videoData.videoAssets = [videoAssets mutableCopy];
}

- (NSArray<AVAsset *> *)subTrackVideoAssets
{
    return [self.videoData.subTrackVideoAssets copy];
}

- (void)setSubTrackVideoAssets:(NSArray<AVAsset *> *)subTrackVideoAssets
{
    self.videoData.subTrackVideoAssets = [subTrackVideoAssets mutableCopy];
}

- (int32_t)previewFrameRate
{
    return self.videoData.previewFrameRate;
}

- (void)setPreviewFrameRate:(int32_t)previewFrameRate
{
    self.videoData.previewFrameRate = previewFrameRate;
}

- (NSDictionary<AVAsset *,NSNumber *> *)videoTimeScaleInfo
{
    return [self.videoData.videoTimeScaleInfo copy];
}

- (void)setVideoTimeScaleInfo:(NSDictionary<AVAsset *,NSNumber *> *)videoTimeScaleInfo
{
    self.videoData.videoTimeScaleInfo = [videoTimeScaleInfo mutableCopy];
}

- (void)updateVideoTimeScaleInfoWithScale:(NSNumber *)scale asset:(AVAsset *)asset {
    self.videoData.videoTimeScaleInfo[asset] = scale;
}

- (NSArray<AVAsset *> *)audioAssets
{
    return [self.videoData.audioAssets copy];
}

- (void)setAudioAssets:(NSArray<AVAsset *> *)audioAssets
{
    self.videoData.audioAssets = audioAssets?[audioAssets mutableCopy]:[@[] mutableCopy];
}

- (NSArray<AVAsset *> *)bgAudioAssets
{
    return [self.videoData.bgAudioAssets copy];
}

- (void)setBgAudioAssets:(NSArray<AVAsset *> *)bgAudioAssets
{
    self.videoData.bgAudioAssets = [bgAudioAssets mutableCopy];
}

- (BOOL)isDetectMode
{
    return self.videoData.isDetectMode;
}

- (void)setIsDetectMode:(BOOL)isDetectMode
{
    self.videoData.isDetectMode = isDetectMode;
}

- (CGFloat)totalBGAudioDuration
{
    return [self.videoData totalBGAudioDuration];
}

- (void)setTotalBGAudioDuration:(CGFloat)totalBGAudioDuration
{
    self.videoData.currentTotalBGAudioDuration = totalBGAudioDuration;
}

- (BOOL)hasRecordAudio
{
    return self.videoData.hasRecordAudio;
}

- (NSDictionary<AVAsset *,NSArray<IESMMAudioFilter *> *> *)audioSoundFilterInfo
{
    return [self.videoData.audioSoundFilterInfo copy];
}

- (void)setAudioSoundFilterInfo:(NSDictionary<AVAsset *,NSArray<IESMMAudioFilter *> *> *)audioSoundFilterInfo
{
    [self.videoData.audioSoundFilterInfo removeAllObjects];
    [audioSoundFilterInfo enumerateKeysAndObjectsUsingBlock:^(AVAsset * _Nonnull key, NSArray<IESMMAudioFilter *> * _Nonnull obj, BOOL * _Nonnull stop) {
        self.videoData.audioSoundFilterInfo[key] = [obj mutableCopy];
    }];
}

- (void)updateSoundFilterInfoWithFilters:(NSArray<IESMMAudioFilter *> *)filters asset:(AVAsset *)asset
{
    self.videoData.audioSoundFilterInfo[asset] = [filters mutableCopy];
}

- (void)removeSoundFilterWithFilter:(IESMMAudioFilter *)filter asset:(AVAsset *)asset
{
    [self.videoData.audioSoundFilterInfo[asset] removeObject:filter];
}

- (NSDictionary<AVAsset *,NSArray<IESMMAudioFilter *> *> *)videoSoundFilterInfo
{
    return self.videoData.videoSoundFilterInfo;
}

- (void)setVideoSoundFilterInfo:(NSDictionary<AVAsset *,NSArray<IESMMAudioFilter *> *> *)videoSoundFilterInfo
{
    [self.videoData.videoSoundFilterInfo removeAllObjects];
    [videoSoundFilterInfo enumerateKeysAndObjectsUsingBlock:^(AVAsset * _Nonnull key, NSArray<IESMMAudioFilter *> * _Nonnull obj, BOOL * _Nonnull stop) {
        self.videoData.videoSoundFilterInfo[key] = [obj mutableCopy];
    }];
}

- (void)updateVideoSoundFilterInfoWithFilters:(NSArray<IESMMAudioFilter *> *)filters asset:(AVAsset *)asset
{
    self.videoData.videoSoundFilterInfo[asset] = [filters mutableCopy];
}

- (void)removeVideoSoundFilterWithFilter:(IESMMAudioFilter *)filter asset:(AVAsset *)asset
{
    [self.videoData.videoSoundFilterInfo[asset] removeObject:filter];
}

- (BOOL)videoAssetsAllHaveAudioTrack
{
    return self.videoData.videoAssetsAllHaveAudioTrack;
}

- (BOOL)videoAssetsAllMuted
{
    return self.videoData.videoAssetsAllMuted;
}

- (NSString *)musicID
{
    return self.videoData.musicID;
}

- (void)setMusicID:(NSString *)musicID
{
    self.videoData.musicID = musicID;
}

- (NSDictionary<AVAsset *,NSNumber *> *)assetRotationsInfo
{
    return [self.videoData.assetRotationsInfo copy];
}

- (void)setAssetRotationsInfo:(NSDictionary<AVAsset *,NSNumber *> *)assetRotationsInfo
{
    self.videoData.assetRotationsInfo = [assetRotationsInfo mutableCopy];
}

- (void)updateAssetRotationsInfoWithRotateType:(NSNumber *)rotateType asset:(AVAsset *)asset
{
    self.videoData.assetRotationsInfo[asset] = rotateType;
}

- (NSDictionary<AVAsset *,IESMMVideoTransformInfo *> *)assetTransformInfo
{
    return [self.videoData.assetTransformInfo copy];
}

- (void)setAssetTransformInfo:(NSDictionary<AVAsset *,IESMMVideoTransformInfo *> *)assetTransformInfo
{
    self.videoData.assetTransformInfo = [assetTransformInfo mutableCopy];
}

- (void)updateAssetTransformInfoWithTransformInfo:(IESMMVideoTransformInfo *)transformInfo asset:(AVAsset *)asset
{
    self.videoData.assetTransformInfo[asset] = transformInfo;
}

- (AVAsset *)endingWaterMarkAudio
{
    return self.videoData.endingWaterMarkAudio;
}

- (void)setEndingWaterMarkAudio:(AVAsset *)endingWaterMarkAudio
{
    self.videoData.endingWaterMarkAudio = endingWaterMarkAudio;
}

- (NSDictionary<AVAsset *,NSArray<NSNumber *> *> *)volumnInfo
{
    return [self.videoData.volumnInfo copy];
}

- (void)setVolumnInfo:(NSDictionary<AVAsset *,NSArray<NSNumber *> *> *)volumnInfo
{
    self.videoData.volumnInfo = [volumnInfo mutableCopy];
}

- (void)updateVolumeInfoWithVolumes:(NSArray<NSNumber *> *)volumes asset:(AVAsset *)asset
{
    self.videoData.volumnInfo[asset] = volumes;
}

- (NSDictionary *)bingoVideoKeys
{
    return [self.videoData.bingoVideoKeys copy];
}

- (void)setBingoVideoKeys:(NSDictionary *)bingoVideoKeys
{
    self.videoData.bingoVideoKeys = [bingoVideoKeys mutableCopy];
}

- (CGFloat)videoRateForAsset:(AVAsset *_Nonnull)asset
{
    return [self.videoData videoRateForAsset:asset];
}

- (void)setVolumeForAudio:(float)volume
{
    [self.videoData setVolumeForAudio:volume];
}

- (void)setVolumeForVideo:(float)volume
{
    [self.videoData setVolumeForVideo:volume];
}

- (NSArray<NSNumber *> * _Nullable)volumeForAsset:(AVAsset *_Nonnull)asset
{
    return [self.videoData volumeForAsset:asset];
}

- (CMTimeRange)audioTimeClipRangeForAsset:(AVAsset *_Nonnull)asset
{
    return [self.videoData audioTimeClipRangeForAsset:asset];
}

- (void)addAudioWithAsset:(AVAsset *_Nonnull)asset
{
    [self.videoData addAudioWithAsset:asset];
}

- (void)addAudioWithAssets:(NSArray<AVAsset *> *)asset {
    [self.videoData addAudioWithAssets:asset];
}

- (void)removeAudioWithAssets:(NSArray<AVAsset *> *)asset {
    [self.videoData.audioAssets removeObjectsInArray:asset];
}

- (AVAsset *)addVideoWithAsset:(AVAsset *)asset
{
    [self.videoData addVideoWithAsset:asset];
    return asset;
}

- (AVAsset *)addSubTrackWithAsset:(AVAsset *)asset
{
    [self.videoData addSubTrackWithAsset:asset];
    return asset;
}

- (void)moveVideoAssetFromIndex:(NSInteger)fromIndex
                        toIndex:(NSInteger)toIndex
{
    [self.videoData moveVideoAssetFromIndex:fromIndex toIndex:toIndex];
}

- (void)removeAudioAsset:(AVAsset *_Nonnull)asset
{
    [self.videoData removeAudioAsset:asset];
}

- (void)removeAllAudioAsset
{
    [self.videoData removeAllAudioAsset];
}

- (void)removeAllVideoAsset
{
    [self.videoData removeAllVideoAsset];
}

- (void)removeVideoAsset:(AVAsset *_Nonnull)asset
{
    [self.videoData removeVideoAsset:asset];
}

- (CMTime)getVideoDuration:(AVAsset *_Nonnull)asset
{
    return [self.videoData getVideoDuration:asset];
}

- (void)setMetaData:(AVAsset * _Nonnull)asset recordInfo:(IESMetaRecordInfo)recordInfo MD5:(nullable NSString *)MD5 needStore:(BOOL)needStore {
    [self.videoData setMetaData:asset recordInfo:recordInfo MD5:MD5 needStore:needStore];
}

#pragma mark - 裁剪

- (NSDictionary<AVAsset *,IESMMVideoDataClipRange *> *)videoTimeClipInfo
{
    return [self.videoData.videoTimeClipInfo copy];
}

- (void)setVideoTimeClipInfo:(NSDictionary<AVAsset *,IESMMVideoDataClipRange *> *)videoTimeClipInfo
{
    self.videoData.videoTimeClipInfo = [videoTimeClipInfo mutableCopy];
}

- (void)updateVideoTimeClipInfoWithClipRange:(IESMMVideoDataClipRange *)range asset:(AVAsset *)asset
{
    self.videoData.videoTimeClipInfo[asset] = range;
}

- (AWEAIVideoClipInfoResolveType)studio_videoClipResolveType
{
    return self.videoData.studio_videoClipResolveType;
}

- (void)setStudio_videoClipResolveType:(AWEAIVideoClipInfoResolveType)studio_videoClipResolveType
{
    self.videoData.studio_videoClipResolveType = studio_videoClipResolveType;
}

- (void)setMetaData:(AVAsset *_Nonnull)asset recordInfo:(IESMetaRecordInfo)recordInfo
{
    [self.videoData setMetaData:asset recordInfo:recordInfo];
}

- (CMTimeRange)videoTimeClipRangeForAsset:(AVAsset *_Nonnull)asset
{
    return [self.videoData videoTimeClipRangeForAsset:asset];
}

#pragma mark - 跨平台

- (BOOL)notSupportCrossplat
{
    return self.videoData.notSupportCrossplat;
}

- (void)setNotSupportCrossplat:(BOOL)notSupportCrossplat
{
    self.videoData.notSupportCrossplat = notSupportCrossplat;
}

- (BOOL)crossplatCompile
{
    return self.videoData.crossplatCompile;
}

- (void)setCrossplatCompile:(BOOL)crossplatCompile
{
    self.videoData.crossplatCompile = crossplatCompile;
}

- (BOOL)crossplatInput
{
    return self.videoData.crossplatInput;
}

- (void)setCrossplatInput:(BOOL)crossplatInput
{
    self.videoData.crossplatInput = crossplatInput;
}

#pragma mark - 画布

- (BOOL)enableVideoAnimation
{
    return self.preferCanvasConfig.enableVideoAnimation;
}

- (void)setEnableVideoAnimation:(BOOL)enableVideoAnimation
{
    IESMMCanvasConfig *config = [[IESMMCanvasConfig alloc] init];
    config.enableVideoAnimation = enableVideoAnimation;
    self.preferCanvasConfig = config;
}

- (void)setPreferCanvasConfig:(IESMMCanvasConfig *)preferCanvasConfig
{
    self.videoData.preferCanvasConfig = preferCanvasConfig;
}

- (IESMMCanvasConfig *)preferCanvasConfig
{
    return self.videoData.preferCanvasConfig;
}

- (NSDictionary<AVAsset *,IESMMCanvasSource *> *)canvasInfo
{
    return [self.videoData.canvasInfo copy];
}

- (void)setCanvasInfo:(NSDictionary<AVAsset *,IESMMCanvasSource *> *)canvasInfo
{
    self.videoData.canvasInfo = [canvasInfo mutableCopy];
}

- (void)updateCanvasInfoWithCanvasSource:(IESMMCanvasSource *)canvasSource asset:(AVAsset *)asset
{
    self.videoData.canvasInfo[asset] = canvasSource;
}

- (NSDictionary<AVAsset *,IESMMCanvasConfig *> *)canvasConfigsMap
{
    return [self.videoData.canvasConfigsMap copy];
}

- (void)setCanvasConfigsMap:(NSDictionary<AVAsset *,IESMMCanvasConfig *> *)canvasConfigsMap
{
    self.videoData.canvasConfigsMap = [canvasConfigsMap mutableCopy];
}

- (void)updateCanvasConfigsMapWithConfig:(IESMMCanvasConfig *)config asset:(AVAsset *)asset
{
    self.videoData.canvasConfigsMap[asset] = config;
}

- (CGSize)canvasSize
{
    return self.videoData.canvasSize;
}

- (void)setCanvasSize:(CGSize)canvasSize
{
    self.videoData.canvasSize = canvasSize;
}

- (CGSize)normalizeSize
{
    return self.videoData.normalizeSize;
}

- (void)setNormalizeSize:(CGSize)normalizeSize
{
    self.videoData.normalizeSize = normalizeSize;
}

- (VEContentSource)contentSource
{
    return self.videoData.contentSource;
}

- (void)setContentSource:(VEContentSource)contentSource
{
    self.videoData.contentSource = contentSource;
}

- (NSDictionary<AVAsset *,IESMediaFilterInfo *> *)movieAnimationType
{
    return [self.videoData.movieAnimationType copy];
}

- (void)setMovieAnimationType:(NSDictionary<AVAsset *,IESMediaFilterInfo *> *)movieAnimationType
{
    self.videoData.movieAnimationType = [movieAnimationType mutableCopy];
}

- (void)updateMovieAnimationTypeWithFilter:(IESMediaFilterInfo *)filter asset:(AVAsset *)asset
{
    self.videoData.movieAnimationType[asset] = filter;
}

#pragma mark - 滤镜

- (IESMMEffectStickerInfo * _Nullable (^)(NSString * _Nullable, IESEffectFilterType))effectFilterPathBlock
{
    return self.videoData.effectFilterPathBlock;
}

- (void)setEffectFilterPathBlock:(IESMMEffectStickerInfo * _Nullable (^)(NSString * _Nullable, IESEffectFilterType))effectFilterPathBlock
{
    self.videoData.effectFilterPathBlock = effectFilterPathBlock;
}

- (void)removeAllPitchAudioFilters
{
    [self.videoData removeAllPitchAudioFilters];
}

- (void)clearAllEffectAndTimeMachine
{
    [self.videoData clearAllEffectAndTimeMachine];
}

- (void)clearReverseAsset
{
    [self.videoData clearReverseAsset];
}

#pragma mark - 额外字段

- (NSDictionary<NSString *,id<NSCoding>> *)extraInfo
{
    return [self.videoData.extraInfo copy];
}

- (void)setExtraInfo:(NSDictionary<NSString *,id<NSCoding>> *)extraInfo
{
    self.videoData.extraInfo = [extraInfo mutableCopy];
}

- (NSString *)extraMetaInfo
{
    return self.videoData.extraMetaInfo;
}

- (void)setExtraMetaInfo:(NSString *)extraMetaInfo
{
    self.videoData.extraMetaInfo = extraMetaInfo;
}

- (NSString *)getReverseVideoDataMD5
{
    return self.videoData.getReverseVideoDataMD5;
}

#pragma mark - 照片电影

- (NSDictionary<AVAsset *,NSURL *> *)photoAssetsInfo
{
    return [self.videoData.photoAssetsInfo copy];
}

- (void)setPhotoAssetsInfo:(NSDictionary<AVAsset *,NSURL *> *)photoAssetsInfo
{
    self.videoData.photoAssetsInfo = [photoAssetsInfo mutableCopy];
}

- (void)updatePhotoAssetInfoWithURL:(NSURL *)url asset:(AVAsset *)asset
{
    self.videoData.photoAssetsInfo[asset] = url;
}

- (void)updatePhotoAssetsImageInfoWithImage:(UIImage *)image asset:(AVAsset *)asset
{
    self.videoData.photoAssetsImageInfo[asset] = image;
}

- (BOOL)isNewImageMovie
{
    return self.videoData.imageMovieInfo != nil;
}

- (IESMMImageMovieInfo *)imageMovieInfo
{
    return self.videoData.imageMovieInfo;
}

- (void)setImageMovieInfo:(IESMMImageMovieInfo *)imageMovieInfo
{
    self.videoData.imageMovieInfo = imageMovieInfo;
}

- (void)setImageMovieInfoWithUIImages:(NSArray<UIImage *> *)images
                    imageShowDuration:(NSDictionary<NSString *,IESMMVideoDataClipRange *> *)imageShowDuration
{
    if (images.count != imageShowDuration.count) {
        return;
    }
    
    IESMMImageMovieInfo *imageMovieInfo = [[IESMMImageMovieInfo alloc] init];
    imageMovieInfo.imageArray = [images mutableCopy];
    imageMovieInfo.imageShowDuration = [imageShowDuration mutableCopy];
    self.videoData.imageMovieInfo = imageMovieInfo;
}

- (NSArray<AVAsset *> *)photoMovieAssets
{
    return [self.videoData.photoMovieAssets copy];
}

- (void)setPhotoMovieAssets:(NSArray<AVAsset *> *)photoMovieAssets
{
    self.videoData.photoMovieAssets = [photoMovieAssets mutableCopy];
}

#pragma mark - 贴纸

- (NSArray<IESInfoSticker *> *)infoStickers
{
    return self.videoData.infoStickers;
}

- (void)setInfoStickers:(NSArray<IESInfoSticker *> *)infoStickers
{
    self.videoData.infoStickers = infoStickers;
}

- (IESVideoAddEdgeData *)infoStickerAddEdgeData
{
    return self.videoData.infoStickerAddEdgeData;
}

- (void)setInfoStickerAddEdgeData:(IESVideoAddEdgeData *)infoStickerAddEdgeData
{
    self.videoData.infoStickerAddEdgeData = infoStickerAddEdgeData;
}

- (void)setSticker:(NSInteger)stickerId
           offsetX:(CGFloat)offsetX
           offsetY:(CGFloat)offsetY
{
    [self.videoData setSticker:stickerId offsetX:offsetX offsetY:offsetY];
}

#pragma mark - 音频静音

- (void)awe_muteOriginalAudio
{
    [self.videoData awe_muteOriginalAudio];
}

- (void)awe_setMutedWithAsset:(AVAsset *)asset
{
    [self.videoData awe_setMutedWithAsset:asset];
}

- (void)muteMicrophone:(BOOL)enable
{
    [self.videoData muteMicrophone:enable];
}

#pragma mark - 音视频比较

- (BOOL)acc_audioAssetEqualTo:(id<ACCEditVideoDataProtocol>)anotherVideoData
{
    return [self.videoData acc_audioAssetEqualTo:anotherVideoData];
}

- (void)acc_convertCanvasSizeFromSize:(CGSize)fromSize toSize:(CGSize)toSize
{
    return [self.videoData acc_convertCanvasSizeFromSize:fromSize toSize:toSize];
}

- (void)acc_getRestoreVideoDurationWithSegmentCompletion:(void(^)(CMTime segmentDuration))segmentCompletion
{
    [self.videoData acc_getRestoreVideoDurationWithSegmentCompletion:segmentCompletion];
}

- (IESMMVideoDataClipRange *)acc_safeAudioTimeClipInfo:(AVAsset *)asset
{
    return [self.videoData acc_safeAudioTimeClipInfo:asset];
}

- (Float64)acc_totalVideoDuration
{
    return [self.videoData acc_totalVideoDuration];
}

- (BOOL)acc_videoAssetEqualTo:(id<ACCEditVideoDataProtocol>)anotherVideoData
{
    return [self.videoData acc_videoAssetEqualTo:anotherVideoData];
}

#pragma mark - effectOperationManager 封装

- (void)acc_addVideoAssetDict:(AVAsset *)asset
                fromVideoData:(ACCEditVideoData *)videoData
{
    [self.videoData acc_addVideoAssetDict:asset fromVideoData:videoData];
}

- (void)acc_addAudioAssetDict:(AVAsset *)asset
                fromVideoData:(ACCEditVideoData *)videoData
{
    [self.videoData acc_addAudioAssetDict:asset fromVideoData:videoData];
}

- (void)acc_replaceVideoAssetAtIndex:(NSInteger)index
                           withAsset:(AVAsset *)asset
                       fromVideoData:(ACCEditVideoData *)videoData
{
    [self.videoData acc_replaceVideoAssetAtIndex:index withAsset:asset fromVideoData:videoData];
}

- (void)acc_replaceVideoAssetsInRange:(NSRange)range
                           withAssets:(NSArray<AVAsset *> *)assets
                        fromVideoData:(ACCEditVideoData *)videoData
{
    [self.videoData acc_replaceVideoAssetsInRange:range withAssets:assets fromVideoData:videoData];
}

#pragma mark - effectOperationManager 封装

- (HTSPlayerTimeMachineType)effect_timeMachineType
{
    return self.videoData.effect_timeMachineType;
}

- (void)setEffect_timeMachineType:(HTSPlayerTimeMachineType)effect_timeMachineType
{
    self.videoData.effect_timeMachineType = effect_timeMachineType;
}

- (AVAsset *)effect_reverseAsset
{
    return self.videoData.effect_reverseAsset;
}

- (void)setEffect_reverseAsset:(AVAsset *)effect_reverseAsset
{
    self.videoData.effect_reverseAsset = effect_reverseAsset;
}

- (NSArray<IESMMEffectTimeRange *> *)effect_timeRange
{
    return [self.videoData.effect_timeRange copy];
}

- (NSArray<IESMMEffectTimeRange *> *)effect_operationTimeRange
{
    return [self.videoData.effect_operationTimeRange copy];
}

- (void)setEffect_operationTimeRange:(NSArray<IESMMEffectTimeRange *> *)effect_operationTimeRange
{
    self.videoData.effect_operationTimeRange = effect_operationTimeRange;
}

- (CGFloat)effect_timeMachineBeginTime
{
    return [self.videoData effect_timeMachineBeginTime];
}

- (void)setEffect_timeMachineBeginTime:(CGFloat)effect_timeMachineBeginTime
{
    self.videoData.effect_timeMachineBeginTime = effect_timeMachineBeginTime;
}

- (CGFloat)effect_newTimeMachineDuration
{
    return [self.videoData effect_newTimeMachineDuration];
}

- (void)setEffect_newTimeMachineDuration:(CGFloat)effect_newTimeMachineDuration
{
    self.videoData.effect_newTimeMachineDuration = effect_newTimeMachineDuration;
}

- (CGFloat)effect_videoDuration
{
    return [self.videoData effect_videoDuration];
}

- (NSDictionary *)effect_dictionary
{
    return [self.videoData effect_dictionary];
}

- (void)effect_cleanOperation
{
    [self.videoData effect_cleanOperation];
}

- (void)effect_reCalculateEffectiveTimeRange
{
    [self.videoData effect_reCalculateEffectiveTimeRange];
}

- (CGFloat)effect_currentTimeMachineDurationWithType:(HTSPlayerTimeMachineType)timeMachineType
{
    return [self.videoData effect_currentTimeMachineDurationWithType:timeMachineType];
}

- (AVAsset *)acc_videoAssetAtIndex:(NSUInteger)index {
    return [self.videoData acc_videoAssetAtIndex:index];
}

#pragma mark - Prepare

- (void)prepareWithCompletion:(void (^)(void))completion
{
    // do nothing
    !completion ?: completion();
}

@end
