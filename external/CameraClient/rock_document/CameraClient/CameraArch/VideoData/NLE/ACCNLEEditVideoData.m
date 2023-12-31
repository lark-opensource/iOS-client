//
//  ACCNLEEditVideoDataWrapper.m
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/4/11.
//

#import "ACCNLEEditVideoData.h"
#import <NLEPlatform/NLEInterface.h>
#import <NLEPlatform/NLEModel+iOS.h>
#import <NLEPlatform/NLESegmentMV+iOS.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/NSDictionary+ACCAdditions.h>
#import <CreativeKit/ACCMacrosTool.h>
#import <CreativeKit/ACCMacros.h>

#import "NLEModel_OC+Extension.h"
#import "NLETrack_OC+Extension.h"
#import "NLEEditor_OC+Extension.h"
#import "NLETrackSlot_OC+Extension.h"
#import "NLEResourceAV_OC+Extension.h"
#import "NLEFilter_OC+Extension.h"
#import "HTSVideoData+Capability.h"
#import "ACCEditVideoDataDowngrading.h"
#import "AWEAssetModel.h"
#import "ACCNLEBundleResource.h"

@interface ACCNLEEditVideoData()<NLERenderHook>

@property (nonatomic, strong) NLEModel_OC *nleModel;
@property (nonatomic, strong) NSMutableSet *updateTypes;

@end
@implementation ACCNLEEditVideoData
@synthesize draftFolder = _draftFolder;
@synthesize nle = _nle;
@synthesize effectFilterPathBlock = _effectFilterPathBlock;

- (instancetype)initWithNLEModel:(NLEModel_OC *)nleModel nle:(nonnull NLEInterface_OC *)nle
{
    self = [super init];
    if (self) {
        _nleModel = nleModel;
        _draftFolder = [nle.draftFolder copy];
        _updateTypes = [NSMutableSet set];
        _effectFilterPathBlock = nle.effectPathBlock;
        
        _nle = nle;
        _nle.renderHook = self;
        _nle.bundleDataSource = _nle.acc_bundleResource;
        
        [self p_syncNLE];
    }
    return self;
}

- (void)setNle:(NLEInterface_OC *)nle
{
    IESMMImageMovieInfo *imageMovie = self.imageMovieInfo;
    
    // 资源 bundle 同步
    [nle acc_appendBundleResourceFrom:_nle];
    // 设置 NLE 以及回调
    _nle = nle;
    [self _setupNLEStatus];
    
    // 有一些数据需要同步过来
    self.imageMovieInfo = imageMovie;
}

- (void)beginEdit
{
    [self.nle.editor setModel:self.nleModel];
    [self _setupNLEStatus];
}

- (void)_setupNLEStatus
{
    // 设置 NLE 以及回调
    self.nle.renderHook = self;
    self.nle.bundleDataSource = self.nle.acc_bundleResource;
}

- (NLEInterface_OC *)nle
{
    NSAssert(_nle, @"nle should not be nil");
    return _nle;
}

- (void)pushUpdateType:(VEVideoDataUpdateType)updateType
{
    [self.updateTypes addObject:@(updateType)];
}

#pragma mark - NLERenderHook

- (NSSet<NSNumber *> *)nleWillBeginRender:(NLEInterface_OC *)interface
{
    if (interface != self.nle) {
        return nil;
    }
    return [self p_syncNLE];
}

- (void)nleDidEndRender:(NLEInterface_OC *)interface
{
    if (interface != self.nle) {
        return;
    }
    [self p_syncVE];
}

// 某些透传给 VE 的数据需要在每次提交的时候重新设置一下，防止数据丢失
- (NSSet<NSNumber *> *)p_syncNLE
{
    // 同步常规配置数据
    self.nle.isFastImport = self.nleModel.isFastImport;
    self.nle.isRecordFromCamera = self.nleModel.isRecordFromCamera;
    self.nle.isMicMuted = self.nleModel.isMicMuted;
    self.nle.metaRecordInfo = self.nleModel.metaRecordInfo;
    self.nle.dataInfo = self.nleModel.dataInfo;
    self.nle.preferCanvasConfig = self.nleModel.preferCanvasConfig;
    self.nle.normalizeSize = self.nleModel.normalizeSize;
    self.nle.identifier = self.nleModel.identifier;
    self.nle.extraInfo = self.nleModel.extraInfo;
    self.nle.importTransform = self.nleModel.importTransform;
    if (self.nleModel.infoStickerAddEdgeData != nil &&
        !NLEPreviewEdgeEqual(self.nleModel.infoStickerAddEdgeData, self.nle.infoStickerAddEdgeData)) {
        self.nle.infoStickerAddEdgeData = self.nleModel.infoStickerAddEdgeData;
    }
    if (self.effectFilterPathBlock != self.nle.effectPathBlock) {
        self.nle.effectPathBlock = self.effectFilterPathBlock;
    }
    
    // 同步部分效果数据
    NSMutableSet<NSNumber *> *updateTypes = [NSMutableSet<NSNumber *> set];
    [[self.nleModel slotsWithType:NLETrackVIDEO] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        if (fabs(obj.assetRotationInfo.floatValue - [self.nle assetRotationInfoOfSlot:obj].floatValue) > 0.01) {
            [self.nle setAssetRotationInfo:obj.assetRotationInfo forSlot:obj];
            [updateTypes addObject:@(VEVideoDataUpdateTimeLine)];
        }
        
        if (fabs(obj.movieInputFillType.floatValue - [self.nle movieFillTypeOfSlot:obj].floatValue) > 0.01) {
            [self.nle setMovieInputFillType:obj.movieInputFillType forSlot:obj];
            [updateTypes addObject:@(VEVideoDataUpdateTimeLine)];
        }
        
        // 无需 diff，无需 updateVideoData
        [self.nle setBingoKey:obj.bingoKey forSlot:obj];
    }];
    
    // 外部更新数据
    [updateTypes addObjectsFromArray:self.updateTypes.allObjects];
    [self.updateTypes removeAllObjects];
    
    return updateTypes.copy;
}

- (void)p_syncVE
{
    self.nleModel.isFastImport = self.nle.isFastImport;
    self.nleModel.isRecordFromCamera = self.nle.isRecordFromCamera;
    self.nleModel.isMicMuted = self.nle.isMicMuted;
    self.nleModel.metaRecordInfo = self.nle.metaRecordInfo;
    self.nleModel.dataInfo = self.nle.dataInfo;
    self.nleModel.preferCanvasConfig = self.nle.preferCanvasConfig;
    self.nleModel.normalizeSize = self.nle.normalizeSize;
    self.nleModel.identifier = self.nle.identifier;
    self.nleModel.extraInfo = self.nle.extraInfo;
    self.nleModel.importTransform = self.nle.importTransform;
    if (!NLEPreviewEdgeEqual(self.nleModel.infoStickerAddEdgeData, self.nle.infoStickerAddEdgeData)) {
        self.nleModel.infoStickerAddEdgeData = self.nle.infoStickerAddEdgeData;
    }
    
    [[self.nleModel slotsWithType:NLETrackVIDEO] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        obj.assetRotationInfo = [self.nle assetRotationInfoOfSlot:obj];
        obj.movieInputFillType = [self.nle movieFillTypeOfSlot:obj];
        obj.bingoKey = [self.nle bingoKeyOfSlot:obj];
    }];
}

- (HTSVideoData *)videoData
{
    return [self.nle veVideoData];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    ACCNLEEditVideoData *videoData = [[ACCNLEEditVideoData allocWithZone:zone] initWithNLEModel:[self.nleModel deepClone]
                                                                                            nle:self.nle];
    videoData.isTempVideoData = self.isTempVideoData;
    videoData.effectFilterPathBlock = self.effectFilterPathBlock;
    return videoData;
}

- (void)setIdentifier:(NSString *)identifier
{
    self.nleModel.identifier = identifier;
}

- (NSString *)identifier
{
    return self.nleModel.identifier;
}

- (NSDictionary<AVAsset *,IESMMVideoDataClipRange *> *)audioTimeClipInfo
{
    return [[[self.nleModel tracksWithType:NLETrackAUDIO]
             acc_reduce:[NSMutableDictionary dictionary]
             reducer:^id _Nullable(NSMutableDictionary *_Nullable preValue, NLETrack_OC * _Nonnull obj) {
        [obj.slots acc_forEach:^(NLETrackSlot_OC * _Nonnull trackSlot) {
            AVAsset *asset = [self.nle assetFromSlot:trackSlot];
            if (asset) {
                preValue[asset] = [trackSlot audioClipRange];
            }
        }];
        return preValue;
    }] copy];
}

- (void)setAudioTimeClipInfo:(NSDictionary<AVAsset *,IESMMVideoDataClipRange *> *)audioTimeClipInfo
{
    // 移除旧的剪裁数据
    [[self.nleModel slotsWithType:NLETrackAUDIO] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        [obj resetAudioClipRange];
    }];
    // 添加新的剪裁数据
    [audioTimeClipInfo acc_forEach:^(AVAsset * _Nonnull key, IESMMVideoDataClipRange * _Nonnull obj) {
        [self updateAudioTimeClipInfoWithClipRange:obj asset:key];
    }];
}

- (void)updateAudioTimeClipInfoWithClipRange:(IESMMVideoDataClipRange *)clipRange asset:(AVAsset *)asset
{
    [self.nleModel audioSlotOfAsset:asset nle:self.nle].audioClipRange = clipRange;
}

- (void)removeAudioTimeClipInfoWithAsset:(AVAsset *)asset
{
    [[self.nleModel audioSlotOfAsset:asset nle:self.nle] resetAudioClipRange];
}

- (void)addAudioTimeClipInfos:(NSDictionary<AVAsset *,IESMMVideoDataClipRange *> *)infos
{
    [infos acc_forEach:^(AVAsset * _Nonnull key, IESMMVideoDataClipRange * _Nonnull obj) {
        [self updateAudioTimeClipInfoWithClipRange:obj asset:key];
    }];
}

