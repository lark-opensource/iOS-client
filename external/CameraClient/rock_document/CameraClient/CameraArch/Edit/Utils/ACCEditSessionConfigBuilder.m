//
//  ACCEditSessionConfigBuilder.m
//  CameraClient-Pods-Aweme
//
//  Created by geekxing on 2021/2/24.
//

#import "AWERepoContextModel.h"
#import "AWERepoVideoInfoModel.h"
#import "AWERepoPropModel.h"
#import "ACCEditSessionConfigBuilder.h"
#import <TTVideoEditor/VEEditorSession.h>
#import "ACCEditViewControllerInputData.h"
#import "AWEMVUtil.h"
#import "ACCRepoKaraokeModelProtocol.h"
#import "AWERepoCutSameModel.h"
#import "ACCRepoQuickStoryModel.h"
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/ACCRepoPublishConfigModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import "AWERepoMVModel.h"
#import <CreationKitInfra/ACCConfigManager.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import "ACCConfigKeyDefines.h"
#import "ACCRepoSmartMovieInfoModel.h"
#import "ACCRepoActivityModel.h"
#import <CameraClientModel/ACCVideoCanvasType.h>
#import <CameraClientModel/AWEVideoRecordButtonType.h>
#import "ACCRepoAudioModeModel.h"

@implementation ACCEditSessionConfigBuilder

