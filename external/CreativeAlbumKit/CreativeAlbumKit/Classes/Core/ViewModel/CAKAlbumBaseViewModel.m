//Copyright © 2021 Bytedance. All rights reserved.

#import "CAKAlbumBaseViewModel.h"
#import "CAKAlbumAssetCache.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <ReactiveObjC/ReactiveObjC.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCResponder.h>
#import <CreationKitInfra/ACCLogHelper.h>

@interface CAKAlbumBaseViewModel () <PHPhotoLibraryChangeObserver>

@property (nonatomic, assign) NSInteger currentSelectedIndex;
@property (nonatomic, strong) CAKAlbumDataModel *albumDataModel;
@property (nonatomic, assign, readonly) AWEGetResourceType resourceType;
@property (nonatomic, assign) BOOL hasRegisterChangeObserver;
@property (nonatomic, assign, readwrite) BOOL initialSelectedAssetsSynchronized;
@property (nonatomic, assign) NSInteger currentInsertIndex;
@property (nonatomic, strong, readonly) NSMutableArray<CAKAlbumAssetModel *> *currentHandleSelectAssetModels;
@property (nonatomic, strong) NSMutableArray *lastVideoArray; // icloud
@property (nonatomic, strong) CAKAlbumAssetCache *assetCache;

@end


@implementation CAKAlbumBaseViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _listViewConfig = [[CAKAlbumListViewConfig alloc] init];
        _enableNavigationView = YES;
        _enableBottomView = YES;
        _enableSelectedAssetsView = YES;
        _selectedAssetsViewHeight = 88.0f;
        _navigationViewHeight = 54.f;
        _bottomViewHeight = 52.0f;
        _currentSelectedIndex = -1;
        _hasRequestAuthorizationForAccessLevel = NO;
        
        _albumDataModel = [[CAKAlbumDataModel alloc] init];
        [_albumDataModel setupAssetModelProvider];
        [self p_configDefautTabsInfo];
    }
    return self;
}

