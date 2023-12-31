//
//  ACCRecordTrackServiceImpl.m
//  Pods
//
//  Created by gcx on 2020/7/6.
//

#import "AWERepoStickerModel.h"
#import "AWERepoContextModel.h"
#import "AWERepoTrackModel.h"
#import "AWERepoMVModel.h"
#import "AWERepoPropModel.h"
#import "ACCRecordTrackServiceImpl.h"
#import <TTVideoEditor/VEMediaEffectTracker.h>
#import <TTVideoEditor/IESMMTrackerManager.h>


#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
// sinkage
#import "AWERecordFirstFrameTrackerNew.h"
#import <CreationKitArch/AWEStudioMeasureManager.h>
#import "AWEVideoPublishViewModel+FilterEdit.h"
#import <CameraClient/ACCKdebugSignPost.h>
#import "ACCFeedbackProtocol.h"
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CreationKitArch/ACCRepoTranscodingModel.h>
#import "AWERecorderTipsAndBubbleManager.h"
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import "AWERepoVideoInfoModel.h"
#import "AWERepoFlowerTrackModel.h"
#import "AWEVideoFragmentInfo.h"
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import "ACCRepoKaraokeModelProtocol.h"
#import "ACCRecognitionTrackModel.h"

#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CameraClient/ACCTrackerUtility.h>
#import <CameraClient/AWERepoDuetModel.h>
#import <CameraClientModel/ACCVideoReplyModel.h>
#import <CameraClient/ACCRepoAudioModeModel.h>

#import <CameraClient/ACCStudioLiteRedPacket.h>

@interface ACCRecordTrackServiceImpl ()

@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, assign) BOOL earphoneOn;

@property (nonatomic, strong) NSHashTable *recordVideoHandlers;
@property (nonatomic, assign) BOOL hasAppeared;

@end

@implementation ACCRecordTrackServiceImpl

@synthesize recordModeTrackName = _recordModeTrackName;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    if (self = [super init]) {
        self.publishModel = publishModel;
        self.recordVideoHandlers = [NSHashTable weakObjectsHashTable];

        AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
        for (AVAudioSessionPortDescription* desc in [route outputs]) {
            if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones])
                self.earphoneOn = YES;
        }

        @weakify(self)
        [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionRouteChangeNotification
                                                          object:[AVAudioSession sharedInstance]
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            @strongify(self)
            NSInteger routeChangeReason = [[note.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
            switch (routeChangeReason) {
                case AVAudioSessionRouteChangeReasonOldDeviceUnavailable: // 此时系统已经自动把mixPlayer暂停了
                    self.earphoneOn = NO;
                    break;
                case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
                    self.earphoneOn = YES;
                    break;
                default:
                    break;
            }
        }];
    }
    return self;
}

#pragma mark - Public

