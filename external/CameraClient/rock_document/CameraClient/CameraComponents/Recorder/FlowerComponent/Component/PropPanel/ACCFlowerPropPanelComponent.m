//
//  ACCFlowerPropPanelComponent.m
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/11/12.
//

#import <CameraClient/ACCRecordPropService.h>
#import <CameraClient/AWEStickerApplyHandlerContainer.h>
#import <CameraClient/AWEStickerPickerControllerCollectionStickerPlugin.h>
#import <CreationKitBeauty/ACCNetworkReachabilityProtocol.h>
#import <CreationKitComponents/ACCBeautyService.h>
#import <CreationKitComponents/ACCFilterService.h>
#import <CreationKitInfra/ACCDeviceAuth.h>
#import <CreationKitInfra/ACCTapticEngineManager.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitArch/ACCRecordTrackService.h>

#import "ACCFlowerCampaignManagerProtocol.h"
#import "ACCFlowerPropPanelComponent.h"
#import "ACCFlowerPropPanelService.h"
#import "ACCFlowerPropPanelView+Tray.h"
#import "ACCFlowerPropPanelView.h"
#import "ACCFlowerPropPanelViewModel.h"
#import "ACCFlowerRewardModel.h"
#import "ACCFlowerService.h"
#import "ACCLynxWindowService.h"
#import "ACCRecognitionService.h"
#import <CreationKitBeauty/ACCNetworkReachabilityProtocol.h>
#import "ACCFlowerAuditDataService.h"
#import "ACCRecordAuthService.h"
#import "ACCScanService.h"
#import "ACCRecordFlowService.h"
#import "AWERepoContextModel.h"
#import "AWERepoFlowerTrackModel.h"
#import <CreationKitBeauty/ACCNetworkReachabilityProtocol.h>
#import "ACCFlowerAuditDataService.h"

@interface ACCFlowerPropPanelComponent () <
ACCFlowerServiceSubscriber,
ACCRecordSwitchModeServiceSubscriber,
ACCRecordPropServiceSubscriber,
ACCRecorderViewContainerItemsHideShowObserver,
ACCCameraLifeCircleEvent>

@property (nonatomic, strong) ACCFlowerPropPanelViewModel *viewModel;
@property (nonatomic, strong) ACCFlowerPropPanelView *exposePanelView;

@property (nonatomic, weak) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, weak) id<ACCRecordPropService> propService;
@property (nonatomic, weak) id<ACCFlowerService> flowerService;
@property (nonatomic, weak) id<ACCCameraService> cameraService;
@property (nonatomic, weak) id<ACCRecordAuthService> authService;
@property (nonatomic, weak) id<ACCRecordFlowService> flowService;
@property (nonatomic, weak) id<ACCRecordTrackService> trackService;

@property (nonatomic, strong) RACDisposable *recorderStateDisposable;
@property (nonatomic, assign) NSInteger previousSelectedIndex;

@property (nonatomic, assign) BOOL hasAutoEnteredFlower;
@property (nonatomic, strong) IESEffectModel *needToInsertProp; // 外部带道具拍摄，需要插入到春节面板里的

@property (nonatomic, assign) BOOL p_viewDidAppared;
@property (nonatomic, copy) NSString *waitForShowAwardSchema;
@property (nonatomic, copy) NSDictionary *waitForShowAwardData;

@property (nonatomic, assign) BOOL shouldTrackEnter;
@property (nonatomic, assign) BOOL isFromClickEntrance;

@property (nonatomic, assign) BOOL firstFrameLoaded;
@property (nonatomic,   copy) dispatch_block_t firstFrameShowBlock;

@end

@implementation ACCFlowerPropPanelComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer);

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.flowerService = IESAutoInline(serviceProvider, ACCFlowerService);
    [self.flowerService addSubscriber:self];
    self.cameraService = IESAutoInline(serviceProvider, ACCCameraService);
    [self.cameraService addSubscriber:self];
    self.propService = IESAutoInline(serviceProvider, ACCRecordPropService);
    self.flowService = IESAutoInline(serviceProvider, ACCRecordFlowService);
    [self.propService addSubscriber:self];
    self.viewModel.propService = self.propService;
    self.viewModel.flowerService = self.flowerService;
    self.viewModel.cameraService = self.cameraService;
    self.authService = IESAutoInline(serviceProvider, ACCRecordAuthService);
    if (![ACCDeviceAuth hasCameraAndMicroPhoneAuth]) {
        [[self.authService.passCheckAuthSignal takeUntil:self.rac_willDeallocSignal].deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
            if ([ACCDeviceAuth hasCameraAndMicroPhoneAuth]) {
                [self autoEnterFlowerModeIfNeeded];
            }
        }];
    }
    self.trackService = IESAutoInline(serviceProvider, ACCRecordTrackService);
}

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCFlowerPropPanelService),
                                   self.viewModel);
}

- (void)componentDidMount {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enterFlowerModeByClickingEntrance)
                                                 name:@"flowerPropPanelShow"
                                               object:nil];
    self.flowerService.viewContainer = self.viewContainer;
    [self.flowerService prefetchFlowerPanelData];
    self.previousSelectedIndex = kACCFlowerPanelIndexInvalid; // 设置为一个无效值;
    self.mounted = YES; // 方法名叫 componentDidMount，按照 cocoa conventions，此时 mounted 就应该 = YES，但 componentManager 是在这个方法之后才设置 mounted，所以这里需要手动设一下，用于 autoEnterFlowerModeIfNeeded
    [self autoEnterFlowerModeIfNeeded];
    [IESAutoInline(ACCBaseServiceProvider(), ACCFlowerAuditDataService) unzipAuditPackageIfNeeded];
}

- (void)componentDidAppear
{
    self.p_viewDidAppared = YES;
    if (!ACC_isEmptyString(self.waitForShowAwardSchema) && self.firstFrameLoaded) {
        NSString *schema = self.waitForShowAwardSchema;
        NSDictionary *data = self.waitForShowAwardData;
        self.waitForShowAwardSchema = nil;
        self.waitForShowAwardData = nil;
        [self displayDailyReward:schema awardData:data];
    }
}

#pragma mark - Protocol Implementation

#pragma mark ACCCameraLifeCircleEvent

- (void)onCameraDidStartRender:(id<ACCCameraService>)cameraService
{
    self.firstFrameLoaded = YES;
    if (!ACC_isEmptyString(self.waitForShowAwardSchema) && self.p_viewDidAppared) {
        NSString *schema = self.waitForShowAwardSchema;
        NSDictionary *data = self.waitForShowAwardData;
        self.waitForShowAwardSchema = nil;
        self.waitForShowAwardData = nil;
        [self displayDailyReward:schema awardData:data];
    }
}

#pragma mark ACCFlowerServiceSubscriber

- (void)flowerServiceDidEnterFlowerMode:(id<ACCFlowerService>)service
{
    self.shouldTrackEnter = YES;
    [self setupUIIfNeeded];
    [self p_bindViewModel];
    [self fetchFlowerData]; // 拉数据
    [self updatePanelViewVisibilityWithAnimated:YES isFirstLanding:self.viewModel.items.count == 0]; // 展示面板
    self.repository.repoFlowerTrack.fromFlowerCamera = YES;
}
    
- (void)flowerServiceDidLeaveFlowerMode:(id<ACCFlowerService>)service
{
    [self updatePanelViewVisibilityWithAnimated:YES isFirstLanding:NO];
    [self p_unbindViewModel];
    self.repository.repoFlowerTrack.fromFlowerCamera = NO;
    self.repository.repoFlowerTrack.isFromShootProp = NO;
    self.repository.repoFlowerTrack.isInRecognition = NO;
    
    if (ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab) && ACCConfigBool(kConfigBool_horizontal_scroll_change_subtab)) {
        (IESAutoInline(self.serviceProvider, ACCFilterService)).panGestureRecognizerEnabled = NO;
    } else {
        (IESAutoInline(self.serviceProvider, ACCFilterService)).panGestureRecognizerEnabled = YES;
    }
}

