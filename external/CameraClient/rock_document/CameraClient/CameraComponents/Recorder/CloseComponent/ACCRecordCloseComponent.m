//
//  ACCRecordCloseComponent.m
//  Pods
//
//  Created by songxiangwu on 2019/7/28.
//

#import "AWERepoDraftModel.h"
#import "AWERepoTrackModel.h"
#import "AWERepoPropModel.h"
#import "ACCRecordCloseComponent.h"
#import <CreationKitArch/ACCEditAndPublishConstants.h>

#import <CreativeKit/ACCRecorderViewContainer.h>

#import <CreativeKit/ACCMemoryTrackProtocol.h>
#import "ACCRecordCloseViewModel.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreativeKit/ACCAnimatedButton.h>
#import "ACCRecordFlowService.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import "ACCPublishServiceFactoryProtocol.h"
#import "ACCPublishNetServiceProtocol.h"
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import "ACCMultiStyleAlertProtocol.h"
#import "ACCEditServiceUtils.h"
#import "ACCFriendsServiceProtocol.h"
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoGameModel.h>
#import "AWERepoVideoInfoModel.h"
#import "AWEVideoFragmentInfo.h"
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import "ACCRepoUserIncentiveModelProtocol.h"
#import "ACCRepoQuickStoryModel.h"
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CameraClient/ACCDraftProtocol.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import "ACCVideoPublishProtocol.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCRouterProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import "ACCRepoKaraokeModelProtocol.h"
#import "ACCStudioGlobalConfig.h"
#import <CameraClient/ACCUIReactTrackProtocol.h>
#import <CameraClient/AWERepoContextModel.h>
#import "ACCKaraokeService.h"
#import "AWERepoDuetModel.h"
#import "AWERecordFirstFrameTrackerNew.h"
#import <CreativeKit/ACCAccessibilityProtocol.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CameraClient/ACCDraftSaveLandingProtocol.h>
#import <CameraClient/ACCFlowerService.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitInfra/ACCTapticEngineManager.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import "ACCRecordCloseHandlerProtocol.h"

@interface ACCRecordCloseComponent() <ACCRecorderViewContainerItemsHideShowObserver>

/// 通过设置config展示不同的显示内容
@property (nonatomic, strong) ACCMultiStyleAlertConfigParamsBlock backAlertConfig;
/// 返回挽留弹窗
@property (nonatomic, strong) NSObject<ACCMultiStyleAlertProtocol> *backAlert;

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) ACCRecordCloseViewModel *viewModel;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) ACCAnimatedButton *closeButton;
@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCPublishServiceProtocol> publishService;
@property (nonatomic, strong, readwrite) AWEResourceUploadParametersResponseModel *uploadParamsCache;
@property (nonatomic, strong, readwrite) ACCGroupedPredicate *showButtonPredicte;
@end

@implementation ACCRecordCloseComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)


#pragma mark - ACCFeautreComponent

- (void)loadComponentView
{
    UIImage *image = ACCResourceImage(@"ic_titlebar_close_white");
    [self.closeButton setImage:image forState:UIControlStateNormal];
    UIView *superView = self.viewContainer.interactionView;
    [superView addSubview:self.closeButton];
    [self.closeButton addTarget:self action:@selector(clickBackBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.closeButton.superview bringSubviewToFront:self.closeButton];
}

- (void)componentDidMount
{
    self.isFirstAppear = YES;
    self.isAccessibilityElement = YES;
    self.accessibilityLabel = ACCLocalizedCurrentString(@"off");
    
    // multi seg prop not support draft return record page. in order to impl draft -> edit -> record(clear) -> select multi prop again -> edit -> record(should not clear) use mount to avoid the clear again.
    if ([self.publishModel.repoProp isMultiSegPropApplied] && (self.publishModel.repoDraft.isDraft || self.publishModel.repoDraft.isBackUp)) {
        [self removeAllSegments];
    }
}

- (void)p_bindViewModelObserver
{
    @weakify(self);
    [RACObserve(self.cameraService.recorder, recorderState).deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        ACCCameraRecorderState state = x.integerValue;
        switch (state) {
            case ACCCameraRecorderStateNormal:
                break;
            case ACCCameraRecorderStatePausing:
                [self updateCloseButtonVisibility];
                break;
            case ACCCameraRecorderStateRecording:
                [self updateCloseButtonVisibility];
                break;
        }
    }];
}