+ (VEEditorSessionConfig *)editorSessionConfigWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    VEEditorSessionConfig *config = [[VEEditorSessionConfig alloc] init];

    if (publishModel.repoVideoInfo.canvasType != ACCVideoCanvasTypeNone && publishModel.repoVideoInfo.canvasType != ACCVideoCanvasTypeDuet) {
        if (publishModel.repoContext.videoSource == AWEVideoSourceCapture) {
            publishModel.repoVideoInfo.video.isRecordFromCamera = YES;
        }
        if (publishModel.repoPublishConfig.coverImage == nil) {
            publishModel.repoPublishConfig.coverImage = publishModel.repoUploadInfo.toBeUploadedImage;
        }
        
        config.useNewMudule = NO;
        config.isVideoNeedReverse = [publishModel.repoVideoInfo isVideoNeedReverse];
        if (publishModel.repoVideoInfo.canvasType == ACCVideoCanvasTypeSinglePhoto) {//TODO,各场景各自在入口处设置feedType，而不是在后续流程修改
            publishModel.repoContext.feedType = publishModel.repoQuickStory.isAvatarQuickStory || publishModel.repoQuickStory.isNewCityStory ? ACCFeedTypeCanvasPost : ACCFeedTypePhotoToVideo;
            config.enableNoAvplayer = publishModel.repoContext.enableTakePictureOpt;
            config.enablePhotoFirstFrameOpt = publishModel.repoContext.enableTakePictureOpt;
        }
    } else if (publishModel.repoContext.isQuickStoryPictureVideoType || publishModel.repoContext.videoType == AWEVideoTypeStoryPicture) {
        CGFloat duration = ACCConfigDouble(kConfigDouble_story_picture_duration);
        if (publishModel.repoContext.isQuickStoryPictureVideoType) {
            duration = 10.0;
        }
        [publishModel.repoVideoInfo.video removeAllVideoAsset];
        publishModel.repoVideoInfo.video.isRecordFromCamera = YES;
        
        if (publishModel.repoPublishConfig.coverImage == nil) {
            publishModel.repoPublishConfig.coverImage = publishModel.repoUploadInfo.toBeUploadedImage;
        }
        
        UIImage *image = publishModel.repoUploadInfo.toBeUploadedImage ?: [UIImage new];
        [publishModel.repoVideoInfo.video setImageMovieInfoWithUIImages:@[image]
                                                      imageShowDuration:@{
                                                          [NSString stringWithFormat:@"%p", image] : IESMMVideoDataClipRangeMake(0, duration)
                                                      }];
        
        config.useNewMudule = NO;
        config.isVideoNeedReverse = [publishModel.repoVideoInfo isVideoNeedReverse];
        if (publishModel.repoContext.isQuickStoryPictureVideoType) {
            publishModel.repoContext.feedType = ACCFeedTypePhotoToVideo;
        }
    } else if (publishModel.repoCutSame.isClassicalMV || publishModel.repoContext.videoType == AWEVideoTypePhotoToVideo) {
        
        if ([publishModel.repoSmartMovie isSmartMovieMode]) {
            config.enableMultiTrack = YES;
            config.useGlobalEffectGroup = YES;
        } else {
            BOOL shouldConfigMVPlayer = [AWEMVUtil shouldConfigPlayerWithPublishViewModel:publishModel];
            
            if (shouldConfigMVPlayer) {
                [AWEMVUtil preprocessPublishViewModelForMVPlayer:publishModel];
                publishModel.repoVideoInfo.video.notSupportCrossplat = YES;
                config.useNewMudule = YES;
                config.isVideoNeedReverse = NO;
                
                config.mvModel = publishModel.repoMV.mvModel.veMVModel;
                
                if (publishModel.repoMusic.music.loaclAssetUrl) {
                    AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:publishModel.repoMusic.music.loaclAssetUrl
                                                                 options:@{
                                                                           AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)
                                                                           }];
                    NSTimeInterval clipDuration = CMTimeGetSeconds(audioAsset.duration);
                    
                    IESMMVideoDataClipRange *clipRange = [IESMMVideoDataClipRange new];
                    clipRange.startSeconds = 0;
                    clipRange.durationSeconds = MIN(clipDuration, publishModel.repoVideoInfo.video.totalVideoDuration);
                    clipRange.repeatCount = (publishModel.repoVideoInfo.video.totalVideoDuration / clipDuration) + 1;

                    if (publishModel.repoVideoInfo.video.totalVideoDuration > clipDuration && clipDuration > 0) {
                        publishModel.repoMusic.bgmClipRange = clipRange;
                    }
                }
            } else {
                config = nil;
            }
        }
    } else if (publishModel.repoProp.isMultiSegPropApplied) {
        config.useNewMudule = YES;
        config.enableMultiTrack = YES;
        config.useGlobalEffectGroup = YES;
        config.disableEffectGroup = NO;
    } else if (publishModel.repoCutSame.isNewCutSameOrSmartFilming) {
        config = [VEEditorSessionConfig videoTemplateDefaultConfig];
    }  else if (publishModel.repoContext.isKaraokeAudio) {
        id<ACCRepoKaraokeModelProtocol> repoModel = [publishModel extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
        config.useNewMudule = YES;
        config.isVideoNeedReverse = NO;
        config.mvModel = repoModel.mvModel.veMVModel;
        publishModel.repoVideoInfo.video.notSupportCrossplat = YES;
    } else if (publishModel.repoFlowControl.videoRecordButtonType == AWEVideoRecordButtonTypeAudio) {
        config.useNewMudule = YES;
        config.isVideoNeedReverse = NO;
        config.mvModel = publishModel.repoAudioMode.mvModel.veMVModel;
        publishModel.repoVideoInfo.video.notSupportCrossplat = YES;
    } else if (publishModel.repoContext.videoType == AWEVideoTypeNewYearWish) {
        config.useNewMudule = YES;
        config.isVideoNeedReverse = NO;
        config.mvModel = publishModel.repoActivity.mvModel.veMVModel;
        publishModel.repoVideoInfo.video.notSupportCrossplat = YES;
    } else {
        // 合拍多轨和无画布 canvasType == ACCVideoCanvasTypeDuet ||  ACCVideoCanvasTypeNone
        config.useNewMudule = NO;
        if ([publishModel.repoVideoInfo isMultiVideoFastImport]) {
            config.enableMultiTrack = YES;
            config.useGlobalEffectGroup = YES;
            config.disableCanvasTimelineAutoComplete = YES;
            config.isVideoNeedReverse = [publishModel.repoVideoInfo isVideoNeedReverse];
        }
    }
    
    if (publishModel.repoVideoInfo.canvasType != ACCVideoCanvasTypeNone) {
        // Canvas 只在跨平台下支持
        publishModel.repoVideoInfo.video.crossplatInput = YES;
        publishModel.repoVideoInfo.video.crossplatCompile = YES;
    }
    
    return config;
}

