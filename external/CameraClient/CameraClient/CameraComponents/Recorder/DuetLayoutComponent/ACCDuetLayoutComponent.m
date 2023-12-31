//
//  ACCDuetLayoutComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by 李辉 on 2020/2/14.
//

#import "ACCDuetLayoutComponent.h"
#import <CreationKitArch/ACCRecorderToolBarDefines.h>
#import "ACCDuetLayoutViewController.h"
#import "ACCDuetLayoutManager.h"
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import "ACCDuetLayoutGuideView.h"
#import <CreativeKit/ACCRecorderViewContainer.h>
#import "AWERecorderTipsAndBubbleManager.h"
#import "ACCConfigKeyDefines.h"
#import "ACCDuetLayoutViewModel.h"
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import "ACCRecordFlowService.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UILabel+ACCAdditions.h>
#import <CreationKitArch/AWECameraContainerToolButtonWrapView.h>
#import <CreationKitArch/IESEffectModel+ACCSticker.h>
#import "AWEDuetCalculateUtil.h"
#import "ACCRecordConfigService.h"
#import "ACCRecordPropService.h"
#import "ACCRecordFlowService.h"
#import "AWERepoDuetModel.h"
#import "ACCPropViewModel.h"
#import "AWEVideoFragmentInfo.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <YYWebImage/UIImage+YYWebImage.h>
#import "ACCRecorderEvent.h"
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoGameModel.h>
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import "AWEDuetCalculateUtil.h"
#import "ACCBarItem+Adapter.h"
#import "ACCToolBarContainerAdapter.h"
#import "ACCToolBarAdapterUtils.h"

typedef NS_ENUM(NSInteger, IESMMEffectMsgDuet) {
    IESMMEffectMsgDuetFigureAppearThreshold = 0x3D,
    IESMMEffectMsgDuetFigureAppearDuration = 0x3C,
    IESMMEffectMsgDuetLayoutChange = 0x5002
};

static const NSInteger kEffectRemoveLastSegmentMsgId = 27560;
static const NSInteger kEffectRemoveAllSegmentsMsgId = 27561;

@interface ACCDuetLayoutComponent () <ACCDuetLayoutViewControllerDelegate, ACCEffectEvent, ACCRecordConfigAudioHandler, ACCRecordConfigDurationHandler, ACCRecordFlowServiceSubscriber, ACCRecordPropServiceSubscriber, ACCCameraLifeCircleEvent, ACCRecorderEvent>

@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCRecordPropService> propService;

@property (nonatomic, strong) id multiplayerObserver;
@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;

@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, assign) BOOL hasShowDuetLayoutButtonTips;
@property (nonatomic, assign) BOOL onCreateCameraCompleted;

@property (nonatomic, weak) ACCDuetLayoutGuideView *layoutGuideView;
@property (nonatomic, strong) ACCDuetLayoutViewController *duetLayoutViewController;
@property (nonatomic, strong) ACCDuetLayoutViewModel *viewModel;

// @property (nonatomic, strong) AWEReactMicrophoneButton *reactMicButton;                 // 麦克风按钮
// @property (nonatomic, strong) UILabel *reactMicButtonLabel;                             // 麦克风按钮文字

@end

@implementation ACCDuetLayoutComponent


IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, propService, ACCRecordPropService)

#pragma mark -

- (ACCServiceBinding *)serviceBinding {
    return ACCCreateServiceBinding(@protocol(ACCDuetLayoutService),
                                   self.viewModel);
}

- (void)loadComponentView
{
    [self buildDuetViewsIfNeeded];
    [self.viewContainer.barItemContainer addBarItem:[self barItem]];
}

- (void)componentDidMount
{
    self.isFirstAppear = YES;
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [self p_bindViewModel];
}

- (void)componentWillAppear
{
    if (self.onCreateCameraCompleted && ACCConfigBool(kConfigBool_karaoke_ios_duet_ear_back) && self.repository.repoDuet.isDuetSing) {
        [self configKaraokeDuetEarBack];
    }
}

- (void)componentDidAppear
{
    if ([self isDuet]) {
        if (self.isFirstAppear) {
            [self prepareDuet];
        }
    }
    self.isFirstAppear = NO;
    [self showDuetLayoutBubbleIfNeeded];
    [self.viewModel updateFigureAppearanceDurationInMS];
}

