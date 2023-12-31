//
//  ACCRepoSecurityInfoModel.m
//  CameraClient-Pods-Aweme
//
//  Created by lixingdong on 2021/1/18.
//

#import "ACCRepoSecurityInfoModel.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitArch/AWEEffectFilterDataManager.h>

#import "AWERepoContextModel.h"
#import <CameraClient/AWERepoMusicModel.h>
#import "AWERepoVideoInfoModel.h"
#import <CreationKitArch/ACCRepoStickerModel.h>
#import <CreationKitArch/ACCRepoMVModel.h>
#import "ACCRepoTextModeModel.h"
#import "AWERepoCutSameModel.h"
#import "AWERepoVoiceChangerModel.h"
#import <CreationKitArch/ACCRepoDuetModel.h>
#import "ACCRepoImageAlbumInfoModel.h"
#import "ACCRepoImageAlbumInfoModel+ACCStickerLogic.h"
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import "ACCRepoQuickStoryModel.h"
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import "ACCConfigKeyDefines.h"
#import "AWEEffectPlatformDataManager.h"
#import "AWEVideoFragmentInfo.h"
#import <CreationKitArch/ACCRepoContextModel.h>
#import "ACCRepoKaraokeModelProtocol.h"
#import <CreationKitArch/ACCVideoDataProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <TTVideoEditor/IESInfoSticker.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <CreationKitArch/ACCRepoVideoInfoModel.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCMonitorToolProtocol.h>
#import <CameraClient/AWERepoPublishConfigModel.h>
#import <CreationKitArch/ACCRepoCutSameModel.h>
#import <CameraClient/AWERecordInformationRepoModel.h>
#import <CameraClient/AWERepoDuetModel.h>
#import <CameraClientModel/ACCVideoCanvasType.h>
#import <CameraClient/ACCRepoAudioModeModel.h>
#import <CameraClient/AWEVideoSpecialEffectsDefines.h>

@interface ACCRepoSecurityInfoModel()<ACCRepositoryContextProtocol, ACCRepositoryRequestParamsProtocol>

@property (nonatomic, copy, readwrite) NSArray *bgStickerImageAssests;
@property (nonatomic, copy, readwrite) NSArray *bgStickerVideoAssests;
@property (nonatomic, strong, readwrite) NSMutableArray<NSNumber *> *bgStickerVideoAssetsClipDuration;

@property (nonatomic, assign) NSInteger shouldUploadOriginFrame; // 0表示未赋值需要计算，-1表示NO，1表示YES
@property (nonatomic, assign) NSInteger shouldUploadOriginAudio; // 0表示未赋值需要计算，-1表示NO，1表示YES
@property (nonatomic, assign) NSInteger shouldUploadOriginImage; // 0表示未赋值需要计算，-1表示NO，1表示YES


@end

@implementation ACCRepoSecurityInfoModel

#pragma mark -

- (nonnull id)copyWithZone:(nullable NSZone *)zone
{
    ACCRepoSecurityInfoModel *security = [[ACCRepoSecurityInfoModel alloc] init];
    security.shootPhotoFramePath = self.shootPhotoFramePath;
    security.shootPhotoFrameSignal = self.shootPhotoFrameSignal;
    return security;
}

// 判断是否需要送审
- (BOOL)needUploadOriginFrame
{
    if ([self p_isCanvansPubishAsImageAlbumAndNeedUploadFrame]) {
        // 单图发布为图集如果是拍照且使用道具需审核的是原图
        // 因为是runtime的判定，实时判断，不走后面的逻辑
        return NO;
    }
    
    if (self.shouldUploadOriginFrame != 0) {
        return self.shouldUploadOriginFrame>0;
    }

    BOOL need = YES;
    do {
        // 服务端开关可以关闭抽帧
        if (ACCConfigBool(kConfigBool_close_upload_origin_frames)) {
            AWELogToolInfo(AWELogToolTagSecurity, @"[needUploadOriginFrame] 服务端抽帧开关关闭，不需要原始帧送审");

            need = NO;
            break;
        }

        // 图集模式不在这里处理，图集模式的抽帧目前放在图集的发布流程
        ACCRepoImageAlbumInfoModel *imageAlbum = [self.repository extensionModelOfClass:ACCRepoImageAlbumInfoModel.class];
        if ([imageAlbum isImageAlbumEdit]) {
            AWELogToolInfo(AWELogToolTagSecurity, @"[needUploadOriginFrame] 图集内容，不走视频抽帧送审逻辑");
            
            need = NO;
            break;
        }

        // 录制类视频
        if ([self checkNeedUploadFramesForRecordVideos]) {
            break;
        }

        // 模板类视频：经典影集，剪同款，一键MV，时光故事，上传一键成片
        if ([self checkNeedUploadFramesForTemplateVideos]) {
            break;
        }

        // 画布类型视频
        if ([self checkNeedUploadFramesForCanvasVideos]) {
            break;
        }

        // 看视频是否有添加一些编辑效果
        if ([self checkNeedUploadFramesForUploadVideos]) {
            break;
        }

        need = NO;
    } while (NO);
    
    self.shouldUploadOriginFrame = need?1:-1;

    return need;
}

