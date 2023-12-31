//
//  ACCLVMusicRecoverUtil.m
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2020/12/29.
//

#import "AWERepoCutSameModel.h"
#import "ACCLVAudioRecoverUtil.h"
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import "AWERepoFlowControlModel.h"
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import "AWERepoVideoInfoModel.h"
#import "AWERepoMVModel.h"
#import "ACCEditVideoDataDowngrading.h"
#import <CameraClient/AWERepoDuetModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import <CreationKitArch/ACCRepoStickerModel.h>

#import <CreativeKit/NSArray+ACCAdditions.h>

@implementation ACCLVAudioRecoverUtil

+ (void)recoverAudioIfNeededWithOption:(ACCLVFrameRecoverOption)option publishModel:(AWEVideoPublishViewModel *)publishModel editService:(id<ACCEditServiceProtocol>)editService
{
    AWERepoFlowControlModel *flowControlModel = [publishModel extensionModelOfClass:AWERepoFlowControlModel.class];
    if (option & ACCLVFrameRecoverMusic) {
        [self p_recoverMusicIfNeededWithPublishModel:publishModel editService:editService];
        [self p_recoverVolumeIfNeededWithPublishModel:publishModel editService:editService]; 
        flowControlModel.LVHasRecoverFlag |= ACCLVFrameRecoverMusic;
    }
    if (option & ACCLVFrameRecoverVolume) {
        [self p_recoverVolumeIfNeededWithPublishModel:publishModel editService:editService];
        flowControlModel.LVHasRecoverFlag |= ACCLVFrameRecoverVolume;
    }
    if (option & ACCLVFrameRecoverCutMusic) {
        [self p_recoverMusicRangeIfNeededWithPublishModel:publishModel editService:editService];
        flowControlModel.LVHasRecoverFlag |= ACCLVFrameRecoverCutMusic;
    }
    if (option & ACCLVFrameRecoverVoiceChanger) {
        [self p_recoverVoiceChangerIfNeededWithPublishModel:publishModel editService:editService];
        flowControlModel.LVHasRecoverFlag |= ACCLVFrameRecoverVoiceChanger;
    }
    if (option & ACCLVFrameRecoverTextReading) {
        [self p_recoverTextReadingsIfNeededWithPublishModel:publishModel editService:editService];
        flowControlModel.LVHasRecoverFlag |= ACCLVFrameRecoverTextReading;
    }
}

#pragma mark - Recover Music

+ (void)p_recoverMusicIfNeededWithPublishModel:(AWEVideoPublishViewModel *)publishModel editService:(id<ACCEditServiceProtocol>)editService
{
    if (!publishModel.repoFlowControl.hasRecoveredAudioFragments && (publishModel.repoDraft.isDraft || publishModel.repoDraft.isBackUp)) {
        // 针对旧的草稿数据做数据迁移，目前需要处理的只有配乐，因为老版本没有配音
        if (!publishModel.repoMusic.isLVAudioFrameModel) {
            AVAsset *oldBgmAsset = publishModel.repoVideoInfo.video.audioAssets.firstObject;
            if (oldBgmAsset && !publishModel.repoDuet.isDuet) {
                publishModel.repoMusic.bgmAsset = oldBgmAsset;
            }
        }
        
        if (![publishModel.repoCutSame isNewCutSameOrSmartFilming] && publishModel.repoContext.videoType != AWEVideoTypeKaraoke) {
            if (publishModel.repoDuet.isDuet) {
                // react不要清空.mp4
                NSMutableArray<AVAsset *> *assetsToRemoved = @[].mutableCopy;
                [publishModel.repoVideoInfo.video.audioAssets enumerateObjectsUsingBlock:^(AVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj isKindOfClass:[AVURLAsset class]]) {
                        BOOL isReactedOrDuetVideo = [((AVURLAsset *)obj).URL.path.lastPathComponent hasSuffix:@".mp4"] || [((AVURLAsset *)obj).URL.path.lastPathComponent hasSuffix:@".mov"];
                        if (!isReactedOrDuetVideo) {
                            [assetsToRemoved acc_addObject:obj];
                        }
                    }
                }];
                [publishModel.repoVideoInfo.video removeAudioWithAssets:assetsToRemoved];
            } else {
                // 首先需要清空videoData中的audio数据，这部分是sdk保存的
                publishModel.repoVideoInfo.video.audioTimeClipInfo = @{};
                publishModel.repoVideoInfo.video.audioAssets = @[];
            }
        }
        
        if (publishModel.repoContext.videoType != AWEVideoTypeKaraoke) {
            // 背景音乐，这里需要恢复到player，否则setVolume对bgm不生效
            if (publishModel.repoMV.mvModel && acc_videodata_is_nle(publishModel.repoVideoInfo.video)) {
                [publishModel.repoMV.mvModel addBGMForDraftWithRepository:publishModel];
            } else if (!publishModel.repoDuet.isDuet && [publishModel.repoMusic.bgmAsset isKindOfClass:[AVURLAsset class]]) {
                [self p_replaceAudio:((AVURLAsset *)publishModel.repoMusic.bgmAsset).URL withPublishModel:publishModel editService:editService];
            }
        }
        
        if ([publishModel.repoMusic.bgmAsset isKindOfClass:[AVURLAsset class]]) {
            AWELogToolInfo(AWELogToolTagEdit,
                           @"recoverAudioFragmentInfo: bgmAsset:%@ exist:%@",
                           ((AVURLAsset *)publishModel.repoMusic.bgmAsset).URL.path,
                           [NSFileManager.defaultManager fileExistsAtPath:((AVURLAsset *)publishModel.repoMusic.bgmAsset).URL.path] ? @"YES" : @"NO");
        }
    }
}

