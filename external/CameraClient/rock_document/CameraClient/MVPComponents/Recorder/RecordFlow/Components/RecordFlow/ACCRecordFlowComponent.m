//
//  ACCRecordFlowComponent.m
//  Pods
//
//  Created by songxiangwu on 2019/8/2.
//

#import "AWERepoStickerModel.h"
#import "AWERepoVideoInfoModel.h"
#import "AWERepoFlowControlModel.h"
#import "AWERepoContextModel.h"
#import "ACCRecordFlowComponent.h"
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCComponentManager.h>
#import <CreationKitInfra/ACCResponder.h>
#import "AWERecorderTipsAndBubbleManager.h"
#import "ACCRecordTrackHelper.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "ACCRecordFrameSamplingServiceProtocol.h"
#import "ACCAudioAuthUtils.h"
#import <CreationKitArch/ACCRecordTrackService.h>
#import "ACCRecorderEvent.h"
#import "ACCRecordPropService.h"
#import "ACCFeedbackProtocol.h"
#import "AWEMVTemplateModel.h"
#import <KVOController/NSObject+FBKVOController.h>
#import <CameraClient/ACCVideoInspectorProtocol.h>
#import <CameraClient/AWEXScreenAdaptManager.h>
#import "ACCRecordDraftHelper.h"
#import "ACCRecordFlowService.h"
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import "ACCPropViewModel.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitArch/ACCRepoGameModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/ACCRepoPublishConfigModel.h>
#import "AWEModernStickerViewController.h"
#import "ACCRecordFlowConfigProtocol.h"
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import "ACCFriendsServiceProtocol.h"
#import "ACCKdebugSignPost.h"
#import <CreationKitArch/ACCTimeTraceUtil.h>
#import "ACCVideoPublishProtocol.h"
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import "AWERepoTranscodingModel.h"
#import "ACCRecordMemoryControl.h"
#import "ACCRecorderMeteorModeServiceProtocol.h"
#import "ACCRecordMode+MeteorMode.h"
#import "ACCLightningCaptureButtonAnimationProtocol.h"
#import <CreationKitInfra/ACCRACWrapper.h>
#import "ACCVEVideoData.h"
#import <CameraClient/AWERecordFirstFrameTrackerNew.h>
#import <MediaPlayer/MPVolumeView.h>
#import <ByteDanceKit/UIDevice+BTDAdditions.h>
#import "ACCToolBarContainerAdapter.h"
#import "ACCToolBarAdapterUtils.h"
#import "ACCRepoKaraokeModelProtocol.h"
#import <CreationKitInfra/ACCDeviceAuth.h>
#import "ACCLivePhotoFramesRecorder.h"
#import <CameraClient/ACCRecognitionConfig.h>
#import "AWERepoPublishConfigModel.h"
#import <CreationKitArch/AWEDraftUtils.h>
#import "ACCRepoRearResourceModel.h"
#import <CreationKitArch/AWEStickerMusicManager.h>
#import "ACCRecorderLivePhotoProtocol.h"
#import <CreativeKit/ACCProtocolContainer.h>
#import "ACCVideoPublishAsImageAlbumProtocol.h"
#import <CameraClient/ACCRecordMode+LiteTheme.h>
#import <CameraClientModel/AWEVideoRecordButtonType.h>
#import <CameraClientModel/ACCVideoCanvasType.h>
#import <CreativeKit/ACCRouterService.h>
#import "ACCEditViewControllerInputData.h"
#import "AWERedPackThemeService.h"
#import "ACCUIReactTrackProtocol.h"
#import "ACCFlowerService.h"
#import "ACCScanService.h"
#import "ACCFlowerRedPacketHelperProtocol.h"
#import "ACCRepoRedPacketModel.h"
#import "ACCFlowerRedpacketPropTipView.h"
#import <CameraClient/ACCStudioLiteRedPacket.h>
#import <CreationKitInfra/ACCDeviceAuth.h>
#import <CameraClient/ACCRecordAuthService.h>
#import <Masonry/Masonry.h>
extern const NSTimeInterval kACCRecordAnimateDuration;
extern const NSTimeInterval kACCRecordAnimateDurationOnPropPanel;

static const CGFloat kRecordButtonWidth = 80;
static const CGFloat kRecordButtonHeight = kRecordButtonWidth;

// 如果第一次和第二次回调的时间间隔小于0.6秒钟，认为长按开始
static const CGFloat kTimeIntervalBetweenFirstAndSecondCallbacks = 0.6;
// 如果一次回调之后，间隔0.4秒钟没有继续收到回调，认为长按结束
static const CGFloat kTimeIntervalAfterLastCallback = 0.4;
// 开始录制0.3秒钟之内，如果有多次回调，只会响应第一次回调，后面回调忽略掉；因为有些系统点击一下可能回调了多次
static const NSTimeInterval kNoRespondTimeAfterFirstCallback = 0.3;

#define AVSystemController_SystemVolumeDidChangeNotification (([UIDevice currentDevice].systemVersion.floatValue >= 15.0) ? @"SystemVolumeDidChange" : @"AVSystemController_SystemVolumeDidChangeNotification")

typedef NS_ENUM(NSUInteger, RecordFlowProcessType) {
    RecordFlowProcessType_Init = 0,
    RecordFlowProcessType_VideoPhase,
    RecordFlowProcessType_PhotoPhase,
    RecordFlowProcessType_LivePhotoPhase,
    RecordFlowProcessType_Completed,
};

@interface ACCRecordFlowComponent()  <
ACCCameraLifeCircleEvent,
ACCRecorderEvent,
UIGestureRecognizerDelegate,
ACCPanelViewDelegate,
ACCRecordPropServiceSubscriber,
ACCRecorderViewContainerItemsHideShowObserver,
ACCRouterServiceSubscriber>

@property (nonatomic, strong) UIButton *recordButton;
@property (nonatomic, strong, readwrite) UIView<ACCCaptureButtonAnimationProtocol> *captureButtonAnimationView;
@property (nonatomic, strong) UIButton *recordShowTipButton; // 按下即toast提示录制时间已超过最大时间
@property (nonatomic, strong) ACCFlowerRedpacketPropTipView *flowerRedpacketPropTipView;
@property (nonatomic, assign) BOOL needShowFlowerRedpacketPropTipFlag;

@property (nonatomic, strong) UIView *mixRecordBubble;
@property (nonatomic, assign) CGPoint lastTouchPoint;
@property (nonatomic, assign) CGFloat oldZoomFactor;

@property (nonatomic, strong) UIView<ACCTextLoadingViewProtcol> *indicatorView;

@property (nonatomic, assign) BOOL hasAddedVolumeChangeObserver;
@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, assign) BOOL hasAddApplicationActiveNotification;
@property (nonatomic, assign) BOOL applicationActive;
@property (nonatomic, assign) BOOL isZooming;
@property (nonatomic, assign) BOOL shouldRemoveLastFragment;
@property (nonatomic, strong, readwrite) ACCGroupedPredicate<id, id> *shouldShowCaptureAnimationView;

@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCRecordTrackService> trackService;
@property (nonatomic, strong) id<ACCRecordFlowConfigProtocol> flowConfig;
@property (nonatomic, strong) id<ACCRecordPropService> propService;
@property (nonatomic, weak) id<ACCRecorderMeteorModeServiceProtocol> meteorModeService;
@property (nonatomic, strong) id<AWERedPackThemeService> themeService;
@property (nonatomic, strong) id<ACCRecordAuthService> authService;
@property (nonatomic, strong) id<ACCFlowerService> flowerService;
@property (nonatomic, strong) id<ACCScanService> scanService;

@property (nonatomic, weak) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCVideoConfigProtocol> videoConfig;
@property (nonatomic, assign) CGFloat cameraZoomFactor;

@property (nonatomic, strong) ACCRecordMemoryControl *memoryControl;

/** 音量键回调次数 */
@property (nonatomic, assign) NSInteger numberOfVolumeButtonCallbacks;
@property (nonatomic, strong) MPVolumeView *volumeView;
/** 原来的音量 */
@property (nonatomic, assign) float originalVolume;
/** 是否是第一次调整音量 */
@property (nonatomic, assign) BOOL isFirstTimeOfTappingVolumeButton;
/** 音量键触发开始录制时间 */
@property (nonatomic, assign) NSTimeInterval timeToStartRecordTriggeredByVolumeButton;
/** 是否屏蔽音量键拍摄功能 */
@property (nonatomic, assign) BOOL shouldBlockVolumnButtonTriggersTheShoot;
/** 动图拍摄中 */
@property (nonatomic, assign) BOOL isLivePhotoRecording;
/** 记录当前是否处于拍摄流程中*/
@property (nonatomic, assign) RecordFlowProcessType recordFlowProcess;
@end

@implementation ACCRecordFlowComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, trackService, ACCRecordTrackService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, flowConfig, ACCRecordFlowConfigProtocol)
IESAutoInject(self.serviceProvider, propService, ACCRecordPropService)
IESAutoInject(ACCBaseServiceProvider() , videoConfig, ACCVideoConfigProtocol)
IESOptionalInject(self.serviceProvider, meteorModeService, ACCRecorderMeteorModeServiceProtocol)
IESAutoInject(self.serviceProvider, themeService, AWERedPackThemeService)
IESAutoInject(self.serviceProvider, authService, ACCRecordAuthService);
IESAutoInject(self.serviceProvider, scanService, ACCScanService)
IESAutoInject(self.serviceProvider, flowerService, ACCFlowerService)


#pragma mark - ACCComponentProtocol

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // 移除自定义 MPVolumeView
    if (_volumeView) {
        [_volumeView removeFromSuperview];
        _volumeView = nil;
    }
}

- (void)close
{
    [self.controller close];
}

- (void)loadComponentView
{
    [self setupUI];
    [self forceLoadComponentIfNeeded];
}

- (void)componentDidMount
{
    [self.trackService configTrackDidLoad];
    self.applicationActive = YES;
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    
    [self addVolumeChangeObserver];
    [self addRecordChangeObserver];
    [self addApplicationActiveNotification];
    [self.viewContainer.panelViewController registerObserver:self];
    [self bindViewModel];

    @weakify(self);
    
    self.memoryControl = [[ACCRecordMemoryControl alloc] init];
    self.memoryControl.recordController = self.controller;
    self.memoryControl.cameraPureModeBlock = ^(BOOL pure) {
        @strongify(self);
        if (pure) {
            [self.flowService turnOnPureMode];
        } else {
            [self.flowService turenOffPureMode];
        }
    };
    [self.controller.componentManager registerMountCompletion:^{
        @strongify(self);
        if (self.repository.repoVideoInfo.canvasType != ACCVideoCanvasTypeNone) {
            [self.repository.repoVideoInfo.video removeAllVideoAsset];
        }
        [self.flowService restoreVideoDuration];
        [self.captureButtonAnimationView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.viewContainer.interactionView);
        }];

        [self.captureAnimation switchToMode:[self.switchModeService currentRecordMode] force:YES];
        @weakify(self)
        self.captureAnimation.trackRecordVideoEventBlock = ^ {
            @strongify(self);
            [self.trackService trackRecordVideoEventWithCameraService:self.cameraService];
        };
        if (self.repository.repoGame.gameType != ACCGameTypeNone) {
            self.recordButton.hidden = YES;
            self.captureButtonAnimationView.hidden = YES;
            self.recordShowTipButton.hidden = YES;
        }

        [self updateRecordButtonWithCurrentDuration:self.flowService.currentDuration];
        [self updateStandardDurationIndicatorDisplay];
    }];
    
    self.needShowFlowerRedpacketPropTipFlag = [self p_needShowFlowerRedpacketPropTip];
    if (self.needShowFlowerRedpacketPropTipFlag &&
        ![ACCDeviceAuth hasCameraAndMicroPhoneAuth]) {
        @weakify(self)
        [[self.authService.passCheckAuthSignal takeUntil:self.rac_willDeallocSignal].deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
            @strongify(self);
            [self p_showFlowerRedpacketPropTipIfNeed];
        }];
    }
    
    self.isFirstAppear = YES;
}