- (BOOL)flowerService:(id<ACCFlowerService>)flowerService JSBDidRequestApplyPropWithID:(NSString *)propID
{
    if (!self.flowerService.inFlowerPropMode) {
        return NO;
    }
    
    self.repository.repoFlowerTrack.lastFlowerPropChooseMethod = @"sf_2022_activity_camera_task_panel";
    NSInteger index = [self.viewModel itemIndexForFlowerPropID:propID];
    if ([self.viewModel.items acc_objectAtIndex:index].dType == ACCFlowerEffectTypeScan) {
        (IESAutoInline(self.serviceProvider, ACCScanService)).scanReferString = @"sf_2022_activity_camera_task_panel";
    }
    if (index == kACCFlowerPanelIndexInvalid) {
        return NO;
    } else {
        self.viewModel.selectedIndex = index;
        // track for camera task panel auto use
        [self.viewModel flowerTrackForPropClick:index enterMethod:@"sf_2022_activity_camera_click"];
        return YES;
    }
}

- (void)flowerServiceDidChangeFromItem:(ACCFlowerPanelEffectModel *)prevItem toItem:(ACCFlowerPanelEffectModel *)item
{
    if (self.shouldTrackEnter) {
        if (self.isFromClickEntrance) {
            [self.viewModel flowerTrackForEnterFlowerCameraTab:@"click_sf_2022_icon" propID:item.effectID];
        } else {
            [self.viewModel flowerTrackForEnterFlowerCameraTab:nil propID:item.effectID];
        }
        self.isFromClickEntrance = NO;
        self.shouldTrackEnter = NO;
    }
    
    // MARK: 拍照道具
    BOOL oldIsShootProp = prevItem.dType == ACCFlowerEffectTypePhoto;
    BOOL newIsShootProp = item.dType == ACCFlowerEffectTypePhoto;
    if (!oldIsShootProp && newIsShootProp) {
        // 切换到拍照模式
        self.cameraService.recorder.cameraMode = HTSCameraModePhoto;
        
        self.viewModel.isShootPropPanelShow = YES;
        self.repository.repoFlowerTrack.isFromShootProp = YES;
        // 展开拍照道具托盘
        if (self.viewModel.shootPropLoaded) {
            [self.exposePanelView showFlowerShootCollectionPanel];
        } else {
            // 尝试重新加载
            [self.viewModel loadFlowerShootPropDataIfNeed:self.viewModel.items];
        }
        // 更新侧边栏
        [self.viewContainer.barItemContainer updateAllBarItems];
    } else if (oldIsShootProp && !newIsShootProp) {
        // 恢复到快拍
        self.cameraService.recorder.cameraMode = HTSCameraModeVideo;
        // 收起拍照道具托盘
        self.viewModel.isShootPropPanelShow = NO;
        self.repository.repoFlowerTrack.isFromShootProp = NO;
        [self.exposePanelView hideFlowerShootCollectionPanel];
        // 更新侧边栏
        [self.viewContainer.barItemContainer updateAllBarItems];
    }
    
    // MARK: 滤镜美颜屏蔽，时间仓促，后续沉淀的话搞个plugin吧
    BOOL newIsScan = item && item.dType == ACCFlowerEffectTypeScan;
    BOOL newIsNotScan = item && (item.dType != ACCFlowerEffectTypeScan); // 注意 newIsScan 和 newIsNotScan 没有涵盖所有 case。
    if (newIsScan) {
        // 扫一扫模式清空美颜、滤镜
        [IESAutoInline(self.serviceProvider, ACCBeautyService) clearAllComposerBeautyEffects];
        [IESAutoInline(self.serviceProvider, ACCFilterService) applyFilter:nil withShowFilterName:YES sendManualMessage:YES];
        (IESAutoInline(self.serviceProvider, ACCFilterService)).panGestureRecognizerEnabled = NO;
    }
    if (newIsNotScan) {
        (IESAutoInline(self.serviceProvider, ACCFilterService)).panGestureRecognizerEnabled = YES;
    }
}

