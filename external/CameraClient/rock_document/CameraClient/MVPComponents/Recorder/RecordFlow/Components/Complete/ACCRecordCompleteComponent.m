//
//  ACCRecordCompleteComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by guochenxiang on 2020/11/24.
//

#import "AWERepoPropModel.h"
#import "ACCRecordCompleteComponent.h"
#import <CreativeKit/ACCRecorderViewContainer.h>
#import "ACCButton.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "ACCRecordFlowService.h"
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import "ACCRecordPropService.h"
#import <CreationKitArch/ACCRecordTrackService.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import "ACCRecordConfigService.h"
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>

// repo model
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CreationKitArch/ACCRepoGameModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/ACCRACWrapper.h>

#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoVideoInfoModel.h>
#import "ACCRepoKaraokeModelProtocol.h"
#import <CameraClient/ACCRecordMode+LiteTheme.h>
#import <CameraClientModel/AWEVideoRecordButtonType.h>
#import "ACCUIReactTrackProtocol.h"
#import "ACCRecordCompleteTrackSender.h"

@interface ACCRecordCompleteComponent () <
ACCRecordFlowServiceSubscriber,
ACCRecordConfigDurationHandler,
ACCCameraLifeCircleEvent,
ACCRecorderViewContainerItemsHideShowObserver>

@property (nonatomic, strong) ACCButton *completeButton; // 右下角完成按钮

@property (nonatomic, weak) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCRecordPropService> propService;
@property (nonatomic, strong, readwrite) ACCGroupedPredicate<id, id> *shouldShow;
@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, strong) ACCRecordCompleteTrackSender *trackSender;

@end

@implementation ACCRecordCompleteComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, propService, ACCRecordPropService)


- (void)loadComponentView
{
    [self.viewContainer.layoutManager addSubview:self.completeButton viewType:ACCViewTypeCompleteButton];
    [self.completeButton acc_addSingleTapRecognizerWithTarget:self action:@selector(clickCompleteBtn:)];
}

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    [self bindViewModel];
}

- (void)componentWillAppear
{
    self.isFirstAppear = YES;
    [self.completeButton acc_enableUserInteraction];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)bindViewModel
{
    @weakify(self);
    [self.viewContainer addObserver:self];

    [RACObserve(self.cameraService.recorder, recorderState).deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        ACCCameraRecorderState state = x.integerValue;
        switch (state) {
            case ACCCameraRecorderStateNormal:
                if (self.viewContainer.isShowingPanel) {
                    [self updateCompleteButtonHidden:YES];
                }
                break;
            case ACCCameraRecorderStatePausing: {
                if (self.repository.repoGame.gameType == ACCGameTypeNone) {
                    [self updateCompleteButtonHidden:NO];
                }
                break;
            }
            case ACCCameraRecorderStateRecording:
                [self updateCompleteButtonHidden:NO];
                break;
        }
    }];
}

- (NSArray<ACCServiceBinding *> *)serviceBindingArray {
    return @[
        ACCCreateServiceBinding(@protocol(ACCRecordCompleteTrackSenderProtocol), self.trackSender),
    ];
}

- (void)updateCompleteButtonHidden:(BOOL)hidden
{
    if (self.switchModeService.currentRecordMode.autoComplete) {
        self.completeButton.hidden = YES;
        return;
    }
    BOOL enabled = [self.flowService allowComplete];
    BOOL isRecording = self.cameraService.recorder.isRecording;
    BOOL shouldShow = (!isRecording && self.repository.repoVideoInfo.fragmentInfo.count > 0) || (isRecording && enabled);
    if (AWEVideoTypePhotoToVideo == self.repository.repoContext.videoType) {
        shouldShow = NO;
    }
    // seg prop only can be completed when the last seg finished
    if ([self.repository.repoProp isMultiSegPropApplied]) {
        // if is multi prop when open the record page, it should be draft, so it will clear the segments in close component.
        if (!self.isFirstAppear) {
            shouldShow = NO;
        } else if ([self.cameraService.cameraControl status] == IESMMCameraStatusRecording || self.flowService.videoSegmentsCount < self.propService.prop.clipsArray.count) {
            enabled = NO;
            if (isRecording) {
                hidden = YES;
            }
        }
    }
    self.completeButton.selected = enabled;
    self.completeButton.backgroundColor = enabled ? ACCResourceColor(ACCUIColorConstPrimary) : [ACCResourceColor(ACCUIColorConstPrimary) colorWithAlphaComponent:0.5];
    shouldShow = shouldShow && !self.viewContainer.isShowingPanel && !hidden && [self.shouldShow evaluate];
    if (shouldShow) {
        [self.completeButton acc_fadeShow];
    } else {
        [self.completeButton acc_fadeHidden];
    }
}

#pragma mark - action

