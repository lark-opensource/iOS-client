//
//  ACCRecordFlowServiceImpl.m
//  Pods
//
//  Created by liyingpeng on 2020/6/23.
//

#import "AWERepoPublishConfigModel.h"
#import "AWERepoVideoInfoModel.h"
#import "AWERepoPropModel.h"
#import "ACCRecordFlowServiceImpl.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import "AWEVideoPublishViewModel+InteractionSticker.h"
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import <CreationKitArch/AWEStudioMeasureManager.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import "ACCConfigKeyDefines.h"
#import "ACCAudioAuthUtils.h"
#import "AWERecordInformationRepoModel.h"
#import "ACCRecordConfigService.h"
#import <TTVideoEditor/UIImage+ImageProcess.h>
#import <TTVideoEditor/IESMMTrackerManager.h>
#import "ACCRepoStickerModel+InteractionSticker.h"
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoGameModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import <CreationKitArch/ACCRepoChallengeModel.h>
#import "ACCConfigKeyDefines.h"
#import "AWEVideoFragmentInfo.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/NSData+ACCAdditions.h>
#import <TTVideoEditor/UIImage+ImageProcess.h>
#import <TTVideoEditor/IESMMTrackerManager.h>
#import <CameraClient/ACCEditVideoDataFactory.h>
#import "AWERepoVideoInfoModel.h"
#import "AWERepoContextModel.h"
#import "ACCTrackerUtility.h"
#import "ACCEditVideoDataDowngrading.h"
#import "ACCVEVideoData.h"
#import "ACCRecorderLivePhotoProtocol.h"
#import "ACCRepoLivePhotoModel.h"
#import "AWERepoStickerModel.h"
#import <CreativeKit/ACCProtocolContainer.h>
#import <CameraClientModel/ACCVideoCanvasType.h>
#import "ACCRepoAudioModeModel.h"
#import <CameraClient/ACCUIReactTrackProtocol.h>
#import "ACCRecorderProtocolD.h"
#import <CameraClient/ACCRepoAudioModeModel.h>
#import <CameraClient/ACCCameraFactory.h>

@interface ACCRecordFlowServiceImpl ()

@property (nonatomic, assign, readwrite) ACCRecordFlowState flowState;
@property (nonatomic, strong, readwrite) NSMutableArray *markedTimes;

@property (nonatomic, strong) ACCCameraSubscription *subscription;
@property (nonatomic, strong) RACSubject *captureStillImageSubject;

@end

@implementation ACCRecordFlowServiceImpl
@synthesize selectedSpeed = _selectedSpeed;
@synthesize flowState = _flowState;
@synthesize isFirstDuration = _isFirstDuration;
@synthesize exporting = _exporting;
@synthesize currentDuration = _currentDuration;
@synthesize lastCapturedVideoDuration = _lastCapturedVideoDuration;
@synthesize reactLastCapturedVideoDuration = _reactLastCapturedVideoDuration;
@synthesize mixSubtype = _mixSubtype;
@synthesize hasStopCaptureWhenEnterEdit = _hasStopCaptureWhenEnterEdit;
@synthesize isDelayRecord = _isDelayRecord;
@synthesize segmentDurationEnumerator = _segmentDurationEnumerator;
@synthesize totalDurationCalculator = _totalDurationCalculatortail;

- (instancetype)init
{
    if (self = [super init]) {
        _selectedSpeed = HTSVideoSpeedNormal;
    }
    return self;
}

#pragma mark - duration

- (NSInteger)markedTimesCount
{
    return _markedTimes.count;
}

- (NSMutableArray *)markedTimes
{
    if (!_markedTimes) {
        _markedTimes = [NSMutableArray arrayWithCapacity:5];
    }
    return _markedTimes;
}

- (void)removeAllMarkedTime
{
    [[self mutableArrayValueForKey:@"markedTimes"] removeAllObjects];
    if (self.repository.repoReshoot.isReshoot && self.repository.repoReshoot.durationBeforeReshoot > 0) {
        [[self mutableArrayValueForKey:@"markedTimes"] addObject:@(0)];
    }
}

- (void)removeLastMarkedTime
{
    [[self mutableArrayValueForKey:@"markedTimes"] removeLastObject];
    if (self.repository.repoReshoot.isReshoot && [self markedTimesCount] == 0 && self.repository.repoReshoot.durationBeforeReshoot > 0) {
        [[self mutableArrayValueForKey:@"markedTimes"] addObject:@(0)];
    }
}

- (void)setCurrentDuration:(CGFloat)currentDuration
{
    if (isnan(currentDuration)) {
        return;
    }
    
    if (currentDuration != _currentDuration) {
        if (!self.repository.repoReshoot.isReshoot) {
            [self judgeIsFirstVideoDuration:currentDuration];
        }
        _currentDuration = currentDuration;
        [self.subscription performEventSelector:@selector(flowServiceDidUpdateDuration:) realPerformer:^(id<ACCRecordFlowServiceSubscriber> subscriber) {
            [subscriber flowServiceDidUpdateDuration:currentDuration];
        }];
    }
}

- (void)markDuration:(CGFloat)duration
{
    CGFloat toMarkDuration = duration;
    if (self.repository.repoReshoot.isReshoot) {
        toMarkDuration = MIN(duration, self.repository.repoContext.maxDuration);
    }
    if (self.markedTimes.lastObject == nil ||
        toMarkDuration != [self.markedTimes.lastObject floatValue]) {
        if (self.markedTimes || self.repository.repoReshoot.isReshoot) {
            [[self mutableArrayValueForKey:@"markedTimes"] addObject:@(toMarkDuration)];
        }
        [self.subscription performEventSelector:@selector(flowServiceDidMarkDuration:) realPerformer:^(id<ACCRecordFlowServiceSubscriber> subscriber) {
            [subscriber flowServiceDidMarkDuration:toMarkDuration];
        }];
    }
}

