//
//  ACCRecorderAudioModeComponent.m
//  CameraClient-Pods-AwemeCore
//
//  Created by liujinze on 2021/10/15.
//

#import "ACCRecorderAudioModeComponent.h"
#import <HTSServiceKit/HTSMessageCenter.h>
#import <ByteDanceKit/BTDNetworkUtilities.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoPublishConfigModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreationKitArch/ACCRecordTrackService.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreationKitInfra/ACCRACWrapper.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreationKitComponents/ACCFilterService.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCRouterService.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CameraClientModel/AWEVideoRecordButtonType.h>
#import "ACCRecordFlowService.h"
#import "AWERepoContextModel.h"
#import "ACCRecordSubmodeViewModel.h"
#import "ACCRecordMode+MeteorMode.h"
#import "ACCRecorderAudioModeViewController.h"
#import "ACCRecorderAudioModeViewModel.h"
#import "ACCRecordViewControllerInputData.h"
#import "ACCPropViewModel.h"
#import "AWERepoMusicModel.h"
#import "AWERepoMVModel.h"
#import "AWERepoVideoInfoModel.h"
#import "ACCRecordFrameSamplingServiceProtocol.h"
#import "ACCRecorderBackgroundManagerProtocol.h"
#import "ACCEditViewControllerInputData.h"
#import "ACCRepoAudioModeModel.h"
#import "AWERepoCaptionModel.h"
#import "ACCRecordSelectMusicService.h"
#import "AWEAudioExport.h"
#import "ACCBubbleProtocol.h"
#import "ACCTapBubbleBackgroundView.h"
#import "AWERecorderTipsAndBubbleManager.h"

NSString *const kACCAudioModeGuideShownKey = @"kACCAudioModeGuideShownKey";

@interface ACCRecorderAudioModeComponent () <ACCRecordSwitchModeServiceSubscriber,ACCAudioModeRecordFlowDelegate,ACCCameraLifeCircleEvent,ACCRecordFlowServiceSubscriber,ACCRouterServiceSubscriber,ACCHideBubbleDelegate,ACCUserServiceMessage>

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCFilterService> filterService;
@property (nonatomic, strong) id<ACCRecordTrackService> trackService;
@property (nonatomic, strong) id<ACCRecordSelectMusicService> musicService;

@property (nonatomic, strong) ACCRecorderAudioModeViewController *audioModeViewController;
@property (nonatomic, strong) ACCRecorderAudioModeViewModel *viewModel;
@property (nonatomic, strong) ACCRecordSubmodeViewModel *submodeViewModel;
@property (nonatomic, strong) AWEVideoPublishViewModel *audioModePublishModel;
@property (nonatomic, strong) NSObject<ACCRecorderBackgroundSwitcherProtocol> *backgroundManager;
@property (nonatomic, strong) AWEAudioExport *audioExport;

@property (nonatomic, strong) id<ACCTextLoadingViewProtcol> loadingView;
@property (nonatomic, assign) CFTimeInterval exportTaskStartTime;
@property (nonatomic, strong) ACCTapBubbleBackgroundView *bubbleContainer;
@property (nonatomic, strong) UIView *guideBubble;

@property (nonatomic, assign) BOOL isExportingVideo;
@property (nonatomic, assign) BOOL hasPrefetchTemplate;

@end

@implementation ACCRecorderAudioModeComponent

IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, filterService, ACCFilterService)
IESAutoInject(self.serviceProvider, musicService, ACCRecordSelectMusicService)
IESAutoInject(self.serviceProvider, trackService, ACCRecordTrackService)

- (void)componentDidMount
{
    if (_backgroundManager == nil) {
        acc_dispatch_queue_async_safe(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.backgroundManager preloadInitBackground];
        });
    }
    REGISTER_MESSAGE(ACCUserServiceMessage, self);
}

- (void)componentWillAppear
{
    if (self.switchModeService.currentRecordMode.modeId != ACCRecordModeAudio ||
        self.repository.repoAudioMode.isAudioMode == NO) {
        return;
    }
    [self prepareEnterAudioMode];
}