- (void)dealloc
{
    if (self.hasRegisterChangeObserver) {
        [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    }
}

#pragma mark - getter && setter

- (void)setListViewConfig:(CAKAlbumListViewConfig *)listViewConfig
{
    _listViewConfig = listViewConfig;
    self.assetCache.useQueueOpt = listViewConfig.enableMultithreadOpt;
    [self p_loadCameraRollCollectionIfNeeded];
    [self p_configDefautTabsInfo];
    [self p_prefetchAssetsIfNeeded];
}

- (void)setHasRequestAuthorizationForAccessLevel:(BOOL)hasRequestAuthorizationForAccessLevel
{
    _hasRequestAuthorizationForAccessLevel = hasRequestAuthorizationForAccessLevel;

    if (_hasRequestAuthorizationForAccessLevel) {
        [self p_registerPhotoLibraryChangeObserver];
    }
}

- (UIViewController<CAKAlbumListViewControllerProtocol> *)currentSelectedListVC
{
    NSInteger currentSelectedIndex = self.currentSelectedIndex >= 0 ? self.currentSelectedIndex : self.defaultSelectedIndex;
    UIViewController<CAKAlbumListViewControllerProtocol> *currentListVC = [self.tabsInfo acc_objectAtIndex:currentSelectedIndex];
    return currentListVC;
}

- (NSMutableArray<CAKAlbumAssetModel *> *)currentSelectAssetModels
{
    if (self.listViewConfig.enableMixedUpload) {
        return self.albumDataModel.mixedSelectAssetsModels;
    }
    if (self.resourceType == AWEGetResourceTypeImage) {
        return self.albumDataModel.photoSelectAssetsModels;
    }
    if (self.resourceType == AWEGetResourceTypeVideo) {
        return self.albumDataModel.videoSelectAssetsModels;
    }
    return self.albumDataModel.mixedSelectAssetsModels;
}

- (NSMutableArray<CAKAlbumAssetModel *> *)currentHandleSelectAssetModels
{
    if (self.resourceType == AWEGetResourceTypeImage) {
        return self.albumDataModel.photoSelectAssetsModels;
    } else if (self.resourceType == AWEGetResourceTypeVideo) {
        return self.albumDataModel.videoSelectAssetsModels;
    } else {
        return self.albumDataModel.mixedSelectAssetsModels;
    }
}

- (NSInteger)defaultSelectedIndex
{
    NSInteger index = 0;
    for (UIViewController<CAKAlbumListViewControllerProtocol> *listVC in self.tabsInfo) {
        if ([listVC.tabIdentifier isEqualToString:self.listViewConfig.defaultTabIdentifier]) {
            return index;
        }
        index++;
    }
    return 0;
}

- (CGFloat)choosedTotalDuration
{
    if (ACC_isEmptyArray(self.currentSelectAssetModels)) {
        return 0;
    }
    
    __block CGFloat duration = 0;
    [self.currentSelectAssetModels enumerateObjectsUsingBlock:^(CAKAlbumAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        duration += obj.phAsset.duration;
    }];
    
    return duration;
}

- (BOOL)hasSelectedVideo
{
    return self.albumDataModel.videoSelectAssetsModels.count > 0;
}

- (BOOL)hasSelectedPhoto
{
    return self.albumDataModel.photoSelectAssetsModels.count > 0;
}

- (BOOL)hasSelectedAssets
{
    return self.currentSelectAssetModels.count > 0;
}

- (BOOL)hasSelectedMaxCount
{
    return self.currentSelectAssetModels.count >= [self maxSelectionCount] && !self.listViewConfig.withoutCountLimitation;
}

- (BOOL)hasVideoSelectedMaxCount
{
    return self.albumDataModel.videoSelectAssetsModels.count >= [self videoMaxSelectionCount] && !self.listViewConfig.withoutCountLimitation;
}

- (BOOL)hasPhotoSelectedMaxCount
{
    return self.albumDataModel.photoSelectAssetsModels.count >= [self photoMaxSelectionCount] && !self.listViewConfig.withoutCountLimitation;
}

- (NSUInteger)videoMaxSelectionCount
{
    return MIN(self.listViewConfig.maxAssetsSelectionCount - self.albumDataModel.photoSelectAssetsModels.count, self.listViewConfig.maxVideoAssetsSelectionCount) - [self p_initialVideoSelectedAssetsCount];
}

- (NSUInteger)photoMaxSelectionCount
{
    return MIN(self.listViewConfig.maxAssetsSelectionCount - self.albumDataModel.videoSelectAssetsModels.count, self.listViewConfig.maxPhotoAssetsSelectionCount) - [self p_initialPhotoSelectedAssetsCount];
}

- (NSInteger)currentSelectedAssetsCount
{
    return [self currentSelectAssetModels].count;
}

- (AWEGetResourceType)resourceType
{
    UIViewController<CAKAlbumListViewControllerProtocol> *listVC = [self.tabsInfo acc_objectAtIndex:self.currentSelectedIndex];
    if ([listVC.tabIdentifier isEqualToString:CAKAlbumTabIdentifierImage]) {
        return AWEGetResourceTypeImage;
    }
    
    if ([listVC.tabIdentifier isEqualToString:CAKAlbumTabIdentifierVideo]) {
        return AWEGetResourceTypeVideo;
    }
    
    if ([listVC.tabIdentifier isEqualToString:CAKAlbumTabIdentifierAll]) {
        return AWEGetResourceTypeImageAndVideo;
    }
    return AWEGetResourceTypeImageAndVideo;
}

- (NSArray<NSString *> *)titles
{
    NSMutableArray<NSString *> *array = [NSMutableArray array];
    for (UIViewController<CAKAlbumListViewControllerProtocol> *item in self.tabsInfo) {
        [array acc_addObject:item.title];
    }
    return array.copy;
}

#pragma mark - public

- (UIViewController<CAKAlbumListViewControllerProtocol> *)albumListVCWithResourceType:(AWEGetResourceType)type
{
    return nil;
}

- (void)reloadAssetsDataWithResourceType:(AWEGetResourceType)resourceType useCache:(BOOL)useCache
{
    @weakify(self);
    [self p_reloadAssetsDataWithResourceType:resourceType useCache:useCache completion:^(PHFetchResult *result, BOOL (^filterBlock)(PHAsset *phasset)) {
        @strongify(self);
        [self p_updateSourceAssetsWithResourceType:resourceType fetchResult:result filterBlock:filterBlock needResetTable:NO];
        [self p_registerPhotoLibraryChangeObserver];
    }];
}

- (void)reloadAssetsDataWithAlbumCategory:(CAKAlbumModel * _Nullable)albumModel completion:(void (^)(void))completion
{
    if ([self.albumDataModel.albumModel.localIdentifier isEqual:albumModel.localIdentifier]) {
        return;
    }
    
    self.albumDataModel.albumModel = albumModel;
    [self.albumDataModel setupAssetModelProvider];
    @weakify(self);
    [self doActionForAllListVC:^(UIViewController<CAKAlbumListViewControllerProtocol> * _Nonnull listViewController, NSInteger index) {
        @strongify(self);
        AWEGetResourceType resourceType = [self p_tabIdentifierToResourceType:listViewController.tabIdentifier];
        [self p_reloadAssetsDataWithResourceType:resourceType useCache:YES completion:^(PHFetchResult *result, BOOL (^filter)(PHAsset *phasset)) {
            @strongify(self);
            [self p_updateSourceAssetsWithResourceType:resourceType fetchResult:result filterBlock:filter needResetTable:YES];
            ACCBLOCK_INVOKE(completion);
            [self p_registerPhotoLibraryChangeObserver];
        }];
    }];
}

- (void)didSelectedAsset:(CAKAlbumAssetModel *)model
{
    if (!model) {
        return;
    }
    
    if (![self.currentSelectedListVC respondsToSelector:@selector(resourceType)] || ![self.currentSelectedListVC respondsToSelector:@selector(tabConfig)]) {
        return;
    }
    
    if (!self.currentSelectedListVC.tabConfig.enableMultiSelect) {
        if (self.listViewConfig.enableMixedUpload) {
            [self clearSelectedAssetsArray];
        } else {
            [self p_clearSelectedAssetsForResourceType:self.currentSelectedListVC.resourceType];
        }
    }
    
    self.albumDataModel.addAssetInOrder = self.listViewConfig.addAssetInOrder;
    model.cellIndexPath = [NSIndexPath indexPathForRow:self.currentInsertIndex inSection:0];
    
    if (self.listViewConfig.enableMixedUpload) {
        [self p_didSelectedAssetWithMixedUpload:model];
    } else {
        [self p_didSelectedAssetWithoutMixedUpload:model];
    }
}

- (void)didUnselectedAsset:(CAKAlbumAssetModel *)model
{
    if (!model) {
        return;
    }
    
    self.albumDataModel.removeAssetInOrder = self.listViewConfig.enableAssetsRepeatedSelect;
    
    if (self.listViewConfig.enableMixedUpload) {
        [self p_didUnselectedAssetWithMixedUpload:model];
    } else {
        [self p_didUnselectedAssetWithoutMixedUpload:model];
    }
}

- (void)updateCurrentSelectedIndex:(NSInteger)index
{
    self.currentSelectedIndex = index;
}

- (void)updateCurrentInsertIndex:(NSInteger)currentInsertIndex
{
    self.currentInsertIndex = currentInsertIndex;
}

- (void)updateAssetModel:(CAKAlbumAssetModel *)model
{
    CAKAlbumAssetModel *ret = [self p_findAssetWithAssetModels:self.currentSelectAssetModels localIdentifier:model.phAsset.localIdentifier];
    
    if (ret) {
        model.selectedNum = ret.selectedNum;
    } else {
        model.selectedNum = nil;
    }
}

- (void)updateSelectedAssetsNumber
{
    if (self.listViewConfig.enableMixedUpload) {
        for (NSInteger i = 0; i < self.currentSelectAssetModels.count; i++) {
            CAKAlbumAssetModel *asset = [self.currentSelectAssetModels acc_objectAtIndex:i];
            asset.selectedNum = @(i + 1);
        }
    } else {
        for (NSInteger i = 0; i < self.albumDataModel.mixedSelectAssetsModels.count; i++) {
            CAKAlbumAssetModel *mixedTmp = [self.albumDataModel.mixedSelectAssetsModels acc_objectAtIndex:i];
            CAKAlbumAssetModel *photoTmp = [self p_findAssetWithAssetModels:self.albumDataModel.photoSelectAssetsModels localIdentifier:mixedTmp.phAsset.localIdentifier];
            CAKAlbumAssetModel *videoTmp = [self p_findAssetWithAssetModels:self.albumDataModel.videoSelectAssetsModels localIdentifier:mixedTmp.phAsset.localIdentifier];
            mixedTmp.selectedNum = @(i + 1);
            photoTmp.selectedNum = @(i + 1);
            videoTmp.selectedNum = @(i + 1);
        }
    }
}

- (void)prefetchAlbumListWithCompletion:(void (^)(void))completion
{
    NSInteger needReloadTab = 0;
    AWEGetResourceType type = AWEGetResourceTypeVideo;
    for (UIViewController<CAKAlbumListViewControllerProtocol> *listVC in self.tabsInfo) {
        if ([listVC.tabIdentifier isEqualToString:CAKAlbumTabIdentifierImage] ||
            [listVC.tabIdentifier isEqualToString:CAKAlbumTabIdentifierVideo] ||
            [listVC.tabIdentifier isEqualToString:CAKAlbumTabIdentifierAll]) {
            type = [self p_tabIdentifierToResourceType:listVC.tabIdentifier];
            needReloadTab++;
        }
    }
    
    if (needReloadTab > 1) {
        type = AWEGetResourceTypeImageAndVideo;
    }
    dispatch_async(self.assetCache.loadingQueue, ^{
        [CAKPhotoManager getAllAlbumsForMVWithType:type completion:^(NSArray<CAKAlbumModel *> *albumModels) {
            acc_dispatch_main_async_safe(^{
                self.albumDataModel.allAlbumModels = albumModels;
                ACCBLOCK_INVOKE(completion);
            });
        }];
    });
}

- (void)clearSelectedAssetsArray
{
    [self.albumDataModel removeAllAssetsForResourceType:AWEGetResourceTypeImage];
    [self.albumDataModel removeAllAssetsForResourceType:AWEGetResourceTypeVideo];
    [self.albumDataModel removeAllAssetsForResourceType:AWEGetResourceTypeImageAndVideo];
}

- (NSUInteger)maxSelectionCount
{
    return self.listViewConfig.maxAssetsSelectionCount - [self p_initialSelectedAssetsCount];
}

- (NSIndexPath *)indexPathForOffset:(NSInteger)offset resourceType:(AWEGetResourceType)type
{
    if (offset <= 0) {
        return [NSIndexPath indexPathForRow:0 inSection:0];
    }
    NSInteger col = 0;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    for (CAKAlbumSectionModel *section in [self dataSourceWithResourceType:type]) {
        if (offset > [section.assetDataModel numberOfObject]) {
            offset = offset - [section.assetDataModel numberOfObject];
            col++;
        } else {
            indexPath = [NSIndexPath indexPathForRow:offset inSection:col];
        }
    }

    return indexPath;
}

- (CAKAlbumAssetDataModel *)currentAssetDataModel
{
    return [self p_assetDataModelForResourceType:self.resourceType];
}

- (BOOL)isExceededMaxSelectableDuration:(NSTimeInterval)duration
{
    return duration > self.listViewConfig.videoSelectableMaxSeconds || [self choosedTotalDuration] + duration > self.listViewConfig.videoSelectableMaxSeconds;
}

- (void)doActionForAllListVC:(void (^)(UIViewController<CAKAlbumListViewControllerProtocol> * _Nonnull listViewController, NSInteger index))actionBlock
{
    for (UIViewController<CAKAlbumListViewControllerProtocol> *item in self.tabsInfo) {
        NSInteger index = [self.tabsInfo indexOfObject:item];
        ACCBLOCK_INVOKE(actionBlock, item, index);
    }
}

- (NSArray<CAKAlbumSectionModel *> *)dataSourceWithResourceType:(AWEGetResourceType)type
{
    CAKAlbumAssetDataModel *dataModel = [self p_assetDataModelForResourceType:type];
    CAKAlbumSectionModel *sectionModel = [CAKAlbumSectionModel new];
    sectionModel.title = @"";
    sectionModel.resourceType = type;
    sectionModel.assetDataModel = dataModel;
    return @[sectionModel];
}

- (void)handleSelectedAssets:(NSArray<CAKAlbumAssetModel *> *)assetModelArray completion:(void (^)(NSMutableArray<CAKAlbumAssetModel *> *))completion
{
    //add mask view
    UIView *maskView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    maskView.backgroundColor = [UIColor clearColor];
    [[[UIApplication sharedApplication].delegate window] addSubview:maskView];
    
    NSMutableArray *assetArray = [NSMutableArray array];
    self.lastVideoArray = assetArray;
    
    for (NSInteger i = 0; i < assetModelArray.count; i++) {
        [assetArray acc_addObject:@1];
    }
    
    for (NSInteger i = 0; i < assetModelArray.count; i++) {
        CAKAlbumAssetModel *assetModel = [[assetModelArray acc_objectAtIndex:i] copy];

        PHAsset *sourceAsset = assetModel.phAsset;
        const PHAssetMediaType mediaType = sourceAsset.mediaType;
        
        @weakify(self);
        if (PHAssetMediaTypeImage == mediaType) {
            [self p_fetchImageAsset:assetModel completion:^(CAKAlbumAssetModel *model) {
                if (model) {
                    [assetArray acc_replaceObjectAtIndex:i withObject:assetModel];
                    for (id item in assetArray) {
                        if ([item isKindOfClass:[NSNumber class]]) {
                            return;
                        }
                    }
                
                    [maskView removeFromSuperview];
                    ACCBLOCK_INVOKE(completion, assetArray);
                } else {
                    [maskView removeFromSuperview];
                    return;
                }
            }];
        } else if (PHAssetMediaTypeVideo == mediaType) {
            [self p_fetchVideoAsset:assetModel completion:^(CAKAlbumAssetModel *model, BOOL isICloud) {
                @strongify(self);
                if (!model && isICloud) {
                    ACCBLOCK_INVOKE(self.fetchIcloudStartBlock);
                    [self p_requestAVAssetFromiCloudWithModel:assetModel idx:i videoArr:assetArray assetModelArray:assetModelArray completion:^(CAKAlbumAssetModel *fetchedAsset, NSMutableArray *assetArray) {
                        ACCBLOCK_INVOKE(completion, assetArray);
                    }];
                    [maskView removeFromSuperview];
                    return;
                }
                
                if (model) {
                    [assetArray acc_replaceObjectAtIndex:i withObject:assetModel];
                    
                    for (id item in assetArray) {
                        if ([item isKindOfClass:[NSNumber class]]) {
                            return;
                        }
                    }
                    
                    [maskView removeFromSuperview];
                    ACCBLOCK_INVOKE(completion, assetArray);
                    return;
                }
                
                [maskView removeFromSuperview];
                ACCBLOCK_INVOKE(completion, nil);
            }];
        }
    }
}

- (void)preFetchAssetsWithListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC {
    if (![self p_hasAlbumAccessAuth]) {
        return;
    }
    UIViewController<CAKAlbumListViewControllerProtocol> *defaultVC = [self.tabsInfo acc_objectAtIndex:[self defaultSelectedIndex]];
    BOOL isCurrent = [listVC.tabIdentifier isEqualToString:defaultVC.tabIdentifier];
    [self.assetCache loadCollectionDataWithType:listVC.resourceType sortStyle:[self p_assetSortStyle] ascending:self.listViewConfig.assetsOrder == CAKAlbumAssetsOrderAscending fromAlbumModel:self.albumDataModel.albumModel isCurrent:isCurrent useCache:NO completion:nil];
}

- (void)setPrefetchData:(id)data {
    self.assetCache = [[CAKAlbumAssetCache alloc] initWithPrefetchData:data];
}

#pragma mark - private

- (CAKAlbumAssetSortStyle)p_assetSortStyle {
    if (self.cameraRoolCollection) {
        return self.listViewConfig.assetsSortStyle;
    }
    return CAKAlbumAssetSortStyleDefault;
}

- (BOOL)p_hasAlbumAccessAuth
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
#ifdef __IPHONE_14_0 //xcode12
    if (@available(iOS 14.0, *)) {
        status = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
    }
#endif
    if (status != PHAuthorizationStatusAuthorized) {
        return NO;
    }
    return YES;
}

