//
//  ACCEditVideoFilterComponent.m
//  AWEStudio-Pods-Aweme
//
//  Created by 郝一鹏 on 2019/10/20.
//

#import "AWERepoFilterModel.h"
#import "ACCEditVideoFilterComponent.h"
#import <CreationKitArch/AWEColorFilterDataManager.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCEditViewContainer.h>

#import <CreationKitComponents/AWETabFilterViewController.h>
#import <CreationKitComponents/AWECameraFilterConfiguration.h>
#import "ACCEditorDraftService.h"
#import <CreativeKit/ACCEditViewContainer.h>
#import "ACCVideoEditToolBarDefinition.h"
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import <CreationKitArch/AWEEffectFilterDataManager.h>
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import <CreationKitComponents/ACCFilterDefines.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import "ACCStickerGestureComponentProtocol.h"
#import "ACCConfigKeyDefines.h"
#import <CreationKitArch/AWEColorFilterDataManager.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitArch/ACCRepoFilterModel.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "ACCDraftProtocol.h"
#import "ACCStickerPanelServiceProtocol.h"
#import "ACCStickerServiceProtocol.h"
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CameraClient/AWERepoDraftModel.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import "ACCEditVideoFilterTrackerSender.h"
#import "ACCEditBarItemExtraData.h"
#import "ACCFilterDataServiceImpl.h"
#import "ACCBarItem+Adapter.h"
#import "ACCStickerSelectionContext.h"

@interface ACCEditVideoFilterComponent () <
AWERecordFilterSwitchProtocol,
AWERecordFilterVCDelegate,
ACCPanelViewDelegate,
ACCEditSessionLifeCircleEvent
>
@property (nonatomic, strong) AWETabFilterViewController *tabFilterController;
@property (nonatomic, strong) AWECameraFilterConfiguration *cameraFilterConfiguration;
@property (nonatomic, strong) NSMutableSet<IESEffectModel *> *scrollBrowsedFilters;
@property (nonatomic, strong) UILabel *filterNameLabel;
@property (nonatomic, strong) UIView *maskView; //通用遮罩
@property (nonatomic, assign) BOOL isCacheClearedEnter;//清空缓存后草稿恢复
@property (nonatomic, assign) BOOL isShowingFilterPanel;
@property (nonatomic, weak) id<ACCStickerGestureComponentProtocol> stickerGestureComponent;
@property (nonatomic, weak) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCStickerPanelServiceProtocol> stickerPanelService;
@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerService;

@property (nonatomic, strong, readwrite) ACCEditVideoFilterServiceImpl *filterService;
@property (nonatomic, strong) ACCEditVideoFilterTrackerSender *trackSender;

@end

/* @warning 图集模式下由于复用兼容问题太多另起了一个ACCImageEditFilterComponent
            如果视频的滤镜有些改动 请确认下图集模式下是否需要同步修改
 */


@implementation ACCEditVideoFilterComponent

@synthesize enableFilterSwitch = _enableFilterSwitch;

IESAutoInject(self.serviceProvider, stickerGestureComponent, ACCStickerGestureComponentProtocol)
IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, stickerPanelService, ACCStickerPanelServiceProtocol)
IESAutoInject(self.serviceProvider, stickerService, ACCStickerServiceProtocol)

#pragma mark - ACCFeatureComponent protocol

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

- (NSArray<ACCServiceBinding *> *)serviceBindingArray {
    return @[
        ACCCreateServiceBinding(@protocol(ACCEditVideoFilterService), self.filterService),
        ACCCreateServiceBinding(@protocol(ACCEditVideoFilterTrackSenderProtocol), self.trackSender),
    ];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.filterService.editService = self.editService;
    self.filterService.repository = self.repository;
    [self.editService addSubscriber:self];
}

- (void)loadComponentView {
    [self.viewContainer addToolBarBarItem:[self filterBarItem]];
}