- (void)clickCompleteBtn:(UITapGestureRecognizer *)sender
{
    if (sender) {
        [self.trackSender sendCompleteButtonClickedSignal];
    }
    if (self.propService.prop.isMultiSegProp && ([self.cameraService.cameraControl status] == IESMMCameraStatusRecording || self.flowService.videoSegmentsCount < self.propService.prop.clipsArray.count))
    {
        [ACCToast() show:@"需要拍完要求的段数才可以下一步哦"];
        return;
    }
    
    if (!self.isMounted) {
        return;
    }
    
    [self addPlayerFirstRenderDuration];
    [self.completeButton acc_disableUserInteractionWithTimeInterval:2];
    BOOL canComplete = [self.flowService complete];
    if (!canComplete) {
        if ([self.repository.repoFlowControl isFixedDuration]) {
            [ACCToast() show: ACCLocalizedString(@"edit_page_adjust_clips_reshoot_toast",@"拍摄长度需要与原片段时长一致")];
        } else {
            [ACCToast() show: ACCLocalizedString(@"video_too_short", @"时间太短啦，再拍一段儿吧")];
        }
        return;
    } else {
        if (![[ACCToolUIReactTrackService() latestEventName] isEqualToString:kAWEUIEventFinishFastRecord]) {
            [ACCToolUIReactTrackService() eventBegin:kAWEUIEventClickRecordNext];
        }
    }
    
    [ACCTracker() trackEvent:@"finish"
                                      label:@"shoot_page"
                                      value:nil
                                      extra:nil
                                 attributes:self.repository.repoTrack.referExtra];
}

- (void)addPlayerFirstRenderDuration
{
    NSTimeInterval duraion = [ACCMonitor() timeIntervalForKey:@"player_first_render_duration"];
    if (duraion > 1000 || duraion < 1) {
        [ACCMonitor() startTimingForKey:@"player_first_render_duration"];
    }
}

#pragma mark - ACCRecorderViewContainerItemsHideShowObserver

- (void)shouldItemsShow:(BOOL)show animated:(BOOL)animated
{
    [self updateCompleteButtonHidden:!show];
}

#pragma mark - ACCRecordFlowServiceSubscriber

- (void)flowServiceDidUpdateDuration:(CGFloat)duration
{
    [self updateCompleteButtonHidden:NO];
}

- (void)flowServiceStateDidChanged:(ACCRecordFlowState)state preState:(ACCRecordFlowState)preState
{
    if (state == ACCRecordFlowStatePause) {
        id<ACCRepoKaraokeModelProtocol> repoKaraoke = [self.repository extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
        BOOL completeAfterStop = [self.flowService allowComplete];
        
        if (completeAfterStop) {
            completeAfterStop = self.switchModeService.currentRecordMode.isStoryStyleMode || repoKaraoke.lightningStyleKaraoke || self.switchModeService.currentRecordMode.modeId == ACCRecordModeAudio;
        }
        if (completeAfterStop && self.liteLowQualityHandler) {
            completeAfterStop = [self.liteLowQualityHandler shouldCompleteWhenPause];
        }
        
        if (completeAfterStop)  {
            [self clickCompleteBtn:nil];
        }
    }
}

#pragma mark - ACCRecordConfigDurationHandler

- (void)didSetMaxDuration:(CGFloat)duration
{
    [self updateCompleteButtonHidden:NO];
}

#pragma mark - ACCCameraLifeCircleEvent

- (void)cameraService:(id<ACCCameraService>)cameraService pauseRecordWithError:(NSError *)error
{
    /// @xiafeiyu 快拍tab，拍摄过程中退后台，会 push 两个编辑页。一个在 - (void)flowServiceStateDidChanged:(ACCRecordFlowState)state preState:(ACCRecordFlowState)preState，一个是此处。https://bits.bytedance.net/meego/aweme/issue/detail/2337330#detail
    /// 感觉这里是没必要的，先注释掉，加AB，经过集成和回归看看有无问题。
    if (ACCConfigBool(kConfigBool_acc_complete_only_once)) {
        return;
    }
    UIApplicationState currentState = [UIApplication sharedApplication].applicationState;
    BOOL isAppNotActiveAndInStory = currentState != UIApplicationStateActive && self.repository.repoFlowControl.videoRecordButtonType == AWEVideoRecordButtonTypeStory;
    if (isAppNotActiveAndInStory && [self.flowService allowComplete]) {
        [self clickCompleteBtn:nil];
    }
    if (error) {
        AWELogToolError(AWELogToolTagRecord, @"Pause record failed. %@", error);
    }
}

#pragma mark - getter setter

- (ACCButton *)completeButton
{
    if (!_completeButton) {
        _completeButton = [ACCButton buttonWithSelectedAlpha:1.0];
        _completeButton.backgroundColor = ACCResourceColor(ACCUIColorConstPrimary);
        _completeButton.adjustsImageWhenHighlighted = NO;
        _completeButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_completeButton setImage:ACCResourceImage(@"iconUnchecked") forState:UIControlStateNormal];
        [_completeButton setImage:ACCResourceImage(@"iconCheck") forState:UIControlStateSelected];
        _completeButton.layer.masksToBounds = YES;
        _completeButton.accessibilityLabel = ACCLocalizedString(@"common_next", @"next");
        _completeButton.hidden = YES;
    }
    return _completeButton;
}

- (ACCRecordCompleteTrackSender *)trackSender
{
    if (!_trackSender) {
        _trackSender = [[ACCRecordCompleteTrackSender alloc] init];
    }
    return _trackSender;
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.flowService addSubscriber:self];
    [self.cameraService addSubscriber:self];
    [IESAutoInline(self.serviceProvider, ACCRecordConfigService) registDurationHandler:self];
}

- (ACCGroupedPredicate *)shouldShow
{
    if (!_shouldShow) {
        _shouldShow = [[ACCGroupedPredicate alloc] init];
    }
    return _shouldShow;
}

@end
