//
//  MVPRecordCloseComponent.m
//  CameraClient
//
//  Created by Howie He on 2021/6/6.
//  Copyright © 2021 chengfei xiao. All rights reserved.
//

#import "MVPRecordCloseComponent.h"

#import <CameraClient/ACCEditServiceImpls.h>
#import <CameraClient/ACCEditSessionBuilderImpls.h>
#import <CameraClient/ACCFriendsServiceProtocol.h>
#import <CameraClient/ACCPublishNetServiceProtocol.h>
#import <CameraClient/ACCPublishServiceFactoryProtocol.h>
#import <CameraClient/ACCRecordFlowService.h>
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CameraClient/AWERepoContextModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import <CreationKitArch/ACCRepoGameModel.h>
#import <CameraClient/ACCRepoQuickStoryModel.h>
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CameraClient/ACCRepoUserIncentiveModelProtocol.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CameraClient/ACCSubtitleActionSheetProtocol.h>
#import <CameraClient/ACCVideoPublishProtocol.h>
#import <CameraClient/AWERepoDraftModel.h>
#import <CameraClient/AWERepoPropModel.h>
#import <CameraClient/AWERepoTrackModel.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CameraClient/ACCDraftProtocol.h>
#import <CameraClient/AWEVideoFragmentInfo.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>
#import <CreationKitArch/ACCEditAndPublishConstants.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCMemoryTrackProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitInfra/ACCRACWrapper.h>

#import <CameraClient/ACCRecordSwitchModeComponent.h>
#import <CameraClient/ACCCaptureComponent.h>
#import <CreationKitComponents/ACCFilterComponent.h>
#import <CameraClient/ACCRecordDeleteComponent.h>
#import <CameraClient/ACCRecordCompleteComponent.h>
#import <CreationKitComponents/ACCBeautyFeatureComponent.h>
#import <CreationKitComponents/ACCBeautyTrackSenderProtocol.h>
#import <CreationKitComponents/ACCFilterTrackSenderProtocol.h>
#import <CameraClient/ACCRecordDeleteTrackSenderProtocol.h>
#import <CameraClient/ACCRecordCompleteTrackSenderProtocol.h>

#import "LarkVideoDirector/LarkVideoDirector-Swift.h"

#define kQuickPublishActionSheetReshootIndex 0
#define kQuickPublishActionSheetExitCameraIndex 1
#define kQuickPublishActionSheetPublishIndex 2

@interface MVPRecordCloseComponent () <ACCSubtitleActionSheetDelegate, ACCRecorderViewContainerItemsHideShowObserver>

@property (nonatomic, strong) NSObject<ACCSubtitleActionSheetProtocol> *backActionSheetWithSubtitle;
@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) ACCAnimatedButton *closeButton;
@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCPublishServiceProtocol> publishService;
@property (nonatomic, strong, readwrite) AWEResourceUploadParametersResponseModel *uploadParamsCache;

@end

@implementation MVPRecordCloseComponent

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
                if (!self.viewContainer.isShowingPanel) {
                    [self.closeButton acc_fadeShow];
                }
                break;
            case ACCCameraRecorderStateRecording:
                [self.closeButton acc_fadeHidden];
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
    if (self.switchModeService.currentRecordMode.modeId == ACCRecordModeStory) {
        [self removeAllSegments];
    }
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
    if (animated) {
        if (!show) {
            [self.closeButton acc_fadeHidden];
        } else {
            [self.closeButton acc_fadeShow];
        }
    } else {
        self.closeButton.hidden = !show;
    }
}

#pragma mark - ACCSubtitleActionSheet

- (NSObject<ACCSubtitleActionSheetProtocol> *)backActionSheetWithSubtitle
{
    if (!_backActionSheetWithSubtitle) {
        _backActionSheetWithSubtitle = ACCSubtitleActionSheet();
        _backActionSheetWithSubtitle.delegate = self;
    }
    return _backActionSheetWithSubtitle;
}