- (void)componentWillUnmount
{
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    if (self.repository.repoTrack.referExtra) {
        [attributes addEntriesFromDictionary:self.repository.repoTrack.referExtra];
    }
    attributes[@"publish_cnt"] = @([ACCVideoPublish() publishTaskCount]);
    [ACCTracker() trackEvent:@"cancel_shoot"
                        label:@"shoot_page"
                        value:nil
                        extra:nil
                  attributes:self.repository.repoTrack.referExtra];
}

- (void)componentDidUnmount
{
    [ACCCache() setString:nil forKey:kACCMusicRecommendPropIDKey];
    [self removeApplicationActiveNotification];
}

- (void)componentDidAppear
{
    // 这部分逻辑不能移到flowerComponent里，因为这里可能是演练期间而不是春节期间，得整个通用的component
    [self p_showFlowerRedpacketPropTipIfNeed];
    
    self.recordFlowProcess = RecordFlowProcessType_Init;

    if (self.isFirstAppear && self.repository.repoFlowControl.autoShoot && self.switchModeService.currentRecordMode.isVideo) {
        if (self.cameraService.cameraHasInit) {
            [self startRecord:self.recordButton delay:YES];
        }
    }
    AWELogToolInfo(AWELogToolTagRecord, @"recordflow didappear isFirstAppear:%@, autoShoot:%@, isvideoModel:%@, camera:%@", @(self.isFirstAppear), @(self.repository.repoFlowControl.autoShoot), @(self.switchModeService.currentRecordMode.isVideo), self.cameraService.cameraHasInit ? @"YES" : @"NO");
    self.isFirstAppear = NO;
    self.repository.repoVideoInfo.canvasType = ACCVideoCanvasTypeNone;
    [self openVolumnButtonTriggersTheShoot];

    if ([ACCToolBarAdapterUtils useToolBarFoldStyle]) {
        ACCToolBarContainerAdapter *adapter = (ACCToolBarContainerAdapter *)self.viewContainer.barItemContainer;
        [adapter resetUpBarContentView];
    }
}

- (void)componentDidDisappear
{
    [self stopRecordButtonAnimation];
    [self closeVolumnButtonTriggersTheShoot];
}

- (void)forceLoadComponentIfNeeded {
    NSInteger delay = ACCConfigInt(kConfigInt_component_performance_architecture_forceload_delay);
    if (delay <= 0 || ![self.controller enableFirstRenderOptimize]) {
        return;
    }
    @weakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        if (!self) {
            return;
        }
        if (!self.isMounted && [self.controller.componentManager respondsToSelector:@selector(forceLoadComponentsWhenInteracting)]) {
            [AWERecordFirstFrameTrackerNew sharedTracker].forceLoadComponent = YES;
            [self.controller.componentManager forceLoadComponentsWhenInteracting];
        }
    });
}

- (void)addApplicationActiveNotification
{
    if (self.hasAddApplicationActiveNotification) {
        return;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    self.hasAddApplicationActiveNotification = YES;
}

- (void)removeApplicationActiveNotification
{
    if (!self.hasAddApplicationActiveNotification) {
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    self.hasAddApplicationActiveNotification = NO;
}

#pragma mark 添加 VolumeDidChange 监听
- (void)addVolumeChangeObserver
{
    if (self.hasAddedVolumeChangeObserver) {
        return;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeClicked:) name:AVSystemController_SystemVolumeDidChangeNotification object:nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    self.hasAddedVolumeChangeObserver = YES;
}

#pragma mark 移除 VolumeDidChange 监听
- (void)removeVolumeChangeObserver
{
    if (self.hasAddedVolumeChangeObserver) {
        self.hasAddedVolumeChangeObserver = NO;
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVSystemController_SystemVolumeDidChangeNotification object:nil];
    }
}

- (void)addRecordChangeObserver
{

    @weakify(self);
    self.flowService.mixSubtype = self.captureAnimation.mixSubtype;
    [self.KVOController
     observe:self.captureAnimation
     keyPath:NSStringFromSelector(@selector(mixSubtype))
     options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
     block:^(typeof(self) observer, typeof(self.captureAnimation) object, NSDictionary<NSString *,id> * changes) {
        @strongify(self);
        NSNumber *mixSubtype = ACCDynamicCast(changes[NSKeyValueChangeNewKey], NSNumber);
        self.flowService.mixSubtype = (AWERecordModeMixSubtype)mixSubtype.integerValue;
    }];
}

- (void)componentWillLayoutSubviews
{
    AWECaptureButtonAnimationView *captureButtonView = self.captureButtonAnimationView;
    [captureButtonView updateAnimatedRecordButtonCenter:self.recordButton.center];
}

- (void)setupUI
{
    [self.viewContainer.interactionView addSubview:self.recordButton];
    [self.viewContainer.interactionView addSubview:self.recordShowTipButton];
    [self.viewContainer.interactionView addSubview:self.captureButtonAnimationView];
    if ([self.flowConfig enableLightningStyleRecordButton]) {
        [self.viewContainer.interactionView bringSubviewToFront:self.recordShowTipButton];
    }
    [self.viewContainer.layoutManager addSubview:self.recordShowTipButton viewType:ACCViewTypeShowTipButton];
    if ([self.controller enableFirstRenderOptimize]) {
        [self.captureAnimation switchToMode:[self.switchModeService currentRecordMode] force:YES];
    }
}

#pragma mark - ACCPanelViewDelegate
- (void)panelViewController:(id<ACCPanelViewController>)panelViewController willShowPanelView:(id<ACCPanelViewProtocol>)panelView
{
    [self closeVolumnButtonTriggersTheShoot];
}

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController didDismissPanelView:(id<ACCPanelViewProtocol>)panelView {
    [self openVolumnButtonTriggersTheShoot];
    
    if (panelView.identifier == ACCRecordStickerPanelContext) {
        self.recordButton.hidden = NO;
        self.recordButton.alpha = 1.0f;
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - ACCRecordFlowServiceSubscriber

- (void)flowServiceStateDidChanged:(ACCRecordFlowState)state preState:(ACCRecordFlowState)preState
{
    if (ACCRecordFlowStateStart == state) {
        self.recordFlowProcess = RecordFlowProcessType_VideoPhase;
        
        if (self.repository.repoVideoInfo.canvasType != ACCVideoCanvasTypeNone) {
            self.repository.repoVideoInfo.canvasType = ACCVideoCanvasTypeNone;
            [self.repository.repoVideoInfo.video removeAllVideoAsset];
        }
    } else if (ACCRecordFlowStateStop == state) {
        [self p_recordProcessCompleted];
        [self stopRecordButtonAnimation];
        if ([ACCAudioAuthUtils shouldStopAudioCaptureWhenPause:self.repository]) {
            [self.cameraService.cameraControl stopAudioCapture];
        }
        
        // 清空计数
        [self clearVolumeButtonRelatedFlag];
    } else if (ACCRecordFlowStatePause == state) {
        [self p_recordProcessCompleted];
        [self.captureAnimation endCountdownModeIfNeed];
        if ([ACCAudioAuthUtils shouldStopAudioCaptureWhenPause:self.repository]) {
            [self.cameraService.cameraControl stopAudioCapture];
        }
        if (self.flowService.isDelayRecord && self.cameraService.cameraControl.status != IESMMCameraStatusIdle) {
            [self pauseRecord];
        }
        
        // 清空计数
        [self clearVolumeButtonRelatedFlag];
    } else if (ACCRecordFlowStateFinishExport == state) {
        [self p_recordProcessCompleted];
        if (self.switchModeService.currentRecordMode.modeId == ACCRecordModeAudio) {
            //audio mode handle videoData by async
            [self.indicatorView dismissWithAnimated:YES];
        } else {
            [self.flowService willEnterNextPageWithMode:self.switchModeService.currentRecordMode];
            [self.controller controllerTaskFinished];
            [self.indicatorView dismissWithAnimated:YES];
            [self.flowService didEnterNextPageWithMode:self.switchModeService.currentRecordMode];
        }
    }
}

- (BOOL)flowServcieShouldStartRecord:(BOOL)isDelayRecord
{
    NSDictionary *data = @{@"service"   : @"record_error",
                           @"action"    : @"trigger_start_record",
                           @"task"      : self.repository.repoDraft.taskID?:@"",};
    [ACCMonitor() trackData:data logTypeStr:@"aweme_movie_publish_log"];
    [[AWERecorderTipsAndBubbleManager shareInstance] removePropHint];
    if (self.cameraService.cameraControl.status != IESMMCameraStatusIdle) {
        return NO;
    }
    if (isDelayRecord) {
        [self.recordButton acc_fadeShow];
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive && self.applicationActive) {
            [self.captureAnimation startCountdownMode];
            [self.trackService trackRecordVideoEventWithCameraService:self.cameraService];
            return YES;
        } else {
            [self.captureAnimation endCountdownModeIfNeed];
            return NO;
        }
    }
    return YES;
}

- (void)flowServiceDidUpdateDuration:(CGFloat)duration
{
    double progress = ((NSTimeInterval)self.flowService.currentDuration) / self.repository.repoContext.maxDuration;
    if (progress >= 1) {
        [self stopRecordButtonAnimationWithIgnoreProgress:YES];
    } else if (self.propService.prop.isMultiSegProp && duration > [self.propService.prop.clipsArray acc_objectAtIndex:(self.flowService.videoSegmentsCount - 1)].end){
        // if recording, current seg count will be at least 1, so there need to minus 1 to get the corresponding clip end time.
        [self stopRecordButtonAnimation];
        [self.flowService pauseRecord];
    }
    
    [self updateRecordButtonWithCurrentDuration:duration];
    [self updateProgressAndMarksDisplay];
}

- (void)flowServiceDidMarkDuration:(CGFloat)duration
{
    if (self.repository.repoGame.gameType == ACCGameTypeNone) {
        [self.viewContainer showItems:YES animated:YES];
    }
}

- (void)flowServiceDidRemoveLastSegment:(BOOL)isReactHasMerge
{
    [self.viewContainer showItems:YES animated:YES];
    // 清除录制抽帧结果
    //TODO: - ⚠️数据依赖等待repo重构后聚合到对应的抽帧handler中。
    let samplingService = IESAutoInline(self.serviceProvider, ACCRecordFrameSamplingServiceProtocol);
    NSAssert([samplingService respondsToSelector:@selector(removeAllFrames)], @"-[%@ removeAllFrames] not found", samplingService);
    [samplingService removeAllFrames];
}

- (void)flowServiceDidRemoveAllSegment
{
    if (!self.viewContainer.isShowingPanel) {
        [self.viewContainer showItems:YES animated:YES];
    }
    // 清除录制抽帧结果
    //TODO: - ⚠️数据依赖等待repo重构后聚合到对应的抽帧handler中。
    let samplingService = IESAutoInline(self.serviceProvider, ACCRecordFrameSamplingServiceProtocol);
    NSAssert([samplingService respondsToSelector:@selector(removeAllFrames)], @"-[%@ removeAllFrames] not found", samplingService);
    [samplingService removeAllFrames];
}

- (void)flowServiceWillBeginTakePicture
{
    self.recordButton.enabled = NO;
    self.recordFlowProcess = RecordFlowProcessType_PhotoPhase;
}

- (void)flowServiceDidTakePicture:(UIImage *)image error:(NSError *)error
{
    if (error && !self.repository.repoContext.enableTakePictureDelayFrameOpt) {
        acc_dispatch_main_async_safe(^{
            self.recordButton.enabled = YES;
            self.recordButton.alpha = 1.0f;
            [self p_recordProcessCompleted];
            [ACCToast() showError:ACCLocalizedCurrentString(@"com_mig_couldnt_shoot_video_try_again_later")];
        });
        
        AWELogToolError2(@"take_picture", AWELogToolTagRecord, @"captureStillImageWithCompletion failed: %@", error);
    } else {
        if (ACCConfigBool(kConfigBool_enable_lightning_pic_to_video_optimize)) {
            self.repository.repoContext.videoType = AWEVideoTypeQuickStoryPicture;
            self.repository.repoContext.videoRecordType = AWEVideoRecordTypeNormal;
            if ([IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) singlePhotoOptimizationABTesting].isCanvasEnabled) {
                self.repository.repoVideoInfo.canvasType = ACCVideoCanvasTypeSinglePhoto;
                // 支持未编辑的画布单图发布为图集的话需要先将原始图存到草稿和图集信息中
                // 异步存储，不影响进入到编辑页的首帧体验
                if (image && ACCConfigBool(kConfigBool_enable_canvas_photo_publish_optimize)) {
                    [ACCVideoPublishAsImageAlbumHelper() saveOriginalImageWithImage:image to:self.repository completion:nil];
                }
                // DA要求普通canvas都报为CanvasPhoto
                if (self.repository.repoPublishConfig.categoryDA ==  ACCFeedTypeExtraCategoryDaUnknown) {
                    self.repository.repoPublishConfig.categoryDA =  ACCFeedTypeExtraCategoryDaSinglePhoto;
                }
            }
            self.repository.repoUploadInfo.originUploadPhotoCount = @1;
        } else {
            self.repository.repoContext.videoType = AWEVideoTypePicture;
        }
        self.repository.repoSticker.assetCreationDate = [NSDate date];
        // DA 要求快拍的拍照，不上报 record_video
        if (self.repository.repoFlowControl.videoRecordButtonType != AWEVideoRecordButtonTypeStory) {
            [self.trackService trackRecordVideoEventWithCameraService:self.cameraService];
        }
        
        let samplingService = IESAutoInline(self.serviceProvider, ACCRecordFrameSamplingServiceProtocol);
        [samplingService saveBgPhotosForTakePicture];
        
        void(^toNextPageBlock)(void) = ^(void) {
            self.recordButton.enabled = YES;
            self.recordButton.alpha = 1.0f;
            if ([self.flowConfig needJumpDirectlyAfterTakePicture]) {
                self.repository.repoPublishConfig.firstFrameImage = image;
                [self.flowService willEnterNextPageWithMode:self.switchModeService.currentRecordMode];
                [self.controller controllerTaskFinished];
                [self.flowService didEnterNextPageWithMode:self.switchModeService.currentRecordMode];
            }
            [self p_recordProcessCompleted];
        };
        if (ACCConfigBool(kConfigBool_enable_lightning_pic_to_video_optimize)) {
            toNextPageBlock();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                toNextPageBlock();
            });
        }
    }
}