- (CGFloat)totalVideoDuration
{
    return self.nle.totalVideoDuration;
}

- (NSTimeInterval)currentTotalDuration
{
    return self.nle.totalVideoDuration;
}

- (NSTimeInterval)totalDurationWithTimeMachine
{
    return self.nle.totalDurationWithTimeMachine;
}

- (BOOL)isFastImport
{
    return self.nleModel.isFastImport;
}

- (void)setIsFastImport:(BOOL)isFastImport
{
    self.nleModel.isFastImport = isFastImport;
}

- (BOOL)isRecordFromCamera
{
    return self.nleModel.isRecordFromCamera;
}

- (void)setIsRecordFromCamera:(BOOL)isRecordFromCamera
{
    self.nleModel.isRecordFromCamera = isRecordFromCamera;
}

- (BOOL)isMicMuted
{
    return self.nleModel.isMicMuted;
}

- (void)setIsMicMuted:(BOOL)isMicMuted
{
    self.nleModel.isMicMuted = isMicMuted;
}

- (NSDictionary<AVAsset *,NSNumber *> *)movieInputFillType
{
    return [[[self.nleModel slotsWithType:NLETrackVIDEO]
     acc_reduce:[NSMutableDictionary dictionary]
     reducer:^id _Nonnull(NSMutableDictionary  *_Nonnull preValue, NLETrackSlot_OC * _Nonnull next) {
        AVAsset *asset = [self.nle assetFromSlot:next];
        if (asset) {
            preValue[asset] = next.movieInputFillType;
        }
        return preValue;
    }] copy];
}

- (void)setMovieInputFillType:(NSDictionary<AVAsset *,NSNumber *> *)movieInputFillType
{
    [[self.nleModel slotsWithType:NLETrackVIDEO] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        obj.movieInputFillType = nil;
        [self.nle setMovieInputFillType:nil forSlot:obj];
    }];
    
    [movieInputFillType acc_forEach:^(AVAsset * _Nonnull key, NSNumber * _Nonnull value) {
        NLETrackSlot_OC *videoSlot = [self.nleModel videoSlotOfAsset:key nle:self.nle];
        
        if (videoSlot) {
            videoSlot.movieInputFillType = value;
            [self.nle setMovieInputFillType:value forSlot:videoSlot];
        }
    }];
}

- (void)updateMovieInputFillTypeWithType:(NSNumber *)type asset:(AVAsset *)asset
{
    // 查找当前asset对应的slot
    NLETrackSlot_OC *videoSlot = [self.nleModel videoSlotOfAsset:asset nle:self.nle];
    
    if (videoSlot) {
        [videoSlot setMovieInputFillType:type];
    }
}

- (CGFloat)maxTrackDuration
{
    return self.nle.maxTrackDuration;
}

- (void)setMaxTrackDuration:(CGFloat)maxTrackDuration
{}

- (NSDictionary *)dataInfo
{
    return self.nleModel.dataInfo;
}

- (void)setDataInfo:(NSDictionary *)dataInfo
{
    self.nleModel.dataInfo = dataInfo;
}

- (CGAffineTransform)importTransform
{
    return self.nleModel.importTransform;
}

- (void)setImportTransform:(CGAffineTransform)importTransform
{
    self.nleModel.importTransform = importTransform;
}

- (BOOL)disableMetadataInfo
{
    return self.nle.disableMetadataInfo;
}

- (void)setDisableMetadataInfo:(BOOL)disableMetadataInfo
{
    self.nle.disableMetadataInfo = disableMetadataInfo;
}

- (NSDictionary *)metaRecordInfo
{
    return self.nleModel.metaRecordInfo;
}

- (void)setMetaRecordInfo:(NSDictionary *)metaRecordInfo
{
    self.nleModel.metaRecordInfo = metaRecordInfo;
}

- (BOOL)isHDR
{
    return self.nle.veVideoData.colorSpaceInfo.transferFunction == VETransferFunctionType_ARIB_STD_B67 || self.nle.veVideoData.colorSpaceInfo.transferFunction == VETransferFunctionType_SMPTEST2084;
}

- (CGFloat)totalVideoDurationAddTimeMachine
{
    return self.nle.totalVideoDurationAddTimeMachine;
}

- (IESMMTranscoderParam *)transParam
{
    return self.nle.transParam;
}

- (void)setTransParam:(IESMMTranscoderParam *)transParam
{
    self.nle.transParam = transParam;
}

- (NSDictionary<AVAsset *,IESMMCurveSource *> *)videoCurves
{
    NSMutableDictionary *videoCurves = [NSMutableDictionary dictionary];
    for (NLETrackSlot_OC *videoSlot in [self.nleModel slotsWithType:NLETrackVIDEO]) {
        AVAsset *asset = [self.nle assetFromSlot:videoSlot];
        NLESegmentVideo_OC *videoSegment = videoSlot.videoSegment;
        if (asset && videoSegment.curveSpeedPoints.count > 0) {
            IESMMCurveSource *curveSource = [[IESMMCurveSource alloc] init];
            NSMutableArray *xPoints = [NSMutableArray array];
            NSMutableArray *yPoints = [NSMutableArray array];
            for (NSValue *curvePointValue in [videoSegment curveSpeedPoints]) {
                CGPoint curvePoint = [curvePointValue CGPointValue];
                [xPoints addObject:@(curvePoint.x)];
                [yPoints addObject:@(curvePoint.y)];
            }
            curveSource.xPoints = [xPoints copy];
            curveSource.yPoints = [yPoints copy];
            videoCurves[asset] = curveSource;
        }
    }
    return [videoCurves copy];
}

- (void)setVideoCurves:(NSDictionary<AVAsset *,IESMMCurveSource *> *)videoCurves
{
    [[self.nleModel slotsWithType:NLETrackVIDEO] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        [obj.videoSegment removeAllCurveSpeedPoint];
    }];
    
    for (AVAsset *asset in [videoCurves allKeys]) {
        IESMMCurveSource *curveSource = videoCurves[asset];
        [self updateVideoCurvesWithCurveSource:curveSource asset:asset];
    }
}

- (void)updateVideoCurvesWithCurveSource:(IESMMCurveSource *)curveSource asset:(AVAsset *)asset
{
    // 查找当前asset对应的slot
    NLETrackSlot_OC *videoSlot = [self.nleModel videoSlotOfAsset:asset nle:self.nle];
    
    if (videoSlot) {
        NLESegmentVideo_OC *video = videoSlot.videoSegment;

        // 清除当前所有的变速点
        [video removeAllCurveSpeedPoint];

        // 添加变速点
        NSInteger xPointsCount = curveSource.xPoints.count;
        NSInteger yPointsCount = curveSource.yPoints.count;
        NSInteger pointCount = xPointsCount > yPointsCount ? yPointsCount : xPointsCount;
        for (int idx = 0; idx < pointCount; idx++) {
            CGFloat xPoint = [curveSource.xPoints[idx] floatValue];
            CGFloat yPoint = [curveSource.yPoints[idx] floatValue];
            [video addCurveSpeedPoint:CGPointMake(xPoint, yPoint)];
        }
    }
}

- (NSString *)cacheDirPath
{
    return self.nle.draftFolder;
}

#pragma mark - 音视频资源

- (AVAsset *)videoHeader
{
    return self.nle.videoHeader;
}

- (void)setVideoHeader:(AVAsset *)videoHeader
{
    self.nle.videoHeader = videoHeader;
}

- (NSArray<AVAsset *> *)videoAssets
{
    NLETrack_OC *mainTrack = [self.nleModel getMainVideoTrack];
    return [[mainTrack slots] acc_map:^id _Nullable(NLETrackSlot_OC * _Nonnull obj) {
        AVAsset *asset = [self.nle assetFromSlot:obj];
        if (obj.videoSegment.getResNode.resourceType == NLEResourceTypeImage) {
            asset.frameImageURL = [NSURL fileURLWithPath:obj.videoSegment.getResNode.acc_path];
        }
        return asset;
    }];
}

- (void)setVideoAssets:(NSArray<AVAsset *> *)videoAssets
{
    NSArray<NLETrackSlot_OC *> *tracks = [videoAssets acc_map:^id _Nullable(AVAsset * _Nonnull obj) {
        return [NLETrackSlot_OC videoTrackSlotWithAsset:obj nle:self.nle];
    }];
    
    NLETrack_OC *track = [self.nleModel getMainVideoTrack];
    [track clearSlots];
    [track updateAndOrderSlots:tracks];
}

- (NSArray<AVAsset *> *)subTrackVideoAssets
{
    // 只支持单条副轨，后续支持多条需维护副轨状态
    return [[[self.nleModel tracksWithType:NLETrackVIDEO] acc_filter:^BOOL(NLETrack_OC * _Nonnull item) {
        return item.isVideoSubTrack && !item.isMainTrack;
    }] acc_flatMap:^id _Nonnull(NLETrack_OC  *_Nonnull track) {
        return [[track slots] acc_map:^id(NLETrackSlot_OC * _Nonnull obj) {
            AVAsset *asset = [self.nle assetFromSlot:obj];
            if (obj.videoSegment.getResNode.resourceType == NLEResourceTypeImage) {
                asset.frameImageURL = [NSURL fileURLWithPath:obj.videoSegment.getResNode.acc_path];
            }
            return asset;
        }];
    }];
}

- (void)setSubTrackVideoAssets:(NSArray<AVAsset *> *)subTrackVideoAssets
{
    NSArray<NLETrackSlot_OC *> *trackSlots = [subTrackVideoAssets acc_map:^id _Nonnull(AVAsset * _Nonnull obj) {
        return [NLETrackSlot_OC videoTrackSlotWithAsset:obj nle:self.nle];
    }];
    
    NLETrack_OC *subTrack = [self.nleModel getSubVideoTrack];
    [subTrack clearSlots];
    [trackSlots acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        [subTrack addSlot:obj];
    }];
}

- (int32_t)previewFrameRate
{
    return self.nle.previewFrameRate;
}

- (void)setPreviewFrameRate:(int32_t)previewFrameRate
{
    self.nle.previewFrameRate = previewFrameRate;
}

