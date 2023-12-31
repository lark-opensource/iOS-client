//
//  ACCRecordSelectMusicServiceImpl.m
//  CameraClient-Pods-Aweme
//
//  Created by liuqing on 2020/3/25.
//

#import "AWERepoMusicModel.h"
#import "ACCRecordSelectMusicServiceImpl.h"
#import "ACCConfigKeyDefines.h"
#import "AWEAIMusicRecommendManager.h"
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import "AWECameraContainerIconManager.h"
#import <CameraClient/ACCMusicNetServiceProtocol.h>
#import "NSObject+ACCEventContext.h"
#import "AWERecorderTipsAndBubbleManager.h"
#import "ACCVideoMusicProtocol.h"
#import "AWEEffectPlatformManager+Download.h"
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CreationKitArch/ACCRecordInformationRepoModel.h>

#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>

#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreationKitInfra/ACCDeviceAuth.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import "AWERepoVideoInfoModel.h"
#import "ACCRepoLivePhotoModel.h"
#import "ACCMusicModelProtocolD.h"

static NSString * const kPropReuseOriginAudioBubblePrompt = @"已使用原视频音乐，最长拍%.0fs";

typedef NS_ENUM(NSUInteger, kACCRecordReuseMusicType) {
    kACCRecordReuseMusicTypeNone = 0,
    kACCRecordReuseMusicTypeA,
    kACCRecordReuseMusicTypeB,
};

@implementation ACCRecordSelectMusicCoverInfo

@end

@interface ACCRecordSelectMusicServiceImpl ()

@property (nonatomic, strong) RACSubject *musicCoverSubject;
@property (nonatomic, strong) RACSubject *selectMusicAnimationSubject;
@property (nonatomic, strong) RACSubject *selectMusicPanelShowSubject;
@property (nonatomic, strong) RACSubject *bindMusicErrorSubject;
@property (nonatomic, strong) RACSubject *cancelMusicSubject;
@property (nonatomic, strong) RACSubject *pickMusicSubject;
@property (nonatomic, strong) RACSubject *musicTipSubject;
@property (nonatomic, strong) RACSubject *muteTipSubject;
@property (nonatomic, strong) RACSubject *downloadMusicForStickerSubject; // List of music will be recommended for the selected sticker, first of which will be displayed on music bubble. Downloading service success notifies record page to use this music.

@property (nonatomic, strong) IESEffectModel *currentSticker;

@property (nonatomic, strong) IESEffectModel *reuseFeedEffect;
@property (nonatomic, copy) NSString *feedMusicFailedReason;
@property (nonatomic, copy) NSString *feedStickerFailedReason;

@property (nonatomic, assign) BOOL hasSelectedMusic;

@property (nonatomic, strong) id<ACCVideoConfigProtocol> config;
@property (nonatomic, strong) id<ACCCameraService> cameraService;

@end

@implementation ACCRecordSelectMusicServiceImpl
IESAutoInject(self.serviceProvider, config, ACCVideoConfigProtocol)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)

#pragma mark - Life Cycle

- (void)dealloc
{
    [_musicCoverSubject sendCompleted];
    [_selectMusicAnimationSubject sendCompleted];
    [_bindMusicErrorSubject sendCompleted];
    [_cancelMusicSubject sendCompleted];
    [_pickMusicSubject sendCompleted];
    [_musicTipSubject sendCompleted];
    [_muteTipSubject sendCompleted];
    [_selectMusicPanelShowSubject sendCompleted];
    [_downloadMusicForStickerSubject sendCompleted];
}

#pragma mark - Public

- (void)refreshMusicCover
{
    [self refreshMusicCoverWithMusic:self.publishModel.repoMusic.music];
}

- (void)startBGMIfNeeded
{
    if (self.cameraService.effect && [self hasCameraAndMicroPhoneAuth]) {
        // 通过3D Touch进入拍摄器，此时VC还未ViewDidLoad，创建camera添加CameraPreview会失败，所以创建了才执行
        [self.cameraService.effect startEffectPropBGM:IESEffectBGMTypeNormal];
    }
}

- (BOOL)supportSelectMusic
{
    AWEVideoPublishViewModel *publishModel = self.inputData.publishModel;
    BOOL selectMusicShow = !publishModel.repoDuet.isDuet;
    return selectMusicShow;
}

- (void)handlePickMusic:(id<ACCMusicModelProtocol>)music error:(NSError *)error completion:(void (^)(void))completion
{
    self.publishModel.repoMusic.musicSelectFrom = AWERecordMusicSelectSourceMusicSelectPage;
    if (error) {
        [self.bindMusicErrorSubject sendNext:error];
        ACCBLOCK_INVOKE(completion);
        return;
    }
    
    if ((self.publishModel.repoMusic.music == nil && music != nil) ||
        (self.publishModel.repoMusic.music != nil && music == nil)) {
        self.hasSelectedMusic = YES;
    }
    
    if (music) {
        //埋点统计
        if (music.musicSelectedFrom) {
            music.awe_selectPageName = @"shoot_page";
        }
        if (!self.publishModel.repoMusic.music ||
            ![self.publishModel.repoMusic.music.musicID isEqualToString:music.musicID] ||
            music.isLocalScannedMedia) {
            [self refreshMusicCoverWithMusic:music];
        }

        [self pickMusic:music complete:completion];
    } else {
        ACCBLOCK_INVOKE(completion);
    }
}