- (void)flowServiceWillBeginLivePhoto
{
    self.recordButton.enabled = NO;
    self.isLivePhotoRecording = YES;
    self.recordFlowProcess = RecordFlowProcessType_LivePhotoPhase;
    [IESAutoInline(self.serviceProvider, ACCRecordConfigService) configPublishModelMaxDurationWithAsset:self.repository.repoMusic.musicAsset showRecordLengthTipBlock:NO isFirstEmbed:NO];
    
    [self.trackService trackRecordVideoEventWithCameraService:self.cameraService];
}

- (void)flowServiceWillCompleteLivePhotoWithConfig:(id<ACCLivePhotoConfigProtocol>)config
{
    if ([self.captureButtonAnimationView respondsToSelector:@selector(startLoadingAnimation)]) {
        [self.captureButtonAnimationView startLoadingAnimation];
    }
}

- (void)flowServiceDidCompleteLivePhoto:(id<ACCLivePhotoResultProtocol>)data error:(NSError *)error
{
    self.recordButton.enabled = YES;
    self.recordButton.alpha = 1.0f;
    [self p_recordProcessCompleted];
    [IESAutoInline(self.serviceProvider, ACCRecordConfigService) configPublishModelMaxDurationWithAsset:self.repository.repoMusic.musicAsset showRecordLengthTipBlock:NO isFirstEmbed:NO];
    
    self.isLivePhotoRecording = NO;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self.captureButtonAnimationView respondsToSelector:@selector(stopLoadingAnimation)]) {
            [self.captureButtonAnimationView stopLoadingAnimation];
        }
        [IESAutoInline(self.serviceProvider, ACCRecordConfigService) configPublishModelMaxDurationWithAsset:self.repository.repoMusic.musicAsset showRecordLengthTipBlock:NO isFirstEmbed:NO];
    });
    let samplingService = IESAutoInline(self.serviceProvider, ACCRecordFrameSamplingServiceProtocol);
    [samplingService stop];

    if (error) {
        [ACCToast() showError:ACCLocalizedCurrentString(@"com_mig_couldnt_shoot_video_try_again_later")];
        AWELogToolError2(@"live_photo", AWELogToolTagRecord, @"flowServiceDidCompleteLivePhoto error: %@", error);
    }
    else {
        self.repository.repoContext.feedType = ACCFeedTypePhotoToVideo; // 按照Da要求复用单图的
        // 首帧预渲染优化
        NSString *firstFramePath = data.framePaths.firstObject;
        if (firstFramePath != nil) {
            NSString *fullPath = [AWEDraftUtils generateDraftFolderFromTaskId:self.repository.repoDraft.taskID];
            fullPath = [fullPath stringByAppendingPathComponent:firstFramePath];
            UIImage *image = [[UIImage alloc] initWithContentsOfFile:fullPath];
            self.repository.repoPublishConfig.firstFrameImage = image;
        }
    }
}

- (void)flowServiceDidStepLivePhotoWithConfig:(id<ACCLivePhotoConfigProtocol>)config index:(NSInteger)index total:(NSInteger)total expectedTotal:(NSInteger)expectedTotal
{
    // 当前LivePhoto的抽帧只关心首尾各1帧
    if (index == 0) {
        let samplingService = IESAutoInline(self.serviceProvider, ACCRecordFrameSamplingServiceProtocol);
        // 设置一个超出录制时长的时间，避免抽取中间帧
        NSTimeInterval const DoNotReachTimeInterval = config.recordDuration + 60.0;
        [samplingService startWithCameraService:self.cameraService timeInterval:DoNotReachTimeInterval];
    }
    else if (index == total - 1) {
        // 抽最后一帧
        let samplingService = IESAutoInline(self.serviceProvider, ACCRecordFrameSamplingServiceProtocol);
        [samplingService sampleFrame];
    }
}

- (void)bindViewModel
{
    @weakify(self);
    [[[RACObserve(self.viewContainer, propPanelType)
       skip:1] deliverOnMainThread] subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        BOOL shouldHidden = self.viewContainer.isShowingAnyPanel;
        [self showRecordButtonIfShould:!shouldHidden animated:NO];
        self.captureButtonAnimationView.supportGestureWhenHidden = (self.repository.repoGame.gameType == ACCGameTypeNone) && [x boolValue];
    }];
    
    [self.viewContainer addObserver:self];

    [RACObserve(self.cameraService.recorder, recorderState).deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        ACCCameraRecorderState state = x.integerValue;
        switch (state) {
            case ACCCameraRecorderStateNormal:
                if (self.viewContainer.isShowingPanel) {
                    [self showRecordButtonIfShould:NO animated:NO];
                }
                break;
            case ACCCameraRecorderStatePausing: {
                if (self.repository.repoGame.gameType == ACCGameTypeNone) {
                    [self showRecordButtonIfShould:YES animated:YES];
                }
                break;
            }
            case ACCCameraRecorderStateRecording:
                break;
        }
    }];
    
    if (@available(iOS 13.0, *)) {
        // `allowHapticsAndSystemSoundsDuringRecording` control will be implemented by VE in the near future.
        RACSignal *didStartRecording = [[[RACObserve(self.flowService, flowState) deliverOnMainThread] filter:^BOOL(NSNumber * _Nullable value) {
            return value.integerValue == ACCRecordFlowStateStart;
        }] mapReplace:@(NO)];
        RACSignal *didStopRecording = [[[RACObserve(self.flowService, flowState) deliverOnMainThread] filter:^BOOL(NSNumber * _Nullable value) {
            return value.integerValue == ACCRecordFlowStatePause || value.integerValue == ACCRecordFlowStateStop;
        }] mapReplace:@(YES)];
        RACSignal *didAppear = [[self rac_signalForSelector:@selector(componentDidAppear)] mapReplace:@(YES)];
        RACSignal *didDisappear = [[self rac_signalForSelector:@selector(componentDidDisappear)] mapReplace:@(NO)];
        
        [[RACSignal merge:@[
            didStartRecording,
            didStopRecording,
            didAppear,
            didDisappear,
        ]] subscribeNext:^(NSNumber * _Nullable allowHaptics) {
            ACCOptimizePerformanceType type = ACCConfigEnum(kConfigInt_component_performance_architecture_optimization_type, ACCOptimizePerformanceType);
            BOOL enableComponentOptimize = ACCOptimizePerformanceTypeContains(type, ACCOptimizePerformanceTypeRecorderWithForceLoad);
            if (enableComponentOptimize) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    if ([[AVAudioSession sharedInstance] allowHapticsAndSystemSoundsDuringRecording] != allowHaptics.boolValue) {
                        NSError *error = nil;
                        [[AVAudioSession sharedInstance] setAllowHapticsAndSystemSoundsDuringRecording:allowHaptics.boolValue error:&error];
                        AWELogToolError(AWELogToolTagRecord, @"-[AVAudioSession setAllowHapticsAndSystemSoundsDuringRecording] meet error %@", error);
                    }
                });
            }else {
                if ([[AVAudioSession sharedInstance] allowHapticsAndSystemSoundsDuringRecording] != allowHaptics.boolValue) {
                    NSError *error = nil;
                    [[AVAudioSession sharedInstance] setAllowHapticsAndSystemSoundsDuringRecording:allowHaptics.boolValue error:&error];
                    AWELogToolError(AWELogToolTagRecord, @"-[AVAudioSession setAllowHapticsAndSystemSoundsDuringRecording] meet error %@", error);
                }
            }
        }];
    }
    
    [[self propViewModel].didApplyStickerSignal.deliverOnMainThread subscribeNext:^(ACCDidApplyEffectPack _Nullable x) {
        @strongify(self);
        IESEffectModel *prop = x.first;
        BOOL success = x.second.boolValue;
        [self propServiceDidApplyProp:prop success:success];
        
        if ([self blockVolumnButtonTriggersTheShootFlag]) {
            BOOL hasForceBindMusic = [AWEStickerMusicManager musicIsForceBindStickerWithExtra:prop.extra];
            BOOL disabled = (hasForceBindMusic && !ACC_isEmptyString(prop.musicIDs.firstObject)) || self.repository.repoMusic.music;
            if (disabled) {
                [self blockVolumnButtonTriggersTheShoot];
            } else {
                self.shouldBlockVolumnButtonTriggersTheShoot = NO;
                [self openVolumnButtonTriggersTheShoot];
            }
        }
    }];

    [self.meteorModeService.didChangeMeteorModeSignal.deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        self.captureAnimation.recordMode.isMeteorMode = x.boolValue;
        [self.captureAnimation switchToMode:self.captureAnimation.recordMode];
    }];
    
    if ([self blockVolumnButtonTriggersTheShootFlag]) {
        // 录制按钮隐藏，关闭音量键拍摄功能；录制按钮显示，开启音量键拍摄功能
        [[[RACObserve(self.recordButton, hidden) distinctUntilChanged] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
            @strongify(self);
            if (self.recordButton.hidden && !self.flowerService.inFlowerPropMode) {
                [self hideSystemVolumeView:NO];
            } else {
                [self openVolumnButtonTriggersTheShoot];
            }
        }];
        
        // 有配乐关闭音量键拍摄功能；无配乐开启音量键拍摄功能
        [[[RACObserve(self.repository.repoMusic, music) distinctUntilChanged] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
            @strongify(self);
            if (self.repository.repoMusic.music) {
                [self blockVolumnButtonTriggersTheShoot];
            } else {
                self.shouldBlockVolumnButtonTriggersTheShoot = NO;
                [self openVolumnButtonTriggersTheShoot];
            }
        }];
        
        if ([self needDownloadMusicOrProp] ||
            [self hasSetMusic]) {
            [self blockVolumnButtonTriggersTheShoot];
        }
    }
}