- (void)componentDidDisappear
{
    if ([self isDuet]) {
        if (self.cameraService.cameraHasInit) {
            [self.cameraService.recorder multiVideoPause];
        }
    }
}

- (void)componentDidUnmount
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    if ([self isDuet]) {
        [self.cameraService.recorder multiVideoPause];
    }
}

- (void)cameraService:(id<ACCCameraService>)cameraService didReachMaxTimeVideoRecordWithError:(NSError *)error
{
    if (error) {
        AWELogToolError(AWELogToolTagRecord, @"Duet didReachMaxTimeVideoRecord error: %@", error);
    }
    if ([self isDuet]) {
        [self.cameraService.recorder bgVideoPause];
    }
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

#pragma mark - Private

- (ACCBarItem *)barItem {
    let config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCRecorderToolBarDuetLayoutContext];
    if (config) {
        ACCBarItem *bar = [[ACCBarItem alloc] init];
        bar.title = ACCLocalizedString(@"duet_layout_entrance", @"Layout");
        bar.imageName = @"duet_layout_left_right";
        bar.itemId = ACCRecorderToolBarDuetLayoutContext;
        bar.type = ACCBarItemFunctionTypeCover;
        @weakify(self);
        bar.barItemActionBlock = ^(UIView * _Nonnull itemView) {
            @strongify(self);
            [self handleClickDuetLayoutAction];
        };
        bar.needShowBlock = ^BOOL{
            @strongify(self);
            return [self isDuet] && ![self.cameraService.recorder isRecording];
        };
        bar.showBubbleBlock = ^{
            @strongify(self);
            UIView *targetView = (UIView *)[self.viewContainer.barItemContainer viewWithBarItemID:ACCRecorderToolBarDuetLayoutContext];
            NSString *tipTitle = [NSString stringWithFormat:@"试试切换%@布局", self.repository.repoDuet.duetIdentifierText];
            [[AWERecorderTipsAndBubbleManager shareInstance] showDuetLayoutBubbleIfNeededForView:targetView text:tipTitle containerView:self.viewContainer.interactionView];
        };
        [self p_forceInsert];
        return bar;
    } else {
        return nil;
    }
}

- (void)p_forceInsert
{
    if ([ACCToolBarAdapterUtils useAdaptedToolBarContainer] && [self isDuet]) {
        NSArray *array = @[[NSValue valueWithPointer:ACCRecorderToolBarDuetLayoutContext],
                           [NSValue valueWithPointer:ACCRecorderToolBarMicrophoneContext],
                           ];
        ACCToolBarContainerAdapter *adapter = (ACCToolBarContainerAdapter *)self.viewContainer.barItemContainer;
        [adapter forceInsertWithBarItemIdsArray:array];
    }
}

- (void)p_bindViewModel
{
    @weakify(self);
    [self.viewModel.successDownFirstLayoutResourceSignal subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        if ([self isDraftOrBackup] || [self.viewModel isDuetLandscapeVideoAndNeedOptimizeLayout]) {
            self.duetLayoutViewController.firstTimeSelectedIndex = self.viewModel.firstTimeIndex;
            [self.duetLayoutViewController forceSelectFirstLayoutIfNeeded];
        }
    }];
    
    [self.viewModel.refreshDuetLayoutsSignal subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if ([x boolValue]) {
            [self.duetLayoutViewController reloadData];
        } else {
            [self.duetLayoutViewController showNetErrorView];
        }
    }];
    
    [self.viewModel.duetIconImageReadySignal subscribeNext:^(ACCDuetIconImagePack  _Nullable x) {
        @strongify(self);
        RACTupleUnpack(UIImage *image, NSNumber *index)  = x;
        if (index.integerValue == self.duetLayoutViewController.currentSelectedIndex) {
            [self.viewModel sendUpdateIconSignal:image];
        }
    }];
    [RACObserve(self.flowService, flowState).deliverOnMainThread subscribeNext:^(NSNumber *  _Nullable x) {
        @strongify(self);
        ACCRecordFlowState state = x.integerValue;
        if (ACCRecordFlowStateStart == state) {
            if ([self isDuet]) {
                [self.cameraService.recorder multiVideoPlay];
            }
            [self addDuetLayoutCameraKVOIfNeeded];
        } else if (ACCRecordFlowStatePause == state) {
            if ([self isDuet]) {
                [self.cameraService.recorder multiVideoPause];
            }
        } else if (ACCRecordFlowStateStop == state) {
            if ([self isDuet]) {
                [self.cameraService.recorder multiVideoPause];
            }
        }
    }];

    [self.viewModel.updateIconSignal.deliverOnMainThread subscribeNext:^(UIImage * _Nullable x) {
        @strongify(self);
        UIImage *resizeImage = [x yy_imageByResizeToSize:CGSizeMake(32, 32) contentMode:UIViewContentModeScaleToFill];
        [self.duetLayoutButton setImage:resizeImage forState:UIControlStateNormal];
    }];

    // Skip 1 for initialization
    [[self.viewModel.duetLayoutDidChangedSignal.deliverOnMainThread skip:1] subscribeNext:^(ACCDuetLayoutModelPack  _Nullable x) {
        @strongify(self);
        [self showHintWithEffect:x.first.effect];
    }];

    [self.viewModel.shouldSwapCameraPositionSignal.deliverOnMainThread subscribeNext:^(ACCDuetLayoutModel * _Nullable layout) {
        @strongify(self);
        [self handleCameraWithDuetLayoutModel:layout.effect];
    }];
}

