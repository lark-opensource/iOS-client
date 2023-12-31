//
//  ACCEditCutMusicViewModel.m
//  Pods
//
//  Created by liyingpeng on 2020/8/7.
//

#import "AWERepoMusicModel.h"
#import "ACCEditCutMusicViewModel.h"
#import "AWEAudioClipFeatureManager.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import <CreationKitArch/ACCMVTemplateInfo.h>
#import <CameraClient/ACCConfigKeyDefines.h>

#import <CameraClient/AWERepoContextModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CreationKitArch/ACCRepoGameModel.h>
#import <CreationKitArch/ACCRepoCutSameModel.h>
#import <CreationKitArch/ACCRepoMVModel.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <IESInject/IESInject.h>

@interface ACCEditCutMusicViewModel ()

@property (nonatomic, strong) RACSubject *checkMusicFeatureToastSubject;
@property (nonatomic, strong) RACSubject *didClickCutMusicButtonSubject;
@property (nonatomic, strong) RACSubject *didDismissPanelSubject;

@property (nonatomic, strong) RACSubject<ACCCutMusicRangeChangeContext *> *cutMusicRangeDidChangeSubject;
@property (nonatomic, strong) RACSubject<ACCCutMusicRangeChangeContext *> *didFinishCutMusicSubject;

@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;

@property (nonatomic, assign) BOOL isProcessingClipMusic;
@property (nonatomic, strong) AVAsset *lastClipAsset;
@property (nonatomic, assign) HTSAudioRange lastClipAudioRange;
@property (nonatomic, assign) NSInteger repeatCount;

@end

@implementation ACCEditCutMusicViewModel

IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
    [_checkMusicFeatureToastSubject sendCompleted];
    [_didClickCutMusicButtonSubject sendCompleted];
    [_didDismissPanelSubject sendCompleted];
    [_cutMusicRangeDidChangeSubject sendCompleted];
    [_didFinishCutMusicSubject sendCompleted];
}

- (BOOL)isClipViewShowing
{
    return self.audioClipFeatureManager.showingAudioClipView;
}

- (void)clipMusic:(HTSAudioRange)range repeatCount:(NSInteger)repeatCount
{
    self.repository.repoMusic.audioRange = range;
    AVAsset *bgm = self.repository.repoMusic.bgmAsset;
    if (!bgm) {
        return;
    }
    if (self.isProcessingClipMusic && self.lastClipAsset == bgm && self.lastClipAudioRange.location == range.location && self.lastClipAudioRange.length == range.length && self.repeatCount == repeatCount) {
        return;
    }
    self.isProcessingClipMusic = YES;
    self.lastClipAsset = bgm;
    self.lastClipAudioRange = range;
    self.repeatCount = repeatCount;

    IESMMVideoDataClipRange *clipRange = [IESMMVideoDataClipRange new];
    clipRange.startSeconds = range.location;
    clipRange.durationSeconds = MIN(range.length, [self.repository.repoMusic.music.shootDuration floatValue]);
    
    //photo to video need to repeat play music when music duration is shorter than video duration, keep other condition unchange at present.
    if (AWEVideoTypePhotoToVideo == self.repository.repoContext.videoType) {
        repeatCount = self.repeatCount > 0 ? self.repeatCount : repeatCount;
    }
    clipRange.repeatCount = repeatCount;
    
    [self.editService.audioEffect setAudioClipRange:clipRange forAudioAsset:bgm];
    self.repository.repoMusic.bgmClipRange = clipRange;
    [self.editService.preview pause];
    @weakify(self);
    [self.editService.preview seekToTime:CMTimeMake(0, 1) completionHandler:^(BOOL finished) {
        @strongify(self);
        [self.editService.preview play];
        self.isProcessingClipMusic = NO;
    }];
}

- (void)clipMusicBeforeAddedIfNeeded:(ACCEditVideoData *)videoData music:(id<ACCMusicModelProtocol>)music asset:(nonnull AVURLAsset *)asset
{
    if ([self p_isEffectMusicMV]) {
        Float64 duration = MIN([self p_appropriateDurationOfMusicModel:music], 60.f);
        HTSAudioRange range = { .location = 0, .length = duration };
        IESMMVideoDataClipRange *clipRange = IESMMVideoDataClipRangeMake(0, duration);
        videoData.audioTimeClipInfo = @{};
        [videoData updateAudioTimeClipInfoWithClipRange:clipRange asset:asset];
        self.repository.repoMusic.audioRange = range;
    }
}

