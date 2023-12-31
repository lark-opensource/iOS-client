//
//  ACCMicrophoneComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/2/19.
//

#import "ACCMicrophoneComponent.h"
#import "AWEReactMicrophoneButton.h"
#import <CreationKitArch/ACCRecorderToolBarDefines.h>
#import <CreationKitArch/AWECameraContainerToolButtonWrapView.h>
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import <CreationKitInfra/UILabel+ACCAdditions.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import "ACCMicrophoneViewModel.h"

#import <CreationKitRTProtocol/ACCCameraService.h>
#import "ACCRecordConfigService.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import "ACCRecordFlowService.h"
#import "ACCRecordPropService.h"
#import "ACCPropViewModel.h"
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import "ACCRepoRecorderTrackerToolModel.h"
#import "AWERepoDuetModel.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import "ACCBarItem+Adapter.h"
#import "AWERepoContextModel.h"

static BOOL kHasShowMicrophoneTip = NO;

@interface ACCMicrophoneComponent () <ACCRecordConfigAudioHandler, ACCRecordConfigDurationHandler, ACCRecordSwitchModeServiceSubscriber, ACCRecordFlowServiceSubscriber, ACCRecordPropServiceSubscriber>

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCRecordPropService> propService;

@property (nonatomic, strong) AWEReactMicrophoneButton *reactMicButton;//麦克风按钮
@property (nonatomic, strong) UILabel *reactMicButtonLabel;//麦克风按钮文字
@property (nonatomic, strong) ACCMicrophoneViewModel *viewModel;

@property (nonatomic, assign) BOOL viewDidAppearOnce;
@property (nonatomic, assign) BOOL hasAppearMusicToast;
@property (nonatomic, copy) NSString *expectedDuetMicrophoneShowTip;

@end

@implementation ACCMicrophoneComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, propService, ACCRecordPropService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)

#pragma mark - ACCComponentProtocol

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [IESAutoInline(self.serviceProvider, ACCRecordConfigService) registAudioHandler:self];
    [IESAutoInline(self.serviceProvider, ACCRecordConfigService) registDurationHandler:self];
    [self.flowService addSubscriber:self];
    [self.switchModeService addSubscriber:self];
    [self.propService addSubscriber:self];
}

#pragma mark - ACCFeatureComponent

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCMicrophoneService), self.viewModel);
}

- (void)loadComponentView
{
    [self createMicrophoneBarItem];
}

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    [self.viewModel setUpSession];
    [self.viewModel updateAcousticAlgorithmConfig];
    [self updateMicroBarUIAlpha];
    [self p_setupDuetMicrophoneStatusTipIfNeed];
}

- (void)componentDidAppear
{
    if (!self.viewDidAppearOnce) {
        self.viewDidAppearOnce = YES;
        [self p_showDuetMicrophoneTipIfNeed];
        [self p_showMusicMicrophoneTipIfNeed];
    }
}

#pragma mark - set UI

- (void)createMicrophoneBarItem
{
    let config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCRecorderToolBarMicrophoneContext];
    if (config) {
        AWECameraContainerToolButtonWrapView *microphoneCustomView = [[AWECameraContainerToolButtonWrapView alloc] initWithButton:self.reactMicButton label:self.reactMicButtonLabel itemID:ACCRecorderToolBarMicrophoneContext];
        ACCBarItem *microphoneBarItem = [[ACCBarItem alloc] initWithCustomView:microphoneCustomView itemId:ACCRecorderToolBarMicrophoneContext];
        microphoneBarItem.type = ACCBarItemFunctionTypeDefault;
        @weakify(self);
        microphoneBarItem.needShowBlock = ^BOOL{
            @strongify(self);
            return [self.viewModel shouldShowMicroBar] && ![self.cameraService.recorder isRecording];
        };
        [self.viewContainer.barItemContainer addBarItem:microphoneBarItem];
    }
    [self.reactMicButton mutedMicrophone:self.repository.repoVideoInfo.videoMuted];//创建时候取videoMuted，存在草稿恢复/重拍等case

    self.reactMicButton.accessibilityLabel = [NSString stringWithFormat:@"%@%@", self.reactMicButtonLabel.text, self.reactMicButton.isMuted ? @"已关闭" : @"已打开"];

    if (self.repository.repoReshoot.isReshoot) {
        self.reactMicButton.enabled = NO;;
    }
}

