//
//  ACCRecorderPendantComponent.m
//  Indexer
//
//  Created by HuangHongsen on 2021/11/1.
//

#import "ACCRecorderPendantComponent.h"
#import "ACCRecorderPendantView.h"
#import "ACCRecorderPendantViewModel.h"
#import "ACCRecordFlowService.h"
#import "ACCRecordPropService.h"
#import "ACCRecordContainerMode.h"
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreativeKit/UIDevice+ACCHardware.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import "ACCRepoRearResourceModel.h"

#import <CreativeKit/ACCMacrosTool.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>

@interface ACCRecorderPendantComponent ()<ACCRecorderPendantViewDelegate, ACCRecordSwitchModeServiceSubscriber, ACCPanelViewDelegate, ACCRecordFlowServiceSubscriber, ACCRecordPropServiceSubscriber>
@property (nonatomic, weak) id<ACCRecorderViewContainer> viewContainer;

@property (nonatomic, strong) ACCRecorderPendantView *pendantView;
@property (nonatomic, strong) ACCRecorderPendantViewModel *viewModel;

@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCRecordFlowService> recordFlowService;
@property (nonatomic, strong) id<ACCRecordPropService> propService;

@property (nonatomic, assign) BOOL pendantShowing;
@property (nonatomic, assign) ACCRecorderPendantResourceType pendantResourceType;

@end

@implementation ACCRecorderPendantComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, recordFlowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, propService, ACCRecordPropService)
#pragma mark - Life Cycle

- (void)componentDidMount
{
    [self.viewContainer.panelViewController registerObserver:self];
    [self setupPendantView];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseLazy;
}

- (void)setupPendantView
{
    self.pendantResourceType = ACCRecorderPendantResourceTypeNotInitialized;
    if ([self shouldShowPendantInMode:self.switchModeService.currentRecordMode]) {
        @weakify(self);
        [self.viewModel checkPendantShouldShowWithCompletion:^(ACCRecorderPendantResourceType resourceType, NSArray *iconURLList, NSDictionary *lottieJSON) {
            @strongify(self);
            self.pendantResourceType = resourceType;
            if (resourceType != ACCRecorderPendantResourceTypeNone) {
                [self.pendantView loadResourceWithType:resourceType urlList:iconURLList lottieJSON:lottieJSON completion:^(BOOL success) {
                    @strongify(self);
                    if (success) {
                        self.pendantView.alpha = 0.f;
                        [self.viewContainer.rootView addSubview:self.pendantView];
                        [self updatePandentStatusWithRecordMode:self.switchModeService.currentRecordMode];
                        
                    } else {
                        [self hidePendant];
                    }
                }];
            } else {
                [self hidePendant];
            }
        }];
    }
}

#pragma mark - Getter

- (ACCRecorderPendantView *)pendantView
{
    if (!_pendantView) {
        CGSize pendantSize = [ACCRecorderPendantView pendentSize];
        CGFloat topInset = 54;
        if ([UIDevice acc_screenHeightCategory] >= ACCScreenHeightCategoryiPhone6Plus) {
            topInset = 64;
        }
        topInset += ACC_STATUS_BAR_NORMAL_HEIGHT;
        _pendantView = [[ACCRecorderPendantView alloc] initWithFrame:CGRectMake(0, topInset, pendantSize.width, pendantSize.height)];
        _pendantView.backgroundColor = [UIColor clearColor];
        _pendantView.delegate = self;
    }
    return _pendantView;
}

- (ACCRecorderPendantViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self getViewModel:ACCRecorderPendantViewModel.class];
    }
    return _viewModel;
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.switchModeService addSubscriber:self];
    [self.recordFlowService addSubscriber:self];
    [self.propService addSubscriber:self];
}

#pragma mark - ACCRecordPropServiceSubscriber

- (void)propServiceDidShowPanel:(UIView *)panel
{
    [self hidePendant];
}

- (void)propServiceDidDismissPanel:(UIView *)panel
{
    [self updatePandentStatusWithRecordMode:self.switchModeService.currentRecordMode];
}

#pragma mark - ACCRecordFlowServiceSubscriber