- (void)restoreDuration
{
    self.currentDuration = [self.cameraService.recorder.videoData totalVideoDuration];
}

- (void)restoreVideoDuration
{
    BOOL isDraftOrBackup = self.repository.repoDraft.isDraft || self.repository.repoDraft.isBackUp;
    if (AWEVideoTypePhotoToVideo == self.repository.repoContext.videoType && isDraftOrBackup) {
        return;
    }

    [self removeAllMarkedTime];
    if (self.repository.repoReshoot.isReshoot) {
        if (self.repository.repoReshoot.durationBeforeReshoot > 0) {
            [self markDuration:0];
        }
    } else {
        self.isFirstDuration = NO;
    }
    __block CMTime totalDuration = kCMTimeZero;

    AWELogToolInfo(AWELogToolTagRecord, @"%@", [NSString stringWithFormat:@"Record restore segmentDuration, is draft: %@, draft videoSource type: %@", self.repository.repoDraft.isDraft ? @"YES" : @"NO", @(self.repository.repoDraft.originalModel.repoContext.videoSource)]);
    
    @weakify(self);
    void(^enumerateBlock)(CMTime) = ^(CMTime segmentDuration) {
        @strongify(self);
        totalDuration = CMTimeAdd(totalDuration, segmentDuration);
        AWELogToolInfo(AWELogToolTagRecord,@"%@", [NSString stringWithFormat:@"Record restore segmentDuration: %f", CMTimeGetSeconds(segmentDuration)]);
        [self markDuration:(CGFloat)CMTimeGetSeconds(totalDuration)];
    };
    // We do not have video segments in karaoke audio mode, in which case we need a special enumerator to compute duration for each audio segment. `self.segmentDurationEnumerator` is set in `RecordFlowKaraokePlugin`.
    if (self.segmentDurationEnumerator) {
        HTSVideoData *videoData = acc_videodata_make_hts(self.repository.repoVideoInfo.video);
        self.segmentDurationEnumerator(videoData, enumerateBlock);
    } else {
        [self.repository.repoVideoInfo.video acc_getRestoreVideoDurationWithSegmentCompletion:enumerateBlock];
    }
    self.currentDuration = CMTimeGetSeconds(totalDuration);
    [self.subscription performEventSelector:@selector(flowServiceDurationHasRestored) realPerformer:^(id<ACCRecordFlowServiceSubscriber> subscriber) {
        [subscriber flowServiceDurationHasRestored];
    }];
    if (!self.repository.repoReshoot.isReshoot) {
        if (self.cameraService.cameraHasInit) {
            self.lastCapturedVideoDuration = self.cameraService.recorder.videoData.totalVideoDuration;
        }
    }
}

- (void)setupMaxLimitTime
{
    if (self.repository.repoGame.gameType != ACCGameTypeNone) {
        [self.cameraService.recorder setMaxLimitTime:kCMTimeInvalid];
    } else {
        int32_t timeScale = 600;
        double maxDuration = self.repository.repoContext.maxDuration;
        double totalDuration = [self.cameraService.recorder getTotalDuration];
        maxDuration -= totalDuration;
        maxDuration = maxDuration > 0 ? maxDuration : 0;
        CMTime time = CMTimeMakeWithSeconds(maxDuration, timeScale);
        [self.cameraService.recorder setMaxLimitTime:time];
    }
}

#pragma mark - private

- (void)judgeIsFirstVideoDuration:(CGFloat)currentDuration
{
    self.isFirstDuration = NO;
}

- (BOOL)allowComplete
{
    CGFloat maxDuration = self.repository.repoContext.maxDuration;
    if ([self.repository.repoFlowControl isFixedDuration]) {
        return self.currentDuration >= maxDuration;
    }
    if ([self.recordConfigService respondsToSelector:@selector(videoMinDuration)]) {
        CGFloat videoMinSeconds = [self.recordConfigService videoMinDuration];
        return self.currentDuration >= videoMinSeconds;
    }
    id<ACCVideoConfigProtocol> videoConfig = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
    NSInteger videoMinSeconds = [videoConfig videoMinSeconds];

    return self.currentDuration >= videoMinSeconds;
}

#pragma mark - remove video

- (void)deleteAllSegments
{
    [self deleteAllSegments:nil];
}

