//
//  ACCRecordSwitchModeComponent.m
//  Pods
//
//  Created by songxiangwu on 2019/7/30.
//

#import "AWERepoFlowControlModel.h"
#import "ACCRecordSwitchModeComponent.h"

#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIApplication+ACC.h>
#import <CameraClient/ACCRecordModeFactory.h>
#import "AWEMVTemplateModel.h"

#import "ACCRecordFlowService.h"
#import "AWEVideoRecordOutputParameter.h"
#import "AWERecorderTipsAndBubbleManager.h"
#import <CreativeKit/ACCRecorderViewContainer.h>
#import "ACCRecordSwitchModeViewModel.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitArch/ACCRecordTrackService.h>
#import <CreationKitArch/AWESwitchModeSingleTabConfig.h>
#import "AWERecorderTipsAndBubbleManager.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import "ACCRecordContainerMode.h"
#import "ACCFlowerService.h"
#import "ACCFlowerCampaignManagerProtocol.h"
#import "AWESwitchModeSingleTabConfigD.h"
#import "ACCConfigKeyDefines.h"

#import <CreationKitArch/ACCRepoGameModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import <CreationKitArch/ACCRepoVideoInfoModel.h>
#import <CreationKitArch/CKConfigKeysDefines.h>

@interface ACCRecordSwitchModeComponent () <ACCRecordVideoEventHandler, ACCRecordSwitchModeServiceSubscriber, ACCRecorderViewContainerItemsHideShowObserver, ACCFlowerServiceSubscriber>

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCRecordModeFactory> modeFactory;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCFlowerService> flowerService;

@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, strong, readwrite) ACCGroupedPredicate *shouldShowSwitchModeView;
@property (nonatomic, strong) ACCRecordSwitchModeViewModel *viewModel;

@end

@implementation ACCRecordSwitchModeComponent


IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, modeFactory, ACCRecordModeFactory)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, flowerService, ACCFlowerService)

#pragma mark - life cycle

- (instancetype)initWithContext:(id<IESServiceProvider>)context
{
    self = [super initWithContext:context];
    if (self) {
        _isFirstAppear = YES;
    }
    return self;
}

#pragma mark - ACCFeatureComponent

- (void)loadComponentView
{
    self.viewContainer.switchModeContainerView.delegate = self.viewModel;
    self.viewContainer.switchModeContainerView.dataSource = self.viewModel;
    [self.viewContainer.switchModeContainerView reloadData];
    
    @weakify(self);
    [RACObserve(self.cameraService.recorder, recorderState).deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        ACCCameraRecorderState state = x.integerValue;
        switch (state) {
            case ACCCameraRecorderStateNormal:
                [self updateSwitchModeViewHidden:NO];
                break;
            case ACCCameraRecorderStatePausing: {
                if (self.repository.repoGame.gameType == ACCGameTypeNone) {
                    [self updateSwitchModeViewHidden:[self enableWaterfallStyleMVTemplatesVC] && self.viewContainer.isShowingMVDetailVC];
                }
                break;
            }
            case ACCCameraRecorderStateRecording:
                [self.viewContainer.switchModeContainerView acc_fadeHidden];
                break;
            default:
                break;
        }
    }];
}

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    
    [self bindViewModel];

    NSMutableArray *tabList = [NSMutableArray array];
    [self.viewModel.tabConfigArray enumerateObjectsUsingBlock:^(AWESwitchModeSingleTabConfig * _Nonnull config, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *tabName = [self.modeFactory modeWithIdentifier:config.recordModeId].trackIdentifier;
        if (!ACC_isEmptyString(tabName)) {
            [tabList addObject:tabName];
        }
    }];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"tab_list"] = tabList;
    [ACCTracker() trackEvent:@"shoot_page_tab_show" params:params needStagingFlag:NO];
    
    if (self.isFirstAppear) {
        [self.switchModeService updateModeSelection:YES];
    }
}

- (void)componentDidAppear
{
    if (self.isFirstAppear) {
        self.isFirstAppear = NO;
    }
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)bindViewModel
{
    [self.viewContainer addObserver:self];
    [self handleExclusiveLiveTabIfNeeded];
}

- (void)showSwitchContainerViewIfNeed
{
    BOOL exclusiveLiveTabNotNeedShow = self.repository.repoFlowControl.showOneTabExclusively && ACCRecordModeLive == self.repository.repoFlowControl.exclusiveRecordModeId;
    if (!exclusiveLiveTabNotNeedShow) {
        [self.viewContainer.switchModeContainerView acc_fadeShow];
    }
}