- (void)componentDidMount
{
    [AWEEffectFilterDataManager defaultManager].trackExtraDic = [self.repository.repoTrack.commonTrackInfoDic copy];
    [self.viewContainer.panelViewController registerObserver:self];
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    [self configFilterSwitchManager];
    [self p_bindViewModel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshCurrentFilter) name:kAWEStudioColorFilterListUpdateNotification object:nil];
}

- (void)componentWillAppear
{
    [self.filterService.filterSwitchManager startSwitchDisplayLink];
}

- (void)componentDidDisappear
{
    [self.filterService.filterSwitchManager stopSwitchDisplayLink];
}

- (void)componentDidUnmount
{
    [self.viewContainer.panelViewController unregisterObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)p_bindViewModel
{
    @weakify(self);
    [[[[self stickerPanelService] willShowStickerPanelSignal] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self.filterService.filterSwitchManager updatePanGestureEnabled:NO];
    }];
    
    [[[[self stickerPanelService] willDismissStickerPanelSignal] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        BOOL shouldUpdateGes = YES;
        if ([x isKindOfClass:ACCStickerSelectionContext.class]) {
            shouldUpdateGes = ((ACCStickerSelectionContext *)x).stickerType != ACCStickerTypeLyricSticker;
        }
        [self.filterService.filterSwitchManager updatePanGestureEnabled:shouldUpdateGes];
    }];
    
    [[[[self stickerService] willStartEditingStickerSignal] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        [self.filterService.filterSwitchManager updatePanGestureEnabled:NO];
    }];
    
    [[[[self stickerService] didFinishEditingStickerSignal] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        [self.filterService.filterSwitchManager updatePanGestureEnabled:YES];
    }];
    
}

#pragma mark - ACCEditSessionLifeCircleEvent

- (void)firstRenderWithEditService:(id<ACCEditServiceProtocol>)editService
{
    [EffectPlatform setAutoDownloadEffects:NO];
    [[AWEEffectFilterDataManager defaultManager] updateEffectFilters];
}

#pragma mark - 

- (void)filterClicked
{
    [self.trackSender sendFilterClickedSignal];
    self.tabFilterController.selectedFilter = [AWEColorFilterDataManager effectWithID:self.repository.repoFilter.colorFilterId];
    [self.viewContainer.panelViewController showPanelView:self.tabFilterController duration:0.49];
    [self.tabFilterController reloadData];
}

- (ACCBarItem<ACCEditBarItemExtraData*>*)filterBarItem {
    let config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarFilterContext];
    if (!config) return nil;
    ACCBarItem<ACCEditBarItemExtraData*>* barItem = [[ACCBarItem alloc] init];
    barItem.title = config.title;
    barItem.imageName = config.imageName;
    barItem.location = config.location;
    barItem.itemId = ACCEditToolBarFilterContext;
    barItem.type = ACCBarItemFunctionTypeCover;
    @weakify(self);
    barItem.barItemActionBlock = ^(UIView * _Nonnull itemView) {
        @strongify(self);
        if (!self.isMounted) {
            return;
        }
        [self filterClicked];
    };
    barItem.needShowBlock = ^BOOL{
        return YES;
    };
    barItem.extraData = [[ACCEditBarItemExtraData alloc] initWithButtonClass:nil type:AWEEditAndPublishViewDataTypeFilter];
    return barItem;
}


#pragma mark - AWERecordFilterSwitchProtocol 想要添加手势滑动切换滤镜的Controller需要遵守的协议

- (void)applyFilterWithFilterModel:(IESEffectModel *)filterModel type:(IESEffectType)type
{
    // applyFilter message from filterSwitchManager
    [self.filterService sendAppleFilterToSubscribers];
}