- (void)deleteAllSegments:(dispatch_block_t)completion
{
    // TODO: @xiafeiyu 从 17.0.0 开始，等几个版本没问题就保留 if，删除 else
    if (ACCConfigBool(kConfigBool_karaoke_enabled) && ACCConfigBool(kConfigBool_enable_story_tab_in_recorder)) {
        @weakify(self);
        [self.cameraService.recorder removeAllVideoFragments:^{
            @strongify(self);
            [self p_deleteAllSegmentsStickerSavePhotos];
            [self.repository.repoVideoInfo.fragmentInfo removeAllObjects];
            self.repository.repoPublishConfig.firstFrameImage = nil;
            // 拍摄器不兼容 NLE
            ACCEditVideoData *videoData = [ACCVEVideoData videoDataWithVideoData:self.cameraService.recorder.videoData draftFolder:self.repository.repoDraft.draftFolder];
            [self.repository.repoVideoInfo updateVideoData:videoData];
            [self p_deleteAllSegmentsFrames];
            [self.repository.repoSticker removeAllSegmentStickerLocations];

            acc_dispatch_main_async_safe(^{
                @strongify(self);
                [self removeAllMarkedTime];
                self.currentDuration = 0.0f;
                [self.subscription performEventSelector:@selector(flowServiceDidRemoveAllSegment) realPerformer:^(id<ACCRecordFlowServiceSubscriber> subscriber) {
                    [subscriber flowServiceDidRemoveAllSegment];
                }];
                ACCBLOCK_INVOKE(completion);
            });
        }];
    } else {
        [self.cameraService.recorder removeAllVideoFragments:^{
            acc_dispatch_main_async_safe(^{
                ACCBLOCK_INVOKE(completion);
            });
        }];
        [self p_deleteAllSegmentsStickerSavePhotos];
        [self.repository.repoVideoInfo.fragmentInfo removeAllObjects];
        self.repository.repoPublishConfig.firstFrameImage = nil;
        // 拍摄器不兼容 NLE
        ACCEditVideoData *videoData = [ACCVEVideoData videoDataWithVideoData:self.cameraService.recorder.videoData draftFolder:self.repository.repoDraft.draftFolder];
        [self.repository.repoVideoInfo updateVideoData:videoData];
        [self p_deleteAllSegmentsFrames];
        [self.repository.repoSticker removeAllSegmentStickerLocations];

        [self removeAllMarkedTime];

        self.currentDuration = 0.0f;

        [self.subscription performEventSelector:@selector(flowServiceDidRemoveAllSegment) realPerformer:^(id<ACCRecordFlowServiceSubscriber> subscriber) {
            [subscriber flowServiceDidRemoveAllSegment];
        }];
    }

}

- (void)p_deleteAllSegmentsFrames
{
    [self.repository.repoVideoInfo.originalFrameNamesArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *imagePath = [AWEDraftUtils generatePathFromTaskId:self.repository.repoDraft.taskID name:obj];
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:imagePath error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagRecord, @"removeItemAtPath failed. %@", error);
        }
    }];
}

- (void)removeLastVideoFragmentInfo
{
    NSUInteger stickerSavePhotosCount = self.repository.repoVideoInfo.fragmentInfo.lastObject.stickerSavePhotoInfo.photoNames.count;
    self.repository.repoProp.totalStickerSavePhotos -= stickerSavePhotosCount;
    [self p_deleteLastSegmentFrames];
    [self p_deleteLastSegmentStickerSavePhotos]; // 清除该段视频中的道具存图
    AWEVideoFragmentInfo *lastFragmentInfo = [self.repository.repoVideoInfo.fragmentInfo lastObject];
    
    [self.repository enumerateExtensionModels:YES requireProtocol:nil requireSelector:@selector(onRemoveLastVideoFragmentInfo:) block:^(NSString *clzStr, id model, BOOL *stop) {
        [model onRemoveLastVideoFragmentInfo:lastFragmentInfo];
    }];

    [self.repository.repoVideoInfo.fragmentInfo removeLastObject];
    
    // 所有视频片段删除后，清理firstFrameImage
    if (self.repository.repoVideoInfo.fragmentInfo.count == 0) {
        self.repository.repoPublishConfig.firstFrameImage = nil;
    }
    [self adjustPublishTitleAfterRemoveLastVideoFragmentInfo:lastFragmentInfo];
}

/*
 删除片段后需要将对应话题也移除
 */
- (void)adjustPublishTitleAfterRemoveLastVideoFragmentInfo:(AWEVideoFragmentInfo *)lastFragmentInfo
{
    NSSet<NSString *> *allChallengeName = [NSSet setWithArray:[self.repository.repoChallenge allChallengeNameArray]];
    NSMutableArray<NSString *> *removeChallengeName = [NSMutableArray array];
    
    // 判断删除片段中的话题是否还存在 allChallengeName 中，若没有，从 publishTitle 移除
    [lastFragmentInfo.challengeInfos enumerateObjectsUsingBlock:^(AWEVideoPublishChallengeInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.challengeName.length > 0 && ![allChallengeName containsObject:obj.challengeName]) {
            [removeChallengeName addObject:obj.challengeName];
        }
    }];
    
    __block NSString *publishTitle = self.repository.repoPublishConfig.publishTitle;
    [removeChallengeName enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *hashTag = [NSString stringWithFormat:@"#%@ ", obj];
        NSRange range = [publishTitle rangeOfString:hashTag];
        if (range.location != NSNotFound) {
            publishTitle = [publishTitle stringByReplacingCharactersInRange:range withString:@""];
        }
    }];
    
    self.repository.repoPublishConfig.publishTitle = publishTitle;
}

- (void)p_deleteLastSegmentFrames
{
    [self.repository.repoVideoInfo.fragmentInfo.lastObject.originalFramesArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *imagePath = [AWEDraftUtils generatePathFromTaskId:self.repository.repoDraft.taskID name:obj];
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:imagePath error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagRecord, @"removeItemAtPath failed. %@", error);
        }
    }];
}

- (void)p_deleteLastSegmentStickerSavePhotos
{
    [self.repository.repoVideoInfo.fragmentInfo.lastObject deleteStickerSavePhotos:self.repository.repoDraft.taskID];
}

- (void)p_deleteAllSegmentsStickerSavePhotos
{
    [self.repository.repoVideoInfo.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull info, NSUInteger idx, BOOL * _Nonnull stop) {
        [info deleteStickerSavePhotos:self.repository.repoDraft.taskID];
    }];
    self.repository.repoProp.totalStickerSavePhotos = 0;
}