- (BOOL)needUploadOriginAudio
{
    if (self.shouldUploadOriginAudio != 0) {
        return self.shouldUploadOriginAudio>0;
    }

    BOOL need = YES;
    do {
        if (!ACCConfigBool(kConfigBool_upload_origin_audio_track)) {
            need = NO;
            break;
        }
        
        AWERepoMusicModel *musicModel = [self.repository extensionModelOfClass:AWERepoMusicModel.class];
        AWERepoVideoInfoModel *videoModel = [self.repository extensionModelOfClass:AWERepoVideoInfoModel.class];
        ACCRepoStickerModel *stickerModel = [self.repository extensionModelOfClass:ACCRepoStickerModel.class];
        ACCRepoMVModel *mvModel = [self.repository extensionModelOfClass:ACCRepoMVModel.class];
        AWERepoVoiceChangerModel *voiceChangerModel = [self.repository extensionModelOfClass:AWERepoVoiceChangerModel.class];
        ACCRepoContextModel *contextModel = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
        ACCRepoCutSameModel *cutsameModel = [self.repository extensionModelOfClass:ACCRepoCutSameModel.class];
        AWERepoDuetModel *duetModel = [self.repository extensionModelOfClass:AWERepoDuetModel.class];
        
        if (mvModel.enableOriginSoundInMV) {
            break;
        }
        
        if (contextModel.videoType == AWEVideoTypeKaraoke) {
            break;
        }
        
        ACCRepoAudioModeModel *audioModel = [self.repository extensionModelOfClass:ACCRepoAudioModeModel.class];
        if (audioModel.isAudioMode == YES && musicModel.music != nil) {
            break;
        }
        
        // support fingerprint identification of background sound of mixed video
        if (musicModel.music.musicID != nil && musicModel.musicVolume == 0 && videoModel.video.hasRecordAudio) {
            // https://bytedance.feishu.cn/docs/doccnSK81hZyiEMD7RC1Q8scL5d
            break;
        }
        
        if (stickerModel.textReadingAssets.count > 0) {
            break;
        }
        
        if (contextModel.videoType == AWEVideoTypeMV && cutsameModel.accTemplateType == ACCMVTemplateTypeClassic) {
            need = NO;
            break;
        }
        
        // 说明: 修复一个集成BUG，目前使用这个补丁方式先集成进去，2021.8这块重新整理改造
        if (contextModel.videoType==AWEVideoTypeSmartMV &&
            (videoModel.videoMuted || ABS(musicModel.voiceVolume)<FLT_EPSILON || musicModel.voiceVolumeDisable)) {
            need = NO;
            break;
        }

        if (duetModel.isDuet && duetModel.isDuetUpload) { // 合拍上传导入
            if (duetModel.duetUploadType == ACCDuetUploadTypePic) { // 图片素材不用音频送审
                need = NO;
            }
            break;
        } else if (musicModel.music || voiceChangerModel.voiceEffectType != ACCVoiceEffectTypeNone) {
            need = videoModel.video.hasRecordAudio;
            break;
        }

        need = NO;
    } while (NO);
    
    self.shouldUploadOriginAudio = need?1:-1;
    
    return need;
}

/**
 * 是否需要审核图集原始图片，如果是图集模式并且在编辑页添加贴纸就需要上传原始图片送审
 */