- (void)componentWillAppear
{
    if (self.isFirstAppear) {
        if (![self.controller enableFirstRenderOptimize]) {
            [self loadComponentView];
        }
        [self.viewContainer addObserver:self];
    }
    
    // `story` mode throws away un-published data, ignore [self.flowService videoSegmentsCount] which is not correct
    // "takePicture" mode may have a fragment when camera uses pixloop or greenScreen props. remove it if needed
    ACCRecordModeIdentifier modeID = self.switchModeService.currentRecordMode.modeId;
    id<ACCRepoKaraokeModelProtocol> repoKaraoke = [self.repository extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
    if (modeID == ACCRecordModeStory ||
        modeID == ACCRecordModeTakePicture ||
        modeID == ACCRecordModeLivePhoto ||
        repoKaraoke.lightningStyleKaraoke ||
        modeID == ACCRecordModeAudio ||
        modeID == ACCRecordModeTheme) {
        [self removeAllSegments];
    }
    self.repository.repoMusic.bgmClipRange = nil;
}

- (void)removeAllSegments
{
    self.closeButton.userInteractionEnabled = NO;
    // calls [self.camera removeAllVideoFragments], which is async
    if (self.cameraService.cameraHasInit) {
        [self.flowService deleteAllSegments:^{
            acc_dispatch_main_async_safe(^{
                self.closeButton.userInteractionEnabled = YES;
            });
        }];
    } else {
        self.closeButton.userInteractionEnabled = YES;
    }
}

- (void)componentDidAppear
{
    if (self.isFirstAppear) {
        [self p_bindViewModelObserver];
        self.isFirstAppear = NO;
    }
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    if ([self.controller enableFirstRenderOptimize]) {
        return ACCFeatureComponentLoadPhaseBeforeFirstRender;
    }else {
        return ACCFeatureComponentLoadPhaseEager;
    }
    
}

#pragma mark - ACCRecorderViewContainerItemsHideShowObserver

- (void)shouldItemsShow:(BOOL)show animated:(BOOL)animated
{
    [self updateCloseButtonVisibility];
}

- (void)updateCloseButtonVisibility
{
    BOOL hide = self.viewContainer.itemsShouldHide || self.viewContainer.isShowingPanel || self.cameraService.recorder.recorderState == ACCCameraRecorderStateRecording || self.viewModel.inputData.publishModel.repoGame.gameType != ACCGameTypeNone;
    
    if (self.viewModel.inputData.publishModel.repoContext.flowerBooking == 1) {
        hide = NO;
    }
    
    if (hide || ![self.showButtonPredicte evaluate]) {
        [self.closeButton acc_fadeHidden];
    } else {
        [self.closeButton acc_fadeShow];
    }
}

- (void)closeRecorder
{
    BOOL isFromDuetSing = self.repository.repoDuet.isFromDuetSingTab;
    BOOL isFromDuetSingMode = self.repository.repoDuet.isFromDuetSingMode;
    NSString *referString = self.repository.repoTrack.referString ?: @"";
    if (isFromDuetSing) {
        [[AWERecordFirstFrameTrackerNew sharedTracker] clear]; // 合拍收不到 Effect 首帧回调，在这里兜底清除 firstFrame 数据。
        [ACCRouter() transferToURLStringWithFormat:@"aweme://studio/create?type=ktv&enter_from=%@&shoot_way=%@&ktv_detault_tab_id=%@&is_from_duet_recorder=1", referString, referString, kAWEKaraokeCollectionIDDuetSing];
    } else if (isFromDuetSingMode) {
        [[AWERecordFirstFrameTrackerNew sharedTracker] clear];
        [ACCRouter() transferToURLStringWithFormat:@"aweme://studio/create?type=duet_page&shoot_way=%@&enter_from=%@&enter_method=from_existed_page", referString, referString];
    } else {
        [self.controller close];
    }
}

#pragma mark - ACCComponentProtocol

- (UIView *)componentContentView
{
    return self.closeButton;
}

- (void)clickBackBtn:(id)sender
{
    if (!self.isMounted) {
        return;
    }
    
    let flowerService = IESAutoInline(self.serviceProvider, ACCFlowerService);
    
    [self.closeButton acc_disableUserInteractionWithTimeInterval:1.0];
    if ([self.viewModel.inputData.publishModel.repoTrack.referString isEqualToString:@"diary_shoot"] || [self.viewModel.inputData.publishModel.repoTrack.referString isEqualToString:@"slide_shoot"]) {
        NSString *enterFrom = @"homepage_familiar";
        NSInteger closeShootIntervalms = [IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) enterQuickRecordInFamiliarDateDiff] * 1000;
        [ACCTracker() trackEvent:@"close_video_shoot_page" params:@{
                                                                    @"enter_method" : sender ? @"click_button" : @"slide_down",
                                                                    @"shoot_way" : self.viewModel.inputData.publishModel.repoTrack.referString ?: @"",
                                                                    @"enter_from" : enterFrom ?: @"",
                                                                    @"close_shoot_interval_ms" : @(closeShootIntervalms),
                                                                    @"prop_panel_open" : @"0",
                                                                    @"publish_cnt" : @([ACCVideoPublish() publishTaskCount])
                                                                    }
         ];
    } else if ([self.viewModel.inputData.publishModel.repoTrack.referString isEqualToString:@"profile_visitor_list_shoot"]) {
        [ACCTracker() trackEvent:@"close_video_shoot_page" params:@{
                                                                    @"shoot_way" : self.viewModel.inputData.publishModel.repoTrack.referString ?: @"",
        }];
    } else if (flowerService.inFlowerPropMode) {
        [ACCTracker() trackEvent:@"close_video_shoot_page" params:@{
            @"enter_method" : @"click_button",
            @"tab_name" : @"sf_2022_activity_camera",
            // flower通用参数
            @"params_for_special" : @"flower",
        }];
    } else {
        [ACCTracker() trackEvent:@"close_video_shoot_page" params:@{
            @"enter_method" : sender ? @"click_button" : @"slide_down",
            @"publish_cnt" : @([ACCVideoPublish() publishTaskCount]),
            @"prop_panel_open" : @"0",
        }];
    }
    
    if (self.themeHandler && [self.themeHandler handleCloseButtonDidClick]) {
        return;
    }

    if ([self p_showBackAlertForDraftIfNeeded]) {
        return;
    }
    
    if ([self p_showBackAlertIfNeeded]) {
        return;
    }
    if ([self.cameraService.recorder fragmentCount] > 0 || self.viewModel.inputData.publishModel.repoDraft.isDraft) {
        [self showCancelShootAlertBtn:sender];
    } else {
        [ACCDraft() deleteDraftWithID:self.viewModel.inputData.publishModel.repoDraft.taskID];
        [ACCToolUIReactTrackService() eventBegin:kAWEUIEventClickCloseCamera];
        [self.viewModel manullyClickCloseButtonSuccessfullyClose];
        [self closeRecorder];
    }
    if (ACCConfigBool(kConfigBool_enable_story_tab_in_recorder) && ACCConfigBool(kConfigBool_enable_remember_last_tab)) {
        [ACCCache() setInteger:self.viewModel.inputData.publishModel.repoFlowControl.videoRecordButtonType forKey:@"last_record_button_type"];
    }
    if ([self.viewModel.inputData.publishModel.repoTrack musicLandingMultiLengthInitially]) {
        [ACCCache() setInteger:self.viewModel.inputData.publishModel.repoFlowControl.videoRecordButtonType forKey:@"last_record_button_type_for_music"];
    }
}