- (NSDictionary<AVAsset *,NSNumber *> *)videoTimeScaleInfo
{
    return [[[self.nleModel slotsWithType:NLETrackVIDEO]
     acc_reduce:[NSMutableDictionary dictionary]
     reducer:^id _Nonnull(NSMutableDictionary  *_Nonnull preValue, NLETrackSlot_OC * _Nonnull next) {
        AVAsset *asset = [self.nle assetFromSlot:next];
        if (asset) {
            preValue[asset] = @(next.videoSegment.absSpeed);
        }
        return preValue;
    }] copy];
}

- (void)setVideoTimeScaleInfo:(NSDictionary<AVAsset *,NSNumber *> *)videoTimeScaleInfo
{
    [[self.nleModel slotsWithType:NLETrackVIDEO] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        obj.videoSegment.absSpeed = HTSVideoSpeedNormal;
    }];
    
    [videoTimeScaleInfo acc_forEach:^(AVAsset * _Nonnull key, NSNumber * _Nonnull value) {
        [self updateVideoTimeScaleInfoWithScale:value asset:key];
    }];
}


/// 设置视频变速，同时也会设置视频的动画变速
/// @param scale 变速
/// @param asset AVAsset *  视频
- (void)updateVideoTimeScaleInfoWithScale:(NSNumber *)scale asset:(AVAsset *)asset {
    NLETrackSlot_OC *videoSlot = [self.nleModel videoSlotOfAsset:asset nle:self.nle];
    
    if (videoSlot) {
        // speed 不能为0，默认是1
        CGFloat absSpeed = scale.floatValue;
        absSpeed = ACC_FLOAT_EQUAL_ZERO(absSpeed) ? 1.f : absSpeed;
        videoSlot.videoSegment.absSpeed = absSpeed;
        [videoSlot.getVideoAnims enumerateObjectsUsingBlock:^(NLEVideoAnimation_OC * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.segmentVideoAnimation.animationDuration = videoSlot.duration;
        }];
    }
}

- (NSArray<AVAsset *> *)audioAssets
{
    return [[[self.nleModel slotsWithType:NLETrackAUDIO] sortedArrayUsingComparator:^NSComparisonResult(NLETrackSlot_OC * _Nonnull obj1, NLETrackSlot_OC * _Nonnull obj2) {
        if (obj1.layer == obj2.layer) {
            return NSOrderedSame;
        } else {
            return obj1.layer > obj2.layer ? NSOrderedDescending : NSOrderedAscending;
        }
    }] acc_compactMap:^id _Nonnull(NLETrackSlot_OC * _Nonnull trackSlot) {
        if (trackSlot.audioSegment.audioFile.resourceType != NLEResourceTypeKaraokeUserAudio) {
            return [self.nle assetFromSlot:trackSlot];
        } else {
            return nil;
        }
    }];
}

- (void)setAudioAssets:(NSArray<AVAsset *> *)audioAssets
{
    // 移除老的非K歌用户唱的声音资源音频轨道，因为K歌用户唱的声音资源是放在bgAudioAssets里
    [[self.nleModel tracksWithType:NLETrackAUDIO] acc_forEach:^(NLETrack_OC * _Nonnull obj) {
        // 内部有copy了，不需要重复
        for (NLETrackSlot_OC *slot in obj.slots) {
            if (slot.audioSegment.audioFile.resourceType != NLEResourceTypeKaraokeUserAudio) {
                [obj removeSlot:slot];
            }
        }
        if (obj.slots.count == 0) {
            [self.nleModel removeTrack:obj];
        }
    }];
    
    // 添加新的音轨
    [[audioAssets acc_map:^id _Nullable(AVAsset * _Nonnull asset) {
        NLETrackSlot_OC *slot = [NLETrackSlot_OC audioTrackSlotWithAsset:asset nle:self.nle];
        NLETrack_OC *track = [[NLETrack_OC alloc] init];
        track.extraTrackType = NLETrackAUDIO;
        [track addSlot:slot];
        return track;
    }] acc_forEach:^(NLETrack_OC * _Nonnull track) {
        track.slots.firstObject.layer = [self.nleModel getLayerMax] + 1;
        [self.nleModel addTrack:track];
    }];
}

- (NSArray<AVAsset *> *)bgAudioAssets
{
    return [[[self.nleModel slotsWithType:NLETrackAUDIO] sortedArrayUsingComparator:^NSComparisonResult(NLETrackSlot_OC * _Nonnull obj1, NLETrackSlot_OC * _Nonnull obj2) {
        if (obj1.layer == obj2.layer) {
            return NSOrderedSame;
        } else {
            return obj1.layer > obj2.layer ? NSOrderedDescending : NSOrderedAscending;
        }
    }] acc_compactMap:^id _Nonnull(NLETrackSlot_OC * _Nonnull trackSlot) {
        if (trackSlot.audioSegment.audioFile.resourceType == NLEResourceTypeKaraokeUserAudio) {
            return [self.nle assetFromSlot:trackSlot];
        } else {
            return nil;
        }
    }];
}

- (void)setBgAudioAssets:(NSArray<AVAsset *> *)bgAudioAssets
{
    if ([self.nleModel bgAudioAssetTrack]) {
        [self.nleModel removeTrack:[self.nleModel bgAudioAssetTrack]];
    }
    if (!ACC_isEmptyArray(bgAudioAssets)) {
        NLETrack_OC *track = [[NLETrack_OC alloc] init];
        for (AVAsset *asset in bgAudioAssets) {
            NLETrackSlot_OC *slot = [NLETrackSlot_OC audioTrackSlotWithAsset:asset nle:self.nle];
            [slot.audioSegment getResNode].resourceType = NLEResourceTypeKaraokeUserAudio;
            slot.layer = [self.nleModel getLayerMax] + 1;
            [track addSlot:slot];
        }
        track.startTime = CMTimeMake(0 * USEC_PER_SEC, USEC_PER_SEC);
        [self.nleModel addTrack:track];
    }
}

- (BOOL)isDetectMode
{
    return self.nle.isDetectMode;
}

- (void)setIsDetectMode:(BOOL)isDetectMode
{
    self.nle.isDetectMode = isDetectMode;
}

- (CGFloat)totalBGAudioDuration
{
    NLETrack_OC *track = [self.nleModel bgAudioAssetTrack];
    return CMTimeGetSeconds(CMTimeSubtract(track.endTime, track.startTime));
}

- (void)setTotalBGAudioDuration:(CGFloat)totalBGAudioDuration
{
    NLETrack_OC *bgAudioTrack = [self.nleModel bgAudioAssetTrack];
    bgAudioTrack.duration = CMTimeMake(totalBGAudioDuration * USEC_PER_SEC, USEC_PER_SEC);
    bgAudioTrack.endTime = CMTimeAdd(bgAudioTrack.startTime, bgAudioTrack.duration);
}

- (BOOL)hasRecordAudio
{
    NSArray<NLETrack_OC *> *videoTracks = [self.nleModel tracksWithType:NLETrackVIDEO];
    if (videoTracks.count == 0) {
        return NO;
    }
    
    if (self.isMicMuted) {
        return NO;
    }
    
    BOOL containAudioTrack = [videoTracks acc_any:^BOOL(NLETrack_OC * _Nonnull obj) {
        return [obj.slots acc_any:^BOOL(NLETrackSlot_OC * _Nonnull obj) {
            return [[obj videoSegment] audioFile].hasAudio;
        }];
    }];
    if (!containAudioTrack) {
        return NO;
    }
    
    BOOL volumIsNotZero = [videoTracks acc_any:^BOOL(NLETrack_OC * _Nonnull obj) {
        return [obj.slots acc_any:^BOOL(NLETrackSlot_OC * _Nonnull obj) {
            return [obj videoSegment].volume >= 1e-5;
        }];
    }];
    if (!volumIsNotZero) {
        return NO;
    }
    
    return YES;
}

- (NSDictionary<AVAsset *,NSArray<IESMMAudioFilter *> *> *)audioSoundFilterInfo
{
    NSMutableArray *audioFilters = [NSMutableArray array];
    
    for (NLEFilter_OC *filter in [self.nleModel voiceChangerFilters]) {
        IESMMAudioFilter *audioFilter = [filter mmAudioFilterFromCurrentFilter];
        if (audioFilter) {
            [audioFilters addObject:audioFilter];
        }
    }
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    [[self.nleModel tracksWithType:NLETrackAUDIO] acc_forEach:^(NLETrack_OC * _Nonnull track) {
        [track.slots acc_forEach:^(NLETrackSlot_OC * _Nonnull trackSlot) {
            AVAsset *asset = [self.nle assetFromSlot:trackSlot];
            if (asset) {
                if (!track.isBGMTrack) {
                    IESMMAudioFilter *volumFilter = [[IESMMAudioFilter alloc] init];
                    IESMMAudioVolumeConfig *volumeConfig = [[IESMMAudioVolumeConfig alloc] init];
                    volumeConfig.multiClipEffected = YES;
                    volumeConfig.volume = trackSlot.audioSegment.volume;
                    volumFilter.config = volumeConfig;
                    [audioFilters addObject:volumFilter];
                }
                info[asset] = audioFilters;
            }
        }];
    }];
    return [info copy];
}

- (void)setAudioSoundFilterInfo:(NSDictionary<AVAsset *,NSArray<IESMMAudioFilter *> *> *)audioSoundFilterInfo
{
    [self.nleModel removeAllAudioFiltersForAudioAsset:YES];
    [audioSoundFilterInfo enumerateKeysAndObjectsUsingBlock:^(AVAsset * _Nonnull key, NSArray<IESMMAudioFilter *> * _Nonnull obj, BOOL * _Nonnull stop) {
        [self.nleModel setAudioFilters:obj forTrack:[self.nleModel audioTrackOfAsset:key nle:self.nle] draftFolder:self.nle.draftFolder];
    }];
}