- (BOOL)needUploadOriginalImage
{
    if ([self p_isCanvansPubishAsImageAlbumAndNeedUploadFrame]) {
        // 单图发布为图集送审判断
        // 因为是runtime的判定，实时判断，不走后面的逻辑
        return YES;
    }

    if (self.shouldUploadOriginImage != 0) {
        return self.shouldUploadOriginImage>0;
    }
    
    ACCRepoImageAlbumInfoModel *imageAlbum = [self.repository extensionModelOfClass:ACCRepoImageAlbumInfoModel.class];
    
    BOOL need = [imageAlbum isImageAlbumEdit] && [imageAlbum isHaveAnySticker];
    self.shouldUploadOriginImage = need?1:-1;

    return need;
}

- (BOOL)p_isPublishCanvasAsImageAlbumMode
{
    AWERepoPublishConfigModel *configModel = [self.repository extensionModelOfClass:AWERepoPublishConfigModel.class];
    return  configModel.isPublishCanvasAsImageAlbum;
}

- (BOOL)p_isCanvansPubishAsImageAlbumAndNeedUploadFrame
{
    return ([self p_isPublishCanvasAsImageAlbumMode] &&
            [self hasCanvansPublishAsImageAlbumFrame]);
}

- (BOOL)hasCanvansPublishAsImageAlbumFrame
{
    // 如果是拍照且使用道具需审核的是原图
    if ([self isSourceTakePhotoAndHasAnyPropFrames]) {
        return YES;
    }
    // 如果有贴纸需要
    AWERepoVideoInfoModel *videoInfoModel = [self.repository extensionModelOfClass:AWERepoVideoInfoModel.class];
    if (!ACC_isEmptyArray(videoInfoModel.video.infoStickers)) {
        return YES;
    }
    return NO;
}

- (BOOL)isSourceTakePhotoAndHasAnyPropFrames
{
    AWERepoContextModel *contextModel = [self.repository extensionModelOfClass:AWERepoContextModel.class];
    
    AWERecordInformationRepoModel *recordInfoModel = [self.repository extensionModelOfClass:AWERecordInformationRepoModel.class];
    
    if (contextModel.isPhoto) {
        NSString *propID = recordInfoModel.pictureToVideoInfo.propID;
        return (recordInfoModel.hasStickers || propID != nil);
    }
    return NO;
}

/**
 * 处理拍摄类型的视频
 * NOTE：目前多段视频都是拍摄的，后续拍摄和导入混排，这块逻辑就要修改，:(
 */
- (BOOL)checkNeedUploadFramesForRecordVideos
{
    AWERepoVideoInfoModel *recordInfoModel = [self.repository extensionModelOfClass:AWERepoVideoInfoModel.class];
    ACCRepoDuetModel *duetModel = [self.repository extensionModelOfClass:ACCRepoDuetModel.class];
    AWERepoContextModel *contextModel = [self.repository extensionModelOfClass:AWERepoContextModel.class];

    BOOL hasProps = recordInfoModel.hasStickers; // 这命名比较有歧义，这里是拍摄道具
    BOOL isGreenScreenDuet = duetModel.isDuet && [duetModel.duetLayout.lowercaseString isEqualToString:@"green_screen"];

    BOOL result = NO;
    NSString *reason = @"";

    if (contextModel.isRecord) {
        result = hasProps || isGreenScreenDuet;
        if (result) {
            reason = hasProps ? @"拍摄类型视频，带道具" : @"拍摄类型视频，绿幕合拍";
        } else {
            reason = @"拍摄类型视频，没有道具并且不是绿幕合拍";
        }
    } else {
        reason = @"不是拍摄类型视频";
    }

    AWELogToolInfo(AWELogToolTagSecurity, @"[needUploadOriginFrame] 按录制类视频方式检测，%@需要送审原始帧，详情: %@", result?@"":@"不", reason);

    return result;
}

