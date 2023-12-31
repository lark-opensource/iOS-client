//
//  AWEVideoEditStickerCollectionViewController.m
//  AWEStudio
//
//  Created by guochenxiang on 2018/9/19.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEVideoEditStickerCollectionViewController.h"
#import "AWEVideoEditStickerBottomBarViewController.h"
#import <ByteDanceKit/BTDNetworkUtilities.h>
#import "AWEVideoEditStickerHeaderView.h"
#import "AWEVideoEditStickerCollectionviewFlowLayout.h"

#import <EffectPlatformSDK/EffectPlatform.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>
#import "AWESingleStickerDownloader.h"
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>

@interface AWEVideoEditStickerCollectionViewController () <UICollectionViewDelegate, UICollectionViewDataSource, AWEVideoEditStickerBottomBarViewControllerDelegate>

@property (nonatomic, strong) UIView *errorView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong, readwrite) AWEVideoEditStickerBottomBarViewController *bottomBarViewController;
@property (nonatomic, strong) AWEVideoEditStickerHeaderView *headerView;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@property (nonatomic, assign) BOOL hasPreloadedStickers;
@property (nonatomic, strong) NSIndexPath *currentSectionIndexPath;
@property (nonatomic, assign) CGFloat lastContentOffset;

@property (nonatomic, strong) AWESingleStickerDownloader *stickerDownloader;
@property (nonatomic, copy) NSString *currentTabID;

@end

@implementation AWEVideoEditStickerCollectionViewController

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

- (instancetype)init
{
    if (self = [super init]) {
        _hasPreloadedStickers = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self p_setupBottomBar];
    [self p_setupHeaderView];
    
    self.containerView = [[UIView alloc] init];
    [self.view addSubview:self.containerView];
    
    [self.containerView addSubview:self.collectionView];
    ACCMasMaker(self.containerView, {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.headerView.mas_bottom);
        make.bottom.equalTo(self.bottomBarViewController.view.mas_top);
    });
    
    ACCMasMaker(self.collectionView, {
        make.edges.equalTo(self.containerView);
    });
    
    [self.view bringSubviewToFront:self.headerView];
    
    [self.view addSubview:self.errorView];
    ACCMasMaker(self.errorView, {
        make.edges.equalTo(self.view);
    });
    
    [self p_fetchData];
    
    [self configureCollectionView];
}

- (void)p_setupBottomBar
{
    self.bottomBarViewController = [[AWEVideoEditStickerBottomBarViewController alloc] init];
    self.bottomBarViewController.delegate = self;
    self.bottomBarViewController.uiConfig = self.uiConfig;
    [self addChildViewController:self.bottomBarViewController];
    [self.view addSubview:self.bottomBarViewController.view];
    [self.bottomBarViewController didMoveToParentViewController:self];
    self.bottomBarViewController.showText = [self shouldShowTextOnBottomBar];
    ACCMasMaker(self.bottomBarViewController.view, {
        make.left.right.bottom.equalTo(self.view);
        make.height.equalTo(@0);
    });
    [self configureBottomBar];
}

- (void)p_setupHeaderView
{
    self.headerView = [[AWEVideoEditStickerHeaderView alloc] init];
    [self.view addSubview:self.headerView];
    
    ACCMasMaker(self.headerView, {
        make.left.right.top.equalTo(self.view);
        make.height.equalTo(@0);
    });
}


#pragma mark - fetch data

- (void)p_fetchData
{
    self.errorView.hidden = YES;
    
    @weakify(self)
    [self fetchDataWithCompletion:^(BOOL success){
        @strongify(self)
        if (success) {
            acc_dispatch_main_async_safe(^{
                [self.collectionView reloadData];
                [self.collectionView layoutIfNeeded];
                if (self.style == AWEVideoEditStickerCollectionViewStyleCategorizedWithHeader) {
                    [self p_updateHeaderFrame];
                    self.collectionView.contentInset = UIEdgeInsetsMake( -[AWEVideoEditStickerHeaderView headerHeight], self.horizontalInset, 0, self.horizontalInset);
                    self.lastContentOffset = [AWEVideoEditStickerHeaderView headerHeight];
                }
            });
            [self preloadFistPageSticker];
        } else {
            acc_dispatch_main_async_safe(^{
                self.errorView.hidden = NO;
                [ACCToast() show:ACCLocalizedCurrentString(@"com_mig_there_was_a_problem_with_the_internet_connection_try_again_later_yq455g")];
            });
        }
    }];
}



- (void)preloadFistPageSticker
{
    if (!self.hasPreloadedStickers) {
        [self preloadingInfoStickersWithWifi]; // collectionView 加载完成
        self.hasPreloadedStickers = YES;
    }
}

