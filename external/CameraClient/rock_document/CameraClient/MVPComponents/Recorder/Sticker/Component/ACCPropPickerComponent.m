//
//  ACCPropPickerComponent.m
//  CameraClient
//
//  Created by zhangchengtao on 2020/7/12.
//

#import "AWERepoPropModel.h"
#import "AWERepoContextModel.h"
#import "ACCPropPickerComponent.h"
#import "AWERedPackThemeService.h"
#import "ACCPropExploreExperimentalControl.h"

#import <CreativeKit/ACCRecorderViewContainer.h>
#import "ACCStickerGroupedApplyPredicate.h"
#import "ACCStickerApplyPredicate.h"
#import "ACCRecordPropService.h"
#import <CreationKitArch/AWEStudioMeasureManager.h>
#import "ACCFriendsServiceProtocol.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import "ACCPropConfigProtocol.h"
#import "ACCFlowerService.h"
#import <CreationKitInfra/ACCDeviceAuth.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreativeKit/ACCRouterService.h>
#import "ACCEditViewControllerInputData.h"
#import "AWEVideoFragmentInfo.h"
#import <IESInject/IESInjectDefines.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import <CreationKitInfra/ACCRACWrapper.h>

#import "AWEStickerDataManager.h"
#import "ACCStudioGlobalConfig.h"
#import "ACCStickerControllerPluginFactoryTemplate.h"

// Bubble
#import "AWERecorderTipsAndBubbleManager.h"

// Sticker Panel and Plug-ins
#import "AWEDouyinStickerCategoryModel.h"
#import "AWEStickerPicckerDataSource.h"
#import "AWEStickerPickerCategoryCell.h"
#import "AWEStickerPickerModel+Favorite.h"
#import "AWEStickerPickerController.h"
#import "AWEStickerPickerController+LayoutManager.h"
#import "AWEStickerPickerDefaultUIConfiguration.h"
#import "AWEStickerPickerControllerFavoritePlugin.h"
#import "AWEStickerPickerControllerCollectionStickerPlugin.h"
#import "AWEStickerPickerControllerSchemaStickerPlugin.h"
#import "AWEStickerPickerControllerSwitchCameraPlugin.h"
#import "AWEStickerPickerControllerShowcaseEntrancePlugin.h"
#import "AWEStickerPickerControllerMusicPropBubblePlugin.h"
#import "AWEStickerPickerControllerDuetPropBubblePlugin.h"
#import "AWEStickerPickerControllerExploreStickerPlugin.h"
#import "AWEStickerPickerControllerSecurityTipsPlugin.h"

#import "AWEStickerPickerDataContainer.h"

// ViewModels
#import "ACCPropViewModel.h"
#import "ACCRecordAuthService.h"
#import "ACCPropExploreService.h"
#import "ACCRecordSelectPropViewModel.h"
#import "ACCPropPickerViewModel.h"
#import "ACCConfigKeyDefines.h"
#import "AWERepoFlowControlModel.h"
#import "AWERepoVideoInfoModel.h"
#import "AWERepoTrackModel.h"

#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>

// Live Duet
#import "AWELiveDuetPostureViewController.h"
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>

// Effect Model for red packet
#import "IESEffectModel+ACCRedpacket.h"

#import "ACCFlowerCampaignManagerProtocol.h"
#import <CameraClient/AWERecordInformationRepoModel.h>
#import <CameraClient/AWERepoContextModel.h>

static NSString * const kAWEEffectStickerPanelName = @"default";

@interface ACCPropPickerComponent ()
<
ACCRecordPropServiceSubscriber,
AWEStickerPickerControllerDelegate,
AWELiveDuetPostureViewControllerDelegate,
ACCRouterServiceSubscriber,
ACCPropExploreServiceSubscriber
>

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;

// Services
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCRecordPropService> propService;
@property (nonatomic, strong) id<ACCRecordAuthService> authService;
@property (nonatomic, strong) id<AWERedPackThemeService> themeService;

@property (nonatomic, strong) ACCPropViewModel *viewModel;

@property (nonatomic, strong, readwrite) AWEStickerPickerController *stickerPickerController;

@property (nonatomic, strong, readwrite) AWEStickerPicckerDataSource *stickerDataSource;

@property (nonatomic, copy) NSString *dismissTrackStr;

@property (nonatomic, assign) BOOL hasAppliedFirstHotProp;

@property (nonatomic, assign) BOOL hasShowPanelBefore;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *downloadStickerStartTimeDictionary;

@property (nonatomic, strong) NSNumber *downloadCategoriesStartTime;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *downloadStickerListStartTimeDictionary;

// Live Duet
@property (nonatomic, strong) AWELiveDuetPostureViewController *liveDuetPostureViewController;

@property (nonatomic, strong) IESEffectModel *needRestoredParentProp;

@property (nonatomic, strong) NSMutableArray *dataSourceCreatorBlocks;

@property (nonatomic, strong, readwrite) ACCGroupedPredicate *skipCategoryPredicate;
@property (nonatomic, strong, readwrite) ACCGroupedPredicate *skipStickerPredicate;

@end

@implementation ACCPropPickerComponent


IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, propService, ACCRecordPropService)
IESAutoInject(self.serviceProvider, authService, ACCRecordAuthService)

IESOptionalInject(self.serviceProvider, themeService, AWERedPackThemeService)

#pragma mark - ACCFeatureComponent

