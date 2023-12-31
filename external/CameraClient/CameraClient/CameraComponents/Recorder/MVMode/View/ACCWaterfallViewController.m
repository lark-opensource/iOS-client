//
//  ACCWaterfallViewController.m
//  CameraClient
//
//  Created by long.chen on 2020/3/1.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCWaterfallViewController.h"
#import "ACCWaterfallCollectionViewLayout.h"
#import "UIViewController+ACCUIKitEmptyPage.h"
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import "ACCRefreshHeader.h"
#import <CreationKitInfra/ACCLoadMoreFooter.h>
#import "UIScrollView+ACCInfiniteScrolling.h"

#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@interface ACCWaterfallViewController () <UICollectionViewDataSource, UICollectionViewDelegate, ACCNewCollectionDelegateWaterfallLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, assign) BOOL isFetchingData;

// track filter flag
@property (nonatomic, assign) BOOL firstLoadFlag;
@property (nonatomic, strong) NSMutableArray<NSIndexPath *> *displayFilterIndexPaths;

@end

@implementation ACCWaterfallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = ACCResourceColor(ACCColorBGCreation);
    
    [self p_addCollectionView];
    
    [self p_fetchContentData:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.contentProvider handleOnViewDidAppear];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    if ([self.contentProvider respondsToSelector:@selector(didReceiveMemoryWarning)]) {
        [self.contentProvider didReceiveMemoryWarning];
    }
}

- (void)p_addCollectionView
{
    [self.view addSubview:self.collectionView];
    ACCMasMaker(self.collectionView, {
        make.edges.equalTo(self.view);
    });
    
    [self.contentProvider registerCellForcollectionView:self.collectionView];
    
    @weakify(self);
    ACCRefreshHeader *header = [ACCRefreshHeader headerWithRefreshingBlock:^{
        @strongify(self);
        self.isFetchingData = YES;
        self.collectionView.mj_footer.hidden = YES;
        [self.collectionView.mj_footer resetNoMoreData];
        @weakify(self);
        [self.contentProvider refreshContentDataIsRetry:NO completion:^(NSError * _Nonnull error, NSArray *contents, BOOL hasMore) {
            @strongify(self);
            self.isFetchingData = NO;
            [self.collectionView.mj_header endRefreshing];
            [self p_updateEmpteStateWithError:error andContentCount:contents.count];
            [self.collectionView reloadData];
            if (!hasMore) {
                [self.collectionView.mj_footer endRefreshingWithNoMoreData];
            } else {
                [self.collectionView.mj_footer endRefreshing];
            }
            [self.collectionView.acc_infiniteScrollingView stopAnimating];
            self.collectionView.mj_footer.hidden = NO;
        }];
    }];
    [header setLoadingViewBackgroundColor:UIColor.clearColor];
    self.collectionView.mj_header = header;
    
    ACCLoadMoreFooter *footer = [ACCLoadMoreFooter footerWithRefreshingBlock:^{
        @strongify(self);
        [self p_loadMoreContent];
    }];
    [footer setLoadingViewBackgroundColor:UIColor.clearColor];
    self.collectionView.mj_footer = footer;
    [self.collectionView acc_addInfiniteScrollingWithActionHandler:^{
        @strongify(self);
        [self p_loadMoreContent];
    }];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    ACCBLOCK_INVOKE(self.updateContentOffsetBlock, self.collectionView);
}

- (void)p_fetchContentData:(BOOL)isRetry
{
    self.isFetchingData = YES;
    UIView<ACCLoadingViewProtocol> *loadingView = [ACCLoading() showLoadingOnView:self.view];
    @weakify(self);
    [self.contentProvider refreshContentDataIsRetry:isRetry completion:^(NSError * _Nonnull error, NSArray *contents, BOOL hasMore) {
        @strongify(self);
        self.isFetchingData = NO;
        [loadingView dismiss];
        [self p_updateEmpteStateWithError:error andContentCount:contents.count];
        [self p_trackFilterReload];
        if (!hasMore) {
            [self.collectionView.mj_footer endRefreshingWithNoMoreData];
        }
        [self.collectionView.acc_infiniteScrollingView stopAnimating];
    }];
}

- (void)p_loadMoreContent
{
    if (!self.contentProvider.hasMore || self.isFetchingData) {
        return;
    }
    @weakify(self);
    [self.contentProvider loadMoreContentDataWithCompletion:^(NSError * _Nonnull error, NSArray *contents, BOOL hasMore) {
        @strongify(self);
        [self p_trackFilterReload];
        if (!hasMore) {
            [self.collectionView.mj_footer endRefreshingWithNoMoreData];
        } else {
            [self.collectionView.mj_footer endRefreshing];
        }
        [self.collectionView.acc_infiniteScrollingView stopAnimating];
    }];
}

- (void)p_updateEmpteStateWithError:(NSError *)error andContentCount:(NSUInteger)contentCount
{
    if (error) {
        self.accui_viewControllerState = ACCUIKitViewControllerStateError;
    } else if (contentCount == 0) {
        self.accui_viewControllerState = ACCUIKitViewControllerStateEmpty;
    } else {
        self.accui_viewControllerState = ACCUIKitViewControllerStateNormal;
    }
}

