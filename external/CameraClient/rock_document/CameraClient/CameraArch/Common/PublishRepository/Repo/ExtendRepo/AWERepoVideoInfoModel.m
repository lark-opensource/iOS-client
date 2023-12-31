//
//  AWERepoVideoInfoModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/20.
//

#import "AWERepoVideoInfoModel.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import <CreationKitArch/AWEEffectFilterDataManager.h>
#import <CreationKitArch/HTSVideoSepcialEffect.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreativeKit/ACCMacros.h>
#import <CameraClient/ACCVideoExportUtils.h>
#import <TTVideoEditor/IESInfoSticker.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <VideoTemplate/LVTemplateDataManager+Fetcher.h>
#import <EffectPlatformSDK/IESEffectManager.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/ACCRepoVideoInfoModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import "AWERepoCutSameModel.h"
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import "AWERepoContextModel.h"
#import "AWERecordInformationRepoModel.h"
#import "ACCRepoEditEffectModel.h"
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoMVModel.h>
#import "AWERepoPublishConfigModel.h"
#import "ACCRepoQuickStoryModel.h"
#import <CameraClient/ACCConfigKeyDefines.h>
#import <NLEPlatform/NLEInterface.h>
#import <NLEPlatform/NLEEditor+iOS.h>
#import "IESInfoSticker+ACCAdditions.h"
#import "ACCEditVideoDataDowngrading.h"
#import <CameraClient/AWERepoPublishConfigModel.h>
#import "AWEVideoFragmentInfo.h"
#import "ACCRepoActivityModel.h"

#import <CameraClient/ACCTrackerUtility.h>
#import <ReactiveObjC/RACSequence.h>
#import <ReactiveObjC/NSArray+RACSequenceAdditions.h>
#import "ACCEditVideoData.h"
#import <CameraClient/AWEAssetModel.h>
#import <CameraClientModel/ACCVideoCanvasType.h>
#import <CameraClient/ACCRepoAudioModeModel.h>

const NSInteger kACCNLEVersionNone = 0;
const NSInteger kACCNLEVersion2 = 2;

@interface AWEVideoPublishViewModel (AWERepoVideoInfo) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (AWERepoVideoInfo)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
	ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoVideoInfoModel.class];
	return info;
}

- (AWERepoVideoInfoModel *)repoVideoInfo
{
    AWERepoVideoInfoModel *videoInfoModel = [self extensionModelOfClass:AWERepoVideoInfoModel.class];
    NSAssert(videoInfoModel, @"extension model should not be nil");
    return videoInfoModel;
}

@end

@interface AWERepoVideoInfoModel()<ACCRepositoryRequestParamsProtocol, ACCRepositoryTrackContextProtocol, ACCRepositoryContextProtocol>

@property (nonatomic, strong) ACCEditVideoData *video;

@end

@implementation AWERepoVideoInfoModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _enableCanvasGesture = @(YES);
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    AWERepoVideoInfoModel *model = [super copyWithZone:zone];
    model.nleVersion = self.nleVersion;
    model.playerFrame = self.playerFrame;
    model.video = self.video.copy;
    model.isFastImportVideo = self.isFastImportVideo;
    model.microphoneBarState = self.microphoneBarState;
    model.capturedPhotoWithWatermark = self.capturedPhotoWithWatermark;
    model.sizeOfVideo = self.sizeOfVideo;
    model.capturePhotoPath = self.capturePhotoPath;
    model.capturePhotoPathRelative = self.capturePhotoPathRelative;
    model.canvasType = self.canvasType;
    model.canvasSource = ({
        ACCVideoCanvasSource *source = [[ACCVideoCanvasSource alloc] init];
        source.center = self.canvasSource.center;
        source.scale = self.canvasSource.scale;
        source.rotation = self.canvasSource.rotation;
        source;
    });
    model.enableCanvasGesture = self.enableCanvasGesture;
    model.videoFrameRatio = self.videoFrameRatio;
    model.canvasContentRatio = self.canvasContentRatio;
    model.videoTextureVertices = self.videoTextureVertices;
    model.fragmentInfo = [self.fragmentInfo mutableCopy];
    model.fragmentInfoJson = [self.fragmentInfoJson mutableCopy];
    model.delay = self.delay;
    model.isDynamicRecorder = self.isDynamicRecorder;
    model.lynxChannel = self.lynxChannel;
    model.dynamicActivityID = self.dynamicActivityID;
    model.dynamicLynxData = self.dynamicLynxData;
    model.dynamicChallengeNames = self.dynamicChallengeNames;
    model.dynamicRecordSchema = self.dynamicRecordSchema;
    model.dynamicAnimationEnable = self.dynamicAnimationEnable;
    model.dynamicPublishPageDisable = self.dynamicPublishPageDisable;
    model.hdVideoCount = self.hdVideoCount;
    return model;
}

