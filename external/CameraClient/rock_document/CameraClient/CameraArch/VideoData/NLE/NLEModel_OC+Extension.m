//
//  NLEModel_OC+Extension.m
//  CameraClient-Pods-Aweme
//
//  Created by geekxing on 2021/1/19.
//

#import "NLEModel_OC+Extension.h"
#import "NLETrack_OC+Extension.h"
#import "NLETrackSlot_OC+Extension.h"
#import "NLEResourceAV_OC+Extension.h"
#import "NLEFilter_OC+Extension.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <objc/runtime.h>
#import "NLEFilter_OC+Extension.h"
#import "ACCNLEBundleResource.h"

#import <TTVideoEditor/IESVideoAddEdgeData.h>
#import <TTVideoEditor/IESMMAudioFilter.h>
#import <TTVideoEditor/IESMMCanvasConfig.h>

BOOL NLEPreviewEdgeEqual(IESVideoAddEdgeData *l, IESVideoAddEdgeData *r)
{
    if (l == r) {
        return YES;
    }
    
    if (![l isKindOfClass:[IESVideoAddEdgeData class]] ||
        ![r isKindOfClass:[IESVideoAddEdgeData class]]) {
        return NO;
    }
    
    return l.red == r.red && l.green == r.green && l.blue == r.blue && l.alpha == r.alpha &&
        l.addEdgeMode == r.addEdgeMode &&
        CGSizeEqualToSize(l.targetFrameSize, r.targetFrameSize) &&
        CGRectEqualToRect(l.videoFrameRect, r.videoFrameRect);
}

@implementation NLEModel_OC (Extension)

- (NLETrack_OC *)getMainVideoTrack {
    NLETrack_OC *mainTrack = [[self getTracks] acc_match:^BOOL(NLETrack_OC * _Nonnull item) {
        return item.isMainTrack;
    }];
    
    if (!mainTrack) {
        mainTrack = [[NLETrack_OC alloc] init];
        mainTrack.layer = 0;
        mainTrack.mainTrack = YES;
        [self addTrack:mainTrack];
    }
    
    return mainTrack;
}

- (NLETrack_OC *)getSubVideoTrack  {
    NSArray<NLETrack_OC *> *videoSubTracks = [[self getTracks] acc_filter:^BOOL(NLETrack_OC * _Nonnull item) {
        return ([item getTrackType] == NLETrackVIDEO || item.extraTrackType == NLETrackVIDEO) && item.isVideoSubTrack && !item.isMainTrack;
    }];
    
    if (videoSubTracks.count > 0) { // 暂时只支持一条副轨道
        return videoSubTracks.firstObject;
    } else {
        NLETrack_OC *subTrack = [[NLETrack_OC alloc] init];
        subTrack.layer = 1;
        subTrack.isVideoSubTrack = YES;
        [self addTrack:subTrack];
        return subTrack;
    }
}

- (NLETrack_OC *)specialEffectTrack
{
    NSArray <NLETrack_OC *> *tracks = [self tracksWithType:NLETrackEFFECT];
    NLETrack_OC __block *specialEffectTrack = nil;
    
    [tracks enumerateObjectsUsingBlock:^(NLETrack_OC * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isSpecialEffectTrack) {
            specialEffectTrack = obj;
            *stop = YES;
        }
    }];
    
    if (specialEffectTrack == nil) {
        specialEffectTrack = [[NLETrack_OC alloc] init];
        specialEffectTrack.extraTrackType = NLETrackEFFECT;
        specialEffectTrack.isSpecialEffectTrack = YES;
        [self addTrack:specialEffectTrack];
    }
    
    return specialEffectTrack;
}

- (NLETrack_OC *)timeEffectTrack
{
    NSArray <NLETrack_OC *> *tracks = [self tracksWithType:NLETrackEFFECT];
    NLETrack_OC __block *oneTrack = nil;
    
    [tracks enumerateObjectsUsingBlock:^(NLETrack_OC * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isTimeEffectTrack) {
            oneTrack = obj;
            *stop = YES;
        }
    }];
    
    if (oneTrack == nil) {
        oneTrack = [[NLETrack_OC alloc] init];
        oneTrack.extraTrackType = NLETrackEFFECT;
        oneTrack.isTimeEffectTrack = YES;
        [self addTrack:oneTrack];
    }
    
    return oneTrack;
}

