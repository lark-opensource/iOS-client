//
//  ACCVideoEditFlowControlViewModel.m
//  CameraClient
//
//  Created by chengfei xiao on 2020/5/15.
//

#import "AWERepoContextModel.h"
#import "AWERepoCutSameModel.h"
#import "AWERepoVideoInfoModel.h"
#import "AWERepoVoiceChangerModel.h"
#import "AWERepoTrackModel.h"
#import "AWERepoCaptionModel.h"
#import "AWERepoPublishConfigModel.h"
#import "AWERepoChallengeModel.h"
#import "ACCVideoEditFlowControlViewModel.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CameraClient/ACCPublishNetServiceProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import "AWEVideoPublishViewModel+FilterEdit.h"
#import "ACCMainServiceProtocol.h"
#import "AWEMVTemplateModel.h"
#import "ACCRepoPOIModelProtocol.h"
#import <TTVideoEditor/IESMMTrackerManager.h>
#import <TTVideoEditor/IESMMMediaSizeUtil.h>
#import <TTVideoEditor/IESMMParamModule.h>
#import "ACCRepoBirthdayModel.h"
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CreationKitArch/ACCRepoTranscodingModel.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "ACCDraftProtocol.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "ACCStickerServiceProtocol.h"
#import <CameraClient/ACCRepoRedPacketModel.h>
#import "ACCVideoEditFlowControlService.h"
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/ACCRepoPropModel.h>
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CameraClient/ACCRepoEditEffectModel.h>
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import <CreationKitArch/ACCRepoMVModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CameraClient/AWERepoPropModel.h>
#import <CameraClient/AWERepoMVModel.h>
#import <CameraClient/ACCRepoQuickStoryModel.h>
#import <CameraClient/AWERepoDuetModel.h>
#import <CameraClient/AWERepoAuthorityModel.h>
#import <CameraClientModel/ACCVideoReplyModel.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import <CameraClient/ACCRepoKaraokeModelProtocol.h>
#import <CreationKitArch/ACCRepoFilterModel.h>
#import <CreationKitArch/ACCRepoBeautyModel.h>
#import <CameraClient/AWERepoDraftModel.h>
#import <CreationKitArch/ACCRepoStickerModel.h>
#import "AWERepoStickerModel.h"
#import "ACCRepoImageAlbumInfoModel+ACCStickerLogic.h"
#import "ACCVideoPublishProtocol.h"
#import "ACCImageAlbumData.h"
#import "AWEVideoFragmentInfo.h"
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import "ACCRepoSmartMovieInfoModel.h"
#import <CameraClient/ACCIMModuleServiceProtocol.h>
#import "ACCStudioGlobalConfig.h"
#import <CameraClient/AWEInteractionVideoShareStickerModel.h>
#import <CameraClientModel/AWEVideoRecordButtonType.h>
#import <CameraClientModel/ACCVideoCanvasType.h>
#import <CameraClient/ACCRepoAudioModeModel.h>
#import <CameraClient/ACCFlowerRedPacketHelperProtocol.h>
#import "ACCFlowerCampaignManagerProtocol.h"
#import <CreationKitArch/AWEInteractionStickerModel.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CameraClient/ACCStudioLiteRedPacket.h>


static BOOL is_string_equal(NSString *a, NSString *b)
{
    if (!a && !b) {
        return YES;
    }
    if (!a || !b) {
        return NO;
    }
    return  [a isEqualToString:b];
}

static BOOL is_one_null_and_other_nonnull(NSObject *a, NSObject *b)
{
    return (a && !b) || (!a && b);
}

@interface ACCVideoEditFlowControlViewModel ()

@property (nonatomic, strong, readwrite) AWEResourceUploadParametersResponseModel *uploadParamsCache;

@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;
@property (nonatomic, strong) id<ACCVideoEditFlowControlService> flowService;

@property (nonatomic, strong) ACCCameraSubscription *subscription;

@property (nonatomic, strong, readwrite) RACSubject *publishPrivateWorkSubject;

@property (nonatomic, strong) NSNumber *isFlowerRedpacketOneButtonModeCache;

@end

@implementation ACCVideoEditFlowControlViewModel

IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, flowService, ACCVideoEditFlowControlService)

- (void)dealloc
{
    [_publishPrivateWorkSubject sendCompleted];
    ACCLog(@"%@ dealloc", NSStringFromSelector(_cmd));
}

- (void)clearBeforeBack
{
    if (!self.repository.repoDraft.isDraft && self.repository.repoContext.videoSource == AWEVideoSourceCapture) {
        // only for backup mode
        if (!self.repository.repoDraft.isBackUp && self.inputData.sourceModel != nil) {
            [ACCDraft() saveDraftWithPublishViewModel:self.inputData.sourceModel
                                                video:self.inputData.sourceModel.repoVideoInfo.video
                                               backup:!self.inputData.sourceModel.repoDraft.originalDraft
                                           completion:^(BOOL success, NSError *error) {}];
        } else {
            AWERepoPublishConfigModel *configRepo = self.repository.repoPublishConfig;
            configRepo.dynamicCoverStartTime = 0;
            configRepo.coverTitleSelectedId = nil;
            configRepo.coverTitleSelectedFrom = nil;
            configRepo.coverImage = nil;
            configRepo.coverTextModel = nil;
            configRepo.coverTextImage = nil;
            configRepo.cropedCoverImage = nil;
            configRepo.coverCropOffset = CGPointZero;
            self.repository.repoProp.totalStickerSavePhotos = [self.repository.repoReshoot getStickerSavePhotoCount];
            if ([self isVideoEdited]) {
                [self.repository.repoVideoInfo.video clearAllEffectAndTimeMachine];
                [self.inputData.publishModel.repoEditEffect.displayTimeRanges removeAllObjects];
                self.repository.repoSticker.interactionStickers = nil;
                [self notifyDataClearForBackup];
            }
            self.repository.repoFlowControl.step = AWEPublishFlowStepCapture;
            // all logic above is to clear model to shoot status; should better to split model to shoot page / edit page, to avoid rewirte each other using same creation id
            [ACCDraft() saveDraftWithPublishViewModel:self.inputData.publishModel
                                                video:self.repository.repoVideoInfo.video
                                               backup:!self.repository.repoDraft.originalDraft
                                           completion:^(BOOL success, NSError *error) {}];
        }
    } else {
        // It seems that async will cause the clear un-completed when App kills
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [ACCDraft() clearAllEditBackUps];
        });
    }
}