- (void)componentDidAppear
{
    if (!self.hasPrefetchTemplate) {
        [self.viewModel prefetchAudioMVTemplate];
        [self.viewModel preFetchAvatarImage:^{
            if (self.audioModeViewController != nil) {
                [self.audioModeViewController updateUserAvatar:self.viewModel.userAvatarImage];
            }
        }];
        self.hasPrefetchTemplate = YES;
    }
}

- (void)componentDidUnmount{
    [self.viewModel onCleared];
    UNREGISTER_MESSAGE(ACCUserServiceMessage, self);
}

- (ACCServiceBinding *)serviceBinding{
    return ACCCreateServiceBinding(@protocol(ACCAudioModeService),
                                   self.viewModel);
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.switchModeService addSubscriber:self];
    [self.flowService addSubscriber:self];
    [self.cameraService addSubscriber:self];
    [self.cameraService.recorder addSubscriber:self];
    [IESAutoInline(serviceProvider, ACCRouterService) addSubscriber:self];
}

- (void)enterAudioWithMode:(ACCRecordMode *)audioMode
{
    if (self.audioModeViewController) {
        return;
    }
    if (self.viewContainer.switchModeContainerView) {
        @weakify(self);
        ACCRecorderAudioModeViewController *audioModeViewController = [[ACCRecorderAudioModeViewController alloc] initWithBackgroundManager:self.backgroundManager];
        audioModeViewController.delegate = self;
        audioModeViewController.layoutGuide = [self viewContainer].layoutManager.guide;
        audioModeViewController.recordMode = audioMode;
        [audioModeViewController updateUserAvatar:self.viewModel.userAvatarImage];
        audioModeViewController.close = ^{
            @strongify(self);
            [self closeRecorder];
        };
        audioModeViewController.audioViewDidApear = ^{
            @strongify(self);
            [self.viewModel send_audioModeVCDidAppearSignal];
        };
        audioModeViewController.changeColor = ^{
            [ACCTracker() trackEvent:@"change_backgroud_color" params:@{
                @"content_type" : @"audio",
                @"enter_from" : @"audio_shoot_page",
            }];
        };
        audioModeViewController.showGuide = ^(UIView * _Nonnull backgroundView) {
            @strongify(self);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self showAudioModeGuideOnView:backgroundView];
            });
        };
        audioModeViewController.removeGuideBubble = ^{
            @strongify(self);
            [self dismissGuideBubble];
        };
        self.audioModeViewController = audioModeViewController;
        [self.controller.root addChildViewController:self.audioModeViewController];
        self.audioModeViewController.view.alpha = 0;
        [self.viewContainer.modeSwitchView insertSubview:self.audioModeViewController.view belowSubview:self.viewContainer.switchModeContainerView];
        [UIView animateWithDuration:0.2 animations:^{
            self.audioModeViewController.view.alpha = 1;
        }];
        [self.audioModeViewController didMoveToParentViewController:self.controller.root];
        [self handleGestureEnterAudioMode];
    }
}

#pragma mark - bubble
- (void)bubbleBackgroundViewTap:(CGPoint)touchPoint{
    [self dismissGuideBubble];
}


- (void)showAudioModeGuideOnView:(UIView *)containView
{
    if ([ACCCache() boolForKey:kACCAudioModeGuideShownKey]) {
        return;
    }
    [containView addSubview:self.bubbleContainer];
    UIView *referredView = [self.viewContainer.layoutManager viewForType:ACCViewTypeSwitchSubmodeView];
    self.guideBubble = [ACCBubble() showBubble:@"长按或点按开始录制，最长可录制60s"
                                       forView:referredView
                               inContainerView:self.bubbleContainer
                                    fromAnchor:CGPointZero
                              anchorAdjustment:CGPointMake(0, -7)
                              cornerAdjustment:CGPointZero
                                     fixedSize:CGSizeMake(400, 42)
                                   inDirection:ACCBubbleDirectionUp
                              isDarkBackGround:YES completion:^{
                               
                       }];
    [ACCCache() setBool:YES forKey:kACCAudioModeGuideShownKey];
}