- (void)clearAllEditBackUps
{
    if (!self.viewModel.inputData.publishModel.repoReshoot.isReshoot) {
        [ACCDraft() clearAllEditBackUps];
    }
}

- (void)showCancelShootAlertBtn:(id)sender
{
    [self.flowService pauseRecord];
    NSDictionary *extra = self.viewModel.inputData.publishModel.repoTrack.referExtra;
    
    if (self.viewModel.inputData.publishModel.repoDraft.originalDraft == nil) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

        NSString *reshootTitle = self.reshootTitle ?: ACCLocalizedString(@"av_clear_recording_segments",@"重新拍摄");
        NSString *exitTitle = self.exitTitle ?: ACCLocalizedString(@"av_exit_recording", @"退出");
        NSString *cancelTitle = ACCLocalizedCurrentString(@"cancel");
        
        @weakify(self);
        [alertController addAction:[UIAlertAction actionWithTitle:reshootTitle  style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            [ACCTracker() trackEvent:@"reshoot" params:extra needStagingFlag:NO];
            [self.flowService deleteAllSegments];
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:exitTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            [ACCToolUIReactTrackService() eventBegin:kAWEUIEventClickCloseCamera];
            [self saveTheOriginalDraft];
            [self clearAllEditBackUps];
            [self closeRecorder];
            [self.viewModel manullyClickCloseButtonSuccessfullyClose];
            
            NSDictionary *data = @{@"service"   : @"record_error",
                                   @"action"    : @"cancel_shoot_confirm",
                                   @"task"      : self.viewModel.inputData.publishModel.repoDraft.taskID?:@"",};
            [ACCMonitor() trackData:data logTypeStr:@"aweme_movie_publish_log"];
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [ACCTracker() trackEvent:@"cancel_shoot_fail"
                                              label:@"shoot_page"
                                              value:nil
                                              extra:nil
                                         attributes:extra];
        }]];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [ACCAlert() showAlertController:alertController fromView:sender];
        } else {
            [ACCAlert() showAlertController:alertController animated:YES];
        }
        return;
    }
    
    @weakify(self);
    NSString *title = self.viewModel.inputData.closeWarning ?: ACCLocalizedCurrentString(@"com_mig_quit_recording");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedCurrentString(@"com_mig_confirm_mtsudt") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        [self p_exitForDraft];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedCurrentString(@"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        [self p_cancelForDraft];
    }]];
    [ACCAlert() showAlertController:alertController animated:YES];
}