- (BOOL)isVideoEdited
{
    NSArray *infoStickers = self.repository.repoVideoInfo.video.infoStickers;

    BOOL hasVoiceEffect = self.repository.repoVoiceChanger.voiceEffectType != ACCVoiceEffectTypeNone;
    
    BOOL hasVideoReshootClip;
    if (self.repository.repoDuet.isDuet && self.repository.repoDuet.isDuetUpload) { // 上传合拍多轨默认会裁剪视频
        hasVideoReshootClip = NO;
    } else {
        hasVideoReshootClip = [self.repository.repoReshoot hasVideoClipEdits];
    }
    
    let service = IESAutoInline(self.serviceProvider, ACCStickerServiceProtocol);
    BOOL hasStickers = [service hasStickers];

    ACCVideoCanvasSource *canvas = self.repository.repoVideoInfo.canvasSource;
    BOOL canvasMoved = canvas && (canvas.center.x != 0 || canvas.center.y != 0 || canvas.rotation != 0);

    BOOL hasVideoEditClip = self.editService.preview.hasEditClip;
    
    BOOL hasFlowerRedPacket = [self.repository.repoRedPacket didBindRedpacketInfo];

    return self.repository.repoVideoInfo.video.effect_timeRange.count
    || self.repository.repoVideoInfo.video.effect_timeMachineType != HTSPlayerTimeMachineNormal
    || !ACC_isEmptyArray(infoStickers)
    || [self.repository.repoSticker.interactionStickers count]
    || hasVoiceEffect
    || hasStickers
    || canvasMoved
    || hasVideoReshootClip
    || hasVideoEditClip
    || hasFlowerRedPacket;
}

- (BOOL)isDraftEdited
{
    // 音乐
    {
        ACCRepoMusicModel *currentInfo = self.repository.repoMusic;
        ACCRepoMusicModel *draftInfo = self.repository.repoDraft.originalModel.repoMusic;
        if (is_one_null_and_other_nonnull(currentInfo, draftInfo)) {
            return YES;
        }
        if (currentInfo && draftInfo) {
            if (!is_string_equal(currentInfo.music.musicID, draftInfo.music.musicID) ||
                !ACC_FLOAT_EQUAL_TO(currentInfo.voiceVolume, draftInfo.voiceVolume) ||
                !ACC_FLOAT_EQUAL_TO(currentInfo.musicVolume, draftInfo.musicVolume) ||
                !ACC_FLOAT_EQUAL_TO(currentInfo.audioRange.location, draftInfo.audioRange.location) ||
                !ACC_FLOAT_EQUAL_TO(currentInfo.audioRange.length, draftInfo.audioRange.length)) {
                return YES;
            }
        }
    }

    // 裁剪
    if (self.editService.preview.hasEditClip) {
        return YES;
    }

    // 贴纸
    if (self.repository.repoContext.videoType == AWEVideoTypeImageAlbum) {
        ACCRepoImageAlbumInfoModel *currentInfo = self.repository.repoImageAlbumInfo;
        ACCRepoImageAlbumInfoModel *draftInfo = self.repository.repoDraft.originalModel.repoImageAlbumInfo;
        if ([currentInfo numberOfStickers] != [draftInfo numberOfStickers]) {
            return YES;
        }
    } else {
        let stickerService = IESAutoInline(self.serviceProvider, ACCStickerServiceProtocol);
        const NSInteger currentCount = stickerService.stickerCount;
        if (self.originalStickerCount && self.originalStickerCount.integerValue != currentCount) {
            return YES;
        }
    }
    if (self.repository.repoContext.isStickerEdited) {
        return YES;
    }

    // 模版
    {
        ACCRepoMVModel *currentInfo = self.repository.repoMV;
        ACCRepoMVModel *draftInfo = self.repository.repoDraft.originalModel.repoMV;
        if (is_one_null_and_other_nonnull(currentInfo, draftInfo)) {
            return YES;
        }
        if (currentInfo && draftInfo) {
            if (!is_string_equal(currentInfo.templateModelId, draftInfo.templateModelId) ||
                !is_string_equal(currentInfo.templateMusicId, draftInfo.templateMusicId)) {
                return YES;
            }
        }
    }

    // 特效
    {
        ACCRepoEditEffectModel *currentInfo = self.repository.repoEditEffect;
        ACCRepoEditEffectModel *draftInfo = self.repository.repoDraft.originalModel.repoEditEffect;
        if (is_one_null_and_other_nonnull(currentInfo, draftInfo)) {
            return YES;
        }
        if (currentInfo && draftInfo) {
            if (![currentInfo isEqualToObject:draftInfo]) {
                return YES;
            }
        }
    }
    
    // 设置
    {
        AWERepoAuthorityModel *currentInfo = self.repository.repoAuthority;
        AWERepoAuthorityModel *draftInfo = self.repository.repoDraft.originalModel.repoAuthority;
        if (is_one_null_and_other_nonnull(currentInfo, draftInfo)) {
            return YES;
        }
        if (currentInfo && draftInfo) {
            if (![currentInfo isEqualToObject:draftInfo]) {
                return YES;
            }
        }
    }

    // 滤镜
    {
        ACCRepoFilterModel *currentInfo = self.repository.repoFilter;
        ACCRepoFilterModel *draftInfo = self.repository.repoDraft.originalModel.repoFilter;
        if (is_one_null_and_other_nonnull(currentInfo, draftInfo)) {
            return YES;
        }
        if (currentInfo && draftInfo) {
            if (!is_string_equal(currentInfo.colorFilterId, draftInfo.colorFilterId) ||
                !ACC_FLOAT_EQUAL_TO(currentInfo.colorFilterIntensityRatio.doubleValue, draftInfo.colorFilterIntensityRatio.doubleValue)) {
                return YES;
            }
        }
    }

    // 美化
    {
        ACCRepoBeautyModel *currentInfo = self.repository.repoBeauty;
        ACCRepoBeautyModel *draftInfo = self.repository.repoDraft.originalModel.repoBeauty;
        if (is_one_null_and_other_nonnull(currentInfo, draftInfo)) {
            return YES;
        }
        if (currentInfo && draftInfo) {
            if (![currentInfo isEqualToObject:draftInfo]) {
                return YES;
            }
        }
    }

    // 自动字幕
    {
        AWEStudioCaptionInfoModel *currentInfo = self.repository.repoCaption.captionInfo;
        AWEStudioCaptionInfoModel *draftInfo = self.repository.repoDraft.originalModel.repoCaption.captionInfo;
        if (is_one_null_and_other_nonnull(currentInfo, draftInfo)) {
            return YES;
        }
        if (currentInfo.captions.count != draftInfo.captions.count) {
            return YES;
        }
        for (NSInteger idx = 0; idx < currentInfo.captions.count; ++idx) {
            AWEStudioCaptionModel *currentCaption = currentInfo.captions[idx];
            AWEStudioCaptionModel *draftCaption = draftInfo.captions[idx];
            if (!is_string_equal(currentCaption.text, draftCaption.text)) {
                return YES;
            }
        }
    }

    // 画质增强
    AWERepoVideoInfoModel *currentVideoInfo = self.repository.repoVideoInfo;
    AWERepoVideoInfoModel *draftVideoInfo = self.repository.repoDraft.originalModel.repoVideoInfo;
    if (currentVideoInfo.enableHDRNet != draftVideoInfo.enableHDRNet) {
        return YES;
    }

    // 变声
    {
        AWERepoVoiceChangerModel *currentInfo = self.repository.repoVoiceChanger;
        AWERepoVoiceChangerModel *draftInfo = self.repository.repoDraft.originalModel.repoVoiceChanger;
        if (is_one_null_and_other_nonnull(currentInfo, draftInfo)) {
            return YES;
        }
        if (currentInfo && draftInfo) {
            if (![currentInfo isEqualToObject:draftInfo]) {
                return YES;
            }
        }
    }

    // 画布
    if (currentVideoInfo.canvasType != draftVideoInfo.canvasType ||
        is_one_null_and_other_nonnull(currentVideoInfo.canvasSource, draftVideoInfo.canvasSource)) {
        return YES;
    }
    if (currentVideoInfo.canvasSource && draftVideoInfo.canvasSource) {
        if (![currentVideoInfo.canvasSource isEqualToObject:draftVideoInfo.canvasSource]) {
            return YES;
        }
    }

    // 图集
    if (self.repository.repoContext.videoType == AWEVideoTypeImageAlbum) {
        ACCRepoImageAlbumInfoModel *currentInfo = self.repository.repoImageAlbumInfo;
        ACCRepoImageAlbumInfoModel *draftInfo = self.repository.repoDraft.originalModel.repoImageAlbumInfo;
        if (currentInfo.imageAlbumData.imageAlbumItems.count != draftInfo.imageAlbumData.imageAlbumItems.count) {
            return YES;
        }
        for (NSInteger idx = 0; idx < currentInfo.imageAlbumData.imageAlbumItems.count; ++idx) {
            ACCImageAlbumItemModel *current = currentInfo.imageAlbumData.imageAlbumItems[idx];
            ACCImageAlbumItemModel *draft = draftInfo.imageAlbumData.imageAlbumItems[idx];
            if (current.HDRInfo.enableHDRNet != draft.HDRInfo.enableHDRNet) {
                return YES;
            }
            if (!is_string_equal(current.filterInfo.effectIdentifier, draft.filterInfo.effectIdentifier) ||
                !ACC_FLOAT_EQUAL_TO(current.filterInfo.slideRatio.doubleValue, draft.filterInfo.slideRatio.doubleValue) ||
                !ACC_FLOAT_EQUAL_TO(current.filterInfo.filterIntensityRatio.doubleValue, draft.filterInfo.filterIntensityRatio.doubleValue)) {
                return YES;
            }
            
            // 图片裁切
            if (current.cropInfo.cropRatio != draft.cropInfo.cropRatio ||
                current.cropInfo.zoomScale != draft.cropInfo.zoomScale ||
                !CGPointEqualToPoint(current.cropInfo.contentOffset, draft.cropInfo.contentOffset) ||
                !CGRectEqualToRect(current.cropInfo.cropRect, draft.cropInfo.cropRect)) {
                return YES;
            }
        }
    }

    return NO;
}