- (IESMMVideoDataClipRange *)delayRange
{
    /**
     * @note do not cache the result, return a new object each time.
     */
    CGFloat startTime = self.delay / 1000.0;
    CGFloat duration = [self.video totalVideoDurationAddTimeMachine];
    CGFloat attachTime = 0.f;
    if (startTime < 0) {
        attachTime = fabs(startTime);
        startTime = 0.f;
    }
    return IESMMVideoDataClipRangeMakeV2(startTime, duration, attachTime, 1);
}

- (NSValue *)sizeOfVideo
{
    ACCRepoContextModel *contextModel = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
    AWERepoCutSameModel *cutSameModel = [self.repository extensionModelOfClass:AWERepoCutSameModel.class];
    
    // 智能成片&新剪同款
    if (cutSameModel.isNewCutSameOrSmartFilming) {
        CGSize targetSize = [ACCVideoExportUtils videoSizeForVideoData:self.video
                                                         suggestedSize:[self.video.transParam videoSize]
                                                           repoContext:contextModel
                                                           repoCutSame:cutSameModel
                                                         repoVideoInfo:self];
        return [NSValue valueWithCGSize:targetSize];
    }
    
    // 新单图
    if (self.canvasType != ACCVideoCanvasTypeNone) {
        return [NSValue valueWithCGSize:self.video.transParam.targetVideoSize];
    }
    
    ACCRepoAudioModeModel *audioModeModel = [self.repository extensionModelOfClass:ACCRepoAudioModeModel.class];
    
    // mv的videoSize不能用videoTracks里面的值，需要用[transParam videoSize]
    if ((contextModel.isMVVideo && ACCMVTemplateTypeClassic == cutSameModel.accTemplateType)
        || AWEVideoTypePhotoToVideo == contextModel.videoType || audioModeModel.isAudioMode) {
        return [NSValue valueWithCGSize:[self.video.transParam videoSize]];
    }
    
    AVAsset *asset = self.video.videoAssets.firstObject;
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if ([tracks count] > 0) {
        CGSize targetSize = [ACCVideoExportUtils videoSizeForVideoData:self.video
                                                         suggestedSize:[self.video.transParam videoSize]
                                                           repoContext:contextModel
                                                           repoCutSame:cutSameModel
                                                         repoVideoInfo:self];
        return [NSValue valueWithCGSize:targetSize];
    }
    
    return nil;
}

- (NSString *)specializedCanvasPhotoExportSettings
{
    if (self.canvasType != ACCVideoCanvasTypeSinglePhoto) {
        return nil;
    }

    ACCRepoEditEffectModel *repoEffect = [self.repository extensionModelOfClass:[ACCRepoEditEffectModel class]];
    BOOL existsEffectRanges = repoEffect.displayTimeRanges.count != 0;
    
    BOOL existsDynamicStickers = NO;
    for (IESInfoSticker *sticker in self.video.infoStickers) {
        BOOL isTextSticker = sticker.acc_stickerType == ACCEditEmbeddedStickerTypeText;
        if (!isTextSticker) {
            existsDynamicStickers = YES;
            break;
        }
    }
    
    BOOL isStaticContent = !existsEffectRanges && !existsDynamicStickers;
    return isStaticContent ? ACCConfigString(kConfigString_static_canvas_photo_bitrate) : ACCConfigString(kConfigString_dynamic_canvas_photo_bitrate);
}

