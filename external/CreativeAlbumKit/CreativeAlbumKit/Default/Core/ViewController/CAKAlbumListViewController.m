//
//  CAKAlbumListViewController.m
//  CameraClient
//
//  Created by lixingdong on 2020/6/16.
//

#import <Masonry/Masonry.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <KVOController/KVOController.h>
#import <ReactiveObjC/ReactiveObjC.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

#import "CAKAlbumListViewController.h"
#import "CAKAlbumAssetListCell.h"
#import "CAKLoadingProtocol.h"
#import "UIColor+AlbumKit.h"
#import "CAKLanguageManager.h"
#import "CAKAlbumZoomTransition.h"
#import "CAKAlbumPreviewAndSelectController.h"
#import "CAKPhotoManager.h"
#import "CAKAlbumAssetModel+Cover.h"

@interface CAKAlbumListViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, CAKAlbumZoomTransitionOuterContextProvider, CAKAlbumPreviewAndSelectControllerDelegate>

@property (nonatomic, assign) CGSize aspectRatio;

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) CAKAlbumListBlankView *blankContentView;

@property (nonatomic, assign) BOOL hasCheckedAndReload;
@property (nonatomic, strong) UIView<CAKTextLoadingViewProtocol> *loadingView;

@property (nonatomic, strong, readonly) NSArray<CAKAlbumSectionModel *> *dataSource;

@property (nonatomic, strong) CAKAlbumZoomTransitionDelegate *transitionDelegate;

@property (nonatomic, assign) BOOL previewFromBottom;
@property (nonatomic, assign) NSInteger selectedCellIndex;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@property (nonatomic, strong) CAKAlbumViewModel *listViewModel;
@property (nonatomic, assign) BOOL isFirstEnter;

@property (nonatomic, assign) BOOL hasKVOControllerNonRetaining;

@end

@implementation CAKAlbumListViewController

@synthesize vcDelegate, resourceType;
@synthesize tabIdentifier, enableBottomViewShow, enableSelectedAssetsViewShow;

- (instancetype)initWithResourceType:(AWEGetResourceType)resourceType;
{
    self = [super init];
    if (self) {
        self.resourceType = resourceType;
        self.isFirstEnter = YES;
    }
    
    return self;
}

