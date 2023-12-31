//
//  ACCImageEditFilterComponent.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/1/8.
//

#import "ACCImageEditFilterComponent.h"
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
#import "ACCConfigKeyDefines.h"
#import <CreationKitArch/AWEColorFilterDataManager.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "ACCImageAlbumData.h"
#import "ACCImageAlbumItemModel.h"
#import "ACCRepoImageAlbumInfoModel.h"
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import "ACCEditBarItemExtraData.h"
#import "ACCFilterDataServiceImpl.h"
#import "ACCEditImageAlbumMixedProtocolD.h"
#import "ACCBarItem+Adapter.h"

@interface ACCImageEditFilterComponent ()
<
AWERecordFilterVCDelegate,
ACCPanelViewDelegate,
ACCEditSessionLifeCircleEvent
>

@property (nonatomic, strong) AWETabFilterViewController *tabFilterController;
@property (nonatomic, strong) AWECameraFilterConfiguration *cameraFilterConfiguration;
@property (nonatomic, strong) UILabel *filterNameLabel;
@property (nonatomic, strong) UIView *maskView;

@property (nonatomic, strong) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;

@end


@implementation ACCImageEditFilterComponent


IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)

#pragma mark - ACCFeatureComponent protocol

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.editService addSubscriber:self];
}

- (void)componentDidMount
{
    if (!self.repository.repoImageAlbumInfo.isImageAlbumEdit) {
        NSAssert(NO, @"should not added for video edit mode");
        return;
    }
    
    [AWEEffectFilterDataManager defaultManager].trackExtraDic = [self.repository.repoTrack.commonTrackInfoDic copy];
    [self.viewContainer.panelViewController registerObserver:self];
    
    /// 图集只支持Composer滤镜
    if (ACCConfigBool(kConfigBool_enable_composer_filter)) {
        [self.viewContainer addToolBarBarItem:[self filterBarItem]];
    }
}

- (void)componentDidUnmount
{
    [self.viewContainer.panelViewController unregisterObserver:self];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

#pragma mark - ACCEditSessionLifeCircleEvent

- (void)firstRenderWithEditService:(id<ACCEditServiceProtocol>)editService
{
    [[AWEEffectFilterDataManager defaultManager] updateEffectFilters];
}

#pragma mark -

- (void)filterClicked
{
    [self trackFilterEvent];
    self.tabFilterController.selectedFilterIntensityRatio = [self currentColorFilterIntensityRatio];
    self.tabFilterController.selectedFilter = [AWEColorFilterDataManager effectWithID:[self currentFilterId]];
    [self.viewContainer.panelViewController showPanelView:self.tabFilterController duration:0.49];
    [self.tabFilterController reloadData];
}

- (ACCBarItem<ACCEditBarItemExtraData*>*)filterBarItem
{
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
        [self filterClicked];
    };
    barItem.needShowBlock = ^BOOL{
        return YES;
    };
    barItem.extraData = [[ACCEditBarItemExtraData alloc] initWithButtonClass:nil type:AWEEditAndPublishViewDataTypeFilter];
    return barItem;
}

#pragma mark - AWERecordFilterVCDelegate

