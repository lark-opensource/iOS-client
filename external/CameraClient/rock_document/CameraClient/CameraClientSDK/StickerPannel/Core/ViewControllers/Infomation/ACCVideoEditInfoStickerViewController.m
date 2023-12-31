//
//  ACCVideoEditInfoStickerViewController.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/2/4.
//

#import "ACCVideoEditInfoStickerViewController.h"
#import "ACCStickerPannelUIConfig.h"
#import "ACCStickerPannelDataConfig.h"
#import "AWEVideoEditStickerHeaderView.h"
#import "AWEInformationStickerCollectionViewCell.h"
#import "AWEVideoEditStickerCollectionviewFlowLayout.h"
#import "AWEVideoEditStickerBottomBarViewController.h"
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCStickerPannelFilter.h"
#import <CreationKitInfra/ACCLoadMoreFooter.h>
#import "ACCStickerPannelDataHelper.h"
#import "IESInfoStickerModel+ACCExtention.h"
#import <CreationKitInfra/ACCLoadingViewProtocol.h>

#import <EffectPlatformSDK/EffectPlatform+InfoSticker.h>
#import <EffectPlatformSDK/IESInfoStickerCategoryModel.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@interface ACCVideoEditInfoStickerViewController () <UICollectionViewDelegate, UICollectionViewDataSource, ACCVideoEditInfoStickerBottomBarVCDelegate>

@property (nonatomic, strong) UIView *errorView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong, readwrite) ACCVideoEditInfoStickerBottomBarViewController *bottomBarViewController;
@property (nonatomic, strong) AWEVideoEditStickerHeaderView *headerView;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@property (nonatomic, copy) NSArray<IESInfoStickerCategoryModel *> *categories; // 有分类
@property (nonatomic, copy) NSArray<IESInfoStickerModel *> *effects; // 没有分类

// Status Helper
@property (nonatomic, copy) NSString *currentTabID;
@property (nonatomic, assign) CGFloat lastContentOffset;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, strong) ACCStickerPannelDataConfig *dataConfig;

@end

@implementation ACCVideoEditInfoStickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.horizontalInset = 1.5f;
    CGFloat width = (ACC_SCREEN_WIDTH - self.horizontalInset * 2) / 4;
    self.itemSize = CGSizeMake(width, width);

    ACCVideoEditInfoStickerBottomBarViewController *bottomBarViewController = [[ACCVideoEditInfoStickerBottomBarViewController alloc] init];
    bottomBarViewController.delegate = self;
    bottomBarViewController.uiConfig = self.uiConfig;
    [self addChildViewController:bottomBarViewController];
    [self.view addSubview:bottomBarViewController.view];
    [bottomBarViewController didMoveToParentViewController:self];
    bottomBarViewController.showText = NO;
    ACCMasMaker(bottomBarViewController.view, {
        make.left.right.bottom.equalTo(self.view);
        make.height.equalTo(@0);
    });
    bottomBarViewController.disableLeftScrollOutOfBounds = NO;
    bottomBarViewController.disableRightScrollOutOfBounds = YES;
    self.bottomBarViewController = bottomBarViewController;
    
    AWEVideoEditStickerHeaderView *headerView = [[AWEVideoEditStickerHeaderView alloc] init];
    [self.view addSubview:headerView];
    ACCMasMaker(headerView, {
        make.left.right.top.equalTo(self.view);
        make.height.equalTo(@0);
    });
    self.headerView = headerView;
    
    UIView *containerView = [[UIView alloc] init];
    [self.view addSubview:containerView];
    ACCMasMaker(containerView, {
        make.left.right.equalTo(self.view);
        make.top.equalTo(headerView.mas_bottom);
        make.bottom.equalTo(bottomBarViewController.view.mas_top);
    });
    self.containerView = containerView;

    UICollectionViewFlowLayout *layout = [[AWEVideoEditStickerCollectionviewFlowLayout alloc] init];
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.contentInset = UIEdgeInsetsMake(0, self.horizontalInset, 0, self.horizontalInset);
    [collectionView registerClass:[AWEVideoEditStickerCollectionViewHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[AWEVideoEditStickerCollectionViewHeaderView identifier]];
    [collectionView registerClass:[AWEInformationStickerCollectionViewFooter class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[AWEInformationStickerCollectionViewFooter identifier]];
    [collectionView registerClass:[AWEInformationStickerCollectionViewCell class] forCellWithReuseIdentifier:[AWEInformationStickerCollectionViewCell identifier]];
    if ([collectionView respondsToSelector:@selector(contentInsetAdjustmentBehavior)]) {
        if (@available(iOS 11.0, *)) {
            collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    if (@available(iOS 10.0, *)) {
        collectionView.prefetchingEnabled = NO;
    }
    collectionView.delegate = self;
    collectionView.dataSource = self;
    collectionView.mj_footer = [ACCLoadMoreFooter footerWithRefreshingBlock:nil];
    [containerView addSubview:collectionView];
    ACCMasMaker(collectionView, {
        make.edges.equalTo(containerView);
    });
    self.collectionView = collectionView;
    [self.view bringSubviewToFront:headerView];

    UIView *errorView = [[UIView alloc] init];
    errorView.backgroundColor = [UIColor clearColor];
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"网络不给力，请点击重试";
    titleLabel.font = [ACCFont() systemFontOfSize:15];
    titleLabel.textColor = ACCResourceColor(ACCUIColorConstIconInverse3);
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.numberOfLines = 0;
    [errorView addSubview:titleLabel];
    ACCMasMaker(titleLabel, {
        make.center.equalTo(_errorView);
        make.left.equalTo(@32);
        make.right.equalTo(@-32);
    });
    
    UITapGestureRecognizer *ges = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_fetchData)];
    [errorView addGestureRecognizer:ges];
    [self.view addSubview:errorView];
    ACCMasMaker(errorView, {
        make.edges.equalTo(self.view);
    });
    errorView.hidden = YES;
    self.errorView = errorView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // 每次进入该页面，都需要重新检查一下，因为抽帧包上传比较慢，初次打开面板可能还没上传好
    [self p_fetchData];
}

#pragma mark - fetch data
- (void)p_fetchData
{
    ACCStickerPannelDataConfig *currentConfig = self.delegate.dataConfig;
    if (self.isLoading || ([self.dataConfig.zipURI isEqualToString:currentConfig.zipURI] && self.errorView.hidden)) {
        return;
    }
    
    self.isLoading = YES;
    self.dataConfig = [currentConfig copy];
    self.errorView.hidden = YES;
    UIView<ACCLoadingViewProtocol> *loadingView = self.categories.count > 0 ? nil : [ACCLoading() showLoadingOnView:self.view];

    @weakify(self)
    ACCStickerPannelDataRequest *params = [[ACCStickerPannelDataRequest alloc] init];
    params.uploadURI = self.dataConfig.zipURI;
    params.creationId = self.dataConfig.creationId;
    params.filterTags = self.pannelFilter.filterTags;
    if (self.pannelFilter.isAlbumImage || self.pannelFilter.isIMPhoto) {
        params.customPanelName = @"propsforpic";
    } else if (self.pannelFilter.isCommerce) {
        params.customPanelName = @"infostickerecommerce";
        params.uploadURI = @"";
    }
    
    [ACCStickerPannelDataHelper fetchInfoStickerPannelData:params completion:^(BOOL success, ACCStickerPannelDataResponse *response) {
        @strongify(self)
        // Helper内保证了在主线程回调
        if (success && response) {
            self.effects = response.effects;
            self.categories = response.categories;
            self.currentTabID = [self.categories firstObject].categoryID;
            [self.collectionView reloadData];
            [self.collectionView layoutIfNeeded];
            if (self.style == ACCVideoEditInfoStickerCollectionStyleWithHeader) {
                [self p_updateHeaderFrame];
                self.collectionView.contentInset = UIEdgeInsetsMake(-[AWEVideoEditStickerHeaderView headerHeight], self.horizontalInset, 0, self.horizontalInset);
                [self.collectionView setContentOffset:CGPointMake(-self.horizontalInset, [AWEVideoEditStickerHeaderView headerHeight]) animated:YES];
                self.lastContentOffset = [AWEVideoEditStickerHeaderView headerHeight];
            }
            
            [self.collectionView.mj_footer endRefreshingWithNoMoreData];
        } else if (!self.effects && !self.categories) {
            self.errorView.hidden = NO;
            [ACCToast() show:@"网络不给力，请稍后重试"];
        }
        [loadingView removeFromSuperview];
        self.isLoading = NO;
    }];
}

- (void)setCategories:(NSArray<IESInfoStickerCategoryModel *> *)categories
{
    _categories = categories;
    [self p_updateStyleByData];
    [self p_updateUIByStyle];
}

#pragma mark - StyleControl
- (void)p_updateStyleByData
{
    if (ACC_isEmptyArray(self.categories)) {
        self.style = ACCVideoEditInfoStickerCollectionStyleNone;
    } else {
        self.style = ACCVideoEditInfoStickerCollectionStyleWithHeader;
    }
}

- (void)p_updateUIByStyle
{
    if (self.style == ACCVideoEditInfoStickerCollectionStyleWithHeader) {
        CGFloat bottomBarHeight = ACC_isEmptyArray(self.categories) ? 0.f : [AWEVideoEditStickerBottomBarViewController bottomBarHeight];
        CGFloat headerHeight = ACC_isEmptyArray(self.categories) ? 0.f : [AWEVideoEditStickerHeaderView headerHeight];
        ACCMasUpdate(self.bottomBarViewController.view, {
            make.height.equalTo(@(bottomBarHeight));
        });
        ACCMasUpdate(self.headerView, {
            make.height.equalTo(@(headerHeight));
        });
        self.bottomBarViewController.categories = self.categories;
        if (!ACC_isEmptyArray(self.categories)) {
            [self.bottomBarViewController selectCategory:[self.categories firstObject]];
            NSMutableArray *titles = [NSMutableArray array];
            for (IESInfoStickerCategoryModel *category in self.categories) {
                [titles acc_addObject:(category.categoryName ? : @"")];
            }
            [self.headerView updateWithTitles:titles];
        }
        CGFloat containerHeight = self.view.bounds.size.height - headerHeight - bottomBarHeight;
        self.gradientLayer.frame = CGRectMake(0, 0, ACC_SCREEN_WIDTH, containerHeight);
        self.gradientLayer.locations = @[@0, @(8.f / self.view.bounds.size.height), @(1.f - 8.f / self.view.bounds.size.height), @1];
        self.gradientLayer.colors = @[(__bridge id)[[UIColor blackColor] colorWithAlphaComponent:0.0f].CGColor,
                                      (__bridge id)[[UIColor blackColor] colorWithAlphaComponent:1.0f].CGColor,
                                      (__bridge id)[[UIColor blackColor] colorWithAlphaComponent:1.0f].CGColor,
                                      (__bridge id)[[UIColor blackColor] colorWithAlphaComponent:0.0f].CGColor];
        self.containerView.layer.mask = self.gradientLayer;
        self.view.layer.mask = nil;
    } else {
        self.gradientLayer.frame = self.view.bounds;
        self.gradientLayer.locations = @[@0, @(50.f / self.view.bounds.size.height), @1];
        self.gradientLayer.colors = @[(__bridge id)[[UIColor blackColor] colorWithAlphaComponent:0.4f].CGColor,
                                      (__bridge id)[[UIColor blackColor] colorWithAlphaComponent:1.0f].CGColor,
                                      (__bridge id)[[UIColor blackColor] colorWithAlphaComponent:1.0f].CGColor];
        self.view.layer.mask = self.gradientLayer;
        self.containerView.layer.mask = nil;
    }
}

- (CAGradientLayer *)gradientLayer
{
    if (!_gradientLayer) {
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        const CGFloat slidingViewHeight = self.view.bounds.size.height - 104.f;
        if (slidingViewHeight > 0) {
            gradientLayer.startPoint = CGPointMake(0.5f, 0.0f);
            gradientLayer.endPoint = CGPointMake(0.5f, 1.0f);
            gradientLayer.frame = CGRectMake(0, 0, self.view.bounds.size.width, slidingViewHeight);
            gradientLayer.colors = @[(__bridge id)[[UIColor blackColor] colorWithAlphaComponent:0.0f].CGColor,
                                     (__bridge id)[[UIColor blackColor] colorWithAlphaComponent:1.0f].CGColor,
                                     (__bridge id)[[UIColor blackColor] colorWithAlphaComponent:1.0f].CGColor];
            gradientLayer.locations = @[@(0), @(30.0f/slidingViewHeight), @(1)];
        }

        _gradientLayer = gradientLayer;
    }
    return _gradientLayer;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    if (self.style == ACCVideoEditInfoStickerCollectionStyleNone) {
        return 1;
    }
    return self.categories.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.style == ACCVideoEditInfoStickerCollectionStyleNone) {
        return self.effects.count;
    }
    IESInfoStickerCategoryModel *category = [self.categories acc_objectAtIndex:section];
    return category.infoStickerList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    IESInfoStickerModel *model = nil;
    if (self.style == ACCVideoEditInfoStickerCollectionStyleNone) {
        model = [self.effects acc_objectAtIndex:indexPath.row];
    } else {
         IESInfoStickerCategoryModel *category = [self.categories acc_objectAtIndex:indexPath.section];
         model = [category.infoStickerList acc_objectAtIndex:indexPath.row];
    }
    AWEBaseStickerCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:[AWEInformationStickerCollectionViewCell identifier] forIndexPath:indexPath];
    cell.uiConfig = self.uiConfig;
    cell.stickerId = model.stickerIdentifier;
    cell.stickerName = model.effectName;
    
    [cell configCellWithImage:model.previewImgUrls];
    if (model.stickerIdentifier) {
        cell.downloadStatus = model.stickerDownloading ? AWEInfoStickerDownloadStatusDownloading : AWEInfoStickerDownloadStatusUndownloaded;
    }
    return cell;
}