- (void)handleCancelMusic:(id<ACCMusicModelProtocol>)music
{
    [self handleCancelMusic:music muteBGM:NO trackInfo:nil];
}

- (void)handleCancelMusic:(id<ACCMusicModelProtocol>)music muteBGM:(BOOL)muteBGM trackInfo:(nullable NSDictionary *)trackInfo
{
    if (music) {
        [self unselectMusic:music muteBGM:muteBGM trackInfo:trackInfo];
    }
}

- (void)applyForceBindMusic:(id<ACCMusicModelProtocol>)musicModel
{
    if (self.publishModel.repoMusic.musicSelectFrom == AWERecordMusicSelectSourceStickerForceBind && musicModel) {
        [self.cameraService.effect muteEffectPropBGM:YES];
        [self selectForceBindMusic:musicModel error:nil];
        [self.selectMusicAnimationSubject sendNext:@(YES)];
        self.publishModel.repoMusic.musicSelectFrom = musicModel.loaclAssetUrl ? AWERecordMusicSelectSourceStickerForceBind : AWERecordMusicSelectSourceUnSelected;
    }
}

- (void)pickForceBindMusic:(id<ACCMusicModelProtocol>)musicModel isForceBind:(BOOL)isForceBind error:(NSError *)musicError
{
    if (isForceBind &&  musicModel) {
        if (musicError ||[musicModel isOffLine] || !musicModel.loaclAssetUrl) {
            //出现下载失败气泡
            self.publishModel.repoMusic.musicSelectFrom = AWERecordMusicSelectSourceUnSelected;
            if (self.publishModel.repoMusic.music) {
                [self unselectMusic:self.publishModel.repoMusic.music muteBGM:NO trackInfo:nil];
            }
        } else {
            self.publishModel.repoMusic.musicSelectFrom = AWERecordMusicSelectSourceStickerForceBind;
            [self.cameraService.effect muteEffectPropBGM:YES];
            [self selectForceBindMusic:musicModel error:musicError];
            [self.selectMusicAnimationSubject sendNext:@(YES)];
        }
    } else {
        self.publishModel.repoMusic.musicSelectFrom = AWERecordMusicSelectSourceUnSelected;
    }
    
    if (!musicModel || [musicModel isOffLine]) {
        if (self.publishModel.repoMusic.music) {
            [self unselectMusic:self.publishModel.repoMusic.music muteBGM:NO trackInfo:nil];
            self.publishModel.repoMusic.musicSelectFrom = AWERecordMusicSelectSourceUnSelected;
        }
    }
}

- (void)cancelForceBindMusic:(id<ACCMusicModelProtocol>)musicModel
{
    [self unselectMusic:musicModel muteBGM:NO trackInfo:nil];
    self.publishModel.repoMusic.musicSelectFrom = AWERecordMusicSelectSourceUnSelected;
}

- (void)showSelectMusicPanel
{
    [self.selectMusicPanelShowSubject sendNext:nil];
}

- (void)switchAIRecordFrameTypeIfNeeded
{
    if (!ACCConfigBool(kConfigBool_close_upload_origin_frames)) {
        if (self.currentSticker) {
            [[AWEAIMusicRecommendManager sharedInstance] setFrameRecordType:AWEAIRecordFrameTypeOriginal];
        }
        return;
    }
    if (self.currentSticker ||
        ![[AWEAIMusicRecommendManager sharedInstance] serviceOnWithModel:self.publishModel]) {
        return;
    }
    [[AWEAIMusicRecommendManager sharedInstance] setFrameRecordType:AWEAIRecordFrameTypeRecord];
}

- (void)updateCurrentSticker:(IESEffectModel *)currentSticker
{
    self.currentSticker = currentSticker;
}

- (void)removeFrames:(BOOL)confirm
{
    if (confirm) {
        [self.publishModel.repoVideoInfo.fragmentInfo removeAllObjects];
    }
}

- (void)trackChangeMusic:(BOOL)enabled
{
    if (!enabled) {
        [self acc_trackEvent:@"change_music_grey" attributes:^(ACCAttributeBuilder *build) {
            build.attribute(@"creation_id").equalTo(self.publishModel.repoContext.createId);
            build.attribute(@"shoot_way").equalTo(self.publishModel.repoTrack.referString);
        }];
    } else {
         NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.publishModel.repoTrack.referExtra];
         referExtra[@"enter_from"] = @"video_shoot_page";
         [ACCTracker() trackEvent:@"change_music" params:referExtra needStagingFlag:NO];
    }
}