- (void)p_registerPhotoLibraryChangeObserver
{
    if ([CAKPhotoManager isiOS14PhotoNotDetermined] && self.listViewConfig.enableiOS14AlbumAuthorizationGuide) {
        return;
    }
    if (!self.hasRegisterChangeObserver) {
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        self.hasRegisterChangeObserver = YES;
    }
}

- (void)p_configDefautTabsInfo
{
    UIViewController<CAKAlbumListViewControllerProtocol> *mixedViewController = [self albumListVCWithResourceType:AWEGetResourceTypeImageAndVideo];
    UIViewController<CAKAlbumListViewControllerProtocol> *videoViewController = [self albumListVCWithResourceType:AWEGetResourceTypeVideo];
    UIViewController<CAKAlbumListViewControllerProtocol> *photoViewController = [self albumListVCWithResourceType:AWEGetResourceTypeImage];

    NSMutableArray *tabsInfo = [NSMutableArray array];
    if (self.listViewConfig.mixedAssetsTabConfig.enableTab && self.listViewConfig.enableMixedUpload) {
        [tabsInfo acc_addObject:mixedViewController];
    }
    if (self.listViewConfig.videoAssetsTabConfig.enableTab) {
        [tabsInfo acc_addObject:videoViewController];
    }
    
    if (self.listViewConfig.photoAssetsTabConfig.enableTab) {
        [tabsInfo acc_addObject:photoViewController];
    }
    self.tabsInfo = tabsInfo.copy;
}

