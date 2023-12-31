//
//  ACCPropComponentV2.m
//  CameraClient
//
//  Created by zhangchengtao on 2020/7/12.
//

#import "AWERepoPropModel.h"
#import "ACCPropComponentV2.h"
#import "ACCPropExploreExperimentalControl.h"

#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreationKitInfra/ACCResponder.h>
#import <CreationKitArch/AWEStudioMeasureManager.h>
#import <CreationKitInfra/ACCDeviceAuth.h>

// Service
#import "ACCRecordFlowService.h"
#import "ACCRecordPropService.h"
#import "ACCRecordConfigService.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitArch/ACCRecordTrackService.h>
#import "ACCRecordModeFactory.h"

// Sticker Handler
#import "AWEStickerApplyHandlerContainer.h"

// ViewModels
#import "ACCAudioAuthUtils.h"
#import "ACCPropViewModel.h"
#import "ACCRecordAuthService.h"
#import "ACCScanService.h"
#import <CreationKitComponents/ACCFilterService.h>
#import "AWEStickerPickerDefaultLogger.h"
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>
#import <CameraClient/ACCRecordMode+LiteTheme.h>

@interface ACCPropComponentV2 ()
<
ACCCameraLifeCircleEvent,
ACCRecordPropServiceSubscriber,
ACCRecordSwitchModeServiceSubscriber
>

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;

// Services
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCRecordPropService> propService;
@property (nonatomic, strong) id<ACCRecordConfigService> configService;
@property (nonatomic, strong) id<ACCRecordTrackService> trackService;
@property (nonatomic, strong) id<ACCRecordAuthService> authService;
@property (nonatomic, strong) id<ACCFilterService> filterService;
@property (nonatomic, strong) id<ACCRecordModeFactory> modeFactory;
@property (nonatomic, weak) id<ACCKaraokeService> karaokeService;
@property (nonatomic, strong) id<ACCStickerApplyHandlerTemplate> stickerApplyHandlerTemplate;

@property (nonatomic, strong) ACCPropViewModel *viewModel;

@property (nonatomic, strong) AWEStickerApplyHandlerContainer *stickerApplyHandlerContainer;

@property (nonatomic, strong) id<AWEStickerPickerLoggerDelegate> logger;

@property (nonatomic, assign) BOOL isDisappear;

@end

@implementation ACCPropComponentV2


IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, propService, ACCRecordPropService)
IESAutoInject(self.serviceProvider, configService, ACCRecordConfigService)
IESAutoInject(self.serviceProvider, trackService, ACCRecordTrackService)
IESAutoInject(self.serviceProvider, authService, ACCRecordAuthService)
IESAutoInject(self.serviceProvider, filterService, ACCFilterService)
IESAutoInject(self.serviceProvider, modeFactory, ACCRecordModeFactory)
IESAutoInject(self.serviceProvider, stickerApplyHandlerTemplate, ACCStickerApplyHandlerTemplate)

IESOptionalInject(self.serviceProvider, karaokeService, ACCKaraokeService)

#pragma mark - ACCFeatureComponent

- (void)dealloc
{
    AWELogToolDebug(AWELogToolTagNone, @"%s", __func__);
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.cameraService addSubscriber:self]; // ACCCameraLifeCircleEvent
    [self.cameraService.message addSubscriber:self]; // ACCEffectEvent
    [self.propService addSubscriber:self]; // ACCRecordPropServiceSubscriber
    [self.switchModeService addSubscriber:self];
}

- (void)componentDidMount
{
    [[ACCPropExploreExperimentalControl sharedInstance] setPublishModel:self.viewModel.inputData.publishModel];

    [self p_bindViewModels];
    
    // Create a logger and setup as a delegate of AWEStickerPickerLogger.
    self.logger = [[AWEStickerPickerDefaultLogger alloc] init];
    [AWEStickerPickerLogger sharedInstance].delegate = self.logger;
    
    // Config sticker apply handler container.
    [self createStickerApplyContainer];
    
    // Add notification observer
    [self addNotificationObserver];
}