#pragma mark - UICollectionVIewDelegate

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (self.style == ACCVideoEditInfoStickerCollectionStyleWithHeader) {
        AWEVideoEditStickerCollectionViewHeaderView *headerView = (AWEVideoEditStickerCollectionViewHeaderView *)[collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:[AWEVideoEditStickerCollectionViewHeaderView identifier] forIndexPath:indexPath];
        headerView.uiConfig = self.uiConfig;
        if (indexPath.section >= [self.categories count]) {
            return headerView;
        }
        IESInfoStickerCategoryModel *category = self.categories[indexPath.section];
        [headerView updateWithTitle:category.categoryName];
        return headerView;
    } else {
        return [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[AWEInformationStickerCollectionViewFooter identifier] forIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    IESInfoStickerModel *model = nil;
    NSString *tabID = nil;
    if (self.style != ACCVideoEditInfoStickerCollectionStyleNone) {
        IESInfoStickerCategoryModel *category = [self.categories acc_objectAtIndex:indexPath.section];
        model = [category.infoStickerList acc_objectAtIndex:indexPath.row];
        tabID = category.categoryID;
    } else {
        model = [self.effects acc_objectAtIndex:indexPath.row];
    }
    [self.logger logStickerWillDisplay:model.effectIdentifier categoryId:tabID categoryName:[self stickerType]];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (self.style == ACCVideoEditInfoStickerCollectionStyleWithHeader) {
        if (section >= [self.categories count]) {
            return CGSizeZero;
        }
        return CGSizeMake(ACC_SCREEN_WIDTH, 40.0f);
    } else {
        return CGSizeZero;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    if (self.style != ACCVideoEditInfoStickerCollectionStyleWithFooter) {
        return CGSizeZero;
    }
    if ([self numberOfSectionsInCollectionView:collectionView]-1 == section) {
        return CGSizeZero;
    }
    return CGSizeMake(ACC_SCREEN_WIDTH, 40.f);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.itemSize;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    IESInfoStickerModel *model = nil;
    NSString *tabID = nil;
    if (self.style != ACCVideoEditInfoStickerCollectionStyleNone) {
        IESInfoStickerCategoryModel *category = [self.categories acc_objectAtIndex:indexPath.section];
        model = [category.infoStickerList acc_objectAtIndex:indexPath.row];
        tabID = category.categoryID;
    } else {
        model = [self.effects acc_objectAtIndex:indexPath.row];
    }

    [self.logger logStickerPannelDidSelectSticker:model.effectIdentifier index:indexPath.row tab:self.currentTabID categoryName:[self stickerType] extra:@{
        @"image_uri" : self.videoUploadURI ? : @""
    }];
    AWEBaseStickerCollectionViewCell *cell = (AWEBaseStickerCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(modernStickerCollectionVC:didSelectSticker:atIndex:categoryName:tabName:downloadProgressBlock:downloadedBlock:)]) {
        NSInteger stickerIndex = 0;
        if (self.style != ACCVideoEditInfoStickerCollectionStyleNone) {
            for (NSInteger sectionIndex = 0; sectionIndex < indexPath.section-1; sectionIndex++) {
                stickerIndex += [self.categories acc_objectAtIndex:sectionIndex].infoStickerList.count;
            }
            stickerIndex += indexPath.row + 1;
        } else {
            stickerIndex += indexPath.row + 1;
        }

        @weakify(cell);
        [self.delegate modernStickerCollectionVC:self didSelectSticker:model atIndex:stickerIndex categoryName:[self stickerType] tabName:tabID  downloadProgressBlock:^(CGFloat progress){
            @strongify(cell);
            if ([model.stickerIdentifier isEqualToString:cell.stickerId]) {
                [cell updateDownloadProgress:progress];
                model.stickerDownloading = YES;
            }
        } downloadedBlock:^{
            @strongify(cell);
            if ([model.stickerIdentifier isEqualToString:cell.stickerId]) {
                cell.downloadStatus = AWEInfoStickerDownloadStatusDownloaded;
            }
            if (model.stickerIdentifier) {
                model.stickerDownloading = NO;
            }
        }];
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.style == ACCVideoEditInfoStickerCollectionStyleWithHeader) {
        BOOL scrollUp = (scrollView.contentOffset.y > self.lastContentOffset);
        self.lastContentOffset = scrollView.contentOffset.y;
        [self p_updateHeaderFrame];
        if(scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating) {
            [self p_updateSelectedCategoryOnBottomBarWithScrollUp:scrollUp];
        }
        BOOL needMask = YES;
        CGPoint contentOffset = self.collectionView.contentOffset;
        UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
        for (NSInteger section = 0; section < [self.categories count]; section++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
            CGRect frame = [layout layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath].frame;
            if ((frame.origin.y - contentOffset.y > -2 * [AWEVideoEditStickerHeaderView headerHeight] && frame.origin.y - contentOffset.y < -[AWEVideoEditStickerHeaderView headerHeight]) || contentOffset.y <= [AWEVideoEditStickerHeaderView headerHeight]) {
                needMask = NO;
                break;
            } else if (frame.origin.y - contentOffset.y > [AWEVideoEditStickerHeaderView headerHeight]) {
                break;
            }
        }
        if (!needMask) {
            self.containerView.layer.mask = nil;
        } else if (!self.containerView.layer.mask) {
            self.containerView.layer.mask = self.gradientLayer;
        }
    }
}

- (void)p_updateSelectedCategoryOnBottomBarWithScrollUp:(BOOL)scrollUp
{
    if (ACC_isEmptyArray(self.categories)) {
        return ;
    }
    CGPoint contentOffset = self.collectionView.contentOffset;
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    NSInteger targetIndex = -1;
    for (NSInteger section = 0; section < [self.categories count]; section++) {
        IESInfoStickerCategoryModel *category = self.categories[section];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:category.infoStickerList.count - 1 inSection:section];
        CGRect frame = [layout layoutAttributesForItemAtIndexPath:indexPath].frame;
        if (scrollUp) {
            if (CGRectGetMaxY(frame) - contentOffset.y >= -[AWEVideoEditStickerHeaderView headerHeight]) {
                targetIndex = section;
                break;
            }
        } else {
            if (CGRectGetMinY(frame) - contentOffset.y >= -2 * [AWEVideoEditStickerHeaderView headerHeight]) {
                targetIndex = section;
                break;
            }
        }
    }
    IESInfoStickerCategoryModel *category = nil;
    if (targetIndex >= 0 && targetIndex < [self.categories count]) {
        category = self.categories[targetIndex];
    }
    self.currentTabID = category.categoryID;
    [self.bottomBarViewController selectCategory:category];
}