#pragma mark 屏蔽音量键拍摄功能
- (void)blockVolumnButtonTriggersTheShoot
{
    [self hideSystemVolumeView:NO];
    self.shouldBlockVolumnButtonTriggersTheShoot = YES;
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    self.applicationActive = NO;
    if ([ACCResponder topViewController] == self.controller.root) {
        // multi seg prop will delete the processing segment, if the app resign active
        // due to pause record is an async process, so move the removeLastSeg to the callback
        if (self.propService.prop.isMultiSegProp && self.flowService.videoSegmentsCount > 0 && [self.cameraService.cameraControl status] == HTSCameraStatusRecording) {
            self.shouldRemoveLastFragment = YES;
        }
        
        [self stopRecordButtonAnimation];
        [self.flowService pauseRecord];
    }
    
    // 关闭音量键拍摄功能
    [self closeVolumnButtonTriggersTheShoot];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    self.applicationActive = YES;
    // trigger ui showing
    self.cameraService.recorder.recorderState = ACCCameraRecorderStatePausing;
    // 打开音量键拍摄功能
    [self openVolumnButtonTriggersTheShoot];
}

- (MPVolumeView *)volumeView
{
    if (!_volumeView) {
        _volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(-1000, -1000, 10, 10)];
        [self.viewContainer.interactionView addSubview:_volumeView];
    }
    return _volumeView;
}

- (UISlider *)volumeSider
{
    UISlider *volumeSlider = nil;
    for (UIView *view in _volumeView.subviews) {
         if ([view.class.description isEqualToString:@"MPVolumeSlider"]) {
             volumeSlider = (UISlider *)view;
             break;
         }
    }
    return volumeSlider;
}

#pragma mark 设置音量
- (void)setVolume:(CGFloat)volume
{
    if (_volumeView) {
        UISlider *slider = [self volumeSider];
        AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s, setVolumeRecord ing, outputVolume:%f, slider.value:%f, volumeToSet:%f.", __func__, [[AVAudioSession sharedInstance] outputVolume], slider.value, volume);
        slider.value = volume;
    }
}

#pragma mark 隐藏/显示系统音量键 UI; hidden=YES，隐藏, hidden=NO，显示
- (void)hideSystemVolumeView:(BOOL)hidden
{
    if (!IS_OS_9_OR_LATER) {
        return;
    }
    
    if (hidden) {
        self.volumeView.hidden = !hidden;
    } else {
        _volumeView.hidden = !hidden;
    }
}

#pragma mark YES：点击和长按都是录制；NO：点击拍照，长按录制
- (BOOL)isTapAndHoldToRecordCase
{
    if ([ACCStudioLiteRedPacket() isLiteRedPacketRecord:self.repository]) {
        return YES; //极速版红包路径不能点击拍照
    }
    if (ACCConfigBool(kConfigBool_tools_shoot_advanced_setting_panel)) {
        return !self.enableTapToTakePhoto;
    }
    return ACCConfigBool(kConfigBool_story_tab_tap_hold_record);
}

#pragma mark 是否是分段拍
- (BOOL)isModeMix
{
    NSInteger modeId = self.switchModeService.currentRecordMode.modeId;
    return (ACCRecordModeMixHoldTapRecord == modeId || ACCRecordModeMixHoldTap15SecondsRecord == modeId || ACCRecordModeMixHoldTapLongVideoRecord == modeId || ACCRecordModeMixHoldTap60SecondsRecord == modeId || ACCRecordModeMixHoldTap3MinutesRecord == modeId);
}

#pragma mark 是否是快拍-照片
- (BOOL)isModeTakePicture
{
    return ACCRecordModeTakePicture == self.switchModeService.currentRecordMode.modeId || self.flowerService.isShowingPhotoProp;
}

#pragma mark 是否是快拍-动图
- (BOOL)isLivePhoto
{
    return ACCRecordModeLivePhoto == self.switchModeService.currentRecordMode.modeId;
}

#pragma mark 是否是快拍-视频
- (BOOL)isModeStory
{
    return self.switchModeService.currentRecordMode.isStoryStyleMode;
}

#pragma mark 是否是 IM 拍摄器
- (BOOL)isFromIM
{
    return self.repository.repoContext.isIMRecord;
}

#pragma mark 进入页面的时候是否需要加载道具或音乐
- (BOOL)needDownloadMusicOrProp
{
    ACCRepoRearResourceModel *rearResource = [self.repository extensionModelOfClass:ACCRepoRearResourceModel.class];
    if (rearResource.stickerIDArray.count > 0 ||
        rearResource.musicModel) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark 是否设置了音乐
- (BOOL)hasSetMusic
{
    return self.repository.repoMusic.music != nil;
}

#pragma mark 是否需要处理系统音量键 UI
- (BOOL)enableVolumnButtonTriggersTheShoot
{
    return [self enableVolumnButtonTriggersTheShootFlag] && [self isModeSupportVolumeButton] && self.enableVolumeToShoot;
}

#pragma mark 是否是支持音量键触发拍摄的模式
- (BOOL)isModeSupportVolumeButton
{
    return [self isModeTakePicture] || [self isModeStory] || [self isModeMix] || [self isLivePhoto];
}

#pragma mark 是否开启音量键拍摄功能
- (BOOL)enableVolumnButtonTriggersTheShootFlag
{
    AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s, enableVolumnButtonTriggersTheShootFlag:%d.", __PRETTY_FUNCTION__, self.enableVolumeToShoot);
    return ACCConfigBool(kConfigBool_tools_shoot_advanced_setting_panel);
}

#pragma mark 是否开启屏蔽音量键拍摄功能
- (BOOL)blockVolumnButtonTriggersTheShootFlag
{
    return ACCConfigBool(kConfigBool_tools_shoot_advanced_setting_panel);
}

#pragma mark 开启音量键拍摄功能
- (void)openVolumnButtonTriggersTheShoot
{
    BOOL hideRecord = self.recordButton.hidden && !self.flowerService.inFlowerPropMode;
    BOOL enabled = [self enableVolumnButtonTriggersTheShoot] && !hideRecord;
    if (ACCConfigBool(kConfigBool_tools_shoot_advanced_setting_panel)) {
        enabled = enabled && !self.shouldBlockVolumnButtonTriggersTheShoot && !self.repository.repoDuet.isDuet;
    }
    if (enabled) {
        // 记录原来的音量值
        self.originalVolume = [AVAudioSession sharedInstance].outputVolume;
        AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|self.originalVolume is %f.", self.originalVolume);
        // 隐藏系统音量键 UI
        [self hideSystemVolumeView:YES];
    }
}

#pragma mark 关闭音量键拍摄功能
- (void)closeVolumnButtonTriggersTheShoot
{
    if ([self enableVolumnButtonTriggersTheShoot]) {
        [self closeVolumnButtonTriggersTheShootForce];
    }
}

- (void)closeVolumnButtonTriggersTheShootForce
{
    // 恢复系统音量键 UI
    [self hideSystemVolumeView:NO];
    // 清空计数
    [self clearVolumeButtonRelatedFlag];
}

#pragma mark 设备相机｜麦克风是否已授权
- (BOOL)isDeviceAuthorized
{
    ACCRecordAuthComponentAuthType authType = [ACCDeviceAuth currentAuthType];
    if ((authType & ACCRecordAuthComponentCameraAuthed) && (authType & ACCRecordAuthComponentMicAuthed)) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark 音量键回调事件
- (void)volumeClicked:(NSNotification *)notification
{
    if (@available(iOS 15.0, *)) {
        // iOS15通知回调会在子线程调用，即使在主线程监听
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleVolumeClickedEventWithNotification:notification];
        });
    } else {
        [self handleVolumeClickedEventWithNotification:notification];
    }
}