- (void)preloadingInfoStickersWithWifi
{
    // wifi 情况下下载第一屏贴纸
    if (BTDNetworkWifiConnected()) {
        NSArray *effects = [self.effects copy];//用于遍历防止 crash
        for (NSUInteger index = 0; index < effects.count && index < self.collectionView.visibleCells.count; index ++) {
            IESEffectModel *effect = [self.effects acc_objectAtIndex:index] ?:[effects acc_objectAtIndex:index];//优先用self.effects，用于cell点击下载判断
            if (effect && !effect.downloaded) {
                @weakify(self);
                void(^compeletion)(AWESingleStickerDownloadInfo * _Nonnull downloadInfo) = ^(AWESingleStickerDownloadInfo * _Nonnull downloadInfo) {
                    @strongify(self);
                    [self.logger logStickerDownloadFinished:downloadInfo];
                };
                AWESingleStickerDownloadParameter *download = [AWESingleStickerDownloadParameter new];
                download.sticker = effect;
                download.downloadProgressBlock = nil;
                download.compeletion = compeletion;
                [self.stickerDownloader downloadSticker:download];
            }
        }
    }
}

- (AWESingleStickerDownloader *)stickerDownloader {
    if (!_stickerDownloader) {
        _stickerDownloader = [AWESingleStickerDownloader new];
    }
    return _stickerDownloader;
}
#pragma mark - setter 随拍过滤投票贴纸

- (void)setCategories:(NSArray<IESCategoryModel *> *)categories
{
    _categories = categories;
    [self updateCurrentStyle];
    self.currentTabID = [categories firstObject].categoryIdentifier;

    acc_dispatch_main_async_safe(^{
        [self p_updateUIByStyle];
    });
}

- (void)p_updateUIByStyle
{
    if (self.style == AWEVideoEditStickerCollectionViewStyleCategorizedWithHeader) {
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
            for (IESCategoryModel *category in self.categories) {
                [titles addObject:(category.categoryName ? : @"")];
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

#pragma mark - getter

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[AWEVideoEditStickerCollectionviewFlowLayout alloc] init];
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.contentInset = UIEdgeInsetsMake(0, self.horizontalInset, 0, self.horizontalInset);
        [_collectionView registerClass:[AWEVideoEditStickerCollectionViewHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[AWEVideoEditStickerCollectionViewHeaderView identifier]];
        [_collectionView registerClass:[AWEInformationStickerCollectionViewFooter class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[AWEInformationStickerCollectionViewFooter identifier]];
        if ([_collectionView respondsToSelector:@selector(contentInsetAdjustmentBehavior)]) {
            if (@available(iOS 11.0, *)) {
                _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            }
        }
        if (@available(iOS 10.0, *)) {
            _collectionView.prefetchingEnabled = NO;
        }
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
    }
    return _collectionView;
}

- (UIView *)errorView
{
    if (!_errorView) {
        _errorView = [[UIView alloc] init];
        _errorView.backgroundColor = [UIColor clearColor];

        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.text = ACCLocalizedCurrentString(@"error_retry");
        titleLabel.font = [ACCFont() systemFontOfSize:15];
        titleLabel.textColor = ACCResourceColor(ACCUIColorConstIconInverse3);
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.numberOfLines = 0;
        [_errorView addSubview:titleLabel];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wimplicit-retain-self"
        ACCMasMaker(titleLabel, {
            make.center.equalTo(_errorView);
            make.left.equalTo(@32);
            make.right.equalTo(@-32);
        });
#pragma clang diagnostic pop
        _errorView.hidden = YES;
        UITapGestureRecognizer *ges = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_fetchData)];
        [_errorView addGestureRecognizer:ges];
    }
    return _errorView;
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
    if (self.style == AWEVideoEditStickerCollectionViewStyleNone) {
        return 1;
    }
    return self.categories.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.style == AWEVideoEditStickerCollectionViewStyleNone) {
        return self.effects.count;
    }
    IESCategoryModel *category = [self.categories acc_objectAtIndex:section];
    return category.effects.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    IESEffectModel *model = nil;
    if (self.style == AWEVideoEditStickerCollectionViewStyleNone) {
        model = [self.effects acc_objectAtIndex:indexPath.row];
    } else {
        IESCategoryModel *category = [self.categories acc_objectAtIndex:indexPath.section];
        model = [category.effects acc_objectAtIndex:indexPath.row];
    }
    AWEBaseStickerCollectionViewCell *cell = [self cellAtIndexPath:indexPath];
    [cell configCellWithImage:model.iconDownloadURLs];
    // 增加emoji表情的贴纸名字
    cell.stickerName = [[model.effectName stringByReplacingOccurrencesOfString:@"-" withString:@""] stringByReplacingOccurrencesOfString:@"emoji" withString:@"表情"];
    return cell;
}

