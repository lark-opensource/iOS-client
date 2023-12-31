//
//  ACCAcousticAlgorithmComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by xiafeiyu on 2021/6/5.
//

#import "ACCAcousticAlgorithmComponent.h"

#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/AWECameraContainerToolButtonWrapView.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCMacrosTool.h>
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreationKitRTProtocol/ACCCameraControlEvent.h>
#import <CreationKitRTProtocol/ACCCameraLifeCircleEvent.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitInfra/UILabel+ACCAdditions.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <ReactiveObjC/NSObject+RACPropertySubscribing.h>
#import <CreativeKit/ACCMacros.h>

#import "ACCAudioPortService.h"
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import <CreativeKit/ACCProtocolContainer.h>
#import "AWERepoVideoInfoModel.h"
#import "ACCAECModelManager.h"
#import "ACCRecorderProtocolD.h"
#import "AWERepoTrackModel.h"
#import "AWERepoContextModel.h"
#import "AWERepoDuetModel.h"
#import "ACCConfigKeyDefines.h"
#import "ACCRecorderToolBarDefinesD.h"
#import "ACCRecorderViewContainerImpl.h"

static NSString * const kACCUserOpenedEBKey = @"user_eb";

static NSString * const kACCHasShownOpenEBToastKey = @"open_eb";
static NSString * const kACCHasShownCloseEBToastKey = @"close_eb";

@interface ACCAcousticAlgorithmComponent() <ACCCameraControlEvent, ACCCameraLifeCircleEvent>

@property (nonatomic, assign) BOOL audioCaptureInitialized;
@property (nonatomic, weak) id<ACCRecorderViewContainer> viewContainer;

@property (nonatomic, strong, readwrite) ACCGroupedPredicate *openAECPredicate;
@property (nonatomic, assign) BOOL AECOpened;

@property (nonatomic, strong, readwrite) ACCGroupedPredicate *openDAPredicate;
@property (nonatomic, assign) BOOL DAOpened;

@property (nonatomic, strong, readwrite) ACCGroupedPredicate *openLEPredicate;
@property (nonatomic, assign) BOOL LEOpened;
@property (nonatomic, strong) NSMutableArray<ACCLoudnessLUFSProvider> *lufsProvider;

@property (nonatomic, strong) AWECameraContainerToolButtonWrapView *EBCustomView; // 侧边栏按钮 Wrapper View
@property (nonatomic, strong) ACCBarItem *EBBarItem; // 侧边栏按钮 Item
@property (nonatomic, strong, readwrite) ACCGroupedPredicate *showEBBarItemPredicate; // 是否显示侧边栏按钮
@property (nonatomic, strong, readwrite) ACCGroupedPredicate *openEBPredicate; // 是否允许打开耳返
@property (nonatomic, assign, readwrite) BOOL userOpenedEarback; // 用户打开了耳返
@property (nonatomic, assign) BOOL EBOpened; // 当前耳返状态

@property (nonatomic, strong, readwrite) ACCGroupedPredicate *forceRecordAudioPredicate;

/**
 * @note This component should rely only on cameraService and audioPortService.
 */
@property (nonatomic, weak) id<ACCCameraService> cameraService;
@property (nonatomic, weak) id<ACCAudioPortService> audioPortService;

@end

@implementation ACCAcousticAlgorithmComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer);

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.cameraService = IESAutoInline(serviceProvider, ACCCameraService);
    self.audioPortService = IESAutoInline(serviceProvider, ACCAudioPortService);
    @weakify(self);
    [[self.audioPortService.IOPortChangeSignal takeUntil:self.rac_willDeallocSignal].deliverOnMainThread subscribeNext:^(RACTwoTuple * _Nullable x) {
        @strongify(self);
        if (!self.cameraService.cameraHasInit) {
            return;
        }
        [self openAlgorithmsIfNeeded];
        [self enableForceRecordAudioIfNeeded];
        [self updateBarItemsVisibility];
    }];
    [self.cameraService.cameraControl addSubscriber:self];
}

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    self.userOpenedEarback = [ACCCache() boolForKey:kACCUserOpenedEBKey];
    @weakify(self);
    [RACObserve(self.cameraService.recorder, recorderState).deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self updateBarItemsVisibility];
    }];
    [self openAlgorithmsIfNeeded];
    [self enableForceRecordAudioIfNeeded];
    [self updateBarItemsVisibility];
}

- (void)loadComponentView
{
    [self createEBBarItem];
}

#pragma mark - ACCCameraLifeCycleEvent

- (void)onCreateCameraCompleteWithCamera:(id<ACCCameraService>)cameraService
{
    [self openAlgorithmsIfNeeded];
    [self enableForceRecordAudioIfNeeded];
    [self updateBarItemsVisibility];
}

#pragma mark - ACCCameraControlEvent

- (void)onDidInitAudioCapture
{
    self.audioCaptureInitialized = YES;
    [self openAlgorithmsIfNeeded];
}

