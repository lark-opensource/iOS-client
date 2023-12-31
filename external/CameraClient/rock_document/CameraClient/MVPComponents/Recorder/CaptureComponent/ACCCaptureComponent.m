//
//  ACCCaptureComponent.m
//  Pods
//
//  Created by guochenxiang on 2019/7/28.
//

#import "AWERepoVideoInfoModel.h"
#import "AWERepoMusicModel.h"
#import "AWERepoPropModel.h"
#import "AWERepoContextModel.h"
#import "ACCCaptureComponent.h"

#import <EffectSDK_iOS/MessageDefine.h>
#import <AVFoundation/AVCaptureSessionPreset.h>

#import <CreationKitArch/AWEStudioMeasureManager.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import "ACCPropViewModel.h"
#import "AWEVideoRecordOutputParameter.h"
#import "ACCCaptureViewModel.h"
#import <CreationKitInfra/ACCDeviceAuth.h>
#import "ACCRecordFrameSamplingServiceProtocol.h"
#import <CreationKitRTProtocol/ACCCameraControlEvent.h>
#import "ACCRecordTrackHelper.h"
#import "AWECameraPreviewContainerView.h"
#import "AWEXScreenAdaptManager.h"
#import "ACCRecordFlowService.h"
#import <CreationKitArch/ACCRecordTrackService.h>
#import <CreationKitComponents/ACCBeautyService.h>
#import <CreationKitComponents/ACCFilterService.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import "ACCRecordARService.h"
#import "ACCRecordAuthService.h"
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>
#import "ACCRepoSecurityInfoModel.h"
#import <CreationKitArch/ACCRepoDraftModel.h>
#import "ACCConfigKeyDefines.h"
#import "AWERecorderTipsAndBubbleManager.h"
#import <CameraClient/ACCSecurityFramesSaver.h>
#import "ACCRecordPropService.h"
#import "UIImage+GaussianBlur.h"
#import <CameraClient/ACCRecordMode+LiteTheme.h>
#import "ACCRepoAudioModeModel.h"

static const NSInteger kEffectToastMsgId = 0x29;

@interface ACCCaptureComponent () <ACCRecordConfigAudioHandler, ACCCameraLifeCircleEvent, ACCCameraControlEvent, ACCEffectEvent, CAAnimationDelegate, ACCRecordSwitchModeServiceSubscriber, ACCRecordFlowServiceSubscriber
>

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCRecordTrackService> trackService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCRecordARService> arService;
@property (nonatomic, strong) id<ACCRecordAuthService> authService;
@property (nonatomic, strong) id<ACCBeautyService> beautyService;
@property (nonatomic, strong) id<ACCFilterService> filterService;
@property (nonatomic, strong) id<ACCRecordPropService> propService;

@property (nonatomic, strong, readwrite) ACCGroupedPredicate<id, id> *startVideoCaptureOnWillAppearPredicate;
@property (nonatomic, strong, readwrite) ACCGroupedPredicate<id, id> *startAudioCaptureOnWillAppearPredicate;
@property (nonatomic, strong, readwrite) ACCGroupedPredicate<id, id> *startVideoCaptureOnAuthorizedPredicate;
@property (nonatomic, strong, readwrite) ACCGroupedPredicate<id, id> *startAudioCaptureOnAuthorizedPredicate;
@property (nonatomic, strong, readwrite) ACCGroupedPredicate<id, id> *shouldStartSamplingPredicate;

@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, strong) ACCCaptureViewModel *viewModel;
@property (nonatomic, assign) BOOL hasReleasePreviewWhenMemoryWarning;//YES表示收到过内存警告，并且释放了preview。
@property (nonatomic, strong) UIView<ACCTextLoadingViewProtcol> *loadingView;
@property (nonatomic, strong) UIView *blockView;
@property (nonatomic, weak) UIImageView *lastFrameImageView;

@end

@implementation ACCCaptureComponent


IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, trackService, ACCRecordTrackService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, authService, ACCRecordAuthService)
IESAutoInject(self.serviceProvider, beautyService, ACCBeautyService)
IESAutoInject(self.serviceProvider, filterService, ACCFilterService)

IESOptionalInject(self.serviceProvider, arService, ACCRecordARService)

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCCaptureService), self.viewModel);
}


