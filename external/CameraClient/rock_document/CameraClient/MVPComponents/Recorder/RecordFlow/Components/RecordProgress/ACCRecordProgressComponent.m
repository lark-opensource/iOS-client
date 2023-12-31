//
//  ACCRecordProgressComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/11/6.
//

#import "ACCRecordProgressComponent.h"
#import "AWEReshootVideoProgressView.h"
#import <CreativeKit/ACCRecorderViewContainer.h>
#import "ACCRecordFlowService.h"
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import "ACCRecordConfigService.h"
#import "ACCRecordPropService.h"
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCComponentManager.h>
#import <CreationKitArch/ACCRepoGameModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/ACCDeviceAuth.h>
#import "ACCRecordFlowConfigProtocol.h"
#import <CreationKitArch/ACCRepoVideoInfoModel.h>
#import <CameraClient/ACCRecordMode+LiteTheme.h>

@interface ACCRecordProgressComponent () <
ACCRecordFlowServiceSubscriber,
ACCRecordConfigDurationHandler,
ACCCameraLifeCircleEvent,
ACCRecordSwitchModeServiceSubscriber,
ACCRecorderViewContainerItemsHideShowObserver>

@property (nonatomic, strong) UIView<AWEVideoProgressViewProtocol> *studioProgressView;
@property (nonatomic, assign) CGRect studioProgressViewFrame;

@property (nonatomic, weak) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordPropService> propService;
@property (nonatomic, strong) id<ACCVideoConfigProtocol> videoConfig;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCRecordFlowConfigProtocol> flowConfig;

@property (nonatomic, strong) UILabel *timeLabel; // 已录制的时间

@end

@implementation ACCRecordProgressComponent

IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, propService, ACCRecordPropService)
IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(ACCBaseServiceProvider() , videoConfig, ACCVideoConfigProtocol)
IESAutoInject(self.serviceProvider, flowConfig, ACCRecordFlowConfigProtocol)


- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)loadComponentView
{
    if (![self.flowConfig enableLightningStyleRecordButton]) {
        [self.viewContainer.interactionView addSubview:self.studioProgressView];
    }
}

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    [self.viewContainer addObserver:self];
    
    @weakify(self);
    [self.controller.componentManager registerMountCompletion:^{
        @strongify(self);
        if (self.repository.repoGame.gameType != ACCGameTypeNone) {
            [self hideProgressBar:YES];
        } else {
            [self hideProgressBar:AWEVideoTypePhotoToVideo == self.repository.repoContext.videoType];
        }
        [self updateStandardDurationIndicatorDisplay];
    }];
}

- (void)componentDidAppear
{
    if (self.repository.repoReshoot.isReshoot) {
        [self updateBlinkingMark];
    }
}

- (CGRect)studioProgressViewFrame {
    CGFloat top = 6;
    if (@available(iOS 11.0, *)) {
         if ([UIDevice acc_isIPhoneX]) {
             top = ACC_STATUS_BAR_NORMAL_HEIGHT + 6;
         }
    }
    return CGRectMake(0, top, ACC_SCREEN_WIDTH, 6);
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.cameraService addSubscriber:self];
    [self.flowService addSubscriber:self];
    [self.switchModeService addSubscriber:self];
    [IESAutoInline(self.serviceProvider, ACCRecordConfigService) registDurationHandler:self];
}

#pragma mark - ACCRecorderViewContainerItemsHideShowObserver

- (void)shouldItemsShow:(BOOL)show animated:(BOOL)animated
{
    [self hideTimeLabelIfNeed];
}

#pragma mark - ACCCameraLifeCircleEvent

- (void)cameraService:(id<ACCCameraService>)cameraService pauseRecordWithError:(NSError *)error
{
    if (error) {
        AWELogToolError(AWELogToolTagRecord, @"pause record failed. %@", error);
    }
    if (self.repository.repoReshoot.isReshoot) {
        [self updateBlinkingMark];
        [self blinkBarIfCompleted];
    }
    [self hideTimeLabelIfNeed];
}

- (void)cameraService:(id<ACCCameraService>)cameraService startRecordWithError:(NSError *)error
{
    if (error) {
        AWELogToolError(AWELogToolTagRecord, @"start record failed. %@", error);
    }
    if (self.repository.repoReshoot.isReshoot) {
        [self updateBlinkingMark];
    }
}

#pragma mark - ACCRecordConfigDurationHandler

- (void)didSetMaxDuration:(CGFloat)duration
{
    [self updateStandardDurationIndicatorDisplay];
    [self updateProgressAndMarksDisplay];
}

#pragma mark - ACCRecordFlowServiceSubscriber

- (void)flowServiceDidUpdateDuration:(CGFloat)duration
{
    [self updateProgressAndMarksDisplay];
    [self updateDurationDisplay];
}

- (void)flowServiceStateDidChanged:(ACCRecordFlowState)state preState:(ACCRecordFlowState)preState
{
    [self hideTimeLabelIfNeed];
}