- (void)dismissGuideBubble
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [ACCBubble() removeBubble:self.guideBubble];
        self.guideBubble = nil;
        [self.bubbleContainer removeFromSuperview];
    });
}

- (void)exitAudioMode
{
    [self.audioModeViewController willMoveToParentViewController:nil];
    [self.audioModeViewController.view removeFromSuperview];
    [self.audioModeViewController removeFromParentViewController];
    self.audioModeViewController = nil;
    [self handleGestureExitAudioMode];
}

- (void)closeRecorder
{
    [ACCDraft() deleteDraftWithID:self.viewModel.inputData.publishModel.repoDraft.taskID];
    [self.controller close];
}

- (void)startRecord
{
    if (self.cameraService.recorder.isRecording) {
        return;
    }
    if (self.viewContainer.switchModeContainerView.isPanned) {
        //滑动模式时点击了录制
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.audioModeViewController.recordAnimationView stop];
        });
        return;
    }
    [self.flowService startRecordWithDelayRecord:NO];
}

#pragma mark - audio

- (void)prepareEnterAudioMode
{
    self.repository.repoAudioMode.isAudioMode = YES;
    [self.cameraService.cameraControl releaseAudioCapture];
    [self.cameraService.karaoke setRecorderAudioMode:VERecorderAudioModeOnlyAudio];
    [self.cameraService.cameraControl initAudioCapture:nil];
    [self.cameraService.cameraControl stopVideoAndAudioCapture];
    [self.cameraService.effect muteEffectPropBGM:YES];
    [self.musicService handleCancelMusic:self.repository.repoMusic.music muteBGM:YES trackInfo:nil];
    [[AWERecorderTipsAndBubbleManager shareInstance] removeBubbleAndHintIfNeeded];
}

- (void)prepareExitAudioMode
{
    self.repository.repoAudioMode.isAudioMode = NO;
    self.repository.repoContext.feedType = ACCFeedTypeGeneral;
    [self.cameraService.cameraControl releaseAudioCapture];
    [self.cameraService.karaoke setRecorderAudioMode:VERecorderAudioModeDefault];
    [self.cameraService.cameraControl initAudioCapture:nil];
    [self.cameraService.cameraControl stopVideoAndAudioCapture];
    if ([self.switchModeService isVideoCaptureMode]) {
        //因为都在didchange消息里去中心化的操作camera，有时序问题，此处对于切换至需要capture的模式不关闭videocapture
        [self.cameraService.cameraControl startVideoCapture];
    }
    if (!self.repository.repoMusic.music) {
        [self.cameraService.effect muteEffectPropBGM:NO];
    }
}

#pragma mark - Gesture

- (void)handleGestureEnterAudioMode
{
    self.filterService.panGestureRecognizerEnabled = NO;
    NSInteger tabCount = [self.switchModeService siblingsCountForRecordModeId:ACCRecordModeAudio];
    NSInteger tabIndex = [self.switchModeService getIndexForRecordModeId:ACCRecordModeAudio];
    if (tabIndex > 0){
        [self p_installSwipeGestureRecognizerWithDirection:UISwipeGestureRecognizerDirectionRight];
    }
    if (tabIndex + 1 < tabCount){
        [self p_installSwipeGestureRecognizerWithDirection:UISwipeGestureRecognizerDirectionLeft];
    }
}

- (void)p_installSwipeGestureRecognizerWithDirection:(UISwipeGestureRecognizerDirection)direction
{
    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self.submodeViewModel action:@selector(swipeSwitchSubmode:)];
    swipeGesture.direction = direction;
    swipeGesture.numberOfTouchesRequired = 1;
    swipeGesture.delegate = self.submodeViewModel;
    RAC(swipeGesture, enabled) = RACObserve(self.submodeViewModel, swipeGestureEnabled);
    [self.audioModeViewController.view addGestureRecognizer:swipeGesture];
}