#pragma mark - ACCComponentProtocol

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [IESAutoInline(self.serviceProvider, ACCRecordConfigService) registAudioHandler:self];
    [self.cameraService addSubscriber:self];
    [self.cameraService.cameraControl addSubscriber:self];
    [self.cameraService.message addSubscriber:self];
    [self.switchModeService addSubscriber:self];
    [self.flowService addSubscriber:self];
    self.propService = IESAutoInline(serviceProvider, ACCRecordPropService);
}

- (void)componentReceiveMemoryWarning
{
    [self p_releasePreviewWhenMemoryWarning];
}

- (void)onAppWillEnterForeground:(NSNotification *)notification {
    if (!self.cameraService.cameraHasInit && [ACCDeviceAuth isCameraAuth]) {
        [self.cameraService buildCameraIfNeeded];
    }
}

#pragma mark - ACCFeatureComponent

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    if ([self.controller enableFirstRenderOptimize]) {
        return ACCFeatureComponentLoadPhaseBeforeFirstRender;
    } else {
        return ACCFeatureComponentLoadPhaseEager;
    }
}

- (void)componentDidMount
{
    self.isFirstAppear = YES;
    if ([ACCDeviceAuth isCameraAuth]) {
        [self.cameraService buildCameraIfNeeded];
        if ([self.controller enableFirstRenderOptimize] || ACCConfigBool(kConfigBool_enable_start_capture_in_advance)) {
            [self startVideoCaptureIfCheckAPPState:NO];
        }
    }
    
    [self p_bindViewModels];
    
    let samplingService = IESAutoInline(self.serviceProvider, ACCRecordFrameSamplingServiceProtocol);
    [samplingService configCameraService:self.cameraService];

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onAppWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [self addLastCaptureFrameIfNeeded];
}

- (void)componentWillUnmount
{
    [self trackPreviewPerformanceWithNextAction:@"exit_record_page"];
}

- (void)componentDidUnmount
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopCameraCapture];
}

- (void)componentWillAppear
{
    [self.flowService cancelDelayFetchIfNeeded];
    if (self.viewModel.inputData.publishModel.repoVideoInfo.lynxChannel.length > 0) {
        return;
    }
    if (self.switchModeService.currentRecordMode.modeId != ACCRecordModeLive) {
        if (self.hasReleasePreviewWhenMemoryWarning) {
            self.hasReleasePreviewWhenMemoryWarning = NO;
            [self.cameraService.cameraControl resumeHTSGLPreviewWithView:self.cameraService.cameraPreviewView];
        }

        if (!self.repository.repoDuet.isDuet) {
            // duet senario can't change captureSize
            [self p_resetCameraOutputSizeIfNeeded:nil];
        }
        [self.cameraService.cameraControl ignoreNotification:NO];
        BOOL checkAppState = !self.isFirstAppear;
        if ([self.startVideoCaptureOnWillAppearPredicate evaluate]) {
            [self startVideoCaptureIfCheckAPPState:checkAppState];
        }
        if ([self.startAudioCaptureOnWillAppearPredicate evaluate]) {
            [self startAudioCapture];
        }
    }
}

- (void)componentDidAppear
{
    if (self.cameraService.cameraHasInit) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //when a viewcontroller pop without animation, this behavior may block pop viewcontroller's dismiss action
            //从编辑页回到拍摄页的时候，如果是无动画返回的，didappear调用的会比较早，下面这个代码会block600ms的主线程，导致600ms内没有重绘，效果上就像是编辑页的返回卡顿了一样
            [self.cameraService.effect startEffectPropBGM:IESEffectBGMTypeNormal];
        });
    }

    if (self.isFirstAppear) {
        self.isFirstAppear = NO;
        [self p_bindViewModelObserver];
    }
}

- (void)componentWillDisappear
{
    [self.cameraService.cameraControl ignoreNotification:YES];
    @weakify(self);
    void(^handleCameraClose)(void) = ^(void) {
        @strongify(self);
        if (self.cameraService.cameraHasInit) {
            if (!ACC_FLOAT_EQUAL_ZERO(self.cameraService.cameraControl.zoomFactor - 1.0)) {
                if (self.cameraService.cameraControl.supprotZoom) {
                    [self resetCameraZoomFactor];
                }
            }
        }
        [self stopCameraCapture];
    };
    if (self.repository.repoContext.enableTakePictureDelayFrameOpt && self.flowService.captureStillImageSignal) {
        [self.flowService.captureStillImageSignal subscribeCompleted:^{
            handleCameraClose();
        }];
    } else {
        handleCameraClose();
    }
    [self.cameraService.effect pauseEffectPropBGM:IESEffectBGMTypeNormal];
}

