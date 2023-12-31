//
//  ACCAdvancedRecordSettingComponent.m
//  Indexer
//
//  Created by Shichen Peng on 2021/10/25.
//

#import "ACCAdvancedRecordSettingComponent.h"

// AB
#import <CreationKitInfra/ACCConfigManager.h>

// CreationKitRTProtocol
#import <CreationKitRTProtocol/ACCCameraService.h>

// CreationKitArch
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>

// CreativeKit
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreativeKit/ACCProtocolContainer.h>
#import <CreativeKit/ACCPanelViewController.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCTrackProtocol.h>

// CameraClient
#import <CameraClient/ACCRecorderToolBarDefinesD.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CameraClient/ACCBarItem+Adapter.h>
#import <CameraClient/ACCKaraokeService.h>
#import <CameraClient/ACCPopupViewControllerProtocol.h>
#import <CameraClient/ACCPopupTableViewController.h>
#import <CameraClient/ACCAdvancedRecordSettingDataManager.h>
#import <CameraClient/ACCAdvancedRecordSettingItem.h>
#import <CameraClient/ACCPopupTableViewBinarySwitchCell.h>
#import <CameraClient/ACCPopupTableViewSegmentCollectionViewCell.h>
#import <CameraClient/ACCRecordFlowService.h>
#import <CameraClient/ACCAdvancedRecordSettingServiceImpl.h>
#import <CameraClient/ACCRecordMode+LiteTheme.h>
#import <CameraClient/AWERepoContextModel.h>
#import <CameraClient/UIDevice+ACCAdditions.h>
#import <CameraClient/ACCCameraControlProtocolD.h>
#import <CameraClient/ACCAdvancedRecordSettingGridView.h>
#import <CameraClient/AWECameraPreviewContainerView.h>
#import <CameraClient/ACCAdvancedRecordSettingConfigManager.h>
#import <CameraClient/AWERepoTrackModel.h>
#import <CameraClient/ACCFlowerService.h>
#import <CameraClient/ACCStudioLiteRedPacket.h>


@interface ACCAdvancedRecordSettingComponent() <ACCRecordSwitchModeServiceSubscriber, ACCPopupTableViewControllerDelegateProtocol, ACCKaraokeServiceSubscriber, ACCFlowerServiceSubscriber, ACCPanelViewDelegate>

@property (nonatomic, strong) ACCPopupTableViewController *tableVC;
@property (nonatomic, strong) ACCAdvancedRecordSettingDataManager *dataManager;
@property (nonatomic, strong) ACCAdvancedRecordSettingServiceImpl *service;
@property (nonatomic, strong) ACCAdvancedRecordSettingGridView *gridView;
@property (nonatomic, strong) ACCAdvancedRecordSettingConfigManager *configManager;

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCCameraControlProtocolD> cameraControl;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, weak) id<ACCKaraokeService> karaokeService;
@property (nonatomic, strong) id<ACCFlowerService> flowerService;

@property (nonatomic, assign) BOOL isFirstAppear;

/// record selected length mode
/// 记录当前选择的拍摄时长模式
@property (nonatomic, assign) ACCRecordLengthMode lengthMode;

@end

@implementation ACCAdvancedRecordSettingComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESOptionalInject(self.serviceProvider, karaokeService, ACCKaraokeService)
IESAutoInject(self.serviceProvider, flowerService, ACCFlowerService)

#pragma mark - ACCComponentProtocol

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _tableVC = nil;
    _dataManager = nil;
    _service = nil;
    _configManager = nil;
}

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCAdvancedRecordSettingService),
                                   self.service);
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.cameraControl = ACCGetProtocol(self.cameraService.cameraControl, ACCCameraControlProtocolD);
    [self.switchModeService addSubscriber:self];
    [self.karaokeService addSubscriber:self];
    [self.flowerService addSubscriber:self];
}

- (void)loadComponentView
{
    [self loadDataItems];
    [self p_configureTopRightBarItem];
    [self.viewContainer.interactionView insertSubview:self.gridView aboveSubview:self.viewContainer.preview];
}