- (void)saveTheOriginalDraft
{
    AWEVideoPublishViewModel *originalModel = self.viewModel.inputData.publishModel.repoDraft.originalModel;
    id<ACCDraftModelProtocol> originalDraft = self.viewModel.inputData.publishModel.repoDraft.originalDraft;
    
    if (originalModel!=nil && originalDraft!=nil) {
        [ACCDraft() saveDraftWithPublishViewModel:originalModel
                                            video:originalModel.repoVideoInfo.video
                                           backup:(originalDraft==nil)
                                   presaveHandler:^(id<ACCDraftModelProtocol> _Nonnull draft) {
            // 原先有草稿，这里的草稿恢复成原先的草稿时间
            if (originalDraft.saveDate != nil) {
                draft.saveDate = originalDraft.saveDate;
            }
        }
                                       completion:^(BOOL success, NSError * _Nonnull error) {
            if (success && !error) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kACCAwemeDraftUpdateNotification
                                                                    object:nil
                                                                  userInfo:@{[ACCDraft() draftIDKey]: originalModel.repoDraft.taskID?:@""}];
            } else if ([error.domain isEqual:NSCocoaErrorDomain] && error.code == NSFileWriteOutOfSpaceError) {
                [ACCToast() show:ACCLocalizedString(@"disk_full", @"磁盘空间不足，请清理缓存后重试")];
            }
        }];
    }
}

#pragma mark - Private Methods

#pragma mark 挽留弹窗（草稿）
/// 只针对https://bytedance.feishu.cn/docs/doccnadChske4TiH55xv9KM8Mmb 特殊场景补充 11-3 做挽留弹窗实验补充
/// 目前只有分段拍的草稿能进拍摄页
- (BOOL)p_showBackAlertForDraftIfNeeded
{
    if(!self.repository.repoDraft.isDraft) {
        return NO;
    }
    // 若为线上样式则直接return, 线上样式走兜底弹窗，系统alert
    if (!ACCMultiStyleAlertParamsProtocol(ACCConfigInt(kConfigInt_creative_edit_record_beg_for_stay_prompt_style))) {
        return NO;
    }
    self.backAlertConfig = [self p_draftBackAlertConfig];
    [self.backAlert show];
    return YES;
}


/// 草稿挽留弹窗配置
- (ACCMultiStyleAlertConfigParamsBlock)p_draftBackAlertConfig
{
    @weakify(self);
    return ^(id<ACCMultiStyleAlertBaseParamsProtocol> params) {
        @strongify(self);

        //  Popover弹窗差异点
        ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(params, ACCMultiStyleAlertPopoverParamsProtocol, ^{
            params.alignmentMode = UIControlContentHorizontalAlignmentLeft;
            params.sourceView = self.closeButton;
            params.sourceRect = self.closeButton.bounds;
            params.fixedContentWidth = 160;
        });
        
        //  Alert差异点
        ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(params, ACCMultiStyleAlertNormalParamsProtocol, ^{
            params.title = self.viewModel.inputData.closeWarning ?: ACCLocalizedCurrentString(@"com_mig_quit_recording");
            params.isButtonAlignedVertically = YES;
        });
        
        
        BOOL isSheet = [params conformsToProtocol:@protocol(ACCMultiStyleAlertSheetParamsProtocol)];
        BOOL isAlert = [params conformsToProtocol:@protocol(ACCMultiStyleAlertNormalParamsProtocol)];
        
        // 放弃修改
        [params addAction:^(id<ACCMultiStyleAlertBaseActionProtocol> action) {
            @strongify(self);
            ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(action, ACCMultiStyleAlertPopoverActionProtocol, ^{
                action.image = ACCResourceImage(@"ic_actionlist_block_red");
            });
            action.actionStyle = ACCMultiStyleAlertActionStyleHightlight;
            action.title = isAlert ? @"放弃" : @"放弃修改";
            action.eventBlock = ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
                @strongify(self);
                [self p_exitForDraft];
            };
        }];
        // 取消
        if (isSheet || isAlert) {
            [params addAction:^(id<ACCMultiStyleAlertBaseActionProtocol> action) {
                action.title = @"取消";
                action.eventBlock = ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
                    @strongify(self);
                    [self p_cancelForDraft];
                };
            }];
        }
    };
}

/// 草稿时 退出逻辑
- (void)p_exitForDraft
{
    NSDictionary *extra = self.viewModel.inputData.publishModel.repoTrack.referExtra;
    [ACCTracker() trackEvent:@"cancel_shoot_confirm"
                       label:@"shoot_page"
                       value:nil
                       extra:nil
                  attributes:extra];
    
    [self saveTheOriginalDraft];
    [self clearAllEditBackUps];
    [self closeRecorder];
    [self.viewModel manullyClickCloseButtonSuccessfullyClose];
    
    NSDictionary *data = @{@"service"   : @"record_error",
                           @"action"    : @"cancel_shoot_confirm",
                           @"task"      : self.viewModel.inputData.publishModel.repoDraft.taskID?:@"",};
    [ACCMonitor() trackData:data logTypeStr:@"aweme_movie_publish_log"];
}

/// 草稿时 cancel逻辑
- (void)p_cancelForDraft
{
    NSDictionary *extra = self.viewModel.inputData.publishModel.repoTrack.referExtra;
    [ACCTracker() trackEvent:@"cancel_shoot_fail"
                                      label:@"shoot_page"
                                      value:nil
                                      extra:nil
                                 attributes:extra];
}
#pragma mark 挽留弹窗