- (void)p_bindViewModels
{
    //subscribe signals
    //ar
    @weakify(self);
    [self.arService.inputTextChangeSignal subscribeNext:^(ACCInputTextChangetPack _Nullable x) {
        @strongify(self);
        RACTupleUnpack(NSString *text, IESMMEffectMessage *messageModel) = x;
        [self.cameraService.effect setEffectText:text messageModel:messageModel];
    }];
    [self.arService.inputCompleteSignal subscribeNext:^(NSNumber *x) {
        @strongify(self);
        [self.cameraService.effect setInputKeyboardHide:x.boolValue];
    }];
    
    [self.authService.passCheckAuthSignal.deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        //必须相机授权通过才去 createCamera，如果只是授权麦克风就走 createCamera，在 createCamera 里又会请求相机授权，导致授权页面消不掉
        if ((x.integerValue & ACCRecordAuthComponentCameraAuthed)) {
            [self.cameraService buildCameraIfNeeded];
            if ([self.startVideoCaptureOnAuthorizedPredicate evaluate]) {
                [self startVideoCaptureIfCheckAPPState:NO];
            }
            if ((x.integerValue & ACCRecordAuthComponentMicAuthed) && [self.startAudioCaptureOnAuthorizedPredicate evaluate]) {
                [self startAudioCapture];
            }
        }
    }];
    
    self.viewModel.loadingHandler = ^(BOOL close, NSString * _Nullable text) {
        @strongify(self);
        if (close) {
            [self.loadingView dismissWithAnimated:NO];
            self.loadingView = nil;
        } else {
            self.loadingView = [ACCLoading() showTextLoadingOnView:self.viewContainer.rootView title:text animated:YES];
        }
    };
    
    self.viewModel.toastHandler = ^(NSString * _Nonnull text) {
        [ACCToast() show:text];
    };
    
    self.viewModel.sendMessageHandler = ^(IESMMEffectMessage * msg) {
        @strongify(self);
        [self.cameraService.message sendMessageToEffect:msg];
    };
}

- (void)p_bindViewModelObserver
{
    @weakify(self);
    [[[RACObserve(self.cameraService.cameraControl, currentCameraPosition) distinctUntilChanged] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        if (!self.cameraService.cameraHasInit) {
            return;
        }

        if (ACCConfigBool(kConfigBool_enable_lens_sharpen)) {
            self.cameraService.cameraControl.currentCameraPosition == AVCaptureDevicePositionBack ? [self startFaceDetect] : [self stopFaceDetect];
        }

        if (!ACC_FLOAT_EQUAL_ZERO(self.cameraService.cameraControl.zoomFactor - 1.0)) {
            if (self.cameraService.cameraControl.supprotZoom) {
                [self resetCameraZoomFactor];
            }
        }
    }];
    
    if (ACCViewFrameOptimizeContains(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize), ACCViewFrameOptimizeFullDisplay)) {
        [[[RACObserve(self.cameraService.cameraControl, outputSize) ignore:nil] deliverOnMainThread] subscribeNext:^(NSValue * _Nullable x) {
            @strongify(self);
            IESPreviewModeType previewType = [AWEXScreenAdaptManager aspectFillForRatio:[x CGSizeValue] isVR:NO] ? IESPreviewModePreserveAspectRatioAndFill : IESPreviewModePreserveAspectRatio;
            [self.cameraService.cameraControl setPreviewModeType:previewType];
        }];
    }
}

#pragma mark - private methods