- (BOOL)shouldAccommodateVideoDurationToMusicDuration
{
    ACCRepoQuickStoryModel *quickStoryModel = [self.repository extensionModelOfClass:ACCRepoQuickStoryModel.class];
    return self.canvasType == ACCVideoCanvasTypeSinglePhoto && !quickStoryModel.isAvatarQuickStory && !quickStoryModel.isNewcomersStory && !quickStoryModel.isNewCityStory;
}

#pragma mark - Setter
- (void)setIsFastImportVideo:(BOOL)isFastImportVideo
{
    _isFastImportVideo = isFastImportVideo;
    self.video.isFastImport = isFastImportVideo;
}

#pragma mark - ACCRepositoryContextProtocol

@synthesize repository;

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    NSMutableDictionary *params = @{
        @"low_light_opt" : @(self.isExposureOptmize),
        @"duration" : @([self.video totalVideoDuration]),
        @"segment_count" : @(self.video.videoAssets.count),
    }.mutableCopy;
    
    let config = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
    BOOL isLongVideo = [self.video totalVideoDuration] > config.standardVideoMaxSeconds;
    params[@"long_video"] = @(isLongVideo);
    
    NSMutableArray *effects = @[].mutableCopy;
    NSMutableArray *effectIds = @[].mutableCopy;
    
    [self.video.effect_timeRange enumerateObjectsUsingBlock:^(IESMMEffectTimeRange * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *name = [[AWEEffectFilterDataManager defaultManager] effectWithID:obj.effectPathId].effectName;
        if (name) {
            [effects addObject:name];
        }
        if (obj.effectPathId) {
            [effectIds addObject:obj.effectPathId];
        }
    }];
    
    NSString *timeEffectName = [HTSVideoSepcialEffect effectWithType:self.video.effect_timeMachineType].name;
    if (timeEffectName) {
        [effects addObject:timeEffectName];
    }
    [effectIds addObject:@(self.video.effect_timeMachineType)];//时间特效的 effect_id 传枚举值
    params[@"fx_name"] = [effects componentsJoinedByString:@","];
    params[@"effect_id"] = [effectIds componentsJoinedByString:@","];
    
    ACCEditVideoData *videoData = self.video;
    NSMutableArray *segment_durations = [NSMutableArray new];
    
    [videoData.videoAssets enumerateObjectsUsingBlock:^(AVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        AVAsset *asset = obj;
        CMTimeRange clipRange = [videoData videoTimeClipRangeForAsset:asset];
        CGFloat rate = [videoData videoRateForAsset:asset];
        CMTime duration = kCMTimeZero;
        if (clipRange.duration.timescale!=0) {
            duration = CMTimeMake(clipRange.duration.value / rate, clipRange.duration.timescale);
        }
        
        CGFloat secends = CMTimeGetSeconds(duration);
        [segment_durations addObject:[NSString stringWithFormat:@"%.3f",secends]];
    }];
    params[@"segment_durations"] = [segment_durations componentsJoinedByString:@","];

    params[@"ancestor"] = [self p_videoShareInfoFromThirdPartyApplication];
    
    params[@"is_fast_import_video"] = @(self.isFastImportVideo);
    params[@"fast_import"] = @(self.isFastImportVideo);
    params[@"file_fps"] = [NSString stringWithFormat:@"%.2f", self.fps];
    params[@"improve_status"] = @(self.enableHDRNet);//使用画质增强

    params[@"category_da"] = publishViewModel.repoUploadInfo.extraDict[@"category_da"];
    if (publishViewModel.repoQuickStory.isAvatarQuickStory) {
        params[@"is_from_avatar"] = @(publishViewModel.repoQuickStory.isAvatarQuickStory);
        publishViewModel.repoPublishConfig.categoryDA = ACCFeedTypeExtraCategoryDaAvatarStory;
        // "is_diy_prop" 临时用于换头像发日常送审，后续安全侧服务端完成aweme_type支持后会弃用
        params[@"is_diy_prop"] = @(YES);
        params[@"origin_avatar_uri"] = publishViewModel.repoUploadInfo.extraDict[@"origin_avatar_uri"];
    }
    if (publishViewModel.repoActivity.wishModel.avatarURI.length) {
        params[@"is_from_avatar"] = @(1);
        params[@"origin_avatar_uri"] = publishViewModel.repoActivity.wishModel.avatarURI;
    }
    if (publishViewModel.repoQuickStory.isNewCityStory) {
        publishViewModel.repoPublishConfig.categoryDA = ACCFeedTypeExtraCategoryDaNewCity;
        params[@"story_source_type"] = @(4);
        params[@"origin_avatar_uri"] = publishViewModel.repoUploadInfo.extraDict[@"origin_avatar_uri"];
    }
    if (publishViewModel.repoQuickStory.isNewcomersStory) {
        publishViewModel.repoPublishConfig.categoryDA = ACCFeedTypeExtraCategoryDaNewcomers;
    }
    if ([publishViewModel.repoTrack.referString isEqualToString:@"mp_record"]) {
        BOOL open = ACCConfigBool(kConfigBool_studio_enable_mprecord_da_fix);
        if (open) {
            NSString *videoPath = [publishViewModel.repoUploadInfo.extraDict acc_stringValueForKey:@"videoPath"];
            BOOL isRecorderVideo = [videoPath containsString:@"game_recorderVideo.mp4"] ||
                [videoPath containsString:@"game_recorderTrimVideo.mp4"];
            if (isRecorderVideo) {
                params[@"category_da"] = @(ACCFeedTypeExtraCategoryDaMiniGameVideo);
            }
        }
        else {
            params[@"category_da"] = @(ACCFeedTypeExtraCategoryDaMiniGameVideo);
        }
    }
    if (self.canvasType == ACCVideoCanvasTypeChangeBackground) {
        params[@"category_da"] = @(ACCFeedTypeExtraCategoryDaChangeBackground);
    }
    if (self.canvasType == ACCVideoCanvasTypeMusicStory) {
        params[@"category_da"] = @(publishViewModel.repoPublishConfig.categoryDA);
    }
    
    if (params[@"category_da"] == nil &&
        publishViewModel.repoPublishConfig.categoryDA == ACCFeedTypeExtraCategoryDaSinglePhoto) {
        params[@"category_da"] = @(ACCFeedTypeExtraCategoryDaSinglePhoto);
    }
    
    return params;
}