- (void)handleExclusiveLiveTabIfNeeded
{
    if (self.repository.repoFlowControl.showOneTabExclusively && ACCRecordModeLive == self.repository.repoFlowControl.exclusiveRecordModeId) {
        [self.viewContainer.switchModeContainerView acc_fadeHidden];
    }
}

- (void)updateSwitchModeViewHidden:(BOOL)hidden
{
    AWEVideoType videoType = self.repository.repoContext.videoType;
    BOOL hasRecordedVideo = self.repository.repoVideoInfo.fragmentInfo.count && videoType != AWEVideoTypePhotoToVideo && videoType != AWEVideoTypeLiteTheme;
    if (hasRecordedVideo || self.repository.repoReshoot.isReshoot || self.viewContainer.isShowingAnyPanel || self.repository.repoGame.gameType != ACCGameTypeNone || self.cameraService.recorder.isRecording) {
        hidden = YES;
    }
    hidden = hidden || ![self.shouldShowSwitchModeView evaluate];
    if (hidden) {
        [self.viewContainer.switchModeContainerView acc_fadeHidden];
    } else {
        [self showSwitchContainerViewIfNeed];
    }
}

- (BOOL)enableWaterfallStyleMVTemplatesVC
{
    return self.switchModeService.currentRecordMode.modeId == ACCRecordModeMV;
}

- (BOOL)isSplitting
{
    return !ACC_FLOAT_EQUAL_TO(ACC_SCREEN_WIDTH, [UIScreen mainScreen].bounds.size.width);
}

#pragma mark - getter & setter

- (ACCRecordSwitchModeViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self.modelFactory createViewModel:ACCRecordSwitchModeViewModel.class];
    }
    return _viewModel;
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [IESAutoInline(self.serviceProvider, ACCRecordTrackService) registRecordVideoHandler:self];
    [self.switchModeService addSubscriber:self];
    [self.flowerService addSubscriber:self];
}

#pragma mark - ACCRecordVideoEventHandler

- (NSDictionary *)recordVideoEvent
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    params[@"record_type"] = [self p_getRecordType];
    params[@"record_mode"] = [self p_getRecordMode];
    return [params copy];
}

// 用于埋点 - 获取 record_video 事件的 record_mode 参数的值
- (NSString *)p_getRecordMode
{
    if (self.switchModeService.currentRecordMode.isPhoto ||
        self.switchModeService.currentRecordMode.isVideo) {
        return self.switchModeService.currentRecordMode.trackIdentifier ? : @"";
    }
    return @"";
}

- (NSString *)p_getRecordType
{
    if (self.switchModeService.currentRecordMode.isPhoto ||
        self.switchModeService.currentRecordMode.isVideo){
        return self.flowService.mixSubtype == AWERecordModeMixSubtypeTap ? @"click" : @"press";
    }
    return @"";
}

#pragma mark - ACCRecorderViewContainerItemsHideShowObserver

- (void)shouldItemsShow:(BOOL)show animated:(BOOL)animated
{
    if (animated) {
        [self updateSwitchModeViewHidden:!show];
    }
}

#pragma mark - ACCFlowerServiceSubscriber

- (void)flowerServiceWillEnterFlowerMode:(nullable id<ACCFlowerService>)service
{
    if (!ACCConfigBool(kConfigBool_enable_story_tab_in_recorder)) {
        return;
    }
    
    //用户未预约或命中Flower相机独立实验
    if(![ACCFlowerCampaignManager() currentUserHasBooked] ||
       !ACCConfigBool(kConfigBool_tools_flower_show_card_gather_entrance)) {
        return;
    }

    for (AWESwitchModeSingleTabConfigD *tabConfig in self.viewModel.tabConfigArray) {
        if(tabConfig.recordModeId == ACCRecordModeStory &&
           self.switchModeService.currentRecordMode.modeId == ACCRecordModeStory &&
           self.switchModeService.currentRecordMode.isInitial){
            ACCDynamicCast(tabConfig, AWESwitchModeSingleTabConfigD).flowerMode = YES;
            ACCDynamicCast(tabConfig, AWESwitchModeSingleTabConfigD).shouldShowFlower = YES;
            break;
        }
    }
}