- (UIButton *)duetLayoutButton
{
    return [self.viewContainer.barItemContainer viewWithBarItemID:ACCRecorderToolBarDuetLayoutContext].barItemButton;
}

- (void)updateDuetItemWithDuration:(CGFloat)currentDuration
{
    if (currentDuration > 0) {
        if ([self isDuet]) {
            self.duetLayoutButton.enabled = NO;
        }
    } else {
        if ([self isDuet]) {
            self.duetLayoutButton.enabled = YES;
        }
    }
}

- (void)addDuetLayoutCameraKVOIfNeeded
{
    CGFloat lastCapturedDuration = [self flowService].lastCapturedVideoDuration;
    double speed = [self flowService].selectedSpeed;
    CMTime targetTime = CMTimeMultiplyByFloat64(CMTimeMakeWithSeconds(lastCapturedDuration, 10000), speed);
    if ([self isDuet]) {
        AVPlayer *player = [self.cameraService.recorder getMultiPlayer];
        @weakify(self);
        @weakify(player);
        self.multiplayerObserver = [player addPeriodicTimeObserverForInterval:CMTimeMake(1, 60) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            @strongify(self);
            @strongify(player);
            if (CMTimeGetSeconds(targetTime) < CMTimeGetSeconds(time)) {
                [self.cameraService.recorder multiVideoIsReady];
                [player removeTimeObserver:self.multiplayerObserver];
                self.multiplayerObserver = nil;
            }
        }];
    }
}

- (void)buildDuetViewsIfNeeded
{
    if (![self isDuet]) {
        return;
    }
    [self configPublishModelMaxDurationWithLocalURL:self.repository.repoDuet.duetLocalSourceURL];
    if (!self.isFirstAppear) { // 首次安装弹权限窗口时，ViewDidAppear已发生，但是Camera以及preview尚未创建，需要在创建preview时再执行相关初始化配置
        [self prepareDuet];
    }
}