- (void)trackPreviewPerformanceWithNextAction:(NSString *)nextAction
{

    NSString *resolution = [NSString stringWithFormat:@"%@*%@",@(self.cameraService.config.outputSize.width),@(self.cameraService.config.outputSize.height)];
    NSInteger beautyStatus = [self.beautyService isUsingBeauty] ? 1 : 0;
    NSMutableDictionary *info = [@{
        @"beauty_status":@(beautyStatus),
        @"resolution":resolution,
        @"effect_id":self.propViewModel.currentSticker.effectIdentifier ?:@"",
        @"filter_id":[self filterService].currentFilter.effectIdentifier ?: ([self filterService].hasDeselectionBeenMadeRecently ? @"-1" : @""),
        @"appstate" : @(self.viewModel.inputData.firstCaptureAppState)
    } mutableCopy];
    if ([self.cameraService.cameraControl currentExposureBias] != 0) {
        info[@"exposure_values"] = @([self.cameraService.cameraControl currentExposureBias]);
    }
    [self.trackService trackPreviewPerformanceWithInfo:info nextAction:nextAction];
}

- (void)p_resetCameraOutputSizeIfNeeded:(dispatch_block_t)completion
{
    CGSize preferredSize = [AWEVideoRecordOutputParameter expectedMaxRecordWriteSizeForPublishModel:self.repository];
    if (!CGSizeEqualToSize([self.cameraService.cameraControl captureSize], preferredSize)) {
        AWELogToolInfo2(@"resolution", AWELogToolTagRecord, @"resetCameraOutputSize begin. camera captureSize:%@ => %@, camera preset: %@, camera output size: %@, publishModel video size: %@, maxRecordWriteSize: %@", NSStringFromCGSize([self.cameraService.cameraControl captureSize]),
                        NSStringFromCGSize(preferredSize),  self.cameraService.config.capturePreset,NSStringFromCGSize(self.cameraService.config.outputSize), NSStringFromCGSize(self.repository.repoVideoInfo.video.transParam.videoSize), NSStringFromCGSize([AWEVideoRecordOutputParameter maximumRecordWriteSize]));
        @weakify(self);
        [self.cameraService.cameraControl resetCapturePreferredSize:preferredSize then:^{
            @strongify(self);
            BOOL resetSuccess = CGSizeEqualToSize([self.cameraService.cameraControl captureSize], preferredSize);
            NSString *(^alog)(void) = ^ {
                @strongify(self);
                return [NSString stringWithFormat:@"resetCameraOutputSize end. camera captureSize:%@, camera preset: %@, camera output size: %@, publishModel video size: %@", NSStringFromCGSize([self.cameraService.cameraControl captureSize]), self.cameraService.config.capturePreset,NSStringFromCGSize(self.cameraService.config.outputSize), NSStringFromCGSize(self.repository.repoVideoInfo.video.transParam.videoSize)];
            };
            if (resetSuccess) {
                [AWEVideoRecordOutputParameter updatePublishViewModelOutputParametersWith:self.viewModel.inputData.publishModel];
                AWELogToolInfo2(@"resolution", AWELogToolTagRecord, @"%@", alog());
            } else {
                AWELogToolError2(@"resolution", AWELogToolTagRecord, @"%@", alog());
            }
            ACCBLOCK_INVOKE(completion);
        }];
    } else {
        AWELogToolInfo2(@"resolution", AWELogToolTagRecord, @"captureSize matches. camera captureSize:%@, camera preset: %@, camera output size: %@, publishModel video size: %@, maxRecordWriteSize: %@", NSStringFromCGSize([self.cameraService.cameraControl captureSize]), self.cameraService.config.capturePreset,
                        NSStringFromCGSize(self.cameraService.config.outputSize), NSStringFromCGSize(self.repository.repoVideoInfo.video.transParam.videoSize), NSStringFromCGSize([AWEVideoRecordOutputParameter maximumRecordWriteSize]));
        ACCBLOCK_INVOKE(completion);
    }
}

#pragma mark - audio and video

- (void)p_handleAVAuth
{
    BOOL isVoiceRecognition = [self.propService.prop isTypeVoiceRecognization];//应用音量道具的时候 处理过audio的开关 这里对已应用的场景保持不动
    if (self.switchModeService.currentRecordMode.isPhoto && !isVoiceRecognition) {
        [self.cameraService.cameraControl stopAudioCapture];
    }
    if ((self.switchModeService.currentRecordMode.isVideo && self.isMounted) ||
        self.switchModeService.currentRecordMode.isPhoto){
        [self.cameraService.cameraControl startVideoCapture];
    }
}