- (void)handleVolumeClickedEventWithNotification:(NSNotification *)notification
{
    if (self.viewContainer.isShowingPanel) {
        return;
    }
    
    NSDictionary *userInfo = notification.userInfo;
    NSString *parameterString = nil;
    NSString *resonString = nil;
    float volume = 0;
    if (@available(iOS 15.0, *)) {
        parameterString = ACCDynamicCast(userInfo[@"AudioCategory"], NSString);
        resonString = ACCDynamicCast(userInfo[@"Reason"], NSString);
        volume = [[userInfo objectForKey:@"Volume"] floatValue];
    } else {
        parameterString = ACCDynamicCast(userInfo[@"AVSystemController_AudioCategoryNotificationParameter"], NSString);
        resonString = ACCDynamicCast(userInfo[@"AVSystemController_AudioVolumeChangeReasonNotificationParameter"], NSString);
        volume = [[userInfo objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    }
    
    BOOL isDeviceAuthorized = [self isDeviceAuthorized];
    if (!isDeviceAuthorized) {
        // 恢复系统音量键 UI
        [self hideSystemVolumeView:NO];
        // 设置为最新的音量
        [self setVolume:volume];
        AWELogToolError(AWELogToolTagRecord, @"volumebutton|%s, isDeviceAuthorized:%d.", __PRETTY_FUNCTION__, isDeviceAuthorized);
        return;
    }

    if (!([parameterString isEqualToString:@"Audio/Video"] && [resonString isEqualToString:@"ExplicitVolumeChange"])) {
        // 这个场景就不要恢复系统音量键，系统非ExplicitVolumeChange无谓调用很多
        AWELogToolError(AWELogToolTagRecord, @"volumebutton|%s, parameterString:%@, resonString:%@, return.", __PRETTY_FUNCTION__, parameterString, resonString);
        return;
    }
    
    UIApplicationState currentState = [UIApplication sharedApplication].applicationState;
    BOOL isCurrentVCOnFrontWindow = [self p_isCurrentVCOnFrontWindow];
    if (!isCurrentVCOnFrontWindow ||
        currentState != UIApplicationStateActive ||
        !self.recordButton.enabled ||
        [ACCResponder topViewController] != self.controller.root) {
        // 恢复系统音量键 UI
        [self hideSystemVolumeView:NO];
        // 设置为最新的音量
        [self setVolume:volume];
        AWELogToolError(AWELogToolTagRecord, @"volumebutton|%s, isCurrentVCOnFrontWindow:%d, currentState:%d, recordButton.enabled:%d, topVC is root:%d.", __PRETTY_FUNCTION__, isCurrentVCOnFrontWindow, currentState, self.recordButton.enabled, [ACCResponder topViewController] == self.controller.root);
        return;
    }

    AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s, modeId:%d, isModeTakePicture:%d, isModeStory:%d, isModeMix:%d, isTapAndHoldToRecordCase:%d, isFromIM:%d, isCountdowning:%d, new volume:%f.", __PRETTY_FUNCTION__, self.switchModeService.currentRecordMode.modeId, [self isModeTakePicture], [self isModeStory], [self isModeMix], [self isTapAndHoldToRecordCase], [self isFromIM], self.viewContainer.shouldClearUI, volume);

    // 如果没有开启音量键拍摄功能，保留现网逻辑，只处理 快拍-照片、快拍-动图
    if (![self enableVolumnButtonTriggersTheShootFlag]) {
        if (self.cameraService.recorder.cameraMode == HTSCameraModePhoto) {
            self.repository.repoContext.isTriggeredByVolumeButton = YES;
            self.recordButton.alpha = 0.5f;
            [self.flowService takePicture];
        }
        else if ([self isLivePhoto]) {
            [self handleLivePhotoCase:NO];
        }
        else {
            // 上报第一次点击音量键
            [self trackFirstTimeOfTappingVolumeButton];
        }
        return;
    }
    
    // 如果音量键开关没有打开则不使用音量键拍摄
    if (!self.enableVolumeToShoot) {
        return;
    }

    // 以下逻辑都是开启了音量键拍摄功能
    BOOL hideRecord = self.recordButton.hidden && !self.flowerService.inFlowerPropMode;
    BOOL flowerBan = self.flowerService.isShowingLynxWindow || self.scanService.currentMode != ACCScanModeNone;
    BOOL disabled = ![self isModeSupportVolumeButton] || hideRecord || flowerBan;
    if (ACCConfigBool(kConfigBool_tools_shoot_advanced_setting_panel)) {
        disabled = disabled || self.shouldBlockVolumnButtonTriggersTheShoot || self.repository.repoDuet.isDuet;
    }
    if (disabled) {
        // 恢复系统音量键 UI
        [self hideSystemVolumeView:NO];
        // 设置为最新的音量
        [self setVolume:volume];
        AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s, enableVolumnButtonTriggersTheShoot:%d.", __PRETTY_FUNCTION__, [self enableVolumnButtonTriggersTheShoot]);
        return;
    }

    // 恢复回原来的音量
    [self setVolume:self.originalVolume];

    // 正在倒计时，不支持拍摄功能，同时不支持修改音量
    if (self.viewContainer.shouldClearUI) {
        AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s, isCountdowning:%d.", __PRETTY_FUNCTION__, self.viewContainer.shouldClearUI);
        return;
    }
    
    if (UIAccessibilityIsVoiceOverRunning()) {
        // 将焦点聚焦到录制按钮
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.captureButtonAnimationView);
    }
    
    if ([self isModeTakePicture]) {
        // 快拍-照片
        [self handleTakePictureCase];
    } else if (([self isModeStory] && [self isTapAndHoldToRecordCase] && ![self isFromIM]) || [self isModeMix]) {
        // 快拍-视频同时非 IM 拍摄器 或者 分段拍
        [self handleTapAndHoldToRecordCase];
    } else if ([self isModeStory] && (![self isTapAndHoldToRecordCase] || [self isFromIM])) {
        // 快拍-视频或者 IM 拍摄器
        [self handleTapToTakePictureAndHoldToRecordCase];
    }
    else if ([self isLivePhoto]) {
        // 快拍-动图
        [self handleLivePhotoCase:YES];
    }
}

#pragma mark 快拍-照片（点击或长按都是拍照）
- (void)handleTakePictureCase
{
    AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s.", __PRETTY_FUNCTION__);
    // 隐藏系统音量键 UI
    [self hideSystemVolumeView:YES];
    self.repository.repoContext.isTriggeredByVolumeButton = YES;
    self.recordButton.alpha = 0.5f;
    [self takePicture];
}

- (void)handleLivePhotoCase:(BOOL)hideSystemVolumeUI
{
    AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s.", __PRETTY_FUNCTION__);
    // 隐藏系统音量键 UI
    if (hideSystemVolumeUI) {
        [self hideSystemVolumeView:YES];
    }
    self.repository.repoContext.isTriggeredByVolumeButton = YES;
    [self startLivePhotoRecord];
}

#pragma mark 快拍-视频或者分段拍（点击：开始录制，再次点击：结束录制；按住：开始录制，松开：结束录制）
- (void)handleTapAndHoldToRecordCase
{
    // 开始录制 kNoRespondTimeAfterFirstCallback 秒钟之内，如果有多次回调，只会响应第一次回调，后面回调忽略掉；因为有些系统点击一下可能回调了多次
    if (self.timeToStartRecordTriggeredByVolumeButton > 0) {
        NSTimeInterval nowTime = [NSDate date].timeIntervalSinceReferenceDate;
        NSTimeInterval delta = nowTime - self.timeToStartRecordTriggeredByVolumeButton;
        if (delta <= kNoRespondTimeAfterFirstCallback) {
            return;
        }
    }
    
    // 隐藏系统音量键 UI
    [self hideSystemVolumeView:YES];
    self.numberOfVolumeButtonCallbacks++;
    AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s, number:%d.", __PRETTY_FUNCTION__, self.numberOfVolumeButtonCallbacks);
    if (self.numberOfVolumeButtonCallbacks == 1) {
        // 开始录制
        if ([self enableStoryTabInRecorder]) {
            // 开启录制按钮反转实验
            [self beginRecordByVolumeButton];
        } else {
            // 关闭录制按钮反转实验
            if ([self isModeMix]) {
                [self beginRecordByVolumeButtonWhenDisableStoryTabInRecorder];
            }
        }
        self.timeToStartRecordTriggeredByVolumeButton = [NSDate date].timeIntervalSinceReferenceDate;
    } else if (self.numberOfVolumeButtonCallbacks >= 2) {
        NSInteger tmpNumber = self.numberOfVolumeButtonCallbacks;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kTimeIntervalAfterLastCallback * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s, tmpNumber:%d, number:%d.", __PRETTY_FUNCTION__, tmpNumber, self.numberOfVolumeButtonCallbacks);
            if (tmpNumber == self.numberOfVolumeButtonCallbacks) {
                // 清空开始录制时间
                self.timeToStartRecordTriggeredByVolumeButton = 0;
                
                // 结束录制
                if ([self enableStoryTabInRecorder]) {
                    // 开启录制按钮反转实验
                    [self endRecordByVolumeButton];
                } else {
                    // 关闭录制按钮反转实验
                    if ([self isModeMix]) {
                        [self endRecordByVolumeButtonWhenDisableStoryTabInRecorder];
                    }
                }
            }
        });
    }
}

#pragma mark 快拍-视频（点击：拍照；按住：开始录制，松开：结束录制）
- (void)handleTapToTakePictureAndHoldToRecordCase
{
    // 隐藏系统音量键 UI
    [self hideSystemVolumeView:YES];
    self.numberOfVolumeButtonCallbacks++;
    AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s, number:%d.", __PRETTY_FUNCTION__, self.numberOfVolumeButtonCallbacks);
    if (self.numberOfVolumeButtonCallbacks == 1) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kTimeIntervalBetweenFirstAndSecondCallbacks * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.numberOfVolumeButtonCallbacks == 1) {
                // 拍照
                self.recordButton.alpha = 0.5f;
                [self takePictureInTapTriggerRecordingMode];
                self.numberOfVolumeButtonCallbacks = 0;
            }
        });
        return;
    }
    
    if (self.numberOfVolumeButtonCallbacks == 2) {
        // 开始录制
        [self beginRecordByVolumeButton];
    }
    
    if (self.numberOfVolumeButtonCallbacks >= 2) {
        NSInteger tmpNumber = self.numberOfVolumeButtonCallbacks;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kTimeIntervalAfterLastCallback * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s, tmpNumber:%d, number:%d.", __PRETTY_FUNCTION__, tmpNumber, self.numberOfVolumeButtonCallbacks);
            if (tmpNumber == self.numberOfVolumeButtonCallbacks) {
                // 结束录制
                [self endRecordByVolumeButton];
            }
        });
    }
}

#pragma mark 拍照
- (void)takePicture
{
    [self.flowService takePicture];
}

#pragma mark 拍照(ACCConfigBool(kConfigBool_story_tab_tap_hold_record) == NO)
- (void)takePictureInTapTriggerRecordingMode
{
    AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s.", __PRETTY_FUNCTION__);
    
    self.repository.repoContext.isTriggeredByVolumeButton = YES;
    self.cameraService.recorder.cameraMode = HTSCameraModePhoto;
    [self.flowService takePicture];
    self.cameraService.recorder.cameraMode = HTSCameraModeVideo;
}

#pragma mark 是否开启录制按钮反转实验
- (BOOL)enableStoryTabInRecorder
{
    BOOL result = ACCConfigBool(kConfigBool_enable_story_tab_in_recorder);
    AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s, enableStoryTabInRecorder:%d.", __PRETTY_FUNCTION__, result);
    return result;
}

#pragma mark 音量键触发开始录制
- (void)beginRecordByVolumeButton
{
    AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s.", __PRETTY_FUNCTION__);
    self.repository.repoContext.isTriggeredByVolumeButton = YES;
    [self.lightningAnimation executeTouchesBeganTask];
}

#pragma mark 音量键触发结束录制
- (void)endRecordByVolumeButton
{
    AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s.", __PRETTY_FUNCTION__);
    [self.lightningAnimation executeTouchesEndTask];
    [self clearVolumeButtonRelatedFlag];
}

#pragma mark 音量键触发开始录制（当开启录制按钮反转实验）
- (void)beginRecordByVolumeButtonWhenDisableStoryTabInRecorder
{
    AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s.", __PRETTY_FUNCTION__);
    self.repository.repoContext.isTriggeredByVolumeButton = YES;
    [self.captureButtonAnimationView executeTouchesBeganTask];
}

#pragma mark 音量键触发结束录制（当开启录制按钮反转实验）
- (void)endRecordByVolumeButtonWhenDisableStoryTabInRecorder
{
    AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s.", __PRETTY_FUNCTION__);
    [self.captureButtonAnimationView executeTouchesEndTask];
    [self clearVolumeButtonRelatedFlag];
}

#pragma mark 清除音量键相关 flag
- (void)clearVolumeButtonRelatedFlag
{
    AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s.", __PRETTY_FUNCTION__);
    self.numberOfVolumeButtonCallbacks = 0;
    self.repository.repoContext.isTriggeredByVolumeButton = NO;
}

#pragma mark 上报第一次点击音量键
- (void)trackFirstTimeOfTappingVolumeButton
{
    if (!self.isFirstTimeOfTappingVolumeButton &&
        ![self enableVolumnButtonTriggersTheShootFlag]) {
        // 对照组才上报
        self.isFirstTimeOfTappingVolumeButton = YES;
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        params[@"enter_from"] = @"video_shoot_page";
        params[@"shoot_way"] = self.repository.repoTrack.referString ?: @"";
        params[@"creation_id"] = self.repository.repoContext.createId ?: @"";
        NSString *eventName = [self isFromIM] ? @"im_edit_volume" : @"edit_volume";
        [ACCTracker() trackEvent:eventName params:params needStagingFlag:NO];
    }
}

#pragma mark - record button

- (id<ACCCaptureButtonAnimationProtocol>)captureAnimation
{
    return self.captureButtonAnimationView;
}

- (void)stopRecordButtonAnimation
{
    [self stopRecordButtonAnimationWithIgnoreProgress:NO];
}

// 子类 ACCLightningStyleRecordFlowComponent 重写
- (void)stopRecordButtonAnimationWithIgnoreProgress:(BOOL)ignoreProgress
{
    [self.captureAnimation endCountdownModeIfNeed];
    [self.captureAnimation stop];
}

- (void)showMixRecordButtonTips
{
    self.mixRecordBubble = [ACCBubble() showBubble: ACCLocalizedString(@"record_mode_combine_tip", @"单击或按住拍摄视频")  forView:self.recordButton inContainerView:self.viewContainer.interactionView anchorAdjustment:CGPointMake(0, -16) inDirection:ACCBubbleDirectionUp bgStyle:ACCBubbleBGStyleDefault completion:^{}];
    
    [ACCBubble() bubble:self.mixRecordBubble supportTapToDismiss:YES];
}

- (void)showRecordButtonIfShould:(BOOL)show animated:(BOOL)animated
{
    show = (show && !self.viewContainer.isShowingAnyPanel &&
            self.repository.repoGame.gameType == ACCGameTypeNone);
    show = show &&  [self.shouldShowCaptureAnimationView evaluate]; // fix https://bits.bytedance.net/meego/aweme/story/detail/983728?issueId=1939012&parentUrl%255C%3D%2Faweme%2Fdashboard%255C%23issue_management#issue_management

    if (animated) {
        if (!show) {
            [self.recordButton acc_fadeHidden];
            [self.captureButtonAnimationView acc_fadeHidden];
        } else {
            [self.recordButton acc_fadeShow];
            [self.captureButtonAnimationView acc_fadeShow];
        }
    } else {
        if ([ACCRecognitionConfig enabled]) {
            self.recordButton.alpha = 1;
            self.captureButtonAnimationView.alpha = 1;
        }
        self.recordButton.hidden = !show;
        self.captureButtonAnimationView.hidden = !show;
    }
    CGFloat maxDuration = self.repository.repoContext.maxDuration;
    self.recordShowTipButton.hidden = !show || self.flowService.currentDuration < maxDuration;
    ACCLog(@"shootButton maxDuration=%f currentDuration=%f show=%d", maxDuration, self.flowService.currentDuration, show);
}

- (void)updateRecordButtonWithCurrentDuration:(CGFloat)currentDuration
{
    CGFloat maxDuration = self.repository.repoContext.maxDuration;
    BOOL enabled = (currentDuration < maxDuration);
    self.recordButton.enabled = enabled;
    if (ACC_FLOAT_GREATER_THAN(currentDuration, maxDuration) && maxDuration > 0) {
        ACCLog(@"recordShowTipButton.hidden=NO");
        self.recordShowTipButton.hidden = NO;
    } else {
        self.recordShowTipButton.hidden = YES;
    }
    if ([self.captureAnimation respondsToSelector:@selector(setAnimationEnabled:)]) {
        [self.captureAnimation setAnimationEnabled:enabled];
    }
}