#pragma mark - UICollectionVIewDelegate

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (self.style == AWEVideoEditStickerCollectionViewStyleCategorizedWithHeader) {
        AWEVideoEditStickerCollectionViewHeaderView *headerView = (AWEVideoEditStickerCollectionViewHeaderView *)[collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:[AWEVideoEditStickerCollectionViewHeaderView identifier] forIndexPath:indexPath];
        headerView.uiConfig = self.uiConfig;
        if (indexPath.section >= [self.categories count]) {
            return headerView;
        }
        IESCategoryModel *category = self.categories[indexPath.section];
        [headerView updateWithTitle:category.categoryName];
        return headerView;
    } else {
        return [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[AWEInformationStickerCollectionViewFooter identifier] forIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    IESEffectModel *model = nil;
    NSString *tabID = nil;
    if (self.style != AWEVideoEditStickerCollectionViewStyleNone) {
        IESCategoryModel *category = [self.categories acc_objectAtIndex:indexPath.section];
        model = [category.effects acc_objectAtIndex:indexPath.row];
        tabID = category.categoryIdentifier;
    } else {
        model = [self.effects acc_objectAtIndex:indexPath.row];
    }
    [self.logger logStickerWillDisplay:model.effectIdentifier categoryId:tabID categoryName:[self stickerType]];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (self.style == AWEVideoEditStickerCollectionViewStyleCategorizedWithHeader) {
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
    if (self.style != AWEVideoEditStickerCollectionViewStyleCategorizedWithFooter) {
        return CGSizeZero;
    }
    if ([self numberOfSectionsInCollectionView:collectionView]-1 == section) {
        return CGSizeZero;
    }
    return CGSizeMake(ACC_SCREEN_WIDTH, 40.0f);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.itemSize;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    IESEffectModel *model = nil;
    NSString *tabID = nil;
    if (self.style != AWEVideoEditStickerCollectionViewStyleNone) {
        IESCategoryModel *category = [self.categories acc_objectAtIndex:indexPath.section];
        model = [category.effects acc_objectAtIndex:indexPath.row];
        tabID = category.categoryIdentifier;
    } else {
        model = [self.effects acc_objectAtIndex:indexPath.row];
    }
    
    [self.logger logStickerPannelDidSelectSticker:model.effectIdentifier index:indexPath.row tab:self.currentTabID categoryName:[self stickerType] extra:nil];
    AWEBaseStickerCollectionViewCell *cell = (AWEBaseStickerCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerCollectionViewController:didSelectSticker:atIndex:categoryName:tabName:downloadProgressBlock:downloadedBlock:)]) {
        // 贴纸/表情所在位置索引，先统计前面的所有 section 的总和，再加上该贴纸的位置
        NSInteger stickerIndex = 0;
        if (self.style != AWEVideoEditStickerCollectionViewStyleNone) {
            for (NSInteger sectionIndex = 0; sectionIndex < indexPath.section-1; sectionIndex++) {
                stickerIndex += [(IESCategoryModel *)([self.categories acc_objectAtIndex:sectionIndex]) effects].count;
            }
            stickerIndex += indexPath.row + 1;
        } else {
            stickerIndex += indexPath.row + 1;
        }
        
        @weakify(cell);
        [self.delegate stickerCollectionViewController:self didSelectSticker:model atIndex:stickerIndex categoryName:[self stickerType] tabName:tabID  downloadProgressBlock:^(CGFloat progress){
            @strongify(cell);
            ACCLog(@"sticker download progress is %.2f",progress);
            [cell updateDownloadProgress:progress];
        } downloadedBlock:^{
            @strongify(cell);
            cell.downloadStatus = AWEInfoStickerDownloadStatusDownloaded;
        }];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.style == AWEVideoEditStickerCollectionViewStyleCategorizedWithHeader) {
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
        IESCategoryModel *category = self.categories[section];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[category.effects count] - 1 inSection:section];
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
    IESCategoryModel *category = nil;
    if (targetIndex >= 0 && targetIndex < [self.categories count]) {
        category = self.categories[targetIndex];
    }
    self.currentTabID = category.categoryIdentifier;
    ACCLog(@"===Selection: %@", @(targetIndex));
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
            [headerAttributes addObject:attributes];
        }
    }
    [self.headerView updateWithAttributes:headerAttributes yOffset:self.collectionView.contentOffset.y - [AWEVideoEditStickerHeaderView headerHeight]];
}

#pragma mark - AWEVideoEditStickerBottomBarViewControllerDelegate

- (void)bottomBarViewControllerDidSelectCategory:(IESCategoryModel *)category shouldTrack:(BOOL)shouldTrack
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

#pragma mark - For Subclassing

- (BOOL)shouldShowTextOnBottomBar
{
    return NO;
}

- (void)configureCollectionView
{
    
}

- (AWEBaseStickerCollectionViewCell *)cellAtIndexPath:(NSIndexPath *)indexPath
{
    NSAssert(NO, @"Use concrete subclass instead of this class");
    return nil;
}

- (void)fetchDataWithCompletion:(void (^)(BOOL))completion
{
    
}

- (void)updateCurrentStyle
{
    
}

- (NSString *)stickerType
{
    return @"";
}

- (void)configureBottomBar
{
    
}

- (NSDictionary *)logPB
{
    return @{};
}

@end
