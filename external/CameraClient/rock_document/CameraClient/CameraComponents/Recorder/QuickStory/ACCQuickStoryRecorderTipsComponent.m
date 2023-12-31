//
//  ACCQuickStoryRecorderTipsComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2020/11/19.
//

#import "ACCQuickStoryRecorderTipsComponent.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import "ACCQuickStoryRecorderTipsViewModel.h"
#import <CreationKitRTProtocol/ACCCameraService.h>
#import "ACCRecordFlowService.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import "ACCConfigKeyDefines.h"
#import "ACCRecordFlowConfigProtocol.h"
#import "ACCIMServiceProtocol.h"
#import <CameraClient/AWERepoContextModel.h>
#import "ACCSpeedControlViewModel.h"
//#import "ACCQuickAlbumViewModel.h"
#import <CreationKitArch/ACCRepoDraftModel.h>
#import "AWEXScreenAdaptManager.h"
#import "ACCRecordLayoutGuide.h"
#import <CameraClient/ACCRecordMode+LiteTheme.h>

@interface ACCQuickStoryRecorderTipsComponent ()<
ACCRecordFlowServiceSubscriber,
ACCRecorderViewContainerItemsHideShowObserver>

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) UILabel *recordHintLabel; // 点击拍照，按住录制
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCRecordFlowConfigProtocol> flowConfig;

@end

@implementation ACCQuickStoryRecorderTipsComponent


IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, flowConfig, ACCRecordFlowConfigProtocol)

- (void)componentDidMount
{
    [self.viewContainer.interactionView addSubview:self.recordHintLabel];
    [self bindViewModel];
    [self.viewContainer addObserver:self];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.flowService addSubscriber:self];
}

- (ACCQuickStoryRecorderTipsViewModel *)viewModel
{
    ACCQuickStoryRecorderTipsViewModel *viewModel = [self getViewModel:[ACCQuickStoryRecorderTipsViewModel class]];
    NSAssert(viewModel, @"should not be nil");
    return viewModel;
}

- (void)bindViewModel
{
    @weakify(self);
    [[RACObserve([self viewModel], showingTips) deliverOnMainThread] subscribeNext:^(NSString * _Nullable x) {
        @strongify(self);
        if (x != nil) {
            [self updateWithText:x];
            [self showRecordHintLabel:YES];
        } else {
            [self showRecordHintLabel:NO];
        }
    }];
    [[RACObserve(self.cameraService.recorder, recorderState) deliverOnMainThread] subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        ACCCameraRecorderState state = x.integerValue;
        switch (state) {
            case ACCCameraRecorderStateRecording:
                [[self viewModel] hideRecordHintLabel];
                break;
            default:
                break;
        }
    }];
    if (ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab) && !self.repository.repoContext.isIMRecord && ![IESAutoInline(ACCBaseServiceProvider(), ACCIMServiceProtocol) isEnterFromFlyBird:self.repository] && !self.repository.repoDraft.isDraft) {
        [[RACObserve(self.speedControlViewModel, speedControlButtonSelected) deliverOnMainThread] subscribeNext:^(NSNumber *  _Nullable x) {
            @strongify(self)
            BOOL show = x.boolValue;
            self.recordHintLabel.alpha = show ? 0 : 1;
        }];
    }
//    [self.quickAlbumViewModel.quickAlbumShowStateSignal subscribeNext:^(NSNumber *  _Nullable x) {
//        @strongify(self)
//        BOOL show = x.boolValue;
//        self.recordHintLabel.alpha = show ? 0 : 1;
//    }];
}

- (UILabel *)recordHintLabel
{
    if (!_recordHintLabel) {
        _recordHintLabel = [[UILabel alloc] init];
        _recordHintLabel.font = [ACCFont() acc_boldSystemFontOfSize:15];
        _recordHintLabel.textColor = [UIColor whiteColor];
        _recordHintLabel.textAlignment = NSTextAlignmentCenter;
        _recordHintLabel.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
        _recordHintLabel.layer.shadowOpacity = 1;
        _recordHintLabel.layer.shadowRadius = 8;
        _recordHintLabel.layer.shadowOffset = CGSizeMake(0, 1);
        _recordHintLabel.hidden = YES;
    }
    return _recordHintLabel;
}