- (NLETrack_OC *)bgAudioAssetTrack
{
    NLETrack_OC *track = [[self tracksWithType:NLETrackAUDIO] acc_match:^BOOL(NLETrack_OC * _Nonnull item) {
        return item.slots.firstObject.audioSegment.audioFile.resourceType == NLEResourceTypeKaraokeUserAudio;
    }];
    
    return track;
}

- (void)removeAllSpecialEffects
{
    NLETrack_OC *specialEffectTrack = [self specialEffectTrack];
    [self removeTrack:specialEffectTrack];
    
    NLETrack_OC *videoTrack = [self getMainVideoTrack];
    NLETrack_OC *timeEffectTrack = [self timeEffectTrack];
    
    NLESegmentTimeEffect_OC *timeEffect = [[NLESegmentTimeEffect_OC alloc] init];
    timeEffect.timeEffectType = NLESegmentTimeEffectTypeNormal;
    NLETrackSlot_OC *timeSlot = timeEffectTrack.slots.firstObject;
    if (!timeSlot) {
        timeSlot = [[NLETrackSlot_OC alloc] init];
        [timeEffectTrack addSlot:timeSlot];
    }

    timeSlot.segment = timeEffect;
    timeSlot.startTime = CMTimeMake(0 * USEC_PER_SEC, USEC_PER_SEC);
    timeSlot.duration = CMTimeMake(CMTimeGetSeconds(videoTrack.endTime) * USEC_PER_SEC, USEC_PER_SEC);
}

- (NSArray<NLETrack_OC *> *)tracksWithType:(NLETrackType)type {
    NSCParameterAssert(type >= NLETrackNONE && type <= NLETrackMV);
    return [[self getTracks] acc_filter:^BOOL(NLETrack_OC * _Nonnull item) {
        if (type == NLETrackVIDEO) {
            return [item getTrackType] == NLETrackVIDEO ||
                [item getTrackType] == NLETrackMV ||
                item.extraTrackType == NLETrackVIDEO ||
                item.extraTrackType == NLETrackMV;
        }
        return [item getTrackType] == type || item.extraTrackType == type;
    }];
}

- (void)removeTracksWithType:(NLETrackType)type
{
    [[self tracksWithType:type] acc_forEach:^(NLETrack_OC * _Nonnull obj) {
        [self removeTrack:obj];
    }];
}

- (NSArray<NLETrack_OC *> *)subTracksWithType:(NLETrackType)type {
    NSCParameterAssert(type >= NLETrackNONE && type <= NLETrackMV);
    return [[self getTracks] acc_filter:^BOOL(NLETrack_OC * _Nonnull item) {
        return ([item getTrackType] == type || item.extraTrackType == type) && ![item isMainTrack];
    }];
}

- (NLETrack_OC *)addTrackWithLayer:(int)layer {
    NLETrack_OC *track = [[NLETrack_OC alloc] init];
    track.layer = layer;
    track.mainTrack = (layer == 0);
    [self addTrack:track];
    return track;
}