- (RACSignal *)publishPrivateWorkSignal
{
    return self.publishPrivateWorkSubject;
}

- (RACSubject *)publishPrivateWorkSubject
{
    if (!_publishPrivateWorkSubject) {
        _publishPrivateWorkSubject = [RACSubject subject];
    }
    return _publishPrivateWorkSubject;
}

#pragma mark -

- (void)fetchUploadParams
{
    if(![IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin]){
        return;
    }
    @weakify(self)
    [IESAutoInline(self.serviceProvider, ACCPublishNetServiceProtocol) requestUploadParametersWithCompletion:^(AWEResourceUploadParametersResponseModel * _Nullable model, NSError * _Nullable error) {
        if (model && !error) {
            @strongify(self)
            self.uploadParamsCache = model;
            [ACCMonitor() trackService:@"aweme_publish_request_params_rate" status:0 extra:nil];
            [self.subscription performEventSelector:@selector(didFetchUploadParams:)realPerformer:^(id<ACCVideoEditFlowControlSubscriber> subscriber) {
                [subscriber didFetchUploadParams:model];
            }];
        } else {
            [ACCMonitor() trackService:@"aweme_publish_request_params_rate" status:1 extra:@{ @"errorCode" : @(error.code),
                                                                                                    @"errorDomain" : error.domain ? : @"", }];
        }
    }];
}

- (NSMutableDictionary *)extraAttributes
{
    if (self.repository.repoContext.videoType == AWEVideoTypePhotoMovie) {
        return [@{@"media_type" : @"pic_movie"} mutableCopy];
    }
    return [@{@"is_photo" : self.repository.repoContext.videoType == AWEVideoTypePicture ? @1 : @0} mutableCopy];
}