- (void)stopCameraCapture {
    // duetLayoutGreenScreen: call the stopVideoCapture: and releaseAudioCapture: here
    if ([self.viewModel.inputData.publishModel.repoDuet.duetLayout isEqualToString:@"green_screen"] && self.viewModel.inputData.publishModel.repoDuet.isDuet) {
        [self.cameraService.cameraControl stopVideoCapture];
        [self.cameraService.cameraControl releaseAudioCapture];
    }
    // MARK: @xiafeiyu It's expected to release audio capture on leaving record page. In order to control the potential impact of this modification, We use the karaoke's ab to control it, which will be turned on in 17.0.0. If there's no user feedback until 17.5.0, we would be confident to delete this `if`.
    if (ACCConfigBool(kConfigBool_karaoke_enabled)) {
        if (self.repository.repoAudioMode.isAudioMode) {
            [self.cameraService.karaoke setRecorderAudioMode:VERecorderAudioModeOnlyAudio];
        } else {
            [self.cameraService.karaoke setRecorderAudioMode:VERecorderAudioModeDefault]; // move `setRecorderAudioMode` to RecorderProtocol
        }
        [self.cameraService.cameraControl releaseAudioCapture];
    }
    BOOL enableAsyncStop = ACCConfigEnum(kConfigInt_record_to_edit_optimize_type, ACCRecordToEditOptimizeType) & ACCRecordToEditOptimizeTypeStopCapture;
    if (self.flowService.hasStopCaptureWhenEnterEdit && !enableAsyncStop) {
        self.flowService.hasStopCaptureWhenEnterEdit = NO;
        return;
    }
    //直播为了实现预览页至直播间无缝切换不停止，其他页面需要停止，不停止容易OOM
    if (self.switchModeService.currentRecordMode.modeId != ACCRecordModeLive) {
        /** @xiafeiyu Previouslly we stop audio capture only if `[ACCAudioAuthUtils shouldStartAudio:self.repository]` returns YES. For some weird reason, the condition becomes false when voice recognization props are used (e.g 922884) , leading to unclosed audio capture. See slardar issue http://t.wtturl.cn/ewBYhYj/ .
         * Although the bug remains unveiled, it stands to reason that audio capture should be closed immediately when users have left recording page. We made this change on alpha/17.2.0.
         @code
             [self.cameraService.cameraControl stopVideoCapture];
             if ([ACCAudioAuthUtils shouldStartAudio:self.repository]) {
                 [self.cameraService.cameraControl stopAudioCapture];
             }
         */
        [self.cameraService.cameraControl stopVideoAndAudioCapture];
    }
}

- (void)startVideoCaptureIfCheckAPPState:(BOOL)checkAPPState
{
    if ([self.switchModeService isVideoCaptureMode]) {
        [self.cameraService.cameraControl startVideoCaptureIfCheckAppStatus:checkAPPState];
        [self.viewModel.inputData recordCurrentApplicateState];
    }
}

- (void)startAudioCapture {
    if ([ACCDeviceAuth isMicroPhoneAuth]) {
        [self.cameraService.cameraControl initAudioCapture:^{}];
        AWELogToolInfo(AWELogToolTagRecord, @"initAudioCapture called, start audio capture timing optimize case 1");
    }
}

#pragma mark - ACCCameraLifeCircleEvent

- (void)cameraService:(id<ACCCameraService>)cameraService pauseRecordWithError:(NSError *)error {
    [self stopSampling];
}

- (void)cameraService:(id<ACCCameraService>)cameraService startRecordWithError:(NSError *)error {
    if (error) {
        AWELogToolError(AWELogToolTagRecord, @"Start record failed. %@", error);
    }
    [self startSamplingIfNeeded];
    [self trackPreviewPerformanceWithNextAction:@"start_record"];
}

- (void)cameraService:(id<ACCCameraService>)cameraService stopVideoCaptureWithError:(NSError *)error {
    [self stopSampling];
    if (ACCConfigBool(kConfigBool_enable_lens_sharpen)) {
        [self stopFaceDetect];
    }
}

- (void)cameraService:(id<ACCCameraService>)cameraService didReachMaxTimeVideoRecordWithError:(NSError *)error {
    [self stopSampling];
    [AWEStudioMeasureManager sharedMeasureManager].pauseRecordTime = CACurrentMediaTime();
}