#pragma mark ACCRecorderViewContainerItemsHideShowObserver

- (void)shouldItemsShow:(BOOL)show animated:(BOOL)animated
{
    [self updatePanelViewVisibilityWithAnimated:animated isFirstLanding:NO];
}

#pragma mark - 进入春节tab
#pragma mark 点击快拍上的入口进入春节Tab
- (void)enterFlowerModeByClickingEntrance
{
    [ACCTapticEngineManager tap];
    
    if (![IESAutoInline(self.serviceProvider, ACCNetworkReachabilityProtocol) isReachable]) {
        [ACCToast() show:@"网络错误，请检查网络设置"];
        return;
    }
    if (!self.flowerService.inFlowerPropMode) {
        self.isFromClickEntrance = YES;
        self.flowerService.inFlowerPropMode = YES;
    }
}

#pragma mark 首次进拍摄页自动进入春节Tab

- (BOOL)autoEnterFlowerModeIfNeeded
{
    if (self.hasAutoEnteredFlower) {
        return NO;
    }
    
    if (![ACCDeviceAuth hasCameraAndMicroPhoneAuth]) {
        return NO;
    }
    
    if (!self.isMounted) {
        return NO;
    }
    
    AWERepoContextModel *repoContext = self.repository.repoContext;
    if (!repoContext.flowerMode) {
        return NO;
    }
    
    // Schema 指定进入春节 tab || 使用春节道具拍同款
    if (ACC_isEmptyString(repoContext.flowerItem) && self.needToInsertProp == nil) {
        return NO;
    }

    if (![IESAutoInline(self.serviceProvider, ACCNetworkReachabilityProtocol) isReachable]) {
        [ACCToast() show:@"网络错误，请检查网络设置"];
        return NO;
    }
    
    self.hasAutoEnteredFlower = YES;
    if (!self.flowerService.inFlowerPropMode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.flowerService.inFlowerPropMode = YES;
        });
    }
    
    return YES;
}

#pragma mark PropServiceSubscriber

/// 道具自动插入春节面板逻辑
- (void)propServiceRearFinishedDownloadProp:(IESEffectModel *)effect parentProp:(IESEffectModel *)parentEffect
{
    if (![effect isFlowerProp]) {
        return;
    }
    self.needToInsertProp = effect;
    if (!self.flowerService.inFlowerPropMode) {
        [self autoEnterFlowerModeIfNeeded];
    } else {
        NSInteger targetIndex = [self insertPropIntoFlowerPanel:effect];
        [self locateFlowerPanelToIndex:targetIndex];
        
    }
}

#pragma mark - View Model Binding

- (void)p_bindViewModel
{
    [self.viewContainer addObserver:self];
    @weakify(self);
    self.recorderStateDisposable = [[[RACObserve(self.cameraService.recorder, recorderState) skip:1] takeUntil:self.rac_willDeallocSignal].deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        [self updatePanelViewVisibilityWithAnimated:YES isFirstLanding:NO];
    }];
    
    [[RACObserve(self.viewModel, shootPropLoaded) takeUntil:self.rac_willDeallocSignal] subscribeNext:^(NSNumber*  _Nullable x) {
        @strongify(self)
        // update shoot prop panel if data not ready
        if (x.boolValue && self.viewModel.isShootPropPanelShow) {
            [self.exposePanelView showFlowerShootCollectionPanel];
        }
    }];
    

    [[RACObserve(self.viewModel, selectedItem) takeUntil:self.rac_willDeallocSignal] subscribeNext:^(ACCFlowerPanelEffectModel*  _Nullable item) {
        @strongify(self)
        if(item.dType == ACCFlowerEffectTypeInvalid) return;

        switch (item.dType) {
            case ACCFlowerEffectTypeProp:
                [self.exposePanelView updateEntryText:[ACCFlowerCampaignManager() flowerEntryPropHint]];
                break;
            case ACCFlowerEffectTypeScan:
                [self.exposePanelView updateEntryText:[ACCFlowerCampaignManager() flowerEntryScanHint]];
                break;
            case ACCFlowerEffectTypePhoto:
                [self.exposePanelView updateEntryText:[ACCFlowerCampaignManager() flowerEntryPhotoHint]];
                break;
            case ACCFlowerEffectTypeRecognition:
                [self.exposePanelView updateEntryText:[ACCFlowerCampaignManager() flowerEntryGrootHint]];
                break;
                
            default:
                break;
        }
    }];
    
}