// 第三方分享到抖音标识上报（暂时只有剪映有需求）
- (NSString *)p_videoShareInfoFromThirdPartyApplication
{
    ACCRepoTrackModel *trackModel = [self.repository extensionModelOfClass:ACCRepoTrackModel.class];
    let config = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    if ([trackModel.referString isEqualToString:@"lv_sync"]) {
        dictionary[@"product"] = @(1775);
        dictionary[@"is_long_video"] = @(([self.video totalVideoDuration] >= config.longVideoDurationLowerLimit));
    } else if ([trackModel.referString isEqualToString:@"beautyme_sync"]) {
        dictionary[@"product"] = @(150121);
    } else if ([trackModel.referString isEqualToString:@"retouch_sync"]) {
        dictionary[@"product"] = @(2515);
    }
    if (dictionary.count == 0) {
        return nil;
    }

    NSError *parseError;
    NSData *ancestorData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&parseError];
    if (parseError) {
        AWELogToolError(AWELogToolTagNone, @"%s %@", __PRETTY_FUNCTION__, parseError);
    }
    NSString *ancestorStr = [[NSString alloc] initWithData:ancestorData encoding:NSUTF8StringEncoding];
    return ancestorStr;
}

- (NLEEditor_OC *)nleEditor
{
    if (acc_videodata_is_nle(self.video)) {
        return acc_videodata_take_nle(self.video).nle.editor;
    } else {
        return nil;
    }
}