- (void)trackPlayPerformanceWithNextActionName:(NSString *)nextAction
{
    AVAssetTrack *videoTrack = [self.repository.repoVideoInfo.video.videoAssets.firstObject tracksWithMediaType:AVMediaTypeVideo].firstObject;
    if (!videoTrack) {
        return;
    }
    NSDictionary *referExtra = self.repository.repoTrack.referExtra;
    NSDictionary *videoFragmentInfoDictionary = [self.inputData.publishModel.repoTrack videoFragmentInfoDictionary];
    IESMMTrackerManager *mmTracker = [IESMMTrackerManager shareInstance];
       
    CGSize videoSize = videoTrack.naturalSize;
    NSString *size = [NSString stringWithFormat:@"%@*%@",@(videoSize.width),@(videoSize.height)];
    NSString *fileBitRate = [NSString stringWithFormat:@"%ld", (long)(roundf(videoTrack.estimatedDataRate/1000.f))]; //kbps
    NSString *settingBitRate = [NSString stringWithFormat:@"%ld", (long)(roundf(self.repository.repoVideoInfo.video.transParam.bitrate/1000.f))]; //kbps
    NSString *duration_ms = [NSString stringWithFormat:@"%.1f",self.repository.repoVideoInfo.video.totalVideoDuration * 1000.f];
    CGFloat fileFPS = videoTrack.nominalFrameRate;
    CGFloat playFPS = [mmTracker getPlayFps];
    CGSize renderSize = videoSize;
    if ([IESMMParamModule sharedInstance].useMaxFrameSizeLimit) {
        BOOL needResize = [IESMMMediaSizeUtil issourceSize:videoSize exceedLimitWithTargetSize:[IESMMParamModule sharedInstance].maxEditSize];
        if (needResize) {
            renderSize = [IESMMMediaSizeUtil getSizeWithSourceSize:videoSize targetSize:[IESMMParamModule sharedInstance].maxEditSize];
        }
    }
    
    NSMutableDictionary *params = @{@"play_fps":@(playFPS),
                                    @"file_fps":@(fileFPS),
                                    @"file_bitrate":fileBitRate?:@"",
                                    @"bitrate":settingBitRate?:@"",
                                    @"resolution":size,
                                    @"duration":duration_ms,
                                    @"enter_from":@"video_edit_page",
                                    @"shoot_way":referExtra[@"shoot_way"] ?: @"",
                                    @"creation_id":referExtra[@"creation_id"] ?: @"",
                                    @"creation_session_id":referExtra[@"creation_session_id"] ?: @"",
                                    @"content_source":referExtra[@"content_source"] ?: @"",
                                    @"content_type":referExtra[@"content_type"] ?: @"",
                                    @"prop_list":videoFragmentInfoDictionary[@"prop_list"] ?: @"",
                                    @"filter_id_list":videoFragmentInfoDictionary[@"filter_id_list"] ?: @"",
                                    @"next_action":nextAction?:@"",
                                    @"preview_resolution": [NSString stringWithFormat:@"%@*%@",@(renderSize.width),@(renderSize.height)]}.mutableCopy;
    [params addEntriesFromDictionary:self.repository.repoRecordInfo.beautifyTrackInfoDic?:@{}];
    
    [ACCTracker() trackEvent:@"tool_performance_edit_preview" params:params.copy];
}