- (void)showTip:(NSString *)tip isFirstEmbed:(BOOL)isFirstEmbed
{
    NSString *tipCopy = [tip copy];
    BOOL isDraftOrBackup = self.publishModel.repoDraft.isDraft || self.publishModel.repoDraft.isBackUp;
    if ((isFirstEmbed && isDraftOrBackup) || self.publishModel.repoVideoInfo.fragmentInfo.count > 0) {
        // 草稿，冷启，或已拍视频片段不为0时不展示气泡
        tipCopy = nil;
    }
    
    if (self.configService.isFixedMaxDuration) {
        return;
    }
    
    [self.musicTipSubject sendNext:RACTuplePack(tipCopy, @(isFirstEmbed))];
}

- (id<ACCMusicModelProtocol>)sameStickerMusic
{
    return self.inputData.sameStickerMusic;
}

- (AWEVideoPublishViewModel *)publishModel
{
    return self.inputData.publishModel;
}

- (void)downloadPropRecommendedMusic
{
    if (self.propRecommendMusic) {
        @weakify(self);
        [ACCVideoMusic() fetchLocalURLForMusic:self.propRecommendMusic withProgress:^(float progress) {
        } completion:^(NSURL * _Nonnull localURL, NSError * _Nonnull error) {
            @strongify(self);
            self.propRecommendMusic.loaclAssetUrl = localURL;
           [self.downloadMusicForStickerSubject sendNext:error];
        }];
    }
}

- (void)handleAutoSelectWeakBindMusic:(id<ACCMusicModelProtocol>)music error:(NSError *)error completion:(dispatch_block_t)completion
{
    if (error) {
        [self.bindMusicErrorSubject sendNext:error];
        ACC_LogError(@"%@", error.description);
        ACCBLOCK_INVOKE(completion);
        return;
    }
    if (music.isOffLine || !music.loaclAssetUrl || self.publishModel.repoMusic.musicSelectFrom != AWERecordMusicSelectSourceUnSelected) {
        ACCBLOCK_INVOKE(completion);
        return;
    }
    self.publishModel.repoMusic.musicSelectFrom = AWERecordMusicSelectSourceRecommendAutoApply;
    [self refreshMusicCoverWithMusic:music];
    [self pickMusic:music complete:completion];
}

- (void)handleRearApplyMusic:(id<ACCMusicModelProtocol>)music completion:(void (^)(void))completion
{
    self.hasSelectedMusic = YES;
    [self refreshMusicCoverWithMusic:music];
    @weakify(self);
    [self pickMusic:music complete:^{
        @strongify(self);
        if (ACCConfigEnum(kConfigInt_music_shoot_landing_submode_type, ACCMusicShootLandingType) == ACCMusicShootLandingTypeSyncMusicClip) {
            CGFloat leftClippedTime = self.publishModel.repoMusic.musicMaxRecordableDuration - self.publishModel.repoMusic.musicClipBeginTime;
            if (self.publishModel.repoContext.maxDuration < leftClippedTime) {
                [self updateAudioRangeWithStartLocation:self.publishModel.repoMusic.musicClipBeginTime];
            }
        }
    }];//这里有range清空 需要重新设置
    [self.selectMusicAnimationSubject sendNext:@(YES)];
}
#pragma mark - Private

- (void)pickMusic:(id<ACCMusicModelProtocol>)music complete:(void (^)(void))completeBlock
{
    self.publishModel.repoMusic.music = music;
    
    AVAsset *asset = self.publishModel.repoVideoInfo.video.audioAssets.lastObject;
    [self.publishModel.repoVideoInfo.video removeAudioAsset:asset];
    
    @weakify(self);
    [self.cameraService.recorder removePlayer:^{
        @strongify(self);
        // removePlayer会异步的清除videoData里的audioAssert，所以保证时序问题，
        // 异步清除完成之后在回调配置新的audioAssert
        [self.configService configAudioIfsetUp:NO withCompletion:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                //拍摄页选音乐之前不存在其他assets，所以应用后的音乐赋值为self.inputData.publishModel.repoVideoInfo.video.audioAssets.firstObject
                // 保证在下面configPublishModelMaxDurationWithAsset这句之前
                // 否则新框架下[self musicAsset]返回nil
                self.publishModel.repoMusic.bgmAsset = self.publishModel.repoVideoInfo.video.audioAssets.firstObject;
                // 先更新 maxDuration
                // update maxDuration first
                [self.configService configPublishModelMaxDurationWithAsset:self.publishModel.repoMusic.musicAsset showRecordLengthTipBlock:YES isFirstEmbed:NO];
                // 再更新进度条
                // then update the progressView
                [self.pickMusicSubject sendNext:nil];
                
                [self updateAudioRangeWithStartLocation:0];
                [self.cameraService.effect acc_propPlayMusic:self.cameraService.effect.currentSticker];// if is musicBeat prop, need to play music immediately after selection.
                [self.cameraService.effect muteEffectPropBGM:YES];
                ACCBLOCK_INVOKE(completeBlock);
                
                if (self.publishModel.repoMusic.music.challenge == nil) {
                    [IESAutoInline(self.serviceProvider, ACCMusicNetServiceProtocol) requestMusicItemWithID:music.musicID completion:^(id<ACCMusicModelProtocol> model, NSError *error) {
                        if (error) {
                            AWELogToolError(AWELogToolTagRecord, @"Request music item. %@", error);
                            return;
                        }
                        if (model && [model.musicID isEqualToString:self.publishModel.repoMusic.music.musicID]) {
                            id<ACCMusicModelProtocolD> music = (id<ACCMusicModelProtocolD>)self.publishModel.repoMusic.music;
                            music.challenge = model.challenge;
                            music.karaoke = ((id<ACCMusicModelProtocolD>)model).karaoke;
                        }
                    }];
                }
            });
        }];
    }];
}