- (NSString *)titleForSubtitleActionSheet:(id<ACCSubtitleActionSheetProtocol>)actionSheet
{
    id<ACCRepoUserIncentiveModelProtocol> userIncentiveModel = [self.repository extensionModelOfProtocol:@protocol(ACCRepoUserIncentiveModelProtocol)];
    if (ACC_isEmptyString([userIncentiveModel motivationTaskID])) {
        return nil;
    }
    NSString *target = [userIncentiveModel motivationTaskTargetText];
    NSString *reward = [userIncentiveModel motivationTaskReward];
    if (ACC_isEmptyString(target)) {
        target = @"任务";
    }
    if (ACC_isEmptyString(reward)) {
        reward = @"奖励";
    }
    NSString *title = [NSString stringWithFormat:@"继续%@，即得%@", target, reward];
    return title;
}

- (NSArray<NSString *> *)buttonTextsForSubtitleActionSheet:(id<ACCSubtitleActionSheetProtocol>)actionSheet
{
    NSMutableArray *buttonTexts = [[NSMutableArray alloc] initWithCapacity:10];
    [buttonTexts addObject:self.reshootTitle ?: @"重新拍摄"];
    [buttonTexts addObject:self.exitTitle ?: @"退出相机"];
    if (![self shouldHidePublishStoryButton]) {
        [buttonTexts addObject:@"发日常 · 1 天可见"];
    }
    return buttonTexts;
}

- (NSArray<NSNumber *> *)buttonTypesForSubtitleActionSheet:(id<ACCSubtitleActionSheetProtocol>)actionSheet
{
    NSMutableArray *buttonTypes = [[NSMutableArray alloc] initWithCapacity:10];
    [buttonTypes addObject:[NSNumber numberWithInt:AWESubtitleActionSheetButtonHighlight]];
    [buttonTypes addObject:[NSNumber numberWithInt:AWESubtitleActionSheetButtonNormal]];
    if (![self shouldHidePublishStoryButton]) {
        [buttonTypes addObject:[NSNumber numberWithInt:AWESubtitleActionSheetButtonNormal]];
    }
    return buttonTypes;
}

- (void)subtitleActionSheet:(id<ACCSubtitleActionSheetProtocol>)actionSheet didClickedButtonAtIndex:(NSInteger)index
{
    NSMutableDictionary *params = self.publishModel.repoTrack.referExtra.mutableCopy;
    params[@"tab_name"] = self.publishModel.repoTrack.tabName;
    params[@"enter_from"] = @"video_shoot_page";
    
    if (index == kQuickPublishActionSheetPublishIndex) {
        @weakify(self);
        [(UIViewController *)self.controller dismissViewControllerAnimated:YES completion:^{
            @strongify(self);
            id<ACCEditServiceProtocol> editService = [[ACCEditServiceImpls alloc] init];
            ACCEditSessionBuilderImpls *builder = [[ACCEditSessionBuilderImpls alloc] initWithPublishModel:self.publishModel isMV:NO];
            editService.editBuilder = builder;
            [editService buildEditSession];
            [editService.preview resetPlayerWithViews:@[editService.mediaContainerView]]; // should remain
            BOOL shouldPreservePublishTitle = [[self publishModel].repoDuet isDuet];
            self.publishService = [ACCPublishServiceFactory() build];
            self.publishService.publishModel = self.publishModel;
            self.publishService.editService = editService;
            self.publishService.shouldPreservePublishTitle = shouldPreservePublishTitle;
            [self.publishService publishQuickStory];
            [ACCTracker() trackEvent:@"return_sheet_publish" params:params];
        }];
    } else if (index == kQuickPublishActionSheetReshootIndex) {
        [self.flowService deleteAllSegments];
        [ACCTracker() trackEvent:@"reshoot" params:params];
    } else if (index == kQuickPublishActionSheetExitCameraIndex) {
        [self saveTheOriginalDraft];
        [self clearAllEditBackUps];
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
    if ([self.repository.repoTrack.referString isEqualToString:@"diary_shoot"] || [self.repository.repoTrack.referString isEqualToString:@"slide_shoot"]) {
        NSString *enterFrom = @"homepage_familiar";
        NSInteger closeShootIntervalms = [IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) enterQuickRecordInFamiliarDateDiff] * 1000;
        [ACCTracker() trackEvent:@"close_video_shoot_page" params:@{
                                                                    @"enter_method" : sender ? @"click_button" : @"slide_down",
                                                                    @"shoot_way" : self.repository.repoTrack.referString ?: @"",
                                                                    @"enter_from" : enterFrom ?: @"",
                                                                    @"close_shoot_interval_ms" : @(closeShootIntervalms),
                                                                    @"prop_panel_open" : @"0",
                                                                    @"publish_cnt" : @([ACCVideoPublish() publishTaskCount])
                                                                    }
         ];
    } else if ([self.repository.repoTrack.referString isEqualToString:@"profile_visitor_list_shoot"]) {
        [ACCTracker() trackEvent:@"close_video_shoot_page" params:@{
                                                                    @"shoot_way" : self.repository.repoTrack.referString ?: @"",
        }];
    } else {
        [ACCTracker() trackEvent:@"close_video_shoot_page" params:@{
            @"enter_method" : sender ? @"click_button" : @"slide_down",
            @"publish_cnt" : @([ACCVideoPublish() publishTaskCount]),
            @"prop_panel_open" : @"0",
        }];
    }
//    if ([self showSubtitleActionSheetIfNeeded]) {
//        return;
//    }
    if ([self.cameraService.recorder fragmentCount] > 0 || self.repository.repoDraft.isDraft) {
        [self showCancelShootAlertBtn:sender];
        [LVDCameraMonitor customTrack:@"public_photograph_click" params:@{
            @"click": @"close",
            @"target": @"public_photograph_close_confirm_view"
        }];
    } else {
        [LVDCameraMonitor customTrack:@"public_photograph_click" params:@{
            @"click": @"close",
            @"target": @"im_chat_main_view"
        }];
        [ACCDraft() deleteDraftWithID:self.repository.repoDraft.taskID];
        [self.controller close];
    }
    if (ACCConfigBool(kConfigBool_enable_story_tab_in_recorder) && ACCConfigBool(kConfigBool_enable_remember_last_tab)) {
        [ACCCache() setInteger:self.repository.repoFlowControl.videoRecordButtonType forKey:@"last_record_button_type"];
    }
    if ([self.repository.repoTrack musicLandingMultiLengthInitially]) {
        [ACCCache() setInteger:self.repository.repoFlowControl.videoRecordButtonType forKey:@"last_record_button_type_for_music"];
    }
}