- (void)dealloc
{
    AWELogToolDebug(AWELogToolTagNone, @"%s", __func__);
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase {
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [IESAutoInline(serviceProvider, ACCRouterService) addSubscriber:self];
    [IESAutoInline(serviceProvider, ACCPropExploreService) addSubscriber:self];
}

- (void)componentDidMount {
    [[ACCPropExploreExperimentalControl sharedInstance] setPublishModel:self.viewModel.inputData.publishModel];
    [self p_bindViewModels];
    
    // Load props which need to insert into hot tab.
    // 加载要前插到热门分类到道具数据
    [self p_fetchPrioritizedStickers];
    
    if (ACCConfigBool(kConfigBool_enable_prefetch_effect_list)) {
        // Preload sticker panel list data.
        // 预加载道具面板数据
        self.stickerPickerController.model.stickerCategoryListLoadMode = AWEStickerCategoryListLoadModePrefecth;
        [self.stickerPickerController loadStickerCategory];
    }

    [self p_showPanelForLocalStickerIfNeeded];
    if ([self shouldShowLiveDuetPostureViewController]) {
        // to prevent hot categories's sticker interferes, so need to set stickerPickerController to be nil
        self.stickerPickerController = nil;

        // configure live duet
        self.liveDuetPostureViewController.delegate = self;
        [self setLiveDuetPostureViewControllerDismissBlockIfNeeded];

        NSString *imageFolderPath = self.viewModel.inputData.publishModel.repoProp.liveDuetPostureImagesFolderPath;
        [self.liveDuetPostureViewController prepareForImageDataWithFolderPath:imageFolderPath];
        [self.liveDuetPostureViewController prepareForCameraService:self.cameraService];

        IESEffectModel *localSticker = self.viewModel.inputData.localSticker;
        if (localSticker) {
            if (!self.viewModel.inputData.publishModel.repoReshoot.isReshoot) {
                self.viewModel.inputData.publishModel.repoProp.localPropId = !ACC_isEmptyString(localSticker.effectIdentifier) ? localSticker.effectIdentifier : @"";
            }
            [self.liveDuetPostureViewController updateRenderImageKeyWithEffectModel:localSticker];
            [self.liveDuetPostureViewController renderPicImageWithIndex:self.viewModel.inputData.publishModel.repoProp.selectedLiveDuetImageIndex];
        }
    }

    [self.propService addSubscriber:self];
}

- (void)componentDidAppear
{
    if ([self shouldShowLiveDuetPostureViewController]) {
        IESEffectModel *localSticker = self.viewModel.inputData.localSticker;
        if (localSticker) {
            self.stickerPickerController.model.currentSticker = localSticker;
            self.stickerPickerController.model.stickerWillSelect = localSticker;
            [self.liveDuetPostureViewController updateRenderImageKeyWithEffectModel:localSticker];
            [self.liveDuetPostureViewController renderPicImageWithIndex:self.viewModel.inputData.publishModel.repoProp.selectedLiveDuetImageIndex];
        }
    }
}

- (void)componentDidDisappear
{
    if (self.stickerPickerController != nil) {
        self.stickerPickerController.model.stickerWillSelect = nil;
    }
}

#pragma mark - Public
- (void)addDataContainerCreateBlock:(AWEStickerDataContainerCreator)block __attribute__((annotate("csa_ignore_block_use_check")))
{
    if (!self.stickerDataSource) {
        if (!self.dataSourceCreatorBlocks) {
            self.dataSourceCreatorBlocks = [NSMutableArray array];
        }
        [self.dataSourceCreatorBlocks acc_addObject:block];
    }
}

#pragma mark - Private

- (void)p_bindViewModels {
    @weakify(self);

    [[self.authService.passCheckAuthSignal deliverOnMainThread] subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        [self p_showPanelForLocalStickerIfNeeded];
    }];

    [[[self selectPropViewModel].clickSelectPropBtnSignal takeUntil:[self rac_willDeallocSignal]].deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self showPanel];
    }];
    ACCPropPickerViewModel *propPickerViewModel = [self getViewModel:[ACCPropPickerViewModel class]];
    [[[propPickerViewModel.showPanelSignal takeUntil:self.rac_willDeallocSignal] deliverOnMainThread] subscribeNext:^(NSString * _Nullable x) {
        @strongify(self);
        [self showPanel];
        if ([x isEqual:@"favor"]) {
            AWEStickerCategoryModel *favorCategory = [self.stickerPickerController.model.stickerCategoryModels acc_match:^BOOL(AWEStickerCategoryModel * _Nonnull item) {
                return item.favorite;
            }];
            [self.stickerPickerController.panelView selectTabWithCategory:favorCategory];
        } else if ([x isEqual:@"hot"]) {
            AWEStickerCategoryModel *category = [self.stickerPickerController.model.stickerCategoryModels acc_match:^BOOL(AWEStickerCategoryModel * _Nonnull item) {
                return !item.favorite && !item.isSearch;
            }];
            [self.stickerPickerController.panelView selectTabWithCategory:category];
        }
    }];
    [[[propPickerViewModel.exposePanelPropSelectionSignal takeUntil:self.rac_willDeallocSignal] deliverOnMainThread] subscribeNext:^(IESEffectModel * _Nullable x) {
        @strongify(self);
        [self applyExposePanelPropSelection:x];
    }];

    [[self viewModel].shouldUpdatePickerStickerSignal.deliverOnMainThread subscribeNext:^(IESEffectModel * _Nullable x) {
        @strongify(self);
        self.stickerPickerController.model.currentSticker = x;
    }];
}

/**
 加载要前插到热门分类的道具
 Fetch stickers with stickerIds if exists. The fetched stickers will insert into hot tab in the sticker panel.
 */
- (void)p_fetchPrioritizedStickers {
    NSArray *prioritizedStickerIds = self.viewModel.inputData.prioritizedStickerIds;
    if (prioritizedStickerIds.count > 0) {
        @weakify(self);
        [EffectPlatform downloadEffectListWithEffectIDS:prioritizedStickerIds
                                             completion:^(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects) {
            @strongify(self);
            if (error) {
                AWELogToolError(AWELogToolTagRecord, @"p_fetchPrioritizedStickers error: %@", error);
                return;
            }
            if (!effects) { return; }
            self.viewModel.inputData.prioritizedStickers = effects;
        }];
    }
}

- (NSMutableDictionary *)downloadStickerStartTimeDictionary
{
    if (_downloadStickerStartTimeDictionary == nil) {
        _downloadStickerStartTimeDictionary = [[NSMutableDictionary alloc] init];
    }

    return _downloadStickerStartTimeDictionary;
}

- (NSMutableDictionary *)downloadStickerListStartTimeDictionary
{
    if (_downloadStickerListStartTimeDictionary == nil) {
        _downloadStickerListStartTimeDictionary = [[NSMutableDictionary alloc] init];
    }

    return _downloadStickerListStartTimeDictionary;
}

- (BOOL)p_shouldApplyProp:(IESEffectModel *)prop
{
    NSError *error = nil;
    BOOL shouldApply = [self.viewModel.groupedPredicate shouldApplySticker:prop error:&error];
    if (error) {
        AWELogToolError(AWELogToolTagRecord, @"Prop doesn't support current ratio %@", error);
    }
    if (!shouldApply && error.localizedDescription.length > 0) {
        NSString *errorToast = error.localizedDescription;
        [ACCToast() showError:errorToast];
    }
    
    return shouldApply;
}

- (void)p_showPanelForLocalStickerIfNeeded
{
    BOOL hasAuth = self.cameraService.cameraHasInit && ([ACCDeviceAuth currentAuthType] & ACCRecordAuthComponentMicAuthed);
    BOOL shouldShowPanel = ![self shouldShowLiveDuetPostureViewController];

    if (hasAuth && shouldShowPanel) {
        // [DMT] 有相册托盘的道具，打开相机后自动展开面板 // Auto expand effect tab and tray for customizable effects (like Green Screen) and effects in albums
        // https://bytedance.feishu.cn/docs/doccnqjb7giNSXHXhUzx8O8PYmT
        IESEffectModel *localSticker = self.viewModel.inputData.localSticker;
        self.viewModel.inputData.publishModel.repoProp.localPropId = !ACC_isEmptyString(localSticker.effectIdentifier) ? localSticker.effectIdentifier : @"";
        if ([localSticker isPixaloopSticker] ||
            [localSticker isVideoBGPixaloopSticker] ||
            localSticker.parentEffectID.length > 0) {
            [self showPanel];
        }
    }
}

- (void)p_resetCurrentStickerIfNeed:(IESEffectModel *)prop
{
    if (prop == nil && self.stickerPickerController.model.currentChildSticker != nil) {
        self.needRestoredParentProp = self.stickerPickerController.model.currentSticker;
    }
    if ([prop.parentEffectID isEqualToString:self.needRestoredParentProp.effectIdentifier]) {
        prop = self.needRestoredParentProp;
        self.needRestoredParentProp = nil;
    }
    
    self.stickerPickerController.model.currentSticker = prop;
}

#pragma mark - Getter
- (ACCGroupedPredicate *)skipCategoryPredicate
{
    if (!_skipCategoryPredicate) {
        _skipCategoryPredicate = [[ACCGroupedPredicate alloc] initWithOperand:ACCGroupedPredicateOperandOr];
    }
    return _skipCategoryPredicate;
}

- (ACCGroupedPredicate *)skipStickerPredicate
{
    if (!_skipStickerPredicate) {
        _skipStickerPredicate = [[ACCGroupedPredicate alloc] initWithOperand:ACCGroupedPredicateOperandOr];
    }
    return _skipStickerPredicate;
}

#pragma mark - ACCRouterServiceSubscriber