- (void)flowerServiceDidLeaveFlowerMode:(nullable id<ACCFlowerService>)service
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSInteger defaultItemIndex = -1;
        for (AWESwitchModeSingleTabConfigD *tabConfig in self.viewModel.tabConfigArray) {
            if(ACCDynamicCast(tabConfig, AWESwitchModeSingleTabConfigD).flowerMode &&
               ACCDynamicCast(tabConfig, AWESwitchModeSingleTabConfigD).shouldShowFlower){
                defaultItemIndex = [self.viewModel.tabConfigArray indexOfObject:tabConfig];
            }
        }
        
        [self modeArrayDidChanged];
        
        if(defaultItemIndex > 0){
            [self.viewContainer.switchModeContainerView setDefaultItemAtIndex: defaultItemIndex];
        }
    });
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceWillChangeToMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    self.repository.repoFlowControl.modeId = mode.modeId;
    if (mode.isPhoto) {
        if (mode.modeId == ACCRecordModeLivePhoto) { // livePhoto特殊，设置为视频模式
            self.cameraService.recorder.cameraMode = HTSCameraModeVideo;
            [AWEVideoRecordOutputParameter configRecordingMultiSegmentMaximumResolutionLimit];
        } else {
            self.cameraService.recorder.cameraMode = HTSCameraModePhoto;
        }
        [ACCTracker() trackEvent:@"shoot_photo_mode"
             label:@"shoot_page"
             value:nil
             extra:nil
        attributes:self.repository.repoTrack.referExtra];
    } else if (mode.isVideo) {
        self.cameraService.recorder.cameraMode = HTSCameraModeVideo;
        [AWEVideoRecordOutputParameter configRecordingMultiSegmentMaximumResolutionLimit];
        [ACCTracker() trackEvent:@"shoot_mode"
                           label:@"shoot_page"
                           value:nil
                           extra:nil
                      attributes:self.repository.repoTrack.referExtra];
    }
    
    [self.viewModel changeCurrentLengthMode:mode];
    
    if (self.repository.repoVideoInfo.fragmentInfo.count == 0) {
        self.repository.repoFlowControl.videoRecordButtonType = mode.buttonType;
    }
}

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    self.viewContainer.switchModeContainerView.cursorView.hidden = NO;
    if (mode.modeId == ACCRecordModeTakePicture ||
        mode.modeId == ACCRecordModeLivePhoto) {
        [self.cameraService.cameraControl changeOutputSize:CGSizeMake(720, 1280)];
        [[AWERecorderTipsAndBubbleManager shareInstance] removeBubbleAndHintIfNeeded];
    }
    
    if (mode.isVideo) {
        CGSize size = [AWEVideoRecordOutputParameter expectedMaxRecordWriteSizeForPublishModel:self.repository];
        if (!CGSizeEqualToSize(self.cameraService.config.outputSize, size)) {
            CGSize configSize = self.cameraService.config.outputSize;
            [self.cameraService.cameraControl changeOutputSize:size];
            AWELogToolError2(@"resolution", AWELogToolTagRecord, @"unexpected recording write-in resolution: %@, expected resolution: %@, isDuet:%@, isDraft:%@, isbackUp:%@", NSStringFromCGSize(configSize), NSStringFromCGSize(size), @(self.repository.repoDuet.isDuet), @(self.repository.repoDraft.isDraft), @(self.repository.repoDraft.isBackUp));
        }
    }

    // 打开无障碍功能及切换到文字/影集/直播，需要屏蔽底层的subviews相应
    if (mode.modeId == ACCRecordModeText || mode.modeId == ACCRecordModeMV || mode.modeId == ACCRecordModeLive || mode.modeId == ACCRecordModeKaraoke) {
        self.viewContainer.interactionView.isAccessibilityElement = NO;
        self.viewContainer.interactionView.accessibilityElementsHidden = YES;
    } else {
        self.viewContainer.interactionView.isAccessibilityElement = NO;
        self.viewContainer.interactionView.accessibilityElementsHidden = NO;
    }
}

- (void)tabConfigDidUpdatedWithModeId:(NSInteger)modeId
{
    [self.viewContainer.switchModeContainerView updateTabConfigForModeId:modeId];
}

- (void)didUpdatedSelectedIndex:(NSInteger)index isInitial:(BOOL)initial
{
    if (initial) {
        [self.viewContainer.switchModeContainerView setDefaultItemAtIndex:index];
    } else {
        [self.viewContainer.switchModeContainerView selectItemAtIndex:index animated:YES];
    }
}

- (void)modeArrayDidChanged
{
    if (self.isMounted) {
        [self.viewContainer.switchModeContainerView reloadData];
    }
}

- (ACCGroupedPredicate *)shouldShowSwitchModeView
{
    if (!_shouldShowSwitchModeView) {
        _shouldShowSwitchModeView = [[ACCGroupedPredicate alloc] init];
    }
    return _shouldShowSwitchModeView;
}

@end

