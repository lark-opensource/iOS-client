//
//  ACCNLEEditAudioEffectWrapper.m
//  CameraClient-Pods-Aweme
//
//  Created by HuangHongsen on 2021/4/12.
//

#import "ACCNLEEditAudioEffectWrapper.h"
#import <CreationKitRTProtocol/ACCEditSessionBuilderProtocol.h>
#import <NLEPlatform/NLENativeDefine.h>
#import <NLEPlatform/NLESegmentAudio+iOS.h>
#import <NLEPlatform/NLETrackSlot+iOS.h>
#import <NLEPlatform/NLETrack+iOS.h>
#import <NLEPlatform/NLEInterface.h>
#import <CreativeKit/ACCMacros.h>

#import "ACCNLEBundleResource.h"
#import "NLETrackSlot_OC+Extension.h"
#import "NLETrack_OC+Extension.h"
#import "NLEModel_OC+Extension.h"
#import "NLEFilter_OC+Extension.h"
#import "NLEEditor_OC+Extension.h"
#import <CreationKitArch/IESEffectModel+ACCSticker.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "ACCNLEEditVideoData.h"
#import <NLEPlatform/NLEAudioSession.h>

@interface ACCNLEEditAudioEffectWrapper()<ACCEditBuildListener>

@property (nonatomic, weak) NLEInterface_OC *nle;

@end

@implementation ACCNLEEditAudioEffectWrapper

@synthesize hadRecoveredVoiceEffect;
@synthesize isEffectPreprocessing;
@synthesize bgmAsset = _bgmAsset;

- (void)setEditSessionProvider:(nonnull id<ACCEditSessionProvider>)editSessionProvider
{
    [editSessionProvider addEditSessionListener:self];
}

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editorSession
{
}

- (void)onNLEEditorInit:(NLEInterface_OC *)editor
{
    self.nle = editor;
}

- (float)bgmVolume
{
    return [[[[self p_getBGMTrack] slots] firstObject] audioSegment].volume;
}

- (void)hotAppendKaraokeAudioAsset:(AVAsset *)asset withRange:(IESMMVideoDataClipRange *)clipRange
{
    [self hotAppendAudioAsset:asset withRange:clipRange isBGM:NO isKaraokeAudio:YES isTextRead:NO];
}

- (void)hotAppendAudioAsset:(AVAsset * _Nonnull)asset withRange:(IESMMVideoDataClipRange * _Nonnull)clipRange
{
    [self hotAppendAudioAsset:asset withRange:clipRange isBGM:NO isKaraokeAudio:NO isTextRead:NO];
}

- (void)hotAppendTextReadAudioAsset:(AVAsset *)asset withRange:(IESMMVideoDataClipRange *)clipRange
{
    [self hotAppendAudioAsset:asset withRange:clipRange isBGM:NO isKaraokeAudio:NO isTextRead:YES];
}

- (void)hotRemoveAudioAssests:(NSArray<AVAsset *> * _Nonnull)assets
{
    NLEModel_OC *model = [self.nle.editor getModel];
    [[model tracksWithType:NLETrackAUDIO] acc_forEach:^(NLETrack_OC * _Nonnull track) {
        BOOL shouldRemove = [assets acc_any:^BOOL(AVAsset * _Nonnull obj) {
            return [self.nle acc_slot:track.slots.firstObject isRelateWithAsset:obj];
        }];
        if (shouldRemove) {
            [model removeTrack:track];
        }
    }];
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)mute:(BOOL)mute
{
    [self.nle setPlayerVolume:mute ? 0 : 1];
    [self setVolumeForAudio:mute ? 0.f : 1.f];
    [self setVolumeForVideo:mute? 0.f : 1.f];
}

- (void)refreshAudioPlayer
{
    [self.nle refreshAudioPlayer];
}

