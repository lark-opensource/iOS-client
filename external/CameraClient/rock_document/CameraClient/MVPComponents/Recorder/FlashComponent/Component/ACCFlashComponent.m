//
//  ACCFlashComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2020/12/30.
//

#import "ACCFlashComponent.h"

#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import <CreationKitArch/AWECameraContainerToolButtonWrapView.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitArch/ACCRecorderToolBarDefines.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CameraClient/ACCRecorderEvent.h>
#import "AWEFlashModeSwitchButton.h"
#import "ACCScreenSimulatedTorchView.h"
#import <CreationKitArch/ACCRecordTrackService.h>
#import "ACCRecordPropService.h"
#import "ACCKaraokeService.h"
#import <CreationKitInfra/UILabel+ACCAdditions.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import "ACCPropViewModel.h"
#import "ACCBarItem+Adapter.h"
#import <CameraClientModel/AWEVideoRecordButtonType.h>


@interface ACCFlashComponent () <ACCCameraLifeCircleEvent, ACCRecordSwitchModeServiceSubscriber, ACCRecordPropServiceSubscriber, ACCKaraokeServiceSubscriber, ACCRecorderEvent>

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordTrackService> trackService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCRecordPropService> propService;
@property (nonatomic, weak) id<ACCKaraokeService> karaokeService;

@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, assign) BOOL shouldShowTorchButton;
@property (nonatomic, strong) AWEFlashModeSwitchButton *flashSwitchButton;
@property (nonatomic, strong) UILabel *flashSwitchButtonLabel;

@property (nonatomic, strong) ACCScreenSimulatedTorchView *frontCameraTorch;

@end

@implementation ACCFlashComponent


IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, trackService, ACCRecordTrackService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, propService, ACCRecordPropService)

IESOptionalInject(self.serviceProvider, karaokeService, ACCKaraokeService)

#pragma mark - ACCComponentProtocol

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.cameraService addSubscriber:self];
    [self.cameraService.cameraControl addSubscriber:self];
    [self.cameraService.message addSubscriber:self];
    [self.cameraService.recorder addSubscriber:self];
    [self.switchModeService addSubscriber:self];
    [self.propService addSubscriber:self];
    [self.karaokeService addSubscriber:self];
}

#pragma mark - ACCFeatureComponent

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)loadComponentView
{
    [self configFlashBarItem];
}

- (void)componentDidMount
{
    self.isFirstAppear = YES;
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    if (self.cameraService.cameraHasInit) {
        [self syncFlashModeState];
    }
}

- (void)componentDidAppear
{
    if (self.isFirstAppear) {
        self.isFirstAppear = NO;
        [self p_bindViewModelObserver];
    }
}

- (void)componentWillDisappear
{
    [self syncFlashModeState]; // 是否有必要
}

#pragma mark - set UI

