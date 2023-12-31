//
//  ACCRecordGestureComponent.m
//  Pods
//
//  Created by songxiangwu on 2019/7/28.
//

#import "ACCRecordGestureComponent.h"
#import "ACCLiveServiceProtocol.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitComponents/ACCFilterService.h>
#import "ACCFocusViewModel.h"
#import <CreativeKit/ACCRecorderViewContainer.h>
#import "ACCPropViewModel.h"
#import "AWECameraPreviewContainerView.h"
#import "ACCRecordARService.h"
#import "ACCRecordGestureService.h"
#import "ACCRecordGestureServiceImpl.h"
#import <CreationKitArch/ACCRepoTrackModel.h>

#import "AWERecorderTipsAndBubbleManager.h"
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitInfra/ACCRTLProtocol.h>
#import "ACCToolBarContainerAdapter.h"
#import "ACCToolBarAdapterUtils.h"
#import "GestureRecognizer/ACCRecordTapGestureRecognizer.h"
#import "ACCScanService.h"

#import <CameraClient/AWERecorderTipsAndBubbleManager.h>
#import <CameraClient/ACCTapicEngineProtocol.h>
#import <CameraClient/ACCCameraSwapService.h>

@interface ACCRecordGestureComponent () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableSet *sdkGesturesSet;
@property (nonatomic, strong) UITapGestureRecognizer *cameraTapGesture;
@property (nonatomic, strong) ACCRecordTapGestureRecognizer *doubleTapSwitchCamera;
@property (nonatomic, strong) UIPanGestureRecognizer *exposureCompensationPanGesture;
@property (nonatomic, strong) UIPanGestureRecognizer *sdkDuetLayoutPanGesture;
@property (nonatomic, strong) UISwipeGestureRecognizer *closeGesture;
@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;

@property (nonatomic, assign) BOOL hasAddGesture;
@property (nonatomic, assign) BOOL hasTrackZoomingEvent;
@property (nonatomic, assign) BOOL sdkGestureHasDisabled;
@property (nonatomic, assign) BOOL hasAddDuetLayoutGesture;//if added duet-layout effects which need gesture, never disable SDKGestures

@property (nonatomic, assign) CGFloat oldZoomFactor;

@property (nonatomic, assign) BOOL isHandleExposureCompensation;
@property (nonatomic, assign) BOOL manuallyDisableSDKGestures;

@property (nonatomic, strong) id<ACCRecordARService> arService;
@property (nonatomic, strong) ACCFocusViewModel *focusViewModel;

@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, weak) id<ACCCameraSwapService> cameraSwapService;
@property (nonatomic, strong) id<ACCFilterService> filterService;
@property (nonatomic, strong) id<ACCRecordGestureService> gestureService;
@property (nonatomic, weak) id<ACCScanService> scanService;

@end

@implementation ACCRecordGestureComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, cameraSwapService, ACCCameraSwapService)
IESAutoInject(self.serviceProvider, filterService, ACCFilterService)

IESOptionalInject(self.serviceProvider, arService, ACCRecordARService)
/**
 禁掉普通录制的手势
 */
- (void)disableNormalRecordGestures
{
    if (!self.hasAddGesture) {
        [self addGestures];
    }
    // 禁掉普通录制的手势
    self.cameraTapGesture.enabled = NO;
    self.exposureCompensationPanGesture.enabled = NO;
    [self.gestureService disableAllGestures];

    self.cameraService.cameraPreviewView.shouldHandleTouch = NO;
    self.cameraService.config.enableTapFocus = NO;
    self.cameraService.config.enableTapexposure = NO;
    // 开启传递给 SDK 手势
    for (UIGestureRecognizer *g in self.sdkGesturesSet) {
        g.enabled = YES;
    }
    self.sdkGestureHasDisabled = NO;
}

/**
 禁掉传递给 SDK 的手势
 */
- (void)disableSDKGesturesAndDisableTapFocus:(BOOL)needTransferTouch
{
    if (!self.hasAddGesture) {
        [self addGestures];
    }
    // 设置对焦开关
    self.cameraTapGesture.enabled = !needTransferTouch;
    
    // 禁掉传递给 SDK 的手势
    for (UIGestureRecognizer *g in self.sdkGesturesSet) {
        g.enabled = NO;
    }
    self.sdkGestureHasDisabled = YES;

    [self.gestureService enableAllGestures];

    // 开启普通录制的手势
    if (needTransferTouch) {
        self.cameraService.cameraPreviewView.shouldHandleTouch = YES;
    } else {
        self.cameraService.cameraPreviewView.shouldHandleTouch = NO;
    }
    self.cameraService.config.enableTapFocus = !needTransferTouch;
    self.cameraService.config.enableTapexposure = !needTransferTouch;
}