- (void)p_loadCameraRollCollectionIfNeeded {
    if (![self p_hasAlbumAccessAuth]) {
        return;
    }
    if (_listViewConfig.assetsSortStyle == CAKAlbumAssetSortStyleRecent) {
        _cameraRoolCollection = [CAKPhotoManager getCamraRoolAssetCollection];

        CAKAlbumModel *model = [[CAKAlbumModel alloc] init];
        model.assetCollection = _cameraRoolCollection;
        _albumDataModel.albumModel = model;
    }
}

- (void)p_prefetchAssetsIfNeeded {
    for (UIViewController<CAKAlbumListViewControllerProtocol> *listVC in self.tabsInfo) {
        BOOL enableAlbumLandingOpt = [CAKPhotoManager enableAlbumLoadOpt];
        if (enableAlbumLandingOpt) {
            [self preFetchAssetsWithListVC:listVC];
        }
    }
}

- (void)p_didSelectedAssetWithMixedUpload:(CAKAlbumAssetModel *)model
{
    model.selectedNum = @([self currentSelectAssetModels].count + 1);
    
    if (![self.currentSelectedListVC respondsToSelector:@selector(tabConfig)]) {
        return;
    }
    
    if (!self.currentSelectedListVC.tabConfig.enableMultiSelect) {
        model.selectedNum = nil;
    }
    [self.albumDataModel addAsset:model forResourceType:self.resourceType];
    
    // synchronize selected data
    if (self.resourceType != AWEGetResourceTypeImageAndVideo) {
        [self p_updateAssetModel:model type:AWEGetResourceTypeImageAndVideo isSelected:YES];
    }
    
    if (self.resourceType != AWEGetResourceTypeImage) {
        [self p_updateAssetModel:model type:AWEGetResourceTypeImage isSelected:YES];
    }
    
    if (self.resourceType != AWEGetResourceTypeVideo) {
        [self p_updateAssetModel:model type:AWEGetResourceTypeVideo isSelected:YES];
    }
}

- (void)p_didSelectedAssetWithoutMixedUpload:(CAKAlbumAssetModel *)model
{
    // udpate selected number
    model.selectedNum = @(self.currentHandleSelectAssetModels.count + 1);

    if (![self.currentSelectedListVC respondsToSelector:@selector(tabConfig)]) {
        return;
    }
    
    if (!self.currentSelectedListVC.tabConfig.enableMultiSelect) {
        model.selectedNum = nil;
    }
    [self.albumDataModel addAsset:model forResourceType:self.resourceType];
}

- (void)p_didUnselectedAssetWithMixedUpload:(CAKAlbumAssetModel *)model
{
    model.selectedNum = nil;
    [self p_updateAssetModel:model type:AWEGetResourceTypeImageAndVideo isSelected:NO];
    [self p_updateAssetModel:model type:AWEGetResourceTypeImage isSelected:NO];
    [self p_updateAssetModel:model type:AWEGetResourceTypeVideo isSelected:NO];
    // udpate selected number
    for (NSInteger i = 0; i < self.albumDataModel.mixedSelectAssetsModels.count; i++) {
        CAKAlbumAssetModel *mixedTmp = self.albumDataModel.mixedSelectAssetsModels[i];
        CAKAlbumAssetModel *photoTmp = [self p_findAssetWithAssetModels:self.albumDataModel.photoSelectAssetsModels localIdentifier:mixedTmp.phAsset.localIdentifier];
        CAKAlbumAssetModel *videoTmp = [self p_findAssetWithAssetModels:self.albumDataModel.videoSelectAssetsModels localIdentifier:mixedTmp.phAsset.localIdentifier];
        mixedTmp.selectedNum = @(i + 1);
        photoTmp.selectedNum = @(i + 1);
        videoTmp.selectedNum = @(i + 1);
    }
}

- (void)p_didUnselectedAssetWithoutMixedUpload:(CAKAlbumAssetModel *)model
{
    model.selectedNum = nil;
    CAKAlbumAssetModel *selectModel = [self p_findAssetWithAssetModels:self.currentHandleSelectAssetModels localIdentifier:model.phAsset.localIdentifier];
    selectModel.selectedNum = nil;
    [self.albumDataModel removeAsset:model forResourceType:self.resourceType];
    
    // udpate selected number
    for (NSInteger i = 0; i < self.currentHandleSelectAssetModels.count; i++) {
        CAKAlbumAssetModel *model = self.currentHandleSelectAssetModels[i];
        model.selectedNum = @(i + 1);
    }
}

- (void)p_reloadAssetsDataWithResourceType:(AWEGetResourceType)resourceType useCache:(BOOL)useCache completion:(void (^)(PHFetchResult *result, BOOL (^filter)(PHAsset *phasset)))completion
{
    CAKAlbumModel *targetAlbum = self.albumDataModel.albumModel;
    if (self.albumDataModel.albumModel) {
        for (CAKAlbumModel *item in self.albumDataModel.allAlbumModels) {
            if ([self.albumDataModel.albumModel.localIdentifier isEqual:item.localIdentifier]) {
                targetAlbum = item;
                break;
            }
        }
    }
    
    BOOL enableAlbumLandingOpt = [CAKPhotoManager enableAlbumLoadOpt];
    if (enableAlbumLandingOpt) {
        [self.assetCache loadCollectionDataWithType:resourceType sortStyle:[self p_assetSortStyle] ascending:self.listViewConfig.assetsOrder == CAKAlbumAssetsOrderAscending fromAlbumModel:targetAlbum isCurrent:resourceType == self.currentSelectedListVC.resourceType useCache:useCache completion:^(PHFetchResult * _Nonnull result) {
            acc_dispatch_main_async_safe(^{
                ACCBLOCK_INVOKE(completion, result, nil);
            });
        }];
    } else {
        if (!targetAlbum) {
            [CAKPhotoManager getAllAssetsWithType:resourceType sortStyle:self.listViewConfig.assetsSortStyle ascending:self.listViewConfig.assetsOrder == CAKAlbumAssetsOrderAscending completion:^(PHFetchResult * _Nonnull result) {
                acc_dispatch_main_async_safe(^{
                    ACCBLOCK_INVOKE(completion, result, nil);
                });
            }];
        } else {
            @weakify(self);
            BOOL (^filterBlock)(PHAsset *phasset) = ^BOOL(PHAsset *phasset){
                @strongify(self);
                return [self p_validPHAsset:phasset resourceType:resourceType];
            };
            ACCBLOCK_INVOKE(completion, targetAlbum.result, filterBlock);
        }
    }
}