- (void)refreshMusicCoverWithMusic:(id<ACCMusicModelProtocol>)music
{
    ACCRecordSelectMusicCoverInfo *coverInfo = [[ACCRecordSelectMusicCoverInfo alloc] init];
    BOOL hasMusic = music != nil;
    coverInfo.hasMusic = hasMusic;
    NSString *title;
    if (hasMusic) {
        if (!ACC_isEmptyString(music.musicName)) {
            title = music.musicName;
            NSString *matchedPGCTitle = [music awe_matchedPGCMusicInfoStringWithPrefix];
            if (!music.isPGC && !ACC_isEmptyString(matchedPGCTitle)) { // 非PGC音乐中，如果有符合使用的PGC音乐
                title = [NSString stringWithFormat:@"%@（%@）", title, matchedPGCTitle];
            }
        } else {
            title = ACCLocalizedString(@"music_selected", @"已选择音乐");
        }
    }
    coverInfo.title = !hasMusic ? ACCLocalizedString(@"choose_music", @"选择音乐") : title;
    coverInfo.image = hasMusic ? [AWECameraContainerIconManager selectMusicButtonSelectedImage] : [AWECameraContainerIconManager selectMusicButtonNormalImage];
    [self.musicCoverSubject sendNext:coverInfo];
}

- (void)selectForceBindMusic:(id<ACCMusicModelProtocol>)music error:(NSError *)error
{
    if (error) {
        [self.bindMusicErrorSubject sendNext:error];
        return;
    }
    
    if (music && music.loaclAssetUrl && !ACC_isEmptyString(music.loaclAssetUrl.absoluteString)) {
        [self.cameraService.effect acc_musicPropStopMusic];
        [self refreshMusicCoverWithMusic:music];
        self.hasSelectedMusic = YES;
        [self pickMusic:music complete:nil];
    }
}

- (void)unselectMusic:(id<ACCMusicModelProtocol>)music muteBGM:(BOOL)muteBGM trackInfo:(nullable NSDictionary *)trackInfo
{
    self.publishModel.repoMusic.musicSelectFrom = AWERecordMusicSelectSourceUnSelected;
    
    if (!trackInfo) {
        NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.publishModel.repoTrack.referExtra];
        referExtra[@"music_id"] = music.musicID ? : @"";
        trackInfo = referExtra;
    }
    [ACCTracker() trackEvent:@"unselect_music" params:trackInfo needStagingFlag:NO];

    [self.cameraService.effect acc_musicPropStopMusic];
    
    [self refreshMusicCoverWithMusic:nil];
    self.publishModel.repoMusic.music = nil;
    if ([music.musicID isEqual:self.propRecommendMusic.musicID]) {
        self.propRecommendMusic = nil;
    }
    self.publishModel.repoMusic.bgmAsset = nil;
    
    AVAsset *asset = self.publishModel.repoVideoInfo.video.audioAssets.lastObject;
    [self.publishModel.repoVideoInfo.video removeAudioAsset:asset];
    [self.cameraService.recorder removePlayer];
    [self.configService configAudioIfsetUp:NO withCompletion:NULL];

    // 先更新maxDuration
    // update maxDuration first
    [self.configService configPublishModelMaxDurationWithAsset:self.publishModel.repoMusic.musicAsset showRecordLengthTipBlock:YES isFirstEmbed:NO];

    // 再更新进度条
    // then update the progressView
    [self.cancelMusicSubject sendNext:nil];
    [self updateAudioRangeWithStartLocation:0];
    [self.cameraService.effect muteEffectPropBGM:muteBGM];
}

