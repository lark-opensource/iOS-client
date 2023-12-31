//
//  ACCEffectControlGameComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by 李辉 on 2020/3/29.
//

#import "ACCEffectControlGameComponent.h"

#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreationKitComponents/ACCFilterService.h>
#import "ACCEffectControlGameViewModel.h"
#import "AWEVideoGameCameraContainerView.h"
#import <CreationKitArch/ACCRecordTrackService.h>
#import "ACCRecordSubmodeViewModel.h"
#import <CameraClient/ACCRecordViewControllerInputData.h>

// sinkage
#import <CreationKitInfra/ACCResponder.h>
#import "ACCPropViewModel.h"
#import "ACCRecordFlowService.h"
#import "ACCRecordSelectMusicService.h"
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoGameModel.h>
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import <CreationKitArch/ACCRepoVideoInfoModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>

@interface ACCEffectControlGameComponent ()
@property (nonatomic, weak) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCRecordSelectMusicService> musicService;
@property (nonatomic, strong) id<ACCFilterService> filterService;

@property (nonatomic, assign) BOOL gameStarted;
@property (nonatomic, assign) HTSCameraMode gamePreviousCameraMode;
@property (nonatomic, assign) BOOL isMicrophoneMuted;
@property (nonatomic, assign) BOOL isGameResignActive;
@property (nonatomic, assign) BOOL previousKeepAlive;
@property (nonatomic, assign) BOOL gameHasNoGuideVide;
@property (nonatomic, assign) BOOL componentHasAppeared;
@property (nonatomic, strong) AWEVideoGameCameraContainerView *gameCameraContainer;
@property (nonatomic, strong) ACCEffectControlGameViewModel *viewModel;
@property (nonatomic, strong) id<ACCRecordTrackService> trackService;
@property (nonatomic, readonly) ACCRecordSubmodeViewModel *submodeViewModel;
@end

@implementation ACCEffectControlGameComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, trackService, ACCRecordTrackService)
IESAutoInject(self.serviceProvider, musicService, ACCRecordSelectMusicService)
IESAutoInject(self.serviceProvider, filterService, ACCFilterService)

- (void)setupGameBlocks
{
    @weakify(self);
    self.viewModel.getCurrentStickerBlock = ^IESEffectModel * _Nonnull{
        @strongify(self);
        return self.propViewModel.currentSticker;
    };

    self.viewModel.handleEffectControlMessageBlock = ^(ACCEffectControlMessageType type) {
        @strongify(self);
        [self handleEffectMessage:type];
    };
}

#pragma mark - handle message
- (void)handleEffectMessage:(ACCEffectControlMessageType)type
{
    switch (type) {
        case ACCEffectControlMessageTypeStartGame:
            [self startGame];
            break;
        case ACCEffectControlMessageTypeFinishGame:
            [self finishAndExportGame];
            break;
        case ACCEffectControlMessageTypeNoGuide:
            self.gameHasNoGuideVide = YES;
            break;
        default:
            break;
    }
}

- (void)startGame
{
    NSMutableDictionary *attributes = [self.viewModel.inputData.publishModel.repoTrack.referExtra mutableCopy];
    [attributes addEntriesFromDictionary:@{
        @"prop_id" : self.propViewModel.currentSticker.effectIdentifier ? : @""
    }];
    [ACCTracker() trackEvent:@"click_game_play_button" params:attributes needStagingFlag:NO];
    self.isGameResignActive = NO;
    self.gameStarted = YES;
    
    [self.viewModel sendGameStatusSignal:ACCEffectGameStatusWillStart];
    [self.viewModel sendGameStatusSignal:ACCEffectGameStatusStart];
    
    if ([self.flowService markedTimesCount] > 0) {
        [self.flowService deleteAllSegments];
    }
    [self.flowService startRecordWithDelayRecord:NO];
    [self.trackService trackRecordVideoEventWithCameraService:self.cameraService];
    AWELogToolInfo(AWELogToolTagRecord, @"game start to record");
}

- (void)finishAndExportGame
{
    if (self.gameStarted) {
        [self.flowService stopRecordAndExportVideo];
        self.gameStarted = NO;
    }
}

- (void)resetGame
{
    [self preResetGame];
    IESEffectModel *currentSticker = self.propViewModel.currentSticker;
    [currentSticker effectStickerInfo].needReload = YES;
    [self.cameraService.effect acc_applyStickerEffect:nil];
    @weakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        [self.cameraService.effect acc_applyStickerEffect:currentSticker];
    });
    self.gameCameraContainer.hidden = NO;
}