- (void)updateSoundFilterInfoWithFilters:(NSArray<IESMMAudioFilter *> *)filters asset:(AVAsset *)asset
{
    [self.nleModel setAudioFilters:filters forTrack:[self.nleModel audioTrackOfAsset:asset nle:self.nle] draftFolder:self.nle.draftFolder];
}

- (void)removeSoundFilterWithFilter:(IESMMAudioFilter *)filter asset:(AVAsset *)asset
{
    [self.nleModel removeAudioFilter:filter forTrack:[self.nleModel audioTrackOfAsset:asset nle:self.nle]];
}

- (NSDictionary<AVAsset *,NSArray<IESMMAudioFilter *> *> *)videoSoundFilterInfo
{
    NSMutableArray *audioFilters = [NSMutableArray array];
    
    for (NLEFilter_OC *filter in [self.nleModel voiceChangerFilters]) {
        IESMMAudioFilter *audioFilter = [filter mmAudioFilterFromCurrentFilter];
        if (audioFilter) {
            [audioFilters addObject:audioFilter];
        }
    }
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    [[self.nleModel tracksWithType:NLETrackVIDEO] acc_forEach:^(NLETrack_OC * _Nonnull track) {
        [track.slots acc_forEach:^(NLETrackSlot_OC * _Nonnull trackSlot) {
            AVAsset *asset = [self.nle assetFromSlot:trackSlot];
            if (asset) {
                info[asset] = audioFilters;
            }
        }];
    }];
    return [info copy];
}

- (void)setVideoSoundFilterInfo:(NSDictionary<AVAsset *,NSArray<IESMMAudioFilter *> *> *)videoSoundFilterInfo
{
    [self.nleModel removeAllAudioFiltersForAudioAsset:NO];
    [videoSoundFilterInfo enumerateKeysAndObjectsUsingBlock:^(AVAsset * _Nonnull key, NSArray<IESMMAudioFilter *> * _Nonnull obj, BOOL * _Nonnull stop) {
        [self.nleModel setAudioFilters:obj forTrack:[self.nleModel videoTrackOfAsset:key nle:self.nle] draftFolder:self.nle.draftFolder];
    }];
}

- (void)updateVideoSoundFilterInfoWithFilters:(NSArray<IESMMAudioFilter *> *)filters asset:(AVAsset *)asset
{
    [self.nleModel setAudioFilters:filters forTrack:[self.nleModel videoTrackOfAsset:asset nle:self.nle] draftFolder:self.nle.draftFolder];
}

- (void)removeVideoSoundFilterWithFilter:(IESMMAudioFilter *)filter asset:(AVAsset *)asset
{
    [self.nleModel removeAudioFilter:filter forTrack:[self.nleModel videoTrackOfAsset:asset nle:self.nle]];
}

- (BOOL)videoAssetsAllHaveAudioTrack
{
    NSArray *videoSlots = [self.nleModel slotsWithType:NLETrackVIDEO];
    if (ACC_isEmptyArray(videoSlots)) {
        return NO;
    }
    return [videoSlots acc_all:^BOOL(NLETrackSlot_OC * _Nonnull obj) {
        return [[obj videoSegment] videoFile].hasAudio;
    }];
}

- (BOOL)videoAssetsAllMuted
{
    return [[self.nleModel slotsWithType:NLETrackVIDEO] acc_all:^BOOL(NLETrackSlot_OC * _Nonnull obj) {
        return ![[obj videoSegment] videoFile].hasAudio;
    }];
}

- (NSString *)musicID
{
    return self.nle.musicID;
}

- (void)setMusicID:(NSString *)musicID
{
    self.nle.musicID = musicID;
}

- (NSDictionary<AVAsset *,NSNumber *> *)assetRotationsInfo
{
    return [[[self.nleModel slotsWithType:NLETrackVIDEO]
            acc_reduce:[NSMutableDictionary dictionary]
            reducer:^id _Nonnull(NSMutableDictionary *_Nonnull preValue, NLETrackSlot_OC * _Nonnull next) {
        AVAsset *asset = [self.nle assetFromSlot:next];
        if (asset) {
            preValue[asset] = next.assetRotationInfo;
        }
        return preValue;
    }] copy];
}

- (void)setAssetRotationsInfo:(NSDictionary<AVAsset *,NSNumber *> *)assetRotationsInfo
{
    [[self.nleModel slotsWithType:NLETrackVIDEO] acc_forEach:^(NLETrackSlot_OC  *_Nonnull item) {
        item.assetRotationInfo = nil;
    }];
    
    [assetRotationsInfo acc_forEach:^(AVAsset * _Nonnull key, NSNumber * _Nonnull value) {
        [self updateAssetRotationsInfoWithRotateType:value asset:key];
    }];
}

- (void)updateAssetRotationsInfoWithRotateType:(NSNumber *)rotateType asset:(AVAsset *)asset
{
    [self.nleModel videoSlotOfAsset:asset nle:self.nle].assetRotationInfo = rotateType;
}

- (NSDictionary<AVAsset *,IESMMVideoTransformInfo *> *)assetTransformInfo
{
    return [[[self.nleModel slotsWithType:NLETrackVIDEO]
            acc_reduce:[NSMutableDictionary dictionary]
            reducer:^id _Nonnull(NSMutableDictionary *_Nonnull preValue, NLETrackSlot_OC * _Nonnull next) {
        AVAsset *asset = [self.nle assetFromSlot:next];
        IESMMVideoTransformInfo *transformInfo = [next videoTransform];
        if (asset && transformInfo) {
            preValue[asset] = transformInfo;
        }
        return preValue;
    }] copy];
}

- (void)setAssetTransformInfo:(NSDictionary<AVAsset *,IESMMVideoTransformInfo *> *)assetTransformInfo
{
    [[self.nleModel slotsWithType:NLETrackVIDEO] acc_forEach:^(NLETrackSlot_OC  *_Nonnull item) {
        [item clearVideoAnim];
    }];
    
    [assetTransformInfo acc_forEach:^(AVAsset * _Nonnull key, IESMMVideoTransformInfo * _Nonnull value) {
        [self updateAssetTransformInfoWithTransformInfo:value asset:key];
    }];
}

- (void)updateAssetTransformInfoWithTransformInfo:(IESMMVideoTransformInfo *)transformInfo asset:(AVAsset *)asset
{
    [self.nleModel videoSlotOfAsset:asset nle:self.nle].videoTransform = transformInfo;
}

- (AVAsset *)endingWaterMarkAudio
{
    return self.nle.endingWaterMarkAudio;
}

- (void)setEndingWaterMarkAudio:(AVAsset *)endingWaterMarkAudio
{
    self.nle.endingWaterMarkAudio = endingWaterMarkAudio;
}

- (NSDictionary<AVAsset *,NSArray<NSNumber *> *> *)volumnInfo
{
    return [[[self.nleModel getTracks]
            acc_reduce:[NSMutableDictionary dictionary]
            reducer:^id _Nullable(NSMutableDictionary  *_Nullable preValue, NLETrack_OC * _Nonnull obj) {
        [obj.slots acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
            AVAsset *asset = [self.nle assetFromSlot:obj];
            NLESegmentAudio_OC *audioSegment = [obj audioSegment];
            if (asset != nil) {
                preValue[asset] = @[@(audioSegment.volume)];
            }
        }];
        return preValue;
    }] copy];
}

- (void)setVolumnInfo:(NSDictionary<AVAsset *,NSArray<NSNumber *> *> *)volumnInfo
{
    [self.volumnInfo acc_forEach:^(AVAsset * _Nonnull key, NSArray<NSNumber *> * _Nonnull value) {
        [self updateVolumeInfoWithVolumes:@[@1] asset:key];
    }];
    
    [volumnInfo acc_forEach:^(AVAsset * _Nonnull key, NSArray<NSNumber *> * _Nonnull obj) {
        [self updateVolumeInfoWithVolumes:obj asset:key];
    }];
}

- (void)updateVolumeInfoWithVolumes:(NSArray<NSNumber *> *)volumes asset:(AVAsset *)asset
{
    if (volumes.count == 0) { return; }
    
    [[self.nleModel audioSlotOfAsset:asset nle:self.nle] audioSegment].volume = [volumes.firstObject floatValue];
    [[self.nleModel videoSlotOfAsset:asset nle:self.nle] videoSegment].volume = [volumes.firstObject floatValue];
}

- (NSDictionary *)bingoVideoKeys
{
    return [[[self.nleModel slotsWithType:NLETrackVIDEO]
     acc_reduce:[NSMutableDictionary dictionary]
     reducer:^id _Nonnull(NSMutableDictionary  *_Nonnull preValue, NLETrackSlot_OC * _Nonnull next) {
        AVAsset *asset = [self.nle assetFromSlot:next];
        if (asset) {
            preValue[asset] = next.bingoKey;
        }
        return preValue;
    }] copy];
}

- (void)setBingoVideoKeys:(NSDictionary *)bingoVideoKeys
{
    [[self.nleModel slotsWithType:NLETrackVIDEO] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        [self.nle setBingoKey:nil forSlot:obj];
    }];
    
    [bingoVideoKeys acc_forEach:^(AVAsset * _Nonnull key, NSString * _Nonnull value) {
        NLETrackSlot_OC *videoSlot = [self.nleModel videoSlotOfAsset:key nle:self.nle];
        
        if (videoSlot) {
            videoSlot.bingoKey = value;
        }
    }];
}

- (CGFloat)videoRateForAsset:(AVAsset *_Nonnull)asset
{
    return [[[self.nleModel videoSlotOfAsset:asset nle:self.nle] videoSegment] absSpeed];
}

- (void)setVolumeForAudio:(float)volume
{
    [self.nleModel acc_setAudioVolumn:volume forTrackCondition:^BOOL(NLETrack_OC * _Nonnull track) {
        return YES;
    }];
}

- (void)setVolumeForVideo:(float)volume
{
    [self.nleModel acc_setVideoVolumn:volume forTrackCondition:^BOOL(NLETrack_OC *track) {
        return YES;
    }];
}