- (void)configFlashBarItem
{
    let config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCRecorderToolBarFlashContext];
    if (config) {
        AWECameraContainerToolButtonWrapView *flashCustomView = [[AWECameraContainerToolButtonWrapView alloc] initWithButton:self.flashSwitchButton label:self.flashSwitchButtonLabel itemID:ACCRecorderToolBarFlashContext];
        ACCBarItem *flashBarItem = [[ACCBarItem alloc] initWithCustomView:flashCustomView itemId:ACCRecorderToolBarFlashContext];
        flashBarItem.type = ACCBarItemFunctionTypeDefault;
        @weakify(self);
        flashBarItem.needShowBlock = ^BOOL{
            @strongify(self);
            ACCRecordMode *currentMode = self.switchModeService.currentRecordMode;
            if (currentMode.isPhoto) {
                if (currentMode.buttonType == AWEVideoRecordButtonTypeLivePhoto) {
                    BOOL show = self.shouldShowTorchButton &&
                        (self.cameraService.cameraControl.currentCameraPosition == AVCaptureDevicePositionBack);
                    return show;
                }
                return self.shouldShowTorchButton && self.cameraService.cameraControl.isFlashEnable;
            } else if (currentMode.isVideo) {
                // more 不显示时
                BOOL isKaraokeAudioMode = self.karaokeService.inKaraokeRecordPage && self.karaokeService.recordMode == ACCKaraokeRecordModeAudio;
                BOOL show = self.shouldShowTorchButton &&
                            (self.cameraService.cameraControl.currentCameraPosition == AVCaptureDevicePositionBack) &&
                            (!isKaraokeAudioMode);
                if (ACCConfigBool(ACCConfigBool_enable_front_torch)) {
                    show = self.shouldShowTorchButton && (!isKaraokeAudioMode);
                }
                return show && ![self.cameraService.recorder isRecording];
            }
            return YES;
        };
        [self.viewContainer.barItemContainer addBarItem:flashBarItem];
    }
    
    if (ACCConfigBool(ACCConfigBool_enable_front_torch)) {
        ACCScreenSimulatedTorchView *torchView = [[ACCScreenSimulatedTorchView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        torchView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [torchView turnOff];
        [self.viewContainer.interactionView insertSubview:torchView aboveSubview:self.viewContainer.preview];
        [self.cameraService.cameraControl registerTorch:torchView forCamera:AVCaptureDevicePositionFront];
        self.frontCameraTorch = torchView;
    }
}

#pragma mark - init methods

- (void)p_bindViewModelObserver
{
    @weakify(self);
    [[[RACObserve(self.cameraService.cameraControl, currentCameraPosition) distinctUntilChanged] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        if (!self.cameraService.cameraHasInit) {
            return;
        }
        [self updateTorchSwitchButtonStateForCameraChange];
    }];
    
    [[RACObserve(self.cameraService.cameraControl, isFlashEnable) deliverOnMainThread] subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if (!self.cameraService.cameraHasInit) {
            return;
        }
        if (!self.shouldShowTorchButton || self.cameraService.recorder.cameraMode == HTSCameraModeVideo) {
            return;
        }
        NSArray *flashButtons = [self flashButtons];
        BOOL flashEnable = [x boolValue];
        for (AWEFlashModeSwitchButton *flashButton in flashButtons) {
            if (!flashButton.superview) {
                continue;
            }
            flashButton.enabled = flashEnable;
        }
    }];
    
    [[RACObserve(self.cameraService.cameraControl, isTorchEnable) deliverOnMainThread] subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if (!self.cameraService.cameraHasInit) {
            return;
        }
        if (!self.shouldShowTorchButton || self.cameraService.recorder.cameraMode == HTSCameraModePhoto) {
            return;
        }
        NSArray *flashButtons = [self flashButtons];
        BOOL torchEnable = [x boolValue];
        for (AWEFlashModeSwitchButton *flashButton in flashButtons) {
            if (!flashButton.superview) {
                continue;
            }
            flashButton.enabled = torchEnable;
        }
    }];

    [[RACObserve(self.cameraService.cameraControl, flashMode) deliverOnMainThread] subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if (!self.cameraService.cameraHasInit) {
            return;
        }
        if (!self.shouldShowTorchButton || self.cameraService.recorder.cameraMode == HTSCameraModeVideo) {
            return;
        }
        NSArray *flashButtons = [self flashButtons];
        ACCCameraFlashMode flashMode = [x unsignedIntegerValue];
        for (AWEFlashModeSwitchButton *flashButton in flashButtons) {
            if (!flashButton.superview) {
                continue;
            }
            [flashButton switchFlashMode:flashMode];
        }
    }];

    [[RACObserve(self.cameraService.cameraControl, torchMode) deliverOnMainThread] subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if (!self.cameraService.cameraHasInit) {
            return;
        }
        if (!self.shouldShowTorchButton || self.cameraService.recorder.cameraMode == HTSCameraModePhoto) {
            return;
        }
        ACCCameraFlashMode flashMode = [x unsignedIntegerValue];
        NSArray *flashButtons = [self flashButtons];
        for (AWEFlashModeSwitchButton *flashButton in flashButtons) {
            if (!flashButton.superview) {
                continue;
            }
            [flashButton switchFlashMode:flashMode];
        }
    }];
}