- (void)componentWillAppear
{
    self.isDisappear = NO;
    if ([ACCAudioAuthUtils shouldStartAudioCaptureWhenApplyProp:self.viewModel.inputData.publishModel]) {
        BOOL isAudioEffect = [self.viewModel.currentSticker isTypeVoiceRecognization];
        if (isAudioEffect && [self.switchModeService isVideoCaptureMode]) {
            [self.cameraService.cameraControl startAudioCapture];
        }
    }
}

- (void)componentDidDisappear
{
    self.isDisappear = YES;
}

- (void)componentDidAppear
{
    [self.stickerApplyHandlerContainer componentDidAppear];
    //performace track
    [[AWEStudioMeasureManager sharedMeasureManager] trackEffectInfo];
}

#pragma mark - ACCCameraLifeCircleEvent

- (void)onCreateCameraCompleteWithCamera:(id<ACCCameraService>)cameraService {
    if (!cameraService.cameraHasInit) return;

    BOOL shouldShowLiveDuetPostureViewController = !ACC_isEmptyString(self.viewModel.inputData.publishModel.repoProp.liveDuetPostureImagesFolderPath);
    // if reshoot and local sticker is nil, need to re-apply the effect model
    if (shouldShowLiveDuetPostureViewController && self.viewModel.inputData.publishModel.repoReshoot.isReshoot && !self.viewModel.inputData.localSticker) {
        [self p_applyStickerWhenReshoot];
        return;
    }
    
    // Apply Local Sticker if camera and audio authed.
    // 如果 camera 和 audio 都已经授权通过，应用 localSticker，否则延后到授权通过后，
    // 即 [self authViewModel].passCheckAuthSignal subscribeNext:^(NSNumber * _Nullable x)...
    if (([ACCDeviceAuth currentAuthType] & ACCRecordAuthComponentMicAuthed)) {
        [self p_applyLocalSticker];
    }
}

- (void)cameraService:(id<ACCCameraService>)cameraService didTakeAction:(IESCameraAction)action error:(NSError * _Nullable)error data:(id _Nullable)data {
    if (!cameraService.cameraHasInit) { return; }
    
    [self.stickerApplyHandlerContainer camera:cameraService didTakeAction:action error:error data:data];
}

#pragma mark - ACCEffectEvent

- (void)onEffectMessageReceived:(IESMMEffectMessage *)message {
    [self.stickerApplyHandlerContainer camera:self.cameraService didRecvMessage:message];
}

#pragma mark - Private

- (void)p_applyLocalSticker
{
    // Apply local sticker if exists.
    if (self.viewModel.inputData.localSticker) {
        [self.propService applyProp:self.viewModel.inputData.localSticker propSource:ACCPropSourceLocalProp byReason:ACCRecordPropChangeReasonOuter];
    }
}

- (void)p_applyStickerWhenReshoot {
    NSString *stickerId = self.viewModel.inputData.publishModel.repoProp.localPropId;

    if (!stickerId) {
        AWELogToolError(AWELogToolTagNone, @"No stickerId at [ACCPropComponent p_applyStickerWhenReshoot:] is available");
        return;
    }

    @weakify(self);
    [EffectPlatform fetchEffectListWithEffectIDS:@[stickerId] completion:^(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects, NSArray<IESEffectModel *> * _Nullable bindEffects) {
        @strongify(self);

        if (error) {
            AWELogToolError(AWELogToolTagNone, @"pre download effect error|ids=%@|error=%@", stickerId, error);
            return;
        }

        if (effects.count == 0) {
            AWELogToolInfo(AWELogToolTagNone, @"do not pre download cuz fetch effects is empty|effectIds=%@", stickerId);
            return;
        }

        IESEffectModel *liveDuetEffectModel = effects.firstObject;
        if (liveDuetEffectModel) {
            self.viewModel.inputData.localSticker = liveDuetEffectModel;
            [self p_applyLocalSticker];
        }
    }];
}