- (void)p_updateSourceAssetsWithResourceType:(AWEGetResourceType)resourceType fetchResult:(PHFetchResult *)fetchResult filterBlock:(BOOL(^)(PHAsset *asset))filterBlock needResetTable:(BOOL)needResetTable
{
    switch (resourceType) {
        case AWEGetResourceTypeImageAndVideo: {
            self.albumDataModel.fetchResult = fetchResult;
            CAKAlbumAssetModelManager *manager = [CAKAlbumAssetModelManager createWithPHFetchResult:fetchResult provider:self.albumDataModel.assetModelProvider];
            self.albumDataModel.mixedSourceAssetsDataModel = [self p_createAsstDataModelRourceType:resourceType manager:manager filterBlock:filterBlock];
            [self.albumDataModel.resultSourceAssetsSubject sendNext:RACTuplePack(self.albumDataModel.mixedSourceAssetsDataModel, @(needResetTable))];

        } break;
        case AWEGetResourceTypeImage: {
            if ([CAKPhotoManager enableAlbumLoadOpt]) {
                self.albumDataModel.fetchResult = fetchResult;
            } else {
                if (!self.albumDataModel.fetchResult) {
                    self.albumDataModel.fetchResult = fetchResult;
                }
            }
            CAKAlbumAssetModelManager *manager = [CAKAlbumAssetModelManager createWithPHFetchResult:fetchResult provider:self.albumDataModel.assetModelProvider];
            self.albumDataModel.photoSourceAssetsDataModel = [self p_createAsstDataModelRourceType:AWEGetResourceTypeImage manager:manager filterBlock:filterBlock];
            [self.albumDataModel.resultSourceAssetsSubject sendNext:RACTuplePack(self.albumDataModel.photoSourceAssetsDataModel, @(needResetTable))];
        } break;
        case AWEGetResourceTypeVideo: {
            if ([CAKPhotoManager enableAlbumLoadOpt]) {
                self.albumDataModel.fetchResult = fetchResult;
            } else {
                if (!self.albumDataModel.fetchResult) {
                    self.albumDataModel.fetchResult = fetchResult;
                }
            }
            CAKAlbumAssetModelManager *manager = [CAKAlbumAssetModelManager createWithPHFetchResult:fetchResult provider:self.albumDataModel.assetModelProvider];
            self.albumDataModel.videoSourceAssetsDataModel = [self p_createAsstDataModelRourceType:AWEGetResourceTypeVideo manager:manager filterBlock:filterBlock];
            [self.albumDataModel.resultSourceAssetsSubject sendNext:RACTuplePack(self.albumDataModel.videoSourceAssetsDataModel, @(needResetTable))];
        } break;
        default:
            break;
    }
    [self p_synchronizeInitialSelectedAssetModelArray];
}

- (void)p_synchronizeInitialSelectedAssetModelArray
{
    if (ACC_isEmptyArray(self.listViewConfig.initialSelectedAssetModelArray)) {
        return;
    }
    if (self.listViewConfig.initialSelectedAssetModelArray.count > 0 && self.listViewConfig.enableSyncInitialSelectedAssets) {
        acc_dispatch_queue_async_safe(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray<CAKAlbumAssetModel *> *selectedFetchedAssets = [NSMutableArray arrayWithCapacity:self.listViewConfig.initialSelectedAssetModelArray.count];
            CAKAlbumAssetDataModel *dataModel = [self p_assetDataModelForResourceType:self.resourceType];
            [[self.listViewConfig.initialSelectedAssetModelArray copy] enumerateObjectsUsingBlock:^(CAKAlbumAssetModel * _Nonnull initialSelectedAsset, NSUInteger idx, BOOL * _Nonnull stop) {
                [dataModel.assetModelManager.fetchResult enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([initialSelectedAsset.phAsset.localIdentifier isEqualToString:asset.localIdentifier]) {
                        CAKAlbumAssetModel *fetchedAsset = [dataModel.assetModelManager objectIndex:idx];
                        [selectedFetchedAssets acc_addObject:fetchedAsset];
                        *stop = YES;
                    }
                }];
            }];
            self.listViewConfig.initialSelectedAssetModelArray = @[];
            acc_dispatch_main_async_safe(^{
                for (CAKAlbumAssetModel *asset in selectedFetchedAssets) {
                    [self didSelectedAsset:asset];
                }
                self.initialSelectedAssetsSynchronized = YES;
            });
        });
    }
}

- (void)p_updateAssetModel:(CAKAlbumAssetModel *)model type:(AWEGetResourceType)type isSelected:(BOOL)selected
{
    if (AWEGetResourceTypeImage == type && model.phAsset.mediaType != PHAssetMediaTypeImage) {
        return;
    }
        
    if (AWEGetResourceTypeVideo == type && model.phAsset.mediaType != PHAssetMediaTypeVideo) {
        return;
    }
    CAKAlbumAssetDataModel *dataModel = [self p_assetDataModelForResourceType:type];
    CAKAlbumAssetModel *sameModel = [dataModel.assetModelManager objectIndex:[dataModel.assetModelManager indexOfObject:model]];
    sameModel.coverImage = model.coverImage;
    sameModel.selectedNum = selected ? [model.selectedNum copy] : nil;
    if (!dataModel && [self p_checkSameTypeWithModel:model type:type]) {
        sameModel = model;
    }
    if (selected) {
        [self.albumDataModel addAsset:sameModel forResourceType:type];
    } else {
        // 删除的场景
        sameModel = [self.albumDataModel findAssetWithResourceType:type localIdentifier:model.phAsset.localIdentifier];
        if (self.listViewConfig.enableAssetsRepeatedSelect) {
            sameModel.cellIndexPath = model.cellIndexPath;
        }
        [self.albumDataModel removeAsset:sameModel forResourceType:type];
    }
}

- (BOOL)p_checkSameTypeWithModel:(CAKAlbumAssetModel *)model type:(AWEGetResourceType)type
{
    if (type == AWEGetResourceTypeImageAndVideo) {
        return model.mediaType == CAKAlbumAssetModelMediaTypeVideo || model.mediaType == CAKAlbumAssetModelMediaTypePhoto;
    } else if (type == AWEGetResourceTypeImage) {
        return model.mediaType == CAKAlbumAssetModelMediaTypePhoto;
    } else if (type == AWEGetResourceTypeVideo) {
        return model.mediaType == CAKAlbumAssetModelMediaTypeVideo;
    }
    return NO;
}