- (void)componentDidMount
{
    self.isFirstAppear = YES;
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    [self.viewContainer.panelViewController registerObserver:self];
}

- (void)componentDidAppear
{
    [self.dataManager updateSelectedItemsIfNeed:YES];
}

- (void)showSettingPanel
{
    if (!self.viewContainer.isShowingPanel) {
        self.viewContainer.isShowingPanel = YES;
        [self.viewContainer showItems:NO animated:YES];

        [self.viewContainer.panelViewController showPanelView:self.tableVC duration:0.2];
    }
}

- (void)dismissSettingPanel
{
    if (self.viewContainer.isShowingPanel) {
        self.viewContainer.isShowingPanel = NO;
        [self.viewContainer showItems:YES animated:YES];
        
        [self.viewContainer.panelViewController dismissPanelView:self.tableVC duration:0.2];
    }
}

#pragma mark - ACCPopupTableViewControllerDelegateProtocol

- (void)showPanel
{
    [self.dataManager updateSelectedItemsIfNeed:NO];
    [self showSettingPanel];
}

- (void)dismissPanel
{
    [self dismissSettingPanel];
    
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    [self.dataManager updateSelectedItemsIfNeed:YES];
}

#pragma mark - ACCKaraokeServiceSubscriber


- (void)karaokeService:(id<ACCKaraokeService>)service inKaraokeRecordPageDidChangeFrom:(BOOL)prevState to:(BOOL)state
{
    [self.dataManager updateSelectedItemsIfNeed:YES];
}

- (void)karaokeService:(id<ACCKaraokeService>)service recordModeDidChangeFrom:(ACCKaraokeRecordMode)prevMode to:(ACCKaraokeRecordMode)mode
{
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarAdvancedSettingContext];
    [self.dataManager updateSelectedItemsIfNeed:YES];
}

#pragma mark - ACCFlowerServiceSubscriber

- (void)flowerServiceDidChangeFromItem:(ACCFlowerPanelEffectModel *)prevItem toItem:(ACCFlowerPanelEffectModel *)item
{
    [self.dataManager updateSelectedItemsIfNeed:YES];
}

#pragma mark - ACCPanelViewDelegate

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController willShowPanelView:(id<ACCPanelViewProtocol>)panelView
{
    
}

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController didDismissPanelView:(id<ACCPanelViewProtocol>)panelView
{
    if ([self isModeStory]) {
        [self.switchModeService switchToLengthMode:self.lengthMode];
    }
}

#pragma mark - Configure UI

- (void)p_configureTopRightBarItem
{
    ACCBarItemResourceConfig *barConfig = [[self.serviceProvider resolveObject:@protocol(ACCBarItemResourceConfigManagerProtocol)] configForIdentifier:ACCRecorderToolBarAdvancedSettingContext];
    if (barConfig) {
        ACCBarItem *bar = [[ACCBarItem alloc] init];
        bar.title = barConfig.title;
        bar.imageName = barConfig.imageName;
        bar.useAnimatedButton = NO;
        bar.itemId = ACCRecorderToolBarAdvancedSettingContext;
        bar.type = ACCBarItemFunctionTypeDefault;
        @weakify(self);
        bar.barItemActionBlock = ^(UIView * _Nonnull itemView) {
            @strongify(self);
            if (!self.isMounted) {
                return;
            }
            [self showPanel];
            [self trackIconClicked];
        };
        bar.needShowBlock = ^BOOL{
            // 这里只控制icon的展示逻辑，具体能力的屏蔽需要添加到对应 ACCAdvancedRecordSettingItem的needShow中。
            @strongify(self);
            [self.dataManager updateSelectedItemsIfNeed:NO];
            if ([self.dataManager.selectedItems count] == 0) {
                return NO;
            }
            if ([self.cameraService.recorder isRecording]) {
                return NO;
            }
            if ([self isKaraokeAudioMode] && self.karaokeService.inKaraokeRecordPage) {
                return NO;
            }
            if ([self isDuetMode] && ![UIDevice acc_supportTrippleVirtualCamera]) {
                return NO;
            }
            if ([ACCStudioLiteRedPacket() isLiteRedPacketRecord:self.repository]) {
                return NO;
            }
            
            return YES;
        };
        [self.viewContainer.barItemContainer addBarItem:bar];
    }
}