- (ACCEditViewControllerInputData *)processedTargetVCInputDataFromData:(ACCEditViewControllerInputData *)data
{
    for (AWEVideoFragmentInfo *fragmentInfo in self.repository.repoVideoInfo.fragmentInfo) {
        if (fragmentInfo.appliedUseOutputProp) {
            data.publishModel.repoVideoInfo.videoMuted = NO;
            break;
        }
    }
    
    [self p_setupFlowerEditPropAwardWhenFinishRecordIfNeedWithPublishModel:data.publishModel];
    
    return data;
}

- (void)p_setupFlowerEditPropAwardWhenFinishRecordIfNeedWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    if (![ACCFlowerCampaignManager() isFlowerAwardActivityOn] ||
        ![publishModel isKindOfClass:[AWEVideoPublishViewModel class]]) {
        return;
    }
    
    ACCFLOActivityStageType stageType = [ACCFlowerCampaignManager() getCurrentActivityStage];

    NSArray <NSString *> *flowerActivityPropList = [self p_flowerAwardPropListWithIsForGroot:NO publishModel:publishModel];
    
    NSArray <NSString *> *grootPropList = nil;
    // 只有活动期才有识别奖励活动
    if (stageType == ACCFLOActivityStageTypeLuckyCard) {
        grootPropList = [self p_flowerAwardPropListWithIsForGroot:YES publishModel:publishModel];
    }

    let flowerService = IESAutoInline(self.serviceProvider, ACCFlowerService);
    if (ACC_isEmptyArray(flowerActivityPropList) && ACC_isEmptyArray(grootPropList) && !flowerService.isShowingPhotoProp) {
        return;
    }
    
    BOOL hasGrootProp = !ACC_isEmptyArray(grootPropList);
    
    NSString *awardEnterFrom = nil;
    
    if (stageType == ACCFLOActivityStageTypeAppointment) {
        awardEnterFrom = @"reserve";
    } else if (stageType == ACCFLOActivityStageTypeLuckyCard) {
        if (hasGrootProp) {
            awardEnterFrom = @"groot";
        } else if (flowerService.isShowingPhotoProp) {
            awardEnterFrom = @"photo";
        } else {
            awardEnterFrom = @"sticker";
        }
    }
    
    if (!ACC_isEmptyString(awardEnterFrom)) {
        publishModel.repoContext.flowerEditActivityEnterFrom = [awardEnterFrom stringByAppendingString:@"_edit"];
        publishModel.repoContext.flowerPublishActivityEnterFrom = [awardEnterFrom stringByAppendingString:@"_publish"];
        publishModel.repoContext.flowerActivityProps = hasGrootProp?grootPropList:flowerActivityPropList;
    }
    
    [ACCFlowerCampaignManager() logFlowerInfo:[NSString stringWithFormat:@"[activity award]did bind flower activity props award, enter from is:%@", awardEnterFrom]];
}

#pragma mark - private

- (NSArray <NSString *> *)p_flowerAwardPropListWithIsForGroot:(BOOL)isForGroot
                                                 publishModel:(AWEVideoPublishViewModel *)publishModel
{
    NSMutableArray <NSString *> *ret = [NSMutableArray array];
    
    if (publishModel.repoContext.isPhoto) {
        
        AWERecordInformationRepoModel *repoRecordInfo =  publishModel.repoRecordInfo;
        
        NSString *propID = repoRecordInfo.pictureToVideoInfo.propID;
        if (!ACC_isEmptyString(propID)) {
            
            if ((isForGroot && repoRecordInfo.pictureToVideoInfo.hasSmartScanSticker) ||
                (!isForGroot && repoRecordInfo.pictureToVideoInfo.hasFlowerActivitySticker)) {
                
                [ret addObject:propID];
            }
        }
    } else {
        
        [publishModel.repoRecordInfo.fragmentInfo.copy enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *propID = obj.stickerId;
            if (!ACC_isEmptyString(propID)&&
                ![ret containsObject:propID]) {
                
                if ((isForGroot && obj.hasSmartScanSticker) ||
                    (!isForGroot && obj.hasFlowerActivitySticker)) {
                    
                    [ret addObject:propID];
                }
            }
        }];
    }

    return [ret copy];
}

#pragma mark - Panel

/**
 Show sticker panel.
 */
- (void)showPanel
{
    if ([self shouldShowLiveDuetPostureViewController]) {
        @weakify(self);
        [self.liveDuetPostureViewController showOnView:self.controller.root.view animated:YES completion:^{
            @strongify(self);
            [self.viewContainer showItems:NO animated:YES];
        }];
    } else {
        [self.viewModel monitorStartStickerPanelLoadingDuration];
        if (self.hasShowPanelBefore) {
            [self.viewModel monitorCancelStickerPanelLoadingDuration];
        }

        if ([self viewModel].propPanelStatus == ACCPropPanelDisplayStatusShow) {
            return;
        }

        [self.viewModel sendSignal_propPanelDisplayStatus:ACCPropPanelDisplayStatusShow];
        self.viewContainer.isShowingPanel = YES;
        @weakify(self);
        [self.stickerPickerController showOnView:self.controller.root.view animated:YES completion:^{
            @strongify(self);
            self.hasShowPanelBefore = YES;
            [self.viewContainer showItems:NO animated:YES];
        }];
        [self.propService didShowPropPanel:self.stickerPickerController.panelView];
    }
}

/**
 Dismiss sticker panel
 */
- (void)dismissPanelWithTrackKey:(NSString *)trackKey
{
    @weakify(self);
    [self.stickerPickerController dismissAnimated:YES completion:^{
        @strongify(self);
        [self.viewModel sendSignal_propPanelDisplayStatus:ACCPropPanelDisplayStatusDismiss];
        self.viewContainer.isShowingPanel = NO;
        [self.viewContainer showItems:YES animated:YES];
        [self.propService didDismissPropPanel:self.stickerPickerController.panelView];
    }];

    self.dismissTrackStr = trackKey;
    [self.viewModel trackStickerPanelLoadPerformanceWithStatus:2 isLoading:self.stickerPickerController.model.isLoading dismissTrackStr:self.dismissTrackStr];
    [self.viewModel trackComfirmPropSettingEvent];
    [self.viewModel trackUserCancelUseSticker];
}

/**
 Lazy create a panel.
 */