- (void)flowServiceDurationHasRestored
{
    if (self.repository.repoReshoot.isReshoot) {
        NSTimeInterval from = self.repository.repoReshoot.durationBeforeReshoot;
        NSTimeInterval to = from + self.repository.repoContext.maxDuration;
        NSTimeInterval total = to + self.repository.repoReshoot.durationAfterReshoot;
        if ([self.studioProgressView isKindOfClass:[AWEReshootVideoProgressView class]]) {
            [(AWEReshootVideoProgressView *)self.studioProgressView setReshootTimeFrom:from to:to totalDuration:total];
        }
        return;
    }
    if (self.repository.repoDraft.isDraft && ![self.flowConfig enableLightningStyleRecordButton]) {
        // 还原长视频模式下的15s提示的显示
        ACCRecordLengthMode mode = self.repository.repoContext.videoLenthMode;
        if (mode == ACCRecordLengthModeLong ||
            mode == ACCRecordLengthMode60Seconds) {
            BOOL showStandardDurationIndicator = YES;
            if (self.repository.repoDuet.isDuet) {
                showStandardDurationIndicator = NO;
            }
            [self.studioProgressView updateStandardDurationIndicatorWithLongVideoEnabled:showStandardDurationIndicator standardDuration:[self.videoConfig standardVideoMaxSeconds] maxDuration:self.repository.repoContext.maxDuration];
        }
    }
}

- (void)flowServiceDidMarkDuration:(CGFloat)duration
{
    if (self.repository.repoGame.gameType == ACCGameTypeNone) {
        [self updateProgressBar];
    }
    
    [self hideTimeLabelIfNeed];
}

- (void)flowServiceDidRemoveLastSegment:(BOOL)isReactHasMerge
{
    [self updateProgressBar];
    if (self.repository.repoReshoot.isReshoot) {
        [self updateBlinkingMark];
    }
}

- (void)flowServiceDidRemoveAllSegment
{
    [self updateProgressBar];
    if (self.repository.repoReshoot.isReshoot) {
        self.flowService.currentDuration = 0.0f;
        [self updateBlinkingMark];
    }
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    if (mode.lengthMode != ACCRecordLengthModeUnknown) {
        [self updateStandardDurationIndicatorDisplay];
    }
    [self hideProgressBar:!mode.isVideo];
}

#pragma mark - progress

- (void)updateStandardDurationIndicatorDisplay
{
    if ([self.flowConfig enableLightningStyleRecordButton]) {
        return;
    }
    ACCRecordLengthMode lengthMode = [self.videoConfig currentVideoLenthMode];
    BOOL showStandardDurationIndicator = lengthMode == ACCRecordLengthModeLong || lengthMode == ACCRecordLengthMode60Seconds;
    if (self.repository.repoDuet.isDuet) {
        showStandardDurationIndicator = NO;
    }
    [self.studioProgressView updateStandardDurationIndicatorWithLongVideoEnabled:showStandardDurationIndicator
                                                                standardDuration:[self.videoConfig standardVideoMaxSeconds]
                                                                     maxDuration:self.repository.repoContext.maxDuration];
}

- (void)updateProgressBar
{
    if ([self.flowConfig enableLightningStyleRecordButton]) {
        return;
    }
    [self.studioProgressView updateViewWithTimeSegments:self.flowService.markedTimes totalTime:self.repository.repoContext.maxDuration];
}

- (void)hideProgressBar:(BOOL)hidden
{
    if (![self.flowConfig enableLightningStyleRecordButton]) {
        self.studioProgressView.hidden = hidden;
    }
}

- (void)updateProgressAndMarksDisplay
{
    self.timeLabel.text = [self currentDurationText];
    [self hideTimeLabelIfNeed];
    
    if ([self.flowConfig enableLightningStyleRecordButton]) {
        return;
    }
    double progress = ((NSTimeInterval)self.flowService.currentDuration) / self.repository.repoContext.maxDuration;
    if (progress >= 1) {
        [self.studioProgressView setProgress:1 duration:self.flowService.currentDuration animated:NO];
    } else {
        BOOL animation = progress < self.studioProgressView.progress;
        if ([self.studioProgressView respondsToSelector:@selector(updateViewWithProgress:marks:duration:totalTime:animated:)]) {
            [self.studioProgressView updateViewWithProgress:progress
                                                      marks:self.flowService.markedTimes
                                                   duration:self.flowService.currentDuration
                                                  totalTime:self.repository.repoContext.maxDuration
                                                   animated:animation];
        } else {
            [self.studioProgressView setProgress:progress duration:self.flowService.currentDuration animated:animation];
        }
    }
}