- (BOOL)showSubtitleActionSheetIfNeeded
{
    if ([self.cameraService.recorder fragmentCount] > 0 && ![self.publishModel.repoQuickStory shouldDisableQuickPublishActionSheet] && ![self.repository.repoProp isMultiSegPropApplied]) {
        NSArray<AWEVideoFragmentInfo *> *fragmentInfos = [self.publishModel.repoVideoInfo.fragmentInfo copy];
        for (AWEVideoFragmentInfo *object in fragmentInfos) {
            if ([object hasRedpacketSticker]) {
                return NO;
            }
        }
        [self.backActionSheetWithSubtitle show];
        NSMutableDictionary *params = self.repository.repoTrack.referExtra.mutableCopy;
        params[@"tab_name"] = self.repository.repoTrack.tabName;
        params[@"enter_from"] = @"video_shoot_page";
        params[@"with_daily_button"] = [self shouldHidePublishStoryButton] ? @"0" : @"1";
        [ACCTracker() trackEvent:@"return_sheet_show" params:params];
        return YES;
    }
    return NO;
}

- (BOOL)shouldHidePublishStoryButton
{
    return ![self.flowService allowComplete] || self.repository.repoContext.videoType == AWEVideoTypeKaraoke;
}

- (void)clearAllEditBackUps
{
    if (!self.repository.repoReshoot.isReshoot) {
        [ACCDraft() clearAllEditBackUps];
    }
}