- (void)p_trackFilterReload
{
    [self.displayFilterIndexPaths removeAllObjects];
    [self.displayFilterIndexPaths addObjectsFromArray:[self.collectionView indexPathsForVisibleItems]];
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [self.contentProvider numberOfSectionsInCollectionView:collectionView];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.contentProvider collectionView:collectionView numberOfItemsInSection:section];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.contentProvider collectionView:collectionView cellForItemAtIndexPath:indexPath];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.contentProvider collectionView:collectionView didSelectItemAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.transitionCoordinator) {
        return;
    }
    if ([self.displayFilterIndexPaths containsObject:indexPath]) {
        [self.displayFilterIndexPaths removeObject:indexPath];
        return;
    }
    if ([self.contentProvider respondsToSelector:@selector(collectionView:willDisplayCell:forItemAtIndexPath:)]) {
        [self.contentProvider collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
    }
}

#pragma mark - ACCNewCollectionDelegateWaterfallLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.contentProvider collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
}

#pragma mark - ACCUIKitEmptyPage

- (ACCUIKitViewControllerEmptyPageConfig *)accui_emptyPageConfigForState:(ACCUIKitViewControllerState)state
{
    return [self.contentProvider accui_emptyPageConfigForState:state];
}

- (void)accui_emptyPagePrimaryButtonTapped:(UIButton *)sender
{
    [self p_fetchContentData:YES];
}

# pragma mark - ACCWaterfallContentScrollDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(waterfallScrollViewDidScroll:viewController:)]) {
        [self.delegate waterfallScrollViewDidScroll:scrollView viewController:self];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(waterfallScrollViewDidEndDragging:willDecelerate:viewController:)]) {
        [self.delegate waterfallScrollViewDidEndDragging:scrollView willDecelerate:decelerate viewController:self];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(waterfallScrollViewDidEndDecelerating:viewController:)]) {
        [self.delegate waterfallScrollViewDidEndDecelerating:scrollView viewController:self];
    }
}

#pragma mark - ACCWaterfallViewControllerProtocol

- (void)refreshContent
{
    if (!self.isFetchingData) {
        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            [self.collectionView.mj_header beginRefreshing];
            [self.collectionView.acc_infiniteScrollingView resetOriginalContentSize]; 
        }];
        [self.collectionView setContentOffset:CGPointMake(0, 0)];
        [CATransaction commit]; 
    }
}

- (void)reloadContent
{
    if (!self.isFetchingData && self.accui_viewControllerState != ACCUIKitViewControllerStateError) {
        if (!self.firstLoadFlag) {
            self.firstLoadFlag = YES;
            [self p_trackFilterReload];
        } else {
            [self.collectionView reloadData];
        }
        [self p_updateEmpteStateWithError:nil andContentCount:[self.contentProvider collectionView:self.collectionView numberOfItemsInSection:0]];
    }
}

- (void)diffReloadContent
{
    NSInteger oldCount = [self.collectionView numberOfItemsInSection:0];
    NSInteger newCount = [self.contentProvider collectionView:self.collectionView numberOfItemsInSection:0];
    if (newCount > oldCount) {
        NSMutableArray *indexPaths = [NSMutableArray array];
        for (NSInteger i = oldCount; i < newCount; i++) {
            [indexPaths addObject:[NSIndexPath indexPathForItem:i inSection:0]];
        }
        [self.collectionView insertItemsAtIndexPaths:indexPaths];
    } else if (newCount < oldCount) {
        [self p_trackFilterReload];
    }
    [self p_updateEmpteStateWithError:nil andContentCount:[self.contentProvider collectionView:self.collectionView numberOfItemsInSection:0]];
}

- (UICollectionViewCell *)transitionCollectionCellForItemOffset:(NSInteger)itemOffset
{
    NSIndexPath *indexPath = self.collectionView.indexPathsForSelectedItems.firstObject;
    if (!indexPath) {
        return nil;
    }
    indexPath = [NSIndexPath indexPathForItem:indexPath.item + itemOffset inSection:indexPath.section];
    if (indexPath.item >= [self.collectionView numberOfItemsInSection:indexPath.section]
        || indexPath.item < 0) {
        return nil;
    };
    UIViewController *toViewController = [self.transitionCoordinator viewControllerForKey:UITransitionContextToViewControllerKey];
    BOOL isBack = NO;
    UIViewController *targetController = self;
    while (targetController) {
        if (toViewController == targetController) {
            isBack = YES;
            break;
        }
        targetController = targetController.parentViewController;
    }
    if (isBack) {
        [self.collectionView scrollToItemAtIndexPath:indexPath
                                    atScrollPosition:UICollectionViewScrollPositionTop
                                            animated:NO];
        ACCBLOCK_INVOKE(self.updateContentOffsetBlock, self.collectionView);
    }
    [self.collectionView layoutIfNeeded];
    return [self.collectionView cellForItemAtIndexPath:indexPath];
}

#pragma mark - Getters

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        ACCWaterfallCollectionViewLayout *waterfallLayout = [[ACCWaterfallCollectionViewLayout alloc] init];
        waterfallLayout.columnCount = self.contentProvider.columnCount;
        waterfallLayout.minimumColumnSpacing = self.contentProvider.minimumColumnSpacing;
        waterfallLayout.minimumInteritemSpacing = self.contentProvider.minimumInteritemSpacing;
        waterfallLayout.sectionInset = self.contentProvider.sectionInset;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:waterfallLayout];
        _collectionView.backgroundColor = ACCResourceColor(ACCColorBGCreation);
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _collectionView;
}

- (NSMutableArray<NSIndexPath *> *)displayFilterIndexPaths
{
    if (!_displayFilterIndexPaths) {
        _displayFilterIndexPaths = [NSMutableArray array];
    }
    return _displayFilterIndexPaths;
}

@end