- (void)dealloc
{
    if (self.hasKVOControllerNonRetaining) {
        [self.KVOControllerNonRetaining unobserve:self.viewModel];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if ([self.vcDelegate respondsToSelector:@selector(albumListVCDidLoad:)]) {
        [self.vcDelegate albumListVCDidLoad:self];
    }

    self.view.backgroundColor = CAKResourceColor(ACCUIColorConstBGContainer);
    
    self.aspectRatio = self.viewModel.listViewConfig.aspectRatio;
    self.collectionView.showsVerticalScrollIndicator = NO;

    [self.view addSubview:self.collectionView];
    ACCMasMaker(self.collectionView, {
        make.edges.equalTo(self.view);
    });

    [self bindViewModel];
}

- (void)bindViewModel
{
    @weakify(self);
    RACSignal *rac_viewDidLayout = [[self rac_signalForSelector:@selector(viewDidLayoutSubviews)] take:1];
    [[[self.viewModel.albumDataModel.resultSourceAssetsSubject deliverOnMainThread] combineLatestWith:rac_viewDidLayout] subscribeNext:^(RACTuple * _Nullable x) {
        CAKAssetsSourceChangedPack result = x.first;
        CAKAlbumAssetDataModel *model = result.first;
        NSNumber *needResetTable = result.second;
        @strongify(self);
        if (model && model.resourceType == self.resourceType) {
            [self reloadDataAndScrollToBottom:needResetTable.boolValue withCompltion:^{
                @strongify(self);
                [self.loadingView dismissWithAnimated:YES];
            }];
            self.blankContentView.hidden = model.numberOfObject > 0;
        }
    }];
    
    if (!self.hasCheckedAndReload) {
        self.hasCheckedAndReload = YES;
        [self checkAuthorizationAndReloadWithScrollToBottom:self.viewModel.listViewConfig.scrollToBottom];
    }

    [self.KVOController observe:self.viewModel.albumDataModel keyPath:@"photoSelectAssetsModels" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        BOOL needUpdate = ![self isCurrentViewControllerVisible];
        needUpdate = needUpdate || (self.resourceType == AWEGetResourceTypeImage && self.resourceType != self.viewModel.currentResourceType);
        if (needUpdate) {
            [self adapterReloadDataInMainThread];
        }
    }];

    [self.KVOController observe:self.viewModel.albumDataModel keyPath:@"videoSelectAssetsModels" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        BOOL needUpdate = ![self isCurrentViewControllerVisible];
        needUpdate = needUpdate || (self.resourceType == AWEGetResourceTypeVideo && self.resourceType != self.viewModel.currentResourceType);
        if (needUpdate) {
            [self adapterReloadDataInMainThread];
        }
    }];

    [self.KVOController observe:self.viewModel.albumDataModel keyPath:@"mixedSelectAssetsModels" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        BOOL needUpdate = ![self isCurrentViewControllerVisible];
        needUpdate = needUpdate || (self.resourceType == AWEGetResourceTypeImageAndVideo && self.resourceType != self.viewModel.currentResourceType);
        if (needUpdate) {
            [self adapterReloadDataInMainThread];
        }
    }];
    if ([CAKPhotoManager isiOS14PhotoNotDetermined] && self.viewModel.listViewConfig.enableiOS14AlbumAuthorizationGuide) {
        self.hasKVOControllerNonRetaining = YES;
        [self.KVOControllerNonRetaining observe:self.viewModel keyPath:@"hasRequestAuthorizationForAccessLevel" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
            @strongify(self);
            BOOL hasRequestPhotoLibraryAuthorization = [change acc_boolValueForKey:NSKeyValueChangeNewKey];
            [self p_handleSelectedPhotoLibraryAuthorization:hasRequestPhotoLibraryAuthorization];
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self.vcDelegate respondsToSelector:@selector(albumListVCWillAppear:)]) {
        [self.vcDelegate albumListVCWillAppear:self];
    }
    
    if (!self.hasCheckedAndReload) {
        self.hasCheckedAndReload = YES;
        [self checkAuthorizationAndReloadWithScrollToBottom:self.viewModel.listViewConfig.scrollToBottom];
    } else {
        for (CAKAlbumAssetListCell *item in self.collectionView.visibleCells) {
            [item updateSelectStatus];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if ([self.vcDelegate respondsToSelector:@selector(albumListVCWillDisappear:)]) {
        [self.vcDelegate albumListVCWillDisappear:self];
    }
}

- (UICollectionViewCell *)transitionCollectionCellForItemOffset:(NSInteger)itemOffset
{
    NSIndexPath *indexPath = [self.viewModel indexPathForOffset:itemOffset resourceType:self.resourceType];

    if ([[self.collectionView indexPathsForVisibleItems] indexOfObject:indexPath] == NSNotFound && [self isValidIndexPath:indexPath]) {
        [self.collectionView scrollToItemAtIndexPath:indexPath
                                    atScrollPosition:UICollectionViewScrollPositionTop
                                            animated:NO];
        [self reloadVisibleCell];
    }
    
    if ([self isValidIndexPath:indexPath]) {
        return [self.collectionView cellForItemAtIndexPath:indexPath];
    } else {
        return nil;
    }
}

- (void)reloadVisibleCell
{
    [self.viewModel updateSelectedAssetsNumber];
    [self p_reloadVisibleCellExcept:nil];
}

- (void)reloadData
{
    [self.collectionView reloadData];
}

- (void)updateAssetsMultiSelectMode
{
    //切换单多选模式 刷新必要UI，无须reload整个页面
    for (CAKAlbumAssetListCell *item in self.collectionView.visibleCells) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:item];
        CAKAlbumSectionModel *sectionModel = [self sectionModelForIndex:indexPath.section];
        CAKAlbumAssetModel *asset = [self assetModelForIndex:indexPath.item sectionModel:sectionModel];
        [self.viewModel updateAssetModel:asset];
        [item updateAssetsMultiSelectMode:[self p_needShowRightTopIcon] withAsset:asset greyMode:[self needDisplayGreyModeCellWithAsset:asset]];
        //增加greymode
        //同步无障碍UI
        if ([item respondsToSelector:@selector(updateSelectPhotoViewAccessibilityLabel)]) {
            [item updateSelectPhotoViewAccessibilityLabel];
        }
    }
}

- (void)p_updateMultiSelectModeListView
{
    //多选下选择/取消选择素材 刷新必要的UI，无须reload整个页面
    for (CAKAlbumAssetListCell *item in self.collectionView.visibleCells) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:item];
        CAKAlbumSectionModel *sectionModel = [self sectionModelForIndex:indexPath.section];
        CAKAlbumAssetModel *asset = [self assetModelForIndex:indexPath.item sectionModel:sectionModel];
        [self.viewModel updateAssetModel:asset];
        [item updateGreyMode:[self needDisplayGreyModeCellWithAsset:asset] withNum:asset.selectedNum];
        [item updateNumberLabel:asset.selectedNum];//取消一个选择的时候 每个素材的标记数会改变
        //同步无障碍UI
        if ([item respondsToSelector:@selector(updateSelectPhotoViewAccessibilityLabel)]) {
            [item updateSelectPhotoViewAccessibilityLabel];
        }
    }
}

- (BOOL)needDisplayGreyModeCellWithAsset:(CAKAlbumAssetModel *)asset
{
    //用cell的asset判断 选择此cell是否超出限制
    BOOL exceedMaxDuration = [self.viewModel isExceededMaxSelectableDuration:asset.phAsset.duration];
    BOOL reachTotalLimit = self.viewModel.listViewConfig.selectionLimitType == CAKAlbumSelectionLimitTypeTotal && self.viewModel.hasSelectedMaxCount;
    BOOL reachSeparateLimit = NO;
    if (asset.mediaType == CAKAlbumAssetModelMediaTypeVideo) {
        reachSeparateLimit = self.viewModel.listViewConfig.selectionLimitType == CAKAlbumSelectionLimitTypeSeparate &&  self.viewModel.hasVideoSelectedMaxCount;
    }
    if (asset.mediaType == CAKAlbumAssetModelMediaTypePhoto) {
        reachSeparateLimit = self.viewModel.listViewConfig.selectionLimitType == CAKAlbumSelectionLimitTypeSeparate && self.viewModel.hasPhotoSelectedMaxCount;
    }
    BOOL greyMode = (reachTotalLimit || reachSeparateLimit) || exceedMaxDuration;
    return greyMode;
}