- (ACCPopupTableViewController *)tableVC
{
    if (!_tableVC) {
        _tableVC = [[ACCPopupTableViewController alloc] initWithDataManager:self.dataManager];
        _tableVC.delegate = self;
    }
    return _tableVC;
}

- (ACCAdvancedRecordSettingDataManager *)dataManager
{
    if (!_dataManager) {
        _dataManager = [[ACCAdvancedRecordSettingDataManager alloc] init];
    }
    return _dataManager;
}

#pragma mark - Item Config

- (void)loadDataItems
{
    [self.dataManager addItem:[self itemMaxDuration]];
    [self.dataManager addItem:[self itemVolumeBtnAsShooting]];
    [self.dataManager addItem:[self itemTapToTakePhoto]];
    [self.dataManager addItem:[self itemMultiLensZooming]];
    [self.dataManager addItem:[self itemCameraGrid]];
    [self.dataManager updateSelectedItemsIfNeed:NO];
}

- (ACCAdvancedRecordSettingConfigManager *)configManager
{
    if (!_configManager) {
        _configManager = [[ACCAdvancedRecordSettingConfigManager alloc] init];
    }
    return _configManager;
}

- (ACCAdvancedRecordSettingItem *)itemMaxDuration
{
    ACCAdvancedRecordSettingItem *item = [[ACCAdvancedRecordSettingItem alloc] init];
    item.title = @"最大拍摄时长（秒）";
    item.content = @"";
    item.cellClass = ACCPopupTableViewSegmentCollectionViewCell.class;
    item.cellType = ACCPopupCellTypeSegment;
    item.iconImage = [UIImage acc_imageWithName:@"ic_timer"];
    item.itemType = ACCAdvancedRecordSettingTypeMaxDuration;
    @weakify(self);
    item.needShow = ^BOOL{
        @strongify(self);
        if (!ACCConfigBool(kConfigBool_tools_maximum_shooting_time)) {
            return NO;
        }
        return [self isModeStoryAndExceptFlowerPhotoMode];
    };
    item.segmentActionBlock = ^(NSUInteger index, BOOL needSync) {
        @strongify(self);
        // the real configuration will be called after panel dismissed.
        // 面板消失以后才会去做真正的设置
        self.lengthMode = [self useRecordLengthWith:index];
        
        if (needSync) {
            [self.switchModeService switchToLengthMode:self.lengthMode];
        }
    };
    item.trackEventSegmentBlock = ^(NSUInteger index) {
        @strongify(self);
        [self trackSettingChangesOf:ACCAdvancedRecordSettingTypeMaxDuration withSegmentState:index];
    };
    item.index = [self.configManager getIndexSettingsOf:ACCAdvancedRecordSettingTypeMaxDuration];
    item.touchEnable = NO;
    return item;
}

- (ACCAdvancedRecordSettingItem *)itemVolumeBtnAsShooting
{
    ACCAdvancedRecordSettingItem *item = [[ACCAdvancedRecordSettingItem alloc] init];
    item.title = @"使用音量键拍摄";
    item.content = @"";
    item.cellClass = ACCPopupTableViewBinarySwitchCell.class;
    item.cellType = ACCPopupCellTypeSwitch;
    item.iconImage = [UIImage acc_imageWithName:@"ic_camera"];
    item.itemType = ACCAdvancedRecordSettingTypeBtnAsShooting;
    @weakify(self);
    item.needShow = ^BOOL{
        @strongify(self);
        if (!ACCConfigBool(kConfigBool_tools_use_volume_keys_to_shoot)) {
            return NO;
        }
        return [self isModeStory] || [self isModeMix] || [self isModeTakePicture] || [self isLivePhoto];
    };
    item.switchActionBlock = ^(BOOL switchState, BOOL needSync) {
        @strongify(self);
        [self.service.subscription performEventSelector:@selector(advancedRecordSettingService:configure:switchStatueChangeTo:needSync:) realPerformer:^(id<ACCAdvancedRecordSettingServiceSubScriber> subscriber) {
            [subscriber advancedRecordSettingService:self.service configure:ACCAdvancedRecordSettingTypeBtnAsShooting switchStatueChangeTo:switchState needSync:needSync];
        }];
    };
    item.trackEventSwitchBlock = ^(BOOL switchState) {
        @strongify(self);
        [self trackSettingChangesOf:ACCAdvancedRecordSettingTypeBtnAsShooting withSwitchState:switchState];
    };
    item.switchState = [self.configManager getBoolSettingsOf:ACCAdvancedRecordSettingTypeBtnAsShooting];
    item.touchEnable = NO;
    return item;
}

