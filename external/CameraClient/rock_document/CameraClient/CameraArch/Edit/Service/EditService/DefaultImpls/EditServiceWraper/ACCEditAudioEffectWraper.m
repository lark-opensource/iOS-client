//
//  ACCEditAudioEffectWraper.m
//  CameraClient
//
//  Created by Me55a on 2020/9/7.
//

#import "ACCEditAudioEffectWraper.h"

#import <CreativeKit/ACCMacros.h>
#import <NLEPlatform/NLEInterface.h>
#import <TTVideoEditor/VEAudioEffectPreprocessor.h>
#import <TTVideoEditor/IESMMAudioFilter.h>
#import <TTVideoEditor/IESMMTransProcessData.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>

#import "VEEditorSession+ACCAudioEffect.h"
#import "AWERepoVideoInfoModel.h"
#import "ACCEditVideoDataDowngrading.h"
#import "ACCEditCompileSession.h"
#import <CreationKitArch/IESEffectModel+ACCSticker.h>

@interface ACCEditAudioEffectWraper () <ACCEditBuildListener>

@property (nonatomic, weak) VEEditorSession *player;

@property (nonatomic, weak) NLEInterface_OC *nle; // work around, seperate in fure

@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, strong, readonly) HTSVideoData *videoData;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary<AVAsset *, NSString *> *> *infoMapCache;
@property (nonatomic, assign) BOOL isTemporyEffectOn;

@property (nonatomic, strong) ACCEditCompileSession *compileSession;

@end

@implementation ACCEditAudioEffectWraper

- (void)setEditSessionProvider:(id<ACCEditSessionProvider>)editSessionProvider
{
    [editSessionProvider addEditSessionListener:self];
}

#pragma mark - ACCEditBuildListener

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editSession
{
    self.player = editSession.videoEditSession;
    self.infoMapCache = [NSMutableDictionary dictionary];
}

// work around
- (void)onNLEEditorInit:(NLEInterface_OC *)editor
{
    self.nle = editor;
}

- (void)setupPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel
{
    self.publishModel = publishViewModel;
}

- (HTSVideoData *)videoData
{
    return acc_videodata_make_hts(self.publishModel.repoVideoInfo.video);
}

- (void)applyAudioEffectWithEffectPath:(NSString *)effectPath
                      inPreProcessInfo:(nullable NSString *)infoData
                               inBlock:(nonnull void (^)(NSString * _Nonnull, NSError * _Nonnull))block
{
    IESMMEffectStickerInfo *info = [[IESMMEffectStickerInfo alloc] init];
    info.path = effectPath;
    
    [self.player acc_applyAudioEffectWithVideoData:self.videoData audioEffectInfo:info inPreProcessInfo:infoData inBlock:block];
}

- (float)bgmVolume {
    return [self.player acc_bgmVolume];
}

- (void)setVolumeForAudio:(float)volume
{
    [self.player acc_setVolumeForAudio:volume videoData:self.videoData];
}

- (void)setVolumeForVideo:(float)volume
{
    [self.player acc_setVolumeForVideo:volume videoData:self.videoData];
}

- (void)setVolumeForVideoMainTrack:(float)volume {
    [self.player acc_setVolumeForVideo:volume videoData:self.videoData];
}

- (void)setVolumeForVideoSubTrack:(float)volume
{
    [self.player acc_setVolumeForVideoSubTrack:volume videoData:self.videoData];
}

- (void)setVolumeForCutsameVideo:(float)volume
{
    // NLE 剪同款逻辑，不实现
}

- (void)setAudioClipRange:(IESMMVideoDataClipRange *)range forAudioAsset:(AVAsset *)asset
{
    if (range.durationSeconds == 0) {
        range.durationSeconds = CMTimeGetSeconds(asset.duration);
    }
    [self.player setAudioClipRange:range forAudioAsset:asset];
}

- (void)refreshAudioPlayer
{
    [self.player refreshAudioPlayer];
}

- (void)hotAppendKaraokeAudioAsset:(AVAsset *)asset withRange:(IESMMVideoDataClipRange *)clipRange
{
    [self hotAppendAudioAsset:asset withRange:clipRange];
}

- (void)hotAppendTextReadAudioAsset:(AVAsset *)asset withRange:(IESMMVideoDataClipRange *)clipRange
{
    [self hotAppendAudioAsset:asset withRange:clipRange];
}

