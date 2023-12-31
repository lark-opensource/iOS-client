//
//  AWERepoContextModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/20.
//

#import "AWERepoContextModel.h"
#import <CreativeKit/ACCTrackProtocol.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CameraClient/AWERepoDuetModel.h>
#import "ACCFriendsServiceProtocol.h"
#import "ACCCommerceServiceProtocol.h"
#import "ACCRepoTextModeModel.h"
#import "ACCRepoAudioModeModel.h"
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import "AWERepoVideoInfoModel.h"
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import "AWEShareMusicToStoryUtils.h"
// dependency
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import "ACCRepoKaraokeModelProtocol.h"
#import "AWERepoCutSameModel.h"
#import "AWERepoVideoInfoModel.h"
#import "ACCRepoActivityModel.h"
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreativeKit/ACCServiceLocator.h>
#import "AWERepoPropModel.h"
#import "AWEVideoFragmentInfo.h"
#import <CreativeKit/ACCMacros.h>
#import <CameraClientModel/ACCVideoCanvasType.h>

@interface AWERepoContextModel ()

@end

@interface AWEVideoPublishViewModel (AWERepoContext) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (AWERepoContext)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
	ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoContextModel.class];
	return info;
}

- (AWERepoContextModel *)repoContext
{
    AWERepoContextModel *contextModel = [self extensionModelOfClass:AWERepoContextModel.class];
    NSAssert(contextModel, @"extension model should not be nil");
    return contextModel;
}

@end


@interface AWERepoContextModel()<ACCRepositoryRequestParamsProtocol, ACCRepositoryTrackContextProtocol>

@end

@implementation AWERepoContextModel

- (id)copyWithZone:(NSZone *)zone
{
    AWERepoContextModel *model = [super copyWithZone:zone];
    model.sourceModel = self.sourceModel;
    model.createId = self.createId;
    model.videoLenthMode = self.videoLenthMode;
    model.allowSkipUpload = self.allowSkipUpload;
    model.remoteVideoResourceId = self.remoteVideoResourceId;
    model.activityVideoType = self.activityVideoType;
    model.activityTaskToken = self.activityTaskToken;
    model.needShowMusicOfflineAlert = self.needShowMusicOfflineAlert;
    model.triggerChangeOfflineMusic = self.triggerChangeOfflineMusic;
    model.isMeteorMode = self.isMeteorMode;
    model.editPageBottomButtonStyle = self.editPageBottomButtonStyle;
    model.isFromCommentPanel = self.isFromCommentPanel;
    model.shareImageAsset = self.shareImageAsset;
    model.isReedit = self.isReedit;
    model.aweme = self.aweme;
    model.awemeData = self.awemeData;
    model.reeditUsingDraft = self.reeditUsingDraft;
    model.isCloseMP = self.isCloseMP;
    model.noLandingAfterPublish = self.noLandingAfterPublish;
    model.quickSaveAlbum = self.quickSaveAlbum;
    model.isSilentMergeMode = self.isSilentMergeMode;
    model.flowerMode = self.flowerMode;
    model.flowerItem = self.flowerItem;
    model.flowerBooking = self.flowerBooking;
    model.flowerEditActivityEnterFrom = self.flowerEditActivityEnterFrom;
    model.flowerPublishActivityEnterFrom = self.flowerPublishActivityEnterFrom;
    model.flowerActivityProps = self.flowerActivityProps;
    model.didRequestFlowerPublishActivityAward = self.didRequestFlowerPublishActivityAward;
    model.liteActivityRedPacketType = self.liteActivityRedPacketType;
    model.liteRedPacketTaskKey = self.liteRedPacketTaskKey;
    return model;
}

#pragma mark - getter

- (BOOL)isLive
{
    return self.videoType == AWEVideoTypeLiveScreenShot || self.videoType == AWEVideoTypeLiveBackRecord || self.videoType == AWEVideoTypeLiveHignLight || self.videoType == AWEVideoTypeLivePlayback;
}

- (BOOL)isQuickStoryPictureVideoType
{
    return self.videoType == AWEVideoTypeQuickStoryPicture;
}

- (BOOL)isLivePhoto
{
    return self.videoType == AWEVideoTypeLivePhoto;
}