- (void)cameraService:(id<ACCCameraService>)cameraService startVideoCaptureWithError:(NSError *)error {
    if (error) {
        [self p_shouldBlockInteraction:YES];
        AWELogToolError(AWELogToolTagRecord, @"Start VideoCapture failed. %@", error);
    } else {
        [self p_shouldBlockInteraction:NO];
        if (ACCConfigBool(kConfigBool_enable_lens_sharpen) &&
            self.cameraService.cameraControl.currentCameraPosition == AVCaptureDevicePositionBack) {
            [self startFaceDetect];
        }
    }
}

- (void)onCameraFirstFrameDidRender:(id<ACCCameraService>)cameraService {
    [self removeLastFrameWhenCaptureStart];
}

- (void)p_shouldBlockInteraction:(BOOL)blocked
{
    if (blocked) {
        if (!self.blockView) {
            self.blockView = [[UIView alloc] initWithFrame:self.viewContainer.rootView.bounds];
            self.blockView.userInteractionEnabled = YES;
            self.blockView.backgroundColor = [UIColor clearColor];
            self.blockView.autoresizingMask =
            UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        }
        [self.viewContainer.rootView addSubview:self.blockView];
    }
    else {
        [self.blockView removeFromSuperview];
    }
}

#pragma mark - samplingService

- (void)startSamplingIfNeeded {
    // 开启抽帧服务
    if (![self.shouldStartSamplingPredicate evaluate]) {
        return;
    }
    let samplingService = IESAutoInline(self.serviceProvider, ACCRecordFrameSamplingServiceProtocol);
    if (!self.repository.repoReshoot.isReshoot) {
        NSAssert([samplingService respondsToSelector:@selector(startWithCameraService:timeInterval:)], @"-[%@ startWithCameraService] not found", samplingService);
    }
    [samplingService startWithCameraService:self.cameraService timeInterval:2.f];
}

- (void)stopSampling {
    // 停止抽帧服务
    let samplingService = IESAutoInline(self.serviceProvider, ACCRecordFrameSamplingServiceProtocol);
    if (!self.repository.repoReshoot.isReshoot) {
        NSAssert([samplingService respondsToSelector:@selector(stop)], @"-[%@ stop] not found", samplingService);
    }
    [samplingService stop];
}

#pragma mark - capture last frame

- (void)addLastCaptureFrameIfNeeded {
    if (!ACCConfigBool(kConfigBool_enable_cover_frame_when_start_capture)) {
        return;
    }
    BOOL shouldShow = self.isFirstAppear || self.mounted;
    if (self.lastFrameImageView || self.flowService.exporting || !shouldShow) {
        return;
    }
    UIImage *frame = [self.cameraService.cameraControl captureFrame];
    if (!frame) {
        return;
    }
    UIImageView *frameView = [[UIImageView alloc] init];
    frameView.contentMode = UIViewContentModeScaleAspectFill;
    frameView.frame = self.cameraService.cameraPreviewView.bounds;
    self.lastFrameImageView = frameView;
    
    void(^addFrame)(void) = ^(){
        UIImage *blurImage = [frame acc_applyGaussianBlur:10.f];
        acc_infra_main_async_safe(^{
            frameView.image = blurImage;
            [self.viewContainer.preview insertSubview:frameView aboveSubview:self.cameraService.cameraPreviewView];
            if (!self.lastFrameImageView || !self.lastFrameImageView.superview) {
                [self p_removeLastFrameView:frameView];
            }
        });
    };
    
    if (self.repository.repoDraft.isBackUp || self.repository.repoDraft.isDraft) {
        addFrame();
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            addFrame();
        });
    }
}

- (void)removeLastFrameWhenCaptureStart {
    if (!self.lastFrameImageView) {
        return;
    }
    [self.cameraService.cameraControl clearCaptureFrame];
    UIView *frameView = self.lastFrameImageView;
    self.lastFrameImageView = nil;
    [self p_removeLastFrameView:frameView];
}

- (void)p_removeLastFrameView:(UIView *)view {
    if (!view.superview) {
        return;
    }
    [UIView animateWithDuration:0.5f animations:^{
        view.alpha = 0.f;
    } completion:^(BOOL finished) {
        [view removeFromSuperview];
    }];
}

#pragma mark - ACCRecordFlowServiceSubscriber