- (void)switchFilterWithFilterOne:(IESEffectModel *)filterOne
                        FilterTwo:(IESEffectModel *)filterTwo
                        direction:(IESMMFilterSwitchDirection)direction
                         progress:(CGFloat)progress
{
    ACCLog(@"switch filter by swipe screen");
    NSString *filterOnePath = [filterOne filePathForCameraPosition:AVCaptureDevicePositionFront] ?: @"";
    NSString *filterTwoPath = [filterTwo filePathForCameraPosition:AVCaptureDevicePositionFront] ?: @"";
    
    float filterOneIndensity = 0, filterTwoIndensity = 0;
    if ([self enableFilterIndensity]) {
        AWEColorFilterConfigurationHelper *helper = [self currentFilterHelper];
        filterOneIndensity = [self filterIndensity:filterOne];
        if (filterOneIndensity == 0 && filterOne.isNormalFilter) {
            filterOnePath = [filterOne filePathForCameraPosition:AVCaptureDevicePositionFront] ?: @"";
        } else {
            BOOL filterOneHasCacheIndensityRatio = [helper hasIndensityRatioForColorEffect:filterOne];
            if (filterOneHasCacheIndensityRatio) {
                float ratio = [helper indensityRatioForColorEffect:filterOne];
                if (filterOneIndensity > 0) {
                    filterOneIndensity = [helper getEffectIndensityWithDefaultIndensity:filterOneIndensity Ratio:ratio];
                }
            }
        }
        
        filterTwoIndensity = [self filterIndensity:filterTwo];
        if (filterTwoIndensity == 0 && filterTwo.isNormalFilter) {
            filterTwoPath = [filterTwo filePathForCameraPosition:AVCaptureDevicePositionFront] ?: @"";
        } else {
            BOOL filterTwoHasCacheIndensityRatio = [helper hasIndensityRatioForColorEffect:filterTwo];
            if (filterTwoHasCacheIndensityRatio) {
                float ratio2 = [helper indensityRatioForColorEffect:filterTwo];
                if (filterTwoIndensity > 0) {
                    filterTwoIndensity = [helper getEffectIndensityWithDefaultIndensity:filterTwoIndensity Ratio:ratio2];
                }
            }
        }
        // 根据缓存读取默认值
        [self.editService.filter switchColorLeftFilter:filterOne rightFilter:filterTwo inPosition:progress inLeftIntensity:filterOneIndensity inRightIntensity:filterTwoIndensity];
    } else {
        [self.editService.filter switchColorLeftFilter:filterOne rightFilter:filterTwo inPosition:progress];
    }
}

- (BOOL)enableFilterSwitch
{
    return self.repository.repoContext.videoType != AWEVideoTypeReplaceMusicVideo && self.repository.repoContext.videoType != AWEVideoTypeNewYearWish && ACCConfigBool(kConfigBool_tools_edit_filter_switch_enable);
}

- (BOOL)switchFilterGestureShouldBegin
{
    if (self.filterService.ignoreSwitchGesture) {
        return NO;
    }
    // TODO: @郝一鹏 stickerGestureController 这个要拆分了，调用组件的方法来判断
    if ([[self stickerGestureComponent].stickerGestureController hitTargetStickerWithGesture:self.filterService.filterSwitchManager.panGes deSelected:NO]) {
        return NO;
    }
    
    if (self.isShowingFilterPanel) {
        CGPoint point = [self.filterService.filterSwitchManager.panGes locationInView:self.tabFilterController.containerView];
        if (CGRectContainsPoint(self.tabFilterController.containerView.bounds, point)) {
            return NO;
        }
    }
    return YES;
}


#pragma mark - AWERecordFilterVCDelegate

- (void)p_applyFilter:(nullable IESEffectModel *)effect
{
    [self.editService.filter applyFilterEffect:effect];
}

- (void)p_applyFilter:(IESEffectModel *)effect indensity:(float)indensity
{
    [self.editService.filter applyFilterEffect:effect intensity:indensity];
}