#pragma mark - ACCCameraLifeCircleEvent
- (void)onCreateCameraCompleteWithCamera:(id<ACCCameraService>)cameraService
{
    [self updateTorchSwitchButtonStateForCameraChange];
    [self syncViewStateWithViewModel];
}

- (void)cameraService:(id<ACCCameraService>)cameraService didTakeAction:(IESCameraAction)action error:(NSError * _Nullable)error data:(id _Nullable)data
{
    if (action == IESCameraDidPauseVideoRecord ||
        action == IESCameraDidReachMaxTimeVideoRecord) {
        if (!(ACCConfigBool(kConfigBool_is_torch_perform_immediately) && self.cameraService.cameraControl.currentCameraPosition == AVCaptureDevicePositionBack &&
            self.cameraService.cameraControl.torchMode == ACCCameraTorchModeOn)) {
            [self.cameraService.cameraControl turnOffUniversalTorch];
        }
    }
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    // livePhoto虽然是isPhoto，但闪光灯要求是手电筒模式
    BOOL oldUseTorch = (oldMode.isVideo && oldMode.modeId != ACCRecordModeAudio) || oldMode.modeId == ACCRecordModeLivePhoto;
    BOOL useTorch = (mode.isVideo && mode.modeId != ACCRecordModeAudio) || mode.modeId == ACCRecordModeLivePhoto;
    
    // 不同tab间保持闪光灯的ab
    if (ACCConfigBool(ACCConfigBOOL_enable_continuous_flash_and_torch)) {
        ACCCameraTorchMode torchMode = self.cameraService.cameraControl.torchMode;
        ACCCameraFlashMode flashMode = self.cameraService.cameraControl.flashMode;
        
        if (oldUseTorch && !useTorch) { // 切换到闪光灯模式
            [self.cameraService.cameraControl switchToTorchMode:ACCCameraTorchModeOff];
            [self.cameraService.cameraControl switchToFlashMode:(ACCCameraFlashMode)torchMode];
        } else if (!oldUseTorch && useTorch) { // 切换到手电筒模式
            ACCCameraTorchMode torchMode = (ACCCameraTorchMode)flashMode;
            if (torchMode == ACCCameraTorchModeAuto && !ACCConfigBool(ACCConfigBool_enable_torch_auto_mode)) {
                torchMode = ACCCameraTorchModeOff;
            }
            [self.cameraService.cameraControl switchToTorchMode:torchMode];
        } else if (!useTorch) { // 其他情况，例如从文本tab切到照片tab
            if ((ACCCameraFlashMode)torchMode != flashMode && flashMode == ACCCameraFlashModeOff) {
                [self.cameraService.cameraControl switchToTorchMode:ACCCameraTorchModeOff];
                [self.cameraService.cameraControl switchToFlashMode:(ACCCameraFlashMode)torchMode];
            }
        }
    } else {
        if (oldUseTorch && mode != oldMode) {
            [self.cameraService.cameraControl switchToTorchMode:ACCCameraTorchModeOff];
        }
        if (!oldUseTorch && useTorch) {
            [self.cameraService.cameraControl switchToFlashMode:ACCCameraFlashModeOff];
        }
    }

    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarFlashContext];
    [self p_updateFlashButtonsEnableStateForModeSwitch];
    [self syncFlashModeState];
}

#pragma mark - ACCKaraokeServiceSubscriber

- (void)karaokeService:(id<ACCKaraokeService>)service recordModeDidChangeFrom:(ACCKaraokeRecordMode)prevMode to:(ACCKaraokeRecordMode)mode
{
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarFlashContext];
    if (mode == ACCKaraokeRecordModeAudio) {
        [self.cameraService.cameraControl switchToTorchMode:ACCCameraTorchModeOff];
    }
}