- (NLETrack_OC *)captionStickerTrack
{
    NLETrack_OC *captionStickerTrack = objc_getAssociatedObject(self, @selector(captionStickerTrack));
    
    // NLEModel 首次添加字幕贴纸的时候需要把前序字幕 Track 移除
    // 存草稿的时候会保存字幕 Track，但是草稿恢复之后需要把前序字幕移除
    if (!captionStickerTrack) {
        NLETrack_OC *track = [[self tracksWithType:NLETrackSTICKER] acc_match:^BOOL(NLETrack_OC * _Nonnull item) {
            return item.slots.firstObject.captionSticker != nil;
        }];
        
        if (track) {
            [self removeTrack:track];
        }
        
        captionStickerTrack = [[NLETrack_OC alloc] init];
        objc_setAssociatedObject(self, @selector(captionStickerTrack), captionStickerTrack, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    if (![[self getTracks] containsObject:captionStickerTrack]) {
        [self addTrack:captionStickerTrack];
    }
    
    return captionStickerTrack;
}

- (NLETrackSlot_OC *)slotOfName:(NSString*)slotName withTrackType:(NLETrackType)trackType {
    NSCParameterAssert(trackType >= NLETrackNONE && trackType <= NLETrackMV);
    NSArray<NLETrack_OC *> *tracks = [self tracksWithType:trackType];
    if (tracks.count == 0) {
        tracks = [self getTracks];
    }
    NLETrackSlot_OC *slot;
    for (NLETrack_OC *track in tracks) {
        if ((slot = [track slotOfName:slotName])) {
            return slot;
        }
    }
    return nil;
}

- (NSArray<NLETrackSlot_OC *>*)removeSlots:(NSArray<NLETrackSlot_OC *> *)slots trackType:(NLETrackType)trackType {
    NSCParameterAssert(trackType >= NLETrackNONE && trackType <= NLETrackMV);
    NSArray *tracks = [self tracksWithType:trackType];
    NSArray<NSString *> *slotNames = [slots acc_mapObjectsUsingBlock:^NSString* (NLETrackSlot_OC *obj, NSUInteger idx) {
        return [obj getName];
    }];
    NSMutableArray *slotsToRemove = [NSMutableArray array];
    for (NLETrack_OC *track in tracks) {
        for (NLETrackSlot_OC *slot in track.slots) {
            if ([slotNames containsObject:[slot getName]]) {
                [track removeSlot:slot];
                [slotsToRemove acc_addObject:slot];
            }
        }
        if (trackType == NLETrackVIDEO) {
            if (track.slots.lastObject && track.slots.lastObject.endTransition) {
                track.slots.lastObject.endTransition = nil;
            }
            [track adjustTargetStartTime];
        }
    }
    if (trackType != NLETrackVIDEO) {
        [self removeEmptyTracksForType:trackType];
    }
    return slotsToRemove.copy;
}

- (void)removeEmptyTracksForType:(NLETrackType)type {
    NSArray *tracks = [self tracksWithType:type];
    for (NLETrack_OC *track in tracks) {
        if (track.slots.count == 0) {
            [self removeTrack:track];
        }
    }
}

- (NSArray<NLETrackSlot_OC *> *)slotsWithType:(NLETrackType)type {
    NSMutableArray *arr = [NSMutableArray array];
    for (NLETrack_OC *track in [self tracksWithType:type]) {
        [arr addObjectsFromArray:track.slots];
    }
    return  arr.copy;
}

#pragma mark - Resources

- (NSArray<NLEResourceNode_OC *> *)acc_allResouces
{
    NSMutableArray<NLEResourceNode_OC *> *allResouces = [NSMutableArray<NLEResourceNode_OC *> array];
    [[self getTracks] acc_forEach:^(NLETrack_OC * _Nonnull track) {
        // 剪同款 Track 不处理
        if (track.isCutsame) {
            return;
        }
        
        // 主轨资源
        [allResouces addObjectsFromArray:[[track slots] acc_compactMap:^id _Nonnull(NLETrackSlot_OC * _Nonnull obj) {
            return obj.segment.getResNode;
        }]];
        
        // pin 资源
        [allResouces addObjectsFromArray:[[track slots] acc_compactMap:^id _Nonnull(NLETrackSlot_OC * _Nonnull obj) {
            return obj.pinAlgorithmFile;
        }]];
        
        // 动画资源
        [allResouces addObjectsFromArray:[[track slots] acc_flatMap:^id _Nonnull(NLETrackSlot_OC * _Nonnull obj) {
            return [obj.getVideoAnims acc_compactMap:^id _Nonnull(NLEVideoAnimation_OC * _Nonnull obj) {
                return obj.segmentVideoAnimation.getResNode;
            }];
        }]];
        
        // 转场资源
        [allResouces addObjectsFromArray:[[track slots] acc_compactMap:^id _Nonnull(NLETrackSlot_OC * _Nonnull obj) {
            return obj.endTransition.getResNode;
        }]];
        
        // 滤镜资源
        [allResouces addObjectsFromArray:[[track slots] acc_flatMap:^id _Nonnull(NLETrackSlot_OC * _Nonnull obj) {
            return [obj.getFilter acc_compactMap:^id _Nonnull(NLEFilter_OC * _Nonnull obj) {
                return obj.segmentFilter.getResNode;
            }];
        }]];
        
        // 特效资源
        [allResouces addObjectsFromArray:[[track slots] acc_flatMap:^id _Nonnull(NLETrackSlot_OC * _Nonnull obj) {
            return [obj.getEffect acc_compactMap:^id _Nonnull(NLEEffect_OC * _Nonnull obj) {
                return obj.segmentEffect.getResNode;
            }];
        }]];
        
        // MV 资源
        if ([track isKindOfClass:[NLETrackMV_OC class]]) {
            [allResouces addObject:((NLETrackMV_OC *)track).mv];
        }
    }];
    
    
    return [allResouces copy];
}

- (BOOL)acc_moveMainResourceToDraftFolder:(NSString *)draftFolder
{
    __block BOOL changed = NO;
    [[[self getTracks] acc_flatMap:^(NLETrack_OC * _Nonnull track) {
        // 只移动主轨资源，忽略剪同款,K歌以及音乐资源
        if (track.isCutsame || track.isBGMTrack || track.isKaraokeTrack) {
            return @[];
        } else {
            return [[track slots] acc_compactMap:^id _Nonnull(NLETrackSlot_OC * _Nonnull obj) {
                NSString *filePath = obj.segment.getResNode.acc_path;
                // 对齐VE逻辑，如果是占位黑视频，不做移动
                if ([filePath containsString:@"IESPhoto.bundle/blankown2.mp4"]) {
                    return nil;
                } else {
                    return obj.segment.getResNode;
                }
            }];
        }
    }] acc_forEach:^(id  _Nonnull obj) {
        BOOL moved = [obj acc_movePrivateResouceToDraftFolder:draftFolder];
        if (moved) {
            changed = moved;
        }
    }];
    
    return changed;
}

#pragma mark - Assets

- (NLETrackSlot_OC *)videoSlotOfAsset:(AVAsset *)asset nle:(NLEInterface_OC *)nle
{
    return [[self slotsWithType:NLETrackVIDEO] acc_match:^BOOL(NLETrackSlot_OC * _Nonnull item) {
        return [nle acc_slot:item isRelateWithAsset:asset];
    }];
}

- (NLETrackSlot_OC *)audioSlotOfAsset:(AVAsset *)asset nle:(NLEInterface_OC *)nle
{
    return [[self slotsWithType:NLETrackAUDIO] acc_match:^BOOL(NLETrackSlot_OC * _Nonnull item) {
        return [nle acc_slot:item isRelateWithAsset:asset];
    }];
}

- (NLETrack_OC *)videoTrackOfAsset:(AVAsset *)asset nle:(NLEInterface_OC *)nle
{
    return [[self tracksWithType:NLETrackVIDEO] acc_match:^BOOL(NLETrack_OC * _Nonnull item) {
        return [item.slots acc_any:^BOOL(NLETrackSlot_OC * _Nonnull slot) {
            return [nle acc_slot:slot isRelateWithAsset:asset];
        }];
    }];
}

- (NLETrack_OC *)audioTrackOfAsset:(AVAsset *)asset nle:(NLEInterface_OC *)nle
{
    return [[self tracksWithType:NLETrackAUDIO] acc_match:^BOOL(NLETrack_OC * _Nonnull item) {
        return [item.slots acc_any:^BOOL(NLETrackSlot_OC * _Nonnull slot) {
            return [nle acc_slot:slot isRelateWithAsset:asset];
        }];
    }];
}

#pragma mark - 音量

- (NSString *)bgmURLString
{
    NLETrack_OC *audioTrack = [[self getTracks] acc_match:^BOOL(NLETrack_OC * _Nonnull item) {
        return item.isBGMTrack;
    }];
    // 根据 BGM 生成算法
    return [[[audioTrack.slots.firstObject audioSegment] audioFile] acc_path];
}

- (void)acc_setAudioVolumn:(float)volume forTrackCondition:(BOOL (^)(NLETrack_OC *track))trackCondition
{
    NSArray<NLETrack_OC *> *audioTracks = [[self getTracks] acc_filter:^BOOL(NLETrack_OC * _Nonnull obj) {
        return trackCondition(obj);
    }];
    
    [audioTracks acc_forEach:^(NLETrack_OC * _Nonnull obj) {
        [obj.slots acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
            [[obj audioSegment] setVolume:volume];
        }];
    }];
}

- (void)acc_setVideoVolumn:(float)volume forTrackCondition:(BOOL (^)(NLETrack_OC *track))trackCondition
{
    NSArray<NLETrack_OC *> *videoTracks = [[self getTracks] acc_filter:^BOOL(NLETrack_OC * _Nonnull obj) {
        return obj.extraTrackType == NLETrackVIDEO && trackCondition(obj);
    }];
    
    [videoTracks acc_forEach:^(NLETrack_OC * _Nonnull track) {
        [track.slots acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
            [[obj videoSegment] setVolume:volume];
        }];
    }];
}