- (BOOL)shouldSelectMusicAutomatically
{
    if (self.videoType == AWEVideoTypeMV) {
        return NO;
    }
    
    if (self.videoType == AWEVideoTypeImageAlbum) {
        return NO;
    }
    
    ACCRepoDraftModel *draftModel = [self.repository extensionModelOfClass:[ACCRepoDraftModel class]];
    if (draftModel.isDraft && !self.enterFromShoot) {
        return NO;
    }
    
    AWERepoCutSameModel *cutSameModel = [self.repository extensionModelOfClass:AWERepoCutSameModel.class];
    if (cutSameModel.isNewCutSameOrSmartFilming) {
        return NO;
    }
    
    ACCRepoTextModeModel *textModel = [self.repository extensionModelOfClass:ACCRepoTextModeModel.class];
    ACCRepoUploadInfomationModel *uploadInfo = [self.repository extensionModelOfClass:ACCRepoUploadInfomationModel.class];
    
    BOOL shouldSelectForTextMode = textModel.isTextMode && [IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) shouldSelectMusicAutomaticallyForTextMode];
    BOOL shouldSelectForSinglePhoto = !textModel.isTextMode && uploadInfo.originUploadPhotoCount.integerValue == 1 && uploadInfo.originUploadVideoClipCount.integerValue == 0 && [IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) shouldSelectMusicAutomaticallyForSinglePhoto];
    BOOL shouldSelectForMutiPhoto = !textModel.isTextMode &&
                                    uploadInfo.originUploadPhotoCount.integerValue > 1 &&
                                    uploadInfo.originUploadVideoClipCount.integerValue == 0 &&
                                    ACCConfigBool(kConfigBool_studio_muti_photo_back_album_change_music);
    BOOL isEcomCommentPage = [IESAutoInline(ACCBaseServiceProvider(), ACCCommerceServiceProtocol) isEnterFromECommerceComment:self.repository];
    ACCRepoContextModel *repoContext = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
    BOOL isNewYearWish = repoContext.videoType == AWEVideoTypeNewYearWish;
    BOOL shouldSelectForLivePhoto = [self isLivePhoto];
    BOOL shouldSelect = self.isQuickStoryPictureVideoType
    || shouldSelectForTextMode
    || shouldSelectForSinglePhoto
    || shouldSelectForMutiPhoto
    || isEcomCommentPage
    || shouldSelectForLivePhoto
    || isNewYearWish;
    return shouldSelect;
}

- (BOOL)shouldUseMVMusic
{
    if (self.videoType == AWEVideoTypeMV || [IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) shouldUseMVMusicForSinglePhoto]) {
        return YES;
    }
    ACCRepoTextModeModel *textModel = [self.repository extensionModelOfClass:ACCRepoTextModeModel.class];
    if (textModel.isTextMode && ![IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) shouldSelectMusicAutomaticallyForTextMode]) {
        return NO;
    }
    ACCRepoUploadInfomationModel *uploadInfo = [self.repository extensionModelOfClass:ACCRepoUploadInfomationModel.class];
    if (!textModel.isTextMode && uploadInfo.originUploadPhotoCount.integerValue == 1 && uploadInfo.originUploadVideoClipCount.integerValue == 0 && ![IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) shouldSelectMusicAutomaticallyForSinglePhoto]) {
        return NO;
    }
    return YES;
}

- (BOOL)canChangeMusicInEditPage
{
    ACCRepoDuetModel *duet = [self.repository extensionModelOfClass:ACCRepoDuetModel.class];
    if (duet.isDuet) {
        return NO;
    }
    
    ACCRepoUploadInfomationModel *uploadInfo = [self.repository extensionModelOfClass:ACCRepoUploadInfomationModel.class];
    if (uploadInfo.videoClipMode == AWEVideoClipModeAI && !ACCConfigBool(kConfigBool_enable_new_clips)) {
        return NO;
    }
    
    AWERepoVideoInfoModel *videoInfo = [self.repository extensionModelOfClass:AWERepoVideoInfoModel.class];
    NSTimeInterval duration = [videoInfo.video totalVideoDuration];
    let config = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
    if ([config limitMusicAccordingLongVideo] && duration >= config.longVideoDurationLowerLimit) {
        return NO;
    }
    
    if (videoInfo.canvasType == ACCVideoCanvasTypeMusicStory) {
        return NO;
    }
    return YES;
}

- (BOOL)isTC21RedPackageActivity {
    NSInteger activityType = [self.activityVideoType integerValue];
    return activityType == 5 || // TC21元旦活动
    activityType == 7 || // TC21点亮
    activityType == 8 || // TC21春节
    activityType == 9; // TC21春节余热
}

- (BOOL)isMVVideo
{
    return AWEVideoTypeMV == self.videoType || AWEVideoTypeMoments == self.videoType || AWEVideoTypeSmartMV == self.videoType || AWEVideoTypeOneClickFilming == self.videoType;
}