- (void)handleGestureExitAudioMode
{
    if (![self.propViewModel.currentSticker isTypeAR] && ![self.propViewModel.currentSticker isTypeTouchGes]) {
        if (!(ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab) && ACCConfigBool(kConfigBool_horizontal_scroll_change_subtab))) {
            self.filterService.panGestureRecognizerEnabled = YES;
        }
    }
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    //willChange生命周期操作camera是不可靠的，现移到DidChange中
    if (mode.modeId == ACCRecordModeAudio) {
        [self prepareEnterAudioMode];
    } else if (oldMode.modeId == ACCRecordModeAudio) {
        [self prepareExitAudioMode];
    }
    
    //迅速滑动scrollView惯性切换模式时，在跨越语音文字双模式的场景下 childVC没有释放 导致在视频等tab下依然是语音模式界面
    BOOL needSilentReleaseAudioVC = (oldMode.modeId == ACCRecordModeAudio) && (mode.modeId == ACCRecordModeText);
    
    if (mode.modeId == ACCRecordModeAudio) {
        [self enterAudioWithMode:mode];
        mode.isMeteorMode = self.repository.repoContext.isMeteorMode;;
        [self.audioModeViewController.recordAnimationView switchToMode:mode];
    } else {
        //切换至其他tab
        if (oldMode.modeId == ACCRecordModeAudio){
            [self dismissGuideBubble];
        }
        if (!needSilentReleaseAudioVC && self.audioModeViewController != nil) {
            [self exitAudioMode];
        }
    }
}

- (void)silentReleaseAudioModeVC
{
    if (self.audioModeViewController == nil ||
        self.switchModeService.currentRecordMode.modeId == ACCRecordModeAudio) {
        return;
    }
    [UIApplication.sharedApplication beginIgnoringInteractionEvents];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self exitAudioMode];
        [UIApplication.sharedApplication endIgnoringInteractionEvents];
    });
}

#pragma mark - ACCAudioModeRecordFlowDelegate

- (BOOL)audioButtonAnimationShouldBegin:(id<ACCCaptureButtonAnimationProtocol>)animationView
{
    return [self.cameraService.cameraControl status] == HTSCameraStatusIdle;
}

- (void)audioButtonAnimationDidBegin:(id<ACCCaptureButtonAnimationProtocol>)animationView
{
    if ([self.cameraService.cameraControl status] == HTSCameraStatusIdle) {
        if (self.cameraService.recorder.cameraMode == HTSCameraModeVideo) {
            [self startRecord];
            [self.trackService trackRecordVideoEventWithCameraService:self.cameraService];
        }
    }
    if (self.flowService.currentDuration >= self.repository.repoContext.maxDuration) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [animationView stop];
        });
    }
}

- (void)audioButtonAnimationDidMoved:(CGPoint)touchPoint
{
    //audio mode no camera do nothing now
}

- (void)audioButtonAnimationDidEnd:(id<ACCCaptureButtonAnimationProtocol>)animationView
{
    [self.flowService pauseRecord];
    if (![self.flowService allowComplete] && self.flowService.currentDuration < 1.0) {
        if (self.cameraService.cameraHasInit) {
            [self.cameraService.cameraControl cancelVideoRecord];
        }
        [self.flowService deleteAllSegments];
        [ACCToast() show:@"录音时长不能小于1秒"];
        [self.audioModeViewController becomeNormalState];
    }
}

#pragma mark - ACCRouterServiceSubscriber

- (ACCEditViewControllerInputData *)processedTargetVCInputDataFromData:(ACCEditViewControllerInputData *)data
{
    if (self.switchModeService.currentRecordMode.modeId != ACCRecordModeAudio) {
        return data;
    }
    [data.publishModel.repoVideoInfo updateVideoData:self.viewModel.resultVideoData];
    data.publishModel.repoFlowControl.videoRecordButtonType = AWEVideoRecordButtonTypeAudio;
    data.publishModel.repoAudioMode.mvModel = self.viewModel.resultMVModel;
    data.publishModel.repoAudioMode.captions = self.viewModel.resultCaptions;
    data.publishModel.repoAudioMode.isAudioMode = YES;
    data.publishModel.repoContext.feedType = ACCFeedTypeAudioMode;
    data.publishModel.repoUploadInfo.toBeUploadedImage = self.viewModel.userAvatarImage;
    return data;
}