#pragma mark - ACCComponentProtocol

- (void)componentDidMount
{
    [self addGestures];
    [self p_readExistData];
    [self p_bindViewModels];
}

- (void)p_bindViewModels
{
    @weakify(self);
    [[self propViewModel].didApplyLocalStickerSignal.deliverOnMainThread subscribeNext:^(IESEffectModel *sticker) {
        @strongify(self);
        [self updateGestureStateForSticker:sticker];
    }];
    
    [[self propViewModel].didSetCurrentStickerSignal.deliverOnMainThread subscribeNext:^(ACCRecordSelectEffectPack _Nullable x) {
        @strongify(self);
        IESEffectModel *sticker = x.first;
        [self updateGestureStateForSticker:sticker];
    }];

    [RACObserve(self.cameraService.recorder, recorderState).deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        ACCCameraRecorderState state = x.integerValue;
        self.closeGesture.enabled = state != ACCCameraRecorderStateRecording;
    }];
    
    // Skip 1 for initialization
    [[RACObserve(self.gestureService, sdkGesturesAction).deliverOnMainThread skip:1] subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        ACCRecordGestureAction action = x.integerValue;
        if (action == ACCRecordGestureActionDisable) {
            [self manuallyDisableSDKGesturesIfNeeded];
        } else if (action == ACCRecordGestureActionRecover) {
            [self manuallyEnableSDKGesturesIfNeeded];
        }
    }];
    
    self.scanService = IESAutoInline(self.serviceProvider, ACCScanService);
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

//when other component send signal in componentDidMount,this component's componentDidMount hasn't excute, so need read exist data;
- (void)p_readExistData
{
    if ([self propViewModel].appliedLocalEffect) {
         [self updateGestureStateForSticker:[self propViewModel].appliedLocalEffect];
    }
    if ([self propViewModel].currentSelectEffectPack) {
        IESEffectModel *sticker = [self propViewModel].currentSelectEffectPack.first;
        [self updateGestureStateForSticker:sticker];
    }
}

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCRecordGestureService), self.gestureService);
}

- (ACCRecordGestureServiceImpl *)gestureService
{
    if (!_gestureService) {
        _gestureService = [[ACCRecordGestureServiceImpl alloc] init];
    }
    return _gestureService;
}

#pragma mark - add gesture

- (void)addGestures
{
    if (self.hasAddGesture) {
        return;
    }
    self.hasAddGesture = YES;
    [self addPinchGestureForZoom];
    [self addSingleTapGesture];
    [self addDoubleTapGesture];
    [self addLongPressGesture];
    [self addPanGesture];
    [self addGesturesForSDK];
    [self disableSDKGesturesAndDisableTapFocus:NO];
    
    [self.cameraTapGesture requireGestureRecognizerToFail:self.doubleTapSwitchCamera];
    
    [[self.gestureService gesturesNeedAdded] enumerateObjectsUsingBlock:^(UIGestureRecognizer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.delegate = self;
    }];
}

#pragma mark - add zoom gesture

- (void)addPinchGestureForZoom
{
    [self addPinchGestureForZoomWithView:self.viewContainer.interactionView];
}

- (void)addPinchGestureForZoomWithView:(UIView *)view
{
    if (!view) {
        return;
    }
    
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGestureForZoom:)];
    pinchGesture.cancelsTouchesInView = NO;
    pinchGesture.delegate = self;
    [view addGestureRecognizer:pinchGesture];
    [self.gestureService.gesturesSet addObject:pinchGesture];
}

#pragma mark - Camera Tap Gesture

- (void)addSingleTapGesture
{
    [self addSingleTapGestureWithView:self.viewContainer.interactionView];
}

- (void)addSingleTapGestureWithView:(UIView *)view
{
    if (!view) {
        return;
    }
    
    UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleCameraTapGesture:)];
    singleTapGesture.numberOfTapsRequired = 1;
    singleTapGesture.delegate = self;
    [view addGestureRecognizer:singleTapGesture];
    self.cameraTapGesture = singleTapGesture;
}

- (void)handleCameraTapGesture:(UITapGestureRecognizer *)gesture
{
    CGPoint point = [gesture locationInView:gesture.view];
    point.x = [ACCRTL() isRTL]? gesture.view.acc_width - point.x :point.x;
    point = [self.cameraService.cameraPreviewView convertPoint:point fromView:gesture.view];
    if (ACCConfigBool(kConfigBool_enable_exposure_compensation)
        && ![[self propViewModel].currentSticker isTypeFaceReplace3D]
        && !self.repository.repoDuet.isDuet) {
        [self.cameraService.cameraControl changeFocusAndExposurePointTo:point];
    } else {
        [self.cameraService.cameraControl changeFocusPointTo:point];
        [self.cameraService.cameraControl changeExposurePointTo:point];
    }

    if ([ACCToolBarAdapterUtils useToolBarFoldStyle]) {
        ACCToolBarContainerAdapter *adapter = (ACCToolBarContainerAdapter *)self.viewContainer.barItemContainer;
        [adapter resetShrinkState];
    }

    [self.gestureService gestureDidRecognized:gesture];
}