/// 是否显示挽留弹窗 （可变样式）
- (BOOL)p_showBackAlertIfNeeded
{
    NSArray <ACCMultiStyleAlertConfigActionBlock> *businessActionConfigs = [self p_businessActionConfigs];
    if (businessActionConfigs.count > 0) {
        self.backAlertConfig = [self p_combineBackAlertConfigWithBusinessActionConfigs:businessActionConfigs];
        [self.backAlert show];
        NSMutableDictionary *params = self.viewModel.inputData.publishModel.repoTrack.referExtra.mutableCopy;
        params[@"tab_name"] = self.viewModel.inputData.publishModel.repoTrack.tabName;
        params[@"enter_from"] = @"video_shoot_page";
        params[@"enter_method"] = @"1";
        params[@"with_daily_button"] = [self p_shouldShowQuickPublishAction] ? @"1" : @"0";
        params[@"with_save_draft_button"] = [self p_shouldShowSaveDraftAction] ? @"1" : @"0";
        params[@"sheet_type"] = self.backAlert.trackerType;
        [ACCTracker() trackEvent:@"return_sheet_show" params:params];
        return YES;
    }
    return NO;
}


/// 公用的挽留弹窗Action埋点信息
- (NSDictionary *)p_commonBackAlertActionTrackInfo
{
    NSMutableDictionary *trackerParams = self.publishModel.repoTrack.referExtra.mutableCopy;
    trackerParams[@"tab_name"] = self.publishModel.repoTrack.tabName;
    trackerParams[@"enter_from"] = @"video_shoot_page";
    trackerParams[@"enter_method"] = @"1";
    trackerParams[@"sheet_type"] = self.backAlert.trackerType;
    return [trackerParams copy];
}

/// 过滤显示挽留弹窗的基本用例，若为NO，则直接不用显示
- (BOOL)p_filterBaseCaseForShowAction
{
    if ([self.publishModel.repoQuickStory shouldDisableQuickPublishActionSheet]) {
        return NO;
    }
    
    if (self.repository.repoDraft.isDraft) {
        return NO;
    }
    
    // 非分段拍
    if ([self.cameraService.recorder fragmentCount] == 0) {
        return NO;
    }
    
    // 红包
    NSArray<AWEVideoFragmentInfo *> *fragmentInfos = [self.publishModel.repoVideoInfo.fragmentInfo copy];
    for (AWEVideoFragmentInfo *object in fragmentInfos) {
        if ([object hasRedpacketSticker]) {
            return NO;
        }
    }
   
    return YES;
}


/// 过滤发日常和存草稿共同case （除ab实验外）
- (BOOL)p_filterCommonCaseForShowQuickPublishAndSaveDraftAction
{
    if (![self p_filterBaseCaseForShowAction]) {
        return NO;
    }
    // 分段道具
    if ([self.viewModel.inputData.publishModel.repoProp isMultiSegPropApplied]) {
        return NO;
    }
    // 拍摄时长不满足条件
    if(![self.flowService allowComplete]) {
        return NO;
    }
    // k歌
    if (self.viewModel.inputData.publishModel.repoContext.videoType == AWEVideoTypeKaraoke) {
        return NO;
    }
    
    // 裁剪点击重新拍摄
    if (self.repository.repoReshoot.isReshoot) {
        return NO;
    }
    
    return YES;
}

/// 是否显示重新拍摄
- (BOOL)p_shouldShowReshootAction
{
    if (![self p_filterBaseCaseForShowAction]) {
        return NO;
    }
    // 重新拍摄根据配置下发，原因是之前实验字段存在一种情况，只有重新拍摄和取消选项，无其余业务能力，但是要弹一样的弹窗
    // 为补齐这个能力，添加该字段
    return ACCConfigInt(kConfigInt_creative_record_beg_for_stay_option) & ACCRecordEditBegForStayOptionReshoot;
}

/// 是否显示发日常选项
- (BOOL)p_shouldShowQuickPublishAction
{
    if (![self p_filterCommonCaseForShowQuickPublishAndSaveDraftAction]) {
        return NO;
    }
    return ACCConfigInt(kConfigInt_creative_record_beg_for_stay_option) & ACCRecordEditBegForStayOptionQuickPublish;
}

/// 是否显示存草稿选项
- (BOOL)p_shouldShowSaveDraftAction
{
    if (![self p_filterCommonCaseForShowQuickPublishAndSaveDraftAction]) {
        return NO;
    }
    return ACCConfigInt(kConfigInt_creative_record_beg_for_stay_option) & ACCRecordEditBegForStayOptionSaveDraft;
}