- (BOOL)isIMRecord
{
    return self.recordSourceFrom == AWERecordSourceFromIM;
}

- (BOOL)isRecord
{
    ACCRepoContextModel *repoContext = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
    return repoContext.videoSource == AWEVideoSourceCapture;
}

- (BOOL)isAudioRecord
{
    ACCRepoAudioModeModel *audioModeModel = [self.repository extensionModelOfClass:ACCRepoAudioModeModel.class];
    return audioModeModel.isAudioMode;
}

- (BOOL)isPhoto
{
    AWERepoContextModel *repoContext = [self.repository extensionModelOfClass:AWERepoContextModel.class];
    AWERepoVideoInfoModel *repoVideoInfo = [self.repository extensionModelOfClass:AWERepoVideoInfoModel.class];
    return repoContext.isQuickStoryPictureVideoType || repoVideoInfo.canvasType == ACCVideoCanvasTypeSinglePhoto;
}

- (BOOL)hasPhoto
{
    ACCRepoUploadInfomationModel *uploadInfoModel = [self.repository extensionModelOfClass:ACCRepoUploadInfomationModel.class];
    BOOL hasImage = uploadInfoModel.originUploadPhotoCount.integerValue > 0;
    return [self isPhoto] || self.videoType == AWEVideoTypePhotoToVideo || self.videoType == AWEVideoTypePhotoMovie || hasImage;
}

// if need to support clip, add condition here
- (BOOL)supportNewEditClip
{
    if (!ACCConfigBool(kConfigBool_enable_new_clips)) {
        return NO;
    }
    
    AWERepoContextModel *repoContext = [self.repository extensionModelOfClass:AWERepoContextModel.class];
    AWERepoDuetModel *duetModel = [self.repository extensionModelOfClass:AWERepoDuetModel.class];
    ACCRepoVideoInfoModel *recordInfoModel = [self.repository extensionModelOfClass:ACCRepoVideoInfoModel.class];
    AWERepoPropModel *propModel = [self.repository extensionModelOfClass:AWERepoPropModel.class];

    AWERepoVideoInfoModel *repoVideo = [self.repository extensionModelOfClass:[AWERepoVideoInfoModel class]];
    if (repoVideo.canvasType == ACCVideoCanvasTypeRePostVideo) {
        return NO;
    }
    
    // 分享到日常场景，未开启分享到日常编辑页增加裁剪能力开关时，屏蔽新裁剪
    if (!ACCConfigBool(kConfigBool_enable_share_to_story_add_clip_capacity_in_edit_page) &&
        repoVideo.canvasType == ACCVideoCanvasTypeShareAsStory) {
        return NO;
    }
    
    BOOL isRecord = repoContext.videoSource == AWEVideoSourceCapture;
    BOOL isNormalVideo = (repoContext.videoType == AWEVideoTypeNormal) ||
    (repoContext.videoType == AWEVideoTypeLiveHignLight) ||
    (repoContext.videoType == AWEVideoTypeLiveScreenShot) ||
    (repoContext.videoType == AWEVideoTypeLiteTheme);
    
    // 音乐转发到日常场景
    if ([AWEShareMusicToStoryUtils enableShareMusicToStoryClipEntry:repoVideo.canvasType]) {
        isNormalVideo |= repoContext.videoType == AWEVideoTypePhotoToVideo;
    }
    
    if (isRecord && duetModel.isDuet) {
        return NO;
    }
    
    if (duetModel.isDuet && duetModel.isDuetUpload) {
        return NO;
    }
    
    ACCRepoAudioModeModel *audioModeModel = [repository extensionModelOfClass:ACCRepoAudioModeModel.class];
    if (audioModeModel.isAudioMode) {
        return NO;
    }
    
    if ([self isIMRecord]) {
        return YES;
    }
    
    if (!isNormalVideo) {
        return NO;
    }
    
    __block BOOL useVideoBackgroundSticker = NO;
    [recordInfoModel.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.stickerVideoAssetURL != nil) {
            useVideoBackgroundSticker = YES;
            *stop = YES;
        }
    }];
    if (useVideoBackgroundSticker) {
        return NO;
    }
    
    if (repoContext.videoSource == AWEVideoSourceAlbum) {
        return YES;
    }
    
    if (propModel.isMultiSegPropApplied) {
        return NO;
    }
    
    return YES;
}

- (BOOL)newClipForMultiUploadVideos
{
    ACCRepoUploadInfomationModel *uploadInfoModel = [self.repository extensionModelOfClass:ACCRepoUploadInfomationModel.class];
    return [self supportNewEditClip] && uploadInfoModel.isMultiVideoUpload;
}