- (void)p_bindViewModels {
    @weakify(self);
    [self.authService.passCheckAuthSignal subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if (!self.cameraService.cameraHasInit) {
            return;
        }
        if (!([ACCDeviceAuth currentAuthType] & ACCRecordAuthComponentMicAuthed)) {
            return;
        }
        [self p_applyLocalSticker];
    }];
    
    [self.viewModel.applyLocalStickerSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        if ([x isKindOfClass:[NSError class]]) {
            [ACCToast() showError:[(NSError *)x localizedDescription]];
        } else {
            [self p_applyLocalSticker];
        }
    }];
}

- (void)createStickerApplyContainer {
    if (nil == self.stickerApplyHandlerContainer) {
        AWEStickerApplyHandlerContainer *container = [[AWEStickerApplyHandlerContainer alloc] initWithCameraService:self.cameraService
                                                                                                        propService:self.propService
                                                                                                        flowService:self.flowService
                                                                                                      configService:self.configService
                                                                                                  switchModeService:self.switchModeService
                                                                                                       trackService:self.trackService
                                                                                                      filterService:self.filterService
                                                                                                    serviceProvider:self.serviceProvider
                                                                                                      propViewModel:self.viewModel
                                                                                            containerViewController:self.controller.root
                                                                                                      viewContainer:self.viewContainer
                                                      modeFactory:self.modeFactory];
        [self propService].propApplyHanderContainer = container;
        
        NSArray *handlers = [self.stickerApplyHandlerTemplate handlerClasses:self];
        for(Class handler in handlers){
            [container addHandler:[[handler alloc] init]];
        }
        self.stickerApplyHandlerContainer = container;
    }
}

- (void)addPropApplyPredicate:(id<ACCStickerApplyPredicate>)predicate
{
    [self.viewModel.groupedPredicate addSubPredicate:predicate];
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceWillChangeToMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    if (!mode.isVideo && !mode.isPhoto && self.propService.prop.isMultiSegProp) {
        [self.propService applyProp:nil propSource:ACCPropSourceUnknown byReason:ACCRecordPropChangeReasonSwitchMode];
        [self.viewModel sendSignal_shouldUpdatePickerSticker:nil];
    }
}

#pragma mark - ViewModels

- (ACCPropViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self getViewModel:ACCPropViewModel.class];
    }
    return _viewModel;
}

#pragma mark - ACCRecordPropServiceSubscriber

- (void)propServiceWillApplyProp:(IESEffectModel *)prop propSource:(ACCPropSource)propSource
{
    if (prop != nil) {
        [self.viewModel trackWillApplySticker:prop];
    }
    
    [self.stickerApplyHandlerContainer camera:self.cameraService willApplySticker:prop];
}

- (void)propServiceDidApplyProp:(IESEffectModel *)prop success:(BOOL)success
{
    AWELogToolInfo(AWELogToolTagRecord, @"propServiceDidApplyProp %@", prop.effectIdentifier);
    [self.stickerApplyHandlerContainer camera:self.cameraService didApplySticker:prop success:success];
}

#pragma mark - To be optimized

- (BOOL)p_currentSwitchModeNeedStartVideo
{
    ACCRecordMode *mode  = self.switchModeService.currentRecordMode;
    // Video and audio capture will be handled by karaoke component in karaoke mode.
    if (self.karaokeService.inKaraokeRecordPage || mode.modeId == ACCRecordModeAudio) {
        return NO;
    }
    
    BOOL videoMode = (mode.isPhoto || mode.isVideo) && mode.isAdditionVideo && mode.modeId != ACCRecordModeAudio;
    BOOL needStartVideo = mode.modeId == ACCRecordModeLive || videoMode;
    return needStartVideo;
}