- (void)clipMusicAfterAddedIfNeeded
{
    if ([self p_isEffectMusicMV]) {
        return;
    }
    if (([self.repository.repoContext supportNewEditClip] && self.repository.repoUploadInfo.isAIVideoClipMode)) {
        return;
    }
    Float64 duration = [self p_appropriateDurationOfMusicModel:self.repository.repoMusic.music];
    
    HTSAudioRange range;
    range.location = 0;
    CGFloat totalVideoDuration = [self.repository.repoVideoInfo.video totalVideoDuration];
    if (self.repository.repoVideoInfo.video.effect_timeMachineType != HTSPlayerTimeMachineNormal) {
        totalVideoDuration = [self.repository.repoVideoInfo.video totalVideoDurationAddTimeMachine];
    }
    if (self.repository.repoGame.gameType != ACCGameTypeNone
        || self.repository.repoContext.isMVVideo
        || AWEVideoTypePhotoToVideo == self.repository.repoContext.videoType) {
        range.length = MIN(duration, totalVideoDuration);
    } else {
        let config = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
        CGFloat videoMaxDuration = config.videoMaxSeconds;
        if (self.repository.repoContext.videoSource == AWEVideoSourceAlbum) {
            videoMaxDuration = config.videoUploadMaxSeconds;
        } else if (ACCConfigBool(kConfigBool_tools_remote_resource_fix_key) && self.repository.repoContext.videoSource == AWEVideoSourceRemoteResource) {
            videoMaxDuration = config.videoUploadMaxSeconds;
        }
        if (self.repository.repoContext.videoType == AWEVideoTypeQuickStoryPicture) {
            videoMaxDuration = totalVideoDuration;
        }

        range.length = MIN(MIN(videoMaxDuration, duration), totalVideoDuration);
    }
    NSInteger repeatCount = -1;
    if ([self.repository.repoMusic shouldEnableMusicLoop:totalVideoDuration]) {
        CGFloat musicShootDuration = [self.repository.repoMusic.music.shootDuration floatValue];
        if (!ACC_FLOAT_EQUAL_ZERO(musicShootDuration)) {
            repeatCount = ceil(totalVideoDuration / musicShootDuration);
        }
    }
    [self clipMusic:range repeatCount:repeatCount];
}

- (void)sendCheckMusicFeatureToastSignal
{
    [self.checkMusicFeatureToastSubject sendNext:nil];
}

- (void)sendDidClickCutMusicButtonSignal
{
    [self.didClickCutMusicButtonSubject sendNext:nil];
}

- (void)sendDidDismissPanelSignal
{
    [self.didDismissPanelSubject sendNext:nil];
}

- (void)sendCutMusicRangeDidChangeSignal:(ACCCutMusicRangeChangeContext *)context
{
    [self.cutMusicRangeDidChangeSubject sendNext:context];
}

- (void)sendDidFinishCutMusicSignal:(ACCCutMusicRangeChangeContext *)context
{
    [self.didFinishCutMusicSubject sendNext:context];
}

#pragma - mark Private

- (Float64)p_appropriateDurationOfMusicModel:(id<ACCMusicModelProtocol>)music
{
    AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:music.loaclAssetUrl options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
    Float64 duration = CMTimeGetSeconds(audioAsset.duration);
    let config = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
    if (music.shootDuration && [music.shootDuration floatValue] > config.videoMinSeconds) {
        if (ABS(duration - [music.shootDuration integerValue]) >= 1) {
            duration = MIN(duration, [music.shootDuration floatValue]);
        }
    } else if (duration > config.musicMaxSeconds) {
        duration = config.musicMaxSeconds;
    }
    return duration;
}

- (BOOL)p_isEffectMusicMV
{
    BOOL isClassicalMV = self.repository.repoCutSame.isClassicalMV; // 经典影集
    BOOL isFromShootEntranceMV = AWEVideoTypePhotoToVideo == self.repository.repoContext.videoType; // 点+进行拍摄之后的MV
    BOOL hasConfigEffectMusic = AWEMVTemplateTypeMusicEffect == self.repository.repoMV.mvTemplateType; // 模型配置了动效音乐
    
    return hasConfigEffectMusic && (isClassicalMV || isFromShootEntranceMV);
}

#pragma - mark Getters

- (RACSignal *)checkMusicFeatureToastSignal
{
    return self.checkMusicFeatureToastSubject;
}

- (RACSubject *)checkMusicFeatureToastSubject
{
    if (!_checkMusicFeatureToastSubject) {
        _checkMusicFeatureToastSubject = [RACSubject subject];
    }
    return _checkMusicFeatureToastSubject;
}

- (RACSignal *)didClickCutMusicButtonSignal
{
    return self.didClickCutMusicButtonSubject;
}

- (RACSubject *)didClickCutMusicButtonSubject
{
    if (!_didClickCutMusicButtonSubject) {
        _didClickCutMusicButtonSubject = [RACSubject subject];
    }
    return _didClickCutMusicButtonSubject;
}

- (RACSignal *)didDismissPanelSignal
{
    return self.didDismissPanelSubject;
}

- (RACSubject *)didDismissPanelSubject
{
    if (!_didDismissPanelSubject) {
        _didDismissPanelSubject = [RACSubject subject];
    }
    return _didDismissPanelSubject;
}

- (RACSignal<ACCCutMusicRangeChangeContext *> *)cutMusicRangeDidChangeSignal
{
    return self.cutMusicRangeDidChangeSubject;
}

- (RACSubject<ACCCutMusicRangeChangeContext *> *)cutMusicRangeDidChangeSubject
{
    if (!_cutMusicRangeDidChangeSubject) {
        _cutMusicRangeDidChangeSubject = [RACSubject subject];
    }
    return _cutMusicRangeDidChangeSubject;
}

- (RACSignal<ACCCutMusicRangeChangeContext *> *)didFinishCutMusicSignal
{
    return self.didFinishCutMusicSubject;
}

- (RACSubject<ACCCutMusicRangeChangeContext *> *)didFinishCutMusicSubject
{
    if (!_didFinishCutMusicSubject) {
        _didFinishCutMusicSubject = [RACSubject subject];
    }
    return _didFinishCutMusicSubject;
}

@end