- (void)flowServiceWillBeginTakePicture {
    // 如果拍摄照片时添加了道具效果，captureStillImageWithCompletion 拍摄的是加了效果（道具，美颜等）的图片，
    // 这里需要调用 captureStillImageWithCompletion 把无效果的照片拍摄用于上传送审。
    ACCRepoSecurityInfoModel *security = [self.repository extensionModelOfClass:ACCRepoSecurityInfoModel.class];
    RACSubject *photoFrameSubject = [RACSubject subject];
    security.shootPhotoFrameSignal = photoFrameSubject;
    [self.cameraService.recorder captureSourcePhotoAsImageByUser:NO completionHandler:^(UIImage * _Nonnull rawImage, NSError * _Nonnull error) {
        if (rawImage) {
            [ACCSecurityFramesSaver saveImage:rawImage
                                         type:ACCSecurityFrameTypeRecord
                                       taskId:self.viewModel.inputData.publishModel.repoDraft.taskID
                                   completion:^(NSString * _Nonnull path, BOOL success, NSError * _Nonnull error) {
                security.shootPhotoFramePath = path;
                [photoFrameSubject sendNext:path];
                [photoFrameSubject sendCompleted];
            }];
        }
        if (error) {
            [photoFrameSubject sendCompleted];
            AWELogToolError(AWELogToolTagRecord, @"Error of capture source photo when taking picture with prop: %@", error);
        }
    } afterProcess:NO];
}

#pragma mark - zoom

- (void)resetCameraZoomFactor
{
    [self.cameraService.cameraControl resetCameraZoomFactor];
}

#pragma mark - memory warning

- (void)p_releasePreviewWhenMemoryWarning
{
    if (self.viewContainer.rootView && self.viewContainer.rootView.window == nil) {
        if (!self.hasReleasePreviewWhenMemoryWarning) {
            self.hasReleasePreviewWhenMemoryWarning = YES;
            [self.cameraService.cameraControl removeHTSGLPreview];
        }
    }
}

#pragma mark - ACCRecordConfigPublishComponentMessageProtocol

- (void)didFinishConfigAudioWithSetMusicCompletion:(void (^)(void))completion
{
    NSURL *audioURL = nil;
    if (self.repository.repoMusic.music != nil){
        audioURL = self.repository.repoMusic.music.loaclAssetUrl;
    }
    if (audioURL) { // has audioURL
        if (self.cameraService.cameraHasInit) {
            BOOL shouldRepeat = self.repository.repoProp.isMultiSegPropApplied || [self.repository.repoMusic shouldEnableMusicLoop:[IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol) videoMaxSeconds]];
            [self.cameraService.recorder setMusicWithURL:audioURL repeat:shouldRepeat completion:completion];
        }
    } else {
        ACCBLOCK_INVOKE(completion);
    }
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    if (mode.modeId == ACCRecordModeKaraoke || mode.modeId == ACCRecordModeAudio) {
        return;
    }
    
    //这里audioMode对于captureComponent视为不需要权限的tab 来保证从音频模式切换到其他模式时 权限可以正常更新
    BOOL modeNeedOpenAVAuth = (mode.isPhoto || mode.isVideo) && mode.isAdditionVideo && mode.modeId != ACCRecordModeAudio;
    BOOL oldModeNeedOpenAVAuth = (oldMode.isPhoto || oldMode.isVideo) && oldMode.isAdditionVideo && oldMode.modeId != ACCRecordModeAudio;
    
    if (modeNeedOpenAVAuth && !oldModeNeedOpenAVAuth) {
        [self p_handleAVAuth];
        [self.viewModel send_captureReadyForSwitchModeSignal:mode oldMode:oldMode];
    }
    
    if (oldMode.modeId == ACCRecordModeLive) {
        [self resetCameraZoomFactor];
    }
}

#pragma mark - ACCEffectEvent

- (void)onEffectMessageReceived:(IESMMEffectMessage *)message {
    [self p_dealWithEffectMessage:message];
}