- (void)showCancelShootAlertBtn:(id)sender
{
    [self.flowService pauseRecord];
    NSDictionary *extra = self.repository.repoTrack.referExtra;
    
    if (self.repository.repoDraft.originalDraft == nil) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

        NSString *reshootTitle = self.reshootTitle ?: ACCLocalizedString(@"av_clear_recording_segments",@"重新拍摄");
        NSString *exitTitle = self.exitTitle ?: ACCLocalizedString(@"av_exit_recording", @"退出");
        NSString *cancelTitle = ACCLocalizedCurrentString(@"cancel");

        @weakify(self);
        [alertController addAction:[UIAlertAction actionWithTitle:exitTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            [self saveTheOriginalDraft];
            [self clearAllEditBackUps];
            [self.controller close];
            
            NSDictionary *data = @{@"service"   : @"record_error",
                                   @"action"    : @"cancel_shoot_confirm",
                                   @"task"      : self.repository.repoDraft.taskID?:@"",};
            [ACCMonitor() trackData:data logTypeStr:@"aweme_movie_publish_log"];

            [LVDCameraMonitor customTrack:@"public_photograph_close_confirm_click" params:@{@"click": @"quit"}];
        }]];

        [alertController addAction:[UIAlertAction actionWithTitle:reshootTitle  style:UIAlertActionStyleDefault  handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            [ACCTracker() trackEvent:@"reshoot" params:extra needStagingFlag:NO];
            [self.flowService deleteAllSegments];

            [LVDCameraMonitor customTrack:@"public_photograph_close_confirm_click" params:@{@"click": @"remake"}];
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [ACCTracker() trackEvent:@"cancel_shoot_fail"
                                              label:@"shoot_page"
                                              value:nil
                                              extra:nil
                                         attributes:extra];
            [LVDCameraMonitor customTrack:@"public_photograph_close_confirm_click" params:@{@"click": @"cancel"}];
        }]];

        [LVDCameraMonitor customTrack:@"public_photograph_close_confirm_view" params:@{}];

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [ACCAlert() showAlertController:alertController fromView:sender];
        } else {
            [ACCAlert() showAlertController:alertController animated:YES];
        }
        return;
    }
    
    @weakify(self);
    NSString *title = ACCLocalizedCurrentString(@"com_mig_quit_recording");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedCurrentString(@"com_mig_confirm_mtsudt") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        [ACCTracker() trackEvent:@"cancel_shoot_confirm"
                                          label:@"shoot_page"
                                          value:nil
                                          extra:nil
                                     attributes:extra];
        
        [self saveTheOriginalDraft];
        [self clearAllEditBackUps];
        [self.controller close];
//        [self.viewModel manullyClickCloseButtonSuccessfullyClose];
        
        NSDictionary *data = @{@"service"   : @"record_error",
                               @"action"    : @"cancel_shoot_confirm",
                               @"task"      : self.repository.repoDraft.taskID?:@"",};
        [ACCMonitor() trackData:data logTypeStr:@"aweme_movie_publish_log"];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedCurrentString(@"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [ACCTracker() trackEvent:@"cancel_shoot_fail"
                                          label:@"shoot_page"
                                          value:nil
                                          extra:nil
                                     attributes:extra];
    }]];
    [ACCAlert() showAlertController:alertController animated:YES];
}