#pragma mark - Check Authorization

- (void)checkAuthorizationAndReloadWithScrollToBottom:(BOOL)scrollToBottom
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
#ifdef __IPHONE_14_0 //xcode12
    if (@available(iOS 14.0, *)) {
        status = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
    }
#endif
    
    switch (status) {
        case PHAuthorizationStatusAuthorized: {
            [self p_fetchPhotoData:YES];
        }
            break;
        case PHAuthorizationStatusNotDetermined: {
#ifdef __IPHONE_14_0 //xcode12
            if (@available(iOS 14.0, *)) {
                if (!self.viewModel.listViewConfig.enableiOS14AlbumAuthorizationGuide) {
                    [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite handler:^(PHAuthorizationStatus status) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            switch (status) {
                                case PHAuthorizationStatusLimited:
                                case PHAuthorizationStatusAuthorized: {
                                    [self p_fetchPhotoData];
                                    break;
                                }
                                case PHAuthorizationStatusNotDetermined:
                                case PHAuthorizationStatusRestricted:
                                case PHAuthorizationStatusDenied: {
                                    [self updateBlankViewWithPermission:NO];
                                    break;
                                }
                                default:
                                    break;
                            }
                        });
                    }];
                }
            } else {
                [self p_requestAuthorizationLessTheniOS14];
            }
#else //xcode11
            [self p_requestAuthorizationLessTheniOS14];
#endif
        }
            break;
        case PHAuthorizationStatusRestricted: {
            [self updateBlankViewWithPermission:NO];
        }
            break;
        case PHAuthorizationStatusDenied: {
            [self updateBlankViewWithPermission:NO];
        }
            break;
        default:
        {
#ifdef __IPHONE_14_0 //xcode12
            if (@available(iOS 14.0, *)) {
                if (status == PHAuthorizationStatusLimited) {
                    [self p_fetchPhotoData];
                }
            }
#endif
        }
            break;
    }
}

//ios14-
- (void)p_requestAuthorizationLessTheniOS14
{
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (status) {
                case PHAuthorizationStatusAuthorized: {
                    [self p_fetchPhotoData];
                    break;
                }
                case PHAuthorizationStatusNotDetermined:
                case PHAuthorizationStatusRestricted:
                case PHAuthorizationStatusDenied: {
                    [self updateBlankViewWithPermission:NO];
                    break;
                }
                default:
                    break;
            }
        });
    }];
}
    
- (void)p_handleSelectedPhotoLibraryAuthorization:(BOOL)hasRequestPhotoLibraryAuthorization
{
    acc_dispatch_main_async_safe(^{
        if (hasRequestPhotoLibraryAuthorization) {
            [self p_fetchPhotoData];
        } else {
            [self updateBlankViewWithPermission:NO];
        }
    });
}

- (void)p_fetchPhotoData
{
    [self p_fetchPhotoData:NO];
}

- (void)p_fetchPhotoData:(BOOL)useCache
{
    if (self.loadingView) {
        [self.loadingView dismiss];
        self.loadingView = nil;
    }

    _blankContentView.hidden = YES;
    if ([CAKPhotoManager enableAlbumLoadOpt]) {
        self.loadingView = [CAKLoading() showLoadingOnView:self.view title:@"" animated:YES afterDelay:0.2];
    } else {
        self.loadingView = [CAKLoading() showLoadingOnView:self.view title:@"" animated:YES];
    }
    [self.viewModel reloadAssetsDataWithResourceType:self.resourceType useCache:useCache];
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

#pragma mark - Reload Data

- (void)adapterReloadDataInMainThread
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.collectionView reloadData];
    });
}

- (void)reloadDataAndScrollToBottom:(BOOL)scrollToBottom withCompltion:(void(^)(void))compltion
{
    BOOL shouldScrollToBottom = self.viewModel.listViewConfig.scrollToBottom;
    if (!self.isFirstEnter && !scrollToBottom) {
        shouldScrollToBottom = NO;
    }
    self.isFirstEnter = NO;
    self.collectionView.hidden = NO;
    [self.collectionView reloadData];
    [self.collectionView setNeedsLayout];
    [self.collectionView layoutIfNeeded];
    
    if(shouldScrollToBottom && [self sourceArr].count > 0) {
        NSInteger sectionIndex = [self sourceArr].count - 1;
        CAKAlbumSectionModel *sectionModel = [self sectionModelForIndex:sectionIndex];
        NSInteger itemIndex = [self countForSectionModel:sectionModel] - 1;
        if (itemIndex > 20) {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
        }
    }
    
    [self updateBlankViewWithPermission:YES];
    ACCBLOCK_INVOKE(compltion);
}