- (NSArray<NSNumber *> * _Nullable)volumeForAsset:(AVAsset *_Nonnull)asset
{
    NLETrackSlot_OC *audioSlot = [self.nleModel audioSlotOfAsset:asset nle:self.nle];
    if (audioSlot) {
        return @[@([audioSlot audioSegment].volume)];
    }

    NLETrackSlot_OC *videoSlot = [self.nleModel videoSlotOfAsset:asset nle:self.nle];
    if (videoSlot) {
        return @[@([videoSlot videoSegment].volume)];
    }
    
    return nil;
}

- (CMTimeRange)audioTimeClipRangeForAsset:(AVAsset *_Nonnull)asset
{
    NLETrackSlot_OC *trackSlot = [self.nleModel audioSlotOfAsset:asset nle:self.nle];
    if (trackSlot && trackSlot.isEnable) {
        NLESegmentAudio_OC *audioSegment = [trackSlot audioSegment];
        return CMTimeRangeMake(audioSegment.timeClipStart, CMTimeSubtract(audioSegment.timeClipEnd, audioSegment.timeClipStart));
    }
    return kCMTimeRangeZero;
}

- (void)addAudioWithAsset:(AVAsset *_Nonnull)asset
{
    BOOL containAsset = [self.nleModel audioSlotOfAsset:asset nle:self.nle] != nil;
    if (containAsset) return;
    
    NLETrackSlot_OC *trackSlot = [NLETrackSlot_OC audioTrackSlotWithAsset:asset nle:self.nle];
    trackSlot.layer = [self.nleModel getLayerMax] + 1;
    NLETrack_OC *track = [[NLETrack_OC alloc] init];
    track.extraTrackType = NLETrackAUDIO;
    [track addSlot:trackSlot];
    
    [self.nleModel addTrack:track];
}

- (void)addAudioWithAssets:(NSArray<AVAsset *> *)asset {
    [asset acc_forEach:^(AVAsset * _Nonnull obj) {
        [self addAudioWithAsset:obj];
    }];
}

- (void)removeAudioWithAssets:(NSArray<AVAsset *> *)assets {
    [assets acc_forEach:^(AVAsset * _Nonnull asset) {
        [self removeAudioAsset:asset];
    }];
}

- (void)removeAllAudioAsset
{
    [self.nleModel removeTracksWithType:NLETrackAUDIO];
}

- (void)removeAudioAsset:(AVAsset *_Nonnull)asset
{
    [[self.nleModel tracksWithType:NLETrackAUDIO] acc_forEach:^(NLETrack_OC * _Nonnull track) {
        [track.slots acc_forEach:^(NLETrackSlot_OC * _Nonnull trackSlot) {
            if ([self.nle acc_slot:trackSlot isRelateWithAsset:asset]) {
                [track removeSlot:trackSlot];
            }
        }];
        
        if (track.slots.count == 0) {
            [self.nleModel removeTrack:track];
        }
    }];
}

- (AVAsset *)addVideoWithAsset:(AVAsset *)asset
{
    NLETrackSlot_OC *curSlot = [self.nleModel videoSlotOfAsset:asset nle:self.nle];
    if (curSlot) {
        return [self.nle assetFromSlot:curSlot];
    }
    
    NLETrackSlot_OC *trackSlot = [NLETrackSlot_OC videoTrackSlotWithAsset:asset nle:self.nle];
    NLETrack_OC *mainTrack = [self.nleModel getMainVideoTrack];
    [mainTrack addSlotAtEnd:trackSlot];
    return [self.nle assetFromSlot:trackSlot];
}

- (AVAsset *)addSubTrackWithAsset:(AVAsset *)asset {
    NSArray<NLETrackSlot_OC *> *allSubTrackSlots = [[[self.nleModel subTracksWithType:NLETrackVIDEO] acc_filter:^BOOL(NLETrack_OC * _Nonnull item) {
        return item.isVideoSubTrack && !item.isMainTrack;
    }] acc_flatMap:^NSArray * _Nonnull(NLETrack_OC *  _Nonnull obj) {
        return [obj slots];
    }];
    
    NLETrackSlot_OC *curSlot = [allSubTrackSlots acc_match:^BOOL(NLETrackSlot_OC * _Nonnull item) {
        return [self.nle acc_slot:item isRelateWithAsset:asset];
    }];
    
    if (curSlot) {
        return [self.nle assetFromSlot:curSlot];
    }
    
    NLETrackSlot_OC *trackSlot = [NLETrackSlot_OC videoTrackSlotWithAsset:asset nle:self.nle];
    NLETrack_OC *subTrack = [self.nleModel getSubVideoTrack];
    [subTrack addSlot:trackSlot];
    return [self.nle assetFromSlot:trackSlot];
}

- (NLETrackSlot_OC *)addPictureWithURL:(NSURL *)url duration:(CGFloat)duration
{
    NLETrackSlot_OC *picSlot = [NLETrackSlot_OC videoTrackSlotWithPictureURL:url duration:duration nle:self.nle];
    [[self.nleModel getMainVideoTrack] addSlotAtEnd:picSlot];
    return picSlot;
}

- (void)moveVideoAssetFromIndex:(NSInteger)fromIndex
                        toIndex:(NSInteger)toIndex
{
    if (fromIndex == toIndex) {
        return;
    }
    
    NSMutableArray<NLETrackSlot_OC *> *sortedSlots = [[[self.nleModel getMainVideoTrack] slots] mutableCopy];
    NLETrackSlot_OC *moveSlot = sortedSlots[fromIndex];
    [sortedSlots removeObjectAtIndex:fromIndex];
    [sortedSlots insertObject:moveSlot atIndex:toIndex];
    
    NLETrack_OC *mainTrack = [self.nleModel getMainVideoTrack];
    [mainTrack updateAndOrderSlots:sortedSlots];
}

- (void)removeAllVideoAsset
{
    [self.nleModel removeTrack:[self.nleModel getMainVideoTrack]];
}

- (void)removeVideoAsset:(AVAsset *_Nonnull)asset
{
    NSMutableArray<NLETrackSlot_OC *> *sortedSlots = [[[self.nleModel getMainVideoTrack] slots] mutableCopy];
    NLETrackSlot_OC *removeSlot = [sortedSlots acc_match:^BOOL(NLETrackSlot_OC * _Nonnull obj) {
        return [self.nle acc_slot:obj isRelateWithAsset:asset];
    }];
    if (!removeSlot) {
        return;
    }
    
    [sortedSlots removeObject:removeSlot];
    NLETrack_OC *mainTrack = [self.nleModel getMainVideoTrack];
    [mainTrack updateAndOrderSlots:sortedSlots];
}

- (void)acc_addVideoAssetDict:(AVAsset *)asset
                fromVideoData:(id<ACCEditVideoDataProtocol>)videoData
{
    ACCNLEEditVideoData *nleVideoData = acc_videodata_take_nle(videoData);
    NLETrackSlot_OC *addSlot =
    [[[[nleVideoData.nleModel getMainVideoTrack] slots] acc_match:^BOOL(NLETrackSlot_OC * _Nonnull obj) {
        return [self.nle acc_slot:obj isRelateWithAsset:asset];
    }] deepClone];
    
    if (!addSlot) {
        return;
    }
    
    NSInteger index = [[[self.nleModel getMainVideoTrack] slots] acc_indexOf:^BOOL(NLETrackSlot_OC * _Nonnull obj) {
        return [self.nle acc_slot:obj isRelateWithAsset:asset];
    }];
    
    if (index == NSNotFound) {
        return;
    }
    
    [[self.nleModel getMainVideoTrack] acc_replaceSlot:addSlot atIndex:index];
}

- (void)acc_addAudioAssetDict:(AVAsset *)asset
                fromVideoData:(id<ACCEditVideoDataProtocol>)videoData
{
    ACCNLEEditVideoData *nleVideoData = acc_videodata_take_nle(videoData);
    
    // 先移除现有的音频
    [self removeAudioAsset:asset];
    
    // 添加新音频
    NLETrack_OC *track = [[[nleVideoData.nleModel getTracks] acc_match:^BOOL(NLETrack_OC * _Nonnull obj) {
        return obj.extraTrackType == NLETrackAUDIO && [obj.slots acc_any:^BOOL(NLETrackSlot_OC * _Nonnull trackSlot) {
            return [self.nle acc_slot:trackSlot isRelateWithAsset:asset];
        }];
    }] deepClone];
    
    if (track) {
        track.slots.firstObject.layer = [self.nleModel getLayerMax] + 1;
        [self.nleModel addTrack:track];
    }
}

- (void)acc_replaceVideoAssetAtIndex:(NSInteger)index
                           withAsset:(AVAsset *)asset
                       fromVideoData:(id<ACCEditVideoDataProtocol>)videoData
{
    [self acc_replaceVideoAssetsInRange:NSMakeRange(index, 1) withAssets:@[asset] fromVideoData:videoData];
}

- (void)acc_replaceVideoAssetsInRange:(NSRange)range
                           withAssets:(NSArray<AVAsset *> *)assets
                        fromVideoData:(id<ACCEditVideoDataProtocol>)videoData
{
    NSArray<NLETrackSlot_OC * > *mainSlots = [[self.nleModel getMainVideoTrack] slots];
    if (range.location == NSNotFound ||
        range.location > mainSlots.count ||
        range.location + range.length - 1 > mainSlots.count) {
        return;
    }
    
    ACCNLEEditVideoData *nleVideoData = acc_videodata_make_nle(videoData, self.nle);
    NSArray<NLETrackSlot_OC *> *replaceSlots = [assets acc_compactMap:^id _Nonnull(AVAsset * _Nonnull asset) {
        return [[[[nleVideoData.nleModel getMainVideoTrack] slots] acc_match:^BOOL(NLETrackSlot_OC * _Nonnull obj) {
            return [self.nle acc_slot:obj isRelateWithAsset:asset];
        }] deepClone];
    }];
    
    NSMutableArray<NLETrackSlot_OC *> *slots = [[[self.nleModel getMainVideoTrack] slots] mutableCopy];
    [slots replaceObjectsInRange:range withObjectsFromArray:replaceSlots];
    [[self.nleModel getMainVideoTrack] updateAndOrderSlots:slots];
}