- (void)configPublishModelMaxDurationWithLocalURL:(NSURL *)localUrl
{
    AVAsset *sourceAsset = [AVURLAsset URLAssetWithURL:localUrl options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
    AVAssetTrack *videoTrack = [sourceAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    NSParameterAssert(videoTrack && !CGSizeEqualToSize(videoTrack.naturalSize, CGSizeZero));
    //see also configPublishModelMaxDuration
    double maxDuration = CMTimeGetSeconds(videoTrack.timeRange.duration);
    // 根据用户当前最大拍摄时长做限制
    let configService = IESAutoInline(self.serviceProvider, ACCRecordConfigService);
    Float64 durationLimit = [configService videoMaxDuration];
    if (maxDuration >= durationLimit) {
        self.repository.repoContext.maxDuration = durationLimit;
    } else {
        self.repository.repoContext.maxDuration = maxDuration;
    }

    AWELogToolInfo(AWELogToolTagRecord, @"%@", [NSString stringWithFormat:@"Record duet source asset video size: %@, video duration: %f", NSStringFromCGSize(videoTrack.naturalSize), maxDuration]);
}

- (void)prepareDuet
{
    if (self.flowService.lastCapturedVideoDuration > 0) { //restore duet video player play time
        CMTime targetTime = CMTimeMultiplyByFloat64(CMTimeMakeWithSeconds(self.flowService.lastCapturedVideoDuration, 10000), self.flowService.selectedSpeed);
        [self.cameraService.recorder multiVideoSeekToTime:targetTime completeBlock:^(BOOL finished) {
        }];
    }
}

- (void)configKaraokeDuetEarBack
{
    [self.cameraService.cameraControl releaseAudioCapture];
    [self.cameraService.karaoke setRecorderAudioMode:VERecorderAudioModeKaraoke];
    [self.cameraService.cameraControl initAudioCapture:^{}];
    [self.viewModel startDuetIfNecessary];
}

#pragma mark - action

- (void)showDuetLayoutBubbleIfNeeded
{
    if (self.repository.repoGame.gameType != ACCGameTypeNone) {
        return; // ignore bubble when gaming...
    }
    if ([self isDuet]) {
        //从草稿、备份、或者当前从编辑页返回到当前页（已经展示过了），都不再展示tips
        if ([self isDraftOrBackup] || (!self.duetLayoutButton.enabled) || self.hasShowDuetLayoutButtonTips) {
            return;//草稿或者备份过来的均不展示toast提示
        }
        self.hasShowDuetLayoutButtonTips = YES;
        if (![ACCToolBarAdapterUtils useAdaptedToolBarContainer]) {
            NSString *tipTitle = [NSString stringWithFormat:@"试试切换%@布局", self.repository.repoDuet.duetIdentifierText];
            [[AWERecorderTipsAndBubbleManager shareInstance] showDuetLayoutBubbleIfNeededForView:self.duetLayoutButton text:tipTitle  containerView:self.viewContainer.interactionView];
        }
    }
}

- (void)showHintWithEffect:(IESEffectModel *)effect
{
    let manager = [AWERecorderTipsAndBubbleManager shareInstance];
    BOOL isDuetGreenScreenHintViewShowing = [ACCCache() boolForKey:kACCDuetGreenScreenHintViewShowKey];
    if (isDuetGreenScreenHintViewShowing) {
        [manager removePropHint];
        [ACCCache() setBool:NO forKey:kACCDuetGreenScreenHintViewShowKey];
    }

    BOOL isPropHintViewShowing = [manager isPropHintViewShowing] || self.propService.isStickerHintViewShowing;
    if (!isPropHintViewShowing) {
        [manager showPropHintWithPublishModel:self.viewModel.inputData.publishModel container:self.viewContainer.interactionView effect:effect];
    }
}

- (void)handleClickDuetLayoutAction
{
    [[AWERecorderTipsAndBubbleManager shareInstance] removeDuetLayoutBubble];
    if (self.cameraService.recorder.isRecording) {
        return;
    }
    self.viewContainer.isShowingPanel = YES;
    [self.viewContainer showItems:NO animated:YES];

    // AR类型道具禁止切换前后置镜头，禁用切换按钮
    IESEffectModel *currentProp = [self currentProp];
    BOOL enabled = ![currentProp isTypeAR];
    [self.duetLayoutViewController enableSwappedCameraButton:enabled];
    
    [self.duetLayoutViewController showOnView:self.viewContainer.interactionView];
    if (self.viewModel.duetManager.hasErrorWhenFetchingEffects) {
        [self.duetLayoutViewController showNetErrorView];
    } else {
        [self.duetLayoutViewController forceSelectFirstLayoutIfNeeded];
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[self duetCommonTrackDic]];
    params[@"content_type"] = @"video";
    NSDictionary *referExtra = self.repository.repoTrack.referExtra;
    params[@"content_source"] = referExtra[@"content_source"] ? : @"";
    if (referExtra) {
        [params addEntriesFromDictionary:referExtra];
    }
    [ACCTracker() trackEvent:@"click_layout_entrance" params:params needStagingFlag:NO];
}

- (NSDictionary *)duetCommonTrackDic
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"creation_id"] = self.repository.repoContext.createId ?: @"";
    params[@"shoot_way"] = @"duet";
    params[@"enter_from"] = @"video_shoot_page";
    if (self.repository.repoDraft.isDraft) {
        params[@"enter_method"] = @"click_draft";
    }
    return [params copy];
}