- (ACCAdvancedRecordSettingItem *)itemTapToTakePhoto
{
    ACCAdvancedRecordSettingItem *item = [[ACCAdvancedRecordSettingItem alloc] init];
    item.title = @"轻触快门拍照";
    item.content = @"";
    item.cellClass = ACCPopupTableViewBinarySwitchCell.class;
    item.cellType = ACCPopupCellTypeSwitch;
    item.iconImage = [UIImage acc_imageWithName:@"ic_shoot"];
    item.itemType = ACCAdvancedRecordSettingTypeTapToTakePhoto;
    @weakify(self);
    item.needShow = ^BOOL{
        @strongify(self);
        if (!ACCConfigBool(kConfigBool_tools_tap_to_take)) {
            return NO;
        }
        return [self isModeStoryAndExceptFlowerPhotoMode];
    };
    
    item.switchActionBlock = ^(BOOL switchState, BOOL needSync) {
        @strongify(self);
        [self.service.subscription performEventSelector:@selector(advancedRecordSettingService:configure:switchStatueChangeTo:needSync:) realPerformer:^(id<ACCAdvancedRecordSettingServiceSubScriber> subscriber) {
            [subscriber advancedRecordSettingService:self.service configure:ACCAdvancedRecordSettingTypeTapToTakePhoto switchStatueChangeTo:switchState needSync:needSync];
        }];
    };
    item.trackEventSwitchBlock = ^(BOOL switchState) {
        @strongify(self);
        [self trackSettingChangesOf:ACCAdvancedRecordSettingTypeTapToTakePhoto withSwitchState:switchState];
    };
    item.switchState = [self.configManager getBoolSettingsOf:ACCAdvancedRecordSettingTypeTapToTakePhoto];
    item.touchEnable = NO;
    return item;
}

- (ACCAdvancedRecordSettingItem *)itemMultiLensZooming
{
    ACCAdvancedRecordSettingItem *item = [[ACCAdvancedRecordSettingItem alloc] init];
    item.title = @"支持多镜头变焦";
    item.content = @"";
    item.cellClass = ACCPopupTableViewBinarySwitchCell.class;
    item.cellType = ACCPopupCellTypeSwitch;
    item.iconImage = [UIImage acc_imageWithName:@"ic_multi_camera"];
    item.itemType = ACCAdvancedRecordSettingTypeMultiLensZooming;
    @weakify(self);
    item.needShow = ^BOOL{
        @strongify(self);
        if (!ACCConfigBool(kConfigBool_tools_multi_lens_zoom)) {
            return NO;
        }
        BOOL needShow = [self isModeStory] || [self isModeMix] || [self isModeTakePicture] || [self isDuetMode] || [self isLivePhoto] || [self isKaraokeMode];
        return needShow && [UIDevice acc_supportTrippleVirtualCamera];
    };
    item.switchActionBlock = ^(BOOL switchState, BOOL needSync) {
        @strongify(self);
        [self.cameraControl setEnableMultiZoomCapability:switchState];
    };
    item.trackEventSwitchBlock = ^(BOOL switchState) {
        @strongify(self);
        [self trackSettingChangesOf:ACCAdvancedRecordSettingTypeMultiLensZooming withSwitchState:switchState];
    };
    item.switchState = [self.configManager getBoolSettingsOf:ACCAdvancedRecordSettingTypeMultiLensZooming];
    item.touchEnable = NO;
    return item;
}