/// 根据业务功能配置，组合为整个弹窗配置
- (ACCMultiStyleAlertConfigParamsBlock)p_combineBackAlertConfigWithBusinessActionConfigs:(NSArray <ACCMultiStyleAlertConfigActionBlock>*)businessActionConfigs
{
    @weakify(self);
    return ^(id<ACCMultiStyleAlertBaseParamsProtocol> params) {
        @strongify(self);
        ACCMultiStyleAlertConfigParamsBlock configWithoutAction = [self p_alertConfigWithoutAction];
        ACCBLOCK_INVOKE(configWithoutAction, params);
        
        // 组装actions
        NSMutableArray <ACCMultiStyleAlertConfigActionBlock> *actionConfigs = [NSMutableArray array];
        if (businessActionConfigs.count > 0) {
            [actionConfigs acc_addObject:[self p_exitActionConfig]];
            [actionConfigs acc_addObjectsFromArray:businessActionConfigs];
        }
        // 取消
        BOOL isSheet = [params conformsToProtocol:@protocol(ACCMultiStyleAlertSheetParamsProtocol)];
        BOOL isAlert = [params conformsToProtocol:@protocol(ACCMultiStyleAlertNormalParamsProtocol)];
        if (isSheet || isAlert) {
            [actionConfigs acc_addObject:[self p_cancelActionConfig]];
        }
        
        for (ACCMultiStyleAlertConfigActionBlock actionConfig in actionConfigs) {
            [params addAction:actionConfig];
        }
    };
}
/// 挽留弹窗配置（除Actions以外）
- (ACCMultiStyleAlertConfigParamsBlock)p_alertConfigWithoutAction
{
    @weakify(self);
    return ^(id<ACCMultiStyleAlertBaseParamsProtocol> params){
        @strongify(self);
        // Sheet差异点
        ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(params, ACCMultiStyleAlertSheetParamsProtocol, (^{
            id<ACCRepoUserIncentiveModelProtocol> userIncentiveModel = [self.viewModel.inputData.publishModel extensionModelOfProtocol:@protocol(ACCRepoUserIncentiveModelProtocol)];
            if (!ACC_isEmptyString([userIncentiveModel motivationTaskID])) {
                NSString *target = [userIncentiveModel motivationTaskTargetText] ;
                NSString *reward = [userIncentiveModel motivationTaskReward];
                if (ACC_isEmptyString(target)) {
                    target = @"任务";
                }
                if (ACC_isEmptyString(reward)) {
                    reward = @"奖励";
                }
                params.title = [NSString stringWithFormat:@"继续%@，即得%@", target, reward];
            }
        }));

        //  Popover弹窗差异点
        ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(params, ACCMultiStyleAlertPopoverParamsProtocol, ^{
            params.alignmentMode = UIControlContentHorizontalAlignmentLeft;
            params.sourceView = self.closeButton;
            params.sourceRect = self.closeButton.bounds;
            params.fixedContentWidth = 160;
        });
        
        //  Alert差异点
        ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(params, ACCMultiStyleAlertNormalParamsProtocol, ^{
            params.title = @"退出并清空内容吗？";
            params.isButtonAlignedVertically = YES;
        });
    };
}

/// 挽留弹窗业务功能 （后续需增加其他业务，直接往内部塞）
- (NSArray <ACCMultiStyleAlertConfigActionBlock>*)p_businessActionConfigs
{
    NSMutableArray <ACCMultiStyleAlertConfigActionBlock> *configs = [NSMutableArray array];
    // 重新拍摄
    if ([self p_shouldShowReshootAction]) {
        [configs acc_addObject:[self p_reshootActionConfig]];
    }
    // 存草稿
    if ([self p_shouldShowSaveDraftAction]) {
        [configs acc_addObject:[self p_saveDraftActionConfig]];
    }
    // 发日常
    if ([self p_shouldShowQuickPublishAction]) {
        [configs acc_addObject:[self p_quickPublishActionConfig]];
    }
    
    return [configs copy];
}