- (void)addNotificationObserver
{
    @weakify(self);
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationWillResignActiveNotification object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(NSNotification *_Nullable x) {
        @strongify(self);
        if (![self shouldHandleAVCaptureForAppLifeEvent]) {
            return;
        }
        // audio effect在pause的时候特殊处理了不调用stopAudioCapture，进后台的特殊情况，强制stop;
        BOOL isAudioEffect = [self.viewModel.currentSticker isTypeVoiceRecognization];
        if (isAudioEffect) {
            [self.cameraService.cameraControl stopAudioCapture];
        }
                
        if ([ACCResponder topViewController] == self.controller.root) {
            [self.cameraService.effect acc_retainForbiddenMusicPropPlayCount];
        }
    }];

    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidBecomeActiveNotification object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(NSNotification *_Nullable x) {
        @strongify(self);
        if (![self shouldHandleAVCaptureForAppLifeEvent]) {
            return;
        }
        // audio effect在pause的时候特殊处理了不调用stopAudioCapture，进后台的特殊情况强制调用了stop，didBecome后开始采集;
        BOOL isAudioEffect = [self.viewModel.currentSticker isTypeVoiceRecognization];
        if (isAudioEffect && !self.isDisappear && [self.propService shouldStartAudio] && [ACCResponder topViewController] == self.controller.root) {
            [self.cameraService.cameraControl startAudioCapture];
        }
        if ([ACCResponder topViewController] == self.controller.root && self.cameraService.cameraControl) {
            [self.cameraService.effect acc_releaseForbiddenMusicPropPlayCount];
        }
    }];

    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationWillEnterForegroundNotification object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(NSNotification *_Nullable x) {
        @strongify(self);
        if (![self shouldHandleAVCaptureForAppLifeEvent]) {
            return;
        }
        UIViewController *topViewController = [ACCResponder topViewController];
        UIViewController *presentedViewController = self.controller.root.presentedViewController;
        if (topViewController == self.controller.root
            || (topViewController == presentedViewController
                && topViewController.modalPresentationStyle == UIModalPresentationOverCurrentContext)) {
            if (self.cameraService.cameraHasInit && [ACCDeviceAuth hasCameraAndMicroPhoneAuth]) {
                if ([self p_currentSwitchModeNeedStartVideo]) {
                    [self.cameraService.cameraControl startVideoCaptureIfCheckAppStatus:NO];
                }
                if ([self.propService shouldStartAudio]) {
                    // 通过3D Touch进入拍摄器，此时VC还未ViewDidLoad，创建camera添加CameraPreview会失败，这里只打开捕获
                    if (self.switchModeService.currentRecordMode.isVideo) {
                        IESEffectModel *currentSticker = self.viewModel.currentSticker;
                        if ([currentSticker isTypeVoiceRecognization]) {
                            [self.cameraService.cameraControl startAudioCapture];
                        }
                    }
                }
            }
        }
    }];

    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(NSNotification *_Nullable x) {
        @strongify(self);
        if (![self shouldHandleAVCaptureForAppLifeEvent]) {
            return;
        }
        [self.cameraService.cameraControl changeToZoomFactor:1.0f];
        UIViewController *topVC = [ACCResponder topViewController];
        UIViewController *presentedViewController = self.controller.root.presentedViewController;
        BOOL vcCondition = (topVC == self.controller.root) || (topVC == presentedViewController &&
                                                               topVC.modalPresentationStyle == UIModalPresentationOverCurrentContext);
        if (vcCondition) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.cameraService.cameraControl stopVideoAndAudioCapture];
            });
        }
    }];
}

- (BOOL)shouldHandleAVCaptureForAppLifeEvent
{
    if (!self.isMounted) {
        return NO;
    }
    ACCRecordModeIdentifier modeID =  self.switchModeService.currentRecordMode.modeId;
    if (modeID == ACCRecordModeLive) {
        return NO;
    }
    if (self.karaokeService.inKaraokeRecordPage) {
        return NO;
    }
    BOOL inKaraokeSelectMusicPage = modeID == ACCRecordModeKaraoke && !self.karaokeService.inKaraokeRecordPage;
    if (inKaraokeSelectMusicPage) {
        return NO;
    }
    if ([IESAutoInline(self.serviceProvider, ACCScanService) currentMode] == ACCScanModeQRCode) {
        return NO;
    }
    return YES;
    
}

@end