- (void)p_updateHeaderFrame
{
    if (ACC_isEmptyArray(self.categories)) {
        return ;
    }
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    NSMutableArray *headerAttributes = [NSMutableArray array];
    for (NSInteger section = 0; section < [self.categories count]; section++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
        UICollectionViewLayoutAttributes *attributes = [layout layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];
        if (attributes) {
            [headerAttributes acc_addObject:attributes];
        }
    }
    [self.headerView updateWithAttributes:headerAttributes yOffset:self.collectionView.contentOffset.y - [AWEVideoEditStickerHeaderView headerHeight]];
}

#pragma mark - ACCVideoEditInfoStickerBottomBarVCDelegate

- (void)bottomBarViewControllerDidSelectCategory:(IESInfoStickerCategoryModel *)category shouldTrack:(BOOL)shouldTrack
{
    NSInteger index = [self.categories indexOfObject:category];
    if (index == NSNotFound) {
        return ;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:index];
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    CGRect frame = [layout layoutAttributesForItemAtIndexPath:indexPath].frame;
    CGFloat yOffset = frame.origin.y;
    if (CGRectGetMinY(frame) + self.collectionView.bounds.size.height >= self.collectionView.contentSize.height) {
        yOffset = self.collectionView.contentSize.height - self.collectionView.bounds.size.height;
    }
    [self.collectionView setContentOffset:CGPointMake(self.collectionView.contentOffset.x, yOffset) animated:NO];
    if (shouldTrack) {
        [self.logger logBottomBarDidSelectCategory:category.categoryName pannelTab:[self stickerType]];
    }
}

- (NSString *)stickerType
{
    return @"sticker";
}

- (NSDictionary *)logPB
{
    return @{};
}

@end