- (AWEStickerPickerController *)stickerPickerController
{
    if (nil == _stickerPickerController) {
        NSMutableArray<id<AWEStickerPickerControllerPluginProtocol>> *plugins = [[NSMutableArray alloc] init];
        
        AWEStickerPickerControllerFavoritePlugin *favoritePlugin = [[AWEStickerPickerControllerFavoritePlugin alloc] init];
        favoritePlugin.trackingInfoDictionary = [self.viewModel trackingInfoDictionary];
        [plugins acc_addObject:favoritePlugin]; // 收藏插件

        AWEStickerPickerControllerCollectionStickerPlugin *collectionStickerPlugin = [[AWEStickerPickerControllerCollectionStickerPlugin alloc] init];
        @weakify(self);
        collectionStickerPlugin.trackingInfoDictionaryBlock = ^NSDictionary * _Nullable {
            @strongify(self);
            NSMutableDictionary *trackingInfoDictionary = [NSMutableDictionary dictionaryWithDictionary:[self.viewModel trackingInfoDictionary]];
            NSString *fromPropID = self.viewModel.inputData.publishModel.repoProp.localPropId;
            if (!ACC_isEmptyString(fromPropID)) {
                trackingInfoDictionary[@"from_prop_id"] = fromPropID;
            }
            NSString *musicID = self.viewModel.inputData.publishModel.repoMusic.music.musicID;
            if (!ACC_isEmptyString(musicID)) {
                trackingInfoDictionary[@"music_id"] = musicID;
            }

            NSString *selectedCategoryName = self.stickerPickerController.model.currentCategoryModel.categoryName;
            NSString *currentPropSelectFrom = @"";
            if (!ACC_isEmptyString(selectedCategoryName)) {
                currentPropSelectFrom = [NSString stringWithFormat:@"prop_panel_%@", selectedCategoryName];
            }
            trackingInfoDictionary[@"prop_selected_from"] = currentPropSelectFrom;
            return trackingInfoDictionary;
        };
        collectionStickerPlugin.didSelectStickerBlock = ^(IESEffectModel * _Nullable sticker, ACCRecordPropChangeReason byReason) {
            @strongify(self);
            [self.propService applyProp:sticker propSource:ACCPropSourceCollection byReason:byReason];
        };
        collectionStickerPlugin.cameraServiceBlock = ^id<ACCCameraService> _Nonnull{
            @strongify(self);
            return self.cameraService;
        };

        [plugins acc_addObject:collectionStickerPlugin]; // 聚合道具插件
        [plugins acc_addObject:[[AWEStickerPickerControllerSchemaStickerPlugin alloc] init]]; // scheme道具插件
        [plugins acc_addObject:[[AWEStickerPickerControllerSwitchCameraPlugin alloc] initWithServiceProvider:self.serviceProvider]]; // 切换摄像头插件
        
        // 获取其他插件
        id<ACCStickerControllerPluginFactoryTemplate> template = IESAutoInline(self.serviceProvider, ACCStickerControllerPluginFactoryTemplate);
        template.component = self;
        NSArray<Class<ACCStickerControllerPluginFactory>> *pluginFactories = [template pluginFactoryClasses];
        NSMutableArray *aPlugins = [NSMutableArray array];
        for (Class<ACCStickerControllerPluginFactory> aClass in pluginFactories) {
            if ([aClass conformsToProtocol:@protocol(ACCStickerControllerPluginFactory)]) {
                id<AWEStickerPickerControllerPluginProtocol> plugin = [aClass pluginWithCompoent:self];
                [aPlugins acc_addObject:plugin];
            }
        }
        
        [plugins acc_addObjectsFromArray:aPlugins];
        
        // 安全合规 - 选中道具增加安全提示
        AWEStickerPickerControllerSecurityTipsPlugin *securityTipsPlugin = [[AWEStickerPickerControllerSecurityTipsPlugin alloc] init];
        [plugins addObject:securityTipsPlugin];
        
        // 熟人社交 - 道具面板增加大家都在拍入口 @hongcheng
        // 当 A/B Testing sticker_to_feed_enable 开启时，添加插件入口。
        AWEStickerPickerControllerShowcaseEntrancePlugin *showcaseEntrancePlugin = nil;
        if ([IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) isStickerShowcaseEntranceEnabled]) {
            showcaseEntrancePlugin = [[AWEStickerPickerControllerShowcaseEntrancePlugin alloc] init];
            showcaseEntrancePlugin.getCreationId = ^NSString * _Nonnull{
                @strongify(self);
                return self.viewModel.inputData.publishModel.repoContext.createId;
            };
            [plugins acc_addObject:showcaseEntrancePlugin];
        }
        
        ACCInsertRecommendPropToHotFirstBlock insertPropBlock = ^(IESEffectModel * _Nonnull effectModel) {
            @strongify(self);
            if (effectModel) {
                [self.stickerDataSource insertPrioritizedStickers:@[effectModel]];
            }
        };
        AWEStickerPickerControllerMusicPropBubblePlugin *musicPropBubblePlugin = [[AWEStickerPickerControllerMusicPropBubblePlugin alloc] initWithViewModel:self.viewModel selectPropViewModel:[self selectPropViewModel] viewContainer:self.viewContainer insertRecommendPropTopBlock:insertPropBlock];
        [plugins acc_addObject:musicPropBubblePlugin];
        
        // duet with prop bubble
        void (^additionalApplyPropBlock)(IESEffectModel *) = ^(IESEffectModel *prop){
            @strongify(self);
            if ([prop isPixaloopSticker] ||
                [prop isVideoBGPixaloopSticker] ||
                prop.parentEffectID.length > 0) { // prop with trap, show panel
                if (prop.parentEffectID.length > 0) {
                    self.stickerPickerController.model.currentChildSticker = prop;
                    self.stickerPickerController.model.currentSticker = self.viewModel.inputData.prioritizedStickers.firstObject;
                } else {
                    self.stickerPickerController.model.currentSticker = prop;
                }
                [self.selectPropViewModel sendSignalAfterClickSelectPropBtn];
            } else { // normal prop
                self.stickerPickerController.model.stickerWillSelect = prop;
                if ([self.stickerPickerController.delegate respondsToSelector:@selector(stickerPickerController:didSelectSticker:)]) {
                    [self.stickerPickerController.delegate stickerPickerController:self.stickerPickerController didSelectSticker:prop];
                }
                self.stickerPickerController.model.currentSticker = prop;
            }
        };
        
        AWEStickerPickerControllerDuetPropBubblePlugin *duetWithPropBubblePlugin = [[AWEStickerPickerControllerDuetPropBubblePlugin alloc] initWithViewModel:self.viewModel bubbleEffect:self.viewModel.inputData.duetDefaultSticker viewContainer:self.viewContainer];
        duetWithPropBubblePlugin.additionalApplyPropBlock = additionalApplyPropBlock;
        
        [plugins acc_addObject:duetWithPropBubblePlugin];

        IESEffectModel *currentSticker = nil;
        IESEffectModel *currentChildSticker = nil;
        IESEffectModel *localSticker = self.viewModel.inputData.localSticker;
        NSArray<IESEffectModel *> *prioritizedStickers = self.viewModel.inputData.prioritizedStickers;
        if (localSticker.parentEffectID.length > 0) {
            currentSticker = prioritizedStickers.firstObject;
            currentChildSticker = localSticker;
        } else {
            currentSticker = localSticker;
            currentChildSticker = nil;
        }
        
        self.stickerDataSource = [self createDataSource];
        NSMutableArray *dataContainers = [NSMutableArray array];
        AWEStickerPickerDataContainer *defaultDataContainer = [[AWEStickerPickerDataContainer alloc] init];
        defaultDataContainer.dataHanleQueue = self.stickerDataSource.dataHanleQueue;
        [dataContainers acc_addObject:defaultDataContainer];
        if (self.dataSourceCreatorBlocks) {
            for (AWEStickerDataContainerCreator creator in self.dataSourceCreatorBlocks) {
                id<AWEStickerPickerDataContainerProtocol> dataContainer = creator(self.stickerDataSource);
                [dataContainers acc_addObject:dataContainer];
            }
            self.dataSourceCreatorBlocks = nil;
        }
        [self.stickerDataSource setupDataContainers:dataContainers];
        [self.stickerDataSource useDataContainer:@"default"];
        
        [self.stickerDataSource insertPrioritizedStickers:prioritizedStickers];
        AWEStickerPickerDefaultUIConfiguration *style = [self createStickerPickerConfig];
        NSString *panelName = [self p_getEffectCamPanelName];
        _stickerPickerController = [[AWEStickerPickerController alloc] initWithPanelName:panelName
                                                                                UIConfig:style
                                                                          currentSticker:currentSticker
                                                                     currentChildSticker:currentChildSticker
                                                                                 plugins:plugins.copy];
        _stickerPickerController.isOnRecordingPage = !self.viewModel.inputData.publishModel.repoContext.isIMRecord;
        [self propService].propPickerViewController = _stickerPickerController;
        [self propService].propPickerDataSource = self.stickerDataSource;
        _stickerPickerController.delegate = self;
        _stickerPickerController.dataSource = self.stickerDataSource;
        _stickerPickerController.favoriteTabIndex = 0;
        self.stickerDataSource.needFavorite = YES;

        if (!self.viewModel.inputData.publishModel.repoContext.isIMRecord && [self shouldSupportSearchFeature] == ACCPropPanelSearchEntranceTypeTab) {
            _stickerPickerController.favoriteTabIndex = 1;
        }

        _stickerPickerController.defaultTabSelectedIndex = _stickerPickerController.favoriteTabIndex + (self.stickerDataSource.needFavorite ? 1 : 0);
        favoritePlugin.layoutManager = _stickerPickerController;
        collectionStickerPlugin.layoutManager = _stickerPickerController;
        showcaseEntrancePlugin.layoutManager = _stickerPickerController;
        
        securityTipsPlugin.layoutManager = _stickerPickerController;
        
        [self createExplorePlugin:_stickerPickerController];
    }
    
    return _stickerPickerController;
}