- (void)hotAppendAudioAsset:(AVAsset *_Nonnull)asset withRange:(IESMMVideoDataClipRange *_Nonnull)clipRange
{
    if (clipRange.durationSeconds == 0) {
        clipRange.durationSeconds = CMTimeGetSeconds(asset.duration);
    }
    [self.player hotAppendAudioAsset:asset withRange:clipRange];
}

- (void)hotRemoveAudioAssests:(NSArray<AVAsset *> *)assets
{
    [self.player hotRemoveAudioAssests:assets];
}

- (void)setVolume:(CGFloat)volume forAudioAssets:(NSArray<AVAsset *> * _Nonnull)assets
{
    [self.player setVolume:volume forAudioAssets:assets];
}

- (void)setVolume:(float)volume
{
    [self.player setPlayerVolume:volume];
}

- (void)setAudioFilter:(IESMMAudioFilter *)filter forAudioAssets:(NSArray<AVAsset *> *_Nonnull)assets
{
    [self.player setAudioFilter:filter forAudioAssets:assets];
}

- (void)setAudioFilter:(IESMMAudioFilter *)filter forVideoAssets:(NSArray<AVAsset *> *_Nonnull)assets
{
    [self.player setAudioFilter:filter forVideoAssets:assets];
}

#pragma mark - Setter & Getter

- (void)setIsEffectPreprocessing:(BOOL)isEffectPreprocessing
{
    self.player.acc_isEffectPreprocessing = isEffectPreprocessing;
}

- (BOOL)isEffectPreprocessing
{
    return self.player.acc_isEffectPreprocessing;
}

- (void)setHadRecoveredVoiceEffect:(BOOL)hadRecoveredVoiceEffect
{
    self.player.acc_hadRecoveredVoiceEffect = hadRecoveredVoiceEffect;
}

- (BOOL)hadRecoveredVoiceEffect
{
    return self.player.acc_hadRecoveredVoiceEffect;
}

- (void)setBgmAsset:(AVAsset *)bgmAsset
{
    self.player.acc_bgmAsset = bgmAsset;
}

- (AVAsset *)bgmAsset
{
    return self.player.acc_bgmAsset;
}

- (void)mute:(BOOL)mute
{
    [self.player setPlayerVolume:mute ? 0 : 1];
    self.player.bgmVolume = mute ? 0 : 1;
    self.player.videoVolume = mute ? 0 : 1;
}

- (void)setBGM:(nonnull NSURL *)url start:(NSTimeInterval)startTime duration:(NSTimeInterval)duration repeatCount:(NSInteger)repeatCount completion:(nonnull void (^)(AVAsset * _Nonnull))completion
{
    AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:url options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
    __block AVAsset *oldBgmAsset = self.player.acc_bgmAsset;
    if (oldBgmAsset) {
        // 音乐拍摄进入编辑页初始化，config bgmAsset的时候还没有调用saveDraft，
        // 导致bgmAsset此时还不在draft目录中而是在AWEResource中，这里需要处理
        [self.publishModel.repoVideoInfo.video.audioAssets enumerateObjectsUsingBlock:^(AVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[AVURLAsset class]] && [oldBgmAsset isKindOfClass:[AVURLAsset class]]) {
                if ([((AVURLAsset *)oldBgmAsset).URL.path.lastPathComponent isEqualToString:((AVURLAsset *)obj).URL.path.lastPathComponent]) {
                    oldBgmAsset = obj;
                    *stop = YES;
                }
            }
        }];
        [self.player hotRemoveAudioAssests:@[oldBgmAsset]];
    }
    if (audioAsset) {
        IESMMVideoDataClipRange *range = [IESMMVideoDataClipRange new];
        range.startSeconds = startTime;
        range.durationSeconds = duration;
        range.repeatCount = repeatCount;
        [self.player hotAppendAudioAsset:audioAsset withRange:range];
    }
    self.bgmAsset = audioAsset;
    ACCBLOCK_INVOKE(completion, audioAsset);
}

- (void)setVolume:(CGFloat)volume forVideoAssets:(NSArray<AVAsset *> * _Nonnull)assets
{
    [self.player setVolume:volume forVideoAssets:assets];
}

- (void)removeBGM
{
    [self.player removeBGM];
}