- (CAKAlbumAssetModel *)p_findAssetWithAssetModels:(NSMutableArray<CAKAlbumAssetModel *> *)models localIdentifier:(NSString *)localIdentifier
{
    if (ACC_isEmptyArray(models) || ACC_isEmptyString(localIdentifier)) {
        return nil;
    }
    
    for (CAKAlbumAssetModel *model in models) {
        if ([model.phAsset.localIdentifier isEqual:localIdentifier]) {
            return model;
        }
    }
    
    return nil;
}

- (void)p_clearSelectedAssetsForResourceType:(AWEGetResourceType)resourceType
{
    if (resourceType == AWEGetResourceTypeImage) {
        [self.albumDataModel.photoSelectAssetsModels enumerateObjectsUsingBlock:^(CAKAlbumAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.albumDataModel removeAsset:obj forResourceType:AWEGetResourceTypeImageAndVideo];
        }];
        [self.albumDataModel removeAllAssetsForResourceType:AWEGetResourceTypeImage];
        return;
    }
    
    if (resourceType == AWEGetResourceTypeVideo) {
        [self.albumDataModel.videoSelectAssetsModels enumerateObjectsUsingBlock:^(CAKAlbumAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.albumDataModel removeAsset:obj forResourceType:AWEGetResourceTypeImageAndVideo];
        }];
        [self.albumDataModel removeAllAssetsForResourceType:AWEGetResourceTypeVideo];
        return;
    }
    
    if (resourceType == AWEGetResourceTypeImageAndVideo) {
        [self clearSelectedAssetsArray];
    }
}

- (CAKAlbumAssetDataModel *)p_assetDataModelForResourceType:(AWEGetResourceType)type
{
    CAKAlbumAssetDataModel *dataModel;
    switch (type) {
        case AWEGetResourceTypeImageAndVideo:
            dataModel = self.albumDataModel.mixedSourceAssetsDataModel;
            break;
        case AWEGetResourceTypeImage:
            dataModel = self.albumDataModel.photoSourceAssetsDataModel;
            break;
        case AWEGetResourceTypeVideo:
            dataModel = self.albumDataModel.videoSourceAssetsDataModel;
            break;
        default:
            dataModel = self.albumDataModel.mixedSourceAssetsDataModel;
            break;
    }
    return dataModel;
}

- (NSMutableArray<CAKAlbumAssetModel *> *)p_currentSelectAssetsWithResourceType:(AWEGetResourceType)resourceType
{
    if (resourceType == AWEGetResourceTypeImage) {
        return self.albumDataModel.photoSelectAssetsModels;
    } else if (resourceType == AWEGetResourceTypeVideo) {
        return self.albumDataModel.videoSelectAssetsModels;
    } else if (resourceType == AWEGetResourceTypeImageAndVideo) {
        return self.albumDataModel.mixedSelectAssetsModels;
    }
    
    return nil;
}

- (CAKAlbumAssetDataModel *)p_createAsstDataModelRourceType:(AWEGetResourceType)resourceType manager:(CAKAlbumAssetModelManager *)manager filterBlock:(BOOL(^)(PHAsset *asset))filterBlock
{
    CAKAlbumAssetDataModel *dataModel = [CAKAlbumAssetDataModel new];
    dataModel.resourceType = resourceType;
    dataModel.assetModelManager = manager;
    if (filterBlock) {
        [dataModel configShowIndexFilterBlock:filterBlock];
    }
    return dataModel;
}

- (void)p_updateSelectAssets:(NSMutableArray<CAKAlbumAssetModel *> *)assetModelArray resourceType:(AWEGetResourceType)resourceType
{
    if (resourceType == AWEGetResourceTypeImage) {
        self.albumDataModel.photoSelectAssetsModels = assetModelArray;
    } else if (resourceType == AWEGetResourceTypeVideo) {
        self.albumDataModel.videoSelectAssetsModels = assetModelArray;
    } else if (resourceType == AWEGetResourceTypeImageAndVideo) {
        self.albumDataModel.mixedSelectAssetsModels = assetModelArray;
    }
}

- (AWEGetResourceType)p_tabIdentifierToResourceType:(NSString *)tabIdentifier
{
    if ([tabIdentifier isEqualToString:CAKAlbumTabIdentifierImage]) {
        return AWEGetResourceTypeImage;
    }
    
    if ([tabIdentifier isEqualToString:CAKAlbumTabIdentifierVideo]) {
        return AWEGetResourceTypeVideo;
    }
    
    if ([tabIdentifier isEqualToString:CAKAlbumTabIdentifierAll]) {
        return AWEGetResourceTypeImageAndVideo;
    }
    return AWEGetResourceTypeImageAndVideo;
}

- (BOOL)p_validPHAsset:(PHAsset *)phasset resourceType:(AWEGetResourceType)resourceType
{
    if (resourceType == AWEGetResourceTypeImage) {
        return phasset.mediaType == PHAssetMediaTypeImage;
    } else if (resourceType == AWEGetResourceTypeVideo) {
        return phasset.mediaType == PHAssetMediaTypeVideo;
    } else if (resourceType == AWEGetResourceTypeImageAndVideo) {
        return phasset.mediaType == PHAssetMediaTypeImage || phasset.mediaType == PHAssetResourceTypeVideo;
    }
    return NO;
}

- (NSInteger)p_initialSelectedAssetsCount
{
    if (self.listViewConfig.initialSelectedAssetModelArray) {
        return self.listViewConfig.initialSelectedAssetModelArray.count;
    }
    return 0;
}

- (NSInteger)p_initialVideoSelectedAssetsCount
{
    NSUInteger count = 0;
    if (self.listViewConfig.initialSelectedAssetModelArray) {
        for (CAKAlbumAssetModel *asset in self.listViewConfig.initialSelectedAssetModelArray) {
            if (asset.mediaType == CAKAlbumAssetModelMediaTypeVideo) {
                count += 1;
            }
        }
        return count;
    }
    return count;
}

- (NSInteger)p_initialPhotoSelectedAssetsCount
{
    NSUInteger count = 0;
    if (self.listViewConfig.initialSelectedAssetModelArray) {
        for (CAKAlbumAssetModel *asset in self.listViewConfig.initialSelectedAssetModelArray) {
            if (asset.mediaType == CAKAlbumAssetModelMediaTypePhoto) {
                count += 1;
            }
        }
        return count;
    }
    return count;
}

- (void)p_fetchImageAsset:(CAKAlbumAssetModel *)assetModel completion:(void (^)(CAKAlbumAssetModel *model))completion
{
    PHAsset *sourceAsset = assetModel.phAsset;
    CGSize imageSize = CGSizeMake(720, 1280);
    if ([UIDevice acc_isBetterThanIPhone7]) {
        imageSize = CGSizeMake(1080, 1920);
    }
    
    [CAKPhotoManager getUIImageWithPHAsset:sourceAsset
                                 imageSize:imageSize
                      networkAccessAllowed:YES
                           progressHandler:^(CGFloat progress, NSError *error, BOOL *stop, NSDictionary *info) {}
                                completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        if (isDegraded) {
            return;
        }
        if (photo) {
            assetModel.highQualityImage = photo;
            assetModel.coverImage = photo;
        }
        ACCBLOCK_INVOKE(completion, assetModel);
    }];
}