- (void)trackWhenGotoPublish
{
    NSMutableDictionary *extraInfo = [NSMutableDictionary dictionary];
    if (!ACC_isEmptyString(self.repository.repoMV.templateModelId)) {
        [extraInfo setObject:self.repository.repoMV.templateModelId forKey:@"mv_id"];
    }

    [extraInfo addEntriesFromDictionary:[self.repository.repoTrack mediaCountInfo]];
    if (!ACC_isEmptyArray(self.repository.repoCaption.captionInfo.captions)) {
        [extraInfo setObject:@(1) forKey:@"is_subtitled"];
    }
    NSMutableArray *pic2VideoSourceArray = @[].mutableCopy;
    NSMutableArray *backgroundIDArray = @[].mutableCopy;
    NSMutableArray *backgroundTypeArray = @[].mutableCopy;
    [self.repository.repoVideoInfo.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.pic2VideoSource && ![obj.pic2VideoSource isEqualToString:@"none"]) {
            [pic2VideoSourceArray addObject:obj.pic2VideoSource];
        }
        if (obj.backgroundID) {
            [backgroundIDArray addObject:obj.backgroundID];
        }
        if (obj.backgroundType) {
            [backgroundTypeArray addObject:obj.backgroundType];
        }
    }];
    if (pic2VideoSourceArray.count > 0) {
        extraInfo[@"picture_source"] = [pic2VideoSourceArray componentsJoinedByString:@","];
    }

    __block NSArray *locationInfos = nil;
    [self.repository enumerateExtensionModels:YES requireProtocol:@protocol(ACCRepositoryEditContextProtocol) requireSelector:@selector(locationInfos) block:^(NSString *clzStr, id model, BOOL *stop) {
        locationInfos = [model locationInfos];
        *stop = YES;
    }];

    [extraInfo setObject:@(locationInfos.count) forKey:@"location_gps_cnt"];
    id<ACCMusicModelProtocol> music = self.repository.repoMusic.music;
    if (!self.repository.repoMusic.musicSelectedFrom) {
        if (music.musicSelectedFrom && music.awe_selectPageName) {
            self.repository.repoMusic.musicSelectedFrom = music.musicSelectedFrom;
        } else if ([self.repository.repoTrack.referString isEqualToString:@"prop_page"] || [self.repository.repoTrack.referString isEqualToString:@"prop_reuse"]) {
            self.repository.repoMusic.musicSelectedFrom = @"prop_auto";
        } else {
            self.repository.repoMusic.musicSelectedFrom = @"original";
        }
    }
    [extraInfo addEntriesFromDictionary:[self.repository.repoSticker customStickersInfos]];
    [extraInfo addEntriesFromDictionary:[self.repository.repoSticker textStickerTrackInfo]];

    extraInfo[@"tab_name"] = self.repository.repoTrack.tabName;
    
    extraInfo[@"friend_label"] = self.repository.repoTrack.friendLabel ? : @"";

    AWERepoStickerModel *repoSticker = [self.repository extensionModelOfClass:[AWERepoStickerModel class]];
    [extraInfo addEntriesFromDictionary:[repoSticker socialStickerTrackInfoDic]];
    [extraInfo addEntriesFromDictionary:[self.repository.repoTrack performanceTrackInfoDic]];
    [extraInfo addEntriesFromDictionary:[repoSticker videoCommentStickerTrackInfo]];
    [extraInfo addEntriesFromDictionary:self.repository.repoRecordInfo.beautifyTrackInfoDic ?: @{}];
    [extraInfo addEntriesFromDictionary:[self.repository.repoPublishConfig recommendedAICoverTrackInfo]];

    if (!ACC_isEmptyString(self.repository.repoTrack.storyGuidePlusIconType)) {
        extraInfo[@"plus_icon_type"] = self.repository.repoTrack.storyGuidePlusIconType;
    }
    extraInfo[@"from_group_id"] = [IESAutoInline(self.serviceProvider, ACCMainServiceProtocol) lastHomePagePlayingAwemeID];
    extraInfo[@"shoot_enter_from"] = self.repository.repoUploadInfo.extraDict[@"shoot_enter_from"];
    if ([self.repository.repoSticker.interactionStickers acc_match:^BOOL(AWEInteractionStickerModel * _Nonnull item) {
        return item.type == AWEInteractionStickerTypeDaily;
    }] != nil) {
        extraInfo[@"has_daily_sticker"] = @1;
    }
    if (self.repository.repoBirthday.isBirthdayPost) {
        extraInfo[@"shoot_way"] = @"happy_birthday";
    }
    if (self.repository.repoBirthday.isIMBirthdayPost) {
        extraInfo[@"shoot_way"] = @"birthday_card";
    }
    id<ACCRepoPOIModelProtocol> poiModel = [self.repository extensionModelOfProtocol:@protocol(ACCRepoPOIModelProtocol)];
    if (poiModel) {
        extraInfo[@"poi_id"] = [poiModel acc_poiID];
    }
    NSDictionary *vagueStatusParams = [poiModel acc_vagueStatusParam];
    if (vagueStatusParams) {
        [extraInfo addEntriesFromDictionary:vagueStatusParams];
    }
    extraInfo[@"content_source"] = self.repository.repoTrack.referExtra[@"content_source"];
    extraInfo[@"shoot_way"] = self.repository.repoTrack.referExtra[@"shoot_way"];
    extraInfo[@"creation_session_id"] = self.repository.repoTrack.creationSessionId ?: @"";
    extraInfo[@"mp_id"] = self.inputData.publishModel.repoUploadInfo.extraDict[@"appID"];
    if (self.repository.repoCutSame.isNewCutSameOrSmartFilming) {
        [extraInfo addEntriesFromDictionary:[self.repository.repoCutSame smartVideoAdditionParamsForPublishTrack]];
    }

    if (self.editService.preview != nil) {
        CGSize size = [self.editService.preview getVideoSize];
        extraInfo[@"is_landscape"] = ACC_FLOAT_GREATER_THAN(size.width, size.height) ? @1 : @0;
    }

    if (self.repository.repoTrack.schemaTrackParmForActivity) {
        [extraInfo addEntriesFromDictionary:self.repository.repoTrack.schemaTrackParmForActivity];
    }
    
    extraInfo[@"is_meteormode"] = @(self.repository.repoContext.isMeteorMode ? 1 : 0);
    
    if (self.repository.repoContext.videoType == AWEVideoTypeKaraoke) {
        id<ACCRepoKaraokeModelProtocol> repoKaraoke = [self.repository extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
        // get [music_selected_from, music_id, pop_music_id, pop_music_type] from repoKaraoke.trackParams
        [extraInfo addEntriesFromDictionary:repoKaraoke.trackParams ? : @{}];
        extraInfo[@"origin_status"] = repoKaraoke.editModel.useOriginalSong && repoKaraoke.editModel.originalSongTimeList.count ? @"on" : @"off";
        if (repoKaraoke.recordMode == ACCKaraokeRecordModeAudio) {
            extraInfo[@"background_material"] = repoKaraoke.editModel.audioBGImages.count ? @"personal" : @"system";
        }
    } else {
        extraInfo[@"music_selected_from"] = self.repository.repoMusic.musicSelectedFrom;
    }

    extraInfo[@"prop_selected_from"] = self.repository.repoProp.propSelectedFrom;
    [extraInfo addEntriesFromDictionary:self.repository.repoTrack.extraTrackInfo];
    [extraInfo addEntriesFromDictionary:self.repository.repoTrack.referExtra];
    [extraInfo setValue:@(self.repository.repoTrack.hdrScene) forKey:@"is_quality_improve"];

    if (self.repository.repoChallenge.challenge.itemID.length) {
        extraInfo[@"tag_id"] = self.repository.repoChallenge.challenge.itemID;
    }
    
    if (!ACC_isEmptyArray(self.repository.repoSticker.shootSameStickerModels)) {
        [self.repository.repoSticker.shootSameStickerModels enumerateObjectsUsingBlock:^(ACCShootSameStickerModel * _Nonnull shootSameStickerModel, NSUInteger idx, BOOL * _Nonnull stop) {
            if (shootSameStickerModel.stickerType == AWEInteractionStickerTypeComment) {
                extraInfo[@"reply_object"] =  @"comment";
                if (shootSameStickerModel.isDeleted) {
                    extraInfo[@"is_retain_sticker"] = @(0);
                } else {
                    extraInfo[@"is_retain_sticker"] = @(1);
                }
            }
        }];
    }
    
    if (self.repository.repoSticker.videoReplyModel != nil) {
        extraInfo[@"reply_object"] =  @"video";
        
        if (self.repository.repoSticker.videoReplyModel.isDeleted) {
            extraInfo[@"is_retain_sticker"] = @(0);
        } else {
            extraInfo[@"is_retain_sticker"] = @(1);
        }
    }
    
    // 智能照片电影
    if ([self.repository.repoSmartMovie isSmartMovieMode]) {
        extraInfo[@"is_smart_slideshow"] = @(1);
    }
    
    NSDictionary *liteParams = [ACCStudioLiteRedPacket() enterVideoEditPageParams:self.repository];
    if (liteParams) {
        [extraInfo addEntriesFromDictionary:liteParams];
    }
    NSDictionary *qualityParams = [ACCStudioLiteRedPacket() quailtiyGuideTrackParams:self.repository];
    if (qualityParams) {
        [extraInfo addEntriesFromDictionary:qualityParams];
    }
    
    NSDictionary *redpacketTrack = [self.repository.repoRedPacket trackInfo];
    if (!ACC_isEmptyDictionary(redpacketTrack)) {
        [extraInfo addEntriesFromDictionary:redpacketTrack];
    }
    
    // 一键成片
    if ([extraInfo[@"content_type"] isEqual:@"ai_upload"]) {
        AWERepoMVModel *repoMV = [self.repository extensionModelOfClass:AWERepoMVModel.class];
        extraInfo[@"ai_upload_entrance"] = repoMV.oneKeyMVEnterfrom;
    }

    if ([self.repository.repoImageAlbumInfo isImageAlbumEdit]) {
        NSDictionary *dictionary = [self.repository.repoImageAlbumInfo tagsTrackInfo];
        if (dictionary != nil) {
            [extraInfo addEntriesFromDictionary:dictionary];
        }
        
        NSDictionary *cropTrackInfo = [self.repository.repoImageAlbumInfo cropTrackInfo];
        if (cropTrackInfo != nil) {
            [extraInfo addEntriesFromDictionary:cropTrackInfo];
        }
    }
    [self.inputData.publishModel trackPostEvent:@"enter_video_post_page" enterMethod:@"click_next_button" extraInfo:[extraInfo copy]];
}