#pragma mark - duet toast

- (void)p_setupDuetMicrophoneStatusTipIfNeed
{
    if (!self.repository.repoDuet.isDuet ||
        self.repository.repoDraft.isDraft ||
        self.repository.repoDraft.isBackUp ||
        !self.repository.repoRecorderTrackerTool.hasAuthority) {
        return;
    }
    
    if (self.repository.repoDuet.shouldEnableMicrophoneOnStart && !self.repository.repoVideoInfo.videoMuted) {
        self.expectedDuetMicrophoneShowTip = @"麦克风已开启，戴耳机的录音效果会更好";
        self.repository.repoDuet.showingDuetMicrophoneStateToast = YES;
        self.repository.repoDuet.shouldEnableMicrophoneOnStart = NO;
    } else if (self.repository.repoVideoInfo.videoMuted) {
        self.expectedDuetMicrophoneShowTip = @"麦克风已自动关闭，可手动开启";
        self.repository.repoDuet.showingDuetMicrophoneStateToast = YES;
    }
}

- (void)p_showDuetMicrophoneTipIfNeed
{
    if (ACC_isEmptyString(self.expectedDuetMicrophoneShowTip)) {
        return;
    }
    [ACCToast() show:self.expectedDuetMicrophoneShowTip];
    // toast显示的时间
    @weakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        self.repository.repoDuet.showingDuetMicrophoneStateToast = NO;
    });


}

#pragma mark - music micro toast

- (void)p_showMusicMicrophoneTipIfNeed
{
    if (kHasShowMicrophoneTip == YES ||
        self.viewModel.currentMicBarState == ACCMicrophoneBarStateHidden ||
        self.repository.repoDuet.isDuet ||
        self.repository.repoReshoot.isReshoot){
        return;
    }
    ACCRepoDraftModel *repoDraft = self.repository.repoDraft;
    BOOL isKaraokeBackupOrDraft = (repoDraft.isDraft || repoDraft.isBackUp) && self.repository.repoContext.videoType == AWEVideoTypeKaraoke;
    if (isKaraokeBackupOrDraft) {
        return; // recovered karaoke works
    }
    [ACCToast() show:@"麦克风已自动关闭，可手动开启"];
    kHasShowMicrophoneTip = YES;
    self.hasAppearMusicToast = YES;
}

#pragma mark - action

- (void)clickReactMicButton:(id)sender
{
    if (!self.isMounted) {
        return;
    }
    if (self.cameraService.recorder.isRecording) {
        return;
    }
    if (self.reactMicButton.isLockedDisable) {
        [ACCToast() show:@"该道具不支持录制原声"];
        return;
    }
    [self toggleMicButton];
    if (!self.reactMicButton.isMuted) {
        [ACCToast() show: ACCLocalizedString(@"reaction_earpiece_tip", @"戴耳机录制效果更好")];
    }
    [self.viewModel trackClickMicButton];//埋点上报
}

- (void)toggleMicButton
{
    BOOL expectToMute = !self.reactMicButton.isMuted;
    [self.reactMicButton mutedMicrophone:expectToMute];//点击切换开关状态
	self.reactMicButton.isAccessibilityElement  = YES;
    self.reactMicButton.accessibilityTraits = UIAccessibilityTraitButton;
    self.reactMicButton.accessibilityLabel = [NSString stringWithFormat:@"%@%@", self.reactMicButtonLabel.text, self.reactMicButton.isMuted ? @"已关闭" : @"已打开"];
    self.repository.repoVideoInfo.videoMuted = expectToMute;//同步值
    [self.viewModel updateAcousticAlgorithmConfig];
    if (expectToMute) {
        [self.cameraService.cameraControl stopAudioCapture];
    }
}
    