- (void)updateAudioRangeWithStartLocation:(double)startLocation
{
    AWELogToolInfo2(@"Camera music range", AWELogToolTagRecord, @"set camera music range. newStartLocation:%f, oldRangeLocaltion:%f", startLocation, self.publishModel.repoMusic.audioRange.location);
    HTSAudioRange range = {0};
    
    range.location = startLocation;
    range.length = self.publishModel.repoContext.maxDuration;
        
    self.publishModel.repoMusic.audioRange = range;
    
    AVAsset *innerAsset = [self musicAsset];
    CGFloat duration = CMTimeGetSeconds(innerAsset.duration);
    CGFloat clipDuration = duration - range.location;
    
    double maxDuration = self.publishModel.repoContext.maxDuration;
    if (self.publishModel.repoLivePhoto.businessType != ACCLivePhotoTypeNone) {
        maxDuration = [self.publishModel.repoLivePhoto videoPlayDuration];
    }
    if (clipDuration > maxDuration) {
        clipDuration = maxDuration;
    }

    AWERepoMusicModel *repoMusic = self.repository.repoMusic;
    if ([repoMusic shouldReplaceClipDurationWithMusicShootDuration:clipDuration]) {
        clipDuration = [repoMusic.music.shootDuration floatValue];
    }

    if (innerAsset && clipDuration != NAN && self.cameraService.cameraHasInit) {
        [self.cameraService.recorder changeMusicStartTime:range.location clipDuration:clipDuration];
    }
}

- (AVAsset *)musicAsset
{
    return self.inputData.publishModel.repoMusic.bgmAsset;
}

- (BOOL)hasCameraAndMicroPhoneAuth
{
    return [ACCDeviceAuth hasCameraAndMicroPhoneAuth];
}

- (id<ACCRecordConfigService>)configService
{
    return IESAutoInline(self.serviceProvider, ACCRecordConfigService);
}

#pragma mark - current feed aweme
- (void)startReuseFeedMusicFlowIfNeed
{
    if (![self shouldUseCurrentFeedMusic]) {
        return;
    }
    
    @weakify(self);
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    __block CFAbsoluteTime stickerFinishTime, musicFinishTime;
    acc_dispatch_queue_async_safe(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_group_t group = dispatch_group_create();
        dispatch_group_enter(group);
        @strongify(self);
        [self preFetchFeedMusicWithCompletion:^{
            musicFinishTime = CFAbsoluteTimeGetCurrent() - startTime;
            dispatch_group_leave(group);
        }];
        dispatch_group_enter(group);
        [self preFetchFeedStickerWithCompletion:^{
            stickerFinishTime = CFAbsoluteTimeGetCurrent() - startTime;
            dispatch_group_leave(group);
        }];
        @weakify(self);
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            @strongify(self);
            [self showFeedMusicViewIfNeeded];
            CFAbsoluteTime totalFinishTime =CFAbsoluteTimeGetCurrent() - startTime;
            NSString *musicId = self.repository.repoMusic.currentFeedModel.music.musicID ? self.repository.repoMusic.currentFeedModel.music.musicID : @"";
            NSString *stickerId = self.reuseFeedEffect.effectIdentifier ? self.reuseFeedEffect.effectIdentifier : @"";
            NSMutableDictionary *temp = @{@"main_reuse_total_time": @(totalFinishTime * 1000),
                                          @"music_download_time": @(musicFinishTime * 1000),
                                          @"music_id": musicId}.mutableCopy;
            if (stickerId.length > 0) {
                temp[@"prop_download_time"] = @(stickerFinishTime * 1000);
                temp[@"prop_id"] = stickerId;
            }
            if (self.feedMusicFailedReason) {
                temp[@"failed_reason"] = self.feedMusicFailedReason;
            }
            if (self.feedStickerFailedReason) {
                temp[@"prop_failed_reason"] = self.feedStickerFailedReason;
            }
            [ACCMonitor() trackService:@"aweme_reuse_music_sticker_monitor"
                                status:0
                                 extra:temp.copy];

        });
    });
}

- (void)showFeedMusicViewIfNeeded
{
    id<ACCMusicModelProtocol> music = self.repository.repoMusic.currentFeedModel.music;
    if (music.loaclAssetUrl) {
        NSMutableDictionary *temp = [self.publishModel.repoTrack.referExtra mutableCopy];
        temp[@"with_prop"] = self.reuseFeedEffect ? @"1" : @"0";
        [ACCTracker() trackEvent:@"same_prop_music_show" params:temp.copy needStagingFlag:NO];
    }
}