- (void)karaokeService:(id<ACCKaraokeService>)service inKaraokeRecordPageDidChangeFrom:(BOOL)prevState to:(BOOL)state
{
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarFlashContext];
    [self syncFlashModeState];
}

#pragma mark - ACCRecorderEvent

- (void)p_handleTorchModeOnStartWithBlock:(void (^)(BOOL *))block
{
    BOOL turnOnTorch = NO;
    if (ACCConfigDouble(kConfigDouble_torch_record_wait_duration) < 0.1) {
        ACCCameraTorchMode torchMode = self.cameraService.cameraControl.torchMode;
        NSNumber *brigthness = self.cameraService.cameraControl.brightness;
        float brightnessThreshold = ACCConfigDouble(ACCConfigDouble_torch_brightness_threshold);
        
        if (torchMode == ACCCameraTorchModeOn ||
            (torchMode == ACCCameraTorchModeAuto &&
             brigthness != nil &&
             [brigthness doubleValue] <= brightnessThreshold)) {
            turnOnTorch = YES;
        }
    }
    
    ACCBLOCK_INVOKE(block, &turnOnTorch);
    if (turnOnTorch) {
        [self.cameraService.cameraControl turnOnUniversalTorch];
    }
}

- (void)onWillStartVideoRecordWithRate:(CGFloat)rate;
{
    [self p_handleTorchModeOnStartWithBlock:nil];
}

- (void)onWillStartLivePhotoRecordWithConfig:(id<ACCLivePhotoConfigProtocol>)config
{
    [self p_handleTorchModeOnStartWithBlock:^(BOOL *turnOn) {
        if (self.cameraService.cameraControl.currentCameraPosition != AVCaptureDevicePositionBack) {
            *turnOn = NO;
        }
    }];
}

#pragma mark - private methods

- (void)updateTorchSwitchButtonStateForCameraChange
{
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarFlashContext];
    [self syncFlashModeState];
}

- (void)syncFlashModeState
{
    if (!ACCConfigBool(ACCConfigBOOL_enable_continuous_flash_and_torch)) {
        switch (self.cameraService.recorder.cameraMode) {
            case HTSCameraModePhoto: {
                [self.cameraService.cameraControl switchToFlashMode:ACCCameraFlashModeOff];
                break;
            }
            case HTSCameraModeVideo: {
                [self.cameraService.cameraControl switchToTorchMode:ACCCameraTorchModeOff];
                break;
            }
            default:
                break;
        }
    }
}

- (void)p_updateFlashButtonsEnableStateForModeSwitch
{
    NSArray *flashButtons = [self flashButtons];
    for (AWEFlashModeSwitchButton *flashButton in flashButtons) {
        if (!flashButton.superview) {
            continue;
        }
        if (self.cameraService.recorder.cameraMode == HTSCameraModeVideo) {
            flashButton.enabled = self.cameraService.cameraControl.isTorchEnable;
            [flashButton switchFlashMode:(IESCameraFlashMode)self.cameraService.cameraControl.torchMode];
        } else {
            flashButton.enabled = self.cameraService.cameraControl.isFlashEnable;
            [flashButton switchFlashMode:(IESCameraFlashMode)self.cameraService.cameraControl.flashMode];
        }
    }
}

- (void)syncViewStateWithViewModel
{
    if (self.shouldShowTorchButton) {
        NSArray *flashButtons = [self flashButtons];
        for (AWEFlashModeSwitchButton *flashButton in flashButtons) {
            if (self.cameraService.recorder.cameraMode == HTSCameraModePhoto) {
                flashButton.enabled = self.cameraService.cameraControl.isFlashEnable;
                [flashButton switchFlashMode:(IESCameraFlashMode)self.cameraService.cameraControl.flashMode];
            } else {
                flashButton.enabled = self.cameraService.cameraControl.isTorchEnable;
                [flashButton switchFlashMode:(IESCameraFlashMode)self.cameraService.cameraControl.torchMode];
            }
        }
    }
}

#pragma mark - call back methods

