//
//  ACCFilterServiceImpl.m
//  Pods
//
//  Created by DING Leo on 2020/2/6.
//

#import "ACCFilterServiceImpl.h"
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreationKitComponents/ACCFilterUtils.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreationKitArch/IESEffectModel+ComposerFilter.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreationKitComponents/ACCBeautyService.h>

@interface ACCFilterServiceImpl ()

@property (nonatomic, strong) RACSubject<IESEffectModel *> *showFilterNameSubject;
@property (nonatomic, strong, readwrite) RACSubject *filterViewWillShowSignal;
@property (nonatomic, strong, readwrite) RACSubject<NSNumber *> *applyFilterSignal;
@property (nonatomic, strong) id<ACCBeautyService> beautyService;
@property (nonatomic, strong) id<ACCCameraService> cameraService;

@end

@implementation ACCFilterServiceImpl

@synthesize filterConfiguration = _filterConfiguration;
@synthesize filterArray = _filterArray;
@synthesize hasDeselectionBeenMadeRecently = _hasDeselectionBeenMadeRecently;
@synthesize panGestureRecognizerEnabled = _panGestureRecognizerEnabled;
@synthesize panGestureRecognizer = _panGestureRecognizer;

IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, beautyService, ACCBeautyService)

#pragma mark - ViewModel Lifecycle

- (void)dealloc
{
    [_showFilterNameSubject sendCompleted];
    [_filterViewWillShowSignal sendCompleted];
    [_applyFilterSignal sendCompleted];
}

- (void)sendFilterViewWillShowSignal
{
    [self.filterViewWillShowSignal sendNext:nil];
}

- (void)sendApplyFilterSignalWith:(BOOL)isComplete
{
    [self.applyFilterSignal sendNext:@(isComplete)];
}

- (RACSubject<IESEffectModel *> *)showFilterNameSubject
{
    if (!_showFilterNameSubject) {
        _showFilterNameSubject = [RACSubject subject];
    }
    return _showFilterNameSubject;
}

- (RACSignal<IESEffectModel *> *)showFilterNameSignal
{
    return self.showFilterNameSubject;
}

- (void)defaultFilterManagerUpdateEffectFilters
{
    [[AWEColorFilterDataManager defaultManager] updateEffectFilters];
}

- (RACSubject *)filterViewWillShowSignal
{
    if (!_filterViewWillShowSignal) {
        _filterViewWillShowSignal = [RACSubject subject];
    }
    return _filterViewWillShowSignal;
}

- (RACSubject<NSNumber *> *)applyFilterSignal
{
    if (!_applyFilterSignal) {
        _applyFilterSignal = [RACSubject subject];
    }
    return _applyFilterSignal;
}

- (void)applyFilter:(IESEffectModel *)filter indensity:(float)indensity
{
    [self.cameraService.filter acc_applyFilterEffect:filter intensity:indensity];
}

- (void)applyFilterForCurrentCameraWithShowFilterName:(BOOL)show sendManualMessage:(BOOL)sendManualMessage
{
    [self applyFilter:self.currentFilter withShowFilterName:show sendManualMessage:sendManualMessage];
}

- (void)applyFilterWithFilterID:(NSString *)filterID
{
    IESEffectModel *filter = [self.filterConfiguration.filterManager effectWithID:filterID];
    [self applyFilter:filter withShowFilterName:NO sendManualMessage:NO];
}

- (void)applyFilter:(IESEffectModel *)filter withShowFilterName:(BOOL)show sendManualMessage:(BOOL)sendManualMessage
{
    float filterIndensity = [self filterIndensity:filter];
    if (filterIndensity != 0) {
        AWEColorFilterConfigurationHelper *helper = [self currentFilterHelper];
        BOOL filterHasCacheIndensityRatio = [helper hasIndensityRatioForColorEffect:filter];
        if (filterHasCacheIndensityRatio) {
            float ratio = [helper indensityRatioForColorEffect:filter];
            if (filterIndensity > 0) {
                filterIndensity = [helper getEffectIndensityWithDefaultIndensity:filterIndensity Ratio:ratio];
            }
        }
    }
    [self.cameraService.filter acc_applyFilterEffect:filter intensity:filterIndensity];

    if (show) {
        [self.showFilterNameSubject sendNext:filter];
    }

    [self refreshCurrentFilterModelWithFilter:filter];
    if (sendManualMessage) {
        [self.beautyService updateAppliedFilter:self.currentFilter];
        
        if ([self isUsingComposerFilter]) {
            [self syncFrontAndRearFilter];
        }
    }
}

- (void)switchFilterWithFilterOne:(IESEffectModel *)filterOne
                        FilterTwo:(IESEffectModel *)filterTwo
                        direction:(IESMMFilterSwitchDirection)direction
                         progress:(CGFloat)progress
{
    float filterOneIndensity = [self filterIndensity:filterOne];
    if (filterOneIndensity != 0) {
        BOOL filterOneHasCacheIndensityRatio = [self.currentFilterHelper hasIndensityRatioForColorEffect:filterOne];
        if (filterOneHasCacheIndensityRatio) {
            float ratio = [self.currentFilterHelper indensityRatioForColorEffect:filterOne];
            if (filterOneIndensity > 0) {
                filterOneIndensity = [self.currentFilterHelper getEffectIndensityWithDefaultIndensity:filterOneIndensity Ratio:ratio];
            }
        }
    }
    
    float filterTwoIndensity = [self filterIndensity:filterTwo];
    if (filterTwoIndensity != 0) {
        BOOL filterTwoHasCacheIndensityRatio = [self.currentFilterHelper hasIndensityRatioForColorEffect:filterTwo];
        if (filterTwoHasCacheIndensityRatio) {
            float ratio2 = [self.currentFilterHelper indensityRatioForColorEffect:filterTwo];
            if (filterTwoIndensity > 0) {
                filterTwoIndensity = [self.currentFilterHelper getEffectIndensityWithDefaultIndensity:filterTwoIndensity Ratio:ratio2];
            }
        }
    }

    [self.cameraService.filter switchColorLeftFilter:filterOne
                                         rightFilter:filterTwo
                                          inPosition:progress
                                     inLeftIntensity:filterOneIndensity
                                    inRightIntensity:filterTwoIndensity];
}

