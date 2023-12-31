//
//  ACCQuickStoryRecordComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by 李一凡 on 2020/6/29.
//

#import "AWERepoContextModel.h"
#import "ACCQuickStoryRecordComponent.h"
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreationKitArch/ACCRecorderToolBarDefines.h>
#import "ACCRecordFlowService.h"
#import "ACCSwitchLengthView.h"
#import <BDWebImage/BDImageView.h>
#import "ACCPropViewModel.h"
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import "ACCRecordPropService.h"
#import "ACCRecordModeFactory.h"
#import "ACCQuickStoryRecorderTipsViewModel.h"
#import "ACCRecordFlowConfigProtocol.h"
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CameraClient/ACCRecordMode+LiteTheme.h>

@interface ACCQuickStoryRecordComponent () <ACCRecordFlowServiceSubscriber, ACCRecordSwitchModeServiceSubscriber>

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCRecordModeFactory> modeFactory;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCRecordPropService> propService;
@property (nonatomic, strong) id<ACCRecordFlowConfigProtocol> flowConfig;

@property (nonatomic, strong) BDImageView *lightningView;

@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, assign) BOOL isQuickAlbumShow;
@property (nonatomic, copy) NSNumber *showingTipsToken;

@end

@implementation ACCQuickStoryRecordComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, modeFactory, ACCRecordModeFactory)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, propService, ACCRecordPropService)
IESAutoInject(self.serviceProvider, flowConfig, ACCRecordFlowConfigProtocol)

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)loadComponentView
{
    if (self.switchModeService.currentRecordMode.isStoryStyleMode) {
        [self showAnimatedLightning];
    }
}

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    self.isFirstAppear = YES;
    @weakify(self);
    if ([self.viewContainer.barItemContainer respondsToSelector:@selector(setFoldOrExpandBlock:)]) {
        [self.viewContainer.barItemContainer setFoldOrExpandBlock:^(BOOL isToFolded) {
            @strongify(self);
            [ACCTracker() trackEvent:@"click_more_icon" params:@{
                @"enter_from" : @"video_shoot_page",
                @"shoot_way" : self.repository.repoTrack.referString ?: @""
            } needStagingFlag:NO];
        }];
    }
}

- (void)componentWillAppear
{
    if ([self shouldShowRecordHintLabel]) {
        self.showingTipsToken = [[self tipsViewModel] showRecordHintLabel:(![self.flowConfig enableTapToTakePictureRecordMode:self.switchModeService.currentRecordMode.isStoryStyleMode])? ACCLocalizedString(@"creation_shoot_snap_too_short", @"Video must be longer, try again") : ACCLocalizedString(@"creation_shoot_snap_guide", @"Tap to take a picture, long press to shoot") exclusive:YES];
    }
}

- (void)componentDidAppear
{
    if (self.switchModeService.currentRecordMode.isStoryStyleMode) {
        [self showAnimatedLightning];
    }
    if (self.isFirstAppear) {
        self.isFirstAppear = NO;
    }
}

- (void)showAnimatedLightning
{
    if ([self.flowConfig enableLightningStyleRecordButton] || [self shouldRemoveFlashIcon]) {
        return;
    }

    if (!_lightningView) {
        CGFloat w = 80;
        _lightningView = [[BDImageView alloc] initWithFrame:CGRectMake(w / 4, w / 4, w / 2, w / 2)];
        _lightningView.image = ACCResourceImage(@"icon_lightning");
        UIView *recordButton = [self.viewContainer.layoutManager viewForType:ACCViewTypeRecordButton];
        [recordButton addSubview:_lightningView];
    }
    _lightningView.hidden = NO;
    [_lightningView startAnimating];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.flowService addSubscriber:self];
    [self.switchModeService addSubscriber:self];
}

- (BOOL)shouldShowRecordHintLabel
{
    return [self.flowConfig enableTapToTakePictureRecordMode:self.switchModeService.currentRecordMode.isStoryStyleMode];
}

#pragma mark - getter setter


#pragma mark - ACCRecordFlowServiceSubscriber

- (void)flowServiceStateDidChanged:(ACCRecordFlowState)state preState:(ACCRecordFlowState)preState
{
    switch (state) {
        case ACCRecordFlowStateStart: {
            self.lightningView.hidden = YES;
            break;
        }
        default: {
            if (self.switchModeService.currentRecordMode.isStoryStyleMode) {
                [self showAnimatedLightning];
            }
            break;
        }
    }
}

#pragma mark - getteer

- (ACCQuickStoryRecorderTipsViewModel *)tipsViewModel
{
    return [self getViewModel:[ACCQuickStoryRecorderTipsViewModel class]];
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    if (self.isFirstAppear) {
        return;
    }
    if ([self shouldShowRecordHintLabel]) {
        self.showingTipsToken = [[self tipsViewModel] showRecordHintLabel:(![self.flowConfig enableTapToTakePictureRecordMode:self.switchModeService.currentRecordMode.isStoryStyleMode])? ACCLocalizedString(@"creation_shoot_snap_too_short", @"Video must be longer, try again") : ACCLocalizedString(@"creation_shoot_snap_guide", @"Tap to take a picture, long press to shoot") exclusive:YES];
    } else {
        [[self tipsViewModel] hideRecordHintLabelWithToken:self.showingTipsToken];
    }

    if (mode.isStoryStyleMode) {
        [self showAnimatedLightning];
    } else {
        self.lightningView.hidden = YES;
    }
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarDelayRecordContext];
}

- (BOOL)shouldRemoveFlashIcon
{
    return self.repository.repoContext.isIMRecord;
}

@end