- (void)acc_setVideoVolumn:(float)volume forTrackSlotCondition:(BOOL (^)(NLETrackSlot_OC * _Nonnull))trackSlotCondition
{
    NSArray<NLETrackSlot_OC *> *videoTrackSlots =
    [[self slotsWithType:NLETrackVIDEO] acc_filter:^BOOL(NLETrackSlot_OC * _Nonnull obj) {
        return trackSlotCondition(obj);
    }];
    
    [videoTrackSlots acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        [[obj videoSegment] setVolume:volume];
    }];
}

#pragma mark - MV

- (void)replaceMainTrackWithMV:(NLETrackMV_OC *)mvTrack
{
    NLETrack_OC *track = [[self getTracks] acc_match:^BOOL(NLETrack_OC * _Nonnull obj) {
        return obj.isMainTrack;
    }];
    
    if (track) {
        [self removeTrack:track];
    }
    
    [self addTrack:mvTrack];
}

- (NLETrackMV_OC *)mvTrack
{
    NLETrack_OC *track = [[self tracksWithType:NLETrackMV] acc_match:^BOOL(NLETrack_OC * _Nonnull obj) {
        NSAssert(obj.isMainTrack, @"mvTrack should be config for mainTrack");
        return (obj.extraTrackType == NLETrackMV) && obj.isMainTrack;
    }];
    
    return (NLETrackMV_OC *)track;
}

