//
//  ACCRecordViewController.m
//  CameraClient
//
//  Created by guochenxiang on 2020/12/11.
//

#import <CameraClient/AWECameraManager.h>
#import <CreativeKit/UIDevice+ACCHardware.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CameraClient/ACCRecordConfigService.h>
#import "ACCRecordViewController.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CameraClient/AWECameraPreviewContainerView.h>
#import <CameraClient/ACCCreativePathManager.h>
#import <CreationKitInfra/ACCDeviceAuth.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import "ACCRepoKaraokeModelProtocol.h"
#import "ACCCreativePathConstants.h"
#import <CreativeKit/ACCViewModelContainer.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import "AWERecordFirstFrameTrackerNew.h"
#import "ACCRepoQuickStoryModel.h"
#import "AWEXScreenAdaptManager.h"
#import <CreativeKit/ACCFastComponentManager.h>

@interface ACCRecordViewController () <ACCCameraLifeCircleEvent>

@property (nonatomic, strong) ACCViewModelContainer *modelContainer;
@property (nonatomic, strong) NSNumber *enableOptimizeValue;

@end

@implementation ACCRecordViewController

#pragma mark - Life Cycle

- (void)dealloc
{
    [AWECameraManager sharedManager].shouldPreventNewRecordController = NO;
}

- (instancetype)initWithBusinessConfiguration:(id<ACCBusinessConfiguration>)business
{
    if (self = [super initWithBusinessConfiguration:business]) {
        [AWECameraManager sharedManager].shouldPreventNewRecordController = YES;
        id<ACCCameraService> cameraService = IESAutoInline(self.serviveProvider, ACCCameraService);
        [cameraService addSubscriber:self];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [[ACCCreativePathManager manager] setupObserve:self page:ACCCreativePageRecord];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ACCRecordBeofeWillAppearNotification object:self];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [[AWERecordFirstFrameTrackerNew sharedTracker] eventBegin:kAWERecordEventViewAppear];
    [super viewDidAppear:animated];
    [[AWERecordFirstFrameTrackerNew sharedTracker] eventEnd:kAWERecordEventViewAppear];
}

- (BOOL)prefersStatusBarHidden
{
    return ![UIDevice acc_isIPhoneX] || ACCViewFrameOptimizeContains(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize), ACCViewFrameOptimizeHideStatusBar);
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    let viewContainer = IESAutoInline(self.serviveProvider, ACCRecorderViewContainer);
    let cameraService = IESAutoInline(self.serviveProvider, ACCCameraService);
    [viewContainer containerViewDidLayoutSubviews];
    cameraService.cameraPreviewView.frame = [self cameraPreviewViewFrame];
}

- (CGRect)cameraPreviewViewFrame
{
    CGRect frame = [UIScreen mainScreen].bounds;
    if ([UIDevice acc_isIPad]) {
        frame = [AWEXScreenAdaptManager customFullFrame];
    } else {
        frame = CGRectMake(0, [AWEXScreenAdaptManager standPlayerFrame].origin.y, frame.size.width, [AWEXScreenAdaptManager standPlayerFrame].size.height);
    }
    return frame;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    let cameraService = IESAutoInline(self.serviveProvider, ACCCameraService);
    [cameraService updatePreviewViewOrientation];
}

#pragma mark - ACCViewController

- (id<ACCComponentManager>)creatComponentManager
{
    if ([self enableFirstRenderOptimize]) {
        ACCFastComponentManager *componentManager = [[ACCFastComponentManager alloc] init];
        componentManager.loadPhaseDelegate = self;
        return componentManager;
    }else {
        ACCComponentManager *componentManager = [[ACCComponentManager alloc] init];
        componentManager.loadPhaseDelegate = self;
        return componentManager;
    }
}