- (void)p_fetchVideoAsset:(CAKAlbumAssetModel *)assetModel completion:(void (^)(CAKAlbumAssetModel *model, BOOL isICloud))completion
{
    PHAsset *sourceAsset = assetModel.phAsset;
    NSURL *url = [sourceAsset valueForKey:@"ALAssetURL"];
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    if (@available(iOS 14.0, *)) {
        options.version = PHVideoRequestOptionsVersionCurrent;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    }
    
    [CAKPhotoManager getAVAssetWithPHAsset:sourceAsset options:options completion:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        void (^completionBlock)(AVAsset *_Nullable blockAsset, AVAudioMix *_Nullable audioMix, NSDictionary *_Nullable info) = ^(AVAsset *_Nullable blockAsset, AVAudioMix *_Nullable audioMix, NSDictionary *_Nullable info){
            acc_dispatch_main_async_safe(^{
                BOOL isICloud = [info[PHImageResultIsInCloudKey] boolValue];
                assetModel.isFromICloud = isICloud;
                
                if (isICloud && !blockAsset) {
                    ACCBLOCK_INVOKE(completion, nil, YES);
                } else if(blockAsset) {
                    assetModel.avAsset = blockAsset;
                    if (ACCSYSTEM_VERSION_LESS_THAN(@"9") && assetModel.mediaSubType == CAKAlbumAssetModelMediaSubTypeVideoHighFrameRate) {
                        AVURLAsset *urlAsset = [AVURLAsset assetWithURL:url];
                        if (urlAsset) {
                            assetModel.avAsset = urlAsset;
                        }
                    }
                    assetModel.info = info;
                    
                    AWELogToolInfo(AWELogToolTagImport, @"AIClip: [export] block asset is not nil, info: %@", info);
                    ACCBLOCK_INVOKE(completion, assetModel, NO);
                } else {
                    //fetch failed
                    acc_dispatch_main_async_safe(^{
                        ACCBLOCK_INVOKE(self.fetchIcloudErrorBlock, info);
                    });
                    
                    if (info != nil) {
                        AWELogToolInfo(AWELogToolTagImport, @"export: AIClip:info: %@", info);
                    } else {
                        AWELogToolInfo(AWELogToolTagImport, @"export: AIClip:info is nil");
                    }
                    
                    ACCBLOCK_INVOKE(completion, nil, NO);
                }
            });
        };
        
        BOOL isICloud = [info[PHImageResultIsInCloudKey] boolValue];
        if (!isICloud && !asset) {
            // some HD videos, when options.version is PHVideoRequestOptionsVersionCurrent, the requested avasset is nil;
            // the above case, use options for PHVideoRequestOptionsVersionOriginal request again, for compatibility;
            [self p_fetchVideoAsset:assetModel version:PHVideoRequestOptionsVersionOriginal resultHandler:^(AVAsset * _Nullable assetVersion, AVAudioMix * _Nullable audioMixVersion, NSDictionary * _Nullable infoVersion) {
                ACCBLOCK_INVOKE(completionBlock, assetVersion, audioMixVersion, infoVersion);
            }];
        } else {
            ACCBLOCK_INVOKE(completionBlock, asset, audioMix, info);
        }
    }];
}

- (void)p_fetchVideoAsset:(CAKAlbumAssetModel *)assetModel version:(PHVideoRequestOptionsVersion)version resultHandler:(void (^)(AVAsset *__nullable asset, AVAudioMix *__nullable audioMix, NSDictionary *__nullable info))resultHandler
{
    PHAsset *sourceAsset = assetModel.phAsset;
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.version = version;
    if (@available(iOS 14.0, *)) {
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    }
    
    [CAKPhotoManager getAVAssetWithPHAsset:sourceAsset options:options completion:resultHandler];
}

- (void)p_requestAVAssetFromiCloudWithModel:(CAKAlbumAssetModel *)assetModel
                                      idx:(NSUInteger)index
                                 videoArr:(NSMutableArray *)videoArray
                          assetModelArray:(NSArray *)assetModelArray
                               completion:(void (^)(CAKAlbumAssetModel *fetchedAsset, NSMutableArray *assetArray))completion
{
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.networkAccessAllowed = YES;

    //run animation ahead
    assetModel.didFailFetchingiCloudAsset = NO;
    assetModel.iCloudSyncProgress = 0.f;
    assetModel.canUnobserveAssetModel = NO;
    [self p_updateProgressAndErrorAndUnobserveFlagWithModel:assetModel];
    
    @weakify(self);//icloud download
    options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            if (assetModel && [self p_canUpdateiCloudAssetStatus] && [self.lastVideoArray isEqual:videoArray]) {
                assetModel.iCloudSyncProgress = progress;
                [self p_updateProgressWithModel:assetModel];
            }
        });
    };
    if (@available(iOS 14.0, *)) {
        options.version = PHVideoRequestOptionsVersionCurrent;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    }

    NSTimeInterval icloudFetchStart = CFAbsoluteTimeGetCurrent();
    PHAsset *sourceAsset = assetModel.phAsset;
    NSURL *url = [sourceAsset valueForKey:@"ALAssetURL"];
    [CAKPhotoManager getAVAssetWithPHAsset:sourceAsset options:options completion:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            if ([self p_canUpdateiCloudAssetStatus]) {
                if (asset) {
                    assetModel.avAsset = asset;
                    if (ACCSYSTEM_VERSION_LESS_THAN(@"9") && assetModel.mediaSubType == CAKAlbumAssetModelMediaSubTypeVideoHighFrameRate) {
                        AVURLAsset *urlAsset = [AVURLAsset assetWithURL:url];
                        if (urlAsset) {
                            assetModel.avAsset = urlAsset;
                        }
                    }
                    
                    assetModel.info = info;
                    if ([videoArray count] > index && assetModel) {
                        [videoArray acc_replaceObjectAtIndex:index withObject:assetModel];
                    }
                    
                    for (id item in videoArray) {
                        if ([item isKindOfClass:[NSNumber class]]) {
                            return;
                        }
                    }
                    
                    NSTimeInterval icloudDuration = (NSInteger)((CFAbsoluteTimeGetCurrent() - icloudFetchStart) * 1000);
                    __block CGFloat size = 0.f;
                    NSArray<AVAssetTrack *> *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
                    [tracks enumerateObjectsUsingBlock:^(AVAssetTrack * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        CGFloat rate = ([obj estimatedDataRate] / 8); // convert bits per second to bytes per second
                        CGFloat seconds = CMTimeGetSeconds([obj timeRange].duration);
                        size += seconds * rate;
                    }];
                    ACCBLOCK_INVOKE(self.fetchIcloudCompletion, icloudDuration, (NSInteger)size);
                    if ([assetModelArray count] && [self.lastVideoArray isEqual:videoArray]) {
                        acc_dispatch_main_async_safe(^{
                            //goto clip page
                            self.lastVideoArray = nil;
                            ACCBLOCK_INVOKE(completion, assetModel, videoArray);
                        });
                    }
                  
                    assetModel.canUnobserveAssetModel = YES;
                    assetModel.iCloudSyncProgress = 1.f;
                    [self p_updateProgressAndErrorAndUnobserveFlagWithModel:assetModel];
                } else {
                    //没有获取到照片
                    assetModel.didFailFetchingiCloudAsset = YES;
                    assetModel.iCloudSyncProgress = 0.f;
                    [self p_updateProgressAndErrorAndUnobserveFlagWithModel:assetModel];
                    acc_dispatch_main_async_safe(^{
                        ACCBLOCK_INVOKE(self.fetchIcloudErrorBlock, info);
                    });
                    if (info != nil) {
                        AWELogToolInfo(AWELogToolTagImport, @"import: [export] info: %@", info);
                    } else {
                        AWELogToolInfo(AWELogToolTagImport, @"import: [export] info is nil");
                    }
                }
            }
        });
    }];
}