- (BOOL)checkNeedUploadFramesForTemplateVideos
{
    BOOL result = YES;
    NSString *reason = @"";

    do {
        // 文字模式先做判断，因为使用了MV，而且使用了贴纸，避免走到下面逻辑。。。
        ACCRepoTextModeModel *textModel = [self.repository extensionModelOfClass:ACCRepoTextModeModel.class];
        if (textModel.isTextMode) {
            reason = @"文字模式视频";
            result = NO;
            break;
        }
        
        // AI卡点，因为视频图片可能会有动效（目前只有图片部分会有动效），所以需要送审
        ACCRepoUploadInfomationModel *uploadModel = [self.repository extensionModelOfClass:ACCRepoUploadInfomationModel.class];
        if (uploadModel.isAIVideoClipMode) {
            reason = @"AI卡点视频";
            break;
        }
        
        // MV视频
        AWERepoContextModel *contextModel = [self.repository extensionModelOfClass:AWERepoContextModel.class];
        if (contextModel.isMVVideo) {
            reason = @"MV视频";
            break;
        }
        
        ACCRepoAudioModeModel *audioModel = [self.repository extensionModelOfClass:ACCRepoAudioModeModel.class];
        if (audioModel.isAudioMode == YES) {
            reason = @"音频投稿 有用户头像";
            break;
        }
        
        // 有图片的情况，单图/上传多图都需要抽帧
        if ([contextModel hasPhoto]) {
            reason = @"有图片（单图或者多张图片会有动效）";
            break;
        }
        
        // K歌自定义背景
        id<ACCRepoKaraokeModelProtocol> repoKaraokeModel = [self.repository extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
        if (repoKaraokeModel.recordMode == ACCKaraokeRecordModeAudio && repoKaraokeModel.editModel.audioBGImages.count > 0) {
            reason = @"K歌自定义背景";
            break;
        }

        result = NO;
        reason = @"不是模板类视频";
    } while (NO);
    
    AWELogToolInfo(AWELogToolTagSecurity, @"[needUploadOriginFrame] 按模板类视频方式检测，%@需要送审原始帧，详情: %@", result?@"":@"不", reason);
    
    return result;
}

// 按照画布的方式看是否需要送审原始帧
- (BOOL)checkNeedUploadFramesForCanvasVideos {
    AWERepoVideoInfoModel *videoModel = [self.repository extensionModelOfClass:AWERepoVideoInfoModel.class];
    ACCVideoCanvasType canvasType = videoModel.canvasType;
    
    // 少几个换头像/签名的类型，那些目前在其它场景会覆盖掉。后续等那些逻辑添加上canvasType再补上 @yangguocheng
    BOOL result = (canvasType==ACCVideoCanvasTypeSinglePhoto ||
    canvasType==ACCVideoCanvasTypeChangeBackground ||
    canvasType==ACCVideoCanvasTypeRePostVideo ||
    canvasType==ACCVideoCanvasTypeShareAsStory);

    AWELogToolInfo(AWELogToolTagSecurity, @"[needUploadOriginFrame] 按画布类视频方式检测，%@需要送审原始帧，详情: 画布类型 %@", result?@"":@"不", @(canvasType));
    
    return result;
}

// 看编辑页面的内容看是否需要送审原始帧
- (BOOL)checkNeedUploadFramesForUploadVideos
{
    BOOL result = YES;
    NSString *reason = @"";
    
    do {
        // 编辑页面可以添加自定义贴纸，这个肯定是要抽的，优先判断
        AWERepoVideoInfoModel *videoModel = [self.repository extensionModelOfClass:AWERepoVideoInfoModel.class];
        NSArray<IESInfoSticker *> *infoStickers = videoModel.video.infoStickers;
        __block BOOL hasCustomSticker = NO;
        [infoStickers enumerateObjectsUsingBlock:^(IESInfoSticker * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop){
            BOOL isCustomSticker = [obj.userinfo[@"isCustomSticker"] boolValue];
            if (isCustomSticker) {
                hasCustomSticker = YES;
                *stop = YES;
            }
        }];
        if (hasCustomSticker) {
            reason = @"视频有自定义贴纸";
            break;
        }
        
        // 文字模式判断，因为使用了MV，而且使用了贴纸，避免走到下面逻辑。。。
        ACCRepoTextModeModel *textModel = [self.repository extensionModelOfClass:ACCRepoTextModeModel.class];
        if (textModel.isTextMode) {
            reason = @"文字模式视频";
            result = NO;
            break;
        }

        // 看有没有用特效
        NSMutableArray *effects = [NSMutableArray array];
        [videoModel.video.effect_timeRange enumerateObjectsUsingBlock:^(IESMMEffectTimeRange * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *effectId = obj.effectPathId;
            __block NSString *name = [[AWEEffectFilterDataManager defaultManager] effectWithID:effectId].effectName;
            
            if (ACC_isEmptyString(name) && !ACC_isEmptyString(effectId)) {
                NSArray<IESEffectModel *> *effectArr = [AWEEffectPlatformDataManager getCachedEffectsOfPanel:kSpecialEffectsSimplifiedPanelName];
                [effectArr enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull innerObj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([innerObj.effectIdentifier isEqualToString:effectId]) {
                        name = innerObj.effectName;
                    }
                }];
            }
            
            if (!ACC_isEmptyString(name)) {
                [effects acc_addObject:name];
            }
        }];
        if (effects.count>0 || videoModel.video.effect_timeMachineType!=HTSPlayerTimeMachineNormal) {
            reason = [NSString stringWithFormat:@"视频有特效，effects count:%@, time machine type: %@", @(effects.count), @(videoModel.video.effect_timeMachineType)];
            
            break;
        }
        
        // 看有没有用贴纸
        ACCRepoStickerModel *stickerModel = [self.repository extensionModelOfClass:ACCRepoStickerModel.class];
        if (videoModel.video.infoStickers.count > 0 || !ACC_isEmptyString(stickerModel.imageText) ||
            stickerModel.interactionStickers.count > 0) {
            reason = [NSString stringWithFormat:@"视频有贴纸，infoStickers count:%@, image text: %@, interactionStickers: %ld", @(videoModel.video.infoStickers.count), stickerModel.imageText, (long)stickerModel.interactionStickers.count];
            
            break;
        }
        
        // 看有没有涂层
        ACCRepoQuickStoryModel *storyModel = [self.repository extensionModelOfClass:ACCRepoQuickStoryModel.class];
        if (storyModel.hasPaint) {
            reason = @"视频有涂层";

            break;
        }
        
        result = NO;
        reason = @"视频无特效/贴纸/涂层等效果";
    } while (NO);
    
    AWELogToolInfo(AWELogToolTagSecurity, @"[needUploadOriginFrame] 按视频编辑效果方式检测，%@需要送审原始帧，详情: %@", result?@"":@"不", reason);
    
    return result;
}