- (void)p_unbindViewModel
{
    [self.viewContainer removeObserver:self];
    [self.recorderStateDisposable dispose];
    self.recorderStateDisposable = nil;
}

#pragma mark - Getter && setter

- (ACCFlowerPropPanelViewModel *)viewModel
{
    if (_viewModel == nil) {
        _viewModel = [[ACCFlowerPropPanelViewModel alloc] init];
    }
    return _viewModel;
}

- (void)displayDailyReward:(NSString *)showSchema awardData:(id)awardData
{
    [self.flowerService broadcastDidOpenTaskPanelMsg];
    @weakify(self);
    [IESAutoInline(self.serviceProvider, ACCLynxWindowService) showSchema:showSchema
                                                                     data:awardData
                                                            dismissAction:^{
        @strongify(self);
        [self.flowerService broadcastDidCloseTaskPanelMsg];
    }];
}

// 让 view Model 拉取春节道具面板相关数据
- (void)fetchFlowerData
{
    @weakify(self);
    //集卡期间每日首次进入拉取三张卡片奖励
    [self.viewModel fetchDailyRewardIfNeededWithCompletion:^(NSError * _Nullable error, ACCFlowerRewardResponse * _Nonnull result, NSString * _Nullable showSchema) {
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            if(ACC_isEmptyString(showSchema)){
                return;
            }
            if (!self.p_viewDidAppared || !self.firstFrameLoaded) {
                self.waitForShowAwardSchema = showSchema;
                self.waitForShowAwardData = result.data;
                return;
            }
            [self displayDailyReward:showSchema awardData:result.data];
        });
    }];
    
    // 拉取春节道具面板
    [self.viewModel fetchFlowerPropDataWithCompletion:^{
        @strongify(self);
        if (self.viewModel.items.count == 0) {
            [ACCToast() show:@"加载失败"];
            self.flowerService.inFlowerPropMode = NO;
            [self.viewModel flowerTrackForQuitFlowerCameraTab:YES];
            return;
        }
        
        /// A. 更新选中的 index
        /// 上次选中的优先级最高
        NSInteger targetIndex = self.previousSelectedIndex;
        
        /// 插入道具
        if (targetIndex == kACCFlowerPanelIndexInvalid && self.needToInsertProp) {
            targetIndex = [self insertPropIntoFlowerPanel:self.needToInsertProp];
            // 使用之后清空 needToInsertProp
            self.needToInsertProp = nil;
        }
        
        /// 外部指定模式
        if (targetIndex == kACCFlowerPanelIndexInvalid) {
            targetIndex = [self.viewModel itemIndexForFlowerItem:self.repository.repoContext.flowerItem];
            self.repository.repoContext.flowerItem = nil; // 消费完就清空
        }
        
        /// 
        if (targetIndex == kACCFlowerPanelIndexInvalid) {
            targetIndex = MAX(0, self.viewModel.targetIndexUnderLuckyCardStage);
        }
        
        [self locateFlowerPanelToIndex:targetIndex];
        // track for auto use
        [self.viewModel flowerTrackForPropClick:targetIndex enterMethod:@"sf_2022_activity_camera_enter"];
        
        /// end of A.
    }];
}