#pragma mark - AudioEffect

- (NSArray<NLEFilter_OC *> *)voiceChangerFilters
{
    return [[[self getMainVideoTrack] filters] acc_filter:^BOOL(NLEFilter_OC * _Nonnull item) {
        return [item isVoiceChangerFilter];
    }];
}

- (void)removeAllVoiceChangerFilters
{
    NSArray *filtersToRemove = [[self voiceChangerFilters] copy];
    for (NLEFilter_OC *filter in filtersToRemove) {
        [[self getMainVideoTrack] removeFilter:filter];
    }
}

- (void)removeAllAudioFiltersForAudioAsset:(BOOL)isAudioAsset
{
    NLETrackType trackType = isAudioAsset ? NLETrackAUDIO : NLETrackVIDEO;
    [[self tracksWithType:trackType] acc_forEach:^(NLETrack_OC * _Nonnull track) {
        [self removeAllAudioFiltersForTrack:track];
    }];
    
}

- (void)setAudioFilters:(NSArray<IESMMAudioFilter *> *)audioFilters
               forTrack:(NLETrack_OC *)track
            draftFolder:(NSString *)draftFolder
{
    [self removeAllAudioFiltersForTrack:track];
    for (IESMMAudioFilter *audioFilter in audioFilters) {
        [self addAudioFilter:audioFilter forTrack:track draftFolder:draftFolder];
    }
}

- (void)removeAudioFilter:(IESMMAudioFilter *)filter forTrack:(NLETrack_OC *)track
{
    NLEFilter_OC *filterToRemove = [track.filters acc_match:^BOOL(NLEFilter_OC * _Nonnull item) {
        return [item isNLEFilterForMMAudioFilter:filter];
    }];
    if (filterToRemove) {
        [track removeFilter:filterToRemove];
    }
}

