//
//  ACCRecordConfigServiceImpl.m

//  CameraClient
//
//  Created by liuqing on 2020/4/20.
//

#import "AWERepoVideoInfoModel.h"
#import "AWERepoCaptionModel.h"
#import "AWERepoContextModel.h"
#import "ACCRecordConfigServiceImpl.h"
#import <CameraClient/ACCMusicNetServiceProtocol.h>
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitArch/AWEStudioMeasureManager.h>
#import <CreationKitArch/ACCStudioServiceProtocol.h>
#import <CreationKitArch/ACCPublishRepository.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitInfra/ACCDeviceAuth.h>
#import "AWEVideoRecordOutputParameter.h"
#import "AWEVideoPublishViewModel+InteractionSticker.h"
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CreationKitArch/ACCRepoTranscodingModel.h>
#import "ACCRepoChallengeBindModel.h"
#import "AWERepoPublishConfigModel.h"
#import "ACCRepoEditEffectModel.h"
#import "AWERepoDuetModel.h"
#import <CameraClient/AWERepoDraftModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CreationKitArch/ACCRepoFilterModel.h>
#import <CreationKitArch/ACCRepoStickerModel.h>
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import "ACCRepoKaraokeModelProtocol.h"
#import <CreationKitArch/ACCRepoGameModel.h>
#import "ACCConfigKeyDefines.h"
#import <CameraClient/ACCVEVideoData.h>
#import "AWEVideoFragmentInfo.h"
#import <CameraClient/ACCEditVideoDataFactory.h>

int kACCModernVideoEditEnlargeMetric = 10;
const static CGFloat kACCIMRecorderVideoMaxDuration = 15.0;
const static CGFloat kACCIMRecorderLongVideoMaxDuration = 60.0;

@interface ACCRecordConfigServiceImpl ()

@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, strong) NSHashTable *durationHandlers;
@property (nonatomic, strong) NSHashTable *audioHandlers;

@property (nonatomic, assign) BOOL hasCameraAuth;
@property (nonatomic, assign) BOOL isFixedMaxDuration;

@property (nonatomic, strong) id<ACCVideoConfigProtocol> videoConfig;

@end

@implementation ACCRecordConfigServiceImpl

IESAutoInject(ACCBaseServiceProvider() , videoConfig, ACCVideoConfigProtocol)

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    self = [super init];
    
    if (self) {
        self.publishModel = publishModel;
        self.durationHandlers = [NSHashTable weakObjectsHashTable];
        self.audioHandlers = [NSHashTable weakObjectsHashTable];
        
        self.hasCameraAuth = [ACCDeviceAuth hasCameraAndMicroPhoneAuth];
    }
    
    return self;
}

- (void)setupInitialConfig
{
    //修复部分贴纸第一次使用失效问题，创建Recorder的时候依赖effectpaltform的config
    [IESAutoInline(ACCBaseServiceProvider(), ACCStudioServiceProtocol) preloadInitializationEffectPlatformManager];
    
    [self createVideoDataIfNeeded];
    [self configPublishModelPhaseInfo];
    [self configAudioIfsetUp:YES withCompletion:NULL];
    [self configBgmAsset];
    //show bubble and save log after [self.camera setMusicWithURL:audioURL], otherwise video.audioAssets is nil
    [self configPublishModelMaxDurationWithAsset:self.publishModel.repoMusic.musicAsset showRecordLengthTipBlock:YES isFirstEmbed:YES];
}

- (void)startFixedMaxDurationMode:(CGFloat)fixDuration
{
    if (fixDuration <= 0) {
        return;
    }
    self.isFixedMaxDuration = YES;
    
    NSHashTable *handlers = [self.durationHandlers copy];
    for (id<ACCRecordConfigDurationHandler> handler in handlers) {
        if ([handler respondsToSelector:@selector(willSetMaxDuration:asset:showTip:isFirstEmbed:)]) {
            [handler willSetMaxDuration:&fixDuration asset:self.publishModel.repoMusic.musicAsset showTip:NO isFirstEmbed:NO];
        }
    }
    
    self.publishModel.repoContext.maxDuration = fixDuration;
    
    for (id<ACCRecordConfigDurationHandler> handler in handlers) {
        if ([handler respondsToSelector:@selector(didSetMaxDuration:)]) {
            [handler didSetMaxDuration:fixDuration];
        }
    }
}