- (void)updateMicroItemWithDuration:(CGFloat)currentDuration
{
    if (self.repository.repoReshoot.isReshoot) {
        return;
    }
    if (currentDuration > 0) {
        self.reactMicButton.enabled = NO;
    } else {
        self.reactMicButton.enabled = YES;
    }
}

- (void)updateMicroBarUIAlpha
{
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarMicrophoneContext];
    if (self.reactMicButton.isLockedDisable) {
        [self.reactMicButton lockButtonDisable:YES shouldShow:self.viewModel.shouldShowMicroBar];
    }
}

#pragma mark - ACCRecordConfigDurationHandler

- (void)didSetMaxDuration:(CGFloat)duration
{
    [self updateMicroItemWithDuration:self.flowService.currentDuration];
}

#pragma mark - ACCRecordFlowServiceSubscriber

- (void)flowServiceDidUpdateDuration:(CGFloat)duration
{
    [self updateMicroItemWithDuration:duration];
}
    
#pragma mark - ACCRecordConfigAudioHandler

- (void)didFinishConfigAudioWithSetMusicCompletion:(void (^)(void))setMusicCompletion
{
    [self.reactMicButton mutedMicrophone:self.repository.repoVideoInfo.videoMuted];
    [self.viewModel updateAcousticAlgorithmConfig];
    [self updateMicroBarUIAlpha];
    if ([self.propService.prop isTypeVoiceRecognization] && self.repository.repoVideoInfo.videoMuted) {
        [self.cameraService.cameraControl stopAudioCapture];
        //正在应用音量道具，使用了音乐使得闭麦 给予提示
        [ACCToast() show:@"当前道具需要打开麦克风生效"];
    } else {
        [self p_showMusicMicrophoneTipIfNeed];
    }
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    if (oldMode.isVideo == mode.isVideo) {
        return;
    }
    [self.viewModel setSupportedMode:mode.isVideo];
    [self updateMicroBarUIAlpha];
}

#pragma mark - ACCRecordPropServiceSubscriber

- (void)propServiceWillApplyProp:(IESEffectModel *)prop propSource:(ACCPropSource)propSource
{
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarMicrophoneContext];
    if (prop && [prop isTypeAudioGraph] && ![prop audioGraphMicSource]) {
        if (!self.reactMicButton.isMuted) {
            [self toggleMicButton];
        }
        [ACCToast() show:@"当前道具不支持录音功能"];
    }
}

#pragma mark - lazy loads

- (ACCMicrophoneViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self getViewModel:ACCMicrophoneViewModel.class];
    }
    return _viewModel;
}

- (UILabel *)reactMicButtonLabel
{
    if (!_reactMicButtonLabel) {
        _reactMicButtonLabel = [[UILabel alloc] acc_initWithFont:[ACCFont() acc_boldSystemFontOfSize:10]
                                                 textColor:ACCResourceColor(ACCUIColorConstTextInverse)
                                                      text:ACCLocalizedCurrentString(@"microphone")];
        _reactMicButtonLabel.textAlignment = NSTextAlignmentCenter;
        _reactMicButtonLabel.numberOfLines = 2;
        [_reactMicButtonLabel acc_addShadowWithShadowColor:ACCResourceColor(ACCUIColorConstLinePrimary) shadowOffset:CGSizeMake(0, 1) shadowRadius:2];
        _reactMicButtonLabel.isAccessibilityElement = NO;
    }
    return _reactMicButtonLabel;
}

- (AWEReactMicrophoneButton *)reactMicButton
{
    if (!_reactMicButton) {
        _reactMicButton = [AWEReactMicrophoneButton new];
        [_reactMicButton mutedMicrophone:self.repository.repoVideoInfo.videoMuted];
        [_reactMicButton addTarget:self action:@selector(clickReactMicButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _reactMicButton;
}

@end