- (void)p_updateProgressWithModel:(CAKAlbumAssetModel *)assetModel
{
    [self.currentSelectAssetModels enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(CAKAlbumAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.phAsset.localIdentifier && assetModel.phAsset.localIdentifier && [obj.phAsset.localIdentifier isEqualToString:assetModel.phAsset.localIdentifier]) {
            obj.iCloudSyncProgress = assetModel.iCloudSyncProgress;//cell has kvo
            *stop = YES;
        }
    }];
    [self.currentHandleSelectAssetModels enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(CAKAlbumAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.phAsset.localIdentifier && assetModel.phAsset.localIdentifier && [obj.phAsset.localIdentifier isEqualToString:assetModel.phAsset.localIdentifier]) {
            obj.iCloudSyncProgress = assetModel.iCloudSyncProgress;//cell has kvo
            *stop = YES;
        }
    }];
}

- (void)p_updateProgressAndErrorAndUnobserveFlagWithModel:(CAKAlbumAssetModel *)assetModel
{
    [self.currentSelectAssetModels enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(CAKAlbumAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.phAsset.localIdentifier && assetModel.phAsset.localIdentifier && [obj.phAsset.localIdentifier isEqualToString:assetModel.phAsset.localIdentifier]) {
            obj.didFailFetchingiCloudAsset = assetModel.didFailFetchingiCloudAsset;
            obj.canUnobserveAssetModel = assetModel.canUnobserveAssetModel;
            obj.iCloudSyncProgress = assetModel.iCloudSyncProgress;
            *stop = YES;
        }
    }];
    [self.currentHandleSelectAssetModels enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(CAKAlbumAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.phAsset.localIdentifier && assetModel.phAsset.localIdentifier && [obj.phAsset.localIdentifier isEqualToString:assetModel.phAsset.localIdentifier]) {
            obj.didFailFetchingiCloudAsset = assetModel.didFailFetchingiCloudAsset;
            obj.canUnobserveAssetModel = assetModel.canUnobserveAssetModel;
            obj.iCloudSyncProgress = assetModel.iCloudSyncProgress;
            *stop = YES;
        }
    }];
}

- (BOOL)p_canUpdateiCloudAssetStatus
{
    UIViewController *topVC = [ACCResponder topViewController];
    return topVC.view.window != nil;
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    BOOL enableAlbumLandingOpt = [CAKPhotoManager enableAlbumLoadOpt];
    if (enableAlbumLandingOpt) {
        [self.assetCache clear];
    }
    
    @weakify(self);
    [self prefetchAlbumListWithCompletion:^{
        @strongify(self);
        for (UIViewController<CAKAlbumListViewControllerProtocol> *listVC in self.tabsInfo) {
            if ([listVC respondsToSelector:@selector(resourceType)]) {
                [self p_checkPhotoLibraryDidChange:changeInstance resourceType:listVC.resourceType fetchResult:self.albumDataModel.fetchResult];
            }
        }
    }];
}

- (void)p_checkPhotoLibraryDidChange:(PHChange *)changeInstance resourceType:(AWEGetResourceType)resourceType fetchResult:(PHFetchResult *)result
{
    PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:result];
    BOOL needHandleFavoriteStateChange = changeInstance != nil && self.listViewConfig.enableDisplayFavoriteSymbol == YES;
    if (changeDetails == nil && result && (needHandleFavoriteStateChange == NO)) {
        return;
    }
    result = changeDetails.fetchResultAfterChanges;
    if (self.albumDataModel.albumModel) {
        CAKAlbumModel *targetAlbum = self.albumDataModel.albumModel;
        for (CAKAlbumModel *item in self.albumDataModel.allAlbumModels) {
            if ([self.albumDataModel.albumModel.localIdentifier isEqual:item.localIdentifier]) {
                targetAlbum = item;
                break;
            }
        }
        targetAlbum.result = result;
    }
    @weakify(self);
    [self p_reloadAssetsDataWithResourceType:resourceType useCache:NO completion:^(PHFetchResult *fetchResult, BOOL (^filter)(PHAsset *phasset)) {
        @strongify(self);
        NSMutableArray *newSelectAssetModelArray = [NSMutableArray array];
        NSMutableArray *deletedAssetModelArray = [NSMutableArray array];

        [self p_updateSourceAssetsWithResourceType:resourceType fetchResult:fetchResult filterBlock:filter needResetTable:NO];
        // update assets for delete case
        for (CAKAlbumAssetModel *assetModel in [self p_currentSelectAssetsWithResourceType:resourceType]) {
            __block BOOL assetDeleted = YES;
            [fetchResult enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([assetModel.phAsset.localIdentifier isEqualToString:asset.localIdentifier]) {
                    CAKAlbumAssetModel *obj = [[self p_assetDataModelForResourceType:resourceType].assetModelManager assetModelForPhAsset:asset];
                    if (obj) {
                        [newSelectAssetModelArray acc_addObject:obj];
                    }
                    assetDeleted = NO;
                    *stop = YES;
                }
            }];
            if (assetDeleted) {
                [deletedAssetModelArray acc_addObject:assetModel];
            }
        }
        for (CAKAlbumAssetModel *assetModel in deletedAssetModelArray) {
            [self didUnselectedAsset:assetModel];
        }

        // update assets for selected case
        for (CAKAlbumAssetModel *assetModel in [self p_currentSelectAssetsWithResourceType:resourceType]) {
            [newSelectAssetModelArray enumerateObjectsUsingBlock:^(CAKAlbumAssetModel *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([assetModel.phAsset.localIdentifier isEqualToString:obj.phAsset.localIdentifier]) {
                    obj.selectedNum = assetModel.selectedNum;
                    *stop = YES;
                }
            }];
        }
        if (!ACC_isEmptyArray(newSelectAssetModelArray)) {
            [self p_updateSelectAssets:newSelectAssetModelArray resourceType:resourceType];
        }
    }];
}

@end