- (void)createExplorePlugin:(nonnull AWEStickerPickerController * )stickerPickerController {
    if (ACCConfigInt(kConfigInt_sticker_explore_type) != ACCPropPanelExploreTypeNone
        && [self.viewModel.repository.repoTrack.referString isEqualToString:@"direct_shoot"]) {
        AWEStickerPickerControllerExploreStickerPlugin *explorePlugin;
        explorePlugin = [[AWEStickerPickerControllerExploreStickerPlugin alloc] initWithServiceProvider:self.serviceProvider viewModel:self.viewModel];
        explorePlugin.layoutManager = stickerPickerController;
        
        [stickerPickerController insertPlugin:explorePlugin];
    }
}

- (NSString *)p_getEffectCamPanelName
{
    id<ACCPropConfigProtocol> propConfig = IESOptionalInline(self.serviceProvider, ACCPropConfigProtocol);
    if (!ACC_isEmptyString([propConfig stickerPickerPanelName])) {
        return [propConfig stickerPickerPanelName];
    }
    NSString *panelName = kAWEEffectStickerPanelName;
    if(ACCConfigBool(kConfigBool_use_effect_cam_key)){
        ACCStickerSortOption stickerOption = ACCConfigEnum(kConfigInt_effect_stickers_panel_option, ACCStickerSortOption);
        switch (stickerOption) {
            case ACCStickerSortOptionRD:
                panelName = @"record-effect-rd";
                break;
            case ACCStickerSortOptionIntegration:
                panelName = @"record-effect-integration-test";
                break;
            case ACCStickerSortOptionAmaizing:
                panelName = @"record-effect-amazing-engine";
                break;
            case ACCStickerSortOptionCreator:
                panelName = @"record-effect-creator-test";
                break;
            default:
                break;
        }
    }
    return panelName;
}

- (AWEStickerPicckerDataSource *)createDataSource {
    AWEStickerPicckerDataSource *dataSource = [[AWEStickerPicckerDataSource alloc] init];
    
    @weakify(self);
    dataSource.tabSizeUpdateHandler = ^(NSInteger tabIndex) {
        @strongify(self);
        [self.stickerPickerController reloadData];
    };

    // 搜索功能需要屏蔽IM
    dataSource.isOnRecordingPage = !self.viewModel.inputData.publishModel.repoContext.isIMRecord;

    BOOL enableMultiSegProp = ACCConfigBool(kConfigBool_enable_multi_seg_prop);
    dataSource.stickerFilterBlock = ^BOOL(IESEffectModel * _Nonnull sticker, AWEStickerCategoryModel * _Nonnull category) {
        @strongify(self);
        // 商业化贴纸过滤
        // 如果开启了过滤商业化道具开关（filterBusiness），那么过滤不显示所有的商业化道具（localSticker除外）
        if (self.viewModel.inputData.filterBusiness &&
            sticker.isCommerce &&
            ![sticker.effectIdentifier isEqualToString:self.viewModel.inputData.localSticker.effectIdentifier]) {
            return NO;
        }
        
        // 多段道具的显示
        AWEVideoPublishViewModel *publishViewModel = self.viewModel.inputData.publishModel;
        
        BOOL shouldNotShowMultiSegProp = !enableMultiSegProp ||
            publishViewModel.repoDuet.isDuet ||
            publishViewModel.repoContext.isIMRecord ||
            publishViewModel.repoReshoot.isReshoot ||
            ![self.switchModeService containsModeWithId:ACCRecordModeCombined];
        if (shouldNotShowMultiSegProp && sticker.isMultiSegProp) {
            return NO;
        }

        if ([[[self viewModel] shouldFilterProp] evaluateWithObject:sticker]) {
            return NO;
        }
        
        // 根据 needFilterStickerType 过滤道具面板
        AWEStickerFilterType needFilterStickerType = 0;
        if (publishViewModel.repoDuet.isDuet) {
            needFilterStickerType = AWEStickerFilterTypeGame & self.viewModel.inputData.needsFilterStickerType;
        } else {
            needFilterStickerType = self.viewModel.inputData.needsFilterStickerType;
        }
        if ((needFilterStickerType & AWEStickerFilterTypeGame) && ([sticker gameType] != ACCGameTypeNone)) {
            return NO;
        }

        // 道具面板过滤规则
        if (publishViewModel.repoDuet.isDuet) {
            if ([sticker acc_isTC21Redpacket]) { return NO; }
            if ([sticker isVideoBGPixaloopSticker]) { return NO; }
            if ([sticker isTypeMusicBeat]) { return NO; }
            if ([sticker acc_isTypeSlowMotion]) { return NO; }
            if ([sticker isTypeVoiceRecognization]) { return NO; }
            if (sticker.isMultiSegProp) { return NO; }
            if ([sticker.tags containsObject:@"audio_effect"]) { return NO; }
            if ([sticker.tags containsObject:@"forbid_for_all_duet"]) { return NO; }
        } else if (publishViewModel.repoReshoot.isReshoot) {
            if ([sticker isVideoBGPixaloopSticker]) { return NO; }
            if ([sticker isEffectControlGame]) { return NO; }
        }
        
        //极速版收藏、热门 tab 需要过滤掉红包道具
        BOOL skipSticker = [self.skipStickerPredicate evaluateWithObject:[RACTwoTuple pack:sticker :category]];
        if (skipSticker) {
            return NO;
        }
        
        // 在IM场景下过滤自动切多段拍摄类道具的展示
        if ([[[sticker.sdkExtra acc_jsonDictionary] allKeys] containsObject:@"prior_record_multi_segment"] &&
            self.viewModel.inputData.publishModel.repoContext.isIMRecord) {
            return NO;
        }
        
        if ([sticker isFlowerBooking]) { return NO; }
        
        return YES;
    };
    
    dataSource.stickerCategoryFilterBlock = ^BOOL(AWEStickerCategoryModel *category) {
        @strongify(self);
        if ([self.skipCategoryPredicate evaluateWithObject:category]) {
            return NO;
        }
        return YES;
    };
    
    return dataSource;
}

