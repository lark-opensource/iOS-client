//
//  ACCCameraSwapComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2020/12/30.

#import "ACCCameraSwapComponent.h"

#import <AVFoundation/AVCaptureSessionPreset.h>
#import <CreativeKit/UIView+AWEStudioAdditions.h>
#import <CreativeKit/UIButton+ACCAdditions.h>

#import "AWERecordDefaultCameraPositionUtils.h"
#import <CreativeKit/ACCRecorderViewContainer.h>
#import "ACCPropViewModel.h"
#import "ACCRecordFrameSamplingServiceProtocol.h"
#import <CreationKitArch/ACCRecorderToolBarDefines.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "AWERecorderTipsAndBubbleManager.h"
#import "ACCKaraokeService.h"
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import <CreationKitArch/ACCRecordTrackService.h>
#import "ACCRecordPropService.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoGameModel.h>
#import "ACCBarItem+Adapter.h"
#import "ACCScanService.h"
#import "ACCCameraSwapService.h"
#import <CameraClient/ACCRepoPointerTransferModel.h>

static const NSTimeInterval kACCBarItemContainerHideShowDuration = 0.2f;

@interface ACCCameraSwapComponent () <ACCCameraLifeCircleEvent, ACCRecordSwitchModeServiceSubscriber, ACCRecordPropServiceSubscriber, ACCRecorderViewContainerItemsHideShowObserver, ACCKaraokeServiceSubscriber, ACCScanServiceSubscriber>

@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, assign) BOOL isSwapCamera;
@property (nonatomic, assign) BOOL isSwitchAVMode; // receive camera capture first frame because of switching from karaoke audio mode to karaoke video mode.
@property (nonatomic, strong) ACCBarItem *swapBarItem;

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, weak) id<ACCCameraSwapService> cameraSwapService;
@property (nonatomic, strong) id<ACCRecordTrackService> trackService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCRecordPropService> propService;
@property (nonatomic, weak) id<ACCKaraokeService> karaokeService;
@property (nonatomic, weak) id<ACCScanService> scanService;

@end

/// service class extension
@interface ACCCameraSwapComponent () <ACCCameraSwapService>
@property (nonatomic, assign, readwrite) BOOL isUserSwappedCamera;
@property (nonatomic, assign, readwrite) AVCaptureDevicePosition currentCameraPosition;
@end

@implementation ACCCameraSwapComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, cameraSwapService, ACCCameraSwapService)
IESAutoInject(self.serviceProvider, trackService, ACCRecordTrackService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, propService, ACCRecordPropService)

IESOptionalInject(self.serviceProvider, karaokeService, ACCKaraokeService)

#pragma mark - ACCComponentProtocol

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.cameraService addSubscriber:self];
    [self.cameraService.message addSubscriber:self];
    [self.switchModeService addSubscriber:self];
    [self.propService addSubscriber:self];
    [self.karaokeService addSubscriber:self];
    self.scanService = IESAutoInline(serviceProvider, ACCScanService);
    [self.scanService addSubscriber:self];
}

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCCameraSwapService), self);
}

#pragma mark - ACCFeatureComponent

- (void)loadComponentView
{
    [self configSwapBarItem];
}

- (void)componentDidMount
{
    self.isFirstAppear = YES;
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    [self p_readExistData];
    [self p_bindViewModels];
}

- (void)componentWillAppear
{
    [self updateToolBarContainerVisibility];
}