- (void)syncFrontAndRearFilter
{
    [self.beautyService syncFrontAndRearFilterId:self.currentFilter.resourceId];
}

- (AWEColorFilterConfigurationHelper *)currentFilterHelper
{
    return [self.filterConfiguration.filterManager colorFilterConfigurationHelperWithType:AWEColorFilterCaptureConfigurationType];
}

- (float)filterIndensity:(IESEffectModel *)filter
{
    if (filter.isEmptyFilter) {
        return 0;
    } else {
        if (filter.isComposerFilter) {
            return filter.filterConfigItem.defaultIntensity;
        } else {
            return [self.cameraService.filter acc_filterEffectOriginIndensity:[filter filePathForCameraPosition:self.cameraService.cameraControl.currentCameraPosition]];
        }
    }
}

// ACCFilterComponentProtocol
- (BOOL)hasIndensityRatioForColorEffect:(IESEffectModel *)effectModel { // 当前滤镜是否有缓存的强度
    AWEColorFilterConfigurationHelper *helper = [self currentFilterHelper];
    BOOL filterHasCacheIndensityRatio = [helper hasIndensityRatioForColorEffect:effectModel];
    return filterHasCacheIndensityRatio;
}

- (float)indensityRatioCacheForColorEffect:(IESEffectModel *)effectModel { // 当前滤镜缓存的强度
    if ([self hasIndensityRatioForColorEffect:effectModel]) {
        AWEColorFilterConfigurationHelper *helper = [self currentFilterHelper];
        return [helper indensityRatioForColorEffect:effectModel];
    } else {
        return 0;
    }
}

- (void)recoverFilterIfNeeded
{
    if (self.filterConfiguration.frontCameraFilter == nil) {
        self.filterConfiguration.frontCameraFilter = self.filterConfiguration.needRecoveryFrontCameraFilter;
    }
    if (self.filterConfiguration.rearCameraFilter == nil) {
        self.filterConfiguration.rearCameraFilter = self.filterConfiguration.needRecoveryRearCameraFilter;
    }
}

- (IESEffectModel *)prevFilterOfCurrentFilter
{
    return [ACCFilterUtils prevFilterOfFilter:self.currentFilter filterArray:self.filterArray];
}

- (IESEffectModel *)nextFilterOfCurrentFilter
{
    return [ACCFilterUtils nextFilterOfFilter:self.currentFilter filterArray:self.filterArray];
}

- (void)refreshCurrentFilterModelWithFilter:(nonnull IESEffectModel *)filter
{
    self.currentFilter = filter;
}

- (NSArray *)filterArray
{
    return self.filterConfiguration.filterArray;
}

- (AWECameraFilterConfiguration *)filterConfiguration
{
    if (!_filterConfiguration) {
        _filterConfiguration = [[AWECameraFilterConfiguration alloc] init];
        [_filterConfiguration updateFilterDataWithCompletion:nil];
    }
    return _filterConfiguration;
}

#pragma mark - setter

- (IESEffectModel *)currentFilter
{
    if ([self isUsingComposerFilter]) {
        return self.filterConfiguration.frontCameraFilter;
    } else {
        if (self.cameraService.cameraControl.currentCameraPosition == AVCaptureDevicePositionBack) {
            return self.filterConfiguration.rearCameraFilter;
        } else {
            return self.filterConfiguration.frontCameraFilter;
        }
    }
}

- (void)setCurrentFilter:(IESEffectModel *)currentFilter
{
    if (!currentFilter) {
        if (self.filterConfiguration.frontCameraFilter) {
            self.filterConfiguration.needRecoveryFrontCameraFilter = self.filterConfiguration.frontCameraFilter;
        }
        if (self.filterConfiguration.rearCameraFilter) {
            self.filterConfiguration.needRecoveryRearCameraFilter = self.filterConfiguration.rearCameraFilter;
        }
        self.filterConfiguration.frontCameraFilter = self.filterConfiguration.rearCameraFilter = currentFilter;
    } else {
        // use same filter in front and rear position when use composer filter
        if (currentFilter.isComposerFilter) {
            self.filterConfiguration.frontCameraFilter = currentFilter;
            self.filterConfiguration.rearCameraFilter = currentFilter;
        } else {
            if (self.cameraService.cameraControl.currentCameraPosition == AVCaptureDevicePositionBack) {
                self.filterConfiguration.rearCameraFilter = currentFilter;
                self.filterConfiguration.frontCameraFilter = self.filterConfiguration.frontCameraFilter ?: self.filterConfiguration.needRecoveryFrontCameraFilter;
            } else {
                self.filterConfiguration.frontCameraFilter = currentFilter;
                self.filterConfiguration.rearCameraFilter = self.filterConfiguration.rearCameraFilter ?: self.filterConfiguration.needRecoveryRearCameraFilter;
            }
        }
    }
}

- (BOOL)isUsingComposerFilter
{
    return self.filterConfiguration.rearCameraFilter.isComposerFilter || self.filterConfiguration.needRecoveryRearCameraFilter.isComposerFilter || self.filterConfiguration.filterManager.enableComposerFilter;
}

@end