- (void)quitGame
{
    [self preResetGame];
    self.gameCameraContainer.hidden = YES;
    @weakify(self);
    //delay 0.1 second is aiming at make sure that camera pause completed: we found that
    //camera call back will still being called after paused.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        [self restoreRecordContextForGame];
    });
}

- (void)preResetGame {
    self.gameStarted = NO;
    [self.viewModel sendGameStatusSignal:ACCEffectGameStatusReset];
    [self.flowService pauseRecord];
    [self.flowService deleteAllSegments];
}

#pragma mark - Life Cycle

- (void)componentDidMount
{
    ACCLog(@"componentDidMount");
    @weakify(self);
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationWillResignActiveNotification object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(NSNotification *_Nullable x) {
        @strongify(self);
        if (!self.isMounted) {
            return;
        }
        if ([ACCResponder topViewController] == self.rootVC) {
            IESEffectBGMType pauseType = IESEffectBGMTypeNormal;
            if (self.viewModel.inputData.publishModel.repoGame.gameType == ACCGameTypeEffectControlGame &&
                self.viewModel.inputData.publishModel.repoFlowControl.step == AWEPublishFlowStepCapture &&
                !self.flowService.exporting) {
                self.isGameResignActive = YES;
                pauseType |= IESEffectTypeGame;
                [self.cameraService.effect pauseEffectPropBGM:pauseType];//must do pause before apply:nil
                [self.cameraService.effect acc_applyStickerEffect:nil];
            }
        }
        self.gameStarted = NO;
    }];
    
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidBecomeActiveNotification object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(NSNotification *_Nullable x) {
        @strongify(self);
        if (!self.isMounted) {
            return;
        }
        if (self.viewModel.inputData.publishModel.repoGame.gameType == ACCGameTypeEffectControlGame) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                @strongify(self);
                self.isGameResignActive = NO;
                if (self.componentHasAppeared) {
                    [self resetGame];
                }
            });
        }
    }];
    
    [self.viewModel.showGameSignal.deliverOnMainThread subscribeNext:^(void(^complete)(void)) {
        @strongify(self);
        [self showEffectControlGameWithCompletion:complete];
    }];

    [self p_readExistData];
    [self p_bindViewModels];
}

- (void)componentDidUnmount
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)componentWillAppear
{
    self.componentHasAppeared = YES;
    if (self.viewModel.inputData.publishModel.repoGame.gameType == ACCGameTypeEffectControlGame) {
        [self resetGame];
    }
}

- (void)componentDidDisappear
{
    self.componentHasAppeared = NO;
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

//when other component send signal in componentDidMount,this component's componentDidMount hasn't excute, so need read exist data;
- (void)p_readExistData
{
    if ([self propViewModel].effectWillApply) {
        [self p_effectWillApply:[self propViewModel].effectWillApply];
    }
    if ([self propViewModel].appliedLocalEffect) {
        [self p_appliedLocalEffect:[self propViewModel].appliedLocalEffect];
    }
    if ([self propViewModel].didApplyEffectPack) {
        [self p_didApplyEffectPack:[self propViewModel].didApplyEffectPack];
    }
}

- (void)p_bindViewModels
{
    @weakify(self);
    //prop
    [[self propViewModel].willApplyStickerSignal.deliverOnMainThread subscribeNext:^(IESEffectModel *sticker) {
        @strongify(self);
        [self p_effectWillApply:sticker];
    }];
    [[self propViewModel].didApplyLocalStickerSignal.deliverOnMainThread subscribeNext:^(IESEffectModel *sticker) {
        @strongify(self);
        [self p_appliedLocalEffect:sticker];
    }];
    [[self propViewModel].didApplyStickerSignal.deliverOnMainThread subscribeNext:^(ACCDidApplyEffectPack _Nullable x) {
        @strongify(self);
        [self p_didApplyEffectPack:x];
    }];
    //switch camera by game
    [[self.viewModel.switchCameraPositionSignal deliverOnMainThread] subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if (self.cameraService.cameraHasInit) {
            NSAssert(self.cameraService.cameraControl, @"exception");
            AVCaptureDevicePosition switchPostion = (AVCaptureDevicePosition)[x integerValue];
            if ([self.cameraService.cameraControl currentCameraPosition] != switchPostion) {
                [self.cameraService.cameraControl switchToOppositeCameraPosition];
            }
        }
    }];
}