- (BOOL)cameraTapGestureEnabled
{
    // if tapGesture is available, all normal gestures are available.
    return self.cameraTapGesture.enabled;
}

- (void)enableAllCameraGesture:(BOOL)enable
{
    if (!self.hasAddGesture) {
        [self addGestures];
    }
    if (enable) {
        [self.gestureService enableAllGestures];
    } else {
        [self.gestureService disableAllGestures];
    }
    self.cameraTapGesture.enabled = enable;
    self.exposureCompensationPanGesture.enabled = enable;
}

#pragma mark - add double gesture

- (void)addDoubleTapGesture
{
    [self addDoubleTapGestureWithView:self.viewContainer.interactionView];
}

- (void)addDoubleTapGestureWithView:(UIView *)view
{
    if (!view) {
        return;
    }
    _doubleTapSwitchCamera = [[ACCRecordTapGestureRecognizer alloc] initWithTarget:self action:@selector(handleCameraDoubleTapGesture:)];
    _doubleTapSwitchCamera.numberOfTapsRequired = 2;
    _doubleTapSwitchCamera.delegate = self;
    [_doubleTapSwitchCamera setIntervalBetweenTaps:0.2];
    [view addGestureRecognizer:_doubleTapSwitchCamera];
    [self.gestureService.gesturesSet addObject:_doubleTapSwitchCamera];
}

- (void)handleCameraDoubleTapGesture:(UIGestureRecognizer *)gesture
{
    if ([[self propViewModel].currentSticker isTypeAR]) {
        return;
    }
    if( ACCConfigBool(kConfigInt_enable_camera_switch_haptic)){
        if(@available(ios 10.0, *)){
            UISelectionFeedbackGenerator *selection = [[UISelectionFeedbackGenerator alloc] init];
            [selection selectionChanged];
        }
    }
    // 处于扫一扫模式不允许双击切换前后置
    if (self.scanService.currentMode == ACCScanModeNone) {
//        [self.cameraService.cameraControl switchToOppositeCameraPosition];
        [self.cameraSwapService switchToOppositeCameraPositionWithSource:ACCCameraSwapSourceDoubleTap];
    }
    // Track Event
    NSTimeInterval duration = [ACCMonitor() timeIntervalForKey:@"swap_camera"];
    NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.repository.repoTrack.referExtra];
    referExtra[@"to_status"] = self.cameraSwapService.currentCameraPosition == AVCaptureDevicePositionFront ? @"front" : @"back";
    referExtra[@"duration"] = @((long long)duration);
    referExtra[@"is_recording"] = [self.cameraService.recorder isRecording]? @(1):@(0);
    referExtra[@"enter_method"] = @"double_click";
    if (self.repository.repoContext.recordSourceFrom == AWERecordSourceFromUnknown) {
        [ACCTracker() trackEvent:@"flip_camera" params:referExtra needStagingFlag:NO];
    }
    [self.gestureService gestureDidRecognized:gesture];
}

- (void)addLongPressGesture
{
    [self addLongPressGestureWithView:self.viewContainer.interactionView];
}

- (void)addLongPressGestureWithView:(UIView *)view
{
    /// TODO: 前置判断
    if (!view) {
        return;
    }

    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleCameraLongPressGesture:)];
    longPressGesture.minimumPressDuration = 0.25;
    longPressGesture.delegate = self;
    [view addGestureRecognizer:longPressGesture];
    [self.gestureService.gesturesSet addObject:longPressGesture];
}

- (void)handleCameraLongPressGesture:(UILongPressGestureRecognizer *)longPressGesture
{
    [self.gestureService gestureDidRecognized:longPressGesture];
}

- (void)addPanGesture
{
    [self addPanGestureWithView:self.viewContainer.interactionView];
}

- (void)addPanGestureWithView:(UIView *)view
{
    if (!ACCConfigBool(kConfigBool_enable_exposure_compensation) || self.repository.repoDuet.isDuet) {
        return ;
    }
    if (view == nil) {
        return ;
    }

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleExposureCompensationPanGesture:)];
    panGesture.maximumNumberOfTouches = 1;
    panGesture.delegate = self;
    [view addGestureRecognizer:panGesture];
    RAC(panGesture, enabled) = RACObserve(self.focusViewModel, exposureCompensationGestureEnabled);
    self.exposureCompensationPanGesture = panGesture;
}