- (BOOL)shouldCompleteImmediatelyAfterStop
{
    if (self.switchModeService.currentRecordMode.isStoryStyleMode) {
        return YES;
    }
    id<ACCRepoKaraokeModelProtocol> repoKaraoke = [self.repository extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
    if (repoKaraoke.lightningStyleKaraoke) {
        return YES;
    }
    return NO;
}

- (BOOL)isLiteRedPacketVideo
{

    BOOL enableLiteV1 = [ACCStudioLiteRedPacket() isLiteRedPacketRecord:self.repository] && self.switchModeService.currentRecordMode.modeId == ACCRecordModeStory;
    
    if (!enableLiteV1) {
        return NO;
    }
    
    ACCLiteShootGuideType type = ACCConfigInt(kConfigInt_lite_shoot_guide);

    BOOL enableQualityDetect = (type == ACCLiteShootGuideTypeAlgorithm ||
                                type == ACCLiteShootGuideTypeVideoGuideAlgorithm);
    
    if (![ACCStudioLiteRedPacket() stickerIsLiteRedPacket:self.repository] && !enableQualityDetect) {
        return NO;
    }
    
    if (self.flowService.currentDuration > 1.0) {
        return NO;
    }
    
    return YES;
}

- (void)liteRedPacketCancelRecord
{
    if (self.flowService.flowState != ACCRecordFlowStatePause) {
        [self.flowService pauseRecord];
    }
    // pauseRecord后ve的工作没有立即结束，会有ui bug。使用dispatch_async解决
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.flowService deleteAllSegments];
        if ([ACCStudioLiteRedPacket() stickerIsLiteRedPacket:self.repository]) {
            [ACCToast() show:@"红包视频不支持录制1s以下的视频"];
        } else {
            [ACCToast() show:@"拍摄时间太短了，重拍试试"];
        }
    });
}

#pragma mark - progress

- (void)updateStandardDurationIndicatorDisplay
{
}

- (void)updateProgressAndMarksDisplay
{
}

#pragma mark - action

- (void)startRecord:(UIButton *)sender
{
    if (self.cameraService.recorder.isRecording) {
        return;
    }
    if (self.viewContainer.switchModeContainerView.isPanned) {
        [self.captureAnimation stop];
        return;
    }

    [[AWERecorderTipsAndBubbleManager shareInstance] removeBubbleAndHintIfNeeded];
    [self startRecord:sender delay:NO];
}

- (void)startRecord:(UIButton *)sender delay:(BOOL)delay
{
    [self.flowService startRecordWithDelayRecord:delay];
}

- (void)clickRecordTipButton:(id)sender
{
    if (!self.isMounted) {
        return;
    }
    [self showReachedDurationLimitToast];
}

- (void)showReachedDurationLimitToast
{
    [ACCToast() show: ACCLocalizedCurrentString(@"com_mig_limit_reached_try_trimming_the_video")];
}

- (void)startLivePhotoRecord
{
    if (!self.isMounted) {
        return;
    }
    if (self.viewContainer.switchModeContainerView.isPanned) {
        [self.captureAnimation stop];
        return;
    }
    if (self.cameraService.recorder.isRecording ||
        self.isLivePhotoRecording ||
        self.cameraService.recorder.cameraMode != HTSCameraModeVideo) {
        return;
    }
    id<ACCRecorderLivePhotoProtocol> recorder = ACCGetProtocol(self.cameraService.recorder, ACCRecorderLivePhotoProtocol);
    if (recorder == nil || [recorder isLivePhotoRecording]) {
        // 拍摄过程中，按音量键重复拍摄等情况
        return;
    }
    
    BOOL oldForbid = self.captureButtonAnimationView.forbidUserPause;
    @weakify(self);
    [self.flowService startLivePhotoRecordWithCompletion:^{
        @strongify(self);
        self.captureButtonAnimationView.forbidUserPause = oldForbid;
    }];
    
    [[AWERecorderTipsAndBubbleManager shareInstance] removeBubbleAndHintIfNeeded];
    self.captureButtonAnimationView.forbidUserPause = YES;
}

#pragma mark - view model

- (ACCPropViewModel *)propViewModel
{
    ACCPropViewModel *propViewModel = [self getViewModel:[ACCPropViewModel class]];
    NSAssert(propViewModel, @"should not be nil");
    return propViewModel;
}

#pragma mark - getter setter

- (UIButton *)recordButton
{
    if (!_recordButton) {
        _recordButton = [[UIButton alloc] initWithFrame:[self recordButtonFrame]];
        _recordButton.titleLabel.font = [ACCFont() acc_boldSystemFontOfSize:15];
        [_recordButton setTitleColor:ACCResourceColor(ACCUIColorConstTextInverse) forState:UIControlStateNormal];
        _recordButton.layer.cornerRadius = kRecordButtonWidth/2.0;
        _recordButton.userInteractionEnabled = NO;
        _recordButton.isAccessibilityElement = NO;
        [_recordButton addTarget:self action:@selector(startRecord:) forControlEvents:UIControlEventTouchUpInside];
        [_recordButton addTarget:self.flowService action:@selector(takePicture) forControlEvents:UIControlEventTouchDown];
        [_recordButton addTarget:self.flowService action:@selector(pauseRecord) forControlEvents:UIControlEventTouchUpInside];
        _recordButton.exclusiveTouch = YES;
        if ([self.flowConfig enableLightningStyleRecordButton]) {
            _recordButton.backgroundColor = [UIColor clearColor];
        }
        [self.viewContainer.layoutManager addSubview:_recordButton viewType:ACCViewTypeRecordButton];
    }
    return _recordButton;
}

- (CGRect)recordButtonFrame
{
    CGFloat shiftToTop = 14;
    if ([AWEXScreenAdaptManager needAdaptScreen] && !(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize) & ACCViewFrameOptimizeFullDisplay)) {
        shiftToTop = -12;
    }
    return CGRectMake((ACC_SCREEN_WIDTH - kRecordButtonWidth)/2, ACC_SCREEN_HEIGHT + [self.viewContainer.layoutManager.guide recordButtonBottomOffset] - kRecordButtonHeight + ([UIDevice acc_isIPhoneX] ? shiftToTop : 0), kRecordButtonWidth, kRecordButtonHeight);
}

- (UIButton *)recordShowTipButton
{
    if (!_recordShowTipButton) {
        _recordShowTipButton = [[UIButton alloc] initWithFrame:[self recordButtonFrame]];
        _recordShowTipButton.hidden = YES;
        [_recordShowTipButton addTarget:self action:@selector(clickRecordTipButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _recordShowTipButton;
}

- (UIView<ACCCaptureButtonAnimationProtocol> *)buildCaptureButton
{
    AWECaptureButtonAnimationView *captureButtonAnimationView = [AWECaptureButtonAnimationView new];
    captureButtonAnimationView.captureButton = self.recordButton;
    captureButtonAnimationView.captureShowTipButton = self.recordShowTipButton;
    captureButtonAnimationView.userInteractionEnabled = YES;
    captureButtonAnimationView.multipleTouchEnabled = YES;
    captureButtonAnimationView.isAccessibilityElement = NO;
    captureButtonAnimationView.captureButton.isAccessibilityElement = NO;
    captureButtonAnimationView.captureShowTipButton.isAccessibilityElement = NO;
    captureButtonAnimationView.delegate = self;
    [captureButtonAnimationView updateAnimatedRecordButtonCenter:self.recordShowTipButton.center];
    return captureButtonAnimationView;
}

- (id<ACCCaptureButtonAnimationProtocol>)captureButtonAnimationView
{
    if (!_captureButtonAnimationView) {
        _captureButtonAnimationView = [self buildCaptureButton];
    }
    return _captureButtonAnimationView;
}

- (id<ACCLightningCaptureButtonAnimationProtocol>)lightningAnimation
{
    if ([self.captureButtonAnimationView conformsToProtocol:@protocol(ACCLightningCaptureButtonAnimationProtocol)]) {
        return (id<ACCLightningCaptureButtonAnimationProtocol>)self.captureButtonAnimationView;
    }
    return nil;
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [IESAutoInline(serviceProvider, ACCRouterService) addSubscriber:self];
    [self.cameraService addSubscriber:self];
    [self.cameraService.recorder addSubscriber:self];
    [self.flowService addSubscriber:self];
    [self.switchModeService addSubscriber:self];
    [self.propService addSubscriber:self];
    [IESAutoInline(self.serviceProvider, ACCRecordConfigService) registDurationHandler:self];
}

#pragma mark - ACCRecordConfigDurationHandler

- (CGFloat)getComponentDuration:(AVAsset *)asset
{
    if (!self.isLivePhotoRecording) {
        return CGFLOAT_MAX;
    }
    ACCRecordMode *changingToMode = self.switchModeService.changingToMode;
    ACCRecordMode *currentMode = self.switchModeService.currentRecordMode;
    
    // fix: 从'拍动图'切到'拍视频'tab，拍视频的时长不对的问题
    // 因为拍视频的时长是在其他类的switchModeServiceWillChangeToMode方法中设置的，
    // 此时 currentRecordMode 还没更新，所以必须要判断 changingToLivePhoto
    BOOL changingToLivePhoto = (changingToMode != nil && changingToMode.modeId == ACCRecordModeLivePhoto);
    BOOL changedToLivePhoto = (changingToMode == nil && currentMode.modeId == ACCRecordModeLivePhoto);
    if (changingToLivePhoto || changedToLivePhoto) {
        return ACCConfigDouble(kConfigDouble_live_photo_record_duration);
    }
    return CGFLOAT_MAX;
}

- (void)didSetMaxDuration:(CGFloat)duration
{
    CGFloat currentDuration = 0;
    if ([self.flowService markedTimesCount] > 0) {
        currentDuration = [[self.flowService.markedTimes lastObject] floatValue];
    }
    [self updateRecordButtonWithCurrentDuration:currentDuration];
    [self updateStandardDurationIndicatorDisplay];
    [self updateProgressAndMarksDisplay];
    double progress = ((NSTimeInterval)self.flowService.currentDuration) / self.repository.repoContext.maxDuration;
    if (progress >= 1) {
        [self stopRecordButtonAnimation];
    }
    
    if (self.repository.repoGame.gameType != ACCGameTypeNone) {
        if(self.cameraService.cameraHasInit){
            [self.cameraService.recorder setMaxLimitTime:kCMTimeInvalid];
        }
    } else {
        int32_t timeScale = 600;
        if(self.cameraService.cameraHasInit){
            CGFloat maxDuration = self.repository.repoContext.maxDuration - [self.cameraService.recorder getTotalDuration];
            maxDuration = maxDuration > 0 ? maxDuration : 0;
            CMTime time = CMTimeMakeWithSeconds(maxDuration, timeScale);
            [self.cameraService.recorder setMaxLimitTime:time];
        }
    }
}

#pragma mark - AWECaptureButtonAnimationViewDelegate

- (BOOL)shouldRespondsToAnimationDidEnd:(id<ACCCaptureButtonAnimationProtocol>)animationView
{
    return [self.flowConfig enableTapToTakePictureRecordMode:self.switchModeService.currentRecordMode.isStoryStyleMode];
}

- (void)touchBeginWithAnimationDisabled:(id<ACCCaptureButtonAnimationProtocol>)animationView
{
    [self showReachedDurationLimitToast];
}

- (BOOL)animationShouldBegin:(id<ACCCaptureButtonAnimationProtocol>)animationView
{
    if (self.flowService.isDelayRecord) { // CAPTAIN-6476
        return YES;
    }
    if ([self.cameraService.cameraControl status] == HTSCameraStatusRecording) {
        [self animationDidEnd:animationView];
        return NO;
    }

    return ([self.cameraService.cameraControl status] == HTSCameraStatusIdle) && !self.viewContainer.isShowingPanel;
}

- (void)animationDidBegin:(id<ACCCaptureButtonAnimationProtocol>)animationView
{
    [ACCToolUIReactTrackService() eventEnd:kAWEUIEventLatestEvent withPublishModel:self.repository];
    AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s, start.", __func__);
    if ([self.cameraService.cameraControl status] == HTSCameraStatusIdle) {
        if (self.cameraService.recorder.cameraMode == HTSCameraModeVideo) {
            if (self.captureAnimation.recordMode.modeId == ACCRecordModeLivePhoto) {
                [self startLivePhotoRecord];
            } else {
                [self startRecord:self.recordButton];
            }
        }
        if (self.cameraService.recorder.cameraMode == HTSCameraModePhoto) {
            [self startPlayerFirstFrameDurationIfNeed];
            [self.flowService takePicture];
        }
        if (self.captureAnimation.recordMode.isMixHoldTapVideo && !self.captureAnimation.isCountdowning) {
            self.lastTouchPoint = self.recordShowTipButton.frame.origin;

            [ACCTracker() trackEvent:@"zoom"
                                              label:@"shoot_page"
                                              value:nil
                                              extra:nil
                                         attributes:@{@"enter_from":@"long_press", @"zoom_method":@"long_press"}];
        }
        self.cameraZoomFactor = self.cameraService.cameraControl.zoomFactor;
    }
    if (self.flowService.currentDuration >= self.repository.repoContext.maxDuration) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [animationView stop];
        });
    }
    AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s, end.", __func__);
}