- (void)onWillReleaseAudioCapture
{
    self.audioCaptureInitialized = NO;
    id<ACCRecorderProtocol> recorder = self.cameraService.recorder;
    [recorder setAECEnabled:NO modelPath:nil];
    [recorder setTimeAlignEnabled:NO modelPath:nil timeAlignCallback:nil];
    [recorder setBalanceEnabled:NO targetLufs:0];
    // audio capture 释放后，耳返自然也失效了，无需 setEnableEarBack:NO。
    // [recorder setEnableEarBack:NO];
    self.AECOpened = NO;
    self.DAOpened = NO;
    self.LEOpened = NO;
    self.EBOpened = NO;
}

#pragma mark - Acoustic Algorithm

- (void)openAlgorithmsIfNeeded
{
    // If audio capture is not initialized, enabling algorithms will not take effect.
    if (!self.audioCaptureInitialized) {
        return;
    }
    [self openAECIfNeeded];
    [self openDAIfNeeded];
    [self openLEIfNeeded];
    [self openEBIfNeeded];
}

- (void)openAECIfNeeded
{
    BOOL openAEC = [self.openAECPredicate evaluate];
    if (openAEC == self.AECOpened) {
        // If target state and current state are the same ....
        return;
    }
    // do not open AEC when algorithm model has not been downloaded.
    NSString *path = [ACCAECModelManager AECModelPath];
    if (openAEC && ACC_isEmptyString(path)) {
        [self.cameraService.recorder setAECEnabled:NO modelPath:nil];
    } else {
        [self.cameraService.recorder setAECEnabled:openAEC modelPath:path];
        self.AECOpened = openAEC;
    }
}

- (void)openDAIfNeeded
{
    BOOL openDA = [self.openDAPredicate evaluate];
    if (openDA == self.DAOpened) {
        // If target state and current state are the same ....
        return;
    }
    NSString *path = [ACCAECModelManager DAModelPath];
    // do not open DA when algorithm model has not been not downloaded.
    if (openDA && !ACC_isEmptyString(path)) {
        @weakify(self);
        [ACCGetProtocol(self.cameraService.recorder, ACCRecorderProtocolD) setTimeAlignEnabled:YES modelPath:path timeAlignCallback:^(float ret) {
            @strongify(self);
            if (self.repository.repoVideoInfo.fragmentInfo.count == 1) {
                self.repository.repoVideoInfo.delay = (NSInteger)ret;
            }
        }];
    } else {
        [ACCGetProtocol(self.cameraService.recorder, ACCRecorderProtocolD) setTimeAlignEnabled:NO modelPath:nil timeAlignCallback:nil];
    }
    self.DAOpened = openDA;
}

- (void)openLEIfNeeded
{
    BOOL openLE = [self.openLEPredicate evaluate];
    if (openLE == self.LEOpened) {
        // If target state and current state are the same ....
        return;
    }
    NSInteger LUFS = ACCLoudnessUFLInvalid;
    for (ACCLoudnessLUFSProvider provider in [self.lufsProvider copy]) {
        LUFS = MIN(LUFS, provider());
    }
    [ACCGetProtocol(self.cameraService.recorder, ACCRecorderProtocolD) setBalanceEnabled:openLE targetLufs:LUFS];
    self.LEOpened = openLE;
}

- (void)registerLUFSProvider:(ACCLoudnessLUFSProvider)provider
{
    [self.lufsProvider acc_addObject:provider];
}

- (void)unregisterLUFProvider:(ACCLoudnessLUFSProvider)provider
{
    [self.lufsProvider acc_removeObject:provider];
}

- (void)openEBIfNeeded
{
    BOOL openEB = [self.openEBPredicate evaluate];
    if (openEB != self.EBOpened) {
        [self.cameraService.recorder setEnableEarBack:openEB];
        self.EBOpened = openEB;
        self.userOpenedEarback = openEB;
        if (openEB && ![ACCCache() boolForKey:kACCHasShownOpenEBToastKey]) {
            [ACCToast() show:@"已打开耳返"];
            [ACCCache() setBool:YES forKey:kACCHasShownOpenEBToastKey];
        }
        if (!openEB && ![ACCCache() boolForKey:kACCHasShownCloseEBToastKey]) {
            [ACCToast() show:@"已关闭耳返"];
            [ACCCache() setBool:YES forKey:kACCHasShownCloseEBToastKey];
        }
    }
}

- (void)setEBOpened:(BOOL)EBOpened
{
    _EBOpened = EBOpened;
    self.EBCustomView.barItemButton.selected = EBOpened;
}

#pragma mark - Bar Items