- (AWEStickerPickerDefaultUIConfiguration *)createStickerPickerConfig {
    // 道具面板样式
    AWEStickerPickerDefaultEffectUIConfiguration *effectConfig = [[AWEStickerPickerDefaultEffectUIConfiguration alloc] init];
    AWEStickerPickerDefaultCategoryUIConfiguration *categoryConfig = [[AWEStickerPickerDefaultCategoryUIConfiguration alloc] init];
    @weakify(self);
    categoryConfig.layoutHandler = ^CGSize(NSIndexPath * _Nonnull indexPath) {
        @strongify(self);
        return [self.stickerDataSource cellSizeForTabIndex:indexPath.item];
    };
    AWEStickerPickerDefaultUIConfiguration *style = [[AWEStickerPickerDefaultUIConfiguration alloc] initWithCategoryUIConfig:categoryConfig
                                                                                                              effectUIConfig:effectConfig];

    
    style.categoryReloadHanlder = ^{
        AWELogToolInfo(AWELogToolTagNone, @"reload category");
        @strongify(self);
        [self.stickerPickerController loadStickerCategory];
    };
    return style;
}

#pragma mark - AWEStickerPickerControllerDelegate

- (void)stickerPickerControllerDidTapDismissBackgroundView:(AWEStickerPickerController *)stickerPickerController
{
    [self dismissPanelWithTrackKey:@"clickClearBackground"];
}

- (void)stickerPickerControllerDidBeginLoadCategories:(AWEStickerPickerController *)stickerPickerController
{
    self.downloadCategoriesStartTime = @(CFAbsoluteTimeGetCurrent());
}

- (void)stickerPickerControllerDidFinishLoadCategories:(AWEStickerPickerController *)stickerPickerController {

    if ([self shouldShowLiveDuetPostureViewController]) {
        return;
    }

    // 查找热门分类tab，用热门分类下的第一个道具的icon显示在道具入口
    // Set the first sticker's icon at the enterance of the sticker panel.
    
    __block AWEDouyinStickerCategoryModel *hotCategoryModel = nil;
    [self.stickerDataSource.categoryArray enumerateObjectsUsingBlock:^(AWEDouyinStickerCategoryModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isHotTab]) {
            hotCategoryModel = obj;
            *stop = YES;
        }
    }];
    
    BOOL shouldShowMusicRecommendPropBubble = [[AWERecorderTipsAndBubbleManager shareInstance] shouldShowMusicRecommendPropBubbleWithInputData:self.viewModel.inputData isShowingPanel:self.viewContainer.isShowingPanel];
    IESEffectModel *firstSticker = hotCategoryModel.stickers.firstObject;
    if (firstSticker && !shouldShowMusicRecommendPropBubble) {
        [[self viewModel] sendSignal_didFinishLoadEffectListWithFirstHotSticker:firstSticker];
    }

    if (stickerPickerController.model.stickerCategoryModels.count > 0
        && self.downloadCategoriesStartTime != nil) {
        CFTimeInterval startTime = [self.downloadCategoriesStartTime doubleValue];

        if (AWEStickerCategoryListLoadModeNormal == self.stickerPickerController.model.stickerCategoryListLoadMode) {
            [[AWEStudioMeasureManager sharedMeasureManager] asyncMonitorTrackService:@"aweme_effect_list_error" status:0 extra:@{
                @"panel" : kAWEEffectStickerPanelName,
                @"panelType" : @(AWEStickerPanelTypeRecord),
                @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                @"needUpdate" : @(YES),
            }];
        }

        [self.viewModel trackToolPerformanceAPIWithType:@"effect_category_list"
                                               duration:(CFAbsoluteTimeGetCurrent() - startTime) * 1000
                                                  error:nil];
    }
}

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController didFailLoadCategoriesWithError:(NSError *)error
{
    if (error) {
        AWELogToolError(AWELogToolTagRecord, @"didFailLoadCategoriesWithError error: %@", error);
    }
    
    if (error != nil && self.downloadCategoriesStartTime != nil) {
        [self.viewModel trackStickerPanelLoadPerformanceWithStatus:1 isLoading:self.stickerPickerController.model.isLoading dismissTrackStr:self.dismissTrackStr];

        CFTimeInterval startTime = [self.downloadCategoriesStartTime doubleValue];
        if (AWEStickerCategoryListLoadModeNormal == self.stickerPickerController.model.stickerCategoryListLoadMode) {
            [[AWEStudioMeasureManager sharedMeasureManager] asyncMonitorTrackService:@"aweme_effect_list_error" status:0 extra:@{
                @"panel" : kAWEEffectStickerPanelName,
                @"panelType" : @(AWEStickerPanelTypeRecord),
                @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                @"needUpdate" : @(YES),
            }];
        }

        [self.viewModel trackToolPerformanceAPIWithType:@"effect_category_list"
                                               duration:(CFAbsoluteTimeGetCurrent() - startTime) * 1000
                                                  error:error];
    }
}

- (void)stickerPickerControllerDidTapClearStickerButton:(AWEStickerPickerController *)stickerPickerController
{
    [self.viewModel trackClickPropTabEventWithCategoryName:@"none"
                                                     value:@""
                                               isPhotoMode:self.switchModeService.currentRecordMode.isPhoto
                                               isThemeMode:self.themeService.isThemeRecordMode && self.themeService.isVideoCaptureState];
}

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController didSelectCategory:(AWEStickerCategoryModel *)category
{
    // 记录当前选中的道具分类信息：key和名称，埋点使用
    self.propService.categoryKey = category.categoryKey;
    self.propService.categoryName = category.categoryName;
    self.propService.favorite = category.favorite;
    
    [self.viewModel trackClickPropTabEventWithCategoryName:category.categoryName
                                                     value:category.favorite ? @"1" : (category.categoryIdentifier ?: @"")
                                               isPhotoMode:self.switchModeService.currentRecordMode.isPhoto
                                               isThemeMode:self.themeService.isThemeRecordMode && self.themeService.isVideoCaptureState];
}

/**
 返回是否允许选中道具，如果不允许选中，弹出 toast 提示。
 return if the sticker can be selected.
 */
- (BOOL)stickerPickerController:(AWEStickerPickerController *)stickerPickerControlelr shouldSelectSticker:(IESEffectModel *)sticker
{
    return [self p_shouldApplyProp:sticker];
}