- (void)handleCameraWithDuetLayoutModel:(IESEffectModel *)duetLayoutModel
{
    [self.cameraService.cameraControl syncCameraActualPosition];
    if (duetLayoutModel.isDuetGreenScreen) {
        BOOL isDevicePositionBack = (self.cameraService.cameraControl.currentCameraPosition == AVCaptureDevicePositionBack);
        IESEffectModel *currentPropModel = [self currentProp];
        if ([currentPropModel isTypeAR] && !isDevicePositionBack) {
            [self.cameraService.cameraControl switchToOppositeCameraPosition];
        } else {
            if (duetLayoutModel.isTypeCameraFront && isDevicePositionBack) {
                [self.cameraService.cameraControl switchToOppositeCameraPosition];
            } else if(duetLayoutModel.isTypeCameraBack && !isDevicePositionBack) {
                [self.cameraService.cameraControl switchToOppositeCameraPosition];
            }
        }
    }
}

#pragma mark - ACCDuetLayoutViewControllerDelegate
- (NSArray *)duetLayoutModels
{
    return self.viewModel.duetLayoutModels;
}

- (void)duetLayoutController:(ACCDuetLayoutViewController *)controller didSelectDuetLayoutAtIndex:(NSInteger)index
{
    if (index < [self duetLayoutModels].count) {
        [self dismissDuetLayoutGideViewIFNeeded];
        [self.viewModel didSelectDuetLayoutAtIndex:index];
    }
}

- (void)duetLayoutController:(ACCDuetLayoutViewController *)controller didSwitchDuetLayoutAtIndex:(NSInteger)index
{
    [self.viewModel.duetManager toggleDuetLayoutWithIndex:index];
}

- (void)duetLayoutController:(ACCDuetLayoutViewController *)controller didTapOnRetryButton:(UIButton *)sender
{
    [self.viewModel retryDownloadDuetEffects];
}

- (void)duetLayoutController:(ACCDuetLayoutViewController *)controller didTapOnSwappedCameraButton:(UIButton *)button
{
    [self.cameraService.cameraControl switchToOppositeCameraPosition];
}

#pragma mark - ACCRecorderEvent

- (void)onFinishExportVideoDataWithData:(HTSVideoData *)data error:(NSError *)error
{
    if (error) {
        AWELogToolError(AWELogToolTagRecord, @"Duet onFinishExportVideoDataWithData error: %@", error);
    }
    if ([self isDuet]) {
        BOOL needAddAudio = YES;
        if (self.repository.repoDraft.isDraft) {
            //In this case needAddAudio = NO: we've already have duet audio from draft so just ignoring it this time.
            needAddAudio = data.audioAssets.count == 0;
        }
        if (self.repository.repoDuet.shouldShowDuetGreenScreenAlert) {
            NSString *key = self.repository.repoDuet.duetIdentifierText;
            NSString *description = [NSString stringWithFormat:@"在无缝%@中，若前景中无人出镜，会导致%@视频与原视频相似度较高，可能影响%@视频的浏览量", key, key, key];
            [ACCAlert() showAlertWithTitle:@"提示"
                               description:description
                                     image:nil
                         actionButtonTitle:@"好的"
                         cancelButtonTitle:nil
                               actionBlock:^{
                                    [self executeExportCompletionWithData:data needAddAudio:needAddAudio];
                            } cancelBlock:nil];

            // reset shouldShowDuetGreenScreenAlert
            self.repository.repoDuet.shouldShowDuetGreenScreenAlert = NO;
            [ACCCache() setBool:YES forKey:kACCDuetGreenScreenIsEverShot];
        } else {
            [self executeExportCompletionWithData:data needAddAudio:needAddAudio];
        }
    }
}