- (void)handleExposureCompensationPanGesture:(UIPanGestureRecognizer *)gesture
{
    UIView *panView = gesture.view;
    double velocityX = [gesture velocityInView:panView].x;
    double velocityY = [gesture velocityInView:panView].y;
    double translationY = [gesture translationInView:panView].y;
    float scaleRatio = 0.1;
    // translation compare with slider's real width
    float ratio = -translationY * scaleRatio / 110;

    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
                if (fabs(velocityX) < fabs(velocityY)) {
                    self.isHandleExposureCompensation = YES;
                } else {
                    self.isHandleExposureCompensation = NO;
                }
                [ACCTracker() trackEvent:@"tool_performance_EV"
                                  params:@{@"creation_id" : self.repository.repoContext.createId ?: @""}
                         needStagingFlag:NO];
        }
            break;
        case UIGestureRecognizerStateChanged:
            if (self.isHandleExposureCompensation) {
                [self.cameraService.cameraControl changeExposureBiasWithRatio:ratio];
                [gesture setTranslation:CGPointZero inView:panView];
            }
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
            self.isHandleExposureCompensation = NO;
            break;

        default:
            break;
    }
}

#pragma mark - zoom event

- (void)handlePinchGestureForZoom:(UIPinchGestureRecognizer *)pinch
{
    if ([IESAutoInline(self.serviceProvider, ACCLiveServiceProtocol) hasCreatedLiveRoom] || !self.cameraService.cameraControl.supprotZoom) {
        NSString *log = [NSString stringWithFormat:@"PinchForZoom end(camera not support): %@", [self.cameraService.cameraControl cameraZoomSupportedInfo]];
        AWELogToolInfo(AWELogToolTagRecord, @"%@", log);
        [ACCTracker() trackEvent:@"zoom"
                           params:@{@"camera_not_support_zoom" : log ?: @""}
                  needStagingFlag:NO];
        return;
    }

    CGFloat scale = self.cameraService.cameraControl.zoomFactor * pinch.scale;
    if ([self.cameraService.cameraControl currentInVirtualCameraMode]) {
            //这里要求在从0.9或者1.1倍焦距切换到1倍的时候要震动一次，但是zoom值是一个浮动变化的值，不一定刚好变为1，
            //所以这里采取了第一次从小于1变化到大于等于1，或者第一次从1.1跳变到小于等于一个足够小，但大于1的阈值的时候
            //（这里根据手势zoom值定的是1.09)，触发震动
            // It is required to vibrate once when switching from 0.9 or 1.1 to 1, but the zoom value is a
            // floating value, not necessarily just changing to 1, so here we take the first change from less
            // than 1 to greater than or equal to 1, or the first jump from 1.1 to less than or equal to a sufficiently
            //small, but greater than 1. When the threshold value (here according to the gesture zoom value is 1.09),
            //trigger vibration
            CGFloat wideZoomScale = 1;
            CGFloat feedbackThreshold = 0.09;
            BOOL isRecording = [self.cameraService.cameraControl status] == IESMMCameraStatusRecording;
            if (!isRecording) {
                if (scale > self.oldZoomFactor && self.oldZoomFactor > 0) {//zoom out
                    if (self.oldZoomFactor < wideZoomScale && scale >= wideZoomScale) {
                        [ACCTapicEngine() triggerWithType:ACCHapticTypeImpactLight];
                    }
                } else { //zoom in
                    CGFloat zoomInBorder = wideZoomScale + feedbackThreshold;
                    if (self.oldZoomFactor > zoomInBorder && scale <= zoomInBorder) {
                        [ACCTapicEngine() triggerWithType:ACCHapticTypeImpactLight];
                    }
                }
            }
            self.oldZoomFactor = scale;
            if (ACCConfigBool(kConfigBool_tools_shoot_advanced_setting_panel)) {
                UIGestureRecognizerState state = pinch.state;
                BOOL isGestureEnd = (state == UIGestureRecognizerStateFailed ||
                                     state == UIGestureRecognizerStateEnded ||
                                     state == UIGestureRecognizerStateCancelled);
                CGFloat minZoomFactor = self.cameraService.cameraControl.minZoomFactor;
                CGFloat maxZoomFactor = self.cameraService.cameraControl.maxZoomFactor;
                if (scale < minZoomFactor) {
                    scale = minZoomFactor;
                } else if (scale > maxZoomFactor) {
                    scale = maxZoomFactor;
                }
                [[AWERecorderTipsAndBubbleManager shareInstance] showZoomScaleHintViewWithContainer:self.viewContainer.interactionView
                                                                                          zoomScale:scale
                                                                                       isGestureEnd:isGestureEnd];
            }
        }
//        if (!self.hasTrackZoomingEvent) {
//            NSString *creationID = [self.filterViewModel.inputData.publishModel.referExtra acc_stringValueForKey:@"creation_id"];
//            [ACCTracker() trackEvent:@"digital_zoom"
//                              params:@{@"digital_zoom_value": @(scale),
//                                       @"creation_id": creationID ?: @""}
//                     needStagingFlag:NO];
//            self.hasTrackZoomingEvent = YES;
//        }

    [self.cameraService.cameraControl changeToZoomFactor:MAX(scale, 1.0f)];
    
    [pinch setScale:1.0f];

    if (fabs(scale - floor(scale)) < 0.1) {
        AWELogToolInfo(AWELogToolTagRecord, @"PinchForZoom end : scale = %f", scale);
    }

    [self.gestureService gestureDidRecognized:pinch];
}