- (BOOL)stickerPickerControllerShouldApplyFirstHotSticker:(AWEStickerPickerController *)stickerPickerControlelr
{
    // 从加号进入，首次点击道具入口，默认应用热门第1位道具
    if (!ACCConfigBool(kConfigBool_tools_auto_apply_first_hot_prop)) {
        return NO;
    }
    
    if (!self.propService.repository.repoTrack.isClickPlus) {
        return NO;
    }
    
    if (self.hasAppliedFirstHotProp) {
        return NO;
    }
    
    if (self.propService.prop != nil) {
        return NO;
    }
     
    self.hasAppliedFirstHotProp = YES;
    return YES;
}

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController
              willSelectSticker:(IESEffectModel *)sticker
                   willDownload:(BOOL)willDownload
               additionalParams:(NSMutableDictionary *)additionalParams
{
    /// @description: 收敛道具propSelectedFrom字段赋值逻辑，来源分为搜索/道具Tab
    if ([additionalParams acc_objectForKey:@"search_method"]) {
        NSString *searchMethod = [additionalParams acc_objectForKey:@"search_method"];
        if (!ACC_isEmptyString(searchMethod)) {
            sticker.propSelectedFrom = [NSString stringWithFormat:@"prop_%@", searchMethod];
        }
    }else{
        sticker.propSelectedFrom = [NSString stringWithFormat:@"prop_panel_%@", self.stickerPickerController.model.currentCategoryModel.categoryName ?: @""];
    }

    // Track
    self.propService.isAutoUseProp = [additionalParams acc_boolValueForKey:@"is_auto"];
    [self.viewModel trackUserDidTapSticker:sticker];
    [self.viewModel trackPropClickEventWithCameraService:self.cameraService
                                                 sticker:sticker
                                            categoryName:stickerPickerController.model.currentCategoryModel.categoryName
                                             atIndexPath:[stickerPickerController currentStickerIndexPath]
                                             isPhotoMode:self.switchModeService.currentRecordMode.isPhoto
                                             isThemeMode:self.themeService.isThemeRecordMode && self.themeService.isVideoCaptureState                                        additionalParams:additionalParams];
}

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerControlelr didBeginDownloadSticker:(IESEffectModel *)sticker
{
    if (!ACC_isEmptyString(sticker.effectIdentifier)) {
        self.downloadStickerStartTimeDictionary[sticker.effectIdentifier] = @(CACurrentMediaTime());
    }
}

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerControlelr didFinishDownloadSticker:(IESEffectModel *)sticker
{
    if (!ACC_isEmptyString(sticker.effectIdentifier)
        && [self.downloadStickerStartTimeDictionary.allKeys containsObject:sticker.effectIdentifier]) {
        [self.viewModel trackDownloadPerformanceWithSticker:sticker
                                          startTime:[self.downloadStickerStartTimeDictionary[sticker.effectIdentifier] doubleValue]
                                            success:YES
                                              error:nil];
        [self.downloadStickerStartTimeDictionary removeObjectForKey:sticker.effectIdentifier];
    }
}

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerControlelr
         didFailDownloadSticker:(IESEffectModel *)sticker
                      withError:(NSError *)error
{
    if (error) {
        AWELogToolError(AWELogToolTagRecord, @"didFailDownloadSticker error: %@", error);
    }
    
    if (!ACC_isEmptyString(sticker.effectIdentifier)
        && [self.downloadStickerStartTimeDictionary.allKeys containsObject:sticker.effectIdentifier]) {
        [self.viewModel trackDownloadPerformanceWithSticker:sticker
                                          startTime:[self.downloadStickerStartTimeDictionary[sticker.effectIdentifier] doubleValue]
                                            success:NO
                                              error:error];
        [self.downloadStickerStartTimeDictionary removeObjectForKey:sticker.effectIdentifier];
    }

    [self.viewModel trackDidFailedDownloadSticker:sticker withError:error];
}

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController didSelectSticker:(IESEffectModel *)sticker
{
    if (![[self viewModel] shouldFilterStickePickerCallback] || [self viewModel].propPanelStatus == ACCPropPanelDisplayStatusShow) {
        [self.propService applyProp:sticker propSource:ACCPropSourceClassic propIndexPath:[stickerPickerController currentStickerIndexPath] byReason:[stickerPickerController currentStickerIndexPath]? ACCRecordPropChangeReasonUserSelect : ACCRecordPropChangeReasonUnkwon];
    }
}

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController didDeselectSticker:(IESEffectModel *)sticker
{
    if (![[self viewModel] shouldFilterStickePickerCallback] || [self viewModel].propPanelStatus == ACCPropPanelDisplayStatusShow) {
        [self.propService applyProp:nil propSource:ACCPropSourceClassic byReason:ACCRecordPropChangeReasonUserCancel];
    }
}

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController
             willDisplaySticker:(IESEffectModel *)sticker
                    atIndexPath:(NSIndexPath *)indexPath
               additionalParams:(NSMutableDictionary *)additionalParams
{
    if (![[self viewModel] shouldFilterStickePickerCallback] || [self viewModel].propPanelStatus == ACCPropPanelDisplayStatusShow) {
        // Track Event
        [self.viewModel trackStickerPanelLoadPerformanceWithStatus:0 isLoading:self.stickerPickerController.model.isLoading dismissTrackStr:self.dismissTrackStr];
        [self.viewModel trackPropShowEventWithSticker:sticker
                                         categoryName:stickerPickerController.model.currentCategoryModel.categoryName
                                          atIndexPath:indexPath
                                          isPhotoMode:self.switchModeService.currentRecordMode.isPhoto
                                     additionalParams:additionalParams];
    }
}

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController didBeginLoadStickersWithCategory:(AWEStickerCategoryModel *)categoryModel
{
    if (!ACC_isEmptyString(categoryModel.categoryKey)) {
        self.downloadStickerListStartTimeDictionary[categoryModel.categoryKey] = @(CFAbsoluteTimeGetCurrent());
    }
}

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController didFinishLoadStickersWithCategory:(AWEStickerCategoryModel *)categoryModel
{
    if ([self.downloadStickerListStartTimeDictionary.allKeys containsObject:categoryModel.categoryKey]) {
        CFTimeInterval startTime = [self.downloadStickerListStartTimeDictionary[categoryModel.categoryKey] doubleValue];
        [self.viewModel monitorTrackServiceEffectListError:nil
                                                 panelName:[kAWEEffectStickerPanelName copy]
                                                  duration:@((CFAbsoluteTimeGetCurrent() - startTime) * 1000)
                                                needUpdate:!categoryModel.isStickerListLoadFromCache];
        if (!categoryModel.isStickerListLoadFromCache) {
            [self.viewModel trackToolPerformanceAPIWithType:@"effect_list"
                                                   duration:(CFAbsoluteTimeGetCurrent() - categoryModel.stickerListStartTime) * 1000
                                                      error:nil];
        }
    }
    if (categoryModel.favorite) {
        ACCPropPickerViewModel *propPickerViewModel = [self getViewModel:[ACCPropPickerViewModel class]];
        [propPickerViewModel sendFavoriteEffectsForRecognitionPanel:categoryModel.stickers];
    }
}

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController
didFailLoadStickersWithCategory:(AWEStickerCategoryModel *)categoryModel
                          error:(NSError *)error
{
    if (error != nil) {
        [self.viewModel monitorTrackServiceEffectListError:error
                                                 panelName:[kAWEEffectStickerPanelName copy]
                                                  duration:@(0)
                                                needUpdate:YES];
        
        //////////////////////////////////////////////////////////////////////////
        ///  @description:
        ///  新道具面板tool_performance_api打点将收藏接口页也包含其中，与旧道具面板有差异
        ///  此处手动将收藏Tab的性能打点切换至effect_favourite_list
        ///  @poc: yuanxin.07
        ///  @date: 2021/May/20
        //////////////////////////////////////////////////////////////////////////
        NSString *toolPerformanceAPIType = @"effect_list";
        if([categoryModel.categoryName isEqualToString:@"收藏"]){
            toolPerformanceAPIType = @"effect_favourite_list";
        }

        [self.viewModel trackToolPerformanceAPIWithType:toolPerformanceAPIType
                                               duration:(CFAbsoluteTimeGetCurrent() - categoryModel.stickerListStartTime) * 1000
                                                  error:error];
    }
}

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController didUpdateStickersWithCategory:(AWEStickerCategoryModel *)categoryModel
{

}

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController trackWithEventName:(NSString *)eventName params:(NSMutableDictionary *)params
{
    // Search Track Event
    params[@"record_mode"] = self.switchModeService.currentRecordMode.trackIdentifier ?: @"";
    [self.viewModel trackSearchWithEventName:eventName params:params];
}

#pragma mark - ViewModels

- (ACCPropViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self getViewModel:ACCPropViewModel.class];
    }
    return _viewModel;
}

- (ACCRecordSelectPropViewModel *)selectPropViewModel {
    ACCRecordSelectPropViewModel *selectPropViewModel = [self getViewModel:ACCRecordSelectPropViewModel.class];
    NSAssert(selectPropViewModel, @"should not be nil");
    return selectPropViewModel;
}

#pragma mark - ACCRecordPropServiceSubscriber