// 判断
- (void)checkVideoFeedType
{
    BOOL success = NO;  // 是否是检测过的类型
    NSString *reason = @"";

    ACCRepoContextModel *contextModel = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
    ACCFeedType feedType = contextModel.feedType;
    switch (feedType) {
        // 这些类型是目前创作链路会走到的feedtype
        case ACCFeedTypeGeneral: // 普通拍摄视频
        case ACCFeedTypeInteractionSticker: // 带有跳转链接的道具视频
        case ACCFeedTypeMV: // 经典MV
        case ACCFeedTypePhotoToVideo: // 照片电影（单图上传）
        case ACCFeedTypeSmartMV: // 智能MV
        case ACCFeedTypeOneClickFilming: // 上传一键成片
        case ACCFeedTypeMoments: // 时光故事
        case ACCFeedTypeKaraoke: // K歌
        case ACCFeedTypeLivePlayRecord: // 直播录屏
        case ACCFeedTypeLivePlayBackRecord: // 直播回放
        case ACCFeedTypeAIMusicVideo: // AI卡点
        case ACCFeedTypeRecognition: // 拍摄页识别
        case ACCFeedTypeLiteTheme:
        case ACCFeedTypeAudioMode:
        {
            success = YES;
            reason = [NSString stringWithFormat:@"已知类型视频, 抽帧逻辑已覆盖，FeedType:%@", @(feedType)];
        }
            break;
        
        // 画布类型特殊处理
        // https://bytedance.feishu.cn/docs/doccn9oXk9dTlwdz1bOKcqHdedc
        case ACCFeedTypeCanvasPost: {
            AWERepoPublishConfigModel *configModel = [self.repository extensionModelOfClass:AWERepoPublishConfigModel.class];
            ACCFeedTypeExtraCategoryDa categoryDA = configModel.categoryDA;
            if (categoryDA == ACCFeedTypeExtraCategoryDaUnknown) {
                ACCRepoUploadInfomationModel *uploadModel = [self.repository extensionModelOfClass:[ACCRepoUploadInfomationModel class]];
                categoryDA = [uploadModel.extraDict acc_integerValueForKey:@"category_da"];
            }
            
            // 说明：ACCFeedTypeExtraCategoryDaBirthday不用画布能力，属于feedType为ACCFeedTypeMV的情况
            if (categoryDA == ACCFeedTypeExtraCategoryDaAvatarStory ||
                categoryDA == ACCFeedTypeExtraCategoryDaTextMode ||
                categoryDA == ACCFeedTypeExtraCategoryDaChangeBackground ||
                categoryDA == ACCFeedTypeExtraCategoryDaIntroduction ||
                categoryDA == ACCFeedTypeExtraCategoryDaNewcomers ||
                categoryDA == ACCFeedTypeExtraCategoryDaRePost ||
                categoryDA == ACCFeedTypeExtraCategoryDaShareAsStory ||
                categoryDA == ACCFeedTypeExtraCategoryDaShareCommentToStory ||
                categoryDA == ACCFeedTypeExtraCategoryDaMusicStory ||
                categoryDA == ACCFeedTypeExtraCategoryDaNewCity ||
                categoryDA == ACCFeedTypeExtraCategoryJoinCircle) {
                success = YES;
                reason = [NSString stringWithFormat:@"已知画布类型视频, 抽帧逻辑已覆盖，categoryDA:%@", @(categoryDA)];
            } else {
                reason = [NSString stringWithFormat:@"未知画布类型视频, 抽帧逻辑未覆盖，categoryDA:%@", @(categoryDA)];
            }
        }
            break;

        default: {
            success = NO;
            reason = [NSString stringWithFormat:@"未知类型视频，抽帧逻辑不一定覆盖，需要确认，FeedType:%@", @(feedType)];
            break;
        }
    }

    if (success) {
        AWELogToolInfo(AWELogToolTagSecurity, @"[checkVideoFeedType] 视频类型已识别，详情：%@", reason);
    } else {
        AWELogToolError(AWELogToolTagSecurity, @"[checkVideoFeedType] 视频类型未识别，请处理送审逻辑，详情：%@", reason);

        [ACCMonitorTool() showWithTitle:reason
                                  error:nil
                                  extra:@{@"tag": @"frames"}
                                  owner:@"raomengyun"
                                options:ACCMonitorToolOptionModelAlert|ACCMonitorToolOptionReportToQiaoFu];
    }
}

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    BOOL needUploadFrame = [self needUploadOriginFrame]; // 是否需要审核视频/道具/贴纸原始帧信息
    BOOL needUploadAudio = [self needUploadOriginAudio]; // 是否需要上传原始音频
    BOOL needUploadImage = [self needUploadOriginalImage]; // 是否需要审核图集原始图片
    if (!needUploadFrame && !needUploadAudio && !needUploadImage) {
        return nil;
    }

    ACCRepoContextModel *contextModel = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
    ACCRepoTrackModel *trackModel = [self.repository extensionModelOfClass:ACCRepoTrackModel.class];
    ACCRepoDuetModel *duetModel = [self.repository extensionModelOfClass:ACCRepoDuetModel.class];
    
    NSMutableDictionary *subParams = [[NSMutableDictionary alloc] init];
    [subParams btd_setObject:@(needUploadFrame ? 1:0) forKey:@"video_check"]; // 是否需要审核原始帧
    [subParams btd_setObject:@(needUploadAudio ? 1:0) forKey:@"audio_check"]; // 是否需要审核原始音频
    [subParams btd_setObject:@(needUploadImage ? 1:0) forKey:@"image_check"]; // 是否需要审核图集原始图片
    [subParams btd_setObject:@(contextModel.videoSource == AWEVideoSourceCapture) forKey:@"origin"];
    [subParams btd_setObject:@(contextModel.feedType) forKey:@"aweme_type"];
    
    if ([self p_isPublishCanvasAsImageAlbumMode]) {
        // 单图发布为图集需要动态设置一些参数
        [subParams btd_setObject:@(ACCFeedTypeImageAlbum) forKey:@"aweme_type"];
    }

    BOOL isDuetGreenScreen = [duetModel.duetLayout isEqualToString:@"green_screen"];
    [subParams btd_setObject:@(isDuetGreenScreen ? 1:0) forKey:@"is_greenscreen_duet"];

    NSString *contentType = ACCDynamicCast([trackModel.referExtra acc_objectForKey:@"content_type"], NSString);
    if (contentType) {
        [subParams setObject:contentType forKey:@"content_type"];
    }
    
    NSArray *durations = [self photoDurations];
    if (!ACC_isEmptyArray(durations)) {
        NSString *photoTimeStr = [NSString stringWithFormat:@"[%@]", [durations componentsJoinedByString:@","]];
        [subParams setObject:@(durations.count) forKey:@"photo_count"];
        [subParams setObject:photoTimeStr forKey:@"photo_time"];
    }
    
    NSAssert([NSJSONSerialization isValidJSONObject:subParams], @"frame_check must be valid json.");
    if ([NSJSONSerialization isValidJSONObject:subParams]) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:subParams options:0 error:nil];
        NSString *frameCheckParams = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSAssert(frameCheckParams, @"frame_check json string must not be nil.");
        if (frameCheckParams) {
            return @{@"frame_check": frameCheckParams};
        }
    }

    return nil;
}