#pragma mark - add sdk gesture

- (void)addGesturesForSDK
{
    [self addSDKPanGestureRecognizer];
    [self addSDKPinchGestureRecognizer];
    [self addSDKRotationGestureRecognizer];
    [self addSDKTapGestureRecognizer];
    [self addSDKLongPressGestureRecognizer];
}

- (void)addSDKPanGestureRecognizer
{
    UIView *view = self.viewContainer.interactionView;
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleSDKPanGesture:)];
    panGesture.maximumNumberOfTouches = 1;
    panGesture.cancelsTouchesInView = NO;
    if ([self.viewContainer.interactionView conformsToProtocol:@protocol(UIGestureRecognizerDelegate)]) {
        panGesture.delegate = (id<UIGestureRecognizerDelegate>)(self.viewContainer.interactionView);
    }
    [view addGestureRecognizer:panGesture];
    [self.sdkGesturesSet addObject:panGesture];
}

- (void)addSDKDuetLayoutPanGestureRecognizer
{
    if (self.sdkDuetLayoutPanGesture) {
        return;
    }
    UIView *view = self.viewContainer.interactionView;
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDuetSDKPanGesture:)];
    panGesture.maximumNumberOfTouches = 1;
    panGesture.cancelsTouchesInView = NO;
    panGesture.delegate = self;
    [view addGestureRecognizer:panGesture];
    self.sdkDuetLayoutPanGesture = panGesture;
 }


- (void)addSDKPinchGestureRecognizer
{
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleSDKPinchGesture:)];
    pinchGesture.delegate = self.arService.arGesturesDelegate;
    pinchGesture.cancelsTouchesInView = NO;
    [self.viewContainer.interactionView addGestureRecognizer:pinchGesture];
    [self.sdkGesturesSet addObject:pinchGesture];
}

- (void)addSDKRotationGestureRecognizer
{
    UIRotationGestureRecognizer *rotationGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleSDKRotationGesture:)];
    [self.viewContainer.interactionView addGestureRecognizer:rotationGesture];
    rotationGesture.cancelsTouchesInView = NO;
    rotationGesture.delegate = self.arService.arGesturesDelegate;
    [self.sdkGesturesSet addObject:rotationGesture];
}

- (void)addSDKTapGestureRecognizer
{
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSDKTapGesture:)];
    tapGes.numberOfTapsRequired = 1;
    tapGes.numberOfTouchesRequired = 1;
    [self.viewContainer.interactionView addGestureRecognizer:tapGes];
    tapGes.delegate = self;
    tapGes.cancelsTouchesInView = NO;
    [self.sdkGesturesSet addObject:tapGes];
}

- (void)addSDKLongPressGestureRecognizer
{
    UILongPressGestureRecognizer *longPressGes = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleSDKLongPressGesture:)];
    longPressGes.cancelsTouchesInView = NO;
    [self.viewContainer.interactionView addGestureRecognizer:longPressGes];
    [self.sdkGesturesSet addObject:longPressGes];
}

#pragma mark - sdk event

- (void)handleSDKPanGesture:(UIPanGestureRecognizer *)panGes
{
    [self p_handleSDKPanGesture:panGes];
}

- (void)handleDuetSDKPanGesture:(UIPanGestureRecognizer *)panGes
{
    if (self.hasAddDuetLayoutGesture) {
        [self p_handleSDKPanGesture:panGes];
    }
}