/// @return index of `prop` after insertion.
- (NSInteger)insertPropIntoFlowerPanel:(IESEffectModel *)prop
{
    // 如果有需要插入的道具
    // 先检查春节tab里是否有该道具，如果有，直接定位
    NSInteger targetIndex = [self.viewModel itemIndexForFlowerPropID:prop.effectIdentifier];
    
    // 如果没有，插入到第一个普通道具前面
    if (targetIndex == kACCFlowerPanelIndexInvalid) {
        NSInteger firstPropIndex = [self.viewModel itemIndexForFlowerItem:ACCFlowerItemTypeProp];
        ACCFlowerPanelEffectModel *item = [ACCFlowerPanelEffectModel panelEffectModelFromIESEffectModel:prop];
        [self.viewModel insertItem:item atIndex:firstPropIndex];
        targetIndex = firstPropIndex;
    }
    return targetIndex;
}

- (void)locateFlowerPanelToIndex:(NSInteger)index
{
    if (index < 0 || index >= self.viewModel.items.count) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.exposePanelView.panelView.selectedIndex != index) {
            // 如果 collectionView 不在 targetIndex，就滚动到这个 index，并且动画结束后会触发更新 viewModel.selectedIndex
            [self.exposePanelView.panelView updateSelectedIndex:index animated:YES];
        } else {
            // 如果 collectionView 已经是 targetIndex 了，只需要手动更新 viewModel.selectedIndex
            self.viewModel.selectedIndex = index;
        }
    });
}

- (void)setupUIIfNeeded
{
    if (_exposePanelView == nil) {
        _exposePanelView = [[ACCFlowerPropPanelView alloc] initWithFrame:self.viewContainer.rootView.bounds];
        _exposePanelView.alpha = 0;
        _exposePanelView.panelViewMdoel = self.viewModel;
        _exposePanelView.panelView.panelViewMdoel = self.viewModel;
        _exposePanelView.panelView.recognitionService = IESAutoInline(self.serviceProvider, ACCRecognitionService);
        _exposePanelView.exposePanGestureRecognizer.innerTouchDelegateView = [self.viewContainer.layoutManager viewForType:ACCViewTypeCaptureAnimation];
        @weakify(self);
        _exposePanelView.didSelectStickerBlock = ^(IESEffectModel * _Nullable sticker) {
            @strongify(self);
            [self.propService applyProp:sticker propSource:ACCPropSourceFlower];
        };
        _exposePanelView.didTakePictureBlock = ^{
            @strongify(self);
            if (self.flowerService.isShowingPhotoProp) {
                [self.flowService takePicture];
                [self.trackService trackRecordVideoEventWithCameraService:self.cameraService];
            }
        };
        _exposePanelView.closeButtonClickCallback = ^{
            @strongify(self);
            [ACCTapticEngineManager tap];
            [self.viewModel flowerTrackForQuitFlowerCameraTab:NO];
            self.previousSelectedIndex = self.viewModel.selectedIndex;
            self.viewModel.selectedIndex = kACCFlowerPanelIndexInvalid;
            self.flowerService.inFlowerPropMode = NO;
        };
        _exposePanelView.onTrayViewChanged = ^(UIView *trayView) {

        };
        _exposePanelView.entryButtonClickCallback= ^{
            @strongify(self);
            self.viewContainer.isShowingPanel = YES;
            [self.viewContainer showItems:NO animated:NO];
            [self.flowerService broadcastDidOpenTaskPanelMsg];
            [IESAutoInline(self.serviceProvider, ACCLynxWindowService) showSchema:[ACCFlowerCampaignManager() flowerSchemaWithSceneName:ACCFLOSceneCameraTask] data:nil dismissAction:^{
                @strongify(self);
                self.viewContainer.isShowingPanel = NO;
                [self.viewContainer showItems:YES animated:NO];
                [self.flowerService broadcastDidCloseTaskPanelMsg];
            }];
        };
    
        [[self viewContainer].interactionView addSubview:_exposePanelView];

        _exposePanelView.recordButtonTop = [[self viewContainer].layoutManager.guide recordButtonCenterY] - 40;
        _exposePanelView.taskEntryViewBottom = [self.viewContainer.layoutManager viewForType:ACCViewTypeSwitchSubmodeView].acc_bottom;
        _exposePanelView.trayViewOffset = 27;
    }
}