- (void)endFixedMaxDurationMode
{
    self.isFixedMaxDuration = NO;
    [self configPublishModelMaxDurationWithAsset:self.publishModel.repoMusic.musicAsset showRecordLengthTipBlock:NO isFirstEmbed:NO];
}

- (CGFloat)videoMaxDuration
{
    if (self.isFixedMaxDuration) {
        return self.publishModel.repoContext.maxDuration;
        
    } else if (self.publishModel.repoContext.videoType == AWEVideoTypeKaraoke) {
        return ((id<ACCRepoKaraokeModelProtocol>)[self.publishModel extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)]).musicModel.karaokeShootDuration;
    } else if (!self.publishModel.repoDuet.isDuet) {
        if (self.publishModel.repoContext.isIMRecord) {
            if (!ACCConfigBool(kConfigBool_story_tab_tap_hold_record) && ACCConfigBool(kConfigBool_quick_story_long_press_hold_60s)) {
                return kACCIMRecorderLongVideoMaxDuration;
            }
            return kACCIMRecorderVideoMaxDuration;
        } else {
            return [self.videoConfig currentVideoMaxSeconds];
        }
    } else {
        return [self.videoConfig longVideoMaxSeconds];
    }
}

- (void)configAudioIfsetUp:(BOOL)isSetUpConfig withCompletion:(void (^)(void))completion
{
    AWEVideoPublishViewModel *publishModel = self.publishModel;
    //新合拍的草稿，其中保存了是否需要Mute的状态，不需要显示的设置为YES
    if (publishModel.repoDuet.isDuet) {
        BOOL isNewDuetDraft = publishModel.repoDraft.isDraft;
        if (!isNewDuetDraft) {
            publishModel.repoVideoInfo.videoMuted = !publishModel.repoDuet.shouldEnableMicrophoneOnStart;
        }
    } else {
        if (publishModel.repoReshoot.isReshoot ||
            (publishModel.repoDraft.isDraft && isSetUpConfig) ||
            (publishModel.repoDraft.isBackUp && isSetUpConfig) ||
            (publishModel.repoMusic.music != nil && publishModel.repoVideoInfo.microphoneBarState != ACCMicrophoneBarStateHidden)) {
            //reshoot时不需要更新 跟随原状态
            //带音乐开麦的草稿 保存了videoMuted状态 setup时不需要设置
            //带音乐录制到一半冷启重新进入app  不需要设置
            //替换音乐时候保持状态 不需要设置
        } else {
            publishModel.repoVideoInfo.videoMuted = publishModel.repoMusic.music != nil ? YES : NO;
            //有音乐则展示麦克风控制bar 默认是关闭
        }
    }

    void (^setMusicCompletion)(void) = ^{
        ACCBLOCK_INVOKE(completion);
    };
    for (id<ACCRecordConfigAudioHandler> handler in self.audioHandlers) {
        if ([handler respondsToSelector:@selector(didFinishConfigAudioWithSetMusicCompletion:)]) {
            [handler didFinishConfigAudioWithSetMusicCompletion:setMusicCompletion];
        }
    }

    NSURL *audioURL = self.publishModel.repoMusic.music.loaclAssetUrl;
    
    if (audioURL) { // has audioURL
        AWELogToolInfo(AWELogToolTagRecord, @"==acc_TOOL_MUSIC_CANT_RECORD==[%@][%@] audioURL: %@, music file exsit: %d, music file attribute: %@", NSStringFromClass(self.class), NSStringFromSelector(_cmd), audioURL, [[NSFileManager defaultManager] fileExistsAtPath:audioURL.path], [[NSFileManager defaultManager] attributesOfItemAtPath:audioURL.path error:nil]);
    }
}

