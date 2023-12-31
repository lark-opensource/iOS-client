//
//  ACCRecordCountdownComponent.m
//  Pods
//
//  Created by guochenxiang on 2019/8/5.
//

#import "ACCRecordCountdownComponent.h"
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/NSTimer+ACCAdditions.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CreationKitInfra/ACCResponder.h>
#import "AWECameraContainerIconManager.h"
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import "AWERecorderTipsAndBubbleManager.h"
#import "AWERecordLoadingView.h"
#import "AWEDelayRecordView.h"
#import "ACCKaraokeService.h"
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreationKitArch/ACCRecorderToolBarDefines.h>
#import "ACCCountDownViewModel.h"
#import "ACCRecordFlowService.h"
#import "ACCRecordPropService.h"
#import "ACCRecordConfigService.h"
#import "ACCFlowerService.h"
#import <CreationKitArch/ACCRecordTrackService.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitArch/ACCRepoGameModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import "AWERepoVideoInfoModel.h"
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CameraClient/AWEVideoFragmentInfo.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import "ACCPropViewModel.h"
#import "ACCBarItem+Adapter.h"

#define kAWEDelayRecordPanelPadding 6

typedef NS_ENUM(NSUInteger, ACCCountDownDismissType) {
    ACCCountDownDismissTypeOnlyDismiss,
    ACCCountDownDismissTypeNeedRecord,
};

@interface ACCRecordCountdownComponent () <
AWEAudioWaveformSliderViewDelegate,
ACCPanelViewDelegate,
ACCRecordVideoEventHandler,
ACCRecordConfigDurationHandler,
ACCRecordFlowServiceSubscriber,
ACCCameraLifeCircleEvent,
ACCRecordSwitchModeServiceSubscriber,
ACCRecordPropServiceSubscriber,
ACCKaraokeServiceSubscriber
>

@property (nonatomic, weak, readonly) UIViewController *containerVC;

@property (nonatomic, strong) AWEDelayRecordView *delayRecordView; //卡节拍 / 倒计时

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) NSTimer *audioWaveformPlayTimer;

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, weak) id<ACCKaraokeService> karaokeService;
@property (nonatomic, strong) id<ACCRecordPropService> propService;
@property (nonatomic, strong) id<ACCFlowerService> flowerService;

@property (nonatomic, strong) ACCCountDownViewModel *viewModel;

@property (nonatomic, assign) ACCCountDownDismissType dismissType;

@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, assign) BOOL applicationActive;
@property (nonatomic, strong) AWERecordLoadingView *loadingView;

@property (nonatomic, assign) BOOL forbidCountdown;

@end

@implementation ACCRecordCountdownComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, propService, ACCRecordPropService)
IESAutoInject(self.serviceProvider, flowerService, ACCFlowerService)

IESOptionalInject(self.serviceProvider, karaokeService, ACCKaraokeService)

#pragma mark - ACCComponentProtocol
- (void)applicationWillResignActive:(NSNotification *)notification
{
    self.applicationActive = NO;
    if ([ACCResponder topViewController] == self.containerVC) {
        [self.player pause];
        [self audioWaveformRemoveTimer];
    }
    [self.loadingView removeFromSuperview];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    self.applicationActive = YES;
    if ([ACCResponder topViewController] == self.containerVC) {
        if (self.viewContainer.isShowingPanel) {
            [self.player play];
            [self audioWaveformAddTimerIfNeeded];
        }
    }
}

- (void)loadComponentView
{
    [self setupUI];
}

- (void)componentDidMount
{
    [self.viewModel configDelayRecordMode];
    
    [self.viewContainer.panelViewController registerObserver:self];
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    self.isFirstAppear = YES;
    self.applicationActive = YES;
    [self bindViewModel];
}

- (void)bindViewModel
{
    @weakify(self);
    [[self propViewModel].didApplyStickerSignal.deliverOnMainThread subscribeNext:^(ACCDidApplyEffectPack _Nullable x) {
        @strongify(self);
        IESEffectModel *prop = x.first;
        BOOL success = x.second.boolValue;
        [self propServiceDidApplyProp:prop success:success];
    }];
}