- (void)animationDidMoved:(CGPoint)touchPoint
{
    AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s.", __PRETTY_FUNCTION__);

    BOOL isLivePhotoCameraZoomable =
    self.captureAnimation.recordMode.modeId == ACCRecordModeLivePhoto &&
    [self.cameraService.cameraControl status] == IESMMCameraStatusIdle;

    if ([self.cameraService.cameraControl status] == IESMMCameraStatusRecording || isLivePhotoCameraZoomable) {
        if (!self.cameraService.cameraControl.supprotZoom) {
            NSString *log = [NSString stringWithFormat:@"PanForZoom end(camera not support): %@", [self.cameraService.cameraControl cameraZoomSupportedInfo]];
            AWELogToolInfo(AWELogToolTagRecord, @"%@", log);
            [ACCTracker() trackEvent:@"zoom"
                                             params:@{@"camera_not_support_zoom" : log ?: @""}
                                    needStagingFlag:NO];
            return;
        }

        // zoom手势起作用的临界值
        CGFloat criticalTopOffsetY = 6;
        if (@available(iOS 11.0, *)) {
             if ([UIDevice acc_isIPhoneX]) {
                 criticalTopOffsetY = ACC_STATUS_BAR_NORMAL_HEIGHT + 6;
             }
        }
        CGFloat criticalBottomOffsetY = self.recordShowTipButton.frame.origin.y;
        CGFloat criticalDistance = criticalBottomOffsetY - criticalTopOffsetY;

        if (ACC_FLOAT_EQUAL_ZERO(criticalDistance) || touchPoint.y > criticalBottomOffsetY) {
            return;
        }

        CGFloat criticalScaleSpeed = (self.cameraService.cameraControl.maxZoomFactor - 1.0)/ criticalDistance;
        CGFloat scale = fabs(criticalBottomOffsetY - touchPoint.y) * criticalScaleSpeed + self.cameraZoomFactor;

        // 开始拖动时，相机zoom已处在最大倍数
        if (!(self.cameraZoomFactor < self.cameraService.cameraControl.maxZoomFactor - 0.5)) {
            if (touchPoint.y <= self.lastTouchPoint.y) {
                // 向上滑动
                self.lastTouchPoint = touchPoint;
            } else {
                // 向下滑动
                CGFloat relativeTopOffsetY = self.lastTouchPoint.y;
                CGFloat relativeDistance = fabs(criticalBottomOffsetY - relativeTopOffsetY);
                if (ACC_FLOAT_EQUAL_ZERO(relativeDistance)) {
                    return;
                }
                CGFloat relativeScaleSpeed = (self.cameraService.cameraControl.maxZoomFactor - 1.0)/ relativeDistance;
                scale = self.cameraService.cameraControl.maxZoomFactor - relativeScaleSpeed * (touchPoint.y - relativeTopOffsetY);
            }
        }

        // 修正scale，由于touchMoved有间隔，手指回到原点后，有可能scale不为1.0
        if (1.f < scale && scale < 1.05f) {
            scale = 1.f;
        }

        if (scale >= 1 && scale <= self.cameraService.cameraControl.maxZoomFactor) {
            self.isZooming = YES;
            [self showZoomInfoIfNeededForScale:scale];
            [self.cameraService.cameraControl changeToZoomFactor:scale];
        }

        if (fabs(scale - floor(scale)) < 0.1) {
            AWELogToolInfo(AWELogToolTagRecord, @"panForZoom : scale = %f", scale);
        }
    }
}

- (void)showZoomInfoIfNeededForScale:(CGFloat)scale
{
    if (![self.cameraService.cameraControl currentInVirtualCameraMode]) {
        return;
    }
    self.oldZoomFactor = scale;
    if (ACCConfigBool(kConfigBool_tools_shoot_advanced_setting_panel)) {
        CGFloat minZoomFactor = self.cameraService.cameraControl.minZoomFactor;
        CGFloat maxZoomFactor = self.cameraService.cameraControl.maxZoomFactor;
        if (scale < minZoomFactor) {
            scale = minZoomFactor;
        } else if (scale > maxZoomFactor) {
            scale = maxZoomFactor;
        }
        [[AWERecorderTipsAndBubbleManager shareInstance] showZoomScaleHintViewWithContainer:self.viewContainer.interactionView
                                                                                  zoomScale:scale
                                                                               isGestureEnd:NO];
    }
}


- (void)animationDidEnd:(id<ACCCaptureButtonAnimationProtocol>)animationView
{
    [[AWERecorderTipsAndBubbleManager shareInstance] removeZoomScaleHintView];
    
    [self pauseRecord];
}

- (void)pauseRecord
{
    AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s.", __func__);
    if ([self isLiteRedPacketVideo]) {
        AWELogToolInfo(AWELogToolTagRecord, @"lite red packet branch");
        [self liteRedPacketCancelRecord];
        return;
    }
    
    BOOL liteStickerCompletion = [ACCStudioLiteRedPacket() liteAllowCompleteWithPublishModel:self.repository cameraService:self.cameraService modeService:self.switchModeService];
    if (!liteStickerCompletion) {
        return;
    }
    
    if (ACCConfigBool(kConfigBool_quick_story_long_press_hold_60s) && self.switchModeService.currentRecordMode.isStoryStyleMode) {
        if (ACCConfigBool(kConfigBool_story_long_record_time)) {
            [self.switchModeService switchToLengthMode:ACCRecordLengthModeLong];
        } else {
            [self.switchModeService switchToLengthMode:ACCRecordLengthModeStandard];
        }
    }
    
    if ([self shouldCompleteImmediatelyAfterStop]) {
        if (self.switchModeService.currentRecordMode.isStoryStyleMode) {
            [ACCToolUIReactTrackService() eventBegin:kAWEUIEventFinishFastRecord];
        }
        [self p_completeImmediatlyWhenStopRecordIfNeeded];
        return;
    }
    if (self.cameraService.recorder.cameraMode == HTSCameraModePhoto) {
        return; //调用拍照方法拍照，拍完照之后跳转到发布页
    }
    if (self.propService.prop.isMultiSegProp) {
        return;
    }
    if (self.cameraService.cameraControl.status == IESMMCameraStatusRecording) {
        if (self.isZooming) {
            [[AWERecorderTipsAndBubbleManager shareInstance] showZoomScaleHintViewWithContainer:self.viewContainer.interactionView
                                                                                      zoomScale:self.oldZoomFactor
                                                                                   isGestureEnd:YES];
            self.isZooming = NO;
        }
        [self.flowService pauseRecord];
    }
}

#pragma mark - ACCCameraLifeCircleEvent

- (void)cameraService:(id<ACCCameraService>)cameraService didRecordReadyWithError:(NSError *)error
{
    [self trackError:error action:@"camera_did_ready"];
}

- (void)cameraService:(id<ACCCameraService>)cameraService startVideoCaptureWithError:(NSError *)error
{
    [self trackError:error action:@"start_capture"];
}

- (void)cameraService:(id<ACCCameraService>)cameraService stopVideoCaptureWithError:(NSError *)error
{
    [self trackError:error action:@"stop_capture"];
}

- (void)cameraService:(id<ACCCameraService>)cameraService didChangeDuration:(CGFloat)duration totalDuration:(CGFloat)totalDuration
{
    if (self.repository.repoGame.gameType != ACCGameTypeNone) {
        return;
    }
    self.flowService.currentDuration = totalDuration;
}

- (void)onCreateCameraCompleteWithCamera:(id<ACCCameraService>)cameraService {
    if (self.cameraService.cameraHasInit) {
        if (self.repository.repoFlowControl.autoShoot && !self.isFirstAppear) {
            [self startRecord:self.recordButton delay:YES];
            self.repository.repoFlowControl.autoShoot = NO;
        }
        [cameraService.effect p_safelySetRenderCacheStringByKey:@"CreationID" value:self.repository.repoContext.createId];
    }
}

- (void)cameraService:(id<ACCCameraService>)cameraService pauseRecordWithError:(NSError *)error
{
    if (self.repository.repoReshoot.isReshoot) {
        [self stopRecordButtonAnimation];
    }
    
    if (self.repository.repoFlowControl.videoRecordButtonType == AWEVideoRecordButtonTypeStory && !ACCConfigBool(kConfigBool_story_tab_tap_hold_record)) {
        [self.flowService picturePauseRecordWithSuccess:error == nil];
    } else {
        [self.flowService pauseRecordWithSuccess:error == nil];
    }
    if (!error) {
        [self.flowService fillChallengeNameForFragmentInfo];
        IESVideoDetectInputModel *input = [IESVideoDetectInputModel new];
        input.asset = self.repository.repoVideoInfo.video.videoAssets.lastObject;
        input.extraLog = @{@"scene": @"record"};
        [ACCVideoInspector() inspectVideo:input];
    }
    
    [self trackError:error action:@"pause_record"];
    UIApplicationState currentState = [UIApplication sharedApplication].applicationState;
    BOOL isAppNotActiveAndInStory = currentState != UIApplicationStateActive && self.repository.repoFlowControl.videoRecordButtonType == AWEVideoRecordButtonTypeStory;
    if (isAppNotActiveAndInStory && ![self.flowService allowComplete]) {
        [self.flowService deleteAllSegments];
        @weakify(self);
        [self.cameraService.recorder.videoData runAsync:^{
            @strongify(self);
            [ACCDraft() deleteDraftWithID:self.repository.repoDraft.taskID];
        }];
    }
    if (!self.repository.repoReshoot.isReshoot) {
        ACCVEVideoData *videoData = [ACCVEVideoData videoDataWithVideoData:self.cameraService.recorder.videoData draftFolder:self.repository.repoDraft.draftFolder];
        [self.repository.repoVideoInfo updateVideoData:videoData];
        [ACCRecordDraftHelper saveBackupWithRepository:self.repository];
    }
    
    if (self.shouldRemoveLastFragment) {
        self.shouldRemoveLastFragment = NO;
        [self.flowService removeLastSegment];
    }
}

- (void)cameraService:(id<ACCCameraService>)cameraService startRecordWithError:(NSError *)error
{
    [self trackError:error action:@"start_record"];
    [ACCFeedback() acc_recordForVideoRecord:AWEStudioFeedBackStatusStart code:0];
    if (error) {
        [ACCFeedback() acc_recordForVideoRecord:AWEStudioFeedBackStatusFail code:error.code];
    }
}