- (void)saveTheOriginalDraft
{
    AWEVideoPublishViewModel *originalModel = self.repository.repoDraft.originalModel;
    id<ACCDraftModelProtocol> originalDraft = self.repository.repoDraft.originalDraft;
    
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

- (AWEVideoPublishViewModel *)publishModel
{
    return self.repository;
}

@end

@implementation LarkRecordSwitchModePlugin

@synthesize component = _component;

+ (id)hostIdentifier
{
  return [ACCRecordSwitchModeComponent class]; //用来说明自己是谁的component
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider {
    let webViewObj = IESAutoInline(serviceProvider, ACCRecordSwitchModeService);
    [webViewObj addSubscriber: self];
}

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode {
    if (mode.modeId == oldMode.modeId) {
        return;
    }
    [LVDCameraMonitor customTrack:@"public_photograph_click" params:@{@"click": mode.isPhoto ? @"photo_tab" : @"video_tab"}];
    [LVDCameraMonitor setTabWithPhoto:mode.isPhoto];
    [LVDCameraMonitor customTrack:@"public_photograph_view" params:@{}];
}

@end

@implementation LarkCameraServicePlugin

@synthesize component = _component;

+ (id)hostIdentifier
{
  return [ACCCaptureComponent class]; //用来说明自己是谁的component
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider {
    let webViewObj2 = IESAutoInline(serviceProvider, ACCCameraService);
    [webViewObj2.cameraControl addSubscriber: self];

    [webViewObj2.recorder addSubscriber: self];
}

- (void)onDidManuallyAdjustFocusAndExposurePoint:(CGPoint)point {
    [LVDCameraMonitor customTrack:@"public_photograph_click" params:@{@"click": @"manual_focus"}];
}

- (void)onDidManuallyAdjustExposureBiasWithRatio:(float)ratio {
    if (ratio == 0) {
        return;
    }
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (self.lastExposureDate + 5 > now) {
        return;
    }
    [LVDCameraMonitor customTrack:@"public_photograph_click" params:@{@"click": @"exposure"}];
    self.lastExposureDate = now;
}

- (void)onCaptureStillImageWithImage:(UIImage *)image error:(NSError *)error {
    [LVDCameraMonitor customTrack:@"public_photograph_click" params:@{
        @"click": @"photograph",
        @"target": @"public_pic_edit_view"
    }];
}

- (void)onWillStartVideoRecordWithRate:(CGFloat)rate {
    [LVDCameraMonitor customTrack:@"public_photograph_click" params:@{
        @"click": @"photograph",
        @"target": @"public_photograph_view"
    }];
}

- (void)onWillPauseVideoRecordWithData:(HTSVideoData *)data {
    [LVDCameraMonitor customTrack:@"public_photograph_click" params:@{@"click": @"pause"}];
}

@end

@implementation LarkRecordDeletePlugin

@synthesize component = _component;

+ (id)hostIdentifier
{
  return [ACCRecordDeleteComponent class]; //用来说明自己是谁的component
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider {
    id<ACCRecordDeleteTrackSenderProtocol> trackSender = [serviceProvider resolveObject:@protocol(ACCRecordDeleteTrackSenderProtocol)];
    [trackSender.deleteConfirmAlertShowSignal subscribeNext:^(id  _Nullable x) {
        [LVDCameraMonitor customTrack:@"public_photograph_delete_confirm_view" params:@{}];
        [LVDCameraMonitor customTrack:@"public_photograph_click" params:@{
            @"click": @"delete",
            @"target": @"public_photograph_delete_confirm_view"
        }];
    }];

    [trackSender.deleteConfirmAlertActionSignal subscribeNext:^(NSNumber*  _Nullable x) {
        [LVDCameraMonitor customTrack:@"public_photograph_delete_confirm_click" params:@{@"click": [x isEqualToNumber:@0] ? @"retain" : @"delete"}];
    }];
}

@end

@implementation LarkRecordCompletePlugin

@synthesize component = _component;

+ (id)hostIdentifier
{
  return [ACCRecordCompleteComponent class]; //用来说明自己是谁的component
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider {
    id<ACCRecordCompleteTrackSenderProtocol> trackSender = [serviceProvider resolveObject:@protocol(ACCRecordCompleteTrackSenderProtocol)];
    [trackSender.completeButtonDidClickedSignal subscribeNext:^(id  _Nullable x) {
        [LVDCameraMonitor customTrack:@"public_photograph_click" params:@{
            @"click": @"done",
            @"target": @"public_video_edit_view"
        }];
    }];
}

@end

@implementation LarkFilterPlugin

@synthesize component = _component;

+ (id)hostIdentifier
{
  return [ACCFilterComponent class]; //用来说明自己是谁的component
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider {
    id<ACCFilterTrackSenderProtocol> trackSender = [serviceProvider resolveObject:@protocol(ACCFilterTrackSenderProtocol)];
    [trackSender.filterViewDidClickFilterSignal subscribeNext:^(IESEffectModel * _Nullable x) {
        [LVDCameraMonitor customTrack:@"public_photograph_filter_edit_click" params:@{@"click": x == NULL ? @"close" : @"open_filter"}];
    }];
}

@end

@implementation LarkBeautyFeaturePlugin

@synthesize component = _component;

+ (id)hostIdentifier
{
  return [ACCBeautyFeatureComponent class]; //用来说明自己是谁的component
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider {
    id<ACCBeautyTrackSenderProtocol> trackSender = [serviceProvider resolveObject:@protocol(ACCBeautyTrackSenderProtocol)];
    @weakify(self);
    [trackSender.composerBeautyViewControllerDidSwitchSignal subscribeNext:^(RACTwoTuple<NSNumber *,NSNumber *> * _Nullable x) {
        @strongify(self);
        if ([x.second isEqualToNumber: [[NSNumber alloc] initWithBool:NO]]) {
            return;
        }
        [LVDCameraMonitor customTrack:@"public_photograph_beauty_edit_click" params:@{
            @"click": @"switch_beauty",
            @"status": [x.first isEqualToNumber: [[NSNumber alloc] initWithBool:YES]] ? @"open" : @"close"
        }];
    }];
}

@end