- (void)componentDidAppear
{
    if (self.isFirstAppear) {
        self.isFirstAppear = NO;
        [self p_bindViewModelObserver];
    }
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

#pragma mark - set UI

- (void)configSwapBarItem
{
    ACCBarItemResourceConfig *barConfig = [[self.serviceProvider resolveObject:@protocol(ACCBarItemResourceConfigManagerProtocol)] configForIdentifier:ACCRecorderToolBarSwapContext];
    if (barConfig) {
        ACCBarItem *bar = [[ACCBarItem alloc] init];
        bar.title = barConfig.title;
        bar.imageName = barConfig.imageName;
        bar.useAnimatedButton = NO;
        bar.itemId = ACCRecorderToolBarSwapContext;
        bar.type = ACCBarItemFunctionTypeDefault;
        @weakify(self);
        bar.barItemActionBlock = ^(UIView * _Nonnull itemView) {
            @strongify(self);
            if (!self.isMounted) {
                return;
            }

            BOOL shouldSwitchPosition = self.cameraSwapButton.alpha == 1.0;
            if (!shouldSwitchPosition) {
                ACCBLOCK_INVOKE(self.cameraSwapButton.acc_disableBlock);
                return;
            }

            [ACCMonitor() startTimingForKey:@"swap_camera"];
            self.isSwapCamera = YES;
            if( ACCConfigBool(kConfigInt_enable_camera_switch_haptic)){
                if(@available(ios 10.0, *)){
                    UISelectionFeedbackGenerator *selection = [[UISelectionFeedbackGenerator alloc] init];
                    [selection selectionChanged];
                }
            }
            [self.cameraSwapService switchToOppositeCameraPositionWithSource:ACCCameraSwapSourceToolBarItem];
        };
        bar.needShowBlock = ^BOOL{
            @strongify(self);
            if (self.karaokeService.inKaraokeRecordPage && self.karaokeService.recordMode == ACCKaraokeRecordModeAudio) {
                return NO;
            }
            return YES;
        };
        [self.viewContainer.barItemContainer addBarItem:bar];
        self.swapBarItem = bar;
        self.cameraSwapButton.exclusiveTouch = YES;
        [self p_configSwapButtonAccessiblity];
    }
}

#pragma mark - accessiblity

- (void)p_configSwapButtonAccessiblity
{
    BOOL isFront = self.cameraSwapService.currentCameraPosition == AVCaptureDevicePositionFront;
    self.cameraSwapButton.accessibilityLabel = isFront ? @"摄像头已前置,点击翻转" : @"摄像头已后置,点击翻转";
    self.cameraSwapButton.accessibilityTraits = UIAccessibilityTraitButton;
}

#pragma mark - init methods

- (void)p_readExistData
{
    if ([self propViewModel].swapCameraBlock) {
        self.cameraSwapButton.acc_disableBlock = [self propViewModel].swapCameraBlock;
        BOOL enabled = [self propViewModel].swapCameraBlock ? NO : YES;
        self.swapBarItem.customView.alpha = enabled? 1.0 : 0.5;
    }
}

- (void)p_bindViewModels
{
    @weakify(self);
    [self.propViewModel.panelDisplayStatusSignal subscribeNext:^(NSNumber*  _Nullable x) {
        @strongify(self);
        [self.viewContainer.barItemContainer updateAllBarItems];
    }];
}

- (void)p_bindViewModelObserver
{
    @weakify(self);
    [[[RACObserve(self.cameraService.cameraControl, currentCameraPosition) distinctUntilChanged] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        if (!self.cameraService.cameraHasInit) {
            return;
        }
        // FIXME: @haoyipeng 这里会不会在没有真正切换摄像头的时候也触发了该动作？
        [self.cameraSwapButton acc_counterClockwiseRotate];
        self.cameraSwapButton.transform = CGAffineTransformIdentity;
        [self p_configSwapButtonAccessiblity];
        AVCaptureDevicePosition position = [x integerValue];
        if (self.isSwapCamera) {
            NSTimeInterval duration = [ACCMonitor() timeIntervalForKey:@"swap_camera"];
            NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.repository.repoTrack.referExtra];
            referExtra[@"to_status"] = self.cameraSwapService.currentCameraPosition == AVCaptureDevicePositionFront ? @"front" : @"back";
            referExtra[@"duration"] = @((long long)duration);
            referExtra[@"is_recording"] = [self.cameraService.recorder isRecording]? @(1):@(0);
            referExtra[@"enter_method"] = @"shoot_icon";
            if (self.repository.repoContext.recordSourceFrom == AWERecordSourceFromUnknown) {
                [ACCTracker() trackEvent:@"flip_camera" params:referExtra needStagingFlag:NO];
            }
            self.isSwapCamera = NO;
        }

        [AWERecordDefaultCameraPositionUtils setDefaultPosition:position];
        
        // 打点需要
        NSString *trackEvent = self.cameraSwapService.currentCameraPosition == AVCaptureDevicePositionFront ? @"rear_to_front" : @"rear_to_back";
        NSMutableDictionary *attributesInfo = @{@"is_photo":self.cameraService.recorder.cameraMode == HTSCameraModePhoto ? @1 : @0}.mutableCopy;
        if (self.repository.repoTrack.referExtra) {
            [attributesInfo addEntriesFromDictionary:self.repository.repoTrack.referExtra];
        }
        [ACCTracker() trackEvent:trackEvent
                                          label:@"shoot_page"
                                          value:nil
                                          extra:nil
                                     attributes:attributesInfo];
    }];
    
    [self.viewContainer addObserver:self];
    
    [RACObserve(self.cameraService.recorder, recorderState).deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        ACCCameraRecorderState state = x.integerValue;
        switch (state) {
            case ACCCameraRecorderStateNormal:
                if (self.viewContainer.isShowingPanel) {
                    [self.viewContainer.barItemContainer.barItemContentView acc_fadeHiddenDuration:kACCBarItemContainerHideShowDuration];
                } else {
                    [self updateToolBarContainerVisibility];
                }
                break;
            case ACCCameraRecorderStatePausing:
                if (self.repository.repoGame.gameType == ACCGameTypeNone && !self.viewContainer.isShowingPanel) {
                    if (ACCConfigBool(kConfigBool_tools_shoot_switch_camera_while_recording)) {
                        [self.viewContainer.barItemContainer updateAllBarItems];
                    } else {
                        [self updateToolBarContainerVisibility];
                    }
                }
                break;
            case ACCCameraRecorderStateRecording:
                if (ACCConfigBool(kConfigBool_tools_shoot_switch_camera_while_recording)) {
                    [self.viewContainer.barItemContainer updateAllBarItems];
                } else {
                    [self.viewContainer.barItemContainer.barItemContentView acc_fadeHiddenDuration:kACCBarItemContainerHideShowDuration];
                }
                break;
            default:
                break;
        }
    }];
}