- (void)p_dealWithEffectMessage:(IESMMEffectMessage *)message
{
    if (message.type == IESMMEffectMsgOther)
    {
        if (message.msgId == BEF_MSG_TYPE_SWITCH_CAMERA_POSITION)
        {
            if (message.arg1 == RENDER_MSG_EVENT_CAMERA_TO_FRONT)
            {
                [self switchCameraPosition:AVCaptureDevicePositionFront];
            }
            else if (message.arg1 == RENDER_MSG_EVENT_CAMERA_TO_BACK)
            {
                [self switchCameraPosition:AVCaptureDevicePositionBack];
            }
            else if (message.arg1 == RENDER_MSG_EVENT_CAMERA_SWITCH)
            {
                AVCaptureDevicePosition switchToPostion = (self.cameraService.cameraControl.currentCameraPosition == AVCaptureDevicePositionBack) ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
                [self switchCameraPosition:switchToPostion];
            }
            else
            {
            }
        } else if (message.msgId == kEffectToastMsgId) {
            [self.viewModel handleEFfectMessageWithArg2:message.arg2 arg3:message.arg3];
        }
   }
}

- (void)switchCameraPosition:(AVCaptureDevicePosition)position {

    [self.cameraService.cameraControl switchToCameraPosition:position];
}

- (void)onWillSwitchToCameraPosition:(AVCaptureDevicePosition)position {
    @weakify(self);
    [self.cameraService.cameraControl captureFrameWhenStopCaptre:^(BOOL success) {
        if (success) {
            @strongify(self);
            [self addLastCaptureFrameIfNeeded];
        }
    }];
}

- (void)onDidSwitchToCameraPosition:(AVCaptureDevicePosition)position {
    [self removeLastFrameWhenCaptureStart];
}

- (void)onDidStopVideoCapture:(BOOL)success {
    if (success) {
        [self addLastCaptureFrameIfNeeded];
    }
}

#pragma mark - Lens Sharpen

- (void)startFaceDetect
{
    [self stopFaceDetect];

    if (!self.cameraService.cameraHasInit ||
        self.cameraService.cameraControl.currentCameraPosition != AVCaptureDevicePositionBack) {
        return;
    }
    @weakify(self);
    [self.cameraService.beauty detectFace:^(BOOL hasFace) {
        @strongify(self);
        BOOL isOn = !hasFace;
        [self.cameraService.beauty turnLensSharpen:isOn];
    }];
}

- (void)stopFaceDetect
{
    [self.cameraService.beauty detectFace:nil];
}

#pragma mark - getter

- (ACCCaptureViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self.modelFactory createViewModel:ACCCaptureViewModel.class];
    }
    return _viewModel;
}

- (ACCPropViewModel *)propViewModel
{
    ACCPropViewModel *propViewModel = [self getViewModel:ACCPropViewModel.class];
    NSAssert(propViewModel, @"should not be nil");
    return propViewModel;
}

- (ACCGroupedPredicate<id,id> *)startVideoCaptureOnWillAppearPredicate
{
    if (!_startVideoCaptureOnWillAppearPredicate) {
        _startVideoCaptureOnWillAppearPredicate = [[ACCGroupedPredicate alloc] init];
    }
    return _startVideoCaptureOnWillAppearPredicate;
}

- (ACCGroupedPredicate<id,id> *)startAudioCaptureOnWillAppearPredicate
{
    if (!_startAudioCaptureOnWillAppearPredicate) {
        _startAudioCaptureOnWillAppearPredicate = [[ACCGroupedPredicate alloc] init];
    }
    return _startAudioCaptureOnWillAppearPredicate;
}

- (ACCGroupedPredicate<id,id> *)startVideoCaptureOnAuthorizedPredicate
{
    if (!_startVideoCaptureOnAuthorizedPredicate) {
        _startVideoCaptureOnAuthorizedPredicate = [[ACCGroupedPredicate alloc] init];
    }
    return _startVideoCaptureOnAuthorizedPredicate;
}

- (ACCGroupedPredicate<id,id> *)startAudioCaptureOnAuthorizedPredicate
{
    if (!_startAudioCaptureOnAuthorizedPredicate) {
        _startAudioCaptureOnAuthorizedPredicate = [[ACCGroupedPredicate alloc] init];
    }
    return _startAudioCaptureOnAuthorizedPredicate;
}

- (ACCGroupedPredicate<id,id> *)shouldStartSamplingPredicate
{
    if (!_shouldStartSamplingPredicate) {
        _shouldStartSamplingPredicate = [[ACCGroupedPredicate alloc] init];
    }
    return _shouldStartSamplingPredicate;
}

@end