/// 存草稿功能
- (ACCMultiStyleAlertConfigActionBlock)p_saveDraftActionConfig
{
    @weakify(self);
    return ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
        ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(action, ACCMultiStyleAlertPopoverActionProtocol, ^{
            action.image = ACCResourceImage(@"ic_actionlist_draft");
        });
        action.title = @"存草稿";
        
        dispatch_block_t saveDraftWithLogin = ^ {
            @strongify(self);
            [ACCTracker() trackEvent:@"return_sheet_save_draft" params:[self p_commonBackAlertActionTrackInfo]];
            
            
            // 修复发布时，由于step问题，导致个人页草稿被过滤，显示不出来问题，具体可查看p_conditionIgnorePublishTask:方法。
            self.publishModel.repoFlowControl.step = AWEPublishFlowStepPublish;
            
            // 修复合拍时，背景音乐为空问题
            AVURLAsset *bgmAsset = (AVURLAsset *)self.publishModel.repoMusic.bgmAsset;
            NSURL *duetSourceURL = self.publishModel.repoDuet.duetLocalSourceURL;
            if (self.publishModel.repoDuet.isDuet && !bgmAsset && duetSourceURL) {
                AVAsset *sourceAsset = [AVURLAsset URLAssetWithURL:duetSourceURL  options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
                if ([sourceAsset isKindOfClass:[AVURLAsset class]] &&
                    CMTimeGetSeconds(sourceAsset.duration) > 0) {
                    self.publishModel.repoVideoInfo.video.audioAssets = @[sourceAsset];
                    self.publishModel.repoMusic.bgmAsset = sourceAsset;
                }
            }
            // 加特效时，草稿封面概现为空
            id<ACCEditServiceProtocol> editService = [ACCEditServiceUtils editServiceOnlyForPublishWithPublishModel:self.publishModel isMV:NO];
            [editService buildEditSession];
            [editService.preview resetPlayerWithViews:@[editService.mediaContainerView]]; // should remain
            
            UIView<ACCProcessViewProtcol> *loadingView = [ACCLoading() showProgressOnView:[UIApplication sharedApplication].delegate.window title:@"保存中" animated:YES type:ACCProgressLoadingViewTypeNormal];

            [ACCDraft() updateCoverImageWithViewModel:self.publishModel editService:editService completion:^(NSError * _Nonnull error) {
                @strongify(self);
               
                if (error) {
                    AWELogToolError2(@"draft", AWELogToolTagEdit, @"save draft cover %@", error);
                }
                [ACCDraft() saveDraftWithPublishViewModel:self.publishModel
                                                    video:self.repository.repoVideoInfo.video
                                                   backup:NO
                                               completion:^(BOOL success, NSError * _Nonnull error) {
                    acc_infra_main_async_safe(^{
                        @strongify(self);
                        [loadingView dismissWithAnimated:NO];
                        if (success) {
                            NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                            userInfo[[ACCDraft() draftIDKey]] = self.repository.repoDraft.taskID;
                            [center postNotificationName:[ACCDraft() draftUpdateNotificationName] object:nil userInfo:userInfo];
                            [ACCDraft() trackSaveDraftWithViewModel:self.repository from:@"video_shoot_page"];
                            
                            NSString *content = @"已保存至个人主页草稿箱";
                            if (ACCConfigInt(kConfigInt_enable_draft_tab_experiment) == ACCUserHomeProfileSubTabStyle) {
                                NSInteger counter = [ACCCache() integerForKey:[NSString stringWithFormat:@"ACCDraftSaveCounter%@", [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) currentLoginUserModel].userID]] ?: 0;
                                content = counter == 0? @"已保存至个人主页草稿箱，卸载抖音将会丢失草稿箱" : content;
                                [ACCCache() setInteger:counter+1 forKey:[NSString stringWithFormat:@"ACCDraftSaveCounter%@", [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) currentLoginUserModel].userID]];
                            }
                            
                            [ACCToast() show:content onView:[UIApplication sharedApplication].delegate.window];
                            [ACCAccessibility() postAccessibilityNotification:UIAccessibilityScreenChangedNotification argument:content];
                            // 震动一下
                            [ACCTapticEngineManager notifySuccess];
                            [ACCTracker() trackEvent:@"save_draft_box_show" params:@{ @"enter_from" : @"video_shoot_page" }];
                            [[NSNotificationCenter defaultCenter] postNotificationName:kAWEStudioDraftRecordSavedModififedVideo object:nil];
                            // 这里不能使用close方法，close会调用cancel方法，导致开方平台打开拍摄页存草稿时，无法弹出相关弹窗
                            [(UIViewController *)self.controller dismissViewControllerAnimated:YES completion:^{
                                if (ACCConfigBool(kConfigBool_enable_draft_save_landing_tab)) {
                                    [ACCDraftSaveLandingService() transferToUserProfileWithParam:@{@"landing_tab" : @"drafts"}];
                                }
                            }];

                        }else {
                            NSString *msg = @"保存失败";
                            if ([error.domain isEqual:NSCocoaErrorDomain] && error.code == NSFileWriteOutOfSpaceError) {
                                msg = ACCLocalizedString(@"disk_full", @"磁盘空间不足，请清理缓存后重试");
                            }
                            [ACCToast() show:msg];
                            [ACCAccessibility() postAccessibilityNotification:UIAccessibilityScreenChangedNotification argument:msg];
                            [ACCTapticEngineManager notifyFailure];
                            AWELogToolError2(@"draft", AWELogToolTagRecord, @"save draft model %@", error);
                            NSMutableDictionary *trackerInfo = [[self.repository.repoTrack referExtra] mutableCopy];
                            trackerInfo[@"enter_from"] = @"video_shoot_page";
                            [ACCTracker() trackEvent:@"save_draft_fail" params:trackerInfo];
                        }
                    });
                }];
            }];
        };
        
        action.eventBlock = ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
            [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) requireLogin:^(BOOL success) {
                if (success) {
                    saveDraftWithLogin();
                }
            }];
        };
    };
}