- (void)p_handleSDKPanGesture:(UIPanGestureRecognizer *)panGes
{
    CGPoint translation = [panGes translationInView:panGes.view];
    [panGes setTranslation:CGPointZero inView:panGes.view];
    translation.x = translation.x / panGes.view.frame.size.width * 2;
    translation.y =  translation.y / panGes.view.frame.size.height * 2;
    CGPoint velocity = [panGes velocityInView:panGes.view];

    UIView *view = self.cameraService.cameraPreviewView;
    CGPoint location = [view convertPoint:[panGes locationInView:panGes.view] fromView:panGes.view];
    if (!CGRectContainsPoint(view.bounds, location)) {
        return;
    }

    CGFloat width = view.acc_width;
    CGFloat height = view.acc_height;
    CGFloat screenRatio = 9.0f / 16.0f;
    CGFloat widthHeightRatio = width / height;

    if (isnan(widthHeightRatio) || isinf(widthHeightRatio)) {
        AWELogToolError2(@"handleSDKPanGesture", AWELogToolTagNone, @"unexpected width / height is nan or inf.");
        return;
    }

    if (widthHeightRatio > screenRatio) {
        CGFloat newHeight = width / screenRatio;
        CGFloat diff = (newHeight - height) * 0.5;
        height = newHeight;
        location.y += diff;
    } else if (widthHeightRatio < screenRatio) {
        CGFloat newWidth = height * screenRatio;
        CGFloat diff = (newWidth - width) * 0.5;
        width = newWidth;
        location.x += diff;
    } else {
        // do nothing
    }

    location.x = location.x / width;
    location.y = location.y / height;

    switch (panGes.state) {
        case UIGestureRecognizerStateBegan: {
            [ACCTracker() trackEvent:@"ar_prop_drag"
                                label:@"shoot_page"
                                value:nil
                                extra:[self p_currentEffectIdentifier]
                           attributes:nil];
            if (fabs(velocity.x)) {
                [ACCTracker() trackEvent:@"ar_prop_control_alert"
                                    label:@"shoot_page"
                                    value:nil
                                    extra:nil
                               attributes:nil];
            }
            [self.cameraService.cameraControl handleTouchDown:location withType:IESMMGestureTypePan];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            [self.cameraService.cameraControl handlePanEventWithTranslation:translation location:location];
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed: {
            [self.cameraService.cameraControl handleTouchUp:location withType:IESMMGestureTypePan];
            break;
        }
        default:
            break;
    }
}

- (void)handleSDKPinchGesture:(UIPinchGestureRecognizer *)pinchGes
{
    UIView *view = self.cameraService.cameraPreviewView;
    CGPoint location = [view convertPoint:[pinchGes locationInView:pinchGes.view] fromView:pinchGes.view];
    if (!CGRectContainsPoint(view.bounds, location)) {
        return;
    }

    CGFloat width = view.acc_width;
    CGFloat height = view.acc_height;
    CGFloat screenRatio = 9.0f / 16.0f;
    CGFloat widthHeightRatio = width / height;

    if (isnan(widthHeightRatio) || isinf(widthHeightRatio)) {
        AWELogToolError2(@"handleSDKPinchGesture", AWELogToolTagNone, @"unexpected width / height is nan or inf.");
        return;
    }

    if (widthHeightRatio > screenRatio) {
        CGFloat newHeight = width / screenRatio;
        CGFloat diff = (newHeight - height) * 0.5;
        height = newHeight;
        location.y += diff;
    } else if (widthHeightRatio < screenRatio) {
        CGFloat newWidth = height * screenRatio;
        CGFloat diff = (newWidth - width) * 0.5;
        width = newWidth;
        location.x += diff;
    } else {
        // do nothing
    }

    location.x = location.x / width;
    location.y = location.y / height;

    switch (pinchGes.state) {
        case UIGestureRecognizerStateBegan: {
            [ACCTracker() trackEvent:@"ar_prop_scale"
                               label:@"shoot_page"
                               value:nil
                               extra:[self p_currentEffectIdentifier]
                          attributes:nil];
            [self.cameraService.cameraControl handleTouchDown:location withType:IESMMGestureTypePinch];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            CGFloat scale = pinchGes.scale;
            [self.cameraService.cameraControl handleScaleEvent:scale];
            [pinchGes setScale:1];
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed: {
            [self.cameraService.cameraControl handleTouchUp:location withType:IESMMGestureTypePinch];
            break;
        }
        default:
            break;
    }
}

- (void)handleSDKRotationGesture:(UIRotationGestureRecognizer *)rotationGes
{
    UIView *view = self.cameraService.cameraPreviewView;
    CGPoint location = [view convertPoint:[rotationGes locationInView:rotationGes.view] fromView:rotationGes.view];
    if (!CGRectContainsPoint(view.bounds, location)) {
        return;
    }

    CGFloat width = view.acc_width;
    CGFloat height = view.acc_height;
    CGFloat screenRatio = 9.0f / 16.0f;
    CGFloat widthHeightRatio = width / height;

    if (isnan(widthHeightRatio) || isinf(widthHeightRatio)) {
        AWELogToolError2(@"handleSDKRotationGesture", AWELogToolTagNone, @"unexpected width / height is nan or inf.");
        return;
    }

    if (widthHeightRatio > screenRatio) {
        CGFloat newHeight = width / screenRatio;
        CGFloat diff = (newHeight - height) * 0.5;
        height = newHeight;
        location.y += diff;
    } else if (widthHeightRatio < screenRatio) {
        CGFloat newWidth = height * screenRatio;
        CGFloat diff = (newWidth - width) * 0.5;
        width = newWidth;
        location.x += diff;
    } else {
        // do nothing
    }

    location.x = location.x / width;
    location.y = location.y / height;

    switch (rotationGes.state) {
        case UIGestureRecognizerStateBegan: {
            [ACCTracker() trackEvent:@"ar_prop_spin"
                               label:@"shoot_page"
                               value:nil
                               extra:[self p_currentEffectIdentifier]
                          attributes:nil];
            [self.cameraService.cameraControl handleTouchDown:location withType:IESMMGestureTypeRotate];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            CGFloat rotate = rotationGes.rotation;
            [self.cameraService.cameraControl handleRotationEvent:rotate];
            [rotationGes setRotation:0];
            break;
        }

        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: {
            [self.cameraService.cameraControl handleTouchUp:location withType:IESMMGestureTypeRotate];
            break;
        }
        default:
            break;
    }
}

- (void)handleSDKTapGesture:(UITapGestureRecognizer *)tapGes
{
    UIView *view = self.cameraService.cameraPreviewView;
    CGPoint location = [view convertPoint:[tapGes locationInView:tapGes.view] fromView:tapGes.view];
    if (!CGRectContainsPoint(view.bounds, location)) {
        return;
    }

    CGFloat width = view.acc_width;
    CGFloat height = view.acc_height;
    CGFloat screenRatio = 9.0f / 16.0f;
    CGFloat widthHeightRatio = width / height;

    if (isnan(widthHeightRatio) || isinf(widthHeightRatio)) {
        AWELogToolError2(@"handleSDKTapGesture", AWELogToolTagNone, @"unexpected width / height is nan or inf.");
        return;
    }

    if (widthHeightRatio > screenRatio) {
        CGFloat newHeight = width / screenRatio;
        CGFloat diff = (newHeight - height) * 0.5;
        height = newHeight;
        location.y += diff;
    } else if (widthHeightRatio < screenRatio) {
        CGFloat newWidth = height * screenRatio;
        CGFloat diff = (newWidth - width) * 0.5;
        width = newWidth;
        location.x += diff;
    } else {
        // do nothing
    }

    location.x = location.x / width;
    location.y = location.y / height;

    [self.cameraService.cameraControl handleTouchEvent:location];

    [ACCTracker() trackEvent:@"ar_prop_click"
                       label:@"shoot_page"
                       value:nil
                       extra:[self p_currentEffectIdentifier]
                  attributes:nil];
}

- (void)handleSDKLongPressGesture:(UILongPressGestureRecognizer *)longPressGes
{
    UIView *view = self.cameraService.cameraPreviewView;
    CGPoint location = [view convertPoint:[longPressGes locationInView:longPressGes.view] fromView:longPressGes.view];
    if (!CGRectContainsPoint(view.bounds, location)) {
        return;
    }

    CGFloat width = view.acc_width;
    CGFloat height = view.acc_height;
    CGFloat screenRatio = 9.0f / 16.0f;
    CGFloat widthHeightRatio = width / height;

    if (isnan(widthHeightRatio) || isinf(widthHeightRatio)) {
        AWELogToolError2(@"handleSDKLongPressGesture", AWELogToolTagNone, @"unexpected width / height is nan or inf.");
        return;
    }

    if (widthHeightRatio > screenRatio) {
        CGFloat newHeight = width / screenRatio;
        CGFloat diff = (newHeight - height) * 0.5;
        height = newHeight;
        location.y += diff;
    } else if (widthHeightRatio < screenRatio) {
        CGFloat newWidth = height * screenRatio;
        CGFloat diff = (newWidth - width) * 0.5;
        width = newWidth;
        location.x += diff;
    } else {
        // do nothing
    }

    location.x = location.x / width;
    location.y = location.y / height;

    switch (longPressGes.state) {
        case UIGestureRecognizerStateBegan: {
            [ACCTracker() trackEvent:@"ar_prop_click"
                               label:@"shoot_page"
                               value:nil
                               extra:[self p_currentEffectIdentifier]
                          attributes:nil];
            [self.cameraService.cameraControl handleTouchDown:location withType:IESMMGestureTypeLongPress];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            [self.cameraService.cameraControl handleLongPressEventWithLocation:location];
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed: {
            [self.cameraService.cameraControl handleTouchUp:location withType:IESMMGestureTypeLongPress];
            break;
        }
        default:
            break;
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    [self.gestureService gesturesOnReceivedTouch];
    
    UIView *touchView = touch.view;
    BOOL hasFound = NO;
    NSMutableArray *queue = [[NSMutableArray alloc] init];
    [queue addObject:self.viewContainer.preview];
    while (queue.count) {
        UIView *front = [queue firstObject];
        [queue removeObjectAtIndex:0];
        for (NSInteger i = front.subviews.count - 1; i >= 0; i--) {
            UIView *view = front.subviews[i];
            if (view == touchView) {
                hasFound = YES;
                break;
            }
            [queue addObject:view];
        }
    }
    if (!hasFound && touchView.userInteractionEnabled && !touchView.hidden && touchView.alpha) {
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        return YES;
    }
    
    if ((gestureRecognizer == self.sdkDuetLayoutPanGesture
         || gestureRecognizer == self.exposureCompensationPanGesture)
        && otherGestureRecognizer == self.filterService.panGestureRecognizer) {
        return YES;
    }

    if (gestureRecognizer == self.closeGesture && otherGestureRecognizer == self.exposureCompensationPanGesture) {
        return NO;
    }
    
    if ([gestureRecognizer isKindOfClass:UISwipeGestureRecognizer.class]) {
        return YES;
    }
    
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == self.closeGesture && otherGestureRecognizer == self.exposureCompensationPanGesture) {
        return YES;
    }

    /// tapGesture has lower priority than longpressGesture
    if (gestureRecognizer == self.cameraTapGesture && [otherGestureRecognizer isKindOfClass:UILongPressGestureRecognizer.class]){
        return YES;
    }

    return NO;
}

- (void)duetLayoutDidApplyDuetEffect:(BOOL)enableDuetLayoutPanGesture
{
    self.hasAddDuetLayoutGesture = enableDuetLayoutPanGesture;
    if (enableDuetLayoutPanGesture) {
        [self addSDKDuetLayoutPanGestureRecognizer];
    }
    self.sdkDuetLayoutPanGesture.enabled = enableDuetLayoutPanGesture;
}

#pragma mark - private method

- (void)updateGestureStateForSticker:(IESEffectModel *)sticker
{
    if (!sticker || !([sticker isTypeAR] || [sticker isTypeTouchGes])) {
        [self disableSDKGesturesAndDisableTapFocus:[sticker needTransferTouch]];
        return;
    }
    
    if ([sticker isTypeAR] || [sticker isTypeTouchGes] || [sticker isEffectControlGame]) {
        [self disableNormalRecordGestures];
        
        if (ACCConfigBool(kConfigBool_tools_shoot_double_tap_except_game_ar_sticker)) {
            if ([sticker isEffectControlGame] || [sticker isTypeAR]) {
                self.doubleTapSwitchCamera.enabled = NO;
            } else {
                self.doubleTapSwitchCamera.enabled = YES;
            }
        }
        return;
    }
}

- (NSString *)p_currentEffectIdentifier
{
    return self.cameraService.effect.currentSticker.effectIdentifier;
}

- (void)manuallyDisableSDKGesturesIfNeeded
{
    if (!self.manuallyDisableSDKGestures) {
        if (!self.sdkGestureHasDisabled) {
            for (UIGestureRecognizer *g in self.sdkGesturesSet) {
                g.enabled = NO;
            }
            self.sdkGestureHasDisabled = YES;
        }
        self.cameraService.cameraPreviewView.enableInteraction = NO;
        self.manuallyDisableSDKGestures = YES;
    }
}

- (void)manuallyEnableSDKGesturesIfNeeded
{
    if (self.manuallyDisableSDKGestures) {
        if (self.sdkGestureHasDisabled) {
            for (UIGestureRecognizer *g in self.sdkGesturesSet) {
                g.enabled = YES;
            }
            self.sdkGestureHasDisabled = NO;
        }
        self.cameraService.cameraPreviewView.enableInteraction = YES;
        self.manuallyDisableSDKGestures = NO;
    }
}

#pragma mark - getter & setter

- (NSMutableSet *)sdkGesturesSet {
    if (!_sdkGesturesSet) {
        _sdkGesturesSet = [[NSMutableSet alloc] init];
    }
    return _sdkGesturesSet;
}

- (ACCPropViewModel *)propViewModel
{
    ACCPropViewModel *propViewModel = [self getViewModel:ACCPropViewModel.class];
    NSAssert(propViewModel, @"should not be nil");
    return propViewModel;
}

- (ACCFocusViewModel *)focusViewModel
{
    ACCFocusViewModel *focusViewModel = [self getViewModel:ACCFocusViewModel.class];
    NSAssert(focusViewModel, @"should not be nil");
    return focusViewModel;
}

@end