- (void)setAudioFilter:(IESMMAudioFilter *)audioFilter
              forTrack:(NLETrack_OC *)track
           draftFolder:(NSString *)draftFolder
{
    BOOL isNoneFilter = audioFilter == nil || audioFilter.type == IESAudioFilterTypeNone;
    
    NSMutableArray *filtersToRemove = [NSMutableArray array];
    for (NLEFilter_OC *filter in track.filters) {
        if (isNoneFilter || [filter isNLEFilterForMMAudioFilter:audioFilter]) {
            [filtersToRemove addObject:filter];
        }
    }
    // 对齐VE接口
    // 1.如果是isNoneFilter，则删除这个asset对应的所有音频滤镜
    // 2.如果是非RangeFilter，则删除这个asset对应的同类型的其它filter
    if (isNoneFilter || ![audioFilter isRangeFilter]) {
        for (NLEFilter_OC *filter in filtersToRemove) {
            [track removeFilter:filter];
        }
    }
    if (!audioFilter.config) {
        return;
    }

    [self addAudioFilter:audioFilter forTrack:track draftFolder:draftFolder];
}

- (void)removeAllAudioFiltersForTrack:(NLETrack_OC *)track
{
    [track.filters acc_forEach:^(NLEFilter_OC * _Nonnull obj) {
        if ([obj isAudioFilter]) {
            [track removeFilter:obj];
        }
    }];
}

- (void)addAudioFilter:(IESMMAudioFilter *)audioFilter
              forTrack:(NLETrack_OC *)track
           draftFolder:(NSString *)draftFolder
{
    NLEFilter_OC *nleFilter = [NLEFilter_OC filterFromMMAudioFilter:audioFilter draftFolder:draftFolder];
    if (nleFilter) {
        if (audioFilter.type == IESAudioFilterTypePitch) {
            [[self getMainVideoTrack] addFilter:nleFilter];
        } else {
            [track addFilter:nleFilter];
        }
    }
}
@end

#pragma mark - NLEModel_OC+VEConfig

static NSString *const kIsFastImportExtraKey = @"ios_nle_only_isFastImport";
static NSString *const kIsRecordFromCameraKey = @"ios_nle_only_isRecordFromCamera";
static NSString *const kIsMicMutedKey = @"ios_nle_only_isMicMuted";
static NSString *const kPreferCanvasConfigKey = @"ios_nle_only_preferCanvasConfig";
static NSString *const kMetaRecordInfoKey = @"ios_nle_only_metaRecordInfo";
static NSString *const kDataInfoKey = @"ios_nle_only_dataInfo";
static NSString *const kNormalizeSizeKey = @"ios_nle_only_normalizeSize";
static NSString *const kIdentifierKey = @"ios_nle_only_identifier";
static NSString *const kExtraInfoKey = @"ios_nle_only_extraInfo";
static NSString *const kCanvasSizeKey = @"ios_nle_only_canvasSize";
static NSString *const kPreviewEdgeKey = @"ios_nle_only_previewEdge";
static NSString *const kImportTransformKey = @"ios_nle_only_importTransform";

static NSString *dictToString(NSDictionary *dict) {
    if (dict == nil) {
        return nil;
    }
    
    if (![NSPropertyListSerialization propertyList:dict
                                  isValidForFormat:NSPropertyListBinaryFormat_v1_0]) {
        return nil;
    }
    
    NSError *error = nil;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:dict
                                                              format:NSPropertyListBinaryFormat_v1_0
                                                             options:0
                                                               error:&error];
    if (error) {
        return nil;
    }
    
    NSData *base64Data = [data base64EncodedDataWithOptions:0];
    if (base64Data == nil) {
        return nil;
    }
    
    return [[NSString alloc] initWithData:base64Data encoding:NSUTF8StringEncoding];
}

static NSDictionary *stringToDict(NSString *string) {
    if (string == nil) {
        return nil;
    }
    
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSData *base64DecodedData = [[NSData alloc] initWithBase64EncodedData:data options:0];
    
    if (base64DecodedData == nil) {
        return nil;
    }
    
    NSError *error = nil;
    NSDictionary *dict = [NSPropertyListSerialization propertyListWithData:base64DecodedData
                                                                  options:0
                                                                   format:nil
                                                                    error:&error];
    if (error) {
        return nil;
    }
    return dict;
}

