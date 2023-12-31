//
//  ACCEditVideoFilterService.m
//  CameraClient
//
//  Created by chengfei xiao on 2020/5/15.
//

#import "ACCEditVideoFilterService.h"
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreationKitArch/AWEColorFilterDataManager.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitArch/ACCRepoFilterModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>

@interface ACCEditVideoFilterServiceImpl() <ACCEditSessionLifeCircleEvent>

@property (nonatomic, strong, readwrite) AWERecordFilterSwitchManager *filterSwitchManager;
@property (nonatomic, strong) RACSignal *applyFilterSignal;
@property (nonatomic, strong) RACSubject *applyFilterSubject;

@end


@implementation ACCEditVideoFilterServiceImpl
@synthesize ignoreSwitchGesture = _ignoreSwitchGesture;

- (void)dealloc
{
    [_applyFilterSubject sendCompleted];
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

#pragma mark - getter

- (AWERecordFilterSwitchManager *)filterSwitchManager
{
    if (!_filterSwitchManager) {
        _filterSwitchManager = [[AWERecordFilterSwitchManager alloc] init];
    }
    return _filterSwitchManager;
}

#pragma mark - ACCEditSessionLifeCircleEvent

- (void)firstRenderWithEditService:(id<ACCEditServiceProtocol>)editService
{
    // 跟首帧优化逻辑保持一致，加载滤镜，防止左右滑动无效果
    @weakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        [[self filterManager] updateEffectFilters];
    });
}

- (void)onCreateEditSessionCompletedWithEditService:(id<ACCEditServiceProtocol>)editService
{
    // 从草稿箱可以点击草稿直接进入发布页，这时不会触发firstRender 回调，所以恢复逻辑需要放在这里
    // 如果这里做延迟处理，要小心确保低端机点击发布时是带上了滤镜，所以这里没有延迟
    [self resumeFilterFromDraft];
}

#pragma mark - Private

- (RACSignal *)applyFilterSignal {
    return self.applyFilterSubject;
}

- (RACSubject *)applyFilterSubject {
    if (!_applyFilterSubject) {
        _applyFilterSubject = [RACSubject subject];
    }
    return _applyFilterSubject;
}

- (void)resumeFilterFromDraft
{
    void (^applyFilterBlock)(IESEffectModel *filter) = ^(IESEffectModel *filterEffect) {
        // 从草稿箱还原的滤镜
        if ([self enableFilterIndensity]) {
            float filterIndensity = [self.editService.filter filterEffectOriginIndensity:filterEffect];
            AWEColorFilterConfigurationHelper *helper = [self currentFilterHelper];
            if (self.repository.repoFilter.colorFilterIntensityRatio && filterEffect) { // 还原草稿
                [helper setIndensityRatioForColorEffect:filterEffect ratio:self.repository.repoFilter.colorFilterIntensityRatio.floatValue];
            }
            BOOL filterHasCacheIndensityRatio = [helper hasIndensityRatioForColorEffect:filterEffect];
            if (filterHasCacheIndensityRatio) {
                float ratio = [helper indensityRatioForColorEffect:filterEffect];
                if (filterIndensity > 0) {
                    filterIndensity = [helper getEffectIndensityWithDefaultIndensity:filterIndensity Ratio:ratio];
                }
            }
            [self.editService.filter applyFilterEffect:filterEffect intensity:filterIndensity];
        } else {
            [self.editService.filter applyFilterEffect:filterEffect.isNormalFilter ? nil : filterEffect];
        }
    };
    
    if (self.repository.repoFilter.colorFilterId) {
        IESEffectModel *filterEffect = [AWEColorFilterDataManager effectWithID:self.repository.repoFilter.colorFilterId];
        
        if (filterEffect.downloaded) {
            ACCBLOCK_INVOKE(applyFilterBlock, filterEffect);
        } else {
            // 若清缓存，需要重新下载;
            [AWEColorFilterDataManager loadEffectWithID:self.repository.repoFilter.colorFilterId completion:^(IESEffectModel *filterEffect) {
                 ACCBLOCK_INVOKE(applyFilterBlock, filterEffect);
            }];
        }
    }
}

- (AWEColorFilterDataManager *)filterManager
{
    return [AWEColorFilterDataManager defaultManager];
}

- (BOOL)enableFilterIndensity
{
    // 新版编辑重构才能调节滤镜强度
    return self.repository.repoContext.videoType != AWEVideoTypePhotoMovie;
}

- (AWEColorFilterConfigurationHelper *)currentFilterHelper {
    if (self.repository.repoContext.isMVVideo
        || AWEVideoTypePhotoToVideo == self.repository.repoContext.videoType) {
        return [[self filterManager] colorFilterConfigurationHelperWithType:AWEColorFilterMvConfigurationType];
    } else {
        return [[self filterManager] colorFilterConfigurationHelperWithType:AWEColorFilterEditorConfigurationType];
    }
}

#pragma mark - Setter

- (void)setEditService:(id<ACCEditServiceProtocol>)editService {
    _editService = editService;
    [editService addSubscriber:self];
}

#pragma mark - public methods

- (void)sendAppleFilterToSubscribers {
    [self.applyFilterSubject sendNext:nil];
}

- (void)clearColorFilter
{
    self.repository.repoFilter.colorFilterId = nil;
    self.repository.repoFilter.colorFilterIntensityRatio = nil;
    ACCBLOCK_INVOKE(self.handleClearFilterBlock);
}

@end