- (void)prepareForLoadComponent
{
    [super prepareForLoadComponent];
    let viewContainer = IESAutoInline(self.serviveProvider, ACCRecorderViewContainer);
    let cameraService = IESAutoInline(self.serviveProvider, ACCCameraService);
    @weakify(self);
    @weakify(viewContainer);
    viewContainer.interactionBlock = ^{
        @strongify(self);
        @strongify(viewContainer);
        if ([self.componentManager respondsToSelector:@selector(forceLoadComponentsWhenInteracting)]) {
            [AWERecordFirstFrameTrackerNew sharedTracker].forceLoadComponent = YES;
            [self.componentManager forceLoadComponentsWhenInteracting];
        }
        viewContainer.interactionBlock = nil;
    };
    [self.componentManager registerLoadViewCompletion:^{
        [viewContainer viewContainerDidLoad];
    }];
    [self.componentManager registerMountCompletion:^{
        [cameraService markComponentsLoadFinished];
    }];
    [viewContainer.preview insertSubview:cameraService.cameraPreviewView atIndex:0];

    let configService = IESAutoInline(self.serviveProvider, ACCRecordConfigService);
    [configService setupInitialConfig];
}

- (void)beforeLoadLazyComponent
{
    let configService = IESAutoInline(self.serviveProvider, ACCRecordConfigService);
    [configService configRecordingMultiSegmentMaximumResolutionLimit];
}

- (ACCViewModelContainer *)viewModelContainer {
    ACCViewModelContainer *viewModelContainer = [super viewModelContainer];
    if (viewModelContainer.viewModelList.count != 0) {
        return viewModelContainer;
    }
    viewModelContainer.viewModelList = @[
        @"ACCRecordCloseViewModel",
        @"ACCFocusViewModel",
        // 道具相关 在道具重构全量后可以去除
        @"ACCEffectControlGameViewModel",
        @"ACCRecordSelectPropViewModel",
        @"ACCPropViewModel",
        @"ACCPropPickerViewModel",
        
        @"ACCQuickAlbumViewModel",
        @"ACCQuickStoryRecorderTipsViewModel",
        @"ACCSpeedControlViewModel",
        @"ACCRecordSubmodeViewModel",
        @"ACCRecordUploadButtonViewModel",
    ];
    return viewModelContainer;
}

#pragma mark - ACCCameraLifeCircleEvent

- (void)onCameraDidStartRender:(id<ACCCameraService>)cameraService
{
    if ([self.componentManager respondsToSelector:@selector(finishFirstRenderTask)]) {
        [self.componentManager finishFirstRenderTask];
    }
}

- (BOOL)enableFirstRenderOptimize
{
    if ([self disableArchOptimizeForKaraoke]) {
        return NO;
    }
    if (self.enableOptimizeValue) {
        return [self.enableOptimizeValue boolValue];
    }
    if ([self.inputData isKindOfClass:[ACCRecordViewControllerInputData class]]) {
        ACCRecordViewControllerInputData *inputData = self.inputData;
        if (inputData.publishModel.repoDuet.isDuet || inputData.publishModel.repoDraft.isDraft || inputData.publishModel.repoDraft.isBackUp) {
            return NO;
        }
    }
    let switchModeService = IESAutoInline(self.serviveProvider, ACCRecordSwitchModeService);
    BOOL enableFirstRenderOptimize = [self enableOptimizeArchPerformance] && [ACCDeviceAuth isCameraAuth] && [switchModeService isVideoCaptureMode];
    self.enableOptimizeValue = @(enableFirstRenderOptimize);
    return enableFirstRenderOptimize;
}

- (BOOL)disableArchOptimizeForKaraoke
{
    if ([self.inputData isKindOfClass:[ACCRecordViewControllerInputData class]]) {
        ACCRecordViewControllerInputData *inputData = self.inputData;
        // disable optimization for backup/draft of karaoke
        ACCRepoDraftModel *draft = inputData.publishModel.repoDraft;
        ACCRepoContextModel *context = inputData.publishModel.repoContext;
        if ((draft.isBackUp || draft.isDraft) && context.videoType == AWEVideoTypeKaraoke) {
            return YES;
        }
        
        // disable optimization for karaoke that enter with music
        id<ACCRepoKaraokeModelProtocol> repoKaraoke = [inputData.publishModel extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
        if ([inputData.publishModel.repoQuickStory.initialTab isEqualToString:ACCLandingTabKeyKaraoke] && repoKaraoke.enterWithMusic) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)enableOptimizeArchPerformance
{
    if ([self disableArchOptimizeForKaraoke]) {
        return NO;
    }
    ACCOptimizePerformanceType type = ACCConfigEnum(kConfigInt_component_performance_architecture_optimization_type, ACCOptimizePerformanceType);
    return ACCOptimizePerformanceTypeContains(type, ACCOptimizePerformanceTypeRecorderWithForceLoad);
}

@end