- (void)preFetchFeedStickerWithCompletion:(void(^)(void))completion
{
    id<ACCAwemeModelProtocol> aweme = self.repository.repoMusic.currentFeedModel;
    if (!aweme.stickers) {
        ACCBLOCK_INVOKE(completion);
        return;
    }

    NSString *stickerID = [[aweme.stickers componentsSeparatedByString:@","] firstObject];
    if (!stickerID) {
        ACCBLOCK_INVOKE(completion);
        return;
    }

    AWEEffectPlatformTrackModel *trackModel = [AWEEffectPlatformTrackModel modernStickerTrackModel];
    @weakify(self);
    void (^nextActionBlock)(IESEffectModel *, NSError *, IESEffectModel *) = ^(IESEffectModel *effectModel, NSError *error, IESEffectModel *parentEffect) {
        @strongify(self);
        if (error) {
            AWELogToolError(AWELogToolTagRecord, @"Download sticker nextAction. %@", error);
        }
        if ([self canUseFeedSticker:effectModel]) {
            if (effectModel.downloaded) {
                self.reuseFeedEffect = effectModel;
                ACCBLOCK_INVOKE(completion);
                return;
            }
            @weakify(self);
            [EffectPlatform downloadEffect:effectModel progress:nil completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
                @strongify(self);
                if (error) {
                    AWELogToolError(AWELogToolTagRecord, @"Download effect. %@", error);
                    self.feedStickerFailedReason = error.localizedDescription;
                }
                if (!error && filePath) {
                    self.reuseFeedEffect = effectModel;
                }
                ACCBLOCK_INVOKE(completion);//finish download effect resource
            }];
            return;
        } else {
            ACCBLOCK_INVOKE(completion);//effect can't be used
        }
    };
    
    [[AWEEffectPlatformManager sharedManager] downloadStickerWithStickerID:stickerID
                                                trackModel:trackModel
                                                  progress:nil
                                                completion:^(IESEffectModel * _Nonnull effect, NSError * _Nonnull error, IESEffectModel * _Nullable parentEffect, NSArray<IESEffectModel *> * _Nullable bindEffects) {
        ACCBLOCK_INVOKE(nextActionBlock, effect, error, parentEffect);
    }];
}

- (void)preFetchFeedMusicWithCompletion:(void(^)(void))completion
{
    id<ACCMusicModelProtocol> music = self.repository.repoMusic.currentFeedModel.music;
    if (!music) {
        self.feedMusicFailedReason = @"music can not be empty!";
        ACCBLOCK_INVOKE(completion);
        return;
    }
    @weakify(self);
    [ACCVideoMusic() fetchLocalURLForMusic:music withProgress:nil completion:^(NSURL * _Nonnull localURL, NSError * _Nonnull error) {
        @strongify(self);
        if (error) {
            AWELogToolError(AWELogToolTagMusic, @"Fetch local URL music. %@", error);
            self.feedMusicFailedReason = error.localizedDescription;
        }
        if (localURL) {
            music.loaclAssetUrl = localURL;
        }
        ACCBLOCK_INVOKE(completion);
    }];
}

- (BOOL)canUseFeedSticker:(IESEffectModel *)effect
{
    if (!effect) {
        return NO;
    }
    BOOL isGameEffect = effect.isEffectControlGame;
    BOOL hasTrayView = ([effect isPixaloopSticker] ||
                        [effect isVideoBGPixaloopSticker] ||
                        [effect isTypeAdaptive] ||
                        effect.parentEffectID.length > 0 ||
                        effect.childrenEffects.count > 0);
    
    NSString *effectType = @"Normal";
    BOOL unuseable = isGameEffect || hasTrayView;
    if (unuseable) {
            effectType = isGameEffect ? @"Game" : @"has tray view";
    }
    NSString *logInfo = [NSString stringWithFormat:@"\nReuseFeedMusic-pym:\nEffect type: %@ \neffect info : %@\n", effectType, effect];
    AWELogToolInfo(AWELogToolTagRecord, @"%@", logInfo);
    if (unuseable) {
        return NO;
    }
    return YES;
}

- (BOOL)shouldUseCurrentFeedMusic
{
    BOOL shouldShowAddFeedMusicView = [[AWERecorderTipsAndBubbleManager shareInstance] shouldShowAddFeedMusicView];
    id<ACCAwemeModelProtocol> model = self.repository.repoMusic.currentFeedModel;
    return shouldShowAddFeedMusicView && (nil != model);
}

#pragma mark - ACCRecordConfigAudioHandler

- (void)videoMutedTip:(NSString *)tip
{
    [self.muteTipSubject sendNext:tip];
}

#pragma mark - ACCRecordConfigDurationHandler

- (CGFloat)getComponentDuration:(AVAsset *)asset
{
    if ([self.repository.repoMusic shouldEnableMusicLoop:[self.config videoMaxSeconds]]) {
        return CGFLOAT_MAX;
    }
    NSNumber *first = [self musicDurationWithAsset:asset].first;
    return [first doubleValue];
}

- (void)didSetMaxDuration:(CGFloat)duration {
    [self updateAudioRangeWithStartLocation:self.publishModel.repoMusic.audioRange.location];
}

- (void)willSetMaxDuration:(inout CGFloat *)duration asset:(AVAsset *)asset showTip:(BOOL)show isFirstEmbed:(BOOL)isFirstEmbed
{
    CGFloat durationMusic = [[self musicDurationWithAsset:asset].first doubleValue];
    CGFloat maxDuration = *duration;
        
    *duration = maxDuration;

    if (asset) { //has music and no bg video sticker
        if (isFirstEmbed) {
            [AWERecorderTipsAndBubbleManager shareInstance].actureRecordBtnMode = [self.config currentVideoLenthMode];
        }
        
        // if seg prop, will not config max duration when the first time enter record page.
        if (show && !(isFirstEmbed && self.inputData.localSticker.isMultiSegProp)) {
            [self handleMusicTipWithDuration:durationMusic isFirstEmbed:isFirstEmbed];
        }
    }
}