- (NSArray *)photoDurations
{
    id<ACCVideoDataProtocol> videoData = [self.repository extensionModelOfProtocol:@protocol(ACCVideoDataProtocol)];
    NSMutableArray *photoTimes = [[NSMutableArray alloc] init];
    
    [videoData.videoAssets enumerateObjectsUsingBlock:^(AVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSURL *imagePath = [videoData.photoAssetsInfo objectForKey:obj];
        if (imagePath) {
            NSTimeInterval duration = CMTimeGetSeconds([videoData getVideoDuration:obj]) * 1000.0;
            NSString *durationStr = [NSString stringWithFormat:@"%0.1f", duration];
            [photoTimes acc_addObject:durationStr];
        }
    }];
    
    return photoTimes;
}

#pragma mark - Green Screen

- (NSArray *)bgStickerImageAssests
{
    if (!_bgStickerImageAssests) {
        NSMutableArray *imagePaths = [@[] mutableCopy];
        AWERepoVideoInfoModel *recordInfoModel = [self.repository extensionModelOfClass:AWERepoVideoInfoModel.class];
        
        [recordInfoModel.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.stickerImageAssetPaths.count > 0) {
                [imagePaths addObjectsFromArray:obj.stickerImageAssetPaths];
            }
        }];
        
        _bgStickerImageAssests = [imagePaths copy];
    }

    return _bgStickerImageAssests;
}