- (void)configPublishModelMaxDurationAfterCameraSetMusic
{
    if (!self.hasCameraAuth) {
        self.hasCameraAuth = YES;
        // fix: https://jira.bytedance.com/browse/AME-67703?filter=-1 by Kuangjeon Tian
        if (self.publishModel.repoMusic.music &&
            !self.publishModel.repoMusic.bgmAsset) {
            AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:self.publishModel.repoMusic.music.loaclAssetUrl.path] options:@{ AVURLAssetPreferPreciseDurationAndTimingKey: @(YES) }];
            self.publishModel.repoMusic.bgmAsset = asset;
        }
        [self configPublishModelMaxDurationWithAsset:self.publishModel.repoMusic.musicAsset showRecordLengthTipBlock:NO isFirstEmbed:NO];
    }
}

- (void)configPublishModelMaxDurationWithAsset:(AVAsset *)asset showRecordLengthTipBlock:(BOOL)show isFirstEmbed:(BOOL)isFirstEmbed
{
    AWEVideoPublishViewModel *publishModel = self.publishModel;
    
    // reshoot use different duration config
    if (publishModel.repoReshoot.isReshoot || self.isFixedMaxDuration) {
        return;
    }
    
    CGFloat maxDuration = 0.f;
    NSHashTable *handlers = [self.durationHandlers copy];
    
    if (publishModel.repoDraft.isDraft && isFirstEmbed) {
        AWERepoContextModel *originDraftcontextModel = [publishModel.repoDraft.originalDraft extensionModelOfClass:AWERepoContextModel.class];
        maxDuration = originDraftcontextModel.maxDuration;
    } else {
        CGFloat maxLimit = [self videoMaxDuration];
        CGFloat minLimit = [self.videoConfig videoMinSeconds];
        maxDuration = maxLimit;
        for (id<ACCRecordConfigDurationHandler> handler in handlers) {
            if ([handler respondsToSelector:@selector(getComponentDuration:)]) {
                CGFloat componentDuration = [handler getComponentDuration:asset];
                maxDuration = MIN(MIN(maxLimit, MAX(minLimit, componentDuration)), maxDuration);
            }
        }
    }
    
    for (id<ACCRecordConfigDurationHandler> handler in handlers) {
        if ([handler respondsToSelector:@selector(willSetMaxDuration:asset:showTip:isFirstEmbed:)]) {
            [handler willSetMaxDuration:&maxDuration asset:asset showTip:(show && !self.isFixedMaxDuration) isFirstEmbed:isFirstEmbed];
        }
    }

    self.publishModel.repoContext.maxDuration = maxDuration;
    
    for (id<ACCRecordConfigDurationHandler> handler in handlers) {
        if ([handler respondsToSelector:@selector(didSetMaxDuration:)]) {
            [handler didSetMaxDuration:maxDuration];
        }
    }
    
    AVAsset *innerAsset = asset ?: self.publishModel.repoMusic.musicAsset;
    BOOL isDuet = self.publishModel.repoDuet.isDuet;
    BOOL enableLongDurationRecordAsTab = !isDuet;
    NSString *logString = [NSString stringWithFormat:@"Record publish model max duration: %lf, asset exist:%@, asset duration: %lf, long video enable:%@, long video record as tab enable:%@", self.publishModel.repoContext.maxDuration, innerAsset ? @"YES" : @"NO" ,CMTimeGetSeconds(asset.duration), @"YES", enableLongDurationRecordAsTab ? @"YES" : @"NO"];
    [[AWEStudioMeasureManager sharedMeasureManager] asyncOperationBlock:^{
        AWELogToolInfo(AWELogToolTagRecord, @"%@", logString);
    }];
}

- (void)configRecordingMultiSegmentMaximumResolutionLimit
{
    // Need to reset the maximum write-in resolution limit when returning from the mv/status/duet scene
    CGSize recordWriteSize = self.publishModel.repoVideoInfo.video.transParam.videoSize;
    // When returning from the MV/Status scene, the VideoData object used to record the scene may be incorrect
    CGSize expectedSize = [AWEVideoRecordOutputParameter expectedMaxRecordWriteSizeForPublishModel:self.publishModel];
    if (!CGSizeEqualToSize(recordWriteSize, expectedSize)) {
        AWELogToolError2(@"resolution", AWELogToolTagRecord, @"unexpected recording write-in resolution:%@, expected resolution:%@, video source:%ld, video type:%ld, isDuet:%@, isDraft:%@, isBackup:%@.", NSStringFromCGSize(recordWriteSize), NSStringFromCGSize(expectedSize), (long)self.publishModel.repoContext.videoSource, (long)self.publishModel.repoContext.videoType, @(self.publishModel.repoDuet.isDuet), @(self.publishModel.repoDraft.isDraft), @(self.publishModel.repoDraft.isBackUp));
    }
    [AWEVideoRecordOutputParameter configRecordingMultiSegmentMaximumResolutionLimit];
}