#pragma mark - ACCRepositoryTrackContextProtocol

- (NSDictionary *)acc_referExtraParams
{
    NSMutableDictionary *referDict = [NSMutableDictionary dictionary];
    [referDict setValue:@(self.fps) forKey:@"fps"];
    
    __block BOOL hasAutoUseHotProp = NO;
    [self.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.hasAutoApplyHotProp) {
            hasAutoUseHotProp = YES;
            *stop = YES;
        }
    }];
    if (hasAutoUseHotProp) {
        [referDict setValue:@(1) forKey:@"is_auto"];
    }
    
    return referDict;
}

#pragma mark - Security

- (void)updateFragmentInfo
{
    [self updateFragmentInfoForce:NO];
}

- (void)updateFragmentInfoForce:(BOOL)force
{
    AWERepoContextModel *contextModel = [self.repository extensionModelOfClass:AWERepoContextModel.class];
    ACCRepoMVModel *mvModel = [self.repository extensionModelOfClass:ACCRepoMVModel.class];

    BOOL isOldMV = mvModel.templateMaterials.count > 0;
    BOOL hasValidOriginalFrames  = !contextModel.isRecord && !ACC_isEmptyArray(self.originalFrameNamesArray);
    hasValidOriginalFrames = hasValidOriginalFrames || isOldMV;
    hasValidOriginalFrames = hasValidOriginalFrames || contextModel.videoType == AWEVideoTypeImageAlbum;
    
    if (!force && (contextModel.isRecord || hasValidOriginalFrames)) {
        return;
    }
    
    if([self invalideLVFragmentTemplate]) {
        return;
    }
    
    if ([self isUseLVMaterialTemplate]) {
        [self updateFragmentInfoForLVMaterialTemplate];
        return;
    }
    
    if ([self isUseLVFragmentTemplate]) {
        [self updateFragmentInfoForLVFragmentTemplate];
        return;
    }
    
    [self updateFragmentInfoForNormal];
}

- (NSArray *)originalFrameNamesArray
{
    __block NSMutableArray *frames = [NSMutableArray array];
    [self.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.originalFramesArray) {
            [frames addObjectsFromArray:obj.originalFramesArray];
        }
    }];
    
    return [frames copy];
}

- (BOOL)hasStickers
{
    AWERepoContextModel *contextModel = [self.repository extensionModelOfClass:AWERepoContextModel.class];
    if (!contextModel.isRecord) {
        return NO;
    }
    
    __block BOOL flag = NO;
    [self.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isSupportExtractFrame ||
            obj.uploadStickerUsed ||
            !ACC_isEmptyString(obj.stickerId) ||
            !ACC_isEmptyArray(obj.stickerImageAssetPaths) ||
            !ACC_isEmptyString(obj.stickerVideoAssetURL.path)) {
            flag = YES;
            *stop = YES;
        }
    }];
    
    return flag;

}

- (NSArray<LVTemplateVideoEditFragment *> *)reloadDisplayFragments
{
    AWERepoCutSameModel *cutSameModel = [self.repository extensionModelOfClass:ACCRepoCutSameModel.class];
    NSMutableArray<LVTemplateVideoEditFragment *> *fragments = [[NSMutableArray alloc] init];
    [[cutSameModel.dataManager allVideoFragments] enumerateObjectsUsingBlock:^(LVTemplateVideoEditFragment * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.canReplace) {
            [fragments acc_addObject:obj];
        }
    }];

    return [fragments copy];
}

/*
 * 是否是 LVMaterialTemplate 类的视频
 * LVMaterialTemplate类视频：剪同款、时光故事优化版本、一键成片
 */
- (BOOL)isUseLVMaterialTemplate
{
    ACCRepoContextModel *contextRepo = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
    
    return contextRepo.isMVVideo && self.nleEditor;
}

/*
 * 是否是 LVFragmentTemplate 类的视频
 * LVFragmentTemplate类视频：剪同款、时光故事老版本
 */