- (void)createEBBarItem
{
    ACCAnimatedButton *ebButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeScale];
    [ebButton setImage:ACCResourceImage(@"ear_back_off") forState:UIControlStateNormal];
    [ebButton setImage:ACCResourceImage(@"ear_back_on") forState:UIControlStateSelected];
    
    UILabel *ebLabel = [[UILabel alloc] acc_initWithFont:[UIFont boldSystemFontOfSize:10]
                                             textColor:UIColor.whiteColor
                                                  text:@"耳返"];
    ebLabel.textAlignment = NSTextAlignmentCenter;
    [ebLabel acc_addShadowWithShadowColor:ACCColorFromRGBA(22, 24, 35, 0.2) shadowOffset:CGSizeMake(0, 1) shadowRadius:1];
    ebLabel.isAccessibilityElement = NO;
    
    self.EBCustomView = [[AWECameraContainerToolButtonWrapView alloc] initWithButton:ebButton label:ebLabel itemID:ACCRecorderToolBarEarBackContext];
    @weakify(self);
    self.EBCustomView.itemViewDidClicked = ^(__kindof UIButton * _Nonnull sender) {
        @strongify(self);
        self.userOpenedEarback = !self.userOpenedEarback;
        [self openEBIfNeeded];
        [ACCCache() setBool:self.userOpenedEarback forKey:kACCUserOpenedEBKey];
        [self trackClickListenBack];
    };
    self.EBBarItem = [[ACCBarItem alloc] initWithCustomView:self.EBCustomView itemId:ACCRecorderToolBarEarBackContext];
    self.EBBarItem.needShowBlock = ^BOOL{
        @strongify(self);
        return [self.showEBBarItemPredicate evaluate] && self.cameraService.recorder.recorderState != ACCCameraRecorderStateRecording;
    };
    [self.viewContainer.barItemContainer addBarItem:self.EBBarItem];
}

// 是否可见
- (void)updateBarItemsVisibility
{
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarEarBackContext];
}

#pragma mark - Force Record Audio

- (void)enableForceRecordAudioIfNeeded
{
    BOOL enable = [self.forceRecordAudioPredicate evaluate];
    void(^excuteBlock)(void) = ^(void){
        // No need to cache previous state since calling these methods is not time-consuming.
        [self.cameraService.recorder setForceRecordAudio:enable];
        [self.cameraService.recorder setForceRecordWithMusicEnd:enable];
    };
    if (self.repository.repoContext.enableTakePictureDelayFrameOpt) {
        dispatch_async(dispatch_get_global_queue(0, 0), excuteBlock);
    } else {
        excuteBlock();
    }
}

#pragma mark - Track

- (void)trackClickListenBack
{
    NSMutableDictionary *params = [self.repository.repoTrack.referExtra mutableCopy];
    [params addEntriesFromDictionary:self.repository.repoTrack.mediaCountInfo];
    if (self.repository.repoContext.videoType == AWEVideoTypeKaraoke) {
        params[@"enter_from"] = @"pop_music_shoot_page";
    } else if (self.repository.repoDuet.isDuetSing) {
        params[@"enter_from"] = @"video_shoot_page";
    }
    params[@"to_status"] = self.userOpenedEarback ? @"on" : @"off";
    [ACCTracker() trackEvent:@"click_listen_back" params:params];
}

#pragma mark - Getters

- (ACCGroupedPredicate *)openAECPredicate
{
    if (!_openAECPredicate) {
        _openAECPredicate = [[ACCGroupedPredicate alloc] initWithOperand:ACCGroupedPredicateOperandOr];
    }
    return _openAECPredicate;
}

- (ACCGroupedPredicate *)openDAPredicate
{
    if (!_openDAPredicate) {
        _openDAPredicate = [[ACCGroupedPredicate alloc] initWithOperand:ACCGroupedPredicateOperandOr];
    }
    return _openDAPredicate;
}

- (ACCGroupedPredicate *)openLEPredicate
{
    if (!_openLEPredicate) {
        _openLEPredicate = [[ACCGroupedPredicate alloc] initWithOperand:ACCGroupedPredicateOperandOr];
    }
    return _openLEPredicate;
}

- (ACCGroupedPredicate *)showEBBarItemPredicate
{
    if (!_showEBBarItemPredicate) {
        _showEBBarItemPredicate = [[ACCGroupedPredicate alloc] initWithOperand:ACCGroupedPredicateOperandOr];
    }
    return _showEBBarItemPredicate;
}

- (ACCGroupedPredicate *)openEBPredicate
{
    if (!_openEBPredicate) {
        _openEBPredicate = [[ACCGroupedPredicate alloc] initWithOperand:ACCGroupedPredicateOperandOr];
    }
    return _openEBPredicate;
}

- (NSMutableArray<ACCLoudnessLUFSProvider> *)lufsProvider
{
    if (!_lufsProvider) {
        _lufsProvider = [NSMutableArray array];
    }
    return _lufsProvider;
}

- (ACCGroupedPredicate *)forceRecordAudioPredicate
{
    if (!_forceRecordAudioPredicate) {
        _forceRecordAudioPredicate = [[ACCGroupedPredicate alloc] initWithOperand:ACCGroupedPredicateOperandOr];
    }
    return _forceRecordAudioPredicate;
}


@end