- (void)removeBGM
{
    [self p_removeOldBGM];
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)setAudioClipRange:(IESMMVideoDataClipRange * _Nonnull)range forAudioAsset:(AVAsset * _Nonnull)asset
{
    if (asset == nil) {
        return;
    }
    
    [[[self.nle.editor getModel] slotsWithType:NLETrackAUDIO] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        if (![self.nle acc_slot:obj isRelateWithAsset:asset]) return;
        
        // 音频长度异常的时候调整为视频时长
        if (range.repeatCount == 1 && range.durationSeconds > self.nle.totalVideoDurationAddTimeMachine) {
            range.durationSeconds = self.nle.totalVideoDurationAddTimeMachine;
        } else if (range.durationSeconds == 0) {
            range.durationSeconds = MIN(self.nle.totalVideoDurationAddTimeMachine, CMTimeGetSeconds(asset.duration));
        }
        
        obj.audioClipRange = range;
    }];
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)setBGM:(nonnull NSURL *)newBGMAssetURL start:(NSTimeInterval)startTime duration:(NSTimeInterval)duration repeatCount:(NSInteger)repeatCount completion:(void (^)(AVAsset * _Nullable))completion
{
    AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:newBGMAssetURL options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
    [self p_removeOldBGM];
    if (audioAsset) {
        // NLE 不允许音频超过主视频轨长度，这里剪裁一下
        if (repeatCount == 1 && duration > self.nle.totalVideoDurationAddTimeMachine) {
            duration = self.nle.totalVideoDurationAddTimeMachine;
        }
        
        IESMMVideoDataClipRange *range = [IESMMVideoDataClipRange new];
        range.startSeconds = startTime;
        range.durationSeconds = duration;
        range.repeatCount = repeatCount;
        [self hotAppendAudioAsset:audioAsset withRange:range isBGM:YES isKaraokeAudio:NO isTextRead:NO];
    }
    ACCBLOCK_INVOKE(completion, audioAsset);
}

- (void)setBGM:(NSURL * _Nonnull)url startTime:(NSTimeInterval)startTime clipDuration:(NSTimeInterval)clipDuration repeatCount:(NSInteger)repeatCount
{
    [self setBGM:url start:startTime duration:clipDuration repeatCount:repeatCount completion:^(AVAsset *a){}];
}

- (void)setVolume:(float)volume
{
    [self.nle setPlayerVolume:volume];
}

- (void)setVolume:(CGFloat)volume forAudioAssets:(NSArray<AVAsset *> * _Nonnull)assets
{
    [[self.nle.editor getModel] acc_setAudioVolumn:volume forTrackCondition:^BOOL(NLETrack_OC *track) {
        return [assets acc_any:^BOOL(AVAsset * _Nonnull obj) {
            return [self.nle acc_slot:track.slots.firstObject isRelateWithAsset:obj];
        }];
    }];
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)setVolume:(CGFloat)volume forVideoAssets:(NSArray<AVAsset *> * _Nonnull)assets
{
    [[self.nle.editor getModel] acc_setVideoVolumn:volume forTrackSlotCondition:^BOOL(NLETrackSlot_OC * _Nonnull trackSlot) {
        return [assets acc_any:^BOOL(AVAsset * _Nonnull obj) {
            return [self.nle acc_slot:trackSlot isRelateWithAsset:obj];
        }];
    }];
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)setVolumeForAudio:(float)volume
{
    [[self.nle.editor getModel] acc_setAudioVolumn:volume forTrackCondition:^BOOL(NLETrack_OC *track) {
        return track.isBGMTrack;
    }];
    [self.nle.editor acc_commitAndRender:nil];
}

/// cutsame 会有自己的音频轨道，素材原声是关闭的，这里修改“视频原声”音量，其实修改
/// 的是cutsame 里的音频轨道的音量
/// @param volume float
- (void)setVolumeForCutsameVideo:(float)volume
{
    [[[[self.nle.editor getModel] getTracks] acc_filter:^BOOL(NLETrack_OC * _Nonnull track) {
        return track.isCutsame && [track getTrackType] == NLETrackAUDIO;
    }] acc_forEach:^(NLETrack_OC * _Nonnull track) {
        [track.slots acc_forEach:^(NLETrackSlot_OC * _Nonnull trackSlot) {
            [[trackSlot audioSegment] setVolume:volume];
        }];
    }];
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)setVolumeForVideo:(float)volume
{
    // if add rewind time effect, we will export a single audio from main track
    // and add a new audio track, so if user change volume for rewind video,we
    // should change the audio track volume;
    NLETrack_OC *timeEffectTrack = [[self.nle.editor getModel] timeEffectTrack];
    BOOL hasRewindTimeEffect = timeEffectTrack.slots.firstObject.timeEffect.timeEffectType == NLESegmentTimeEffectTypeRewind;
    
    if (hasRewindTimeEffect) {
        [[self.nle.editor getModel] acc_setAudioVolumn:volume forTrackCondition:^BOOL(NLETrack_OC *track) {
            return [track getTrackType] == NLETrackAUDIO && !track.isBGMTrack;
        }];
    }
    
    [[self.nle.editor getModel] acc_setVideoVolumn:volume forTrackCondition:^BOOL(NLETrack_OC *track) {
        return YES;
    }];
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)setVolumeForVideoMainTrack:(float)volume {
    NLETrack_OC *timeEffectTrack = [[self.nle.editor getModel] timeEffectTrack];
    BOOL hasRewindTimeEffect = timeEffectTrack.slots.firstObject.timeEffect.timeEffectType == NLESegmentTimeEffectTypeRewind;
    
    if (hasRewindTimeEffect) {
        [[self.nle.editor getModel] acc_setAudioVolumn:volume forTrackCondition:^BOOL(NLETrack_OC *track) {
            return [track getTrackType] == NLETrackAUDIO && !track.isBGMTrack;
        }];
    }
    [[self.nle.editor getModel] acc_setVideoVolumn:volume forTrackCondition:^BOOL(NLETrack_OC *track) {
        return track.isMainTrack;
    }];
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)setVolumeForVideoSubTrack:(float)volume
{
    [[self.nle.editor getModel] acc_setVideoVolumn:volume forTrackCondition:^BOOL(NLETrack_OC * _Nonnull track) {
        return track.isVideoSubTrack;
    }];
    [self.nle.editor acc_commitAndRender:nil];
}