- (ACCPropViewModel *)propViewModel
{
    return [self getViewModel:ACCPropViewModel.class];
}

- (void)componentWillAppear
{
    if (self.isFirstAppear) {
        [self.viewModel configDelayRecordMode];
        [self updateDelayRecordButtonWithMode:self.viewModel.delayRecordMode];
    }
}

- (void)componentDidAppear
{
    if (self.isFirstAppear) {
        self.isFirstAppear = NO;
    }
}

- (void)componentDidUnmount
{
    [self.viewContainer.panelViewController unregisterObserver:self];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)setupUI
{
    id<ACCBarItemContainerView> toolBarContainerView = self.viewContainer.barItemContainer;

    ACCBarItemResourceConfig *barConfig = [[self.serviceProvider resolveObject:@protocol(ACCBarItemResourceConfigManagerProtocol)] configForIdentifier:ACCRecorderToolBarDelayRecordContext];
    if (barConfig) {
        ACCBarItem *barItem = [[ACCBarItem alloc] initWithImageName:(self.viewModel.delayRecordMode == AWEDelayRecordMode3S) ? @"icon_camera_timer_3s" : @"icon_camera_timer_10s" title:ACCLocalizedCurrentString(@"countdown") itemId:ACCRecorderToolBarDelayRecordContext];
        barItem.type = ACCBarItemFunctionTypeCover;
        @weakify(self);
        barItem.needShowBlock = ^BOOL{
            @strongify(self);
            ACCRecordMode *mode = self.switchModeService.currentRecordMode;
            return mode.isVideo && !self.karaokeService.inKaraokeRecordPage && ![self.cameraService.recorder isRecording] && !self.flowerService.isShowingPhotoProp;
        };
        barItem.barItemActionBlock = ^(UIView * _Nonnull itemView) {
            @strongify(self);
            if (!self.isMounted) {
                return;
            }
            [self handleClickDelayStartAction];
        };
        [toolBarContainerView addBarItem:barItem];
    }

    if (self.viewModel.inputData.publishModel.repoDuet.isDuet) {
        [self.delayRecordView.audioWaveformContainerView showNoMusicWaveformView:NO];
    }
}

#pragma mark - ACCCameraLifeCircleEvent

- (void)cameraService:(id<ACCCameraService>)cameraService didChangeDuration:(CGFloat)duration totalDuration:(CGFloat)totalDuration
{
    if (self.repository.repoGame.gameType != ACCGameTypeNone) {
        return;
    }
    if (self.flowService.isDelayRecord) {
        CGFloat pauseTime = [self viewModel].countDownModel.toBePlayedLocation * self.repository.repoContext.maxDuration;
        if (totalDuration >= pauseTime) {
            if (pauseTime < self.repository.repoContext.maxDuration - 0.1) {
                [self.flowService pauseRecord];
            }
        }
    }
}

#pragma mark - private method

- (void)updateDelayRecordUIWithCurrentDuration:(CGFloat)currentDuration
{
    CGFloat maxDuration = self.repository.repoContext.maxDuration;
    BOOL enabled = (currentDuration < maxDuration);
    id<ACCBarItemContainerView> toolBarContainerView = self.viewContainer.barItemContainer;
    ACCBarItem *barItem = [toolBarContainerView barItemWithItemId:ACCRecorderToolBarDelayRecordContext];
    if (barItem && barItem.customView) {
        barItem.customView.enabled = enabled;
    }
}

- (void)handleClickDelayStartAction
{
    if (self.forbidCountdown) {
        [ACCToast() show:@"该道具不支持倒计时功能"];
        return;
    }
    
    if (self.cameraService.recorder.isRecording) {
        return;
    }
    [self.cameraService.effect acc_retainForbiddenMusicPropPlayCount];
    [[AWERecorderTipsAndBubbleManager shareInstance] removePropRecommendMusicBubble];
    [ACCTracker() trackEvent:@"count_down"
                                      label:@"shoot_page"
                                      value:nil
                                      extra:nil
                                 attributes:self.repository.repoTrack.referExtra];

    [ACCTracker() trackEvent:@"count_down" params:self.repository.repoTrack.referExtra needStagingFlag:NO];
    
    [self.viewContainer.panelViewController showPanelView:self.delayRecordView duration:0.49];
}