/// 发日常功能
- (ACCMultiStyleAlertConfigActionBlock)p_quickPublishActionConfig
{
    @weakify(self);
    return ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
        ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(action, ACCMultiStyleAlertPopoverActionProtocol, ^{
            action.image = ACCResourceImage(@"ic_actionlist_send");
        });
        action.title = [ACCStudioGlobalConfig() supportEditWithPublish] ? @"发布" : @"发日常";
        action.eventBlock = ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
            @strongify(self);
            [(UIViewController *)self.controller dismissViewControllerAnimated:YES completion:^{
                id<ACCEditServiceProtocol> editService = [ACCEditServiceUtils editServiceOnlyForPublishWithPublishModel:self.publishModel isMV:NO];
                [editService buildEditSession];
                [editService.preview resetPlayerWithViews:@[editService.mediaContainerView]]; // should remain
                BOOL shouldPreservePublishTitle = [[self publishModel].repoDuet isDuet];
                self.publishService = [ACCPublishServiceFactory() build];
                self.publishService.publishModel = self.publishModel;
                self.publishService.editService = editService;
                self.publishService.shouldPreservePublishTitle = shouldPreservePublishTitle;
                if ([ACCStudioGlobalConfig() supportEditWithPublish]) {
                    [self.publishService publishNormalVideo];
                } else {
                    [self.publishService publishQuickStory];
                }
                [ACCTracker() trackEvent:@"return_sheet_publish" params:[self p_commonBackAlertActionTrackInfo]];
            }];
        };
    };
}

/// 退出
- (ACCMultiStyleAlertConfigActionBlock)p_exitActionConfig
{
    @weakify(self);
    return ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
        @strongify(self);
        ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(action, ACCMultiStyleAlertPopoverActionProtocol, ^{
            action.image = ACCResourceImage(@"ic_actionlist_block_red");
        });
        action.title = self.exitTitle ?: @"退出相机";
        action.actionStyle = ACCMultiStyleAlertActionStyleHightlight;
        action.eventBlock = ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
            @strongify(self);
            [self saveTheOriginalDraft];
            [self clearAllEditBackUps];
            [self closeRecorder];
        };
    };
}

/// 重新拍摄
- (ACCMultiStyleAlertConfigActionBlock)p_reshootActionConfig
{
    @weakify(self);
    return ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
        @strongify(self);
        ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(action, ACCMultiStyleAlertPopoverActionProtocol, ^{
            action.image = ACCResourceImage(@"ic_actionlist_retry");
        });
        action.title = self.reshootTitle ?: @"重新拍摄";
        action.eventBlock = ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
            @strongify(self);
            [self.flowService deleteAllSegments];
            [ACCTracker() trackEvent:@"reshoot" params:[self p_commonBackAlertActionTrackInfo]];
        };
    };
}

/// cancel功能 
- (ACCMultiStyleAlertConfigActionBlock)p_cancelActionConfig
{
    @weakify(self);
    return ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
        action.title = @"取消";
        action.eventBlock = ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
            @strongify(self);
            [self.backAlert dismiss];
        };
    };
}

#pragma mark - Getter & Setter

- (ACCAnimatedButton *)closeButton
{
    if (!_closeButton) {
        _closeButton = [[ACCAnimatedButton alloc] initWithFrame:CGRectMake(6, 20, 44, 44)];
        _closeButton.accessibilityTraits = UIAccessibilityTraitButton;
        _closeButton.accessibilityLabel = @"关闭";
        [self.viewContainer.layoutManager addSubview:_closeButton viewType:ACCViewTypeClose];
    }
    return _closeButton;
}

- (ACCRecordCloseViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self getViewModel:ACCRecordCloseViewModel.class];
    }
    NSAssert(_viewModel, @"should not be nil");
    return _viewModel;
}

- (AWEVideoPublishViewModel *)publishModel
{
    return self.viewModel.inputData.publishModel;
}

- (ACCGroupedPredicate *)showButtonPredicte
{
    if (!_showButtonPredicte) {
        _showButtonPredicte = [[ACCGroupedPredicate alloc] init];
    }
    return _showButtonPredicte;
}

/// 挽留弹窗
- (NSObject<ACCMultiStyleAlertProtocol> *)backAlert
{
    if (!_backAlert) {
        Protocol *paramsProtocol = ACCMultiStyleAlertParamsProtocol(ACCConfigInt(kConfigInt_creative_edit_record_beg_for_stay_prompt_style));
        // 线上默认是Sheet
        if (!paramsProtocol) paramsProtocol = @protocol(ACCMultiStyleAlertSheetParamsProtocol);
        @weakify(self);
        _backAlert = [ACCMultiStyleAlert() initWithParamsProtocol:paramsProtocol configBlock:^(id<ACCMultiStyleAlertBaseParamsProtocol>  _Nonnull params) {
            @strongify(self);
            // 每次显示需实时更新数据
            params.reconfigBeforeShow = YES;
            ACCBLOCK_INVOKE(self.backAlertConfig, params);
        }];
    }
    return _backAlert;
}

@end