- (void)setBGM:(NSURL *)url startTime:(NSTimeInterval)startTime clipDuration:(NSTimeInterval)clipDuration repeatCount:(NSInteger)repeatCount
{
    [self.player setBGM:url startTime:startTime clipDuration:clipDuration repeatCount:repeatCount];
}

#pragma mark - 多段变声

- (void)updateAudioFilters:(NSArray<IESMMAudioFilter *> *)infos withEffects:(NSArray <IESEffectModel *> *)effects forVideoAssetsWithcompletion:(void (^)(void))completion
{
    // batch preprocess
    dispatch_group_t group = dispatch_group_create();
    NSMutableDictionary<NSString *, NSDictionary<AVAsset *, NSString *> *> *effectInfoMap = [NSMutableDictionary dictionary];
    for (IESEffectModel *effect in effects) {
        dispatch_group_enter(group);
        [self preprocessAssetsForEffect:effect completion:^(NSDictionary<AVAsset *,NSString *> *infoMap) {
            // run in main thread
            if (effect.effectIdentifier != nil && infoMap != nil) {
                effectInfoMap[effect.effectIdentifier] = infoMap;
            }
            dispatch_group_leave(group);
        }];
    }
    
    @weakify(self);
    // update audio filters for assets, one asset at a time
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        @strongify(self);
        // construct filters for video assets
        for (AVAsset *videoAsset in [self videoData].videoAssets) {
            NSArray<IESMMAudioFilter *> *audioFilters = [self updateEffectiveFilters:infos forAsset:videoAsset withEffectInfoMap:effectInfoMap];
            if ([self videoData].videoSoundFilterInfo[videoAsset]) {
                NSArray<IESMMAudioFilter *> *nonPitchFilters = [self nonPitchAudioFiltersInFilters:(NSArray<IESMMAudioFilter *> *)[self videoData].videoSoundFilterInfo[videoAsset]];
                audioFilters = [audioFilters arrayByAddingObjectsFromArray:nonPitchFilters];
            }
            [self.player updateAudioFilterInfos:audioFilters forVideoAssets:@[videoAsset]];
        }
        
        ACCBLOCK_INVOKE(completion);
    });
}

- (void)startAudioFilterPreview:(IESEffectModel *)filter completion:(nonnull void (^)(void))completion
{
    self.isTemporyEffectOn = YES;
    @weakify(self);
    [self preprocessAssetsForEffect:filter completion:^(NSDictionary<AVAsset *,NSString *> *infoMap) {
        @strongify(self);
        if (!self.isTemporyEffectOn) { // check if stopped during preprocessing
            return;
        }
        // construct filters for video assets
        for (AVAsset *videoAsset in [self videoData].videoAssets) {
            IESMMAudioFilter *audioFilter = [self audioFilterForEffect:filter asset:videoAsset infoMap:infoMap];
            [self.player startAudioFilters:audioFilter forVideoAssets:@[videoAsset]];
        }
        ACCBLOCK_INVOKE(completion);
    }];
    
}

- (void)stopFiltersPreview
{
    self.isTemporyEffectOn = NO;
    [self.player stopFiltersforVideoAssets:[self videoData].videoAssets];
}

- (void)getVoiceBalanceDetectConfigForVideoAssets:(BOOL)forVideoAssets completion:(ACCVoiceBlanceDetectCompletionBlock)completion
{
    ACCEditVideoData *videoData = [self.publishModel.repoVideoInfo.video copy];
    videoData.isDetectMode = YES;
   
    NSArray<AVAsset *> *vocalAssets = forVideoAssets ? self.player.videoData.videoAssets : self.player.videoData.bgAudioAssets;
    NSMutableArray<IESMMAudioDetectionConfig *> *detectConfigs = [[NSMutableArray alloc] init];
    [vocalAssets enumerateObjectsUsingBlock:^(AVAsset *obj, NSUInteger idx, BOOL *stop) {
        IESMMAudioDetectionConfig *audioDetectConfig = [[IESMMAudioDetectionConfig alloc] init];
        IESMMAudioFilter *detectFilter = [[IESMMAudioFilter alloc] init];
        detectFilter.type = IESAudioFilterTypeDetection;
        detectFilter.config = audioDetectConfig;
        
        if (forVideoAssets) {
            [videoData updateVideoSoundFilterInfoWithFilters:@[detectFilter] asset:obj];
        } else {
            [videoData updateSoundFilterInfoWithFilters:@[detectFilter] asset:obj];
        }
        [detectConfigs btd_addObject:audioDetectConfig];
    }];
   
    IESMMTransProcessData *config = [[IESMMTransProcessData alloc] init];
    config.enableMultiTrack = YES;
    config.disableInfoSticker = YES;
    config.timeOutPeriod = FLT_MAX;
   
    self.compileSession = [[ACCEditCompileSession alloc] initWithVideoData:videoData config:config effectUnit:nil];
    @weakify(self);
    [self.compileSession transcodeWithCompleteBlock:^(IESMMTranscodeRes * _Nullable result) {
        ACCBLOCK_INVOKE(completion, result, detectConfigs);
        @strongify(self)
        self.compileSession = nil;
    }];
}