- (void)trackEnterVideoEditPageEvent
{
    [self.class trackEnterVideoEditPageWith:self.repository fromGroup:[IESAutoInline(self.serviceProvider, ACCMainServiceProtocol) lastHomePagePlayingAwemeID] tracker:ACCTracker()];
}

+ (void)trackEnterVideoEditPageWith:(AWEVideoPublishViewModel *)repository fromGroup:(NSString *)fromGroup tracker:(id<ACCTrackProtocol>)tracker
{
    NSMutableDictionary *params = repository.repoTranscoding.videoQualityTraceInfo;
    if (repository.repoTrack.referExtra) {
        [params addEntriesFromDictionary:repository.repoTrack.referExtra];
    }
    // 分段视频滤镜id和name
    NSDictionary *videoFragmentInfo = repository.repoTrack.videoFragmentInfoDictionary;
    if (videoFragmentInfo) {
        [params addEntriesFromDictionary:videoFragmentInfo];
    }
    if (!ACC_isEmptyString(repository.repoTrack.enterEditPageMethod)) {
        params[@"enter_method"] = repository.repoTrack.enterEditPageMethod;
    }
    
    AVAssetTrack *videoTrack = [repository.repoVideoInfo.video.videoAssets.firstObject tracksWithMediaType:AVMediaTypeVideo].firstObject;
    if (videoTrack) {
        params[@"edit_fps"] = @(videoTrack.nominalFrameRate);
    }
    [params removeObjectForKey:@"fps"];

    if (!ACC_isEmptyString(repository.repoMV.templateModelId)) {
        params[@"mv_id"] = repository.repoMV.templateModelId;
    }
    [params addEntriesFromDictionary:[repository.repoTrack mediaCountInfo]];

    // performanceDic
    NSDictionary *performanceDic = [repository.repoTrack performanceTrackInfoDic];
    if (performanceDic) {
        [params addEntriesFromDictionary:performanceDic];
    }
    params[@"mv_id"] = repository.repoMV.templateModelId ?: @"";

    //pic2Video track
    NSMutableArray *pic2VideoSourceArray = @[].mutableCopy;
    NSMutableArray *backgroundIDArray = @[].mutableCopy;
    NSMutableArray *backgroundTypeArray = @[].mutableCopy;
    [repository.repoVideoInfo.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.pic2VideoSource && ![obj.pic2VideoSource isEqualToString:@"none"]) {
            [pic2VideoSourceArray addObject:obj.pic2VideoSource];
        }
        if (obj.backgroundID) {
            [backgroundIDArray addObject:obj.backgroundID];
        }
        if (obj.backgroundType) {
            [backgroundTypeArray addObject:obj.backgroundType];
        }
    }];
    if (pic2VideoSourceArray.count > 0) {
        params[@"picture_source"] = [pic2VideoSourceArray componentsJoinedByString:@","];
    }
    NSDictionary *beautifyDic = [repository.repoRecordInfo beautifyTrackInfoDic];
    if (beautifyDic) {
        [params addEntriesFromDictionary:beautifyDic];
    }
    id<ACCMusicModelProtocol> music = repository.repoMusic.music;
    if (!repository.repoMusic.musicSelectedFrom) {
        if (music.musicSelectedFrom && music.awe_selectPageName) {
            repository.repoMusic.musicSelectedFrom = music.musicSelectedFrom;
        } else if ([repository.repoTrack.referString isEqualToString:@"prop_page"] || [repository.repoTrack.referString isEqualToString:@"prop_reuse"]) {
            repository.repoMusic.musicSelectedFrom = @"prop_auto";
        } else if (music) {
            repository.repoMusic.musicSelectedFrom = @"slideshow_rec";
        } else {
            repository.repoMusic.musicSelectedFrom = @"original";
        }
    }

    if (repository.repoUploadInfo.isAIVideoClipMode) {
        repository.repoMusic.musicSelectedFrom = @"sync_page_recommend";
    }

    params[@"friend_label"] = repository.repoTrack.friendLabel ? : @"";
    if (repository.repoContext.videoSource == AWEVideoSourceAlbum) {
        params[@"upload_type"] = repository.repoUploadInfo.isMultiVideoUpload ? @"multiple_content" : @"single_content";
        params[@"fast_import"] = @(repository.repoVideoInfo.isFastImportVideo);
        if (repository.repoUploadInfo.extraDict[@"fast_import_err_code"]) {
            params[@"fast_import_fail"] = repository.repoUploadInfo.extraDict[@"fast_import_err_code"];
        }
    }
    params[@"tab_name"] = repository.repoTrack.tabName;
    params[@"new_selected_method"] = repository.repoTrack.selectedMethod;

    if (!ACC_isEmptyString(repository.repoTrack.storyGuidePlusIconType)) {
        params[@"plus_icon_type"] = repository.repoTrack.storyGuidePlusIconType;
    }
    params[@"from_group_id"] = fromGroup;
    params[@"shoot_enter_from"] = repository.repoUploadInfo.extraDict[@"shoot_enter_from"];
    if (repository.repoFlowControl.videoRecordButtonType == AWEVideoRecordButtonTypeText) {
        params[@"enter_from"] = @"text_edit_page";
    }
    
    if (repository.repoQuickStory.isAvatarQuickStory) {
        params[@"enter_from"] = @"profile_photo_page";
    }
    
    if (repository.repoQuickStory.isNewCityStory) {
        params[@"content_type"] = @"profile_info";
        params[@"shoot_way"] = @"city_checkin";
    }
    
    params[@"enter_method_album"] = repository.repoUploadInfo.extraDict[@"enter_method_album"];

    if (repository.repoBirthday.isBirthdayPost) {
        params[@"shoot_way"] = @"happy_birthday";
    }
    if (repository.repoBirthday.isIMBirthdayPost) {
        params[@"shoot_way"] = @"birthday_card";
    }
    
    // tc21 effect track
    NSString *effectTrackString = [AWEVideoFragmentInfo effectTrackStringWithFragmentInfos:repository.repoVideoInfo.fragmentInfo filter:^BOOL(ACCEffectTrackParams * _Nonnull param) {
        return  param.needTrackInEdit;
    }];
    if (effectTrackString.length > 0) {
        params[@"effect_field_result"] = effectTrackString;
    }

    id<ACCRepoPOIModelProtocol> poiModel = [repository extensionModelOfProtocol:@protocol(ACCRepoPOIModelProtocol)];
    if (poiModel) {
        params[@"poi_id"] = [poiModel acc_poiID];
    }
    params[@"is_draft"] = repository.repoDraft.isDraft ? @1 : @0;
    
    NSString *eventName = repository.repoContext.recordSourceFrom == AWERecordSourceFromUnknown ? @"enter_video_edit_page" : @"im_enter_video_edit_page";

    if (repository.repoContext.recordSourceFrom == AWERecordSourceFromUnknown) {
        CGSize videoSize = CGSizeZero;
        if (repository.repoContext.videoType == AWEVideoTypeQuickStoryPicture) {
            videoSize = repository.repoPublishConfig.firstFrameImage.size;
        } else if (repository.repoVideoInfo.sizeOfVideo != nil) {
            videoSize = repository.repoVideoInfo.sizeOfVideo.CGSizeValue;
        }
        params[@"is_landscape"] = ACC_FLOAT_GREATER_THAN(videoSize.width, videoSize.height) ? @1 : @0;
    }
    
    if (repository.repoChallenge.challenge.itemID.length) {
        params[@"tag_id"] = repository.repoChallenge.challenge.itemID;
    }
    id<ACCRepoKaraokeModelProtocol> repoKaraokeModel = [repository extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
    [params addEntriesFromDictionary:([repoKaraokeModel.trackParams copy] ?: @{})];
    AWERepoTrackModel *repoTrack = repository.repoTrack;
    AWERepoContextModel *repoContext = repository.repoContext;
    
    if (!repoTrack.hasRecordEnterEvent && repoTrack.isRestoreFromBackup) {
        params[@"is_restore_crash"] = @(YES);
        repoTrack.hasRecordEnterEvent = YES;
        repoContext.sourceModel.repoTrack.hasRecordEnterEvent = YES;
        params[@"enter_method"] = @"click_continue_popup";
    }
    
    if (repository) {
        NSDictionary *extra = [repository.repoUploadInfo extraDict];
        if (extra && extra[@"appID"]) {
            params[@"mp_id"] = extra[@"appID"];
        }
        [params addEntriesFromDictionary:[repository.repoSticker videoCommentStickerTrackInfo]]; // Video Comment Sticker
    }

    if (repository.repoTrack.schemaTrackParmForActivity) {
        [params addEntriesFromDictionary:repository.repoTrack.schemaTrackParmForActivity];
    }
    params[@"publish_cnt"] = @([ACCVideoPublish() publishTaskCount]);

    if (repository.repoContext.videoSource == AWEVideoSourceCapture && [params objectForKey:@"resolution"]) {
        params[@"original_resolution"] = [params objectForKey:@"resolution"];
    }
    params[@"is_meteormode"] = @(repository.repoContext.isMeteorMode ? 1 : 0);
    
    id storySourceType = repository.repoPublishConfig.unmodifiablePublishParams[@"story_source_type"];
    if ([storySourceType isKindOfClass:[NSNumber class]]) {
        params[@"is_own_video"] = [storySourceType intValue] == 2 ? @(1) : @(0);
    }

    if (repository.repoContext.videoType == AWEVideoTypeKaraoke) {
        id<ACCRepoKaraokeModelProtocol> repoKaraoke = [repository extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
        // get [music_selected_from, music_id, pop_music_id, pop_music_type] from repoKaraoke.trackParams
        [params addEntriesFromDictionary:repoKaraoke.trackParams ? : @{}];
        params[@"origin_status"] = repoKaraoke.editModel.useOriginalSong && repoKaraoke.editModel.originalSongTimeList.count ? @"on" : @"off";
        if (repoKaraoke.recordMode == ACCKaraokeRecordModeAudio) {
            params[@"background_material"] = repoKaraoke.editModel.audioBGImages.count ? @"personal" : @"system";
        }
    } else {
        params[@"music_selected_from"] = repository.repoMusic.musicSelectedFrom;
    }
    params[@"edit_from"] = nil;
    
    //im 调整埋点
    if ([IESAutoInline(ACCBaseServiceProvider(), ACCIMModuleServiceProtocol) isPublishAtMentionWithRepository:repository]) {
        params[@"is_own_video"] = @0;
        params[@"content_type"] = @"share";
    }

    if ([eventName isEqual:@"enter_video_edit_page"]) {
        params[@"prop_selected_from"] = repository.repoProp.propSelectedFrom;
        
        // 智能照片电影
        if ([repository.repoSmartMovie isSmartMovieMode]) {
            params[@"is_smart_slideshow"] = @(1);
        }
        // 一键成片
        if ([params[@"content_type"] isEqual:@"ai_upload"]) {
            AWERepoMVModel *repoMV = [repository extensionModelOfClass:AWERepoMVModel.class];
            params[@"ai_upload_entrance"] = repoMV.oneKeyMVEnterfrom;
        }
        params[@"prop_type"] = [ACCStudioLiteRedPacket() recordPropType:repository];
        
        NSDictionary *liteParams = [ACCStudioLiteRedPacket() enterVideoEditPageParams:repository];
        if (liteParams) {
            [params addEntriesFromDictionary:liteParams];
        }
        NSDictionary *qualityParams = [ACCStudioLiteRedPacket() quailtiyGuideTrackParams:repository];
        if (qualityParams) {
            [params addEntriesFromDictionary:qualityParams];
        }
        
        if ((repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeShareAsStory ||
            repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeRePostVideo) &&
            ACCConfigBool(kConfigBool_enable_share_crop_black_area)) {
            NSDictionary *vertices = repository.repoVideoInfo.videoTextureVertices;
            if ([self isBlackBorderVertices:vertices]) {
                params[@"publish_extra_info"] = @"remove_black";
            }
        }
    }
    
    AWEVideoShareInfoModel *videoShareSticker = repository.repoSticker.videoShareInfo;
    if (videoShareSticker.commentContent.length > 0 &&
        videoShareSticker.commentUserNickname.length > 0 &&
        videoShareSticker.commentId.length > 0) {
        NSString *userID = [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) currentLoginUserModel].userID;
        params[@"is_own_comment"] = @([videoShareSticker.commentUserId isEqualToString:userID]);
    }
    [tracker trackEvent:eventName params:params needStagingFlag:NO];
}