- (void)executeExportCompletionWithData:(HTSVideoData *)data needAddAudio:(BOOL)needAddAudio
{
    AVAsset *sourceAsset = [AVURLAsset URLAssetWithURL:self.repository.repoDuet.duetLocalSourceURL options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
    if (sourceAsset && needAddAudio) {
        [data addAudioWithAsset:sourceAsset];
    }
    NSArray *reportInfoArray = [AWEDuetCalculateUtil duetBoundsInfoArrayForPublishModelVideo:self.repository.repoVideoInfo.video];
    data.metaRecordInfo = reportInfoArray.count ? @{@"reaction_info" : reportInfoArray ?: @[]} : nil;
    [self.flowService executeExportCompletionWithVideoData:data error:nil];
}

#pragma mark - ACCCameraLifeCircleEvent

- (void)onCreateCameraCompleteWithCamera:(id<ACCCameraService>)cameraService
{
    self.onCreateCameraCompleted = YES;
    [self addKVOObserversIfNeeded];
    if (ACCConfigBool(kConfigBool_karaoke_ios_duet_ear_back) && self.repository.repoDuet.isDuetSing) {
        [self configKaraokeDuetEarBack];
    } else {
        [self.viewModel startDuetIfNecessary];
    }
}

#pragma mark - KVO

- (void)addKVOObserversIfNeeded
{
    if ([self isDuet]) {
        [self addKVOObserversForDuet];
    }
}

- (void)addKVOObserversForDuet
{
    @weakify(self);
    [self addKVOForSpeedControlSpeedWithBlock:^(double previousSpeed, double currentSpeed) {
        if (currentSpeed > 0 && previousSpeed > 0) {
            @strongify(self);
            [self.cameraService.recorder multiVideoChangeRate: 1 / currentSpeed completeBlock:^(NSError * _Nullable error) {
                if (error) {
                    AWELogToolError(AWELogToolTagRecord, @"Duet VE multiVideoChangeRate error: %@", error);
                    return;
                }
                @strongify(self);
                CMTime targetTime = CMTimeMultiplyByFloat64(CMTimeMakeWithSeconds(self.flowService.lastCapturedVideoDuration, 10000), currentSpeed);
                [self.cameraService.recorder multiVideoSeekToTime:targetTime completeBlock:^(BOOL finished) {
                    if (!finished) {//@VE RD @zhaomingwei said that it's possible to failed at some weird time, so we need to retry:(2020-3-9)
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            @strongify(self);
                            [self.cameraService.recorder multiVideoSeekToTime:targetTime completeBlock:nil];
                        });
                    }
                }];
            }];
        }
    }];
}

- (void)addKVOForSpeedControlSpeedWithBlock:(void (^)(double previousSpeed, double currentSpeed))block
{
    [[(NSObject *)self.flowService rac_valuesAndChangesForKeyPath:@"selectedSpeed" options:NSKeyValueObservingOptionOld observer:self] subscribeNext:^(RACTwoTuple<id,NSDictionary *> * _Nullable x) {
        NSNumber *previousSpeedNumber = [x.second acc_objectForKey:NSKeyValueChangeOldKey];
        NSNumber *currentSpeedNumber = x.first;
        if (block) {
            block(previousSpeedNumber.doubleValue, currentSpeedNumber.doubleValue);
        }
    }];
}

#pragma mark - ACCEffectEvent

- (void)onEffectMessageReceived:(IESMMEffectMessage *)message {
    if (message.msgId == IESMMEffectMsgDuetFigureAppearThreshold) {
        AWELogToolInfo(AWELogToolTagRecord, @"received IESMMEffectMessage: The duration of duet figure appearance reaches threshold");
        [self.viewModel handleMessageOfFigureAppearanceDurationReachesThreshold];

    } else if (message.msgId == IESMMEffectMsgDuetFigureAppearDuration) {
        NSInteger durationInMS = message.arg2;
        AWELogToolInfo(AWELogToolTagRecord, @"received IESMMEffectMessage: The duration of duet figure appearance is %ld ms", (long)durationInMS);
        self.viewModel.inputData.publishModel.repoVideoInfo.fragmentInfo.lastObject.figureAppearanceDurationInMS = durationInMS;
        [self.viewModel updateFigureAppearanceDurationInMS];

    } else if ([message.arg3 isEqualToString:@"guide_three_screen"]) {
        //新合拍的布局拖动引导只对于符合足够高度的视频才出现，因为“太矮”的视频是无法进行实际拖动的！
        //https://bytedance.feishu.cn/docs/doccnJD8QQbp6wY39BerpKb0uYf#
        NSInteger guideIndex = message.arg2;

        if (![self isDraftOrBackup]) {
            [self dismissDuetLayoutGideViewIFNeeded];
            self.layoutGuideView = [ACCDuetLayoutGuideView showDuetLayoutGuideViewIfNeededWithContainerView:(UIView *)self.cameraService.cameraPreviewView
                                                                                                 guideIndex:guideIndex];
        }
    } else if (message.msgId == IESMMEffectMsgDuetLayoutChange) { // 布局变化的消息通知
        NSString  *duetLayout = message.arg3;
        [self.viewModel handleMessageOfDuetLayoutChanged:duetLayout];
    }
}