- (RACTwoTuple *)musicDurationWithAsset:(AVAsset *)asset
{
    Float64 durationMusic = CGFLOAT_MAX;
    Float64 originDurationMusic = CGFLOAT_MAX;
    
    AVAsset *innerAsset = asset ?: self.publishModel.repoMusic.musicAsset;
    if (innerAsset) {//has music
        Float64 duration = CMTimeGetSeconds(innerAsset.duration);//music duration
        AVAssetTrack *firstTrack = [innerAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        if (duration <= 0. && firstTrack) {
            // make sure firstTrack is not nil, or CMTimeGetSeconds will return nan.
           duration = CMTimeGetSeconds([firstTrack timeRange].duration);
        }
        durationMusic = duration;
        originDurationMusic = duration;
        if (duration >= [self.config videoMinSeconds]) {
            if ([self.publishModel.repoMusic shouldReplaceClipDurationWithMusicShootDuration:duration]) {
                duration = MIN(duration, [self.publishModel.repoMusic.music.shootDuration integerValue]);
            }
            durationMusic = duration;
        }
    }
    
    return RACTuplePack(@(durationMusic), @(originDurationMusic));
}

- (void)handleMusicTipWithDuration:(CGFloat)duration isFirstEmbed:(BOOL)isFirstEmbed
{
    CGFloat durationLimit = [self.configService videoMaxDuration];
    
    void (^trackBlock)(BOOL) = ^(BOOL isFirstEmbed) {
        if (!isFirstEmbed) {
            return;
        }
        NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.inputData.publishModel.repoTrack.referExtra];
        referExtra[@"music_id"] = self.inputData.publishModel.repoMusic.music.musicID ? : @"";
        referExtra[@"prop_id"] = self.inputData.localSticker.effectIdentifier ? : @"";
        referExtra[@"group_id"] = self.inputData.groupID ? : @"";
        [ACCTracker() trackEvent:@"prop_music_show" params:referExtra needStagingFlag:NO];
    };
    
    //显示音乐时长气泡逻辑
    CGFloat maxRecordDuration = (CGFloat)(floor(MIN(duration, durationLimit)));//向下取整,just for bubble display
    if (maxRecordDuration < 1.f) {
        maxRecordDuration = 1.f;
    }
    
    if (duration < durationLimit && duration >= [self.config videoMinSeconds]) {//music duration < durationLimit(15/60s) or durationLimit(15s/3min)
        if ([self.repository.repoMusic shouldEnableMusicLoop:[self.config videoMaxSeconds]]) {
            return;
        }
        NSString *bubbleStr = [NSString stringWithFormat:ACCLocalizedCurrentString(@"com_mig_shoot_up_to_0fs"),maxRecordDuration];//切换音乐 || 音乐拍同款
        if (self.publishModel.repoMusic.music && self.inputData.sameStickerMusic) {//道具拍同款带音乐气泡-展示文案
            if (self.publishModel.repoMusic.music.loaclAssetUrl && self.inputData.sameStickerMusic.loaclAssetUrl &&
                [self.publishModel.repoMusic.music.loaclAssetUrl.absoluteString isEqualToString:self.inputData.sameStickerMusic.loaclAssetUrl.absoluteString]) {
                bubbleStr = [NSString stringWithFormat:kPropReuseOriginAudioBubblePrompt, maxRecordDuration];
                trackBlock(isFirstEmbed);
            }
        }
        
        //display bubble
        [self showTip:bubbleStr isFirstEmbed:isFirstEmbed];

    } else {
        //道具拍同款带音乐气泡 - 考虑版权限制15S
        if (self.publishModel.repoMusic.music && self.inputData.sameStickerMusic) {
            NSString *bubbleStr = [NSString stringWithFormat:ACCLocalizedCurrentString(@"com_mig_shoot_up_to_0fs"),maxRecordDuration];
            if (self.publishModel.repoMusic.music.loaclAssetUrl && self.inputData.sameStickerMusic.loaclAssetUrl &&
                [self.publishModel.repoMusic.music.loaclAssetUrl.absoluteString isEqualToString:self.inputData.sameStickerMusic.loaclAssetUrl.absoluteString]) {//同款道具音乐
                bubbleStr = ACCLocalizedString(@"use_origin_music_tips", @"已使用原视频的音乐");
                ACCRecordLengthMode lengthMode = [AWERecorderTipsAndBubbleManager shareInstance].actureRecordBtnMode;
                //这里的逻辑改动是为了兼容60s/180s长视频并存的case，最大时长需要根据当前的lengthMode来确认
                //The logical change here is to be compatible with the case of 60s / 180s video coexistence, the maximum duration needs to be confirmed according to the current lengthMode
                if (lengthMode == ACCRecordLengthModeStandard) {//15s-button
                    if (duration < [self.config standardVideoMaxSeconds]) {//music duration < 15s
                        bubbleStr = [NSString stringWithFormat:kPropReuseOriginAudioBubblePrompt, maxRecordDuration];
                    }
                } else if (lengthMode == ACCRecordLengthModeLong ||
                           lengthMode == ACCRecordLengthMode60Seconds ||
                           lengthMode == ACCRecordLengthMode60Seconds) {//60s-button || 3min-button
                    CGFloat currentMaxDuration = [self.config currentVideoMaxSeconds];
                    if (duration < currentMaxDuration && currentMaxDuration > [self.config standardVideoMaxSeconds]){//music duration < 60s or 180s
                        bubbleStr = [NSString stringWithFormat:kPropReuseOriginAudioBubblePrompt, maxRecordDuration];
                    }
                }
                trackBlock(isFirstEmbed);

            } else {//更换了音乐,考虑版权限制15S
                if ([AWERecorderTipsAndBubbleManager shareInstance].actureRecordBtnMode == ACCRecordLengthModeStandard &&
                    duration >= [self.config standardVideoMaxSeconds]) {//15s-button, music duration >= 15s
                    bubbleStr = nil;
                } else if (duration >= [self.config videoMaxSeconds] &&
                            [self.config videoMaxSeconds] > [self.config standardVideoMaxSeconds]) {//60s-button, music duration >= 60s || 3min-button, music duration >= 180s
                    bubbleStr = nil;
                }
            }

            //display bubble
            [self showTip:bubbleStr isFirstEmbed:isFirstEmbed];

        } else {
            [self showTip:nil isFirstEmbed:isFirstEmbed];
        }
    }
}