#pragma mark - Private Helper

- (void)preprocessAssetsForEffect:(IESEffectModel *)effect completion:(void (^)(NSDictionary<AVAsset *, NSString *> *))completion
{
    if (effect.filePath.length > 0) {
        NSDictionary<AVAsset *,NSString *> *cachedInfoMap = self.infoMapCache[effect.filePath];
        if (cachedInfoMap) {
            completion(cachedInfoMap);
        } else {
            NSArray *assetsToPreprocess = [self videoData].videoAssets;
            @weakify(self);
            [VEAudioEffectPreprocessor preprocessAVAssets:assetsToPreprocess effectPath:effect.filePath inRangeMap:[self videoData].videoTimeClipInfo completion:^(NSDictionary<AVAsset *,NSString *> *infoMap) {
                @strongify(self);
                self.infoMapCache[effect.filePath] = infoMap;
                completion(infoMap);
            }];
        }
    } else {
        completion(nil);
    }
}

- (IESMMAudioFilter *)audioFilterForEffect:(IESEffectModel *)effect asset:(AVAsset *)asset infoMap:(NSDictionary<AVAsset *,NSString *> *)infoMap
{
    IESMMAudioPitchConfigV2 *config = [IESMMAudioPitchConfigV2 new];
    config.effectPath = [self effectPathForEffect:effect];
    config.infoData = infoMap[asset];
    IESMMAudioFilter *audioFilter = [IESMMAudioFilter new];
    audioFilter.config = config.effectPath.length > 0 ? config : nil;
    audioFilter.type = IESAudioFilterTypePitch;
    audioFilter.attachTime = kCMTimeZero;
    return audioFilter;
}

- (NSString *)effectPathForEffect:(IESEffectModel *)effect
{
    if (effect.effectIdentifier) {
        if (effect.localUnCompressPath.length) {
            return effect.localUnCompressPath;
        } else if (effect.downloaded) {
            return effect.filePath;
        }
    }
    return nil;
}

- (NSArray<IESMMAudioFilter *> *)nonPitchAudioFiltersInFilters:(NSArray<IESMMAudioFilter *> *)filters
{
    NSMutableArray *nonPitchAudioFilters = [NSMutableArray new];
    [filters enumerateObjectsUsingBlock:^(IESMMAudioFilter * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.type != IESAudioFilterTypePitch) {
            [nonPitchAudioFilters addObject:obj];
        }
    }];
    return nonPitchAudioFilters;
}

- (NSArray<IESMMAudioFilter *> *)updateEffectiveFilters:(NSArray<IESMMAudioFilter *> *)filters forAsset:(AVAsset *)asset withEffectInfoMap:(NSDictionary<NSString *, NSDictionary<AVAsset *, NSString *> *> *)effectInfoMap
{
    NSMutableArray *assetFilters = [NSMutableArray arrayWithCapacity:filters.count];
    for (IESMMAudioFilter *filter in filters) {
        IESMMAudioFilter *assetFilter = filter.copy;
        IESMMAudioPitchConfigV2 *config = [IESMMAudioPitchConfigV2 new];
        if ([filter.config isKindOfClass:IESMMAudioPitchConfigV2.class]) {
            config.effectPath = ((IESMMAudioPitchConfigV2 *)filter.config).effectPath;
        }
        config.infoData = effectInfoMap[filter.filterId][asset];
        assetFilter.config = config;
        [assetFilters addObject:assetFilter];
    }
    return assetFilters;
}

@end