#pragma mark - UI

// 仅更新显隐，不会把 panelView 加到 view hierarchy 上
- (void)updatePanelViewVisibilityWithAnimated:(BOOL)animated isFirstLanding:(BOOL)isFirstLanding
{
    BOOL show = YES;
    if (self.cameraService.recorder.recorderState == ACCCameraRecorderStateRecording) {
        show = NO;
    }
    
    if (!self.flowerService.inFlowerPropMode) {
        show = NO;
    }
    
    // 不能用 isShowingAnyPanel 来判断，因为外露面板本身就是一种 panel
    if (self.viewContainer.itemsShouldHide) {
        show = NO;
    }
    
    // 目标状态和当前状态一致
    if (show == (!self.exposePanelView.hidden && self.exposePanelView.alpha > 0)) {
        return;
    }
    
    if (show) {
        self.viewContainer.propPanelType = ACCRecordPropPanelFlower;
    } else if (self.viewContainer.propPanelType == ACCRecordPropPanelFlower) {
        self.viewContainer.propPanelType = ACCRecordPropPanelNone;
    }
        
    if (!animated) {
        self.exposePanelView.hidden = !show;
        self.exposePanelView.alpha = show? 1 : 0;
        if (!show) {
            [self resetLayoutManager];
        } else {
            [self changeLayoutManager];
        }
    } else {
        if (show) {
            if (isFirstLanding) {
                self.exposePanelView.alpha = 1;
                self.exposePanelView.hidden = NO;
                self.exposePanelView.panelView.acc_left = self.exposePanelView.acc_width;
                self.viewContainer.interactionView.userInteractionEnabled = NO;
                [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.exposePanelView.panelView.acc_left = 0;
                } completion:^(BOOL finished) {
                    self.viewContainer.interactionView.userInteractionEnabled = YES;
                }];
            } else {
                self.viewContainer.interactionView.userInteractionEnabled = NO;
                [self.exposePanelView acc_fadeShowWithCompletion:^{
                    self.viewContainer.interactionView.userInteractionEnabled = YES;
                }];
                [self.exposePanelView reloadScrollPanel];
            }
            [self changeLayoutManager];
        } else {
            self.viewContainer.interactionView.userInteractionEnabled = NO;
            [self.exposePanelView acc_fadeHiddenWithCompletion:^{
                self.viewContainer.interactionView.userInteractionEnabled = YES;
            }];
            [self resetLayoutManager];
        }
    }
    self.viewModel.isShowingPanel = show;
}

- (BOOL)isShowingPanel
{
    return (self.exposePanelView.superview != nil) && (self.exposePanelView.hidden == NO) && (self.exposePanelView.alpha == 1) && (self.propService.propApplyHanderContainer.layoutManager == self.exposePanelView);
}


- (void)changeLayoutManager
{
    self.propService.propApplyHanderContainer.layoutManager = self.exposePanelView;
    AWEStickerPickerControllerCollectionStickerPlugin *collectionPlugin = [[self propService].propPickerViewController.plugins acc_match:^BOOL(id<AWEStickerPickerControllerPluginProtocol>  _Nonnull item) {
        return [item isKindOfClass:[AWEStickerPickerControllerCollectionStickerPlugin class]];
    }];
    collectionPlugin.layoutManager = self.exposePanelView;
}

- (void)resetLayoutManager
{
    [self propService].propApplyHanderContainer.layoutManager = [self propService].propPickerViewController;
    AWEStickerPickerControllerCollectionStickerPlugin *collectionPlugin = [[self propService].propPickerViewController.plugins acc_match:^BOOL(id<AWEStickerPickerControllerPluginProtocol>  _Nonnull item) {
        return [item isKindOfClass:[AWEStickerPickerControllerCollectionStickerPlugin class]];
    }];
    collectionPlugin.layoutManager = [self propService].propPickerViewController;
}


@end