- (void)configPlayerWithAudioURL:(NSURL *)audioURL
{
    AVAsset *asset = [self.viewModel musicAsset];
    if (!asset) {
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:audioURL options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
        if (asset) {
            [self.repository.repoVideoInfo.video addAudioWithAsset:asset];
            AVPlayerItem *item = [[AVPlayerItem alloc] initWithAsset:asset];
            self.player = [[AVPlayer alloc] initWithPlayerItem:item];
        }
    } else {
        AVPlayerItem *item = [[AVPlayerItem alloc] initWithAsset:asset];
        self.player = [[AVPlayer alloc] initWithPlayerItem:item];
    }
}

- (void)setupPlayer
{
    NSURL *audioURL = self.repository.repoMusic.music.loaclAssetUrl;
    if (self.viewModel.inputData.publishModel.repoDuet.isDuet) {
        audioURL = self.viewModel.inputData.publishModel.repoDuet.duetLocalSourceURL;
    }
    if (audioURL) { // has audioURL
        [self configPlayerWithAudioURL:audioURL];
    } else {
        self.player = nil;
    }
}

- (void)destoryPlayer
{
    self.player = nil;
}

- (void)audioWaveformAddTimerIfNeeded
{
    AVAsset *asset = [self.viewModel musicAsset];

    if (asset) {
        [self.audioWaveformPlayTimer invalidate];
        self.audioWaveformPlayTimer = nil;
        @weakify(self);
        self.audioWaveformPlayTimer = [NSTimer acc_scheduledTimerWithTimeInterval:1. / 24 block:^(NSTimer * _Nonnull timer) {
            @strongify(self);
            [self audioWaveformPlayTimerAction];
        } repeats:YES];
    }
}

- (void)audioWaveformRemoveTimer
{
    [self.audioWaveformPlayTimer invalidate];
    self.audioWaveformPlayTimer = nil;
}

- (void)audioWaveformPlayTimerAction
{
    AVAsset *asset = [self.viewModel musicAsset];

    Float64 currentTime = CMTimeGetSeconds(self.player.currentTime);
    Float64 totalTime = CMTimeGetSeconds(asset.duration);
    HTSAudioRange audioRange = self.repository.repoMusic.audioRange;
    
    [self.delayRecordView.audioWaveformContainerView updatePlayingLocation:(currentTime - audioRange.location) / self.repository.repoContext.maxDuration];
    
    NSTimeInterval maxThreshold = audioRange.location + self.viewModel.countDownModel.toBePlayedLocation * self.repository.repoContext.maxDuration;
    if (currentTime >= maxThreshold || currentTime >= totalTime) {
        [self.player seekToTime:CMTimeMakeWithSeconds(audioRange.location + [self flowService].currentDuration, NSEC_PER_SEC)];
        [self.player play];
    }
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        [self.player play];
    } else {
        [self.player pause];
    }
}

- (void)clickDelayRecordView
{
    self.dismissType = ACCCountDownDismissTypeOnlyDismiss;
    [self.viewContainer.panelViewController dismissPanelView:self.delayRecordView duration:0.15];
    [self.cameraService.effect acc_releaseForbiddenMusicPropPlayCount];
}

- (void)clickDelayRecord
{
    NSMutableDictionary *params = @{}.mutableCopy;
    [params addEntriesFromDictionary:self.repository.repoTrack.referExtra];
    params[@"countdown_type"] = self.viewModel.delayRecordMode == AWEDelayRecordMode3S ? @"3s" : @"10s";
    [ACCTracker() trackEvent:@"count_down_start" params:params needStagingFlag:NO];
    
    self.dismissType = ACCCountDownDismissTypeNeedRecord;
    [self.viewContainer.panelViewController dismissPanelView:self.delayRecordView duration:0.15];
}