#pragma mark - Record Audio To MV Video Tasks

- (void)exportAudioToMVVideo
{
    if (self.isExportingVideo) {
        return;
    }
    self.isExportingVideo = YES;
    self.exportTaskStartTime = CACurrentMediaTime();
    self.loadingView = [ACCLoading() showWindowLoadingWithTitle:@"视频合成中..." animated:YES];
    NSString *folderPath = [AWEDraftUtils generateDraftFolderFromTaskId:self.repository.repoDraft.taskID];
    __block NSMutableArray<NSString *> *images = [NSMutableArray array];
    @weakify(self);
    [self.audioModeViewController getTemplateBackgroundImagePath:folderPath completion:^(NSString *BGImagePath, BOOL success) {
        if (!ACC_isEmptyString(BGImagePath) && success) {
            @strongify(self);
            [self.audioModeViewController getTemplateuserAvatarImagePath:folderPath completion:^(NSString *avatarImagePath, BOOL success) {
                @strongify(self);
                if (!ACC_isEmptyString(avatarImagePath) && success) {
                    [images acc_addObject:avatarImagePath];
                    [images acc_addObject:BGImagePath];
                    [self exportVideoDataTask:images];
                } else {
                    [self exportVideoFinishIfSuccess:NO withInfo:@{
                        @"error_code" : @(-1),
                    }];
                }
            }];
        } else {
            [self exportVideoFinishIfSuccess:NO withInfo:@{
                @"error_code" : @(-1),
            }];
        }
    }];
}

- (void)exportVideoDataTask:(NSMutableArray *)images
{
    @weakify(self);
    [self.viewModel generateAudioMVDataWithImages:images
                                       repository:self.repository
                                      draftFolder:self.repository.repoDraft.draftFolder
                                        videoData:self.repository.repoVideoInfo.video
                                       completion:^(ACCEditVideoData *videoData, NSError *error) {
        @strongify(self);
        if (error || videoData == nil) {
            [self exportVideoFinishIfSuccess:NO withInfo:@{
                @"error_code" : @(-2),
            }];
            return;
        }
        BOOL needAddAutoCaption = ACCConfigInt(kConfigInt_enable_voice_publish) == ACCRecordAudioModeTypeAtTextLeftWithCaption || ACCConfigInt(kConfigInt_enable_voice_publish) == ACCRecordAudioModeTypeAtTextRightWithCaption;
        if (needAddAutoCaption) {
            [self videoAddcaptionTask];
        } else {
            NSInteger duration = (CACurrentMediaTime() - self.exportTaskStartTime) * 1000;
            [self exportVideoFinishIfSuccess:YES withInfo:@{
                @"time_cost_ms_total" : @(duration),
            }];
        }
    }];
}