#pragma mark - Private helper

- (void)hotAppendAudioAsset:(AVAsset *)asset withRange:(IESMMVideoDataClipRange *)clipRange isBGM:(BOOL)isBGM isKaraokeAudio:(BOOL)isKaraokeAudio isTextRead:(BOOL)isTextRead
{
    if (asset == nil) {
        return;
    }
    
    BOOL containAsset =
    [[[self.nle.editor getModel] tracksWithType:NLETrackAUDIO] acc_any:^BOOL(NLETrack_OC * _Nonnull obj) {
        return [self.nle acc_slot:obj.slots.firstObject isRelateWithAsset:asset];
    }];
    if (containAsset) return;
    
    NLETrackSlot_OC *slot = [NLETrackSlot_OC audioTrackSlotWithAsset:asset nle:self.nle];
    slot.audioClipRange = clipRange;
    slot.layer = [self.nle.editor.model getLayerMax] + 1;
    NLETrack_OC *track = [[NLETrack_OC alloc] init];
    track.isBGMTrack = isBGM;
    track.isTextRead = isTextRead;
    track.isKaraokeTrack = isKaraokeAudio;
    [track addSlot:slot];
    [[self.nle.editor getModel] addTrack:track];
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)p_removeOldBGM
{
    [[self.nle.editor getModel] removeTrack:[self p_getBGMTrack]];
}

#pragma mark - AudioEffects

- (void)applyAudioEffectWithEffectPath:(nullable NSString *)effectPath inPreProcessInfo:(nullable NSString *)infoData inBlock:(nonnull void (^)(NSString * _Nonnull, NSError * _Nonnull))block
{
    if ([[self.nle.editor getModel] voiceChangerFilters].count == 0
        && effectPath == nil) {
        return;
    }
    
    [[self.nle.editor getModel] removeAllVoiceChangerFilters];
    NLEFilter_OC *voiceChangerFilter = [NLEFilter_OC voiceChangerFilterFromEffectPath:effectPath draftFolder:self.nle.draftFolder];
    if (voiceChangerFilter) {
        [[self.nle.editor getModel].getMainVideoTrack addFilter:voiceChangerFilter];
    }
    
    [self.nle.editor acc_commitAndRender:^(NSError * _Nullable error) {
        if (block) {
            NSString *str = nil;
            NSError *error = nil;
            block(str, error);
        }
    }];
}

- (void)updateAudioFilters:(NSArray<IESMMAudioFilter *> *)infos withEffects:(NSArray<IESEffectModel *> *)effects forVideoAssetsWithcompletion:(void (^)(void))completion
{
    [[self.nle.editor getModel] removeAllVoiceChangerFilters];
    for (IESMMAudioFilter *filter in infos) {
        NLEFilter_OC *voiceChangerFilter = [NLEFilter_OC filterFromMMAudioFilter:filter draftFolder:self.nle.draftFolder];
        if (voiceChangerFilter) {
            [voiceChangerFilter setLayer:[self.nle.editor getModel].getMainVideoTrack.filters.count];
            [[[self.nle.editor getModel] getMainVideoTrack] addFilter:voiceChangerFilter];
        }
    }
    [self.nle.editor acc_commitAndRender:^(NSError * _Nullable error) {
        ACCBLOCK_INVOKE(completion);
    }];
}