- (CMTime)getVideoDuration:(AVAsset *_Nonnull)asset
{
    // 因为当前编辑的不一定是当前的 videoData，所以需要做一层筛选
    AVAsset *trueAsset = [self.videoData.videoAssets acc_match:^BOOL(AVAsset * _Nonnull item) {
        return [asset isKindOfClass:[AVURLAsset class]] &&
            [item isKindOfClass:[AVURLAsset class]] &&
            [[(AVURLAsset *)asset URL].absoluteString isEqualToString:[(AVURLAsset *)item URL].absoluteString];
    }];
    
    return [self.videoData getVideoDuration:trueAsset];
}

- (void)setMetaData:(AVAsset * _Nonnull)asset recordInfo:(IESMetaRecordInfo)recordInfo MD5:(nullable NSString *)MD5 needStore:(BOOL)needStore {
    [self.nle setMetaData:asset recordInfo:recordInfo MD5:MD5 needStore:needStore];
}

#pragma mark - 裁剪

- (NSDictionary<AVAsset *,IESMMVideoDataClipRange *> *)videoTimeClipInfo
{
    return [[[self.nleModel slotsWithType:NLETrackVIDEO]
            acc_reduce:[NSMutableDictionary dictionary]
            reducer:^id _Nonnull(id  _Nonnull preValue, NLETrackSlot_OC * _Nonnull next) {
        AVAsset *videoAsset = [self.nle assetFromSlot:next];
        if (videoAsset) {
            preValue[videoAsset] = [next videoClipRange];
        }
        return preValue;
    }] copy];
}

- (void)setVideoTimeClipInfo:(NSDictionary<AVAsset *,IESMMVideoDataClipRange *> *)videoTimeClipInfo
{
    // 重置剪裁区间
    [[self.nleModel slotsWithType:NLETrackVIDEO] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        [obj resetVideoClipRange];
    }];
    // 设置新的区间
    [videoTimeClipInfo acc_forEach:^(AVAsset * _Nonnull key, IESMMVideoDataClipRange * _Nonnull value) {
        [self updateVideoTimeClipInfoWithClipRange:value asset:key];
    }];
}

- (void)updateVideoTimeClipInfoWithClipRange:(IESMMVideoDataClipRange *)range asset:(AVAsset *)asset
{
    [self.nleModel videoSlotOfAsset:asset nle:self.nle].videoClipRange = range;
}

- (AWEAIVideoClipInfoResolveType)studio_videoClipResolveType
{
    return (AWEAIVideoClipInfoResolveType)[self.nleModel getMainVideoTrack].videoClipResolveType;
}

- (void)setStudio_videoClipResolveType:(AWEAIVideoClipInfoResolveType)studio_videoClipResolveType
{
    [self.nleModel getMainVideoTrack].videoClipResolveType = studio_videoClipResolveType;
}

- (void)setMetaData:(AVAsset *_Nonnull)asset recordInfo:(IESMetaRecordInfo)recordInfo
{
    [self.nle setMetaData:asset recordInfo:recordInfo MD5:nil needStore:YES];
}

- (CMTimeRange)videoTimeClipRangeForAsset:(AVAsset *_Nonnull)asset
{
    NLESegmentVideo_OC *videoSegment =
    [[[self.nleModel slotsWithType:NLETrackVIDEO] acc_match:^BOOL(NLETrackSlot_OC * _Nonnull obj) {
        return obj.isEnable && [self.nle acc_slot:obj isRelateWithAsset:asset];;
    }] videoSegment];
    
    if (!videoSegment) {
        return kCMTimeRangeZero;
    }
    
    CMTimeRange clipRange = CMTimeRangeMake(videoSegment.timeClipStart, CMTimeSubtract(videoSegment.timeClipEnd, videoSegment.timeClipStart));
    
    AVAssetTrack *track        = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    CMTimeRange trackTimeRange = track.timeRange;
    trackTimeRange.start       = ACCCMTimeMakeSeconds(CMTimeGetSeconds(trackTimeRange.start));
    trackTimeRange.duration    =  ACCCMTimeMakeSeconds(CMTimeGetSeconds(trackTimeRange.duration));
    
    return CMTimeRangeGetIntersection(trackTimeRange, clipRange);
}

#pragma mark - 跨平台

- (BOOL)notSupportCrossplat
{
    return self.nle.notSupportCrossplat;
}

- (void)setNotSupportCrossplat:(BOOL)notSupportCrossplat
{
    self.nle.notSupportCrossplat = notSupportCrossplat;
}

- (BOOL)crossplatCompile
{
    return self.nle.crossplatCompile;
}

- (void)setCrossplatCompile:(BOOL)crossplatCompile
{
    self.nle.crossplatCompile = crossplatCompile;
}

- (BOOL)crossplatInput
{
    return self.nle.crossplatInput;
}

- (void)setCrossplatInput:(BOOL)crossplatInput
{
    self.nle.crossplatInput = crossplatInput;
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
    self.nleModel.preferCanvasConfig = preferCanvasConfig;
}

- (IESMMCanvasConfig *)preferCanvasConfig
{
    return self.nleModel.preferCanvasConfig;
}

- (NSDictionary<AVAsset *,IESMMCanvasConfig *> *)canvasConfigsMap
{
    return [[[self.nleModel slotsWithType:NLETrackVIDEO]
     acc_reduce:[NSMutableDictionary dictionary]
     reducer:^id _Nonnull(NSMutableDictionary  *_Nonnull preValue, NLETrackSlot_OC * _Nonnull next) {
        AVAsset *asset = [self.nle assetFromSlot:next];
        if (asset) {
            preValue[asset] = next.canvasConfig;
        }
        return preValue;
    }] copy];
}

- (void)setCanvasConfigsMap:(NSDictionary<AVAsset *,IESMMCanvasConfig *> *)canvasConfigsMap
{
    [[self.nleModel slotsWithType:NLETrackVIDEO] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        [obj setCanvasConfig:nil draftFolder:self.draftFolder];
    }];
    
    [canvasConfigsMap acc_forEach:^(AVAsset * _Nonnull key, IESMMCanvasConfig * _Nonnull value) {
        [self updateCanvasConfigsMapWithConfig:value asset:key];
    }];
}

- (void)updateCanvasConfigsMapWithConfig:(IESMMCanvasConfig *)config asset:(AVAsset *)asset
{
    [[self.nleModel videoSlotOfAsset:asset nle:self.nle] setCanvasConfig:config draftFolder:self.draftFolder];
}

- (NSDictionary<AVAsset *,IESMMCanvasSource *> *)canvasInfo
{
    return [[[self.nleModel slotsWithType:NLETrackVIDEO]
     acc_reduce:[NSMutableDictionary dictionary]
     reducer:^id _Nonnull(NSMutableDictionary  *_Nonnull preValue, NLETrackSlot_OC * _Nonnull next) {
        AVAsset *asset = [self.nle assetFromSlot:next];
        if (asset) {
            preValue[asset] = next.canvasSource;
        }
        return preValue;
    }] copy];
}

- (void)setCanvasInfo:(NSDictionary<AVAsset *,IESMMCanvasSource *> *)canvasInfo
{
    [[self.nleModel slotsWithType:NLETrackVIDEO] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        obj.canvasSource = nil;
    }];
    
    [canvasInfo acc_forEach:^(AVAsset * _Nonnull key, IESMMCanvasSource * _Nonnull value) {
        [self updateCanvasInfoWithCanvasSource:value asset:key];
    }];
}

- (void)updateCanvasInfoWithCanvasSource:(IESMMCanvasSource *)canvasSource asset:(AVAsset *)asset
{
    [self.nleModel videoSlotOfAsset:asset nle:self.nle].canvasSource = canvasSource;
}

- (CGSize)canvasSize
{
    return self.nle.canvasSize;
}

- (void)setCanvasSize:(CGSize)canvasSize
{
    self.nle.canvasSize = canvasSize;
    self.nleModel.canvasRatio = canvasSize.width / canvasSize.height;
}

- (CGSize)normalizeSize
{
    return self.nleModel.normalizeSize;
}

- (void)setNormalizeSize:(CGSize)normalizeSize
{
    self.nleModel.normalizeSize = normalizeSize;
}

- (VEContentSource)contentSource
{
    return self.nle.contentSource;
}

- (void)setContentSource:(VEContentSource)contentSource
{
    self.nle.contentSource = contentSource;
}

#pragma mark - 滤镜

- (void)removeAllPitchAudioFilters
{
    [self.nleModel removeAllVoiceChangerFilters];
}

- (void)clearAllEffectAndTimeMachine
{
    [self.nleModel removeAllSpecialEffects];
}

- (void)clearReverseAsset
{
    [self.nle clearEditoReverseAsset];
}

#pragma mark - 额外字段

- (NSDictionary<NSString *,id<NSCoding>> *)extraInfo
{
    return self.nleModel.extraInfo;
}

- (void)setExtraInfo:(NSDictionary<NSString *,id<NSCoding>> *)extraInfo
{
    self.nleModel.extraInfo = extraInfo;
}

- (NSString *)extraMetaInfo
{
    return self.nle.extraMetaInfo;
}

- (void)setExtraMetaInfo:(NSString *)extraMetaInfo
{
    self.nle.extraMetaInfo = extraMetaInfo;
}

- (NSString *)getReverseVideoDataMD5
{
    return [[[self.nleModel slotsWithType:NLETrackVIDEO] acc_map:^id _Nonnull(NLETrackSlot_OC * _Nonnull obj) {
        NSString *videoURL = obj.videoSegment.videoFile.resourceFile;
        NSString *clipInfo = NSStringFromIESMMVideoDataClipRange(obj.videoClipRange);
        NSString *rotationInfo = [@(obj.assetRotationInfo.integerValue) stringValue];
        return [@[videoURL, clipInfo, rotationInfo] componentsJoinedByString:@":"];
    }] componentsJoinedByString:@"-"];
}

#pragma mark - 照片电影