- (ACCAdvancedRecordSettingItem *)itemCameraGrid
{
    ACCAdvancedRecordSettingItem *item = [[ACCAdvancedRecordSettingItem alloc] init];
    item.title = @"网格";
    item.content = @"";
    item.cellClass = ACCPopupTableViewBinarySwitchCell.class;
    item.cellType = ACCPopupCellTypeSwitch;
    item.iconImage = [UIImage acc_imageWithName:@"ic_grid"];
    item.itemType = ACCAdvancedRecordSettingTypeCameraGrid;
    @weakify(self);
    item.needShow = ^BOOL{
        @strongify(self);
        if (!ACCConfigBool(kConfigBool_tools_camera_grid)) {
            return NO;
        }
        return [self isModeStoryAndExpectFlowerScanMode] || [self isModeMix] || [self isModeTakePicture] || [self isLivePhoto] || [self isKaraokeVideoMode];
    };
    
    item.switchActionBlock = ^(BOOL switchState, BOOL needSync) {
        @strongify(self);
        if (switchState) {
            // frame of camera displaying view would be changed, so update it before show it.
            // 拍摄页取景器的frame有可能被改变，所以每次显示网格时更新一下。
            self.gridView.frame = self.cameraService.cameraPreviewView.frame;
            [self.gridView updateGrid];
        }
        [self.gridView setHidden:!switchState];
    };
    item.trackEventSwitchBlock = ^(BOOL switchState) {
        @strongify(self);
        [self trackSettingChangesOf:ACCAdvancedRecordSettingTypeCameraGrid withSwitchState:switchState];
    };
    item.switchState = [self.configManager getBoolSettingsOf:ACCAdvancedRecordSettingTypeCameraGrid];
    item.touchEnable = NO;
    return item;
}

#pragma mark - Tracker

- (void)trackIconClicked
{
    NSMutableDictionary *info = [self generateTrackInfo];
    [ACCTracker() trackEvent:@"click_camera_settings_icon" params:info];
}

- (void)trackSettingChangesOf:(ACCAdvancedRecordSettingType)type withSwitchState:(BOOL)state
{
    NSMutableDictionary *info = [self generateTrackInfo];
    [info setValue:state ? @"on":@"off" forKey:@"to_status"];
    [ACCTracker() trackEvent:[self trackerEventWithType:type] params:info];
}

- (void)trackSettingChangesOf:(ACCAdvancedRecordSettingType)type withSegmentState:(NSUInteger)index
{
    NSMutableDictionary *info = [self generateTrackInfo];
    if (type == ACCAdvancedRecordSettingTypeMaxDuration) {
        NSString *statusContent = @"";
        if (index == 0) {
            statusContent = @"15s";
        } else if (index == 1) {
            statusContent = @"60s";
        } else if (index == 2) {
            statusContent = @"180s";
        } else {
            
        }
        [info setValue:statusContent forKey:@"to_status"];
    }
    
    [ACCTracker() trackEvent:[self trackerEventWithType:type] params:info];
}

- (NSMutableDictionary *)generateTrackInfo
{
    return @{
        @"enter_from" : @"video_shoot_page",
        @"shoot_way" : self.repository.repoTrack.referString ?: @"",
        @"content_type" : self.repository.repoTrack.contentType ?: @"",
        @"content_source" : self.repository.repoTrack.contentSource ?: @"",
        @"creation_id" : self.repository.repoContext.createId ?: @"",
        @"tab_name" : self.repository.repoTrack.tabName ?: @""
    }.mutableCopy;
}