- (void)trackRecordVideoEventWithCameraService:(id<ACCCameraService>)cameraService;
{
    NSMutableDictionary *params = self.publishModel.repoTranscoding.videoQualityTraceInfo;
    NSMutableDictionary *referExtra = [self.publishModel.repoTrack.referExtra mutableCopy];
    NSString *creationID = referExtra[@"creation_id"];
    [params addEntriesFromDictionary:referExtra];
    // ⚠️ enter_from 取值覆盖掉 referExtra 提供的值
    params[@"enter_from"] = @"video_shoot_page";
    
    for (id<ACCRecordVideoEventHandler> handler in self.recordVideoHandlers) {
        if ([handler respondsToSelector:@selector(recordVideoEvent)]) {
            NSDictionary *info = [handler recordVideoEvent];
            if (!ACC_isEmptyDictionary(info)) {
                [params addEntriesFromDictionary:info];
            }
        }
    }
    
    if (self.publishModel.repoFlowerTrack.isFromShootProp) {
        params[@"record_mode"] = @"photo";
    }
    
    // 仅在使用Composer的情况下上报美颜信息
    NSMutableDictionary *perfParams = [NSMutableDictionary dictionary];
    perfParams[@"creation_id"] = creationID;
    AWEVideoFragmentInfo *lastInfo = [self.publishModel.repoVideoInfo.fragmentInfo lastObject];
    if (lastInfo.composerBeautifyInfo) {
        perfParams[@"beautify_used"] = lastInfo.composerBeautifyUsed ? @"1":@"0";
        NSData *composerData = [lastInfo.composerBeautifyInfo dataUsingEncoding:NSUTF8StringEncoding];
        if (composerData) {
            NSArray *composerBeautifyInfo = [NSJSONSerialization JSONObjectWithData:composerData options:0 error:nil];
            perfParams[@"beautify_info"] = [composerBeautifyInfo mutableCopy];
        }
    } else {
        perfParams[@"beautify_used"] = lastInfo.beautifyUsed ? @"1" : @"0";
        perfParams[@"beautify_info"] = @[];
    }
    AWEVideoPublishViewModel *publishModel = self.publishModel;
    perfParams[@"is_composer"] = lastInfo.composerBeautifyInfo ? @(1) : @(0);
    
    if (self.publishModel.repoReshoot.isReshoot) {
        params[@"action_type"] = @"reshoot";
    }
    
    params[@"is_meteormode"] = @(self.publishModel.repoContext.isMeteorMode ? 1 : 0);

    if (!ACC_isEmptyString(self.publishModel.repoProp.localPropId)) {
        params[@"from_prop_id"] = self.publishModel.repoProp.localPropId;
        if (!ACC_isEmptyString(lastInfo.stickerId)) {
            BOOL isDefaultProp = [self.publishModel.repoProp.localPropId isEqualToString:lastInfo.stickerId];
            params[@"is_default_prop"] = isDefaultProp ? @"1" : @"0";
        } else {
            params[@"is_default_prop"] = @"";
        }
    }
    
    params[@"shoot_way"] = publishModel.repoTrack.referString?:@"";
    if (publishModel.repoDuet.isDuet && publishModel.repoDuet.duetLayout) {
        params[@"duet_layout"] = publishModel.repoDuet.duetLayout;
        params[@"mic_status"] = publishModel.repoVideoInfo.videoMuted ? @"off" : @"on";
    }
    [params addEntriesFromDictionary:[publishModel.repoSticker videoCommentStickerTrackInfo]];

    BOOL isFromMainRecorder = publishModel.repoContext.recordSourceFrom == AWERecordSourceFromUnknown;
    NSString *recordVideoEventName = @"";
    if (isFromMainRecorder) {
        recordVideoEventName = @"record_video";
        NSString *musicRecommendPropID = [ACCCache() stringForKey:kACCMusicRecommendPropIDKey];
        if (musicRecommendPropID) {
            params[@"is_pop_up_recommend_prop"] = [musicRecommendPropID isEqualToString:lastInfo.stickerId] ? @"true" : @"false";
        }
        params[@"creation_session_id"] = publishModel.repoTrack.creationSessionId ?: @"";
        /// @description: record_video埋点中的prop_selected_from字段只需要上报当前fragment的propSelectedFrom
        params[@"prop_selected_from"] = publishModel.repoVideoInfo.fragmentInfo.lastObject.propSelectedFrom;
        
        params[@"prop_type"] = [ACCStudioLiteRedPacket() recordPropType:publishModel];
        
        NSDictionary *liteParams = [ACCStudioLiteRedPacket() enterVideoEditPageParams:publishModel];
        if (liteParams) {
            [params addEntriesFromDictionary:liteParams];
        }
        
    } else {
        recordVideoEventName = @"im_record_video";
        params[@"entrance"] = self.publishModel.repoTrack.entrance;
    }
    
    //================================================================================
    AVCaptureDevicePosition cameraPostion = cameraService.cameraControl.currentCameraPosition;
    params[@"camera_direction"] =  ACCDevicePositionStringify(cameraPostion);
    //================================================================================
    if (publishModel.repoContext.videoType == AWEVideoTypeKaraoke) {
        id<ACCRepoKaraokeModelProtocol> repoKaraoke = [publishModel extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
        params[@"music_id"] = repoKaraoke.karaokeMusicID;
        params[@"pop_music_type"] = repoKaraoke.recordMode == ACCKaraokeRecordModeAudio ? @"audio" : @"video";
    }

    //================================================================================
    ACCRecognitionTrackModel *recognitionTrack = [self.publishModel extensionModelOfClass:ACCRecognitionTrackModel.class];
    if (recognitionTrack){
        params[@"content_type"] = @"reality";
        params[@"prop_selected_from"] = recognitionTrack.realityType;
        params[@"reality_id"] = recognitionTrack.realityId;
        params[@"rec_location"] = @(recognitionTrack.propIndex);

    }
    //================================================================================
    
    if (self.publishModel.repoAudioMode.isAudioMode) {
        params[@"content_source"] = @"shoot";
    }
    
    if (publishModel.repoContext.isTriggeredByVolumeButton) {
        params[@"record_method"] = @"volume_button";
    } else {
        params[@"record_method"] = @"shoot_button";
    }
    
    if (publishModel.repoTrack.schemaTrackParmForActivity) {
        [params addEntriesFromDictionary:publishModel.repoTrack.schemaTrackParmForActivity];
    }
    
    if (!ACC_isEmptyArray(publishModel.repoSticker.shootSameStickerModels)) {
        [publishModel.repoSticker.shootSameStickerModels enumerateObjectsUsingBlock:^(ACCShootSameStickerModel * _Nonnull shootSameStickerModel, NSUInteger idx, BOOL * _Nonnull stop) {
            if (shootSameStickerModel.stickerType == AWEInteractionStickerTypeComment) {
                params[@"reply_object"] =  @"comment";
                if (shootSameStickerModel.isDeleted) {
                    params[@"is_retain_sticker"] = @(0);
                } else {
                    params[@"is_retain_sticker"] = @(1);
                }
            }
        }];
    }
    
    if (publishModel.repoSticker.videoReplyModel != nil) {
        params[@"reply_object"] =  @"video";
        
        if (publishModel.repoSticker.videoReplyModel.isDeleted) {
            params[@"is_retain_sticker"] = @(0);;
        } else {
            params[@"is_retain_sticker"] = @(1);;
        }
    }
    
    publishModel.repoContext.isTriggeredByVolumeButton = NO;
    
    [ACCTracker() trackEvent:recordVideoEventName params:params needStagingFlag:NO];
    [ACCTracker() trackEvent:@"perf_record_video" params:perfParams needStagingFlag:NO];
    [ACCTracker() trackEvent:@"earphone_status"
                       params:@{
                           @"plugin_type" : @"record_video",
                           @"to_status" : self.earphoneOn ? @"on" : @"off"
                       }
              needStagingFlag:NO];
}

- (void)trackRecordVideoEventWithSticker:(IESEffectModel *)sticker localSticker:(IESEffectModel *)localSticker prioritizedStickers:(NSArray<IESEffectModel *> *)prioritizedStickers
{
    
}

- (void)registRecordVideoHandler:(id<ACCRecordVideoEventHandler>)handler
{
    NSParameterAssert([handler conformsToProtocol:@protocol(ACCRecordVideoEventHandler)]);
    [self.recordVideoHandlers addObject:handler];
}

- (void)trackPreviewPerformanceWithInfo:(NSDictionary *)info nextAction:(NSString *)nextAction
{
    if (self.publishModel.repoVideoInfo.video.videoAssets.count > 0) {
        return;
    }
    
    IESMMTrackerManager *mmTracker = [IESMMTrackerManager shareInstance];
    CGFloat previewFPS = [mmTracker getPreviewPureFps];
    NSInteger lagCount = [mmTracker getPreviewLagCount];
    NSInteger lagMax = [mmTracker getPreviewLagMaxDuration];
    NSInteger lagDuration = [mmTracker getPreviewLagTotalDuration];
    
    NSMutableDictionary *params = @{@"fps":@(previewFPS),
                                    @"lag_count":@(lagCount),
                                    @"lag_max":@(lagMax),
                                    @"lag_total_duration":@(lagDuration),
                                    @"frame_total":@(mmTracker.recordCount),
                                    @"duration":@(mmTracker.recordStopTime - mmTracker.recordStartTime),
                                    @"next_action":nextAction?:@""}.mutableCopy;
    [params addEntriesFromDictionary:info ? : @{}];
    [params addEntriesFromDictionary:self.publishModel.repoRecordInfo.beautifyTrackInfoDic?:@{}];
    [params addEntriesFromDictionary:self.publishModel.repoTrack.commonTrackInfoDic?:@{}];
    [ACCTracker() trackEvent:@"tool_performance_video_preview" params:params.copy needStagingFlag:NO];
}

- (void)trackRecordPerformanceWithCameraService:(id<ACCCameraService>)cameraService beautyStatus:(NSInteger)beautyStatus
{
    IESMMTrackerManager *mmTracker = [IESMMTrackerManager shareInstance];
    
    CGFloat previewFPS = [mmTracker getPreviewFPS];
    CGFloat writerFPS = [mmTracker getRecordFPS];
    
    NSInteger lagCount = [mmTracker getRecordLagCount];
    NSInteger lagMax = [mmTracker getRecordLagMaxDuration];
    NSInteger lagDuration = [mmTracker getRecordLagTotalDuration];

    AVAsset *srcAsset = self.publishModel.repoVideoInfo.video.videoAssets.firstObject;
    AVAssetTrack *srcVTrack = [srcAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    NSInteger file_bitrate = (NSInteger)(roundf(srcVTrack.estimatedDataRate/1000.f)); //kbps
    NSUInteger bitrate = (NSInteger)(roundf(self.publishModel.repoVideoInfo.video.transParam.bitrate / 1000.f));//kbps
    
    AWEVideoFragmentInfo *lastFragmentInfo = [self.publishModel.repoVideoInfo.fragmentInfo lastObject];
    NSTimeInterval duration = (mmTracker.recordStopTime - mmTracker.recordStartTime) * 1000.f; //ms
    CGFloat zoomFactor = cameraService.cameraControl.zoomFactor;
    NSString *resolution = [NSString stringWithFormat:@"%@*%@",@(cameraService.config.outputSize.width),@(cameraService.config.outputSize.height)];
    
    NSMutableDictionary *params = @{@"fps":@(previewFPS),
                                    @"write_fps":@(writerFPS),
                                    @"file_bitrate":@(file_bitrate),
                                    @"bitrate":@(bitrate),
                                    @"beauty_status":@(beautyStatus),
                                    @"resolution":resolution,
                                    @"effect_id":lastFragmentInfo.stickerId ?:@"",
                                    @"filter_id":lastFragmentInfo.colorFilterId ?: (lastFragmentInfo.hasDeselectionBeenMadeRecently ? @"-1" : @""),
                                    @"lag_count":@(lagCount),
                                    @"lag_max":@(lagMax),
                                    @"lag_total_duration":@(lagDuration),
                                    @"frame_total":@(mmTracker.recordCount),
                                    @"duration":@(duration),
                                    @"digtal_zoom_value" : @(zoomFactor)}.mutableCopy;

    if ([cameraService.cameraControl currentExposureBias] != 0) {
        params[@"exposure_values"] = @([cameraService.cameraControl currentExposureBias]);
    }

    [params addEntriesFromDictionary:self.publishModel.repoRecordInfo.beautifyTrackInfoDic?:@{}];
    [params addEntriesFromDictionary:self.publishModel.repoTrack.commonTrackInfoDic?:@{}];
    params[@"activity_id"] = self.publishModel.repoVideoInfo.dynamicActivityID ?: @"";
    [ACCTracker() trackEvent:@"tool_performance_video_record" params:params.copy needStagingFlag:NO];
}


- (void)configTrackDidLoad
{
    // 配置VE里的埋点tracker
    VEMediaEffectTracker *tracker = [[VEMediaEffectTracker alloc] init];
    [VEMediaEffectTracker setTrackerInstance:tracker];
}

- (void)trackError:(NSError *)error action:(NSString *)action info:(NSDictionary *)info
{
    if (!error && [action isEqualToString:@"export"]) {
        NSDictionary *data = @{@"service"   : @"record_error",
                               @"action"    : action?:@"null",
                               @"errorCode" : @(0).description?:@"null"};
        [[AWEStudioMeasureManager sharedMeasureManager] asyncMonitorTrackData:data logTypeStr:@"aweme_movie_publish_log"];
    }
    if (error) {
        // 录制错误监控
        NSMutableDictionary *data = [@{@"service"   : @"record_error",
                               @"errorCode" : @(error.code).description?:@"null",
                               @"errorDesc" : error.localizedDescription?:@"null",
                               @"errorDomain" : error.domain?:@"null",
                               @"action"    : action?:@"null"} mutableCopy];
        [data addEntriesFromDictionary:info ? : @{}];
        
        [[AWEStudioMeasureManager sharedMeasureManager] asyncMonitorTrackData:data logTypeStr:@"aweme_movie_publish_log"];
        AWELogToolError(AWELogToolTagRecord|AWELogToolTagVideoEditor, @"%@", [NSString stringWithFormat:@"[record_error]: %@", data]);

        // 加使用音乐无法录制的监控
        CFTimeInterval recordActionDurationTime = [AWEStudioMeasureManager sharedMeasureManager].pauseRecordTime - [AWEStudioMeasureManager sharedMeasureManager].startRecordTime;
        if (recordActionDurationTime > 1.0f && !ACC_isEmptyString(self.publishModel.repoMusic.music.musicID)) {
            AWELogToolInfo(AWELogToolTagRecord|AWELogToolTagVideoEditor, @"record action duration: %f", recordActionDurationTime);
            NSDictionary *errorData = @{@"service"   : @"record_error",
                                        @"action"    : @"record_too_short_error",
                                        @"record_action_duration" : @(recordActionDurationTime),
                                        @"error_code" : @(error.code),
                                        };
            [[AWEStudioMeasureManager sharedMeasureManager] asyncMonitorTrackData:errorData logTypeStr:@"aweme_movie_publish_log"];
        }
    }
    
    NSDictionary *data = @{@"service"   : @"record_error_rate",
                           @"errorCode" : @(error?error.code:100).description?:@"null",
                           @"action"    : action?:@"null"};
    [[AWEStudioMeasureManager sharedMeasureManager] asyncMonitorTrackData:data logTypeStr:@"aweme_movie_publish_log"];
}

- (void)trackPauseRecordWithCameraService:(id<ACCCameraService>)cameraService error:(NSError *)error sticker:(IESEffectModel *)sticker beautyStatus:(NSInteger)beautyStatus
{
    if (!error) {
        [self trackRecordPerformanceWithCameraService:cameraService beautyStatus:beautyStatus];
        AWEVideoFragmentInfo *fragmentInfo = self.publishModel.repoVideoInfo.fragmentInfo.lastObject;
        NSMutableDictionary *trackData = [NSMutableDictionary dictionary];
        trackData[@"status"] = @0;
        if (self.publishModel.repoMusic.music) {
            trackData[@"music_id"] = self.publishModel.repoMusic.music.musicID;
        }
        
        IESMMTrackerManager *mmTracker = [IESMMTrackerManager shareInstance];
        fragmentInfo.frameCount = mmTracker.recordCount;
        fragmentInfo.recordDuration = mmTracker.recordStopTime - mmTracker.recordStartTime;
        NSDictionary *fragmentInfoDic = [fragmentInfo dictionaryValue];
        double fps = -1;
        if (fragmentInfo.recordDuration > 0) {
            fps = fragmentInfo.frameCount / fragmentInfo.recordDuration;
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            trackData[@"fps"] = @(fps);
            [ACCMonitor() trackData:trackData logTypeStr:@"aweme_record_success_rate"];
            
            // feedback
            [ACCFeedback() acc_recordForVideoRecord:AWEStudioFeedBackStatusSuccess code:error.code];
            
            NSMutableDictionary *data = @{@"service"   : @"record_performance",
                                          @"action"    : @"fragment_finished",}.mutableCopy;
            
            if (fragmentInfoDic) {
                [data addEntriesFromDictionary:fragmentInfoDic];
            }
            
            data[@"fps"] = @(fps);
            data[@"sticker_md5"] = sticker.md5 ?: @"";
            
            [ACCMonitor() trackData:data logTypeStr:@"publish_core_log"];
        });
    } else {
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        params[@"status"] = @1;
        params[@"errorCode"] = @(error.code);
        params[@"errorDesc"] = error.description ?: @"";
        if (self.publishModel.repoMusic.music) {
            params[@"music_id"] = self.publishModel.repoMusic.music.musicID;
        }
        [ACCMonitor() trackData:params logTypeStr:@"aweme_record_success_rate"];
        
        // feedback
        [ACCFeedback() acc_recordForVideoRecord:AWEStudioFeedBackStatusFail code:error.code];
        AWELogToolError(AWELogToolTagRecord, @"%s %@", __PRETTY_FUNCTION__, error);
    }
}

- (void)trackEnterVideoShootPageWithSwapCamera:(BOOL)isSwapCamera
{
    AWEVideoPublishViewModel *publishModel = self.publishModel;
    [[AWEStudioMeasureManager sharedMeasureManager] trackClickPlusToRecordPageFirstFrameAppearWithReferString:publishModel.repoTrack.referString];
    if (!isSwapCamera) {
        NSMutableDictionary *extra = [NSMutableDictionary dictionaryWithDictionary:publishModel.repoTrack.enterShootPageExtra];
        extra[@"duration"] = @([AWEStudioMeasureManager sharedMeasureManager].viewDidLoadedToFirstFrameAppearDuration);
        NSDictionary *dic = [self.publishModel.repoTrack performanceTrackInfoDic];
        if (dic) {
            [extra addEntriesFromDictionary:dic];
        }
        extra[@"mv_id"] = self.publishModel.repoMV.mvID ? : @"";
        extra[@"prop_id"] = self.publishModel.repoSticker.stickerID ? : @"";
        extra[@"music_id"] = self.publishModel.repoMusic.music.musicID ? : @"";
        extra[@"landing_page"] = self.recordModeTrackName ?: @"";
        if (!ACC_isEmptyString(self.publishModel.repoTrack.storyGuidePlusIconType)) {
            extra[@"plus_icon_type"] = self.publishModel.repoTrack.storyGuidePlusIconType;
        }
        NSString *enterMethod = (self.hasAppeared || self.publishModel.repoDraft.isDraft || self.publishModel.repoDraft.isBackUp || self.publishModel.repoReshoot.isReshoot) ? @"click_back_button" : @"click_shoot";
        if (self.publishModel.repoDuet.isFromDuetSingMode) {
            enterMethod = @"click_duet_button";
        }
        AWEVideoPublishViewModel *sourceRepository = self.publishModel.repoContext.sourceModel;
        
        if (!self.publishModel.repoTrack.hasRecordEnterEvent && !sourceRepository.repoTrack.hasRecordEnterEvent && self.publishModel.repoTrack.isRestoreFromBackup) {
            extra[@"is_restore_crash"] = @(YES);
            self.publishModel.repoTrack.hasRecordEnterEvent = YES;
            sourceRepository.repoTrack.hasRecordEnterEvent = YES;
            enterMethod = @"click_continue_popup";
        }
        self.hasAppeared = YES;
        AWERecordSourceFrom recordSourceFrom = publishModel.repoContext.recordSourceFrom;
        [[AWEStudioMeasureManager sharedMeasureManager] asyncOperationBlock:^{
            NSString *eventName = recordSourceFrom == AWERecordSourceFromUnknown ? @"enter_video_shoot_page" : @"im_enter_video_shoot_page";
            [publishModel trackPostEvent:eventName enterMethod:enterMethod extraInfo:extra isForceSend:YES];
        }];
    }
    ACCKdebugSignPostEnd(10, 0, 0, 0, 0);
}

@end