- (NSDictionary<AVAsset *,NSURL *> *)photoAssetsInfo
{
    return [[[self.nleModel slotsWithType:NLETrackVIDEO]
             acc_reduce:[NSMutableDictionary dictionary]
             reducer:^id _Nullable(NSMutableDictionary *_Nullable preValue, NLETrackSlot_OC * _Nonnull obj) {
        if ([[[obj segment] getResNode] resourceType] == NLEResourceTypeImage) {
            AVAsset *asset = [self.nle assetFromSlot:obj];
            if (asset) {
                NSURL *url = [NSURL fileURLWithPath:[obj.segment getResNode].acc_path];
                asset.frameImageURL = url;
                preValue[asset] = url;
            }
        }
        return preValue;
    }] copy];
}

- (void)setPhotoAssetsInfo:(NSDictionary<AVAsset *,NSURL *> *)photoAssetsInfo
{
    [photoAssetsInfo acc_forEach:^(AVAsset * _Nonnull key, NSURL * _Nonnull obj) {
        [self updatePhotoAssetInfoWithURL:obj asset:key];
    }];
}

- (void)updatePhotoAssetInfoWithURL:(NSURL *)url asset:(AVAsset *)asset
{
    NLETrackSlot_OC *curSlot = [self.nleModel videoSlotOfAsset:asset nle:self.nle];
    
    if (curSlot) {
        asset.frameImageURL = url;
        curSlot.videoSegment.videoFile = [NLEResourceAV_OC videoResourceWithAsset:asset nle:self.nle];
    } else {
        asset.frameImageURL = url;
        if (url) {
            NLETrackSlot_OC *videoTrack = [NLETrackSlot_OC videoTrackSlotWithAsset:asset nle:self.nle];
            [[self.nleModel getMainVideoTrack] addSlotAtEnd:videoTrack];
        }
    }
}

- (void)updatePhotoAssetsImageInfoWithImage:(UIImage *)image asset:(AVAsset *)asset {
    NLETrackSlot_OC *curSlot = [self.nleModel videoSlotOfAsset:asset nle:self.nle];
    
    if (curSlot) {
        AVAsset *nleAsset = [self.nle assetFromSlot:curSlot];
        [self.nle setPhotoAssetsImageInfoWithImage:image asset:nleAsset];
    }
}

- (NSArray<AVAsset *> *)photoMovieAssets
{
    return [[[self.nleModel getMainVideoTrack] slots] acc_compactMap:^id _Nonnull(NLETrackSlot_OC * _Nonnull obj) {
        if (obj.videoSegment.getResNode.resourceType == NLEResourceTypeImage) {
            return [self.nle assetFromSlot:obj];
        }
        return nil;
    }];
}

- (void)setPhotoMovieAssets:(NSArray<AVAsset *> *)photoMovieAssets
{
    // 不需要实现
}

- (BOOL)isNewImageMovie
{
    return [self.nle isNewImageMovie];
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
    [self.nle setImageMovieInfoWithUIImages:images imageShowDuration:imageShowDuration];
}

- (NSDictionary<AVAsset *,IESMediaFilterInfo *> *)movieAnimationType
{
    return [[[self.nleModel slotsWithType:NLETrackVIDEO]
            acc_reduce:[NSMutableDictionary dictionary]
            reducer:^id _Nonnull(id  _Nonnull preValue, NLETrackSlot_OC * _Nonnull next) {
        AVAsset *videoAsset = [self.nle assetFromSlot:next];
        if (videoAsset) {
            preValue[videoAsset] = next.videoTransition;
        }
        return preValue;
    }] copy];
}

- (void)setMovieAnimationType:(NSDictionary<AVAsset *,IESMediaFilterInfo *> *)movieAnimationType
{
    [movieAnimationType acc_forEach:^(AVAsset * _Nonnull key, IESMediaFilterInfo * _Nonnull value) {
        [self updateMovieAnimationTypeWithFilter:value asset:key];
    }];
}

- (void)updateMovieAnimationTypeWithFilter:(IESMediaFilterInfo *)filter asset:(AVAsset *)asset
{
    [self.nleModel videoSlotOfAsset:asset nle:self.nle].videoTransition = filter;
}

#pragma mark - 贴纸

- (NSArray<IESInfoSticker *> *)infoStickers
{
    return [self.nle getInfoStickers];
}

- (void)setInfoStickers:(NSArray<IESInfoSticker *> *)infoStickers
{
    // 移除老的贴纸
    [self.nleModel removeTracksWithType:NLETrackSTICKER];
    
    NSMutableDictionary<NSNumber *, NSString *> *stickerChangeMap =
    [NSMutableDictionary<NSNumber *, NSString *> dictionaryWithCapacity:infoStickers.count];
    // 添加新的贴纸
    [infoStickers acc_forEach:^(IESInfoSticker * _Nonnull obj) {
        NLETrackSlot_OC *trackSlot = [NLETrackSlot_OC stickerTrackSlotWithSticker:obj draftFolder:self.nle.draftFolder];
        if (!trackSlot) {
            return;
        }
        
        trackSlot.layer = [self.nleModel getLayerMax] + 1;
        NLETrack_OC *track = [[NLETrack_OC alloc] init];
        [track addSlot:trackSlot];
        [self.nleModel addTrack:track];
        [self.nle setUserInfo:obj.userinfo forStickerSlot:[trackSlot getName]];
        stickerChangeMap[@(obj.stickerId)] = trackSlot.name;
    }];
    self.stickerChangeMap = stickerChangeMap;
}

- (IESVideoAddEdgeData *)infoStickerAddEdgeData
{
    return self.nleModel.infoStickerAddEdgeData;
}

- (void)setInfoStickerAddEdgeData:(IESVideoAddEdgeData *)infoStickerAddEdgeData
{
    self.nleModel.infoStickerAddEdgeData = infoStickerAddEdgeData;
}

- (void)setSticker:(NSInteger)stickerId
           offsetX:(CGFloat)offsetX
           offsetY:(CGFloat)offsetY
{
    NSString* slotId = [self.nle slotIdForSticker:stickerId];
    if (ACC_isEmptyString(slotId)) {
        return;
    }
    
    NLETrackSlot_OC *trackSlot = [[self nleModel] slotOfName:slotId withTrackType:NLETrackSTICKER];
    [trackSlot setStickerOffset:CGPointMake(offsetX, offsetY) normalizeConverter:self.nle.normalizeConverter];
}

#pragma mark - 音频静音

- (void)awe_muteOriginalAudio
{
    [[self.nleModel slotsWithType:NLETrackVIDEO] acc_forEach:^(NLETrackSlot_OC * _Nonnull item) {
        item.videoSegment.volume = 0;
    }];
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)awe_setMutedWithAsset:(AVAsset *)asset
{
    NLETrackSlot_OC *videoTrackSlot = [self.nleModel videoSlotOfAsset:asset nle:self.nle];
    
    if (videoTrackSlot) {
        videoTrackSlot.videoSegment.volume = 0;
        [self.nle.editor acc_commitAndRender:nil];
    }
}

- (void)muteMicrophone:(BOOL)enable
{
    self.isMicMuted = enable;
}

#pragma mark - 音视频比较

- (BOOL)acc_audioAssetEqualTo:(id<ACCEditVideoDataProtocol>)anotherVideoData
{
    NSArray<NLETrack_OC *> *audioTracks = [self.nleModel tracksWithType:NLETrackAUDIO];
    ACCNLEEditVideoData *nleVideoData = acc_videodata_take_nle(anotherVideoData);
    NSArray<NLETrack_OC *> *anotherAudioTracks = [nleVideoData.nleModel tracksWithType:NLETrackAUDIO];
    
    if (audioTracks.count != anotherAudioTracks.count) {
        return NO;
    }
    
    return [audioTracks acc_all:^BOOL(NLETrack_OC * _Nonnull track) {
        return [anotherAudioTracks acc_any:^BOOL(NLETrack_OC * _Nonnull anotherTrack) {
            if (anotherTrack.slots.count != track.slots.count) {
                return NO;
            }
            return [track.slots acc_allWithIndex:^BOOL(NLETrackSlot_OC * _Nonnull trackSlot, NSInteger index) {
                NSString *resourceFile = [[[trackSlot audioSegment] audioFile] acc_path];
                if (!resourceFile) { return NO; }
                return [[[[anotherTrack.slots[index] audioSegment] audioFile] acc_path] isEqualToString:resourceFile];
            }];
        }];
    }];
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
    NLETrackSlot_OC *trackSlot = [self.nleModel audioSlotOfAsset:asset nle:self.nle];
    if (trackSlot) {
        return [trackSlot audioClipRange];
    }
    return nil;
}

- (Float64)acc_totalVideoDuration
{
    return [self.videoData acc_totalVideoDuration];
}

- (BOOL)acc_videoAssetEqualTo:(id<ACCEditVideoDataProtocol>)anotherVideoData
{
    NSArray<NLETrack_OC *> *videoTracks = [self.nleModel tracksWithType:NLETrackVIDEO];
    ACCNLEEditVideoData *nleVideoData = acc_videodata_take_nle(anotherVideoData);
    NSArray<NLETrack_OC *> *anotherVideoTracks = [nleVideoData.nleModel tracksWithType:NLETrackVIDEO];
    
    if (videoTracks.count != anotherVideoTracks.count) {
        return NO;
    }
    
    return [videoTracks acc_all:^BOOL(NLETrack_OC * _Nonnull track) {
        return [anotherVideoTracks acc_any:^BOOL(NLETrack_OC * _Nonnull anotherTrack) {
            if (anotherTrack.slots.count != track.slots.count) {
                return NO;
            }
            return [track.slots acc_allWithIndex:^BOOL(NLETrackSlot_OC * _Nonnull trackSlot, NSInteger index) {
                NSString *resourceFile = [[[trackSlot videoSegment] videoFile] acc_path];
                if (!resourceFile) { return NO; }
                return [[[[anotherTrack.slots[index] videoSegment] videoFile] acc_path] isEqualToString:resourceFile];
            }];
        }];
    }];
}