- (void)videoAddcaptionTask
{
    CFTimeInterval captionTaskStartTime = CACurrentMediaTime();
    @weakify(self);
    void(^startUploadAudioBlock)(NSURL *url, NSError *error) = ^(NSURL *url, NSError *error) {
        //第二步 上传url换captions
        @strongify(self);
        if (error || !url || !BTDNetworkConnected()) {
            NSInteger totalTaskDuration = (CACurrentMediaTime() - self.exportTaskStartTime) * 1000;
            [self exportVideoFinishIfSuccess:YES withInfo:@{
                @"time_cost_ms_total" : @(totalTaskDuration),
                @"error_code" : @(-3),
            }];
            return;
        }
        [self.repository.repoCaption queryCaptionsWithUrl:url completion:^(NSArray<AWEStudioCaptionModel *> *captionsArray, NSError *error) {
            @strongify(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.viewModel updateAudioCaptions:[[NSMutableArray alloc] initWithArray:captionsArray]];
                NSInteger totalTaskDuration = (CACurrentMediaTime() - self.exportTaskStartTime) * 1000;
                NSInteger captionTaskDuration = (CACurrentMediaTime() - captionTaskStartTime) * 1000;
                [self exportVideoFinishIfSuccess:YES withInfo:@{
                    @"time_cost_ms_total" : @(totalTaskDuration),
                    @"time_cost_ms_caption" : @(captionTaskDuration),
                }];
            });
        }];
    };
    
    //第一步 提取videodata音频内容 到url
    //清除字幕
    self.audioExport = nil;
    self.repository.repoCaption.tosKey = nil;
    [self.repository.repoVideoInfo updateVideoData:self.viewModel.resultVideoData];
    self.audioExport = [[AWEAudioExport alloc] initWithPublishModel:self.repository];
    [self.audioExport exportAudioWithCompletion:^(NSURL * _Nonnull url, NSError * _Nonnull error, AVAssetExportSessionStatus status) {
        ACCBLOCK_INVOKE(startUploadAudioBlock, url, error);
    }];
}

- (void)exportVideoFinishIfSuccess:(BOOL)success withInfo:(nullable NSDictionary *)info
{
    if (!success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.loadingView dismissWithAnimated:YES];
        });
        [ACCToast() showToast:@"视频合成失败，请重试"];
        self.isExportingVideo = NO;
    } else {
        acc_dispatch_main_async_safe(^{
            [self.flowService willEnterNextPageWithMode:self.switchModeService.currentRecordMode];
            [self.controller controllerTaskFinished];
            [self.loadingView dismissWithAnimated:YES];
            [self.flowService didEnterNextPageWithMode:self.switchModeService.currentRecordMode];
            self.isExportingVideo = NO;
        });
    }
    //monitor
    BOOL needAddAutoCaption = ACCConfigInt(kConfigInt_enable_voice_publish) == ACCRecordAudioModeTypeAtTextLeftWithCaption || ACCConfigInt(kConfigInt_enable_voice_publish) == ACCRecordAudioModeTypeAtTextRightWithCaption;
    NSMutableDictionary *extraParams = [NSMutableDictionary dictionaryWithDictionary:info];
    extraParams[@"audio_duration"] = @((NSInteger)(self.repository.repoVideoInfo.video.totalBGAudioDuration * 1000 + 0.5));
    extraParams[@"has_auto_caption"] = @(needAddAutoCaption);
    [ACCMonitor() trackService:@"aweme_audio_mode_generate_mv_rate"
                        status:success ? 0 : 1
                         extra:extraParams];
}

#pragma mark - ACCRecordFlowServiceSubscriber

- (void)flowServiceStateDidChanged:(ACCRecordFlowState)state preState:(ACCRecordFlowState)preState
{
    if (self.switchModeService.currentRecordMode.modeId != ACCRecordModeAudio) {
        return;
    }
    if (ACCRecordFlowStateStart == state) {
        [self dismissGuideBubble];
        [self.audioModeViewController becomeRecordingState];
    } else if (ACCRecordFlowStatePause == state) {
        BOOL isRecording = ([self.cameraService.cameraControl status] == IESMMCameraStatusRecording) || (self.flowService.currentDuration > 0);
        if (![self.flowService allowComplete] && isRecording && self.flowService.currentDuration < 1.0) {
            if (self.cameraService.cameraHasInit) {
                [self.cameraService.cameraControl cancelVideoRecord];
            }
            [self.flowService deleteAllSegments];
            [self.audioModeViewController becomeNormalState];
            [self.audioModeViewController.recordAnimationView stop];
        }
    } else if (ACCRecordFlowStateStop == state) {
        [self.audioModeViewController becomeNormalState];
        [self.audioModeViewController.recordAnimationView stop];
    } else if (ACCRecordFlowStateFinishExport == state) {
        [self.audioModeViewController becomeNormalState];
        [self exportAudioToMVVideo];
    }
}