- (void)startAudioFilterPreview:(IESEffectModel * _Nonnull)filter completion:(void (^)(void))completion
{
    NSString *effectPath = nil;
    if (filter.effectIdentifier) {
        if (filter.localUnCompressPath.length) {
            effectPath = filter.localUnCompressPath;
        } else if (filter.downloaded) {
            effectPath = filter.filePath;
        }
    }
    NLEFilter_OC *voiceChangerFilter = [NLEFilter_OC  voiceChangerFilterFromEffectPath:effectPath draftFolder:self.nle.draftFolder];
    voiceChangerFilter.startTime = CMTimeMake(self.nle.currentPlayerTime * USEC_PER_SEC, USEC_PER_SEC);
    voiceChangerFilter.endTime = voiceChangerFilter.startTime;
    [voiceChangerFilter setLayer:[self.nle.editor getModel].getMainVideoTrack.filters.count];
    ACC_LogDebug(@"start audio startTime=%f|endTime=%f", CMTimeGetSeconds(voiceChangerFilter.startTime), CMTimeGetSeconds(voiceChangerFilter.endTime));
    
    [[self.nle.editor getModel].getMainVideoTrack addFilter:voiceChangerFilter];
    [self.nle.editor doRender:[self.nle.editor commit] completion:^(NSError * _Nonnull renderError) {
        ACCBLOCK_INVOKE(completion);
    }];
}

- (void)stopFiltersPreview
{
    // TODO: 添加多段 example，业务侧需要根据具体场景修改以下实现
    NSArray<NLEFilter_OC *> *filters = [self.nle.editor getModel].getMainVideoTrack.filters;
    for (NLEFilter_OC *filter in filters) {
        if (CMTimeCompare(filter.startTime, filter.endTime) == 0) {
            filter.endTime = CMTimeMake(self.nle.currentPlayerTime * USEC_PER_SEC, USEC_PER_SEC);
            ACC_LogDebug(@"stop audio startTime=%f|endTime=%f|duration=%f",
                         CMTimeGetSeconds(filter.startTime), CMTimeGetSeconds(filter.endTime), CMTimeGetSeconds(filter.duration));
        }
    }
    [self.nle.editor doRender:[self.nle.editor commit] completion:nil];
}

- (void)setAudioFilter:(IESMMAudioFilter * _Nullable)filter forAudioAssets:(NSArray<AVAsset *> * _Nonnull)assets
{
    NLEModel_OC *nleModel = [self.nle.editor getModel];
    for (AVAsset *asset in assets) {
        [nleModel setAudioFilter:filter forTrack:[nleModel audioTrackOfAsset:asset nle:self.nle] draftFolder:self.nle.draftFolder];
    }
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)setAudioFilter:(IESMMAudioFilter * _Nullable)filter forVideoAssets:(NSArray<AVAsset *> * _Nonnull)assets
{
    NLEModel_OC *nleModel = [self.nle.editor getModel];
    for (AVAsset *asset in assets) {
        [nleModel setAudioFilter:filter forTrack:[nleModel videoTrackOfAsset:asset nle:self.nle] draftFolder:self.nle.draftFolder];
    }
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)getVoiceBalanceDetectConfigForVideoAssets:(BOOL)forVideoAssets completion:(ACCVoiceBlanceDetectCompletionBlock)completion
{
    [self.nle.audioSession getVoiceBalanceDetectConfigForVideoAssets:forVideoAssets completion:^(IESMMTranscodeRes * _Nullable result, NSMutableArray<IESMMAudioDetectionConfig *> * _Nonnull detectConfigs) {
            ACCBLOCK_INVOKE(completion, result, detectConfigs);
    }];
}

- (NLEFilter_OC *)existingVoiceChangerFilter
{
    return [[[self.nle.editor getModel] voiceChangerFilters] firstObject];
}

#pragma mark - Priavte

- (NLETrack_OC *)p_getBGMTrack
{
    NLEModel_OC *model = [self.nle.editor getModel];
    NLETrack_OC *bgmTrack = [[model getTracks] acc_match:^BOOL(NLETrack_OC * _Nonnull obj) {
        return obj.isBGMTrack;
    }];
    return bgmTrack;
}

- (AVAsset *)bgmAsset
{
    NLETrack_OC *bgmTrack = [self p_getBGMTrack];
    if (bgmTrack) {
        return [self.nle assetFromSlot:bgmTrack.slots.firstObject];
    }
    return _bgmAsset;
}

- (void)setBgmAsset:(AVAsset *)bgmAsset
{
    _bgmAsset = bgmAsset;
    
    [[[self.nle.editor getModel] getTracks] acc_forEach:^(NLETrack_OC * _Nonnull obj) {
        obj.isBGMTrack = [self.nle acc_slot:obj.slots.firstObject isRelateWithAsset:bgmAsset];
        // see https://bits.bytedance.net/meego/aweme/story/detail/3088635?issueId=3113441#issue_management
        if (!obj.isBGMTrack) {
            AVAsset *slotAsset = [self.nle assetFromSlot:[obj.slots firstObject]];
            if ([slotAsset isKindOfClass:[AVURLAsset class]] && [((AVURLAsset *)bgmAsset).URL.path.lastPathComponent isEqualToString:((AVURLAsset *)slotAsset).URL.path.lastPathComponent]) {
                obj.isBGMTrack = YES;
            }
        }
    }];
}

@end