- (void)removeLastSegment
{
    [self.repository.repoSticker removeLastSegmentStickerLocations];
    [self.cameraService.recorder removeLastVideoFragment];
    [self removeLastMarkedTime];
    [self removeLastVideoFragmentInfo];
    [self fillChallengeNameForFragmentInfo];
    self.currentDuration = [[self.markedTimes lastObject] floatValue];
    [self.subscription performEventSelector:@selector(flowServiceDidRemoveLastSegment:) realPerformer:^(id<ACCRecordFlowServiceSubscriber> subscriber) {
        [subscriber flowServiceDidRemoveLastSegment:NO];
    }];
}

- (void)fillChallengeNameForPictureInfo
{
    //填充每一段用了什么挑战name
    for (AWEVideoPublishChallengeInfo *challenge in self.repository.repoRecordInfo.pictureToVideoInfo.challengeInfos) {
        NSAssert(challenge.challengeId.length > 0, @"name of challenge(challengeName=%@) is invalid!!", challenge.challengeName);
        if (challenge.challengeId.length > 0) {
            NSString *challengeName = self.repository.repoProp.cacheStickerChallengeNameDict[challenge.challengeId];
            challenge.challengeName = challengeName;
            AWELogToolDebug(AWELogToolTagNone, @"fillChageInfo|challengeId=%@|challengeName=%@", challenge.challengeId, challenge.challengeName);
        }
    }
}

- (void)fillChallengeNameForFragmentInfo
{
    //填充每一段用了什么挑战name
    [self.repository.repoVideoInfo.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self fillChallengeInfo:obj];
    }];
}

- (void)fillChallengeInfo:(AWEVideoFragmentInfo *)info
{
    for (AWEVideoPublishChallengeInfo *challenge in info.challengeInfos) {
        NSAssert(challenge.challengeId.length > 0, @"name of challenge(challengeName=%@) is invalid!!", challenge.challengeName);
        if (challenge.challengeId.length > 0) {
            NSString *challengeName = self.repository.repoProp.cacheStickerChallengeNameDict[challenge.challengeId];
            challenge.challengeName = challengeName;
            AWELogToolDebug(AWELogToolTagNone, @"fillChageInfo|challengeId=%@|challengeName=%@", challenge.challengeId, challenge.challengeName);
        }
    }
}

- (NSUInteger)videoSegmentsCount
{
    return self.repository.repoVideoInfo.fragmentInfo.count;
}

#pragma mark - export video

- (void)stopRecordAndPossiblyExportVideo
{
    [self stopRecord];
    if (self.repository.repoReshoot.isReshoot) { // do not export video automatically for reshoot scenario
        return;
    }
    [self exportVideo];
}

- (void)stopRecordAndExportVideo
{
    [self stopRecord];
    [self exportVideo];
}

- (void)stopRecord
{
    if ([self.cameraService.cameraControl status] != IESMMCameraStatusRecording) {
        // IESCameraDurationBlock 回调中获取的时长在某些情况下会比使用 totalVideoDuration 获取的时长少 32ms 左右(1 帧)
        // 所以在stop的时候强制设置 currentDuration 为调用 currentDuration 函数获取的时长，保证时长正确

        // We do not have video data in karaoke audio mode, in which case we need a special calculator to compute total duration from audio assets. `self.totalDurationCalculator` is set in `RecordFlowKaraokePlugin`.
        if (self.totalDurationCalculator) {
            self.currentDuration = self.totalDurationCalculator(self.cameraService.recorder.videoData);
        } else {
            if (ACCConfigEnum(kConfigInt_record_to_edit_optimize_type, ACCRecordToEditOptimizeType) & ACCRecordToEditOptimizeTypePauseRecord) {
                // VE 已经在stop record结束后补一帧，消除误差，此处不需要再同步videoduration，videdata内部为同步队列，取totalVideoDuration会block ui
            } else {
                if (self.repository.repoAudioMode.isAudioMode) {
                    self.currentDuration = [self.cameraService.recorder.videoData totalBGAudioDuration];
                } else {
                    self.currentDuration = [self.cameraService.recorder.videoData totalVideoDuration];
                }
            }
        }
    } else {
        [AWEStudioMeasureManager sharedMeasureManager].pauseRecordTime = CACurrentMediaTime();
        [self.cameraService.recorder pauseVideoRecord];
    }

    self.flowState = ACCRecordFlowStateStop;
    [self.cameraService.recorder.videoData muteMicrophone:self.repository.repoVideoInfo.videoMuted];
}

- (void)exportVideo
{
    if (self.exporting) {
        return;
    }
    [self.cameraService.recorder exportWithVideo:self.cameraService.recorder.videoData];

    self.exporting = YES;
}

- (void)finishExportVideo:(BOOL)success {
    self.exporting = NO;
    
    if (!success) {
        [self restoreDuration];
        return;
    }
    
    [self fillChallengeNameForFragmentInfo];
    
    AVAsset *asset = self.repository.repoVideoInfo.video.videoAssets.firstObject;
    UIImage *firstFrameImage = nil;
    
    firstFrameImage = [self.cameraService.recorder getFirstRecordFrame];
    /*
     VESDK provides correct screenshot in the first frame of the recording
     进编辑耗时优化，首帧占位获取 VE在录制中的首帧截图。VE提供与写入文件相同配置的bufferImage
     */

    if (!firstFrameImage) {
        AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        NSError *imageGenError = nil;
        CGImageRef cgImage = [imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:NULL error:&imageGenError];
        if (cgImage && !imageGenError) {
            firstFrameImage = [[UIImage alloc] initWithCGImage:cgImage];
            CGImageRelease(cgImage);
        }
        if (imageGenError) {
            AWELogToolError(AWELogToolTagRecord, @"CopyCGImageAtTime failed. %@", imageGenError);
        }
    }
    
    self.repository.repoPublishConfig.firstFrameImage = firstFrameImage;
    [[self recordConfigService] configFinishPublishModel];
    
    [self.cameraService.cameraControl stopAndReleaseAudioCapture];
    
    self.flowState = ACCRecordFlowStateFinishExport;
}

