//
//  ACCDuetTemplateSlidingViewController.m
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/10/18.
//

#import <CreativeKit/ACCColorNameDefines.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CameraClient/ACCRefreshHeader.h>
#import <CameraClient/UIScrollView+ACCInfiniteScrolling.h>
#import <CreationKitInfra/ACCLoadMoreFooter.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CameraClient/UIViewController+ACCUIKitEmptyPage.h>
#import <CameraClient/ACCDuetTemplateSlidingViewController.h>
#import <CreativeKit/ACCMacros.h>

@interface ACCDuetTemplateSlidingViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, assign) BOOL isFetchingData;

@property (nonatomic, assign) BOOL firstLoadFlag;
@property (nonatomic, strong) NSMutableArray<NSIndexPath *> *displayFilterIndexPaths;
@end

@implementation ACCDuetTemplateSlidingViewController

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
#pragma mark - Private Methods

- (void)p_addCollectionView
{
    [self.view addSubview:self.collectionView];
    ACCMasMaker(self.collectionView, {
        make.edges.equalTo(self.view);
    });
    
    [self.contentProvider registerCellForCollectionView:self.collectionView];
    @weakify(self);
    self.collectionView.mj_header.userInteractionEnabled = NO;
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

- (void)p_fetchContentData:(BOOL)isRetry
{
    self.isFetchingData = YES;
    UIView<ACCLoadingViewProtocol> *loadingView = [ACCLoading() showLoadingOnView:self.view];
    @weakify(self);
    [self.contentProvider refreshContentDataIsRetry:isRetry completion:^(NSError * _Nonnull error, NSArray *contents, BOOL hasMore) {
        @strongify(self);
        if (error) {
            ACCLog(@"duetTemplateVC %p refreshContentError", self.class);
        }
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
    [self.contentProvider loadMoreContentDataWithCompletion:^(NSError * _Nonnull error, NSArray *contents,
                                                              BOOL hasMore) {
        @strongify(self);
        if (error) {
            ACCLog(@"duetTemplateVC %p error: %@", self.class, error);
        }
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
        ACCLog(@"duetTemplateVC %p error: %@", self.class, error);
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
    [self.displayFilterIndexPaths acc_addObjectsFromArray:[self.collectionView indexPathsForVisibleItems]];
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

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

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.contentProvider respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]) {
        return [self.contentProvider collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
    } else {
        return CGSizeMake(0, 0);
    }
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

#pragma mark - ACCDuetTemplateSlidingViewControllerProtocol

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
            [indexPaths acc_addObject:[NSIndexPath indexPathForItem:i inSection:0]];
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
    }
    [self.collectionView layoutIfNeeded];
    return [self.collectionView cellForItemAtIndexPath:indexPath];
}

#pragma mark - Getters

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
        collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        collectionViewLayout.minimumInteritemSpacing = self.contentProvider.minimumInteritemSpacing;
        collectionViewLayout.minimumLineSpacing = self.contentProvider.minimumColumnSpacing;
        collectionViewLayout.sectionInset = self.contentProvider.sectionInset;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
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