- (void)onUserSlideIndensityValueChanged:(CGFloat)sliderIndensity
{
    [self editService].imageAlbumMixed.currentImageItemModel.filterInfo.slideRatio = @(sliderIndensity);
}

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
    
    if (item) {
        NSString *categoryName = [self.tabFilterController tabNameForFilter:item];
        [self showFilterNamaLabelWithFilterName:item.effectName categoryName:categoryName];
    }
    
    if ([self enableFilterIndensity]) {
        
        float filterIndensity = [self filterIndensity:item];
        NSString *resourcePath = [item filePathForCameraPosition:AVCaptureDevicePositionFront] ?: @"";
        
        if (filterIndensity != 0) {
            AWEColorFilterConfigurationHelper *helper = [self currentFilterHelper];
            BOOL filterHasCacheIndensityRatio = [helper hasIndensityRatioForColorEffect:item];
            if (filterHasCacheIndensityRatio) {
                float ratio = [helper indensityRatioForColorEffect:item];
                if (filterIndensity > 0) {
                    filterIndensity = [helper getEffectIndensityWithDefaultIndensity:filterIndensity Ratio:ratio];
                }
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
    
    [[self draftService] hadBeenModified];
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

- (AWEColorFilterConfigurationHelper *)currentFilterHelper
{
    return [[self filterManager] colorFilterConfigurationHelperWithType:AWEColorFilterEditorConfigurationType];
}

- (BOOL)enableFilterIndensity
{
    return YES;
}

#pragma mark - track
- (void)trackFilterEvent
{
    if (self.repository.repoContext.recordSourceFrom == AWERecordSourceFromUnknown) {
        NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.repository.repoTrack.referExtra];
        [referExtra addEntriesFromDictionary:self.repository.repoTrack.mediaCountInfo];
        [ACCTracker() trackEvent:@"click_modify_entrance" params:[referExtra copy] needStagingFlag:NO];
    }
}

#pragma mark - getter method

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

- (AWETabFilterViewController *)tabFilterController
{
    
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
            NSString *label = self.tabFilterController.selectedFilter.pinyinName;
            if (label) {
                NSMutableDictionary *attributes = [@{@"is_photo" : @0} mutableCopy];
                [attributes addEntriesFromDictionary:self.repository.repoTrack.referExtra];
                [ACCTracker() trackEvent:@"filter_confirm" label:@"mid_page" value:nil extra:label attributes:attributes];
            }
            
            [self.viewContainer.panelViewController dismissPanelView:self.tabFilterController duration:0.25];
        };
    }
    return _tabFilterController;
}

- (AWECameraFilterConfiguration *)cameraFilterConfiguration
{
    if (!_cameraFilterConfiguration) {
        _cameraFilterConfiguration = [[AWECameraFilterConfiguration alloc] init];
        [_cameraFilterConfiguration updateFilterDataWithCompletion:nil];
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

#pragma mark - 滤镜名称显示
- (NSString *)currentFilterId
{
    return [self editService].imageAlbumMixed.currentImageItemModel.filterInfo.effectIdentifier;
}

- (NSNumber *)currentColorFilterIntensityRatio
{
    return [self editService].imageAlbumMixed.currentImageItemModel.filterInfo.slideRatio;
}

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
        [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) stopAutoPlayWithKey:@"filterPanel"];
        [UIView animateWithDuration:0.2 animations:^{
            self.viewContainer.containerView.alpha = .0f;
        }];
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
}

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController didDismissPanelView:(id<ACCPanelViewProtocol>)panelView
{
   if (panelView.identifier == ACCFilterContext) {
       [self.maskView removeFromSuperview];
       [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) startAutoPlayWithKey:@"filterPanel"];
   }
}

#pragma mark - Draft recover

+ (NSArray<NSString *> *)draftResourceIDsToDownloadForPublishViewModel:(AWEVideoPublishViewModel *)publishModel
{
    if (!ACCConfigBool(kConfigBool_enable_images_album_publish)) {
        return @[];
    }
    
    NSMutableArray <NSString *> *resourceIds = [NSMutableArray array];
    
    ACCImageAlbumData *imageData = publishModel.repoImageAlbumInfo.imageAlbumData;
    [imageData.imageAlbumItems enumerateObjectsUsingBlock:^(ACCImageAlbumItemModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSString *filterId = obj.filterInfo.effectIdentifier;
        if (filterId.length > 0 && filterId.longLongValue > 0) {
            IESEffectModel *filterModel = [[AWEColorFilterDataManager defaultManager] effectWithID:filterId];
            if (!filterModel.downloaded) {
                [resourceIds addObject:obj.filterInfo.effectIdentifier];
            }
        }
    }];
    
    return [resourceIds copy];
}

+ (void)updateWithDownloadedEffects:(NSArray<IESEffectModel *> *)effects
                   publishViewModel:(AWEVideoPublishViewModel *)publishModel
                         completion:(nonnull ACCDraftRecoverCompletion)completion
{
    
    [effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [publishModel.repoImageAlbumInfo.imageAlbumData updateRecoveredEffectIfNeedWithIdentifier:obj.effectIdentifier filePath:obj.filePath];
    }];
    
    ACCBLOCK_INVOKE(completion, nil, NO);
}

@end