- (void)p_effectWillApply:(IESEffectModel *)sticker
{
    if (sticker.isEffectControlGame) {
        self.gameCameraContainer.closeBtn.enabled = YES;
        [self.viewModel startReceiveMessageFromCamera];
    }
}

- (void)p_appliedLocalEffect:(IESEffectModel *)sticker
{
    self.viewModel.inputData.publishModel.repoGame.gameType = sticker.gameType;
    if (sticker.gameType == ACCGameTypeEffectControlGame) {
        [self.viewModel startReceiveMessageFromCamera];
        [self showEffectControlGameWithCompletion:nil];
    }
}

- (void)p_didApplyEffectPack:(ACCDidApplyEffectPack _Nullable)pack
{
    IESEffectModel *sticker = pack.first;
    if (sticker.isEffectControlGame) {
        self.gameCameraContainer.closeBtn.enabled = YES;
    }
}

#pragma mark - Game

- (void)showGameCameraContainer
{
    if (!self.gameCameraContainer) {
        self.gameCameraContainer = [[AWEVideoGameCameraContainerView alloc] init];
        self.gameCameraContainer.hidden = YES;
        self.gameCameraContainer.isShowingForEffectControlGame = YES;
        self.gameHasNoGuideVide = NO;
        [self.viewContainer.popupContainerView insertSubview:self.gameCameraContainer atIndex:0];
        @weakify(self);
        [[self.gameCameraContainer.closeBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
            @strongify(self);
            if (self.flowService.isExporting) {
                return;
            }
            if (self.gameStarted && !self.gameHasNoGuideVide) {
                [self resetGame];
            } else {
                [self quitGame];
            }
        }];
    }
    self.gameCameraContainer.hidden = NO;
    self.gameCameraContainer.closeBtn.enabled = YES;
    [self.gameCameraContainer showWithAnimated:NO completion:^{
    }];
}

- (void)showEffectControlGameWithCompletion:(void (^)(void))completion
{
    void(^showGameCameraContainer)(void) = ^{
        [self showGameCameraContainer];
        NSMutableDictionary *attributes = [self.viewModel.inputData.publishModel.repoTrack.referExtra mutableCopy];
        [attributes addEntriesFromDictionary:@{
            @"prop_id" : self.propViewModel.currentSticker.effectIdentifier ? : @""
        }];
        [ACCTracker() trackEvent:@"enter_prop_game_page" params:attributes needStagingFlag:NO];
        
        [self backupRecordContextForGame];
        
        self.submodeViewModel.swipeGestureEnabled = NO;
        self.filterService.panGestureRecognizerEnabled = NO;

        self.viewModel.inputData.publishModel.repoGame.gameType = ACCGameTypeEffectControlGame;
        [self.viewModel sendGameStatusSignal:ACCEffectGameStatusDidShow];
        UIView *progressView = [self.viewContainer.layoutManager viewForType:ACCViewTypeProgress];
        progressView.hidden = YES;
    };
    
    NSUInteger segmentCount = [[self flowService] markedTimesCount];
    if (segmentCount > 0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:ACCLocalizedString(@"av_sticker_game_clear_hint", @"使用游戏道具将清除已录制视频，确定要使用该道具？")  message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        @weakify(self);
        [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedCurrentString(@"com_mig_confirm_mtsudt") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            NSMutableDictionary *attributes = [self.viewModel.inputData.publishModel.repoTrack.referExtra mutableCopy];
            [attributes addEntriesFromDictionary:@{
                @"to_status" : @"confirm",
                @"prop_id" : self.propViewModel.currentSticker.effectIdentifier ? : @""
            }];
            [ACCTracker() trackEvent:@"shoot_video_delete_confirm" params:attributes needStagingFlag:NO];
            [self.flowService deleteAllSegments];
            ACCBLOCK_INVOKE(showGameCameraContainer);
            ACCBLOCK_INVOKE(completion);
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedCurrentString(@"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            [self.propViewModel.stickerFeatureManager clearStickerAllEffect];
            
            NSMutableDictionary *attributes = [self.viewModel.inputData.publishModel.repoTrack.referExtra mutableCopy];
            [attributes addEntriesFromDictionary:@{
                @"to_status" : @"cancel",
                @"prop_id" : self.propViewModel.currentSticker.effectIdentifier ? : @""
            }];
            [ACCTracker() trackEvent:@"shoot_video_delete_confirm" params:attributes needStagingFlag:NO];
        }]];
        [ACCAlert() showAlertController:alertController animated:YES];
    } else {
        ACCBLOCK_INVOKE(showGameCameraContainer);
        ACCBLOCK_INVOKE(completion);
    }
}