- (BOOL)isUseLVFragmentTemplate
{
    ACCRepoContextModel *contextRepo = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
    AWERepoCutSameModel *cutSameRepo = [self.repository extensionModelOfClass:AWERepoCutSameModel.class];
    
    BOOL validType = contextRepo.videoType == AWEVideoTypeMV || contextRepo.videoType == AWEVideoTypeMoments;
    
    return validType && !self.nleEditor && cutSameRepo.dataManager;
}

/*
 * 使用 LVTemplateVideoEditFragment（剪同款、时光故事老版本）,草稿回来cutSameRepo.dataManager = nil，在发布页无需更新 fragmentInfo
 */
- (BOOL)invalideLVFragmentTemplate
{
    ACCRepoContextModel *contextRepo = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
    AWERepoCutSameModel *cutSameRepo = [self.repository extensionModelOfClass:AWERepoCutSameModel.class];
    ACCRepoDraftModel *draftRepo = [self.repository extensionModelOfClass:ACCRepoDraftModel.class];
    
    BOOL validType = contextRepo.videoType == AWEVideoTypeMV || contextRepo.videoType == AWEVideoTypeMoments;
    return draftRepo.isDraft && validType && !cutSameRepo.cutSameNLEModel && !cutSameRepo.dataManager;
}

/*
 * 更新普通上传类、普通模板类视频的 fragmentInfo
 * 包括：AI卡点、普通裁剪、经典MV、生日MV、photoToVideo等case
 */
- (void)updateFragmentInfoForNormal
{
    AWELogToolInfo(AWELogToolTagSecurity, @"updateFragmentInfoForNormal start");
    ACCRepoContextModel *contextModel = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
    AWEVideoFragmentSourceType souceType = contextModel.isMVVideo ? AWEVideoFragmentSourceTypeTemplate : AWEVideoFragmentSourceTypeUpload;
    NSMutableSet *deduplicateSet = [[NSMutableSet alloc] init];
    
    @weakify(self);
    [self.fragmentInfo removeAllObjects];
    [self.video.videoAssets enumerateObjectsUsingBlock:^(AVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @strongify(self);
        NSURL *imageUrl = [self.video.photoAssetsInfo objectForKey:obj];
        if (imageUrl && ![deduplicateSet containsObject:imageUrl]) {
            AWEVideoFragmentInfo *fragment = [[AWEVideoFragmentInfo alloc] initWithSourceType:souceType];
            fragment.imageAssetURL = imageUrl;
            [self.fragmentInfo acc_addObject:fragment];
            [deduplicateSet addObject:imageUrl];
            return;
        }
        
        if (![obj isKindOfClass:[AVURLAsset class]]) {
            return;
        }
        
        AVURLAsset *urlAsset = (AVURLAsset *)obj;
        NSString *effectDirectory = [IESEffectManager manager].config.rootDirectory;
        // 过滤掉特效自身带的视频
        if (!ACC_isEmptyString(effectDirectory) && [urlAsset.URL.path containsString:effectDirectory]) {
            return;
        }
        
        AWEVideoFragmentInfo *fragment = [[AWEVideoFragmentInfo alloc] initWithSourceType:souceType];
        fragment.avAsset = obj;
        fragment.avAssetURL = urlAsset.URL;
        fragment.clipTimeRange = [NSValue valueWithCMTimeRange:[self.video videoTimeClipRangeForAsset:obj]];
        fragment.assetOrientation = [self p_realImageOrientation:obj];
        [self.fragmentInfo acc_addObject:fragment];
    }];
    
    AWELogToolInfo(AWELogToolTagSecurity, @"updateFragmentInfoForNormal end: fragmentInfo.count = %@", @(self.fragmentInfo.count));
}

/*
 * 更新 LVFragmentTemplate 类视频的 fragmentInfo
 * LVFragmentTemplate类视频：剪同款、时光故事老版本
 */