#pragma mark - Signals

- (RACSignal *)downloadMusicForStickerSignal
{
    return self.downloadMusicForStickerSubject;
}

- (RACSubject *)downloadMusicForStickerSubject
{
    if (!_downloadMusicForStickerSubject) {
        _downloadMusicForStickerSubject = [RACSubject subject];
    }
    return _downloadMusicForStickerSubject;
}

- (RACSignal<ACCRecordSelectMusicCoverInfo *> *)musicCoverSignal
{
    return self.musicCoverSubject;
}

- (RACSubject *)musicCoverSubject
{
    if (!_musicCoverSubject) {
        _musicCoverSubject = [RACSubject subject];
    }
    
    return _musicCoverSubject;
}

- (RACSignal *)selectMusicAnimationSignal
{
    return self.selectMusicAnimationSubject;
}

- (RACSubject *)selectMusicAnimationSubject
{
    if (!_selectMusicAnimationSubject) {
        _selectMusicAnimationSubject = [RACSubject subject];
    }
    
    return _selectMusicAnimationSubject;
}

- (RACSignal<NSError *> *)bindMusicErrorSignal
{
    return self.bindMusicErrorSubject;
}

- (RACSubject *)bindMusicErrorSubject
{
    if (!_bindMusicErrorSubject) {
        _bindMusicErrorSubject = [RACSubject subject];
    }
    
    return _bindMusicErrorSubject;
}

- (RACSignal<NSNumber *> *)selectMusicPanelShowSignal
{
    return self.selectMusicPanelShowSubject;
}

- (RACSubject *)selectMusicPanelShowSubject
{
    if (!_selectMusicPanelShowSubject) {
        _selectMusicPanelShowSubject = [RACSubject subject];
    }
    return _selectMusicPanelShowSubject;
}

- (RACSignal *)cancelMusicSignal
{
    return self.cancelMusicSubject;
}

- (RACSubject *)cancelMusicSubject
{
    if (!_cancelMusicSubject) {
        _cancelMusicSubject = [RACSubject subject];
    }
    
    return _cancelMusicSubject;
}

- (RACSignal *)pickMusicSignal
{
    return self.pickMusicSubject;
}

- (RACSubject *)pickMusicSubject
{
    if (!_pickMusicSubject) {
        _pickMusicSubject = [RACSubject subject];
    }
    
    return _pickMusicSubject;
}

- (RACSignal<ACCRecordSelectMusicTipType> *)musicTipSignal
{
    return self.musicTipSubject;
}

- (RACSubject *)musicTipSubject
{
    if (!_musicTipSubject) {
        _musicTipSubject = [RACReplaySubject replaySubjectWithCapacity:1];
    }
    
    return _musicTipSubject;
}

- (RACSignal<NSString *> *)muteTipSignal
{
    return self.muteTipSubject;
}

- (RACSubject *)muteTipSubject
{
    if (!_muteTipSubject) {
        _muteTipSubject = [RACSubject subject];
    }
    
    return _muteTipSubject;
}

@end