- (void)executeExportCompletionWithVideoData:(HTSVideoData *_Nullable)newVideoData error:(NSError *_Nullable)error
{
    if (error) {
        AWELogToolError(AWELogToolTagRecord, @"executeExportCompletionWithVideoData error: %@", error);
    }
    
    ACCVEVideoData *videoData = [[ACCVEVideoData alloc] initWithVideoData:newVideoData draftFolder:self.repository.repoDraft.draftFolder];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.repository.repoVideoInfo updateVideoData:videoData];
        //录制中点击下一步，因为异步执行的原因，pauseRecordWithError msg 中信息的更新会晚于此处，导致后续的fps信息不准确，此处临时兼容此种情况
        AWEVideoFragmentInfo *fragmentInfo = self.repository.repoVideoInfo.fragmentInfo.lastObject;
        IESMMTrackerManager *mmTracker = [IESMMTrackerManager shareInstance];
        fragmentInfo.frameCount = mmTracker.recordCount;
        fragmentInfo.recordDuration = mmTracker.recordStopTime - mmTracker.recordStartTime;

        self.repository.repoUploadInfo.exportTime = [ACCMonitor() timeIntervalForKey:@"video_export_duration"];
        [ACCMonitor() cancelTimingForKey:@"video_export_duration"];

        [self finishExportVideo:!error];
        if (!error) {
            [videoData effect_cleanOperation];//草稿可能带特效
            [videoData effect_reCalculateEffectiveTimeRange];
        }
    });
}
 
#pragma mark - record flow

- (void)startRecord
{
    [ACCToolUIReactTrackService() eventBegin:kAWEUIEventClickRecord];
    [self startRecordWithDelayRecord:NO];
}

- (void)startRecordWithDelayRecord:(BOOL)isDelayRecord
{
    __block BOOL shouldStart = YES;
    [self.subscription performEventSelector:@selector(flowServcieShouldStartRecord:) realPerformer:^(id<ACCRecordFlowServiceSubscriber> subscriber) {
        if(![subscriber flowServcieShouldStartRecord:isDelayRecord]) {
            shouldStart = NO;
        }
    }];
    if (!shouldStart) {
        return;
    }
    self.isDelayRecord = isDelayRecord;
    HTSVideoSpeed speed = self.selectedSpeed;
    [self setupMaxLimitTime];
    // 判断是否超过阈值
    if (self.currentDuration < self.repository.repoContext.maxDuration) {
        if (self.repository.repoGame.gameType != ACCGameTypeNone ||
            self.repository.repoAudioMode.isAudioMode == YES) {
            speed = HTSVideoSpeedNormal;
        }

        [AWEStudioMeasureManager sharedMeasureManager].startRecordTime = CACurrentMediaTime();
        if (![ACCAudioAuthUtils shouldStopAudioCaptureWhenPause:self.repository]) {
            //pause的时候是开启音频的 无须再次开启
            [self realStartRecordWithSpeed:speed];
        } else {
            [self.cameraService.cameraControl startAudioCapture:2 completeBlock:^(BOOL ret, NSError * _Nonnull retError) {
                if(!ret || retError){
                    AWELogToolError(AWELogToolTagRecord, @"StartAudioCapture: fail, error: %@", retError);
                }
            }];

            // 不立刻开始录制会导致短时间内 pauseRecord 无效，UI 错乱
            [self realStartRecordWithSpeed:speed];
        }
    }
}

- (BOOL)p_handleTorchModeOnStartWithBlock:(void (^)(BOOL *))block
{
    BOOL shouldTurnOnTorch = NO;
    if (ACCConfigDouble(kConfigDouble_torch_record_wait_duration) >= 0.1) {
        ACCCameraTorchMode torchMode = self.cameraService.cameraControl.torchMode;
        NSNumber *brigthness = self.cameraService.cameraControl.brightness;
        float brightnessThreshold = ACCConfigDouble(ACCConfigDouble_torch_brightness_threshold);
        
        if (torchMode == ACCCameraTorchModeOn ||
            (torchMode == ACCCameraTorchModeAuto &&
             brigthness != nil &&
             [brigthness doubleValue] <= brightnessThreshold)) {
            shouldTurnOnTorch = YES;
        }
    }
    
    ACCBLOCK_INVOKE(block, &shouldTurnOnTorch);
    if (shouldTurnOnTorch) {
        [self.cameraService.cameraControl turnOnUniversalTorch];
    }
    return shouldTurnOnTorch;
}

- (void)realStartRecordWithSpeed:(HTSVideoSpeed)speed
{
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return;
    }
    
    BOOL turnOnTorch = [self p_handleTorchModeOnStartWithBlock:nil];
    if (turnOnTorch && !self.repository.repoDuet.isDuet) {
        double delay = ACCConfigDouble(kConfigDouble_torch_record_wait_duration);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{//避免闪光灯打开过程录入视频
            [self.cameraService.recorder startVideoRecordWithRate:speed];
        });
    } else {
        [self.cameraService.recorder startVideoRecordWithRate:speed];
    }
    
    self.flowState = ACCRecordFlowStateStart;
    [self addFragmentInfo];
    
    if (ACCConfigEnum(kConfigInt_backup_popup_style, ACCBackupEditsPopupStyle) != ACCBackupEditsPopupStyleDefault || ACCConfigBool(kConfigBool_save_draft_after_cancel_continue_edit)) {
        if (!self.repository.repoPublishConfig.coverImage && !self.repository.repoPublishConfig.backupCover && !self.repository.repoContext.isKaraokeAudio) {
            UIImage *image = [(UIView *)self.cameraService.cameraPreviewView acc_snapshotImageAfterScreenUpdates:NO];
            self.repository.repoPublishConfig.backupCover = image;
            self.repository.repoPublishConfig.backupCoverPath = [AWEDraftUtils generateBackupCoverPathFromTaskID:self.repository.repoDraft.taskID];
            NSData *coverData = UIImageJPEGRepresentation(image, 0.35);
            [coverData acc_writeToFile:self.repository.repoPublishConfig.backupCoverPath atomically:YES];
        }
    }
}