- (NSString *)trackerEventWithType:(ACCAdvancedRecordSettingType)type
{
    NSString *eventKey = @"";
    switch (type) {
        case ACCAdvancedRecordSettingTypeMaxDuration: {
            eventKey = @"record_duration_limit_setting";
            break;
        }
        case ACCAdvancedRecordSettingTypeMultiLensZooming: {
            eventKey = @"multi_camera_zoom_setting";
            break;
        }
        case ACCAdvancedRecordSettingTypeCameraGrid: {
            eventKey = @"grid_camera_setting";
            break;
        }
        case ACCAdvancedRecordSettingTypeTapToTakePhoto: {
            eventKey = @"shutter_slight_press_shoot_setting";
            break;
        }
        case ACCAdvancedRecordSettingTypeBtnAsShooting: {
            eventKey = @"volume_button_record_setting";
            break;
        }
        default:
            eventKey = @"";
            break;
    }
    return eventKey;
}

#pragma mark - Private

- (ACCAdvancedRecordSettingServiceImpl *)service
{
    if (!_service) {
        _service = [[ACCAdvancedRecordSettingServiceImpl alloc] init];
        _service.delegate = self;
    }
    return _service;
}

- (ACCAdvancedRecordSettingGridView *)gridView
{
    if (!_gridView) {
        _gridView = [[ACCAdvancedRecordSettingGridView alloc] initWithFrame:self.cameraService.cameraPreviewView.frame];
        _gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _gridView.hidden = YES;
    }
    return _gridView;
}

- (void)updateGridFrame
{
    self.gridView.frame = self.cameraService.cameraPreviewView.frame;
}

#pragma mark - Private - Mode Checker
/**
 TODO: Severus Peng - pengshichen.lumos12
 随着业务迭代，这里模式判断会变得越来越复杂，二期需要优化。
 如果有好的优化建议，欢迎Lark我～
*/

- (BOOL)isDuetMode
{
    return self.repository.repoDuet.isDuet;
}

- (BOOL)isKaraokeMode
{
    return [self isKaraokeAudioMode] || [self isKaraokeVideoMode];
}

- (BOOL)isKaraokeAudioMode
{
    return self.karaokeService.recordMode == ACCKaraokeRecordModeAudio && self.karaokeService.inKaraokeRecordPage;
}

- (BOOL)isKaraokeVideoMode
{
    return self.karaokeService.recordMode == ACCKaraokeRecordModeVideo && self.karaokeService.inKaraokeRecordPage;
}

- (BOOL)isModeMix
{
    NSInteger modeId = self.switchModeService.currentRecordMode.modeId;
    return (ACCRecordModeMixHoldTapRecord == modeId || ACCRecordModeMixHoldTap15SecondsRecord == modeId || ACCRecordModeMixHoldTapLongVideoRecord == modeId || ACCRecordModeMixHoldTap60SecondsRecord == modeId || ACCRecordModeMixHoldTap3MinutesRecord == modeId) && ![self isDuetMode];
}

- (BOOL)isModeTakePicture
{
    return ACCRecordModeTakePicture == self.switchModeService.currentRecordMode.modeId;
}

- (BOOL)isLivePhoto
{
    return ACCRecordModeLivePhoto == self.switchModeService.currentRecordMode.modeId;
}

- (BOOL)isModeStory
{
    return self.switchModeService.currentRecordMode.isStoryStyleMode && ![self isKaraokeAudioMode];
}

- (BOOL)isModeStoryAndExceptFlowerPhotoMode
{
    return [self isModeStory] && !self.flowerService.isShowingPhotoProp && ![ACCStudioLiteRedPacket() isLiteRedPacketRecord:self.repository];
}

- (BOOL)isModeStoryAndExpectFlowerScanMode
{
    return [self isModeStory] && !self.flowerService.isCurrentScanProp;
}

- (BOOL)isFromIM
{
    return self.repository.repoContext.isIMRecord;
}

- (ACCRecordLengthMode)useRecordLengthWith:(NSUInteger)index
{
    if (index == 0) {
        return ACCRecordLengthModeStandard;
    }
    else if (index == 1) {
        return ACCRecordLengthMode60Seconds;
    } else if (index == 2) {
        return ACCRecordLengthMode3Minutes;
    } else {
        // 兜底返回标准
        return ACCRecordLengthModeStandard;
    }
}

@end