- (void)dismissDuetLayoutGideViewIFNeeded
{
    if (self.layoutGuideView) {
        [self.layoutGuideView dismiss];
        self.layoutGuideView = nil;
    }
}

- (UILabel *)p_createButtonLabel:(NSString *)text
{
    UILabel *label = [[UILabel alloc] acc_initWithFont:[ACCFont() acc_boldSystemFontOfSize:10]
                                                 textColor:ACCResourceColor(ACCUIColorConstTextInverse)
                                                      text:text];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 2;
    [label acc_addShadowWithShadowColor:ACCResourceColor(ACCUIColorConstLinePrimary) shadowOffset:CGSizeMake(0, 1) shadowRadius:2];
    label.isAccessibilityElement = NO;
    return label;
}

#pragma mark - lazy loads

- (ACCDuetLayoutViewController *)duetLayoutViewController
{
    if (!_duetLayoutViewController) {
        _duetLayoutViewController = [[ACCDuetLayoutViewController alloc] init];
        @weakify(self);
        _duetLayoutViewController.dissmissBlock = ^{
            @strongify(self);
            self.viewContainer.isShowingPanel = NO;
            [self.viewContainer showItems:YES animated:YES];
        };
        _duetLayoutViewController.delegate = self;
    }
    return _duetLayoutViewController;
}

- (ACCDuetLayoutViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self.modelFactory createViewModel:ACCDuetLayoutViewModel.class];
    }
    return _viewModel;
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [IESAutoInline(self.serviceProvider, ACCRecordConfigService) registDurationHandler:self];
    [self.flowService addSubscriber:self];
    [self.propService addSubscriber:self];
    [self.cameraService addSubscriber:self];
    [self.cameraService.message addSubscriber:self];
    [self.cameraService.recorder addSubscriber:self];
}

#pragma mark - ACCRecordConfigDurationHandler

- (void)didSetMaxDuration:(CGFloat)duration {
    [self updateDuetItemWithDuration:self.flowService.currentDuration];
}

#pragma mark - ACCRecordFlowServiceSubscriber

- (void)flowServiceDidUpdateDuration:(CGFloat)duration
{
    [self updateDuetItemWithDuration:duration];
}

- (void)flowServiceDidRemoveLastSegment:(BOOL)isReactHasMerge
{
    [self resyncDuetPlayerTime];

    if ([self.viewModel isDuetGreenScreenEverShot]) {
        [self.viewModel sendMessageOfRemovingSegmentsToEffectWithID:kEffectRemoveLastSegmentMsgId];
    }
}

- (void)flowServiceDidRemoveAllSegment
{
    if (!self.repository.repoReshoot.isReshoot) {
        [self resyncDuetPlayerTime];
    }

    if ([self.viewModel isDuetGreenScreenEverShot]) {
        [self.viewModel sendMessageOfRemovingSegmentsToEffectWithID:kEffectRemoveAllSegmentsMsgId];
    }
}

- (void)resyncDuetPlayerTime
{
    if ([self isDuet]) {
        self.flowService.lastCapturedVideoDuration = [self.cameraService.recorder getTotalDuration];
        CMTime targetTime = CMTimeMultiplyByFloat64(CMTimeMakeWithSeconds(self.flowService.lastCapturedVideoDuration, 10000), self.flowService.selectedSpeed);
        [self.cameraService.recorder multiVideoSeekToTime:targetTime completeBlock:nil];
    }
}

- (IESEffectModel *)currentProp
{
    return self.propService.prop;
}

- (BOOL)isDuet
{
    return self.repository.repoDuet.isDuet;
}

- (BOOL)isDraftOrBackup
{
    return self.repository.repoDraft.isDraft || self.repository.repoDraft.isBackUp;
}

@end