- (void)clickTorchSwitchBtn:(AWEFlashModeSwitchButton *)sender
{
    if (!self.isMounted) {
        return;
    }
    [ACCTracker() trackEvent:@"light"
                       label:@"click"
                       value:nil
                       extra:nil
                  attributes:@{@"is_photo": self.cameraService.recorder.cameraMode == HTSCameraModePhoto ? @1 : @0}];
    
    IESCameraFlashMode targetMode = IESCameraFlashModeOff;
    
    switch (self.cameraService.recorder.cameraMode) {
        case HTSCameraModeVideo: {
            targetMode = [self.cameraService.cameraControl getNextTorchMode];
            [self.cameraService.cameraControl switchToTorchMode:targetMode];
            if (ACCConfigBool(ACCConfigBool_enable_front_torch)) { //保证“点击拍照长按录制”模式下拍照也有闪光灯
                [self.cameraService.cameraControl switchToFlashMode:(ACCCameraFlashMode)targetMode];
            }
            break;
        }
        case HTSCameraModePhoto: {
            targetMode = [self.cameraService.cameraControl getNextFlashMode];
            [self.cameraService.cameraControl switchToFlashMode:targetMode];
            break;
        }
        default:
            break;
    }
    
    NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.repository.repoTrack.referExtra];
    referExtra[@"to_status"] =  @{@(IESCameraFlashModeOff):@"off",
                                  @(IESCameraFlashModeOn):@"on",
                                  @(IESCameraFlashModeAuto):@"auto"}[@(targetMode)];
    referExtra[@"camera_direction"] = self.cameraService.cameraControl.currentCameraPosition == AVCaptureDevicePositionFront ? @"front" : @"back";
    [ACCTracker() trackEvent:@"light" params:referExtra needStagingFlag:NO];
    
    if (self.cameraService.recorder.cameraMode == HTSCameraModeVideo) {
        if (ACCConfigBool(kConfigBool_is_torch_perform_immediately)) {
           if (self.cameraService.cameraControl.torchMode == ACCCameraTorchModeOn &&
               self.cameraService.cameraControl.currentCameraPosition == AVCaptureDevicePositionBack) {
               [self.cameraService.cameraControl turnOnUniversalTorch];
           }
       }
    }
}

#pragma mark - getter

- (UILabel *)flashSwitchButtonLabel
{
    if (!_flashSwitchButtonLabel) {
        _flashSwitchButtonLabel = [self p_createButtonLabel: ACCLocalizedCurrentString(@"flash")];
    }
    return _flashSwitchButtonLabel;
}

- (UILabel *)p_createButtonLabel:(NSString *)text
{
    UILabel *label = [[UILabel alloc] acc_initWithFont:[ACCFont() acc_boldSystemFontOfSize:10]
                                             textColor:ACCResourceColor(ACCUIColorConstTextInverse)
                                                  text:text];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 2;
    [label acc_addShadowWithShadowColor:ACCResourceColor(ACCUIColorConstLinePrimary) shadowOffset:CGSizeMake(0, 1) shadowRadius:2];
    label.isAccessibilityElement = NO;
    return label;
}

- (AWEFlashModeSwitchButton *)flashSwitchButton
{
    if (!_flashSwitchButton) {
        _flashSwitchButton = [[AWEFlashModeSwitchButton alloc] initWithType:ACCAnimatedButtonTypeScale];
        if (self.shouldShowTorchButton) {
            [_flashSwitchButton addTarget:self action:@selector(clickTorchSwitchBtn:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    return _flashSwitchButton;
}

- (BOOL)shouldShowTorchButton
{
    if (!_shouldShowTorchButton) {
        _shouldShowTorchButton = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo].hasTorch;
    }
    return _shouldShowTorchButton;
}

- (NSArray<AWEFlashModeSwitchButton *> *)flashButtons
{
    if (!self.shouldShowTorchButton) {
        return @[];
    }
    NSMutableArray *flashButton = @[].mutableCopy;
    if (self.flashSwitchButton) {
        [flashButton addObject:self.flashSwitchButton];
    }
    return [flashButton copy];
}

@end