- (void)albumListScrollToAssetModel:(CAKAlbumAssetModel *)assetModel{
    self.viewModel.albumDataModel.targetIndexPath = nil;

    NSArray<NSIndexPath *> *visibleIndexPaths = [self.collectionView indexPathsForVisibleItems];

    [self.dataSource enumerateObjectsUsingBlock:^(CAKAlbumSectionModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.assetDataModel containsObject:assetModel]) {
            NSInteger idy = [obj.assetDataModel indexOfObject:assetModel];
            NSIndexPath *targetIndexPath = [NSIndexPath indexPathForRow:idy inSection:idx];
            self.viewModel.albumDataModel.targetIndexPath = targetIndexPath;
            //1. if this cell is not within visibleIndexPath, scroll it to center
            //2. if this cell in visibleIndexPath and partly exceed at top of current visible view,scroll it to top
            //3. if this cell in visibleIndexPath and partly exceed at bottom of current visible view,then scroll it to bottom
            if (![visibleIndexPaths containsObject:targetIndexPath]) {
                if (visibleIndexPaths.count > 0) {
                    [self.collectionView scrollToItemAtIndexPath:targetIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
                }
            } else {
                UICollectionViewCell * cell = [self.collectionView cellForItemAtIndexPath:targetIndexPath];
                if (cell){
                    CGRect rect = [self.collectionView convertRect:cell.frame toView:self.view];
                    if (rect.origin.y < 0) {
                        [self.collectionView scrollToItemAtIndexPath:targetIndexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
                    } else if (CGRectGetMaxY(rect) > self.collectionView.frame.size.height) {
                        [self.collectionView scrollToItemAtIndexPath:targetIndexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
                    }
                }

            }
            *stop = YES;
        }
    }];
}

#pragma mark - UICollectionViewDataSource

- (NSArray<CAKAlbumSectionModel *> *)sourceArr
{
    return [self.viewModel dataSourceWithResourceType:self.resourceType];
}

- (CAKAlbumSectionModel *)sectionModelForIndex:(NSUInteger)indexSection
{
    NSArray<CAKAlbumSectionModel *> *sourceArr = [self sourceArr];
    if (indexSection < sourceArr.count) {
        CAKAlbumSectionModel *sectionModel = sourceArr[indexSection];
        return sectionModel;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    NSArray<CAKAlbumSectionModel *> *sourceArr = [self sourceArr];
    return  sourceArr.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSArray<CAKAlbumSectionModel *> *sourceArr = [self sourceArr];
    if (section < sourceArr.count) {
        CAKAlbumSectionModel *sectionModel = sourceArr[section];
        return [self countForSectionModel:sectionModel];
    }
    return 0;
}

- (NSInteger)countForSectionModel:(CAKAlbumSectionModel *)sectionModel
{
    return [sectionModel.assetDataModel numberOfObject];
}
- (CAKAlbumAssetModel *)assetModelForIndex:(NSInteger)index sectionModel:(CAKAlbumSectionModel *)sectionModel
{
    return [sectionModel.assetDataModel objectIndex:index];
}

- (BOOL)isSelectedAsset:(CAKAlbumAssetModel *)asset
{
    for (CAKAlbumAssetModel *model in self.viewModel.listViewConfig.initialSelectedAssetModelArray) {
        if ([model isEqualToAssetModel:asset identity:NO]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)p_needShowRightTopIcon
{
    return self.tabConfig.enableMultiSelect;
}

- (BOOL)p_needShowGIFMark
{
    return self.tabConfig.enableGIFMarkShow;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CAKAlbumAssetListCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([CAKAlbumAssetListCell class]) forIndexPath:indexPath];
    cell.shouldAdjustThumbnailImageViewContentMode = self.viewModel.listViewConfig.enableHorizontalAssetBlackEdge;
    cell.assetsSelectedIconStyle = self.viewModel.listViewConfig.assetsSelectedIconStyle;
    cell.checkMaterialRepeatSelect = self.viewModel.listViewConfig.enableAssetsRepeatedSelect;
    @weakify(self);
    cell.didSelectedAssetBlock = ^(CAKAlbumAssetListCell *selectedCell, BOOL isSelected) {
        @strongify(self);
        [self p_didSelectedAssetWithCell:selectedCell isSelected:isSelected];
        [self p_scrollSelectAssetViewToNext];
    };
    cell.assetsSelectedIconStyle = self.viewModel.listViewConfig.assetsSelectedIconStyle;
    CAKAlbumSectionModel *sectionModel = [self sectionModelForIndex:indexPath.section];
    if (indexPath.item < [self countForSectionModel:sectionModel]) {
        CAKAlbumAssetModel *asset = [self assetModelForIndex:indexPath.item sectionModel:sectionModel];
        if (self.resourceType == AWEGetResourceTypeImageAndVideo) {
            asset.allCellIndex = indexPath.item;
        } else {
            asset.categoriedCellIndex = indexPath.item;
        }
        BOOL greyMode = [self needDisplayGreyModeCellWithAsset:asset];

        BOOL isSelected = [self isSelectedAsset:asset];

        [cell configureCellWithAsset:asset greyMode:greyMode showRightTopIcon:[self p_needShowRightTopIcon] showGIFMark:[self p_needShowGIFMark] alreadySelect:isSelected];

        if ([cell respondsToSelector:@selector(configAccessibilityElements)]) {
            [cell configAccessibilityElements];
        }
        if (self.viewModel.listViewConfig.shouldShowCornerTagView == YES) {
            [cell updateLeftCornerTagText:self.viewModel.listViewConfig.cornerTagContext];
            if ([self.viewModel.listViewConfig.showCornerTagAssetLocalIdentifierSet containsObject:asset.phAsset.localIdentifier]) {
                [cell updateLeftCornerTagShow:YES];
            } else {
                [cell updateLeftCornerTagShow:NO];
            }
        }
        [cell enablefavoriteSymbolShow:self.viewModel.listViewConfig.enableDisplayFavoriteSymbol];
        if ([self.vcDelegate respondsToSelector:@selector(albumListVC:didConfigCellForAsset:)]) {
            [self.vcDelegate albumListVC:self didConfigCellForAsset:asset];
        }
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (![cell isKindOfClass:[CAKAlbumAssetListCell class]]) {
        return;
    }
    CAKAlbumAssetListCell *displayCell = (CAKAlbumAssetListCell *)cell;
    [self.viewModel updateAssetModel:displayCell.assetModel];
    [displayCell updateAssetsMultiSelectMode:[self p_needShowRightTopIcon] withAsset:displayCell.assetModel greyMode:[self needDisplayGreyModeCellWithAsset:displayCell.assetModel]];//cell reuse need refresh
    [displayCell updateSelectStatus];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CAKAlbumSectionModel *sectionModel = [self sectionModelForIndex:indexPath.section];
    if (indexPath.item < [self countForSectionModel:sectionModel]) {
        CAKAlbumAssetModel *assetModel = [self assetModelForIndex:indexPath.item sectionModel:sectionModel];
        if (self.resourceType == AWEGetResourceTypeImageAndVideo) {
            assetModel.allCellIndex = indexPath.item;
        } else {
            assetModel.categoriedCellIndex = indexPath.item;
        }
        [self p_didSelectedToPreview:assetModel coverImage:assetModel.coverImage fromBottomView:NO];
    }
}

#pragma mark - Select

- (void)didSelectedToPreview:(CAKAlbumAssetModel *)model coverImage:(UIImage *)coverImage fromBottomView:(BOOL)fromBottomView
{
    if (!coverImage) {
        coverImage = model.coverImage;
    }
    [self p_didSelectedToPreview:model coverImage:coverImage fromBottomView:fromBottomView];
}

- (void)p_didSelectedToPreview:(CAKAlbumAssetModel *)model coverImage:(UIImage *)coverImage fromBottomView:(BOOL)fromBottomView
{
    if ([self.viewModel previewAndMultiSelectTypeWithListViewController:self] == CAKAlbumPreviewAndMultiSelectTypeEnableMultiSelectDisablePreview) {
        return;
    }

    //not preview
    if ([self.viewModel previewAndMultiSelectTypeWithListViewController:self] == CAKAlbumPreviewAndMultiSelectTypeBothDisabled && [self.vcDelegate respondsToSelector:@selector(albumListVC:didClickedCell:)]) {
        if ([self.vcDelegate respondsToSelector:@selector(albumListVC:shouldSelectAsset:)]) {
            if (![self.vcDelegate albumListVC:self shouldSelectAsset:model]) {
                return;
            }
        }
        [self.viewModel didSelectedAsset:model];
        [self.vcDelegate albumListVC:self didClickedCell:model];
        return;
    }
    
    //preview
    [self.vcDelegate albumListVC:self didClickedCell:model];
    
    self.previewFromBottom = fromBottomView;
    if (AWEGetResourceTypeImage == self.resourceType || CAKAlbumAssetModelMediaTypePhoto == model.mediaType) {
        [self p_didSelectedPhotoToPreview:model coverImage:coverImage fromBottomView:fromBottomView];
    }
    
    if (AWEGetResourceTypeVideo == self.resourceType || CAKAlbumAssetModelMediaTypeVideo == model.mediaType) {
        [self p_didSelectedVideoToPreview:model coverImage:coverImage fromBottomView:fromBottomView];
    }
}

- (void)p_didSelectedPhotoToPreview:(CAKAlbumAssetModel *)model coverImage:(UIImage *)coverImage fromBottomView:(BOOL)fromBottomView
{
    self.selectedCellIndex = self.resourceType == AWEGetResourceTypeImageAndVideo ? model.allCellIndex : model.categoriedCellIndex;
    CAKAlbumPreviewAndSelectController *preview = [[CAKAlbumPreviewAndSelectController alloc] initWithViewModel:self.viewModel anchorAssetModel:model fromBottomView:fromBottomView];
    @weakify(self);
    preview.willDismissBlock = ^(CAKAlbumAssetModel * _Nonnull currentModel) {
        @strongify(self);
        [self albumListScrollToAssetModel:currentModel];
        if ([self.vcDelegate respondsToSelector:@selector(albumListVCUpdateEmptyCellForSelectedAssetView:)]) {
            [self.vcDelegate albumListVCUpdateEmptyCellForSelectedAssetView:self];
        }
        if ([self.vcDelegate respondsToSelector:@selector(albumListVCEndPreview:)]) {
            [self.vcDelegate albumListVCEndPreview:self];
        }
    };
    preview.didClickedTopRightIcon = ^(CAKAlbumAssetModel * _Nonnull currentModel, BOOL isSelected) {
        @strongify(self);
        [self p_didSelectedAsset:currentModel isSelected:isSelected fromPreivew:YES];
        [currentModel fetchCoverImageIfNeededWithCompletion:nil];
        [self p_scrollSelectAssetViewToNext];
        [self reloadVisibleCell];
    };
    preview.modalPresentationStyle = UIModalPresentationCustom;
    preview.modalPresentationCapturesStatusBarAppearance = YES;
    preview.transitioningDelegate = self.transitionDelegate;
    preview.delegate = self;
    self.transitioningDelegate = self.transitionDelegate;
    [self presentViewController:preview animated:YES completion:nil];
}

- (void)p_didSelectedVideoToPreview:(CAKAlbumAssetModel *)model coverImage:(UIImage *)coverImage fromBottomView:(BOOL)fromBottomView
{
    self.selectedCellIndex = self.resourceType == AWEGetResourceTypeImageAndVideo ? model.allCellIndex : model.categoriedCellIndex;
    CAKAlbumPreviewAndSelectController *preview = [[CAKAlbumPreviewAndSelectController alloc] initWithViewModel:self.viewModel anchorAssetModel:model fromBottomView:fromBottomView];
    @weakify(self);
    preview.willDismissBlock = ^(CAKAlbumAssetModel * _Nonnull currentModel) {
        @strongify(self);
        [self albumListScrollToAssetModel:currentModel];
        if ([self.vcDelegate respondsToSelector:@selector(albumListVCUpdateEmptyCellForSelectedAssetView:)]) {
            [self.vcDelegate albumListVCUpdateEmptyCellForSelectedAssetView:self];
        }
        if ([self.vcDelegate respondsToSelector:@selector(albumListVCEndPreview:)]) {
            [self.vcDelegate albumListVCEndPreview:self];
        }
    };
    preview.didClickedTopRightIcon = ^(CAKAlbumAssetModel * _Nonnull currentModel, BOOL isSelected) {
        @strongify(self);
        [self p_didSelectedAsset:currentModel isSelected:isSelected fromPreivew:YES];
        [currentModel fetchCoverImageIfNeededWithCompletion:nil];
        [self p_scrollSelectAssetViewToNext];
        [self reloadVisibleCell];
    };
    preview.modalPresentationStyle = UIModalPresentationCustom;
    preview.modalPresentationCapturesStatusBarAppearance = YES;
    preview.transitioningDelegate = self.transitionDelegate;
    preview.delegate = self;
    self.transitioningDelegate = self.transitionDelegate;
    [self presentViewController:preview animated:YES completion:nil];
}

- (void)p_didSelectedAssetWithCell:(CAKAlbumAssetListCell *)cell isSelected:(BOOL)isSelected
{
    CAKAlbumAssetModel *model = cell.assetModel;
    
    if (![self p_didSelectedAsset:model isSelected:isSelected fromPreivew:NO]) {
        return;
    }
    
    [self p_updateMultiSelectModeListView];
    [cell doSelectedAnimation];
    if ([cell respondsToSelector:@selector(updateSelectPhotoViewAccessibilityLabel)]) {
        [cell updateSelectPhotoViewAccessibilityLabel];
    }
}

- (BOOL)p_didSelectedAsset:(CAKAlbumAssetModel *)model isSelected:(BOOL)isSelected fromPreivew:(BOOL)fromPreview
{
    if (isSelected) {
        // It was selected before clicking, and it will be unselected at this time
        [self.viewModel didUnselectedAsset:model];
        if ([self.vcDelegate respondsToSelector:@selector(albumListVC:didDeselectAsset:isFromPreview:)]) {
            [self.vcDelegate albumListVC:self didDeselectAsset:model isFromPreview:fromPreview];
        }
    } else {
        // It was unselected before clicking, and it will be selected at this time
        
        // Should Select the assetModel.
        if ([self.vcDelegate respondsToSelector:@selector(albumListVC:shouldSelectAsset:)]) {
            if (![self.vcDelegate albumListVC:self shouldSelectAsset:model]) {
                return NO;
            }
        }
        
        [self.viewModel didSelectedAsset:model];
        if ([self.vcDelegate respondsToSelector:@selector(albumListVC:didSelectedAsset:isFromPreview:)]) {
            [self.vcDelegate albumListVC:self didSelectedAsset:model isFromPreview:fromPreview];
        }
    }
    
    return YES;
}

- (void)p_reloadVisibleCellExcept:(CAKAlbumAssetListCell *)cell
{
    NSMutableArray *visibleIndexPaths = [[self.collectionView indexPathsForVisibleItems] mutableCopy];
    if (!cell) {
        [UIView performWithoutAnimation:^{
            [self.collectionView reloadItemsAtIndexPaths:visibleIndexPaths];
        }];
        return;
    }
    
    NSIndexPath *currentIndexPath = [self.collectionView indexPathForCell:cell];
    for (NSIndexPath *path in visibleIndexPaths) {
        if (path.row == currentIndexPath.row && path.section == currentIndexPath.section){
            [visibleIndexPaths removeObject:path];
            break;
        }
    }
    [UIView performWithoutAnimation:^{
        [self.collectionView reloadItemsAtIndexPaths:visibleIndexPaths];
    }];
}

- (void)p_scrollSelectAssetViewToNext
{
    if ([self.vcDelegate respondsToSelector:@selector(albumListVCScrollSelectAssetViewToNext:)]) {
        [self.vcDelegate albumListVCScrollSelectAssetViewToNext:self];
    }
}

#pragma mark - CAKAlbumListViewControllerProtocol

- (void)albumListShowTabDotIfNeed:(void (^)(BOOL showDot, UIColor *color))showDotBlock
{
    ACCBLOCK_INVOKE(showDotBlock, NO, [UIColor clearColor]);
}

- (BOOL)enableMultiSelect
{
    return self.tabConfig.enableMultiSelect;
}

- (void)setEnableMultiSelect:(BOOL)enableMultiSelect
{
    self.tabConfig.enableMultiSelect = enableMultiSelect;
}

- (void)scrollAssetToVisible:(CAKAlbumAssetModel *)assetModel
{
    [[self sourceArr] enumerateObjectsUsingBlock:^(CAKAlbumSectionModel *obj, NSUInteger section, BOOL *stop) {
        NSInteger index = [obj.assetDataModel indexOfObject:assetModel];
        if (index != NSNotFound) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:section];
            BOOL invalidIndexPath = indexPath.section == 0 && indexPath.item == 0;//Attempted to scroll the collection view to an out-of-bounds item (0) when there are only 0 items in section 0. will crash at iOS15
            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
            if (cell != nil) {
                // visible
                [self.collectionView scrollRectToVisible:cell.frame animated:YES];
            } else if (!invalidIndexPath){
                // not visible
                [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
            }
            *stop = YES;
        }
    }];
}

- (BOOL)isEmptyPhotoAlbum {
    return self.viewModel.albumDataModel.photoSourceAssetsDataModel.numberOfObject == 0;
}

- (BOOL)isEmptyVideoeAlbum {
    return self.viewModel.albumDataModel.videoSourceAssetsDataModel.numberOfObject == 0;
}

#pragma mark - CAKAlbumZoomTransitionOuterContextProvider

- (NSInteger)zoomTransitionItemOffset
{
    return self.selectedCellIndex;
}

- (UIView *_Nullable)zoomTransitionStartViewForOffset:(NSInteger)offset
{
    if (self.viewModel.currentSelectedIndex < 0 || self.viewModel.currentSelectedIndex >= self.viewModel.tabsInfo.count) {
        return nil;
    }
    
    if (self.previewFromBottom) {
        return nil;
    }

    UIViewController<CAKAlbumListViewControllerProtocol> *viewController = [self.viewModel.tabsInfo acc_objectAtIndex:self.viewModel.currentSelectedIndex];
    if ([viewController isKindOfClass:[CAKAlbumListViewController class]]) {
        UICollectionViewCell *cell = [((CAKAlbumListViewController *)viewController) transitionCollectionCellForItemOffset:offset];
        return cell;
    }
    
    return nil;
}

#pragma mark - Blank View

- (void)updateBlankViewWithPermission:(BOOL)permission
{
    if ([CAKPhotoManager authorizationStatus] == AWEAuthorizationStatusDenied && self.viewModel.listViewConfig.enableAlbumAuthorizationDenyAccessGuide) {
        if ([self.vcDelegate respondsToSelector:@selector(albumListVCNeedShowAuthoritionDenyView:)]) {
            [self.vcDelegate albumListVCNeedShowAuthoritionDenyView:self];
        }
        return;
    }
    self.blankContentView.frame = self.view.bounds;
    if (!permission) {
        self.blankContentView.type = CAKAlbumListBlankViewTypeNoPermissions;
        return;
    }
    self.blankContentView.type = [self.viewModel blankViewTypeWithResourceType:self.resourceType];
}

#pragma mark - Valid


#pragma mark - Utils

- (BOOL)isCurrentViewControllerVisible
{
    return (self.isViewLoaded && self.view.window);
}

- (BOOL)isValidIndexPath:(NSIndexPath *)index
{
    NSInteger sectionCount = [self.collectionView numberOfSections];
    if (index.section >= sectionCount) {
        return NO;
    }
    
    NSInteger rowCount = [self.collectionView numberOfItemsInSection:index.section];
    if (index.row >= rowCount) {
        return NO;
    }
    
    return YES;
}

#pragma mark - Getter

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        
        CGFloat contentWidth = ACC_SCREEN_WIDTH;
        contentWidth -= 2 * self.viewModel.listViewConfig.horizontalInset;
        
        NSInteger colCount = 4;
        if (self.viewModel.listViewConfig.columnNumber > 0) {
            colCount = self.viewModel.listViewConfig.columnNumber;
        }
        
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        CGFloat width = floor((contentWidth - (colCount - 1) * 1) / colCount);
        CGFloat height = width;
        if (!CGSizeEqualToSize(self.aspectRatio, CGSizeZero) && self.aspectRatio.width > 0.0 && self.aspectRatio.height > 0.0) {
            height = width * self.aspectRatio.height / self.aspectRatio.width;
        }
        CGSize itemSize = CGSizeMake(width, height);
        flowLayout.itemSize = itemSize;
        flowLayout.minimumInteritemSpacing = 1;
        flowLayout.minimumLineSpacing = (contentWidth - width * colCount) / (colCount - 1);

        CGRect collectionViewFrame = self.view.bounds;
        _collectionView = [[UICollectionView alloc] initWithFrame:collectionViewFrame collectionViewLayout:flowLayout];
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.alwaysBounceVertical = YES;
        _collectionView.showsVerticalScrollIndicator = NO;
        if (self.viewModel.listViewConfig.enableBlackStyle) {
            _collectionView.backgroundColor = [UIColor blackColor];
        } else {
            _collectionView.backgroundColor = [UIColor whiteColor];
        }

        [_collectionView registerClass:[CAKAlbumAssetListCell class] forCellWithReuseIdentifier:[CAKAlbumAssetListCell identifier]];
    }
    return _collectionView;
}

- (CAKAlbumListBlankView *)blankContentView
{
    if (!_blankContentView) {
        _blankContentView = [[CAKAlbumListBlankView alloc] initWithFrame:self.view.bounds];
        _blankContentView.backgroundColor = CAKResourceColor(ACCUIColorConstBGContainer);
        _blankContentView.hidden = YES;
        [self.view addSubview:_blankContentView];
    }
    return _blankContentView;
}

- (CAKAlbumZoomTransitionDelegate *)transitionDelegate
{
    if (!_transitionDelegate) {
        _transitionDelegate = [CAKAlbumZoomTransitionDelegate new];
    }
    return _transitionDelegate;
}

#pragma - mark CAKAlbumPreviewAndSelectControllerDelegate

- (void)previewController:(CAKAlbumPreviewAndSelectController *)previewController willBeginSetupPlayer:(AVPlayer *)player status:(NSInteger)status
{
    if ([self.vcDelegate respondsToSelector:@selector(albumListVC:previewControllerWillBeginSetupPlayer:status:)]) {
        [self.vcDelegate albumListVC:self previewControllerWillBeginSetupPlayer:player status:status];
    }
}

- (void)previewControllerDidLoad:(CAKAlbumPreviewAndSelectController *)previewController forAlbumAsset:(CAKAlbumAssetModel *)asset bottomView:(CAKAlbumPreviewPageBottomView *)bottomView
{
    if ([self.vcDelegate respondsToSelector:@selector(albumListVC:previewControllerDidLoadForAlbumAsset:bottomView:)]) {
        [self.vcDelegate albumListVC:self previewControllerDidLoadForAlbumAsset:asset bottomView:bottomView];

    }
}

- (void)previewController:(CAKAlbumPreviewAndSelectController *)previewController scrollViewDidEndDeceleratingWithAlbumAsset:(CAKAlbumAssetModel *)asset
{
    if ([self.vcDelegate respondsToSelector:@selector(albumListVC:previewControllerScrollViewDidEndDeceleratingWithAlbumAsset:)]) {
        [self.vcDelegate albumListVC:self previewControllerScrollViewDidEndDeceleratingWithAlbumAsset:asset];
    }
}

- (void)previewController:(CAKAlbumPreviewAndSelectController *)previewController didFinishFetchIcloudWithFetchDuration:(NSTimeInterval)duration size:(NSInteger)size
{
    if ([self.vcDelegate respondsToSelector:@selector(albumListVC:didFinishFetchIcloudWithFetchDuration:size:)]) {
        [self.vcDelegate albumListVC:self didFinishFetchIcloudWithFetchDuration:duration size:size];
    }
}

- (void)previewController:(CAKAlbumPreviewAndSelectController *)previewController didClickNextButton:(UIButton *)btn
{
    if ([self.vcDelegate respondsToSelector:@selector(albumListVC:previewControllerDidClickNextButton:)]) {
        [self.vcDelegate albumListVC:self previewControllerDidClickNextButton:btn];
    }
}

- (void)previewController:(CAKAlbumPreviewAndSelectController *)previewController updateNextButtonTitle:(UIButton *)btn
{
    if ([self.vcDelegate respondsToSelector:@selector(albumListVC:previewControllerUpdateNextButtonTitle:)]) {
        [self.vcDelegate albumListVC:self previewControllerUpdateNextButtonTitle:btn];
    }
}

- (void)previewController:(CAKAlbumPreviewAndSelectController *)previewController selectedAssetsViewDidChangeOrderWithDraggingAsset:(CAKAlbumAssetModel *)asset
{
    if ([self.vcDelegate respondsToSelector:@selector(albumListVC:previewControllerSelectedAssetsViewDidChangeOrderWithAsset:)]) {
        [self.vcDelegate albumListVC:self previewControllerSelectedAssetsViewDidChangeOrderWithAsset:asset];
    }
}

- (void)previewController:(CAKAlbumPreviewAndSelectController *)previewController selectedAssetsViewdidDeleteAsset:(CAKAlbumAssetModel *)deletedAsset
{
    [self reloadVisibleCell];
    if ([self.vcDelegate respondsToSelector:@selector(albumListVC:previewControllerSelectedAssetsViewDidDeleteAsset:)]) {
        [self.vcDelegate albumListVC:self previewControllerSelectedAssetsViewDidDeleteAsset:deletedAsset];
    }
}

- (void)previewController:(CAKAlbumPreviewAndSelectController *)previewController selectedAssetsViewDidClickAsset:(CAKAlbumAssetModel *)asset
{
    if ([self.vcDelegate respondsToSelector:@selector(albumListVC:previewControllerSelectedAssetsViewDidClickAsset:)]) {
        [self.vcDelegate albumListVC:self previewControllerSelectedAssetsViewDidClickAsset:asset];
    }
}

- (void)previewController:(CAKAlbumPreviewAndSelectController *)previewController viewDidEndZoomingWithZoomIn:(BOOL)isZoomIn asset:(CAKAlbumAssetModel *)asset
{
    if ([self.vcDelegate respondsToSelector:@selector(albumListVC:previewControllerDidEndZoomingWithIsZoomIn:asset:)]) {
        [self.vcDelegate albumListVC:self previewControllerDidEndZoomingWithIsZoomIn:isZoomIn asset:asset];
    }
}


@end