#pragma mark - Game Utils

- (void)backupRecordContextForGame
{
    [self.propViewModel.stickerFeatureManager hideStickerViewController:YES];
    [self.viewContainer showItems:NO animated:NO];
    self.viewContainer.switchModeContainerView.hidden = YES;
    self.viewContainer.barItemContainer.barItemContentView.hidden = YES;
    self.isMicrophoneMuted = self.cameraService.recorder.videoData.isMicMuted;
    self.viewModel.inputData.publishModel.repoVideoInfo.videoMuted = NO;
    [self.viewModel operateMusicWithType:ACCEffectGameMusicOperationTypeBackup];
    self.gamePreviousCameraMode = self.cameraService.recorder.cameraMode;
    self.cameraService.recorder.cameraMode = HTSCameraModeVideo;
    [self.cameraService.cameraControl resetCameraZoomFactor];
    if (!self.viewModel.inputData.publishModel.repoDuet.isDuet) {
        [self.cameraService.recorder removePlayer];
    }

    [self.cameraService.effect muteEffectPropBGM:NO];
    [self.cameraService.filter acc_removeFilterEffect:self.filterService.currentFilter];
    [self.cameraService.recorder.videoData muteMicrophone:NO];
}

- (void)restoreRecordContextForGame
{
    [self.propViewModel.stickerFeatureManager clearStickerAllEffect];
    [self.viewModel operateMusicWithType:ACCEffectGameMusicOperationTypeRecover];
    [IESAutoInline(self.serviceProvider, ACCRecordConfigService) configAudioIfsetUp:NO withCompletion:NULL];
    [self.musicService updateAudioRangeWithStartLocation:0];
    [self.cameraService.recorder resetVideoRecordReady];
    [self.cameraService.cameraControl stopAudioCapture];
    self.cameraService.recorder.cameraMode = self.gamePreviousCameraMode;
    [self.cameraService.recorder.videoData muteMicrophone:self.isMicrophoneMuted];

    if (ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab) && ACCConfigBool(kConfigBool_horizontal_scroll_change_subtab)) {
        self.submodeViewModel.swipeGestureEnabled = YES;
        self.filterService.panGestureRecognizerEnabled = NO;
    } else {
        self.filterService.panGestureRecognizerEnabled = YES;
    }

    self.gameCameraContainer.closeBtn.enabled = NO;
    
    [self.viewModel sendDidbackToRecordSignal];
    
    UIView *progressView = [self.viewContainer.layoutManager viewForType:ACCViewTypeProgress];
    progressView.hidden = NO;
    [self.flowService deleteAllSegments];
    
    if (!self.propViewModel.stickerFeatureManager.stickerController.hasShownBefore) {
        [self.propViewModel.stickerFeatureManager showStickerViewControllerWithBlock:nil];
    }
    [self.propViewModel.stickerFeatureManager hideStickerViewController:NO];
    self.viewContainer.isShowingPanel = YES;
    [self.viewContainer showItems:NO animated:YES];
    if (self.viewModel.inputData.publishModel.repoMusic.music) {
        [self.cameraService.effect muteEffectPropBGM:YES];
    }

    [self.filterService applyFilterForCurrentCameraWithShowFilterName:NO sendManualMessage:NO];
    self.viewModel.inputData.publishModel.repoGame.gameType = ACCGameTypeNone;
}

#pragma mark - getter


-(ACCEffectControlGameViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self getViewModel:ACCEffectControlGameViewModel.class];
        [self setupGameBlocks];
    }
    NSAssert(_viewModel, @"should not be nil");
    return _viewModel;
}

- (UIViewController *)rootVC
{
    if ([self.controller isKindOfClass:UIViewController.class]) {
        return (UIViewController *)(self.controller);
    }
    NSAssert([self.controller isKindOfClass:UIViewController.class], @"controller should be vc");
    return nil;
}

- (ACCPropViewModel *)propViewModel
{
    ACCPropViewModel *propViewModel = [self getViewModel:ACCPropViewModel.class];
    NSAssert(propViewModel, @"should not be nil");
    return propViewModel;
}

- (ACCRecordSubmodeViewModel *)submodeViewModel
{
    return [self getViewModel:ACCRecordSubmodeViewModel.class];
}

@end