#pragma mark - effectOperationManager 封装

- (HTSPlayerTimeMachineType)effect_timeMachineType
{
    NLETrackSlot_OC *timeSlot = [[self nleModel] timeEffectTrack].slots.firstObject;
    return [self htsTimeMachineTypeFromNLETimeEffectType:timeSlot.timeEffect.timeEffectType];
}

- (void)setEffect_timeMachineType:(HTSPlayerTimeMachineType)timeMachineType
{
    NLETrack_OC *timeEffectTrack = [[self nleModel] timeEffectTrack];
    NLETrackSlot_OC *timeSlot = timeEffectTrack.slots.firstObject;
    if (!timeSlot) {
        timeSlot = [[NLETrackSlot_OC alloc] init];
        NLESegmentTimeEffect_OC *timeEffectSegment = [[NLESegmentTimeEffect_OC alloc] init];
        timeSlot.segment = timeEffectSegment;
        [timeEffectTrack addSlot:timeSlot];
    }
    timeSlot.timeEffect.timeEffectType = [self nleTimeEffectTypeFromHtsTimeMachineType:timeMachineType];
}

- (HTSPlayerTimeMachineType)htsTimeMachineTypeFromNLETimeEffectType:(NLESegmentTimeEffectType)timeEffectType
{
    switch (timeEffectType) {
        case NLESegmentTimeEffectTypeNormal:
            return HTSPlayerTimeMachineNormal;
        case NLESegmentTimeEffectTypeRewind:
            return HTSPlayerTimeMachineReverse;
        case NLESegmentTimeEffectTypeSlow:
            return HTSPlayerTimeMachineRelativity;
        case NLESegmentTimeEffectTypeRepeat:
            return HTSPlayerTimeMachineTimeTrap;
        default:
            return HTSPlayerTimeMachineNormal;
    }
}

- (NLESegmentTimeEffectType)nleTimeEffectTypeFromHtsTimeMachineType:(HTSPlayerTimeMachineType)timeMachineType
{
    switch (timeMachineType) {
        case HTSPlayerTimeMachineNormal:
            return NLESegmentTimeEffectTypeNormal;
        case HTSPlayerTimeMachineReverse:
            return NLESegmentTimeEffectTypeRewind;
        case HTSPlayerTimeMachineRelativity:
            return NLESegmentTimeEffectTypeSlow;
        case HTSPlayerTimeMachineTimeTrap:
            return NLESegmentTimeEffectTypeRepeat;
        default:
            return NLESegmentTimeEffectTypeNormal;
    }
}

- (AVAsset *)effect_reverseAsset
{
    return self.nle.effect_reverseAsset;
}

- (void)setEffect_reverseAsset:(AVAsset *)effect_reverseAsset
{
    self.nle.effect_reverseAsset = effect_reverseAsset;
}

- (NSArray<IESMMEffectTimeRange *> *)effect_timeRange
{
    return [self.nle.effect_timeRange copy];
}

- (NSArray<IESMMEffectTimeRange *> *)effect_operationTimeRange
{
    CGFloat videoDuration = self.effect_videoDuration;
    NLETrack_OC *effectTrack = [self.nleModel specialEffectTrack];
    NSMutableArray *operationTimeRange = [NSMutableArray array];
    [[effectTrack.slots sortedArrayUsingComparator:^NSComparisonResult(NLETrackSlot_OC * _Nonnull obj1, NLETrackSlot_OC * _Nonnull obj2) {
        return obj1.layer > obj2.layer;
    }] enumerateObjectsUsingBlock:^(NLETrackSlot_OC * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.segment isKindOfClass:[NLESegmentEffect_OC class]]) {
            NSString *rangeID = [self.nle effectRangIDForSlotName:obj.name];
            if (rangeID.length > 0) {
                NLESegmentEffect_OC *effectSegment = (NLESegmentEffect_OC *)obj.segment;
                IESMMEffectTimeRange *effectRange = [[IESMMEffectTimeRange alloc] init];
                effectRange.rangeID = rangeID;
                
                /*
                 应用时光倒流后，从videoData.effectOperationManager.operationTimeRange获取的timerange是倒转前的。
                 1. 比如有时光倒流时，你添加一个[0s~3s]区间的特效，获取的timerange是[(endtime-3s)~(endtime)]
                 2. 比如没有时光倒流时，添加一个[0s~3s]区间的特效，时光倒流后，特效效果会出现在[(endtime-3s)~(endtime)]区间上，
                    但是你获取的timerange 还是[0s~3s]，
                 
                 NLE在这里通过speed的正负表示当前的时间区域是否是倒转后的时间区域。
                 */
                BOOL isReverse = obj.speed < 0;
                effectRange.startTime = isReverse ? videoDuration - CMTimeGetSeconds(obj.endTime): CMTimeGetSeconds(obj.startTime);
                effectRange.endTime = isReverse ? videoDuration - CMTimeGetSeconds(obj.startTime) : CMTimeGetSeconds(obj.endTime);

                effectRange.effectPathId = effectSegment.effectSDKEffect.resourceId;
                effectRange.timeMachineStatus = TIMERANGE_NORMAL;
                effectRange.effectType = 0;
                [operationTimeRange addObject:effectRange];
            }
        }
    }];
    return [operationTimeRange copy];
}

- (void)setEffect_operationTimeRange:(NSArray<IESMMEffectTimeRange *> *)effect_operationTimeRange
{
    NLETrack_OC *effectTrack = [self.nleModel specialEffectTrack];
    for (IESMMEffectTimeRange *timeRange in effect_operationTimeRange) {
        NLEResourceNode_OC *resourceNode_OC = [[NLEResourceNode_OC alloc] init];
        resourceNode_OC.resourceId = timeRange.effectPathId;
        resourceNode_OC.resourceType = NLEResourceTypeEffect;
        
        NLESegmentEffect_OC *effectSegment = [[NLESegmentEffect_OC alloc] init];
        effectSegment.effectSDKEffect = resourceNode_OC;
        effectSegment.effectName = timeRange.effectPathId;
        
        NLETrackSlot_OC *slot = [[NLETrackSlot_OC alloc] init];
        slot.segment = effectSegment;
        slot.layer = effectTrack.slots.count;
        slot.startTime = CMTimeMake(timeRange.startTime * USEC_PER_SEC, USEC_PER_SEC);
        slot.endTime = CMTimeMake(timeRange.endTime * USEC_PER_SEC, USEC_PER_SEC);
        [effectTrack addSlot:slot];
    }
}

- (CGFloat)effect_timeMachineBeginTime
{
    NLETrackSlot_OC *timeSlot = [self.nleModel timeEffectTrack].slots.firstObject;
    if (timeSlot) {
        return CMTimeGetSeconds(timeSlot.startTime);
    } else {
        return 0.f;
    }
}

- (void)setEffect_timeMachineBeginTime:(CGFloat)beginTime
{
    NLETrackSlot_OC *timeSlot = [self.nleModel timeEffectTrack].slots.firstObject;
    if (timeSlot) {
        timeSlot.startTime = CMTimeMake(beginTime * USEC_PER_SEC, USEC_PER_SEC);
    }
}

- (CGFloat)effect_newTimeMachineDuration
{
    NLETrackSlot_OC *timeSlot = [self.nleModel timeEffectTrack].slots.firstObject;
    if (timeSlot) {
        return CMTimeGetSeconds(timeSlot.duration);
    } else {
        return 0.f;
    }
}

- (void)setEffect_newTimeMachineDuration:(CGFloat)duration
{
    NLETrackSlot_OC *timeSlot = [self.nleModel timeEffectTrack].slots.firstObject;
    if (timeSlot) {
        timeSlot.duration = CMTimeMake(duration * USEC_PER_SEC, USEC_PER_SEC);
    }
}

- (CGFloat)effect_videoDuration
{
    return self.nle.effect_videoDuration;
}

- (NSDictionary *)effect_dictionary
{
    return self.nle.effect_dictionary;
}

- (void)effect_cleanOperation
{
    [self.nle effect_cleanOperation];
}

- (void)effect_reCalculateEffectiveTimeRange
{
    [self.nle effect_reCalculateEffectiveTimeRange];
}

- (CGFloat)effect_currentTimeMachineDurationWithType:(HTSPlayerTimeMachineType)timeMachineType
{
    return [self.nle effect_currentTimeMachineDurationWithType:timeMachineType];
}

- (AVAsset *)acc_videoAssetAtIndex:(NSUInteger)index {
    NSArray<AVAsset *> *videoAssets = self.videoAssets;
    if (index >= videoAssets.count) {
        return nil;
    }
    return videoAssets[index];
}

#pragma mark - Draft

- (BOOL)moveResourceToDraftFolder:(NSString *)draftFolder
{
    // VE 在保存草稿的时候会自动将资源保存到草稿目录内，NLE 也需要这样处理
    return [self.nleModel acc_moveMainResourceToDraftFolder:draftFolder];
}

- (void)acc_fixAudioClipRange
{
    CGFloat totalVideoDuration = CMTimeGetSeconds([[self.nleModel getMainVideoTrack] getMaxEnd]);
    if (totalVideoDuration < 0.01) {
        return;
    }
    
    [[self.nleModel slotsWithType:NLETrackAUDIO] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        CGFloat startTime = CMTimeGetSeconds(obj.audioSegment.timeClipStart);
        CGFloat endTime = CMTimeGetSeconds(obj.audioSegment.timeClipEnd);
        CGFloat audioDuration = CMTimeGetSeconds(obj.audioSegment.audioFile.duration);
        CGFloat maxDuration = MIN(totalVideoDuration, audioDuration);
        
        if ((endTime - startTime) > maxDuration) {
            obj.audioSegment.timeClipEnd = ACCCMTimeMakeSeconds(maxDuration + startTime);
        }
    }];
}

#pragma mark - Prepare

- (void)prepareWithCompletion:(void (^)(void))completion
{
    [self beginEdit];
    [self.nle.editor acc_commitAndRender:^(NSError * _Nullable error) {
        !completion ?: completion();
    }];
}

@end