- (NSArray *)bgStickerVideoAssests {
    if (!_bgStickerVideoAssests) {
        NSMutableArray *assets = [@[] mutableCopy];
        __block NSURL *lastStickerAsset = nil;
        __block CGFloat lastStickerPlayedPercent = 0;
        ACCRepoVideoInfoModel *recordInfoModel = [self.repository extensionModelOfClass:ACCRepoVideoInfoModel.class];
        
        [recordInfoModel.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSURL* stickerVideoAssetURL = obj.stickerVideoAssetURL;
            AVURLAsset* asset = [AVURLAsset assetWithURL:stickerVideoAssetURL];
            if (asset) {
                if ([lastStickerAsset.absoluteString isEqualToString:stickerVideoAssetURL.absoluteString]) {
                    [self.bgStickerVideoAssetsClipDuration removeLastObject];
                    if (obj.stickerBGPlayedPercent > lastStickerPlayedPercent) {
                        lastStickerPlayedPercent = obj.stickerBGPlayedPercent;
                    }
                    [self.bgStickerVideoAssetsClipDuration acc_addObject:@(lastStickerPlayedPercent * CMTimeGetSeconds(asset.duration))];
                } else {
                    [assets acc_addObject:asset];
                    [self.bgStickerVideoAssetsClipDuration acc_addObject:@(obj.stickerBGPlayedPercent * CMTimeGetSeconds(asset.duration))];
                }
                lastStickerAsset = stickerVideoAssetURL;
            }
        }];
        
        _bgStickerVideoAssests = [assets copy];
    }
    
    return _bgStickerVideoAssests;
}

- (NSMutableArray<NSNumber *> *)bgStickerVideoAssetsClipDuration {
    if (!_bgStickerVideoAssetsClipDuration) {
        _bgStickerVideoAssetsClipDuration = [NSMutableArray array];
    }
    return _bgStickerVideoAssetsClipDuration;
}

#pragma mark - ACCRepositoryContextProtocol

@synthesize repository;

@end

#pragma mark - Class AWEVideoPublishViewModel

@interface AWEVideoPublishViewModel (RepoSecurityInfo)<ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoSecurityInfo)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoSecurityInfoModel.class];
    return info;
}

- (ACCRepoSecurityInfoModel *)repoSecurityInfo
{
    ACCRepoSecurityInfoModel *model = [self extensionModelOfClass:ACCRepoSecurityInfoModel.class];
    NSAssert(model, @"extension model should not be nil");
    return model;
}

@end