- (void)applyFilter:(IESEffectModel *)item
{
    ACCLog(@"switch filter by click tab item");
    if ([self.repository.repoFilter.colorFilterId isEqualToString:item.effectIdentifier]) {
        if (!self.isCacheClearedEnter) {
            return;
        } else {
            self.isCacheClearedEnter = NO;//清空缓存后草稿恢复，选择原来的滤镜，需要重新运用而不是return；
        }
    }
    [[self draftService] hadBeenModified];

    AWERepoFilterModel *filterModel = self.repository.repoFilter;
    
    NSMutableString *effectPinYin = [[NSMutableString alloc] initWithString:(item.effectName) ?: @""];
    CFStringTransform((__bridge CFMutableStringRef)effectPinYin, NULL, kCFStringTransformMandarinLatin, NO);
    CFStringTransform((__bridge CFMutableStringRef)effectPinYin, NULL, kCFStringTransformStripDiacritics, NO);
    
    filterModel.colorFilterName = [effectPinYin stringByReplacingOccurrencesOfString:@" " withString:@""];
    filterModel.colorFilterId = item.effectIdentifier;
    
    filterModel.hasDeselectionBeenMadeRecently = item ? NO : YES;
    
    if (item) {
        NSString *categoryName = [self.tabFilterController tabNameForFilter:item];
        [self showFilterNamaLabelWithFilterName:item.effectName categoryName:categoryName];
        [self.filterService.filterSwitchManager refreshCurrentFilterModelWithFilter:item];
    }
    
    
    if ([self enableFilterIndensity]) {
        float filterIndensity = [self filterIndensity:item];
        NSString *resourcePath = [item filePathForCameraPosition:AVCaptureDevicePositionFront] ?: @"";
        if (filterIndensity == 0) {
            self.repository.repoFilter.colorFilterIntensityRatio = nil;
        } else {
            AWEColorFilterConfigurationHelper *helper = [self currentFilterHelper];
            BOOL filterHasCacheIndensityRatio = [helper hasIndensityRatioForColorEffect:item];
            if (filterHasCacheIndensityRatio) {
                float ratio = [helper indensityRatioForColorEffect:item];
                self.repository.repoFilter.colorFilterIntensityRatio = @(ratio);
                if (filterIndensity > 0) {
                    filterIndensity = [helper getEffectIndensityWithDefaultIndensity:filterIndensity Ratio:ratio];
                }
            } else {
                self.repository.repoFilter.colorFilterIntensityRatio = nil;
            }
        }
        [self p_applyFilter:item indensity:filterIndensity];
        if (resourcePath) {
            AWELogToolVerbose(AWELogToolTagEdit, @"apply filter, effect path:%@, intensity:%.2f, effect id:%@, effect name:%@",
                              resourcePath,filterIndensity,item.effectIdentifier,item.effectName);
        } else if (item) {
            AWELogToolError(AWELogToolTagEdit, @"apply filter error, effect path:%@, intensity:%.2f, effect id:%@, effect name:%@",
                            resourcePath,filterIndensity,item.effectIdentifier,item.effectName);
        }
    } else {
        [self p_applyFilter:item];
        AWELogToolVerbose(AWELogToolTagEdit, @"apply filter, normal fileter:%@, effect id:%@, effect name:%@",
                          @(item.isNormalFilter),item.effectIdentifier,item.effectName);
    }
    [self saveDraftIfNeed];
}

- (void)applyFilter:(IESEffectModel *)item indensity:(float)indensity
{
    [self p_applyFilter:item indensity:indensity];
}

- (float)filterIndensity:(IESEffectModel *)item
{
    if (item.isEmptyFilter) {
        return 0;
    } else {
        return [self.editService.filter filterEffectOriginIndensity:item];
    }
}

- (AWEColorFilterConfigurationHelper *)currentFilterHelper {
    if (self.repository.repoContext.isMVVideo || AWEVideoTypePhotoToVideo == self.repository.repoContext.videoType) {
        return [[self filterManager] colorFilterConfigurationHelperWithType:AWEColorFilterMvConfigurationType];
    } else {
        return [[self filterManager] colorFilterConfigurationHelperWithType:AWEColorFilterEditorConfigurationType];
    }
}

- (BOOL)enableFilterIndensity
{
    // 新版编辑重构才能调节滤镜强度
    return self.repository.repoContext.videoType != AWEVideoTypePhotoMovie;
}

#pragma mark - private method