//切换delay模式按钮的点击事件
- (void)switchDelayModebuttonClicked:(UIButton *)sender
{
    if (sender == self.delayRecordView.audioWaveformContainerView.leftButton) {
        if (self.viewModel.delayRecordMode == AWEDelayRecordMode3S) {
            return;
        }
        sender.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.19];
        [sender setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        sender.accessibilityLabel = @"三秒已选中";
        self.delayRecordView.audioWaveformContainerView.rightButton.accessibilityLabel = @"十秒未选中";
        self.delayRecordView.audioWaveformContainerView.rightButton.backgroundColor = [UIColor clearColor];
        [self.delayRecordView.audioWaveformContainerView.rightButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.34] forState:UIControlStateNormal];
        [self.viewModel setDelayRecordMode:AWEDelayRecordMode3S];
        [self updateDelayRecordButtonWithMode:AWEDelayRecordMode3S];
        [ACCToast() show:[NSString stringWithFormat:ACCLocalizedString(@"count_down_switch_toast", @"已切换至 %d 秒倒计时"),3]];
    } else {
        if (self.viewModel.delayRecordMode == AWEDelayRecordMode10S) {
            return;
        }
        sender.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.19];
        [sender setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        sender.accessibilityLabel = @"十秒已选中";
        self.delayRecordView.audioWaveformContainerView.leftButton.accessibilityLabel = @"三秒未选中";
        self.delayRecordView.audioWaveformContainerView.leftButton.backgroundColor = [UIColor clearColor];
        [self.delayRecordView.audioWaveformContainerView.leftButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.34] forState:UIControlStateNormal];
        [self.viewModel setDelayRecordMode:AWEDelayRecordMode10S];
        [self updateDelayRecordButtonWithMode:AWEDelayRecordMode10S];
        [ACCToast() show:[NSString stringWithFormat:ACCLocalizedString(@"count_down_switch_toast",@"已切换至 %d 秒倒计时"),10]];
    }
    NSMutableDictionary *params = @{}.mutableCopy;
    params[@"enter_from"] = @"video_shoot_page";
    params[@"shoot_way"] = self.repository.repoTrack.referString ? : @"";
    params[@"creation_id"] = self.repository.repoContext.createId ? : @"";
    params[@"content_type"] = self.repository.repoTrack.referExtra[@"content_type"] ? : @"";
    params[@"to_status"] = self.viewModel.delayRecordMode == AWEDelayRecordMode3S ? @"3s" : @"10s";
    [ACCTracker() trackEvent:@"select_countdown_type" params:params needStagingFlag:NO];
}

- (void)updateDelayRecordButtonWithMode:(AWEDelayRecordMode)delayRecordMode
{
    id<ACCRecorderBarItemContainerView> toolBarContainerView = self.viewContainer.barItemContainer;
    ACCBarItem *barItem = [toolBarContainerView barItemWithItemId:ACCRecorderToolBarDelayRecordContext];
    if (barItem) {
        id<ACCBarItemCustomView> customView = [toolBarContainerView viewWithBarItemID:ACCRecorderToolBarDelayRecordContext];
        if (customView) {
            customView.imageName = (delayRecordMode == AWEDelayRecordMode3S ? @"icon_camera_timer_3s" : @"icon_camera_timer_10s");
            barItem.imageName = customView.imageName;
        }
    }
}

#pragma mark - AWEAudioWaveformSliderViewDelegate

- (void)audioWaveformSliderView:(AWEAudioWaveformSliderView *)sliderView touchEnd:(CGFloat)percent
{
    [ACCTracker() trackEvent:@"change_beat"
                                      label:@"beat_page"
                                      value:nil
                                      extra:nil
                                 attributes:self.repository.repoTrack.referExtra];
    
    if ([self.viewModel musicAsset]) {
        CGFloat minusTime = 3;//选中位置位置后，往前推3秒，再播放
        
        HTSAudioRange audioRange = self.repository.repoMusic.audioRange;
        CGFloat currentTime = percent * self.repository.repoContext.maxDuration + audioRange.location;
        CGFloat seekTime = currentTime - minusTime;
        if (seekTime < [self flowService].currentDuration + audioRange.location) {
            seekTime = [self flowService].currentDuration + audioRange.location;
        }
        [self.player seekToTime:CMTimeMakeWithSeconds(seekTime, NSEC_PER_SEC)];
        [self.player play];
    }
}