- (void)registDurationHandler:(id<ACCRecordConfigDurationHandler>)handler
{
    NSParameterAssert([handler conformsToProtocol:@protocol(ACCRecordConfigDurationHandler)]);
    [self.durationHandlers addObject:handler];
}

- (void)registAudioHandler:(id<ACCRecordConfigAudioHandler>)handler
{
    NSParameterAssert([handler conformsToProtocol:@protocol(ACCRecordConfigAudioHandler)]);
    [self.audioHandlers addObject:handler];
}

#pragma mark -

- (void)createVideoDataIfNeeded
{
    AWEVideoPublishViewModel *publishModel = self.publishModel;
    if (publishModel.repoVideoInfo.video == nil) {//第一次拍摄
        [publishModel.repoVideoInfo updateVideoData:[ACCVEVideoData videoDataWithDraftFolder:publishModel.repoDraft.draftFolder]];
        publishModel.repoVideoInfo.video.identifier = NSStringFromClass([self class]);
        publishModel.repoVideoInfo.isExposureOptmize = YES;
    }
    
    // 清空选择的动态封面时间
    AWERepoPublishConfigModel *configRepo = publishModel.repoPublishConfig;
    configRepo.dynamicCoverStartTime = 0;
    configRepo.coverTitleSelectedId = nil;
    configRepo.coverTitleSelectedFrom = nil;
    configRepo.coverImage = nil;
    configRepo.coverTextModel = nil;
    configRepo.coverTextImage = nil;
    configRepo.cropedCoverImage = nil;
    configRepo.coverCropOffset = CGPointZero;
    publishModel.repoFilter.colorFilterId = nil;
    [publishModel.repoSticker removeTextReadingInCurrentVideo];
    [publishModel.repoVideoInfo.video clearAllEffectAndTimeMachine];
    [publishModel.repoEditEffect.displayTimeRanges removeAllObjects];
   
    // Configure limited resolution parameters
    publishModel.repoContext.videoSource = AWEVideoSourceCapture;
    [AWEVideoRecordOutputParameter configPublishViewModelOutputParametersWith:self.publishModel];
    publishModel.repoVideoInfo.video.transParam.bitrate = (int)publishModel.repoTranscoding.bitRate;
    publishModel.repoVideoInfo.video.transParam.videoSize = CGSizeMake(publishModel.repoTranscoding.outputWidth, publishModel.repoTranscoding.outputHeight);
    [publishModel.repoVideoInfo.video muteMicrophone:publishModel.repoVideoInfo.videoMuted];
    
    if (publishModel.repoMusic.music.musicID.length && publishModel.repoMusic.music.challenge == nil) {
        [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) requestMusicItemWithID:publishModel.repoMusic.music.musicID
                                                                                         completion:^(id<ACCMusicModelProtocol> _Nullable model, NSError * _Nullable error) {
            if (model && [model.musicID isEqualToString:publishModel.repoMusic.music.musicID]) {
                publishModel.repoMusic.music.challenge = model.challenge;
            }
            
            if (error) {
                AWELogToolError(AWELogToolTagMusic, @"requestMusicItemWithID: %@", error);
            }
        }];
    }
}

- (void)configPublishModelPhaseInfo
{
    AWEVideoPublishViewModel *publishModel = self.publishModel;
    publishModel.repoContext.videoSource = AWEVideoSourceCapture;
    publishModel.repoFlowControl.step = AWEPublishFlowStepCapture;
    publishModel.repoTrack.enterFrom = self.publishModel.repoTrack.enterFrom ? : @"video_shoot_page";
    publishModel.repoSticker.stickerID = self.publishModel.repoSticker.stickerID ? : @"";
    publishModel.repoMusic.music.musicID = self.publishModel.repoMusic.music.musicID ? : @"";
}