- (void)updateFragmentInfoForLVFragmentTemplate
{
    AWELogToolInfo(AWELogToolTagSecurity, @"updateFragmentInfoForLVFragmentTemplate start");
    AWERepoCutSameModel *cutSameModel = [self.repository extensionModelOfClass:ACCRepoCutSameModel.class];
    NSArray<LVTemplateVideoEditFragment *> *allVideoFragments = [cutSameModel.dataManager allVideoFragments];
    
    if (!ACC_isEmptyArray(allVideoFragments)) {
        [self.fragmentInfo removeAllObjects];
    }
    
    @weakify(self);
    [allVideoFragments enumerateObjectsUsingBlock:^(LVTemplateVideoEditFragment * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @strongify(self);
        // 剪同款会把资源拷贝进来，不可替换资源即为下发的资源包资源，无需抽帧；
        if (!obj.canReplace) {
            return;
        }
        
        AWEVideoFragmentInfo *fragment = [[AWEVideoFragmentInfo alloc] initWithSourceType:AWEVideoFragmentSourceTypeTemplate];
        if (obj.isVideo) {
            fragment.avAssetURL = [NSURL URLWithString:obj.assetPath];
            fragment.clipTimeRange = [NSValue valueWithCMTimeRange:obj.sourceTimeRaneg];
        } else {
            fragment.imageAssetURL = [NSURL URLWithString:obj.assetPath];
        }
        
        UIEdgeInsets inset = UIEdgeInsetsMake(obj.crop.upperLeftY,
                                              obj.crop.upperLeftX,
                                              1 - obj.crop.lowerRightY,
                                              1 - obj.crop.lowerRightX);
        fragment.frameInsetsModel = [[ACCSecurityFrameInsetsModel alloc] initWithInsets:inset];
        
        [self.fragmentInfo acc_addObject:fragment];
    }];
    
    AWELogToolInfo(AWELogToolTagSecurity, @"updateFragmentInfoForLVFragmentTemplate : fragmentInfo.count = %@", @(self.fragmentInfo.count));
}

/*
 * 更新 LVMaterialTemplate 类视频的 fragmentInfo
 * LVMaterialTemplate类视频：剪同款、时光故事优化版本、一键成片
 */
- (void)updateFragmentInfoForLVMaterialTemplate
{
    AWELogToolInfo(AWELogToolTagSecurity, @"updateFragmentInfoForLVMaterialTemplate start");
    ACCRepoDraftModel *draftRepo = [self.repository extensionModelOfClass:ACCRepoDraftModel.class];
    NSArray<LVCutSameVideoMaterial *> *allVideoFragments = [LVCutSameConsumer getVideoMaterials:[self.nleEditor getModel]];
    
    if (!ACC_isEmptyArray(allVideoFragments)) {
        [self.fragmentInfo removeAllObjects];
    }
    
    @weakify(self);
    [allVideoFragments enumerateObjectsUsingBlock:^(LVCutSameVideoMaterial * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @strongify(self);
        // 剪同款会把资源拷贝进来，不可替换资源即为下发的资源包资源，无需抽帧；
        if (!obj.isMutable) {
            return;
        }
        
        AWEVideoFragmentInfo *fragment = [[AWEVideoFragmentInfo alloc] initWithSourceType:AWEVideoFragmentSourceTypeTemplate];
        NSString *draftFolder = [AWEDraftUtils generateDraftFolderFromTaskId:draftRepo.taskID];
        NSString *fullPath = [draftFolder stringByAppendingPathComponent:obj.relativePath];
        
        // 获取原路径
        NSString *originRelativePath = obj.originPath;
        if (originRelativePath.length > 0) {
            fullPath = [draftFolder stringByAppendingPathComponent:originRelativePath];
        }

        if (fullPath.length == 0) return;
        
        // 确认路径有效性
        BOOL isExit = [[NSFileManager defaultManager] fileExistsAtPath:fullPath];
        if (!isExit) return;
        
        NSURL *fragmentURL = [NSURL URLWithString:fullPath];
        
        NSArray *tracks = [[AVAsset assetWithURL:[NSURL fileURLWithPath:fullPath]] tracksWithMediaType:AVMediaTypeVideo];
        BOOL isVideo = [tracks count] > 0;
        
        if (isVideo) {
            fragment.avAssetURL = fragmentURL;
            fragment.clipTimeRange = [NSValue valueWithCMTimeRange:obj.sourceTimeRange];
        } else {
            fragment.imageAssetURL = fragmentURL;
        }
        
        UIEdgeInsets inset = UIEdgeInsetsMake(obj.cropYUpper,
                                              obj.cropXLeft,
                                              1 - obj.cropYLower,
                                              1 - obj.cropXRight);
        fragment.frameInsetsModel = [[ACCSecurityFrameInsetsModel alloc] initWithInsets:inset];
        
        [self.fragmentInfo acc_addObject:fragment];
    }];
    
    AWELogToolInfo(AWELogToolTagSecurity, @"updateFragmentInfoForLVMaterialTemplate : fragmentInfo.count = %@", @(self.fragmentInfo.count));
}