#pragma mark - setter getter

- (AWEDelayRecordView *)delayRecordView
{
    if (!_delayRecordView) {
        _delayRecordView = [[AWEDelayRecordView alloc] initWithFrame:self.viewContainer.interactionView.bounds model:self.viewModel.countDownModel];
        [_delayRecordView.delayRecordButton addTarget:self action:@selector(clickDelayRecord) forControlEvents:UIControlEventTouchUpInside];
        [_delayRecordView addTarget:self action:@selector(clickDelayRecordView) forControlEvents:UIControlEventTouchUpInside];
        [_delayRecordView.audioWaveformContainerView.leftButton addTarget:self action:@selector(switchDelayModebuttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_delayRecordView.audioWaveformContainerView.rightButton addTarget:self action:@selector(switchDelayModebuttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_delayRecordView.audioWaveformContainerView setSelectedButtonWithDelayMode:self.viewModel.delayRecordMode];
        [_delayRecordView.audioWaveformContainerView setDelegateForSliderView:self];

        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickDelayRecordView)];
        [_delayRecordView.clearView addGestureRecognizer:tapRecognizer];
    }
    return _delayRecordView;
}

- (UIViewController *)containerVC
{
    return self.controller.root;
}

- (ACCCountDownViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self.modelFactory createViewModel:ACCCountDownViewModel.class];
    }
    return _viewModel;
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [IESAutoInline(self.serviceProvider, ACCRecordTrackService) registRecordVideoHandler:self];
    [IESAutoInline(self.serviceProvider, ACCRecordConfigService) registDurationHandler:self];
    [self.flowService addSubscriber:self];
    [self.switchModeService addSubscriber:self];
    [self.cameraService addSubscriber:self];
    [self.propService addSubscriber:self];
    [self.karaokeService addSubscriber:self];
}

#pragma mark - ACCPanelViewDelegate

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController willShowPanelView:(id<ACCPanelViewProtocol>)panelView
{
    if (panelView.identifier == ACCRecordCountDownContext) {
        self.viewContainer.isShowingPanel = YES;
        [self.viewContainer showItems:NO animated:YES];
        @weakify(self);
        void (^updateMusicBlock)(void) = ^{
            @strongify(self);
            self.delayRecordView.audioWaveformContainerView.usingBarView = YES;
            [self.viewModel showVolumesWithShouldCount:[self.delayRecordView.audioWaveformContainerView waveBarCountForFullWidth] completion:^(NSArray<NSNumber *> * _Nonnull volumes) {
                @strongify(self);

                [self.delayRecordView.audioWaveformContainerView updateWaveBarWithVolumes:volumes];
                CGFloat hasRecordedLocation = 0.f;
                if (self.repository.repoContext.maxDuration > 0.f) {
                    hasRecordedLocation = [self flowService].currentDuration / self.repository.repoContext.maxDuration;
                }
                [self.delayRecordView.audioWaveformContainerView updateHasRecordedLocation:hasRecordedLocation];
                [self.delayRecordView.audioWaveformContainerView updateBottomRightLableWithMaxDuration:self.repository.repoContext.maxDuration];
                [self.delayRecordView.audioWaveformContainerView updateToBePlayedLocation:1.0];
            }];
        };
        if ([self.delayRecordView.audioWaveformContainerView waveBarCountForFullWidth] <= 0.f) {
            // 第一次倒计时页面出现的时候，frame可能没有set
            self.delayRecordView.audioWaveformContainerView.updateMusicBlock = updateMusicBlock;
        } else {
            updateMusicBlock();
        }
        [self setupPlayer];
    }
}

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController didShowPanelView:(id<ACCPanelViewProtocol>)panelView
{
    if (panelView.identifier == ACCRecordCountDownContext) {
        HTSAudioRange audioRange = self.repository.repoMusic.audioRange;
        [self.player seekToTime:CMTimeMakeWithSeconds([self flowService].currentDuration + audioRange.location, NSEC_PER_SEC)];
        [self.player play];
        [self audioWaveformAddTimerIfNeeded];
    }
}

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController didDismissPanelView:(id<ACCPanelViewProtocol>)panelView
{
    if (panelView.identifier == ACCRecordCountDownContext) {
        self.viewContainer.isShowingPanel = NO;
        [self audioWaveformRemoveTimer];
        [self destoryPlayer];
        if (self.dismissType == ACCCountDownDismissTypeOnlyDismiss) {
            [self.viewContainer showItems:YES animated:YES];
        } else {
            [self beginCountDownRecord];
        }
    }
}