- (BOOL)isKaraokeAudio
{
    id<ACCRepoKaraokeModelProtocol> repoModel = [self.repository extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
    return self.videoType == AWEVideoTypeKaraoke && repoModel.recordMode == ACCKaraokeRecordModeAudio;
}

- (BOOL)isKaraokeOfficialBGVideo
{
    id<ACCRepoKaraokeModelProtocol> repoModel = [self.repository extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
    return [self isKaraokeAudio] && repoModel.editModel.audioBGImages.count == 0;
}

- (BOOL)isWishOfficialBGVideo
{
    ACCRepoActivityModel *activityModel = [self.repository extensionModelOfClass:ACCRepoActivityModel.class];
    return self.videoType == AWEVideoTypeNewYearWish && activityModel.wishModel.images.count == 0;
}

- (BOOL)isLitePropEnterMethod
{
    return self.isLiteRedPacketPropCategory && !self.propPannelClicked;
}

- (BOOL)enablePublishFlowerActivityAward
{
    return !ACC_isEmptyString(self.flowerPublishActivityEnterFrom);
}

- (BOOL)enableTakePictureOpt {
    BOOL canvasEnable = [IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) singlePhotoOptimizationABTesting].isCanvasEnabled;
    return ACCConfigBool(kConfigBool_studio_enable_take_picture_opt) && canvasEnable && !self.isIMRecord;
}

- (BOOL)enableTakePictureDelayFrameOpt {
    BOOL canvasEnable = [IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) singlePhotoOptimizationABTesting].isCanvasEnabled;
    return ACCConfigBool(kConfigBool_studio_enable_take_picture_delay_frame_opt) && canvasEnable && !self.isIMRecord;
}

#pragma mark - ACCRepositoryContextProtocol

@synthesize repository;

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    if (self.isReedit) {
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        params[@"aweme_id"] = self.aweme.itemID;
        return params.copy;
    }
    
    NSInteger photoToVideoPhotoCountType = 0;
    if (self.videoType == AWEVideoTypePhotoToVideo) {
        ACCRepoUploadInfomationModel *uploadInfoModel = [self.repository extensionModelOfClass:ACCRepoUploadInfomationModel.class];
        if ([uploadInfoModel.originUploadPhotoCount intValue] == 1) {
            photoToVideoPhotoCountType = 1;
        } else if ([uploadInfoModel.originUploadPhotoCount intValue] > 1) {
            photoToVideoPhotoCountType = 2;
        }
    }
    
    NSMutableDictionary *params = @{
        @"original" : @(self.videoSource),// original导入视频=0，Ame拍摄=1
        @"video_type" : @(self.videoType),
        @"is_single_template" : @(photoToVideoPhotoCountType),
    }.mutableCopy;
    [params setValue:self.createId forKey:@"creation_id"];
    
    __block BOOL uploadStickerUsedInVideo = NO;
    [publishViewModel.repoVideoInfo.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.uploadStickerUsed) {
            params[@"original"] = @(0);
            params[@"original_type"] = @(1);
            uploadStickerUsedInVideo = YES;
            *stop = YES;
        }
    }];
    if (self.videoSource == AWEVideoSourceAlbum) {
        params[@"original_type"] = @(0); // upload from album (by clicking the button on the right of the capture button)
        if (uploadStickerUsedInVideo) {
            params[@"original_type"] = @(1); // upload by using stickers
        }
        if (self.videoType == AWEVideoTypeMV) { // upload from MV
            ACCRepoCutSameModel *cutSameModel = [self.repository extensionModelOfClass:ACCRepoCutSameModel.class];
            if (cutSameModel.accTemplateType == ACCMVTemplateTypeClassic) {
                params[@"original_type"] = @(2); // Classic MV
            } else if (cutSameModel.accTemplateType == ACCMVTemplateTypeCutSame) {
                params[@"original_type"] = @(3); // CutSame MV
            }
        }
        if (self.videoType == AWEVideoTypeMoments) {
            params[@"original_type"] = @(4); // upload from Moments
        }
    }
    if (self.videoType != AWEVideoTypeImageAlbum &&
        self.isMeteorMode) {
        params[@"is_meteor"] = @(1);
    }

    if (!ACC_isEmptyString(self.flowerPublishActivityEnterFrom)) {
        params[@"flower_reward_enter_from"] = self.flowerPublishActivityEnterFrom;
    }
    
    return params;
}

@end