#pragma mark 是否是有黑边的顶点信息
+ (BOOL)isBlackBorderVertices:(NSDictionary *)vertices
{
    TransformTextureVertices *textureVertices = [[TransformTextureVertices alloc] initWithDict:vertices];
    if (vertices.count > 0 && [textureVertices isValid]) {
        if ([self isBlackBorderPoint:textureVertices.topLeft] ||
            [self isBlackBorderPoint:textureVertices.topRight] ||
            [self isBlackBorderPoint:textureVertices.bottomLeft] ||
            [self isBlackBorderPoint:textureVertices.bottomRight]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark 是否一定是黑边顶点
+ (BOOL)isBlackBorderPoint:(CGPoint)point
{
    if ((ACC_FLOAT_EQUAL_TO(point.x, 0) || ACC_FLOAT_GREATER_THAN(point.x, 0.99)) &&
        (ACC_FLOAT_EQUAL_TO(point.y, 0) || ACC_FLOAT_GREATER_THAN(point.y, 0.99))) {
        return NO;
    } else {
        return YES;
    }
}

- (void)notifyWillGoBackToRecordPage
{
    [self.subscription performEventSelector:@selector(willGoBackToRecordPageWithEditFlowService:)
                              realPerformer:^(id<ACCVideoEditFlowControlSubscriber> subscriber) {
        [subscriber willGoBackToRecordPageWithEditFlowService:self];
    }];
}

- (void)notifyWillEnterPublishPage
{
    [self.subscription performEventSelector:@selector(willEnterPublishWithEditFlowService:) realPerformer:^(id<ACCVideoEditFlowControlSubscriber> subscriber) {
        [subscriber willEnterPublishWithEditFlowService:self];
    }];
}

- (void)notifyWillDirectPublish
{
    [self.subscription performEventSelector:@selector(willDirectPublishWithEditFlowService:) realPerformer:^(id<ACCVideoEditFlowControlSubscriber> subscriber) {
        [subscriber willDirectPublishWithEditFlowService:self];
    }];
}

- (void)notifyDataClearForBackup
{
    [self.subscription performEventSelector:@selector(dataClearForBackup:) realPerformer:^(id<ACCVideoEditFlowControlSubscriber> subscriber) {
        [subscriber dataClearForBackup:self];
    }];
}

- (void)notifyDidUpdatePublishButton:(UIView *)publishButton nextButton:(UIView *)nextButton
{
    [self.subscription performEventSelector:@selector(didUpdatePublishButton:nextButton:) realPerformer:^(id<ACCVideoEditFlowControlSubscriber> subscriber) {
        [subscriber didUpdatePublishButton:publishButton nextButton:nextButton];
    }];
}

- (void)notifyDidQuickPublishGuideDismiss
{
    [self.subscription performEventSelector:@selector(didQuickPublishGuideDismiss:)realPerformer:^(id<ACCVideoEditFlowControlSubscriber> subscriber) {
        [subscriber didQuickPublishGuideDismiss:self];
    }];
}

- (ACCCameraSubscription *)subscription {
    if (!_subscription) {
        _subscription = [[ACCCameraSubscription alloc] init];
    }
    return _subscription;
}

#pragma mark - ACCVideoEditFlowControlService

- (void)addSubscriber:(id<ACCVideoEditFlowControlSubscriber>)subscriber {
    [self.subscription addSubscriber:subscriber];
}

-(void)notifyWillSwitchImageAlbumEditMode
{
    [self.subscription performEventSelector:@selector(willSwitchImageAlbumEditModeWithEditFlowService:) realPerformer:^(id<ACCVideoEditFlowControlSubscriber> handler) {
        [handler willSwitchImageAlbumEditModeWithEditFlowService:self];
    }];
}

- (void)notifyWillSwitchSmartMovieEditMode
{
    [self.subscription performEventSelector:@selector(willSwitchSmartMovieEditModeWithEditFlowService:) realPerformer:^(id<ACCVideoEditFlowControlSubscriber> handler) {
        [handler willSwitchSmartMovieEditModeWithEditFlowService:self];
    }];
}

- (void)notifyShouldSynchronizeRepository
{
    [self.subscription performEventSelector:@selector(synchronizeRepositoryWithEditFlowService:) realPerformer:^(id<ACCVideoEditFlowControlSubscriber> handler) {
        [handler synchronizeRepositoryWithEditFlowService:self];
    }];
}

- (void)publishPrivateWork
{
    [self.publishPrivateWorkSubject sendNext:nil];
}

- (void)didSaveDraftOnEditPage
{
    let stickerService = IESAutoInline(self.serviceProvider, ACCStickerServiceProtocol);
    self.originalStickerCount = @(stickerService.stickerCount);
    self.repository.repoContext.isStickerEdited = NO;
    self.editService.preview.hasEditClip = NO;
}

- (BOOL)isFlowerRedpacketOneButtonMode
{
    if (self.isFlowerRedpacketOneButtonModeCache != nil) {
        return [self.isFlowerRedpacketOneButtonModeCache boolValue];
    }
    
    if (ACC_isEmptyString(self.repository.repoRedPacket.routerCouponId)) {
        self.isFlowerRedpacketOneButtonModeCache = @(NO);
        return NO; // 外部不带券不展示
    }
    
    if (self.repository.repoDraft.isDraft && ![self.repository.repoRedPacket didBindRedpacketInfo]) {
        self.isFlowerRedpacketOneButtonModeCache = @(NO);
        return NO; // 草稿回来券被删了不展示
    }

    // 图集暂不支持发红包
    if ([self.repository.repoImageAlbumInfo isImageAlbumEdit]) {
        self.isFlowerRedpacketOneButtonModeCache = @(NO);
        return NO;
    }
    
    NSNumber *activityVideoType = self.repository.repoContext.activityVideoType;
    BOOL ret =  (activityVideoType != nil && [ACCFlowerRedPacketHelper() isFlowerRedPacketActivityVideoType:activityVideoType.integerValue]);
    self.isFlowerRedpacketOneButtonModeCache = @(ret);
    return ret;
}

- (NSString *)nextButtonTitleForFlowerAwardIfEnable
{
    if (![self.repository.repoContext enablePublishFlowerActivityAward]) {
        return nil;
    }
    
    return [ACCFlowerCampaignManager() flowerAwardActivityEditNextBtnTitle];
}

@end