#pragma mark - private

- (void)beginCountDownRecord
{
    [self.viewContainer showItems:NO animated:YES];
    self.viewContainer.shouldClearUI = YES;
    @weakify(self);
    AWERecordLoadingView *loadingView = [[AWERecordLoadingView alloc] initWithFrame:[UIScreen mainScreen].bounds delayRecordMode:self.viewModel.delayRecordMode animationCompletion:^{
        @strongify(self);
        self.viewContainer.shouldClearUI = NO;
        // 倒计时的 animation 可能是由于用户切后台强行中断的，此时不应该开始录制
        // applicationActive 为 NO 表明此时处于从 Active -> Inactive 的中间状态
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive && self.applicationActive) {
            if (ACCConfigBool(kConfigBool_tools_shoot_switch_camera_while_recording)) {
                [self.viewContainer.barItemContainer updateAllBarItems];
                [self.viewContainer showItems:YES animated:YES];
            }
            [self.flowService startRecordWithDelayRecord:YES];
        } else {
            [self.viewContainer showItems:YES animated:YES];
        }
    }];
    loadingView.center = CGPointMake(CGRectGetMidX(self.controller.root.view.bounds),
                                     CGRectGetMidY(self.controller.root.view.bounds));
    [self.viewContainer.interactionView addSubview:loadingView];
    self.loadingView = loadingView;
}

#pragma mark - ACCRecordPropServiceSubscriber

- (void)propServiceDidApplyProp:(IESEffectModel *)prop success:(BOOL)success
{
    self.forbidCountdown = prop.isMultiSegProp;
    ACCBarItem *countdownItem = [self.viewContainer.barItemContainer barItemWithItemId:ACCRecorderToolBarDelayRecordContext];
    if (countdownItem.needShowBlock()) {
        self.countdownButtonCustomView.alpha = (self.forbidCountdown ? 0.34f : 1.f);
    }
}

- (UIView *)countdownButtonCustomView
{
    return (UIView *)[self.viewContainer.barItemContainer viewWithBarItemID:ACCRecorderToolBarDelayRecordContext];
}

#pragma mark - ACCRecordFlowServiceSubscriber

- (void)flowServiceDidUpdateDuration:(CGFloat)duration {
    [self updateDelayRecordUIWithCurrentDuration:duration];
}

- (void)flowServiceDidAddFragment:(AWEVideoFragmentInfo *)fragment {
    if (self.flowService.isDelayRecord) {
        // 只有使用了倒计时拍摄才给 info.delayRecordModeType 赋值, 否则会导致该字段等于上次拍摄缓存的倒计时拍摄模式
        fragment.delayRecordModeType = [self viewModel].delayRecordMode;
    }
}

#pragma mark - ACCRecordConfigDurationHandler

- (void)didSetMaxDuration:(CGFloat)duration {
    [self updateDelayRecordUIWithCurrentDuration:self.flowService.currentDuration];
}

#pragma mark - ACCRecordVideoEventHandler

- (NSDictionary *)recordVideoEvent
{
    return @{};
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarDelayRecordContext];
}

#pragma mark - ACCKaraokeServiceSubscriber

- (void)karaokeService:(id<ACCKaraokeService>)service inKaraokeRecordPageDidChangeFrom:(BOOL)prevState to:(BOOL)state
{
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarDelayRecordContext];
}

@end