#pragma mark - private methods

- (void)showPlaceholderForSwapCamera
{
    UIView<ACCBarItemCustomView> *customView = self.swapBarItem.customView;
    UIView *cloneView = [customView snapshotViewAfterScreenUpdates:NO];
    UIView *superview = self.viewContainer.barItemContainer.barItemContentView.superview;
    cloneView.frame = [customView convertRect:customView.frame toView:superview];
    cloneView.alpha = customView.alpha;
    [superview addSubview:cloneView];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [cloneView removeFromSuperview];
    });
}

#pragma mark - ACCRecorderViewContainerItemsHideShowObserver

- (void)shouldItemsShow:(BOOL)show animated:(BOOL)animated
{
    [self updateToolBarContainerVisibility];
}

// TODO: 把 ToolBar 的UI显隐逻辑挪出 SwapComponent
- (void)updateToolBarContainerVisibility
{
    // original there only observer the animate show hide, if meet some bug that should not show/hide this button when not animate, please modify to only support animate show hide observer.
    if ([self shouldHideToolBarContainer]) {
        [self.viewContainer.barItemContainer.barItemContentView acc_fadeHiddenDuration:kACCBarItemContainerHideShowDuration];
        [[AWERecorderTipsAndBubbleManager shareInstance] removeBubbleAndHintIfNeeded];
    } else {
        [self.viewContainer.barItemContainer.barItemContentView acc_fadeShowWithDuration:kACCBarItemContainerHideShowDuration];
        [self.viewContainer.barItemContainer updateAllBarItems];
    }
}

- (BOOL)shouldHideToolBarContainer
{
    if (self.viewContainer.isShowingPanel || self.viewContainer.itemsShouldHide) {
        return YES;
    }
    if (self.repository.repoGame.gameType != ACCGameTypeNone) {
        return YES;
    }
    if (self.cameraService.recorder.recorderState == ACCCameraRecorderStateRecording) {
        return YES;
    }
    if (self.scanService.currentMode != ACCScanModeNone) {
        return YES;
    }
    ACCRecordMode *mode = self.switchModeService.currentRecordMode;
    if (!mode.isPhoto && !mode.isVideo) {
        return YES;
    }
    return NO;
}

#pragma mark - ACCRecordPropServiceSubscriber

- (void)propServiceDidApplyProp:(IESEffectModel *)prop success:(BOOL)success
{
    // AR类型道具禁止切换前后置镜头，禁用切换按钮。
    [self updateSwapBarItemClickability];
}