- (NSString *)currentDurationText
{
    CGFloat duration = (NSInteger)(self.flowService.currentDuration * 10) / 10.f;
    // 暂时对齐Android不要分段时长，之后可能会加回来
//    if (self.propService.prop.isMultiSegProp) {
//        CGFloat currentSegDuration = duration - [self.propService.prop.clipsArray acc_objectAtIndex:MAX((self.flowService.videoSegmentsCount - 1), 0)].start;
//        duration = currentSegDuration;
//    }
    if (ACCConfigBool(kConfigBool_enable_record_3min_optimize) && !self.propService.prop.isMultiSegProp) {
        return [NSString stringWithFormat:@"%02ld:%02ld", (long)duration / 60, (long)duration % 60];
    }
    return [NSString stringWithFormat:ACCLocalizedString(@"creation_mv_footage_duration", @"%.1fs"), duration];
}

- (void)hideTimeLabelIfNeed
{
    BOOL hidden = NO;
    if (![self.flowConfig enableLightningStyleRecordButton] &&
        ACCConfigBool(kConfigBool_enable_record_3min_optimize) &&
        self.repository.repoVideoInfo.fragmentInfo.count > 0) {
        //1~3min拍摄优化需求要求暂停的时候展示置灰的选择音乐按钮，不展示timeLabel
        //1 ~ 3min Shooting Optimization Requirement Display Grey Selection Music Button
        //when Pause, Do Not Display Time Label
        hidden = YES;
    } else if ([self.propService.prop isMultiSegProp] && self.cameraService.recorder.recorderState != ACCCameraRecorderStateRecording) {
        // 多段拍道具，非录制状态，不展示
        hidden = YES;
    } else if (self.viewContainer.itemsShouldHide) {
        // 指定了小组件需要隐藏
        hidden = YES;
    } else if (self.flowService.currentDuration <= 0.0) {
        // duration <= 0
        hidden = YES;
    } else if (self.switchModeService.currentRecordMode.modeId == ACCRecordModeLivePhoto) {
        // 动图模式
        hidden = YES;
    } else if (![ACCDeviceAuth hasCameraAndMicroPhoneAuth]) {
        hidden = YES;
    } else if (self.switchModeService.currentRecordMode.isStoryStyleMode && (self.flowService.flowState == ACCRecordFlowStateStop || self.flowService.flowState == ACCRecordFlowStateFinishExport)) {
        // 快拍模式，因为录制一段后自动进编辑页了，而且返回时所录片段已经清除，所以只要 stop / finishExport，就可以隐藏 timeLabel，不然有 timeLabel 隐藏有延迟
        hidden = YES;
    }
    self.timeLabel.hidden = hidden;
}

- (void)updateDurationDisplay
{
    CGFloat duration = self.flowService.currentDuration;
    if (duration < 0) {
        [self hideProgressBar:YES];
    } else {
        if (self.repository.repoGame.gameType != ACCGameTypeNone) {
            [self hideProgressBar:YES];
        } else {
            [self hideProgressBar:NO];
        }
    }
}

#pragma mark - reshoot

- (void)updateBlinkingMark
{
    BOOL shouldBlink = self.cameraService.recorder.isRecording && self.flowService.currentDuration < self.repository.repoContext.maxDuration;
    if ([self.studioProgressView isKindOfClass:[AWEReshootVideoProgressView class]]) {
        [(AWEReshootVideoProgressView *)self.studioProgressView blinkMarkAtCurrentProgress:shouldBlink];
    }
}

- (void)blinkBarIfCompleted
{
    BOOL shouldBlink = self.flowService.currentDuration >= self.repository.repoContext.maxDuration;
    if (shouldBlink) {
        if ([self.studioProgressView isKindOfClass:[AWEReshootVideoProgressView class]]) {
            [(AWEReshootVideoProgressView *)self.studioProgressView blinkReshootProgressBarOnce];
        }
    }
}

#pragma mark - getter

- (UIView<AWEVideoProgressViewProtocol> *)studioProgressView
{
    if (!_studioProgressView) {
        CGRect frame = self.studioProgressViewFrame;
        if (self.repository.repoReshoot.isReshoot) {
            _studioProgressView = [[AWEReshootVideoProgressView alloc] initWithFrame:frame];
        } else {
            _studioProgressView = [[AWEStudioVideoProgressView alloc] initWithFrame:frame];
        }
        [self.viewContainer.layoutManager addSubview:_studioProgressView viewType:ACCViewTypeProgress];
    }
    return _studioProgressView;
}

- (UILabel *)timeLabel
{
    if (![self.flowConfig enableLightningStyleRecordButton] || (self.switchModeService.currentRecordMode.isStoryStyleMode && ACCConfigBool(kConfigBool_recorder_remove_time_label))) {
        return nil;
    }
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 21)];
        _timeLabel.font = [UIFont monospacedDigitSystemFontOfSize:15 weight:UIFontWeightBold];
        _timeLabel.textColor = [UIColor whiteColor];
        _timeLabel.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
        _timeLabel.layer.shadowOpacity = 1;
        _timeLabel.layer.shadowRadius = 8;
        _timeLabel.layer.shadowOffset = CGSizeMake(0, 1);
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        [self.viewContainer.layoutManager addSubview:_timeLabel viewType:ACCViewTypeTimeLabel];
    }
    return _timeLabel;
}

@end