- (UIImageOrientation)p_realImageOrientation:(AVAsset *)asset
{
    if (!asset) {
        return UIImageOrientationUp;
    }

    ACCRepoUploadInfomationModel *repoUploadInfo = [self.repository extensionModelOfClass:ACCRepoUploadInfomationModel.class];
    UIImageOrientation imageOrientation = UIImageOrientationUp;
    
    NSInteger uploadCount = [repoUploadInfo.originUploadVideoClipCount integerValue] + [repoUploadInfo.originUploadPhotoCount integerValue];
    NSInteger degree = [self.video.assetRotationsInfo[asset] integerValue];;
    NSInteger direction = degree / 90;
    if (self.isFastImportVideo && uploadCount == 1) {
        CGFloat angle = atan2f(self.video.importTransform.b, self.video.importTransform.a);
        if (ACC_FLOAT_EQUAL_TO(angle, M_PI_2)) {
            imageOrientation = UIImageOrientationRight;
        }
        if (ACC_FLOAT_EQUAL_TO(angle, M_PI)) {
            imageOrientation = UIImageOrientationDown;
        }
        if (ACC_FLOAT_EQUAL_TO(angle, -M_PI_2)) {
            imageOrientation = UIImageOrientationLeft;
        }
    }

    if (self.isMultiVideoFastImport && uploadCount > 1) {
        if (direction == AWEVideoCompositionRotateTypeLeft) {
            imageOrientation = UIImageOrientationLeft;
        }
        if (direction == AWEVideoCompositionRotateTypeRight) {
            imageOrientation = UIImageOrientationRight;
        }
        if (direction == AWEVideoCompositionRotateTypeDown) {
            imageOrientation = UIImageOrientationDown;
        }
    }

    return imageOrientation;
}

#pragma mark - Public Methods

- (void)updateVideoData:(ACCEditVideoData *)videoData
{
    self.video = videoData;
}

- (BOOL)isMultiVideoFastImport
{
    ACCRepoUploadInfomationModel *uploadInfoModel = [self.repository extensionModelOfClass:ACCRepoUploadInfomationModel.class];
    return self.isFastImportVideo && uploadInfoModel.isMultiVideoUpload;
}

- (NSDictionary *)cameraDirectionInfoDic
{
    NSMutableArray *cameraPositionCollection = [self.fragmentInfo.rac_sequence foldLeftWithStart:[NSMutableArray array]
                                                                           reduce:^id _Nullable(id  _Nullable accumulator, AWEVideoFragmentInfo * _Nullable value) {
        AWEVideoFragmentInfo *fragment = value;
        [accumulator addObject:ACCDevicePositionStringify(fragment.cameraPosition)];
        return accumulator;
    }];
    
    // @description: 图片模式补充上报camera_direction
    if(ACC_isEmptyArray(cameraPositionCollection)){
       AWERecordInformationRepoModel *recordInfoModel = [self.repository extensionModelOfClass:[AWERecordInformationRepoModel class]];
        if(recordInfoModel){
          [cameraPositionCollection acc_addObject:recordInfoModel.pictureToVideoInfo.cameraDirection];
        }
    }

    return @{@"camera_direction": [cameraPositionCollection copy]};
}

@end