- (void)updateSwapBarItemClickability
{
    if (!ACCBLOCK_INVOKE(self.swapBarItem.needShowBlock)) {
        return;
    }
    IESEffectModel *prop = self.propService.prop;
    if ([prop isTypeAR]) {
        self.swapBarItem.customView.alpha = 0.5;
        self.cameraSwapButton.acc_disableBlock = ^{
            [ACCToast() show: ACCLocalizedString(@"record_artext_disable_front_camera", @"AR类道具仅支持后置摄像头")];
        };
    } else {
        self.swapBarItem.customView.alpha = 1.0;
        self.cameraSwapButton.acc_disableBlock = nil;
    }
}

#pragma mark - ACCKaraokeServiceSubscriber

- (void)karaokeService:(id<ACCKaraokeService>)service recordModeDidChangeFrom:(ACCKaraokeRecordMode)prevMode to:(ACCKaraokeRecordMode)mode
{
    if (prevMode == ACCKaraokeRecordModeAudio && mode == ACCKaraokeRecordModeVideo) {
        self.isSwitchAVMode = YES;
    }
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarSwapContext];
    [self updateSwapBarItemClickability];
}

- (void)karaokeService:(id<ACCKaraokeService>)service inKaraokeRecordPageDidChangeFrom:(BOOL)prevState to:(BOOL)state
{
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarSwapContext];
    [self updateSwapBarItemClickability];
}

#pragma mark - ACCScanServiceSubscriber

-(void)scanService:(id<ACCScanService>)scanService didSwitchModeFrom:(ACCScanMode)oldMode to:(ACCScanMode)mode
{
    [self updateToolBarContainerVisibility];
    if (mode == ACCScanModeScan && self.cameraSwapService.currentCameraPosition ==  AVCaptureDevicePositionFront) {
        self.isSwapCamera = YES;
        [self.cameraSwapService switchToOppositeCameraPositionWithSource:ACCCameraSwapSourceToolBarItem];
    }
}

#pragma mark - ACCCameraLifeCircleEvent

- (void)onCameraFirstFrameDidRender:(id<ACCCameraService>)cameraService
{
    [self.trackService setRecordModeTrackName:self.switchModeService.currentRecordMode.trackIdentifier];
    [self.trackService trackEnterVideoShootPageWithSwapCamera:self.isSwapCamera || self.isSwitchAVMode];
    self.isSwitchAVMode = NO;
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    [self updateSwapBarItemClickability];
    [self updateToolBarContainerVisibility];
}

#pragma mark - property / getter

- (ACCPropViewModel *)propViewModel
{
    ACCPropViewModel *propViewModel = [self getViewModel:ACCPropViewModel.class];
    NSAssert(propViewModel, @"should not be nil");
    return propViewModel;
}

- (UIButton *)cameraSwapButton
{
    return [self.viewContainer.barItemContainer viewWithBarItemID:ACCRecorderToolBarSwapContext].barItemButton;
}

#pragma mark - CameraSwapService

- (BOOL)isUserSwappedCamera
{
    return self.repository.repoPointerTrans.fields.isUserSwappedCamera;
}

- (void)setIsUserSwappedCamera:(BOOL)isUserSwappedCamera
{
    self.repository.repoPointerTrans.fields.isUserSwappedCamera = isUserSwappedCamera;
}

/// methods
- (void)switchToCameraPosition:(AVCaptureDevicePosition)position source:(ACCCameraSwapSource)source {
    [self p_setUserSwappedWtihSource:source];
    [self.cameraService.cameraControl switchToCameraPosition:position];
}

- (void)switchToOppositeCameraPositionWithSource:(ACCCameraSwapSource)source {
    [self p_setUserSwappedWtihSource:source];
    [self.cameraService.cameraControl switchToOppositeCameraPosition];
}

- (void)syncCameraActualPosition {
    [self.cameraService.cameraControl syncCameraActualPosition];
}

- (AVCaptureDevicePosition)currentCameraPosition
{
    return [self.cameraService.cameraControl currentCameraPosition];
}

-(void)p_setUserSwappedWtihSource:(ACCCameraSwapSource)source
{
    self.isUserSwappedCamera = self.isUserSwappedCamera || source == ACCCameraSwapSourceDoubleTap || source == ACCCameraSwapSourceToolBarItem || source == ACCCameraSwapSourcePropPanel;
}

@end