@implementation NLEModel_OC (VEConfig)

- (BOOL)isFastImport
{
    return [[self getExtraForKey:kIsFastImportExtraKey] boolValue];
}

- (void)setIsFastImport:(BOOL)isFastImport
{
    [self setExtra:@(isFastImport).stringValue forKey:kIsFastImportExtraKey];
}

- (BOOL)isRecordFromCamera
{
    return [[self getExtraForKey:kIsRecordFromCameraKey] boolValue];
}

- (void)setIsRecordFromCamera:(BOOL)isRecordFromCamera
{
    [self setExtra:@(isRecordFromCamera).stringValue forKey:kIsRecordFromCameraKey];
}

- (BOOL)isMicMuted
{
    return [[self getExtraForKey:kIsMicMutedKey] boolValue];
}

- (void)setIsMicMuted:(BOOL)isMicMuted
{
    [self setExtra:@(isMicMuted).stringValue forKey:kIsMicMutedKey];
}

- (NSDictionary *)metaRecordInfo
{
    return stringToDict([self getExtraForKey:kMetaRecordInfoKey]);
}

- (void)setMetaRecordInfo:(NSDictionary *)metaRecordInfo
{
    [self setExtra:dictToString(metaRecordInfo) forKey:kMetaRecordInfoKey];
}

- (NSDictionary *)dataInfo
{
    return stringToDict([self getExtraForKey:kDataInfoKey]);
}

- (void)setDataInfo:(NSDictionary *)dataInfo
{
    [self setExtra:dictToString(dataInfo) forKey:kDataInfoKey];
}

- (IESMMCanvasConfig *)preferCanvasConfig
{
    NSString *configString = [self getExtraForKey:kPreferCanvasConfigKey];
    if (configString == nil) {
        return nil;
    }
    return [[IESMMCanvasConfig alloc] initWithDict:stringToDict(configString)];
}

- (void)setPreferCanvasConfig:(IESMMCanvasConfig *)preferCanvasConfig
{
    [self setExtra:dictToString([preferCanvasConfig toDict]) forKey:kPreferCanvasConfigKey];
}

- (CGSize)normalizeSize
{
    return CGSizeFromString([self getExtraForKey:kNormalizeSizeKey]);
}

- (void)setNormalizeSize:(CGSize)normalizeSize
{
    [self setExtra:NSStringFromCGSize(normalizeSize) forKey:kNormalizeSizeKey];
}

- (NSString *)identifier
{
    return [self getExtraForKey:kIdentifierKey];
}

- (void)setIdentifier:(NSString *)identifier
{
    [self setExtra:identifier forKey:kIdentifierKey];
}

- (NSDictionary<NSString *,id<NSCoding>> *)extraInfo
{
    return stringToDict([self getExtraForKey:kExtraInfoKey]);
}

- (void)setExtraInfo:(NSDictionary<NSString *,id<NSCoding>> *)extraInfo
{
    [self setExtra:dictToString(extraInfo) forKey:kExtraInfoKey];
}

- (void)setInfoStickerAddEdgeData:(IESVideoAddEdgeData *)previewEdge
{
    [self setExtra:dictToString(previewEdge.edgeModeDataToDic) forKey:kPreviewEdgeKey];
}

- (IESVideoAddEdgeData *)infoStickerAddEdgeData
{
    if (![self hasExtraForKey:kPreviewEdgeKey]) {
        return nil;
    }
    
    NSDictionary *previewEdgeDic = stringToDict([self getExtraForKey:kPreviewEdgeKey]);
    return [IESVideoAddEdgeData videoEdgeModeDataFromDic:previewEdgeDic];
}

- (CGAffineTransform)importTransform
{
    return CGAffineTransformFromString([self getExtraForKey:kImportTransformKey]);
}

- (void)setImportTransform:(CGAffineTransform)importTransform
{
    [self setExtra:NSStringFromCGAffineTransform(importTransform) forKey:kImportTransformKey];
}

@end