- (void)updateWithText:(NSString *)text
{
    _recordHintLabel.text = text;
    [_recordHintLabel sizeToFit];
    const CGFloat kRecordButtonWidth = 80.0f;
    const CGFloat kRecordButtonHeight = 80.0f;
    CGFloat shiftToTop = 14;
    if ([AWEXScreenAdaptManager needAdaptScreen] && !(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize) & ACCViewFrameOptimizeFullDisplay)) {
        shiftToTop = -12;
    }
    const CGRect recordButtonFrame = CGRectMake((ACC_SCREEN_WIDTH - kRecordButtonWidth)/2, ACC_SCREEN_HEIGHT + [self.viewContainer.layoutManager.guide recordButtonBottomOffset] - kRecordButtonHeight + ([UIDevice acc_isIPhoneX] ? shiftToTop : 0), kRecordButtonWidth, kRecordButtonHeight);
    _recordHintLabel.acc_centerX = CGRectGetMidX(recordButtonFrame);
    const CGFloat kSwitchLengthViewHeight = 44;
    const CGFloat kSwitchLengthViewOffset = 8;
    if (ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab) && !self.repository.repoContext.isIMRecord && ![IESAutoInline(ACCBaseServiceProvider(), ACCIMServiceProtocol) isEnterFromFlyBird:self.repository] && !self.repository.repoDraft.isDraft) {
        // 如果有子模式则在子模式上方
        _recordHintLabel.acc_bottom = recordButtonFrame.origin.y - kSwitchLengthViewOffset * 2 - kSwitchLengthViewHeight;
    } else {
        _recordHintLabel.acc_bottom = recordButtonFrame.origin.y - kSwitchLengthViewOffset - (kSwitchLengthViewHeight - _recordHintLabel.acc_height) / 2; // 对齐 ACCSwitchLengthView
    }
}

- (void)showRecordHintLabel:(BOOL)show
{
    if (show) {
        if (self.speedControlViewModel.speedControlButtonSelected) {
            self.recordHintLabel.hidden = NO;
            self.recordHintLabel.alpha = 0;
        } else {
            [self.recordHintLabel acc_fadeShow];
        }
        [NSObject cancelPreviousPerformRequestsWithTarget:self.recordHintLabel];
        [self.recordHintLabel performSelector:@selector(acc_fadeHidden) withObject:nil afterDelay:5];
    } else {
        [self.recordHintLabel acc_fadeHidden];
    }
}

#pragma mark - ACCRecordFlowServiceSubscriber

- (void)flowServiceStateDidChanged:(ACCRecordFlowState)state preState:(ACCRecordFlowState)preState
{
    if (state == ACCRecordFlowStatePause && self.switchModeService.currentRecordMode.isStoryStyleMode && ![self.flowService allowComplete]) {
        if (![self.flowConfig enableTapToTakePictureRecordMode:self.switchModeService.currentRecordMode.isStoryStyleMode] &&
            !ACCConfigBool(kConfigBool_enable_lightning_pic_to_video_optimize)) {
                [self showRecordHintLabel:YES];
        }
    }
}

#pragma mark - ACCRecorderViewContainerItemsHideShowObserver

- (void)shouldItemsShow:(BOOL)show animated:(BOOL)animated {
    self.recordHintLabel.alpha = show && !self.speedControlViewModel.speedControlButtonSelected ? 1 : 0;
}

#pragma mark - ViewModels

- (ACCSpeedControlViewModel *)speedControlViewModel
{
    ACCSpeedControlViewModel *speedControlViewModel = [self getViewModel:ACCSpeedControlViewModel.class];
    return speedControlViewModel;
}

//- (ACCQuickAlbumViewModel *)quickAlbumViewModel
//{
//    ACCQuickAlbumViewModel *quickAlbumViewModel = [self getViewModel:ACCQuickAlbumViewModel.class];
//    return quickAlbumViewModel;
//}

@end