- (void)configFilterSwitchManager
{
    self.filterService.filterSwitchManager.delegate = self;
    
    @weakify(self);
    self.filterService.filterSwitchManager.changeProgressBlock = ^(IESEffectModel *leftFilter, IESEffectModel *rightFilter, CGFloat progress) {};
    self.filterService.filterSwitchManager.completionBlock = ^(IESEffectModel *filter) {
        @strongify(self);
        self.repository.repoFilter.colorFilterId = filter.effectIdentifier;
        if ([self enableFilterIndensity]) {
            // 选择滑动滤镜的
            float filterIndensity = [self filterIndensity:filter];
            if (filterIndensity == 0) {
                self.repository.repoFilter.colorFilterIntensityRatio = nil;
            } else {
                AWEColorFilterConfigurationHelper *helper = [self currentFilterHelper];
                BOOL filterHasCacheIndensityRatio = [helper hasIndensityRatioForColorEffect:filter];
                if (filterHasCacheIndensityRatio) {
                    float ratio = [helper indensityRatioForColorEffect:filter];
                    self.repository.repoFilter.colorFilterIntensityRatio = @(ratio);
                } else {
                    self.repository.repoFilter.colorFilterIntensityRatio = nil;
                }
            }
        }
        NSString *categoryName = [self.tabFilterController tabNameForFilter:filter];
        [self showFilterNamaLabelWithFilterName:filter.effectName categoryName:categoryName];
        [[self draftService] hadBeenModified];

        if (self.tabFilterController.view.superview) {
            self.tabFilterController.selectedFilter = filter;
            [self.tabFilterController selectFilterByCode:filter];
        } else {
            if (filter != nil) {
                [self.scrollBrowsedFilters addObject:filter];
            }
        }
        [self.trackSender sendFilterSwitchManagerCompleteSignalWithFilter:filter];
    };
    
    // cameraFilterConfiguration 初始化的时候内部不再主动同步调用数据刷新，需要手动刷新
    [self.cameraFilterConfiguration updateFilterDataWithCompletion:^{
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            [self.filterService.filterSwitchManager addFilterSwitchGestureForViewController:self.containerViewController
                                                                            filterArray:self.cameraFilterConfiguration.filterArray
                                                                    filterConfiguration:self.cameraFilterConfiguration];
            [self refreshCurrentFilter];
        });
    }];
}

- (void)refreshCurrentFilter
{
    IESEffectModel *selectedFilter = nil;
    if (self.repository.repoFilter.colorFilterId) {
        IESEffectModel *filterEffect = [AWEColorFilterDataManager effectWithID:self.repository.repoFilter.colorFilterId];
        if (filterEffect.downloaded) {
            selectedFilter = filterEffect;
        } else {
            self.isCacheClearedEnter = YES;
        }
    }
    if (!selectedFilter && !self.isCacheClearedEnter) {
        selectedFilter = self.cameraFilterConfiguration.filterArray.firstObject;
    }
    [self.filterService.filterSwitchManager refreshCurrentFilterModelWithFilter:selectedFilter];
}

- (void)saveDraftIfNeed
{
    if (!self.repository.repoDraft.isDraft) {
        [ACCDraft() saveDraftWithPublishViewModel:self.repository
                                            video:self.repository.repoVideoInfo.video
                                           backup:!self.repository.repoDraft.originalDraft
                                       completion:^(BOOL success, NSError *error) {
            if (error) {
                ACCLog(@"save draft error: %@", error);
            }
        }];
    }
}

#pragma mark - getter method

- (ACCEditVideoFilterServiceImpl *)filterService {
    if (!_filterService) {
        _filterService = [[ACCEditVideoFilterServiceImpl alloc] init];
        @weakify(self);
        _filterService.handleClearFilterBlock = ^{
            @strongify(self);
            [self p_applyFilter:nil];
        };
    }
    return _filterService;
}

- (UIViewController *)containerViewController
{
    if ([self.controller isKindOfClass:[UIViewController class]]) {
        return (UIViewController *)self.controller;
    }
    NSAssert(nil, @"exception");
    return nil;
}