- (void)pauseRecordWithSuccess:(BOOL)success
{
    if (self.repository.repoDuet.isDuet) {
        self.lastCapturedVideoDuration = self.cameraService.recorder.videoData.totalVideoDuration;
    }
    //should append FragmentInfo when start record, not pauseRecord.
    if (!success) { // if error occured, video asset is not added, last fragment info should be removed
        if (!self.repository.repoReshoot.isReshoot) {
            [self removeLastVideoFragmentInfo];
        }
        [self restoreVideoDuration];
    } else {
        // Sometimes self.currentDuration == 0, if user pauses immediately after recording and the recorder only records one or two frame.
        // If we don't mark duration 0, markedTimes.count will not be equal to publishViewModel.repoVideoInfo.fragmentInfo.count.
        [self markDuration:self.currentDuration];
    }
}

- (void)picturePauseRecordWithSuccess:(BOOL)success
{
    if (self.repository.repoDuet.isDuet) {
        self.lastCapturedVideoDuration = self.cameraService.recorder.videoData.totalVideoDuration;
    }
    //should append FragmentInfo when start record, not pauseRecord.
    if (!success) { // if error occured, video asset is not added, last fragment info should be removed
        if (!self.repository.repoReshoot.isReshoot) {
            [self removeLastVideoFragmentInfo];
        }
        [self restoreVideoDuration];
    } else {
        
        //In quickStory mode, tapping the record button when under this AB will take a picture instead record a fragment and then will go to editor vc so there is no need to mark when self.currentDuration == 0
        if (self.currentDuration > 0) {
            [self markDuration:self.currentDuration];
        }
    }
}

- (void)pauseRecord {
    if (ACCRecordFlowStatePause == self.flowState) {
        return;
    }
    if (!self.isExporting) {
        [AWEStudioMeasureManager sharedMeasureManager].pauseRecordTime = CACurrentMediaTime();
        if (self.cameraService.cameraHasInit) {
            [self.cameraService.recorder pauseVideoRecord];
        }
    }
    self.flowState = ACCRecordFlowStatePause;
}

- (void)setFlowState:(ACCRecordFlowState)flowState {
    ACCRecordFlowState preState = _flowState;
    _flowState = flowState;
    [self.subscription performEventSelector:@selector(flowServiceStateDidChanged:preState:) realPerformer:^(id<ACCRecordFlowServiceSubscriber> subscriber) {
        [subscriber flowServiceStateDidChanged:flowState preState:preState];
    }];
}

#pragma mark - take picture

- (void)takePicture {
    if (self.cameraService.recorder.isRecording) {
        return;
    }

    if (self.cameraService.recorder.cameraMode != HTSCameraModePhoto) {
        return;
    }
    [ACCToolUIReactTrackService() eventBegin:kAWEUIEventClickTakePicture];
    [self.cameraService.effect acc_retainForbiddenMusicPropPlayCount];
    [self addPictureToVideoInfo];
    [self fillChallengeNameForPictureInfo];
    [self.subscription performEventSelector:@selector(flowServiceWillBeginTakePicture) realPerformer:^(id<ACCRecordFlowServiceSubscriber> subscriber) {
        [subscriber flowServiceWillBeginTakePicture];
    }];
    [self startCaptureStillImage];
    if (self.repository.repoContext.enableTakePictureDelayFrameOpt) {
        [self startCaptureEditPreviewImage];
    }
}

- (RACSignal *)captureStillImageSignal {
    return self.captureStillImageSubject;
}

- (void)cancelDelayFetchIfNeeded {
    [self.captureStillImageSubject sendCompleted];
}

- (void)startCaptureEditPreviewImage {
    @weakify(self);
    [self.cameraService.recorder captureSourcePhotoAsImageByUser:YES completionHandler:^(UIImage * _Nullable processedImage, NSError * _Nullable error) {
        @strongify(self);
        acc_dispatch_main_async_safe(^{
            if (error == nil) {
                self.repository.repoUploadInfo.toBeUploadedImage = processedImage.fixOrientation;
                self.repository.repoPublishConfig.firstFrameImage = self.repository.repoUploadInfo.toBeUploadedImage;
                self.repository.repoTrack.enterEditPageMethod = @"click_popup_button";
            }
            [self notifyDidTakePicker:processedImage error:error];
        });
    } afterProcess:YES];
}