/// 针对音乐人拍同款，道具拍同款，音乐拍同款携带音乐进行逻辑处理，
/// 如果不处理，bgmAsset没有，会导致下一步configPublishModelMaxDurationWithAsset失败
- (void)configBgmAsset
{
    AWEVideoPublishViewModel *publishModel = self.publishModel;
    if (!publishModel.repoMusic.bgmAsset && publishModel.repoMusic.music.loaclAssetUrl) {
        AVURLAsset *bgmAsset = [AVURLAsset URLAssetWithURL:publishModel.repoMusic.music.loaclAssetUrl options:@{ AVURLAssetPreferPreciseDurationAndTimingKey: @(YES) }];
        publishModel.repoMusic.bgmAsset = bgmAsset;
    }
}

- (void)configFinishPublishModel
{
    self.publishModel.repoCaption.captionInfo = nil;
    self.publishModel.repoUploadInfo.toBeUploadedImage = nil;
    self.publishModel.repoVideoInfo.video.infoStickers = @[];
    self.publishModel.repoVideoInfo.enableHDRNet = NO;
    if (self.publishModel.repoGame.gameType != ACCGameTypeNone) {
        self.publishModel.repoContext.videoType = AWEVideoType2DGame;
    } else if (self.publishModel.repoContext.videoType == AWEVideoTypeKaraoke ||
               self.publishModel.repoContext.videoType == AWEVideoTypeLiteTheme ||
               self.publishModel.repoContext.videoType == AWEVideoTypeLivePhoto) {
        // If videoType has already been set as karaoke or livephoto, we perform no operation here.
    } else {
        self.publishModel.repoContext.videoType = AWEVideoTypeNormal;
    }
    
    if (self.publishModel.repoMusic.music) {
        [self recordAudioRelatedInfo];
    }

    self.publishModel.repoTrack.enterEditPageMethod = @"click_next_button";
    [self.publishModel endRecordStickerLocations];
    self.publishModel.repoSticker.interactionStickers = nil;//clear interaction stickers when enter video edit view
    [self.publishModel.repoSticker.infoStickerArray removeAllObjects]; // info stickers should be empty
    [[NSNotificationCenter defaultCenter] postNotificationName:ACCVideoChallengeChangeKey object:nil];
    [self.publishModel.repoVideoInfo.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // 对于贴纸POI信息，每次从拍摄页进入后续流程都需要设置YES
        obj.needSelectedStickerPoi = obj.stickerPoiId.length > 0 ? YES : NO;
    }];
    if (self.publishModel.repoDraft.isDraft) {
        [self.publishModel.repoChallengeBind markNeedRemoveWhenReRecord];
    }
}

- (void)recordAudioRelatedInfo
{
    __block AVURLAsset *bgmAsset = nil;
    NSURL *assetURL = self.publishModel.repoMusic.music.loaclAssetUrl;
    if (assetURL) {
        [self.publishModel.repoVideoInfo.video.audioAssets enumerateObjectsUsingBlock:^(AVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSURL *assetURL = self.publishModel.repoMusic.music.loaclAssetUrl;
            if ([obj isKindOfClass:[AVURLAsset class]] && [((AVURLAsset *)obj).URL.path.lastPathComponent hasSuffix:assetURL.path.lastPathComponent]) {
                bgmAsset = (AVURLAsset *)obj;
                *stop = YES;
            }
        }];
    }

    // 假设没有匹配到
    if (!bgmAsset && assetURL) {
        // 音乐拍摄后绑定到bgmAsset
        bgmAsset = [AVURLAsset URLAssetWithURL:assetURL options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
    }
    if (bgmAsset) {
        self.publishModel.repoMusic.bgmAsset = bgmAsset;
        // 查找已存在的clip
        IESMMVideoDataClipRange *clipRange = self.publishModel.repoVideoInfo.video.audioTimeClipInfo[bgmAsset];
        if (!clipRange) {
            // 此时已经有了bgm，用户没有clip，则需要生成一个默认的从零开始的clip
            CGFloat duration = [self.publishModel.repoVideoInfo.video totalVideoDuration];
            // 附加到音轨的时间
            CGFloat attachTime = 0;
            clipRange = IESMMVideoDataClipRangeMakeV2(0, duration, attachTime, 1);
        }
        self.publishModel.repoMusic.bgmClipRange = clipRange;
    }
}

@end