- (void)flowServiceDidMarkDuration:(CGFloat)duration
{
    [self p_updateProgress];
}

- (void)flowServiceDidRemoveLastSegment:(BOOL)isReactHasMerge
{
    [self p_updateProgress];
    // 清除录制抽帧结果
    let samplingService = IESAutoInline(self.serviceProvider, ACCRecordFrameSamplingServiceProtocol);
    NSAssert([samplingService respondsToSelector:@selector(removeAllFrames)], @"-[%@ removeAllFrames] not found", samplingService);
    [samplingService removeAllFrames];
    
}

- (void)flowServiceDidRemoveAllSegment
{
    [self p_updateProgress];
    // 清除录制抽帧结果
    let samplingService = IESAutoInline(self.serviceProvider, ACCRecordFrameSamplingServiceProtocol);
    NSAssert([samplingService respondsToSelector:@selector(removeAllFrames)], @"-[%@ removeAllFrames] not found", samplingService);
    [samplingService removeAllFrames];
    
}

- (void)flowServiceDurationHasRestored
{
    [self p_updateProgress];
}

- (void)flowServiceDidUpdateDuration:(CGFloat)duration
{
    [self updateProgress];
}

- (void)updateProgress
{
    double progress = ((NSTimeInterval)self.flowService.currentDuration) / self.repository.repoContext.maxDuration;
    if (progress >= 1) {
        [self.recordProgressView setProgress:1 duration:self.flowService.currentDuration animated:NO];
    } else {
        BOOL animation = progress < self.recordProgressView.progress;
        [self.recordProgressView setProgress:progress duration:self.flowService.currentDuration animated:animation];
    }
}

- (void)p_updateProgress
{
    [self.recordProgressView updateViewWithTimeSegments:self.flowService.markedTimes
                                              totalTime:self.repository.repoContext.maxDuration];
}

#pragma mark - userSerivceMessage

- (void)didFinishLogin{
    [self.viewModel preFetchAvatarImage:^{
        if (self.audioModeViewController != nil) {
            [self.audioModeViewController updateUserAvatar:self.viewModel.userAvatarImage];
        }
    }];
}

- (void)didFinishLogout{
    [self.viewModel preFetchAvatarImage:^{
        if (self.audioModeViewController != nil) {
            [self.audioModeViewController updateUserAvatar:self.viewModel.userAvatarImage];
        }
    }];
}

#pragma mark - getter

- (ACCRecorderAudioModeViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self.modelFactory createViewModel:ACCRecorderAudioModeViewModel.class];
    }
    return _viewModel;
}

- (NSObject<ACCRecorderBackgroundSwitcherProtocol> *)backgroundManager
{
    if (!_backgroundManager) {
        _backgroundManager = [IESAutoInline(ACCBaseServiceProvider(), ACCRecorderBackgroundManagerProtocol) getACCBackgroundSwitcherWith:ACCBackgroundSwitcherSceneAudioMode];
    }
    return _backgroundManager;
}

- (ACCPropViewModel *)propViewModel
{
    return [self getViewModel:[ACCPropViewModel class]];
}

- (ACCRecordSubmodeViewModel *)submodeViewModel
{
    return [self getViewModel:[ACCRecordSubmodeViewModel class]];
}

- (ACCLightningRecordButton *)recordProgressView
{
    return self.audioModeViewController.recordAnimationView.animatedRecordButton;
}

- (AWEAudioExport *)audioExport
{
    if (!_audioExport) {
        _audioExport = [[AWEAudioExport alloc] initWithPublishModel:self.repository];
    }
    
    return _audioExport;
}

- (ACCTapBubbleBackgroundView *)bubbleContainer{
    if (!_bubbleContainer) {
        _bubbleContainer = [[ACCTapBubbleBackgroundView alloc] initWithFrame:self.viewContainer.interactionView.bounds];
        _bubbleContainer.delegate = self;
    }
    return _bubbleContainer;
}

@end