- (void)cameraService:(id<ACCCameraService>)cameraService didReachMaxTimeVideoRecordWithError:(NSError *)error
{
    if (error) {
        AWELogToolError(AWELogToolTagRecord, @"ReachMaxTimeVideoRecord failed. %@", error);
    }
    BOOL shouldComplete = [ACCStudioLiteRedPacket() liteAllowCompleteWithPublishModel:self.repository cameraService:self.cameraService modeService:self.switchModeService];
    if (shouldComplete && self.themeService.recordShouldComple) {
        shouldComplete = self.themeService.recordShouldComple();
    }
    if (shouldComplete) {
        [self startPlayerFirstFrameDurationIfNeed];
        [[self flowService] stopRecordAndPossiblyExportVideo];
    }
}

- (void)trackError:(NSError *)error action:(NSString *)action
{
    NSString *markdTimes = [self.flowService.markedTimes componentsJoinedByString:@","];
    NSDictionary *info = @{
        @"marked_times" :  markdTimes?:@"",
        @"camera_status" : @([self.cameraService.cameraControl status]),
        @"ignoreNotification" : @([self.cameraService.cameraControl getIgnoreNotificatio])
    };
    [self.trackService trackError:error action:action info:info];
}

#pragma mark - ACCRecorderEvent

- (void)onCaptureStillImageWithImage:(UIImage *)image error:(NSError *)error
{
    [self trackError:error action:@"take_picture"];
}

- (void)startPlayerFirstFrameDurationIfNeed
{
    ACCKdebugSignPostStart(10, 0, 0, 0, 0);
    NSTimeInterval begin = [ACCMonitor() timeIntervalForKey:@"player_first_render_duration"];
    if (begin < 0.1 || begin > 1000) {
        [ACCMonitor() startTimingForKey:@"player_first_render_duration"];
    }
    [ACCMonitor() startTimingForKey:@"video_export_duration"];
}

- (void)onStartExportVideoDataWithData:(HTSVideoData *)data
{
    [ACCTimeTraceUtil startTraceTimeForKey:@"export_video_cost"];//start export video
    
    [self startPlayerFirstFrameDurationIfNeed];
    if (self.repository.repoReshoot.isReshoot) { //React需要合成视频，保留等待提示
        self.indicatorView = [ACCLoading() showTextLoadingOnView:self.viewContainer.interactionView title:ACCLocalizedCurrentString(@"com_mig_loading_67jy7g") animated:YES];
    }
}

- (void)onFinishExportVideoDataWithData:(HTSVideoData *)data error:(NSError *)error
{
    //record video export cost
    NSTimeInterval interval = [ACCTimeTraceUtil timeIntervalForKey:@"export_video_cost"];
    [ACCTimeTraceUtil cancelTraceTimeForKey:@"export_video_cost"];
    self.repository.repoTranscoding.exportVideoDuration = interval;
    
    [self trackError:error action:@"export"];
    [self trackSuccessRateWithError:error];
    
    if (self.repository.repoDuet.isDuet) {
        return;
    }
    if (self.repository.repoReshoot.isReshoot) {
        NSDictionary *referExtra = self.repository.repoTrack.referExtra;
        NSDictionary *params = @{
            @"segment": @(data.videoAssets.count),
            @"enter_from": @"video_edit_page",
            @"shoot_way": referExtra[@"shoot_way"] ?: @"",
            @"creation_id": referExtra[@"creation_id"] ?: @"",
            @"content_source": referExtra[@"content_source"] ?: @"",
            @"content_type": referExtra[@"content_type"] ?: @""
        };
        [ACCTracker() trackEvent:@"back_to_video_trim" params:params needStagingFlag:NO];
    }
    [self.flowService executeExportCompletionWithVideoData:data error:error];
}

- (void)trackSuccessRateWithError:(NSError *)error
{
    NSMutableDictionary *extraData = [NSMutableDictionary dictionary];
    NSInteger status = error ? 1 : 0;
    if (error) {
        extraData[@"errorCode"]  = @(error.code);
        extraData[@"errorDesc"]  = error.description?:@"";
    }
    [ACCMonitor() trackService:@"aweme_concat_success_rate" status:status extra:extraData];
}

#pragma mark - ACCRecordPropServiceSubscriber

- (void)propServiceDidApplyProp:(IESEffectModel *)prop success:(BOOL)success
{
    self.captureButtonAnimationView.forbidUserPause = prop.isMultiSegProp;
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    mode.isMeteorMode = self.repository.repoContext.isMeteorMode;
    [self.captureAnimation switchToMode:mode];
    if (mode.lengthMode != ACCRecordLengthModeUnknown) {
        [self updateStandardDurationIndicatorDisplay];
    }

    [[AWERecorderTipsAndBubbleManager shareInstance] removeZoomScaleHintView];
    
    if (mode.isPhoto) {
        BOOL needUseMVMuisc = YES;
        if (self.repository.repoMusic.music) {
            BOOL draftReuseMusic = AWERecordMusicSelectSourceOriginalVideo == self.repository.repoMusic.musicSelectFrom && [self.repository.repoTrack.referString isEqualToString:@"draft_again"];
            if (AWERecordMusicSelectSourceMusicDetail == self.repository.repoMusic.musicSelectFrom ||
                AWERecordMusicSelectSourceMusicSelectPage == self.repository.repoMusic.musicSelectFrom ||
                draftReuseMusic) {
                needUseMVMuisc = NO;
            }
        }
        if (needUseMVMuisc) {
            [[AWEMVTemplateModel sharedManager] preFetchPhotoToVideoMusicList];
        }
    }
    
    if ([self enableVolumnButtonTriggersTheShootFlag] && self.enableVolumeToShoot) {
        if ([self isModeSupportVolumeButton]) {
            [self openVolumnButtonTriggersTheShoot];
        } else {
            // 恢复系统音量键 UI
            [self hideSystemVolumeView:NO];
            // 清空计数
            [self clearVolumeButtonRelatedFlag];
        }
    }
}

#pragma mark - ACCRecorderViewContainerItemsHideShowObserver

- (void)shouldItemsShow:(BOOL)show animated:(BOOL)animated
{
    [self showRecordButtonIfShould:show animated:NO];
}

#pragma mark - ACCRouterServiceSubscriber

- (ACCEditViewControllerInputData *)processedTargetVCInputDataFromData:(ACCEditViewControllerInputData *)data
{
    if (self.repository.repoContext.enableTakePictureDelayFrameOpt) {
        data.sourceDataSignal = [self.flowService captureStillImageSignal];
    }
    return data;
}

#pragma mark - redpacket
- (void)p_showFlowerRedpacketPropTipIfNeed
{
    if (!self.needShowFlowerRedpacketPropTipFlag ||
        ![ACCDeviceAuth hasCameraAndMicroPhoneAuth]) {
        return;
    }
    self.needShowFlowerRedpacketPropTipFlag = NO;
    
    NSString *tip = [ACCFlowerRedPacketHelper() flowerRedPacketShootToast];
    if (!ACC_isEmptyString(tip)) {
        [self.flowerRedpacketPropTipView showOnView:[self.viewContainer rootView] text:tip];
    }
}

- (BOOL)p_needShowFlowerRedpacketPropTip
{
    if (!ACC_isEmptyString(self.repository.repoRedPacket.routerCouponId) &&
        !self.repository.repoDraft.isDraft &&
        !self.repository.repoDraft.isBackUp) {
        
        NSString *tip = [ACCFlowerRedPacketHelper() flowerRedPacketShootToast];
        if (!ACC_isEmptyString(tip) &&
            [ACCFlowerRedPacketHelper() isFlowerRedPacketActivityOn]) {
            
            return YES;
        }
    }
    return NO;
}

- (ACCFlowerRedpacketPropTipView *)flowerRedpacketPropTipView
{
    if (!_flowerRedpacketPropTipView) {
        _flowerRedpacketPropTipView = [ACCFlowerRedpacketPropTipView new];
    }
    return _flowerRedpacketPropTipView;
}

#pragma mark - private

- (void)p_moveRecordButtonFromViewInteractionToRootView
{
    /// no need to call `removeFromSuperview` before calling `addSubview` to  mantain the UITouchEvents
    /// https://stackoverflow.com/questions/10031253/ios-transfer-ownership-of-uiview-while-touches-happening
    /// rootView -> interactionView -> preview -> propPanelView -> [captureButtonAnimationView]
    self.recordButton.frame = [self recordButtonFrame];
    self.recordShowTipButton.frame = [self recordButtonFrame];
    self.captureButtonAnimationView.frame = self.controller.root.view.frame;

    [self.controller.root.view addSubview:self.recordButton];
    [self.controller.root.view addSubview:self.recordShowTipButton];
    [self.controller.root.view addSubview:self.captureButtonAnimationView];

    if ([self.flowConfig enableLightningStyleRecordButton]) {
        [self.controller.root.view bringSubviewToFront:self.recordShowTipButton];
    }
}

- (void)p_completeImmediatlyWhenStopRecordIfNeeded
{
    [self startPlayerFirstFrameDurationIfNeed];
    if (![self shouldCompleteImmediatelyAfterStop]) {
        return;
    }
    
    if (self.cameraService.cameraControl.status == IESMMCameraStatusRecording) {
        [self.flowService pauseRecord];
    }
//    [self hideInteractionViewUntilDisappear];
    if (![self.flowService allowComplete]) {
        [self pauseRecordAfter];
    }
}

- (BOOL)p_isCurrentVCOnFrontWindow
{
    return self.controller.root.view.window == [self lastWindow];
}

#pragma mark - 记录拍摄流程
- (void)p_recordProcessCompleted {
    self.recordFlowProcess = RecordFlowProcessType_Completed;
}

- (BOOL)p_currentFlowProcessIsTakePhoto {
    return self.recordFlowProcess == RecordFlowProcessType_PhotoPhase;
}

- (UIWindow *)lastWindow
{
    NSArray *windows = [UIApplication sharedApplication].windows;
    for(UIWindow *window in [windows reverseObjectEnumerator]) {
        // 过滤掉键盘的window 并获取与屏幕大小一致的最后一个window
        if ([window isKindOfClass:[UIWindow class]] &&
            CGRectEqualToRect(window.bounds, [UIScreen mainScreen].bounds)) {
            if (window.hidden == YES ||
                [window isKindOfClass:NSClassFromString(@"UIRemoteKeyboardWindow")] ||
                [window isKindOfClass:NSClassFromString(@"UITextEffectsWindow")]) {
                continue;
            }
            return window;
        }
    }
    return [UIApplication sharedApplication].keyWindow;
}

- (void)hideInteractionViewUntilDisappear
{
    UIView *snapshot = [self.viewContainer.preview snapshotViewAfterScreenUpdates:NO];
    [self.viewContainer.rootView addSubview:snapshot];

    [[[self rac_signalForSelector:@selector(componentDidDisappear)].deliverOnMainThread take:1] subscribeNext:^(RACTuple *x) {
        [snapshot removeFromSuperview];
    }];

    // timeout
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [snapshot removeFromSuperview];
    });
}

- (void)pauseRecordAfter
{
    if (self.cameraService.cameraHasInit) {
        [self.cameraService.cameraControl cancelVideoRecord];
    }
    [self.flowService deleteAllSegments];
    
    id<ACCRepoKaraokeModelProtocol> repoKaraoke = [self.repository extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
    if (repoKaraoke.lightningStyleKaraoke) {
        return; // karaoke videos that less than 1s should not be treated as pic2video.
    }
    if (ACCConfigBool(kConfigBool_enable_lightning_pic_to_video_optimize) || [self.flowConfig enableTapToTakePictureRecordMode:self.switchModeService.currentRecordMode.isStoryStyleMode]) {
        // take photo
        //fix bug: 在0.15s内触摸拍摄结束时会同时出发两种逻辑，1.触发直接拍摄照片 2.拍摄流程结束后走到这里后又重复触发拍摄照片逻辑
        if (![self p_currentFlowProcessIsTakePhoto]) {
            self.cameraService.recorder.cameraMode = HTSCameraModePhoto;
            [self.flowService takePicture];
            self.cameraService.recorder.cameraMode = HTSCameraModeVideo;
        }
    }
}

- (ACCGroupedPredicate *)shouldShowCaptureAnimationView
{
    if (!_shouldShowCaptureAnimationView) {
        _shouldShowCaptureAnimationView = [[ACCGroupedPredicate alloc] init];
    }
    return _shouldShowCaptureAnimationView;
}

@end