- (id<ACCEditorDraftService>)draftService
{
    let draftService = IESAutoInline(self.serviceProvider, ACCEditorDraftService);
    NSAssert(draftService, @"should not be nil");
    return draftService;
}

- (NSMutableSet<IESEffectModel *> *)scrollBrowsedFilters
{
    if (!_scrollBrowsedFilters) {
        _scrollBrowsedFilters = [NSMutableSet set];
    }
    return _scrollBrowsedFilters;
}

- (AWETabFilterViewController *)tabFilterController {
    if (!_tabFilterController) {
        _tabFilterController = [[AWETabFilterViewController alloc] initWithFilterConfiguration:self.cameraFilterConfiguration];
        _tabFilterController.delegate = self;
        _tabFilterController.iconStyle = (AWEFilterCellIconStyle)ACCConfigInt(kConfigInt_filter_icon_style);
        ACCFilterDataServiceImpl *dataService = [[ACCFilterDataServiceImpl alloc] initWithRepository:self.repository];
        _tabFilterController.repository = dataService;
        _tabFilterController.isPhotoMode = (self.repository.repoContext.videoType == AWEVideoTypeStoryPicture);
        _tabFilterController.filterManager = [self filterManager];
        @weakify(self);
        _tabFilterController.willDismissBlock = ^(void) {
            @strongify(self);
            [self.trackSender sendTabFilterControllerWillDismissSignalWithSelectedFilter:self.tabFilterController.selectedFilter];
            [self.viewContainer.panelViewController dismissPanelView:self.tabFilterController duration:0.25];
        };
        [self.filterService.filterSwitchManager addPanGesExcludedView:_tabFilterController.bottomTabFilterView];
    }
    return _tabFilterController;
}

- (AWECameraFilterConfiguration *)cameraFilterConfiguration
{
    if (!_cameraFilterConfiguration) {
        _cameraFilterConfiguration = [[AWECameraFilterConfiguration alloc] init];
    }
    return _cameraFilterConfiguration;
}

- (AWEColorFilterDataManager *)filterManager
{
    return [AWEColorFilterDataManager defaultManager];
}

- (UILabel *)filterNameLabel
{
    if (!_filterNameLabel) {
        _filterNameLabel = [[UILabel alloc] init];
        _filterNameLabel.font = [ACCFont() systemFontOfSize:27 weight:ACCFontWeightLight];
        _filterNameLabel.textAlignment = NSTextAlignmentCenter;
        _filterNameLabel.backgroundColor = [UIColor clearColor];
        _filterNameLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        _filterNameLabel.alpha = 0.0f;
        _filterNameLabel.numberOfLines = 0;
        ACC_LANGUAGE_DISABLE_LOCALIZATION(_filterNameLabel);
    }
    return _filterNameLabel;;
}

- (UIView *)maskView
{
    if (!_maskView) {
        _maskView = [[UIView alloc] initWithFrame:self.viewContainer.rootView.bounds];
        _maskView.backgroundColor = [UIColor clearColor];
    }
    return _maskView;
}

- (ACCEditVideoFilterTrackerSender *)trackSender
{
    if (!_trackSender) {
        _trackSender = [[ACCEditVideoFilterTrackerSender alloc] init];
    }
    return _trackSender;
}

#pragma mark - 滤镜名称显示