- (void)flowServiceStateDidChanged:(ACCRecordFlowState)state preState:(ACCRecordFlowState)preState
{
    if (state == ACCRecordFlowStateStart) {
        [self hidePendant];
    }
}

#pragma mark - ACCPanelViewDelegate

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController willShowPanelView:(id<ACCPanelViewProtocol>)panelView
{
    [self hidePendant];
}

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController willDismissPanelView:(id<ACCPanelViewProtocol>)panelView
{
    [self updatePandentStatusWithRecordMode:self.switchModeService.currentRecordMode];
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    [self updatePandentStatusWithRecordMode:mode];
}

#pragma mark - ACCRecorderPendantViewDelegate

- (void)userDidClosePendantView:(ACCRecorderPendantView *)pendantView
{
    [ACCTracker() trackEvent:@"shoot_decoration_close"
                      params:@{
        @"enter_from" : @"video_shoot_page",
        @"activity_id": self.viewModel.activityID ? : @"",
    }];
    [self hidePendant];
    [self.viewModel handleUserClosePandent];
}

- (void)userDidTapOnPendantView:(ACCRecorderPendantView *)pendantView
{
    [ACCTracker() trackEvent:@"shoot_decoration_click"
                      params:@{
        @"enter_from" : @"video_shoot_page",
        @"activity_id": self.viewModel.activityID ? : @"",
    }];
    [self.viewModel handleUserTapOnPendant];
}

#pragma mark - Private Helper

- (void)updatePandentStatusWithRecordMode:(ACCRecordMode *)recordMode
{
    if ([self shouldShowPendantInMode:self.switchModeService.currentRecordMode]) {
        if (self.pendantView.resourceLoaded) {
            [self showPendant];
        } else {
            [self hidePendant];
        }
    } else {
        [self hidePendant];
    }
}

- (BOOL)shouldShowPendantInMode:(ACCRecordMode *)recordMode
{
    NSString *shootway = self.repository.repoTrack.referString;
    if ([self.viewModel userDidClosePendant]) {
        return NO;
    }
    if (self.pendantResourceType == ACCRecorderPendantResourceTypeNone) {
        return NO;
    }
    if ([IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isChildMode]) {
        return NO;
    }
    if (![shootway isEqualToString:@"direct_shoot"] && ![shootway isEqualToString:@"slide_shoot"] && ![shootway isEqualToString:@"super_entrance"]) {
        return NO;
    }
    if (!ACC_isEmptyArray(self.repository.RepoRearResource.stickerIDArray)) {
        return NO;
    }
    if (self.repository.repoDraft.isDraft) {
        return NO;
    }
    if (self.propService.prop) {
        return NO;
    }
    NSInteger modeID = recordMode.modeId;
    if ([recordMode isMemberOfClass:[ACCRecordContainerMode class]]) {
        ACCRecordContainerMode *containerMode = (ACCRecordContainerMode *)recordMode;
        return [self shouldShowPendantInMode:containerMode.submodes[containerMode.currentIndex]];
    }
    if ([recordMode isMemberOfClass:[ACCRecordMode class]]) {
        if (modeID != ACCRecordModeLive && modeID != ACCRecordModeMV && modeID != ACCRecordModeCombined && modeID != ACCRecordModeText && modeID != ACCRecordModeStoryCombined && modeID != ACCRecordModeKaraoke) {
            return YES;
        } else {
            return NO;
        }
    }
    return NO;
}

- (void)hidePendant
{
    [UIView animateWithDuration:0.15 animations:^{
        self.pendantView.alpha = 0.f;
    } completion:^(BOOL finished) {
        self.pendantShowing = NO;
    }];
}

- (void)showPendant
{
    if (self.pendantShowing) {
        return ;
    }
    [ACCTracker() trackEvent:@"shoot_decoration_show"
                      params:@{
        @"enter_from" : @"video_shoot_page",
        @"activity_id": self.viewModel.activityID ? : @"",
    }];
    [UIView animateWithDuration:0.15 animations:^{
        self.pendantView.alpha = 1.f;
    } completion:^(BOOL finished) {
        self.pendantShowing = YES;
    }];
}

@end