+ (void)p_replaceAudio:(NSURL *)url withPublishModel:(AWEVideoPublishViewModel *)publishModel editService:(id<ACCEditServiceProtocol>)editService
{
    AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:url options:@{ AVURLAssetPreferPreciseDurationAndTimingKey: @(YES) }];
    if (!audioAsset) {
        return;
    }
    
    NSTimeInterval playDuration = audioAsset ? CMTimeGetSeconds(audioAsset.duration) : 0;
    NSTimeInterval startSeconds = 0;
    if (publishModel.repoMusic.bgmClipRange.durationSeconds > 0) {
        startSeconds = publishModel.repoMusic.bgmClipRange.startSeconds;
        playDuration = publishModel.repoMusic.bgmClipRange.durationSeconds;
    }
    else if ([publishModel.repoVideoInfo.video totalVideoDuration] > 0) {
        playDuration = [publishModel.repoVideoInfo.video totalVideoDuration];
    }
    else if ([publishModel.repoMusic.music.shootDuration integerValue] > 0) {
        if (ABS(playDuration - [publishModel.repoMusic.music.shootDuration integerValue]) >= 1) {
            playDuration = [publishModel.repoMusic.music.shootDuration floatValue];
        }
    }
    
    [editService.audioEffect setBGM:url start:startSeconds duration:playDuration repeatCount:1 completion:^(AVAsset * _Nullable newBGMAsset) {
        publishModel.repoMusic.bgmAsset = newBGMAsset;
    }];
}

#pragma mark - Recover Volume

+ (void)p_recoverVolumeIfNeededWithPublishModel:(AWEVideoPublishViewModel *)publishModel editService:(id<ACCEditServiceProtocol>)editService
{
    if (publishModel.repoContext.videoType == AWEVideoTypeKaraoke || publishModel.repoDuet.isDuetSing) {
        // K歌和合唱因为有调音面板，音量恢复的逻辑由 component 自己处理。
        // K歌：AWEKaraokeEditComponent -> AWEKaraokeStickerHanlder
        // 合唱：AWEDuetEditComponent
        return;
    }
    if (!publishModel.repoFlowControl.hasRecoveredAudioFragments && (publishModel.repoDraft.isDraft || publishModel.repoDraft.isBackUp)) {
        if (publishModel.repoCutSame.isNewCutSameOrSmartFilming) {
            [editService.audioEffect setVolumeForCutsameVideo:publishModel.repoMusic.voiceVolume];
        } else if (publishModel.repoDuet.isDuet) { // 合拍支持导入多轨只更新主轨音量
            [editService.audioEffect setVolumeForVideoMainTrack:publishModel.repoMusic.voiceVolume];
        } else {
            [editService.audioEffect setVolumeForVideo:publishModel.repoMusic.voiceVolume];
        }
        [editService.audioEffect setVolumeForAudio:publishModel.repoMusic.musicVolume];
    }
}

#pragma mark - Recover Music Range

+ (void)p_recoverMusicRangeIfNeededWithPublishModel:(AWEVideoPublishViewModel *)publishModel editService:(id<ACCEditServiceProtocol>)editService
{
    if (publishModel.repoDuet.isDuetSing) {
        return;
    }
    if (!publishModel.repoFlowControl.hasRecoveredAudioFragments && (publishModel.repoDraft.isDraft || publishModel.repoDraft.isBackUp)) {
        if (!publishModel.repoMusic.isLVAudioFrameModel) {
            AVAsset *oldBgmAsset = publishModel.repoVideoInfo.video.audioAssets.firstObject;
            if (oldBgmAsset && !publishModel.repoDuet.isDuet) {
                IESMMVideoDataClipRange *bgmClipRange = publishModel.repoVideoInfo.video.audioTimeClipInfo[oldBgmAsset];
                if (bgmClipRange) {
                    publishModel.repoMusic.bgmClipRange = bgmClipRange;
                }
            }
        }
        // 恢复背景音乐剪辑
        [editService.audioEffect setAudioClipRange:publishModel.repoMusic.bgmClipRange forAudioAsset:publishModel.repoMusic.bgmAsset];
    }
}

#pragma mark - Recover Voice changer

+ (void)p_recoverVoiceChangerIfNeededWithPublishModel:(AWEVideoPublishViewModel *)publishModel editService:(id<ACCEditServiceProtocol>)editService
{
    if (!publishModel.repoFlowControl.hasRecoveredAudioFragments && (publishModel.repoDraft.isDraft || publishModel.repoDraft.isBackUp)) {
        
    }
}

#pragma mark - Text Readings

+ (void)p_recoverTextReadingsIfNeededWithPublishModel:(AWEVideoPublishViewModel *)publishModel editService:(id<ACCEditServiceProtocol>)editService
{
    if (!publishModel.repoFlowControl.hasRecoveredAudioFragments && (publishModel.repoDraft.isDraft || publishModel.repoDraft.isBackUp) && publishModel.repoContext.videoType != AWEVideoTypeKaraoke) {
        [publishModel.repoSticker.textReadingAssets enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, AVAsset * _Nonnull obj, BOOL * _Nonnull stop) {
            IESMMVideoDataClipRange *readRange = [publishModel.repoSticker.textReadingRanges objectForKey:key];
            if (readRange) {
                [editService.audioEffect hotAppendAudioAsset:obj withRange:readRange];
            }
        }];
    }
}

@end