- (void)startCaptureStillImage {
    @weakify(self);
    self.captureStillImageSubject = [RACSubject subject];
    if (@available(iOS 15, *)) {
        self.repository.repoPublishConfig.lensName
        = [self.cameraService.cameraFactory.camera activePrimaryConstituentDevice].deviceType;
    }
    [self.cameraService.recorder captureStillImageWithCompletion:^(UIImage * _Nonnull processedImage, NSError * _Nonnull error) {
        @strongify(self);
        if (self.repository.repoContext.enableTakePictureDelayFrameOpt) {
            if (error == nil) {
                self.repository.repoUploadInfo.toBeUploadedImage = processedImage.fixOrientation;
                [self.captureStillImageSubject sendNext:processedImage];
            } else {
                [self.captureStillImageSubject sendError:error];
            }
            self.repository.repoTrack.enterEditPageMethod = @"click_popup_button";
            [self.captureStillImageSubject sendCompleted];
            self.captureStillImageSubject = nil;
        } else {
            if (error == nil) {
                self.repository.repoUploadInfo.toBeUploadedImage = processedImage.fixOrientation;
                self.repository.repoTrack.enterEditPageMethod = @"click_popup_button";
            }
            [self notifyDidTakePicker:processedImage error:error];
        }
    }];
}

- (void)notifyDidTakePicker:(UIImage *)image error:(NSError *)error {
    acc_dispatch_main_async_safe(^{
        [self.subscription performEventSelector:@selector(flowServiceDidTakePicture:error:) realPerformer:^(id<ACCRecordFlowServiceSubscriber> subscriber) {
            [subscriber flowServiceDidTakePicture:image error:error];
        }];
    });
}

#pragma mark - live-photo

- (void)startLivePhotoRecordWithCompletion:(void (^)(void))completion
{
    BOOL turnOnTorch = [self p_handleTorchModeOnStartWithBlock:^(BOOL *turnOn) {
        if (self.cameraService.cameraControl.currentCameraPosition != AVCaptureDevicePositionBack) {
            *turnOn = NO;
        }
    }];
    
    [self.subscription performEventSelector:@selector(flowServiceWillBeginLivePhoto) realPerformer:^(id<ACCRecordFlowServiceSubscriber> subscriber) {
        [subscriber flowServiceWillBeginLivePhoto];
    }];

    if (turnOnTorch) {
        double delay = ACCConfigDouble(kConfigDouble_torch_record_wait_duration);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{//避免闪光灯打开过程录入视频
            [self realStartLivePhotoRecordWithCompletion:completion];
        });
    } else {
        [self realStartLivePhotoRecordWithCompletion:completion];
    }
}

- (void)realStartLivePhotoRecordWithCompletion:(void (^)(void))completion
{
    id<ACCRecorderLivePhotoProtocol> recorder = ACCGetProtocol(self.cameraService.recorder, ACCRecorderLivePhotoProtocol);
    [self.cameraService.effect acc_retainForbiddenMusicPropPlayCount];
    [self addPictureToVideoInfo];
    self.flowState = ACCRecordFlowStateStart;
    [self addFragmentInfo];
    
    self.repository.repoVideoInfo.canvasType = ACCVideoCanvasTypeLivePhoto;
    self.repository.repoContext.videoType = AWEVideoTypeLivePhoto;
    self.repository.repoSticker.assetCreationDate = [NSDate date];
    
    @weakify(self);
    let stepBlock = ^(id<ACCLivePhotoConfigProtocol>  _Nonnull config, NSInteger current, NSInteger total, NSInteger expectedTotal) {
        @strongify(self);
        [self.subscription performEventSelector:@selector(flowServiceDidStepLivePhotoWithConfig:index:total:expectedTotal:) realPerformer:^(id<ACCRecordFlowServiceSubscriber> subscriber) {
            [subscriber flowServiceDidStepLivePhotoWithConfig:config index:current total:total expectedTotal:expectedTotal];
        }];
    };
    
    let willCompleteBlock = ^(id<ACCLivePhotoConfigProtocol> config) {
        @strongify(self);
        [self.subscription performEventSelector:@selector(flowServiceWillCompleteLivePhotoWithConfig:) realPerformer:^(id<ACCRecordFlowServiceSubscriber> subscriber) {
            [subscriber flowServiceWillCompleteLivePhotoWithConfig:config];
        }];
    };
    
    NSInteger videoDuration = ACCConfigInt(kConfigInt_live_photo_video_duration);
    NSTimeInterval recordDuration = ACCConfigDouble(kConfigDouble_live_photo_record_duration);
    NSTimeInterval recordInterval = ACCConfigInt(kConfigInt_live_photo_frames_per_duration) / 1000.0;
    ACCLivePhotoType bizType = ACCConfigEnum(kConfigInt_live_photo_video_style, ACCLivePhotoType);

    [recorder startRecordLivePhotoWithConfigBlock:^(id<ACCLivePhotoConfigProtocol>  _Nonnull config) {
        @strongify(self);
        config.repository = self.repository;
        config.recordInterval = recordInterval;
        config.recordDuration = recordDuration;
        config.stepBlock = stepBlock;
        config.willCompleteBlock = willCompleteBlock;
        
    } progress:^(NSTimeInterval currentDuration) {
        @strongify(self);
        self.currentDuration = currentDuration;
        
    } completion:^(id<ACCLivePhotoResultProtocol>  _Nullable data, NSError * _Nullable error) {
        @strongify(self);
        ACCBLOCK_INVOKE(completion);
        if (error == nil) {
            ACCRepoLivePhotoModel *livePhotoModel = self.repository.repoLivePhoto;
            livePhotoModel.businessType = bizType;
            livePhotoModel.imagePathList = data.framePaths;
            livePhotoModel.durationPerFrame = (double)recordDuration / (double)data.framePaths.count;
            [livePhotoModel updateRepeatCountWithVideoPlayDuration:videoDuration];
            
            self.repository.repoVideoInfo.canvasContentRatio = data.contentRatio;
            self.repository.repoTrack.enterEditPageMethod = @"click_popup_button";
        }
        
        [self.subscription performEventSelector:@selector(flowServiceDidCompleteLivePhoto:error:) realPerformer:^(id<ACCRecordFlowServiceSubscriber> subscriber) {
            [subscriber flowServiceDidCompleteLivePhoto:data error:error];
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self stopLivePhotoRecordWithError:error];
        });
    }];
}