- (BOOL)propServiceShouldApplyProp:(IESEffectModel *)prop propSource:(ACCPropSource)propSource propIndexPath:(NSIndexPath *)propIndexPath
{
    BOOL hasStartRecord = self.cameraService.recorder.recorderState == ACCCameraRecorderStateRecording;
    if (hasStartRecord && prop != nil) {
        return NO;
    }
    
    if (propSource == ACCPropSourceKeepWhenEdit) {
        return YES;
    }
    
    return [self p_shouldApplyProp:prop];
}

- (void)applyExposePanelPropSelection:(IESEffectModel *)prop
{
    if (prop == nil) {
        [self.stickerPickerController.model resetHotTab];
        self.stickerPickerController.model.currentSticker = nil;
    } else {
        AWEStickerCategoryModel *categoryToSelect = nil;
        ACCPropPickerViewModel *propPickerViewModel = [self getViewModel:[ACCPropPickerViewModel class]];
        if (propPickerViewModel.isExposePanelShowFavor) {
            categoryToSelect = [self.stickerPickerController.model.stickerCategoryModels acc_match:^BOOL(AWEStickerCategoryModel * _Nonnull item) {
                return item.favorite;
            }];
            [self.stickerPickerController.model resetHotTab];
            [self.stickerPickerController reloadData];
        } else {
            categoryToSelect = [self.stickerPickerController.model.stickerCategoryModels acc_match:^BOOL(AWEStickerCategoryModel * _Nonnull item) {
                return !item.favorite && !item.isSearch;
            }];
            [self.stickerPickerController.model insertStickersAtHotTab:@[prop]];
        }
        if (categoryToSelect != nil) {
            // 先这样吧，突出了内部设计很多问题；数据驱动UI会更好
            if (self.stickerPickerController.panelView == nil) {
                self.stickerPickerController.defaultTabSelectedIndex = [self.stickerPickerController.model.stickerCategoryModels indexOfObject:categoryToSelect];
            } else {
                [self.stickerPickerController.panelView selectTabWithCategory:categoryToSelect];
            }
        }
        self.stickerPickerController.model.currentSticker = prop;
    }

}

- (void)propServiceRearDidSelectedInsertProps:(NSArray<IESEffectModel *> *)effects
{
    [self.stickerPickerController selectDefaultCategory];
    [self.stickerDataSource insertPrioritizedStickers:effects];
}

- (void)propServiceRearFinishedDownloadProp:(IESEffectModel *)effect parentProp:(IESEffectModel *)parentEffect
{
    self.viewModel.inputData.localSticker = effect;
    self.viewModel.inputData.publishModel.repoProp.localPropId = !ACC_isEmptyString(effect.effectIdentifier) ? effect.effectIdentifier : @"";
    if (parentEffect) {
        // 合集道具
        self.stickerPickerController.model.currentChildSticker = effect;
        self.stickerPickerController.model.currentSticker = parentEffect;
    } else {
        self.stickerPickerController.model.currentSticker = effect;
    }
}

- (void)propServiceWillApplyProp:(IESEffectModel *)prop propSource:(ACCPropSource)propSource
{
    if (ACCPropSourceReset == propSource) {
        [self p_resetCurrentStickerIfNeed:prop];
    } else if ((ACCPropSourceExposed == propSource || ACCPropSourceRecognition == propSource || ACCPropSourceFlower == propSource) && [self viewModel].propPanelStatus != ACCPropPanelDisplayStatusShow) {
        [self applyExposePanelPropSelection:prop];
    }
    
    if (prop == nil) {
        self.propService.isAutoUseProp = NO;
    }

    // @description: 同时命中道具后置下载和新道具面板的情况下，拍同款链路使用绿幕道具/合集道具等
    //               需要自动弹起的类型，额外检查道具面板是否弹起。
    // update: ACCPropSourceRecognition dont need pop up this panel
    // @meego: https://bits.bytedance.net/meego/aweme/issue/detail/2055114#detail
    if (([prop isPixaloopSticker] ||
         [prop isVideoBGPixaloopSticker] ||
         prop.childrenEffects.count > 0 ||
         prop.parentEffectID.length > 0 ||
         [prop isTypeAdaptive]) && [self viewModel].propPanelStatus != ACCPropPanelDisplayStatusShow &&
        /// recognition prop dont need trigger show prop panel
        ![prop.panelName isEqualToString:@"recognition"] && propSource != ACCPropSourceRecognition
        ) {
        [self showPanel];
    }
}

- (void)propServiceDidSelectBgPhoto:(UIImage *)bgPhoto photoSource:(NSString * _Nullable)photoSource
{
    // dismiss prop panel if a valid photo is selected.
    if (bgPhoto != nil) {
        [self dismissPanelWithTrackKey:photoSource];
    }
}

- (void)propServiceDidSelectBgPhotos:(NSArray<UIImage *> *)bgPhotos
{
    if (bgPhotos != nil) {
        [self dismissPanelWithTrackKey:@"ChooseImage"];
    }
}

- (void)propServiceDidSelectBgVideo:(NSURL *)bgVideoURL videoSource:(NSString * _Nullable)videoSource
{
    // dismiss prop panel if a valid video is selected.
    if (bgVideoURL != nil) {
        [self dismissPanelWithTrackKey:videoSource];
    }
}

- (void)propServiceDidEnterGameMode
{
    self.stickerPickerController.view.hidden = YES;
    // 如果道具面板是关闭的，打开道具面板
    if (!self.viewContainer.isShowingPanel) {
        [self showPanel];
    }
}

- (void)propServiceDidExitGameMode
{
    self.stickerPickerController.view.hidden = NO;
    // 如果道具面板是关闭的，打开道具面板
    if (!self.viewContainer.isShowingPanel) {
        [self showPanel];
    }
}

#pragma mark - ACCPropExploreServiceSubscriber

- (void)propExplorePageWillShow {
    [self.stickerPickerController.searchView triggerKeyboardToHide];
}


#pragma mark - AWELiveDuetPostureViewControllerDelegate

- (AWELiveDuetPostureViewController *)liveDuetPostureViewController
{
    if (!_liveDuetPostureViewController) {
        _liveDuetPostureViewController = [[AWELiveDuetPostureViewController alloc] init];
    }
    return _liveDuetPostureViewController;
}

- (void)updateSelectedIndex:(NSInteger)selectedIndex
{
    self.viewModel.inputData.publishModel.repoProp.selectedLiveDuetImageIndex = selectedIndex;
}

- (BOOL)shouldShowLiveDuetPostureViewController
{
    return !ACC_isEmptyString(self.viewModel.inputData.publishModel.repoProp.liveDuetPostureImagesFolderPath);
}

- (void)setLiveDuetPostureViewControllerDismissBlockIfNeeded
{
    if (!self.liveDuetPostureViewController.dismissBlock) {
        @weakify(self);
        self.liveDuetPostureViewController.dismissBlock = ^{
            @strongify(self);
            [self.viewModel sendSignal_propPanelDisplayStatus:ACCPropPanelDisplayStatusDismiss];
            [self.viewContainer showItems:YES animated:YES];
            self.viewModel.inputData.showStickerPanelAtLaunch = NO;
        };
    }
}

#pragma mark - AB Experiments

- (ACCPropPanelSearchEntranceType)shouldSupportSearchFeature
{
    if ([[ACCPropExploreExperimentalControl sharedInstance] hiddenSearchEntry])  {
        return ACCPropPanelSearchEntranceTypeNone;
    }
    return ACCConfigEnum(kConfigInt_new_search_effect_config, ACCPropPanelSearchEntranceType);
}

@end