- (void)showFilterNamaLabelWithFilterName:(NSString *)filterName categoryName:(NSString *)catetoryName
{
    if (!self.filterNameLabel.superview) {
        [[self containerViewController].view addSubview:self.filterNameLabel];
    }
    [[self containerViewController].view bringSubviewToFront:self.filterNameLabel];
    
    self.filterNameLabel.alpha = 0.0;
    [self.filterNameLabel.layer removeAllAnimations];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    UIColor *textColor = ACCResourceColor(ACCUIColorConstTextInverse);
    if (filterName.length > 0) {
        filterName = [filterName stringByAppendingString:@"\n"];
        UIFont *font = [ACCFont() systemFontOfSize:28 weight:ACCFontWeightLight];
        NSDictionary *attributes = @{NSFontAttributeName: font, NSForegroundColorAttributeName: textColor};
        NSAttributedString *filterNameAttributedString = [[NSAttributedString alloc] initWithString:filterName attributes:attributes];
        [attributedString appendAttributedString:filterNameAttributedString];
    }
    if (catetoryName.length > 0) {
        UIFont *font = [ACCFont() systemFontOfSize:14 weight:ACCFontWeightLight];
        NSDictionary *attributes = @{NSFontAttributeName: font, NSForegroundColorAttributeName: textColor};
        NSAttributedString *filterCategoryNameAttributedString = [[NSAttributedString alloc] initWithString:catetoryName attributes:attributes];
        [attributedString appendAttributedString:filterCategoryNameAttributedString];
    }
    self.filterNameLabel.attributedText = attributedString;
    CGSize size = [self.filterNameLabel.attributedText boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    self.filterNameLabel.frame = CGRectMake(0, 0, size.width, size.height);
    CGRect frame = self.containerViewController.view.frame;
    self.filterNameLabel.center = CGPointMake(CGRectGetMidX(frame), CGRectGetMinY(frame) + (ACC_SCREEN_HEIGHT / 3));
    [UIView animateKeyframesWithDuration:1.2
                                   delay:0
                                 options:UIViewKeyframeAnimationOptionBeginFromCurrentState
                              animations:^{
                                  [UIView addKeyframeWithRelativeStartTime:0.0
                                                          relativeDuration:(0.3/1.2)
                                                                animations:^{
                                                                    self.filterNameLabel.alpha = 1.0;
                                                                }];
                                  [UIView addKeyframeWithRelativeStartTime:(0.9/1.2)
                                                          relativeDuration:(0.3/1.2)
                                                                animations:^{
                                                                    self.filterNameLabel.alpha = 0.0;
                                                                }];
                              }
                              completion:nil];
}

#pragma mark - ACCPanelViewDelegate

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController willShowPanelView:(id<ACCPanelViewProtocol>)panelView
{
    if (panelView.identifier == ACCFilterContext) {
        [UIView animateWithDuration:0.2 animations:^{
            self.viewContainer.containerView.alpha = .0f;
        }];
    } else {
        [[self filterService].filterSwitchManager updatePanGestureEnabled:NO];
    }
}

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController didShowPanelView:(id<ACCPanelViewProtocol>)panelView
{
    if (panelView.identifier == ACCFilterContext) {
        [self.viewContainer.rootView insertSubview:self.maskView aboveSubview:self.viewContainer.containerView];
    }
}

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController willDismissPanelView:(id<ACCPanelViewProtocol>)panelView
{
    if (panelView.identifier == ACCFilterContext) {
        [UIView animateWithDuration:0.2 animations:^{
            self.viewContainer.containerView.alpha = 1.0;
        }];
    }
    [[self filterService].filterSwitchManager updatePanGestureEnabled:YES];
}

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController didDismissPanelView:(id<ACCPanelViewProtocol>)panelView
{
   if (panelView.identifier == ACCFilterContext) {
        [self.maskView removeFromSuperview];
   }
}

#pragma mark - Draft recover

+ (NSArray<NSString *> *)draftResourceIDsToDownloadForPublishViewModel:(AWEVideoPublishViewModel *)publishModel
{
    if (ACC_isEmptyString(publishModel.repoFilter.colorFilterId)) {
        return @[];
    }
    if ([publishModel.repoFilter.colorFilterId longLongValue] <= 0) {
        return @[];
    }
    
    NSMutableArray *resourceIDsToDownload = [NSMutableArray array];
    IESEffectModel *filterModel = [[AWEColorFilterDataManager defaultManager] effectWithID:publishModel.repoFilter.colorFilterId];
    if ([filterModel downloaded]) {
        return @[];
    }
    [resourceIDsToDownload addObject:publishModel.repoFilter.colorFilterId];
    return resourceIDsToDownload;
}

@end