// 因录制过程实际为连拍而不是视频拍摄，故不能用本类的`-complete`方法
- (void)stopLivePhotoRecordWithError:(NSError *)error
{
    // 进度重置，否则切到拍摄模式会有问题
    self.currentDuration = 0;
    self.flowState = ACCRecordFlowStateStop;
    if (error == nil) {
        [self.cameraService.cameraControl stopVideoCapture];
        [self.cameraService.cameraControl stopAndReleaseAudioCapture];
        // 进编辑页
        self.hasStopCaptureWhenEnterEdit = YES;
        [[self recordConfigService] configFinishPublishModel];
        self.flowState = ACCRecordFlowStateFinishExport;
    }
    else {
        AWELogToolError(AWELogToolTagRecord, @"%s %@", __PRETTY_FUNCTION__, error);
        [self deleteAllSegments];
        // fix: 偶现失败后camera画面禁止不动
        [self.cameraService.cameraControl startVideoCaptureIfCheckAppStatus:YES];
    }
    // 进编辑页后（repo是copy传入的），需要做清理
    [self.repository.repoLivePhoto reset];
}

#pragma mark - completeRecord

- (BOOL)complete {
    BOOL canComplete = [self allowComplete];
    if (!canComplete) {
        return NO;
    }
    [self stopRecordAndExportVideo];
    self.hasStopCaptureWhenEnterEdit = YES;
    if (self.repository.repoDuet.isDuet && [self.repository.repoDuet.duetLayout isEqualToString:@"green_screen"]) {
        // duetLayoutGreenScreen: delay calling stopVideoCapture: and stopAndReleaseAudioCapture:
    } else {
        [self.cameraService.cameraControl stopVideoCapture];
        [self.cameraService.cameraControl stopAndReleaseAudioCapture];
    }
    [self.subscription performEventSelector:@selector(flowServiceDidCompleteRecord) realPerformer:^(id<ACCRecordFlowServiceSubscriber> subscriber) {
        [subscriber flowServiceDidCompleteRecord];
    }];
    return YES;
}

- (void)willEnterNextPageWithMode:(ACCRecordMode *)mode
{
    [self.subscription performEventSelector:@selector(flowServiceWillEnterNextPageWithMode:) realPerformer:^(id<ACCRecordFlowServiceSubscriber> subscriber) {
        [subscriber flowServiceWillEnterNextPageWithMode:mode];
    }];
}

- (void)didEnterNextPageWithMode:(ACCRecordMode *)mode
{
    [self.subscription performEventSelector:@selector(flowServiceDidEnterNextPageWithMode:) realPerformer:^(id<ACCRecordFlowServiceSubscriber> subscriber) {
        [subscriber flowServiceDidEnterNextPageWithMode:mode];
    }];
}

#pragma mark - pictureToVideo

- (void)addPictureToVideoInfo
{
    AWEPictureToVideoInfo *info = [[AWEPictureToVideoInfo alloc] init];
    info.cameraDirection = ACCDevicePositionStringify(self.cameraService.cameraControl.currentCameraPosition); 
    self.repository.repoRecordInfo.pictureToVideoInfo = info;
    [self.subscription performEventSelector:@selector(flowServiceDidAddPictureToVideo:) realPerformer:^(id<ACCRecordFlowServiceSubscriber> subscriber) {
        [subscriber flowServiceDidAddPictureToVideo:info];
    }];
}

#pragma mark - fragment

- (void)addFragmentInfo
{
    AWEVideoFragmentInfo *info = [[AWEVideoFragmentInfo alloc] initWithSourceType:AWEVideoFragmentSourceTypeRecord];
    if (self.repository.repoReshoot.isReshoot) {
        info.reshootTaskId = self.repository.repoDraft.taskID;
    }
    info.watermark = NO;
    info.speed = self.selectedSpeed;
    [self.repository.repoVideoInfo.fragmentInfo addObject:info];
    [self.subscription performEventSelector:@selector(flowServiceDidAddFragment:) realPerformer:^(id<ACCRecordFlowServiceSubscriber> subscriber) {
        [subscriber flowServiceDidAddFragment:info];
    }];
}

#pragma mark - PureMode
- (void)turnOnPureMode
{
    [self.cameraService.cameraControl setPureCameraMode:YES];
    [self.subscription performEventSelector:@selector(flowServiceTurnOnPureMode) realPerformer:^(id<ACCRecordFlowServiceSubscriber> subscriber) {
        [subscriber flowServiceTurnOnPureMode];
    }];
}

- (void)turenOffPureMode
{
    [self.cameraService.cameraControl setPureCameraMode:NO];
    [self.subscription performEventSelector:@selector(flowServiceTurnOffPureMode) realPerformer:^(id<ACCRecordFlowServiceSubscriber> subscriber) {
        [subscriber flowServiceTurnOffPureMode];
    }];
}

#pragma mark - subscription

- (ACCCameraSubscription *)subscription {
    if (!_subscription) {
        _subscription = [ACCCameraSubscription new];
    }
    return _subscription;
}

- (void)addSubscriber:(id<ACCRecordFlowServiceSubscriber>)subscriber {
    [self.subscription addSubscriber:subscriber];
}

- (void)removeSubscriber:(id<ACCRecordFlowServiceSubscriber>)subscriber
{
    [self.subscription removeSubscriber:subscriber];
}

@end