+ (VEEditorSessionConfig *)mvEditorSessionConfigWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    VEEditorSessionConfig *config = [[VEEditorSessionConfig alloc] init];
    if (publishModel.repoVideoInfo.canvasType != ACCVideoCanvasTypeNone) {
        config.useNewMudule = NO;
        config.isVideoNeedReverse = [publishModel.repoVideoInfo isVideoNeedReverse];
    } else if (publishModel.repoCutSame.isClassicalMV || AWEVideoTypePhotoToVideo == publishModel.repoContext.videoType) {
        if (![AWEMVUtil precheckShouldCreateMVPlayerWithPublishViewModel:publishModel]) {
            AWELogToolError(AWELogToolTagRecord|AWELogToolTagMV, @"Create HTSPlayer object failed");
            return nil;
        }
        
        [AWEMVUtil preprocessPublishViewModelForMVPlayer:publishModel];
        
        config.useNewMudule = YES;
        config.isVideoNeedReverse = NO;

        config.mvModel = publishModel.repoMV.mvModel.veMVModel;
        publishModel.repoVideoInfo.video.notSupportCrossplat = YES;
    } else {
        config.useNewMudule = NO;
        if([publishModel.repoVideoInfo isMultiVideoFastImport]) {
            config.enableMultiTrack = YES;
        }
        config.isVideoNeedReverse = [publishModel.repoVideoInfo isVideoNeedReverse];
    }
    
    if (publishModel.repoVideoInfo.canvasType != ACCVideoCanvasTypeNone) {
        // Canvas 只在跨平台下支持
        publishModel.repoVideoInfo.video.crossplatInput = YES;
        publishModel.repoVideoInfo.video.crossplatCompile = YES;
    }
    
    return config;
}

+ (VEEditorSessionConfig *)publishEditorSessionConfigWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    VEEditorSessionConfig *config = [[VEEditorSessionConfig alloc] init];
    if (publishModel.repoContext.isQuickStoryPictureVideoType ||
        publishModel.repoContext.videoType == AWEVideoTypeStoryPicture) {
        CGFloat duration = ACCConfigDouble(kConfigDouble_story_picture_duration);
        if (publishModel.repoContext.isQuickStoryPictureVideoType) {
            duration = 10.0;
        }
        [publishModel.repoVideoInfo.video removeAllVideoAsset];
        publishModel.repoVideoInfo.video.isRecordFromCamera = YES;
        
        if (publishModel.repoPublishConfig.coverImage == nil) {
            publishModel.repoPublishConfig.coverImage = publishModel.repoUploadInfo.toBeUploadedImage;
        }
        
        UIImage *image = publishModel.repoUploadInfo.toBeUploadedImage ?: [UIImage new];
        [publishModel.repoVideoInfo.video setImageMovieInfoWithUIImages:@[image]
                                                      imageShowDuration:@{
                                                          [NSString stringWithFormat:@"%p", image] : IESMMVideoDataClipRangeMake(0, duration)
                                                      }];
        
        config.useNewMudule = NO;
        config.isVideoNeedReverse = [publishModel.repoVideoInfo isVideoNeedReverse];
    } else if (publishModel.repoCutSame.isClassicalMV || publishModel.repoContext.videoType == AWEVideoTypePhotoToVideo) {
        if (![AWEMVUtil precheckShouldCreateMVPlayerWithPublishViewModel:publishModel]) {
            AWELogToolError(AWELogToolTagRecord|AWELogToolTagMV, @"Create HTSPlayer object failed");
            config = nil;
        }
        
        [AWEMVUtil preprocessPublishViewModelForMVPlayer:publishModel];
        
        config.useNewMudule = YES;
        config.isVideoNeedReverse = NO;
        
        config.mvModel = publishModel.repoMV.mvModel.veMVModel;
        publishModel.repoVideoInfo.video.notSupportCrossplat = YES;
    } else if (publishModel.repoContext.isKaraokeAudio) {
        id<ACCRepoKaraokeModelProtocol> repoModel = [publishModel extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
        config.useNewMudule = YES;
        config.isVideoNeedReverse = NO;

        config.mvModel = repoModel.mvModel.veMVModel;
        publishModel.repoVideoInfo.video.notSupportCrossplat = YES;
    } else if (publishModel.repoContext.videoType == AWEVideoTypeNewYearWish) {
        config.useNewMudule = YES;
        config.isVideoNeedReverse = NO;
        config.mvModel = publishModel.repoActivity.mvModel.veMVModel;
        publishModel.repoVideoInfo.video.notSupportCrossplat = YES;
    } else {
        // 合拍多轨和无画布 canvasType == ACCVideoCanvasTypeDuet ||  ACCVideoCanvasTypeNone
        config.useNewMudule = NO;
        if ([publishModel.repoVideoInfo isMultiVideoFastImport]) {
            config.enableMultiTrack = YES;
            config.disableCanvasTimelineAutoComplete = YES;
        }
        config.isVideoNeedReverse = [publishModel.repoVideoInfo isVideoNeedReverse];
    }
    
    if (publishModel.repoVideoInfo.canvasType != ACCVideoCanvasTypeNone) {
        // Canvas 只在跨平台下支持
        publishModel.repoVideoInfo.video.crossplatInput = YES;
        publishModel.repoVideoInfo.video.crossplatCompile = YES;
    }
    
    return config;
}

@end
