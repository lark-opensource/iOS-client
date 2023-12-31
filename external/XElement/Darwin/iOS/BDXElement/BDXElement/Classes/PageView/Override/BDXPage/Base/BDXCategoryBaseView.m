//
//  BDXCategoryBaseView.m

//
//  Created by jiaxin on 2018/3/15.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import "BDXCategoryBaseView.h"
#import "BDXCategoryFactory.h"
#import "BDXCategoryViewAnimator.h"
#import "BDXRTLManager.h"

struct DelegateFlags {
    unsigned int didSelectedItemAtIndexFlag : 1;
    unsigned int didClickSelectedItemAtIndexFlag : 1;
    unsigned int didScrollSelectedItemAtIndexFlag : 1;
    unsigned int canClickItemAtIndexFlag : 1;
    unsigned int scrollingFromLeftIndexToRightIndexFlag : 1;
};

@interface BDXCategoryBaseView () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate>

@property (nonatomic, strong) BDXCategoryCollectionView *collectionView;
@property (nonatomic, assign) struct DelegateFlags delegateFlags;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, assign) CGFloat innerCellSpacing;
@property (nonatomic, assign) CGPoint lastContentViewContentOffset;
@property (nonatomic, strong) BDXCategoryViewAnimator *animator;

@property (nonatomic, assign) NSInteger scrollingTargetIndex;
@property (nonatomic, assign, getter=isNeedReloadByBecomeActive) BOOL needReloadByBecomeActive;
@property (nonatomic, assign, getter=isFirstLayoutSubviews) BOOL firstLayoutSubviews;
@property (nonatomic, assign, getter=isNeedConfigAutomaticallyAdjustsScrollViewInsets) BOOL needConfigAutomaticallyAdjustsScrollViewInsets;

@end

@implementation BDXCategoryBaseView

- (void)dealloc {
    if (self.contentScrollView) {
        [self.contentScrollView removeObserver:self forKeyPath:@"contentOffset"];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [self.animator stop];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initializeData];
        [self initializeViews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self initializeData];
        [self initializeViews];
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];

    [self configAutomaticallyAdjustsScrollViewInsets:newSuperview];
}

- (void)reloadData {
    [self reloadDataWithoutListContainer];
    [self.listContainer reloadData];
}

- (void)reloadDataWithoutListContainer {
    [self refreshDataSource];
    [self refreshState];
    [self.collectionView.collectionViewLayout invalidateLayout];
    [self.collectionView reloadData];
}

- (void)reloadCellAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.dataSource.count) {
        return;
    }
    BDXCategoryBaseCellModel *cellModel = self.dataSource[index];
    cellModel.selectedType = BDXCategoryCellSelectedTypeUnknown;
    [self refreshCellModel:cellModel index:index];
    BDXCategoryBaseCell *cell = (BDXCategoryBaseCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    [cell reloadData:cellModel];
}

- (void)selectItemAtIndex:(NSInteger)index {
    [self selectCellAtIndex:index selectedType:BDXCategoryCellSelectedTypeCode];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect targetFrame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    if (self.isFirstLayoutSubviews) {
        if (self.bounds.size.width == 0 || self.bounds.size.height == 0) {
            return;
        }
        if (self.isNeedConfigAutomaticallyAdjustsScrollViewInsets) {
            [self configAutomaticallyAdjustsScrollViewInsets:self.superview];
        }
        self.firstLayoutSubviews = NO;
        self.collectionView.frame = targetFrame;
        [self reloadDataWithoutListContainer];
    }else {
        if (!CGRectEqualToRect(self.collectionView.frame, targetFrame)) {
            self.collectionView.frame = targetFrame;
            [self.collectionView.collectionViewLayout invalidateLayout];
            [self.collectionView reloadData];
        }
    }
}

#pragma mark - Setter

- (void)setDelegate:(id<BDXCategoryViewDelegate>)delegate {
    _delegate = delegate;

    _delegateFlags.didSelectedItemAtIndexFlag = [delegate respondsToSelector:@selector(categoryView:didSelectedItemAtIndex:)];
    _delegateFlags.didClickSelectedItemAtIndexFlag = [delegate respondsToSelector:@selector(categoryView:didClickSelectedItemAtIndex:)];
    _delegateFlags.didScrollSelectedItemAtIndexFlag = [delegate respondsToSelector:@selector(categoryView:didScrollSelectedItemAtIndex:)];
    _delegateFlags.canClickItemAtIndexFlag = [delegate respondsToSelector:@selector(categoryView:canClickItemAtIndex:)];
    _delegateFlags.scrollingFromLeftIndexToRightIndexFlag = [delegate respondsToSelector:@selector(categoryView:scrollingFromLeftIndex:toRightIndex:ratio:)];
}

- (void)setDefaultSelectedIndex:(NSInteger)defaultSelectedIndex {
    _defaultSelectedIndex = defaultSelectedIndex;

    self.selectedIndex = defaultSelectedIndex;
    [self.listContainer setDefaultSelectedIndex:defaultSelectedIndex];
}

- (void)setContentScrollView:(UIScrollView *)contentScrollView {
    if (_contentScrollView != nil) {
        [_contentScrollView removeObserver:self forKeyPath:@"contentOffset"];
    }
    _contentScrollView = contentScrollView;

    self.contentScrollView.scrollsToTop = NO;
    [self.contentScrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)setListContainer:(id<BDXCategoryViewListContainer>)listContainer {
    _listContainer = listContainer;
    [listContainer setDefaultSelectedIndex:self.defaultSelectedIndex];
    self.contentScrollView = [listContainer contentScrollView];
}

- (void)setIsRTL:(BOOL)isRTL {
    if (_isRTL == isRTL) {
        return;
    }
    _isRTL = isRTL;
    if (isRTL) {
        self.collectionView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    } else {
        self.collectionView.transform = CGAffineTransformIdentity;
    }
    [self.collectionView reloadData];
}

#pragma mark - <UICollectionViewDataSource, UICollectionViewDelegate>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([self preferredCellClass]) forIndexPath:indexPath];
    if (self.isRTL) {
        cell.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    } else {
        cell.transform = CGAffineTransformIdentity;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    BDXCategoryBaseCellModel *cellModel = self.dataSource[indexPath.item];
    cellModel.selectedType = BDXCategoryCellSelectedTypeUnknown;
    [(BDXCategoryBaseCell *)cell reloadData:cellModel];
    if ([_delegate respondsToSelector:@selector(categoryView:willDisplayCell:forItemAtIndexPath:)]) {
        [_delegate categoryView:self willDisplayCell:cell forItemAtIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegate respondsToSelector:@selector(categoryView:didEndDisplayingCell:forItemAtIndexPath:)]) {
        [_delegate categoryView:self didEndDisplayingCell:cell forItemAtIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isTransitionAnimating = NO;
    for (BDXCategoryBaseCellModel *cellModel in self.dataSource) {
        if (cellModel.isTransitionAnimating) {
            isTransitionAnimating = YES;
            break;
        }
    }
    if (!isTransitionAnimating) {
        [self clickSelectItemAtIndex:indexPath.row];
    }
}

#pragma mark - <UICollectionViewDelegateFlowLayout>

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, [self getContentEdgeInsetLeft], 0, [self getContentEdgeInsetRight]);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.dataSource[indexPath.item].cellWidth, self.collectionView.bounds.size.height);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return self.innerCellSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return self.innerCellSpacing;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        CGPoint contentOffset = [change[NSKeyValueChangeNewKey] CGPointValue];
        if ((self.contentScrollView.isTracking || self.contentScrollView.isDecelerating || self.forceObserveContentOffset)) {
            [self contentOffsetOfContentScrollViewDidChanged:contentOffset];
        }
        self.lastContentViewContentOffset = contentOffset;
    }
}

#pragma mark - Private

- (void)configAutomaticallyAdjustsScrollViewInsets:(UIView *)view {
    UIResponder *next = view;
    while (next != nil) {
        if ([next isKindOfClass:[UIViewController class]]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            ((UIViewController *)next).automaticallyAdjustsScrollViewInsets = NO;
#pragma clang diagnostic pop
            self.needConfigAutomaticallyAdjustsScrollViewInsets = NO;
            break;
        }
        next = next.nextResponder;
    }
}

- (CGFloat)getContentEdgeInsetLeft {
    if (self.contentEdgeInsetLeft == BDXCategoryViewAutomaticDimension) {
        return self.innerCellSpacing;
    }
    return self.contentEdgeInsetLeft;
}

- (CGFloat)getContentEdgeInsetRight {
    if (self.contentEdgeInsetRight == BDXCategoryViewAutomaticDimension) {
        return self.innerCellSpacing;
    }
    return self.contentEdgeInsetRight;
}

- (CGFloat)getCellWidthAtIndex:(NSInteger)index {
    return [self preferredCellWidthAtIndex:index] + self.cellWidthIncrement;
}

- (void)clickSelectItemAtIndex:(NSInteger)index {
    if (self.delegateFlags.canClickItemAtIndexFlag && ![self.delegate categoryView:self canClickItemAtIndex:index]) {
        return;
    }

    [self selectCellAtIndex:index selectedType:BDXCategoryCellSelectedTypeClick];
}

- (void)scrollSelectItemAtIndex:(NSInteger)index {
    [self selectCellAtIndex:index selectedType:BDXCategoryCellSelectedTypeScroll];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (self.isNeedReloadByBecomeActive) {
        self.needReloadByBecomeActive = NO;
        [self reloadData];
    }
}

@end

@implementation BDXCategoryBaseView (UISubclassingBaseHooks)

- (CGRect)getTargetCellFrame:(NSInteger)targetIndex {
    CGFloat x = [self getContentEdgeInsetLeft];
    for (int i = 0; i < targetIndex; i ++) {
        BDXCategoryBaseCellModel *cellModel = self.dataSource[i];
        CGFloat cellWidth;
        if (cellModel.isTransitionAnimating && cellModel.isCellWidthZoomEnabled) {
            if (cellModel.isSelected) {
                cellWidth = [self getCellWidthAtIndex:cellModel.index]*cellModel.cellWidthSelectedZoomScale;
            }else {
                cellWidth = [self getCellWidthAtIndex:cellModel.index]*cellModel.cellWidthNormalZoomScale;
            }
        }else {
            cellWidth = cellModel.cellWidth;
        }
        x += cellWidth + self.innerCellSpacing;
    }
    CGFloat width;
    BDXCategoryBaseCellModel *selectedCellModel = self.dataSource[targetIndex];
    if (selectedCellModel.isTransitionAnimating && selectedCellModel.isCellWidthZoomEnabled) {
        width = [self getCellWidthAtIndex:selectedCellModel.index]*selectedCellModel.cellWidthSelectedZoomScale;
    }else {
        width = selectedCellModel.cellWidth;
    }
    return CGRectMake(x, 0, width, self.bounds.size.height);
}

- (CGRect)getTargetSelectedCellFrame:(NSInteger)targetIndex selectedType:(BDXCategoryCellSelectedType)selectedType {
    CGFloat x = [self getContentEdgeInsetLeft];
    for (int i = 0; i < targetIndex; i ++) {
        BDXCategoryBaseCellModel *cellModel = self.dataSource[i];
        x += [self getCellWidthAtIndex:cellModel.index] + self.innerCellSpacing;
    }
    CGFloat cellWidth = 0;
    BDXCategoryBaseCellModel *selectedCellModel = self.dataSource[targetIndex];
    if (selectedCellModel.cellWidthZoomEnabled) {
        cellWidth = [self getCellWidthAtIndex:targetIndex]*selectedCellModel.cellWidthSelectedZoomScale;
    }else {
        cellWidth = [self getCellWidthAtIndex:targetIndex];
    }
    return CGRectMake(x, 0, cellWidth, self.bounds.size.height);
}

- (void)initializeData {
    _firstLayoutSubviews = YES;
    _dataSource = [NSMutableArray array];
    _selectedIndex = 0;
    _cellWidth = BDXCategoryViewAutomaticDimension;
    _cellWidthIncrement = 0;
    _cellSpacing = 20;
    _layoutGravity = BDXTabLayoutGravityCenter;
    _cellWidthZoomEnabled = NO;
    _cellWidthZoomScale = 1.2;
    _cellWidthZoomScrollGradientEnabled = YES;
    _contentEdgeInsetLeft = BDXCategoryViewAutomaticDimension;
    _contentEdgeInsetRight = BDXCategoryViewAutomaticDimension;
    _lastContentViewContentOffset = CGPointZero;
    _selectedAnimationEnabled = NO;
    _selectedAnimationDuration = 0.25;
    _scrollingTargetIndex = -1;
    _contentScrollViewClickTransitionAnimationEnabled = YES;
    _needReloadByBecomeActive = NO;
    _bottomBorderConfig = [[BDXCategoryIndicatorViewBorderConfig alloc] init];
}

- (void)initializeViews {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _collectionView = [[BDXCategoryCollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.scrollsToTop = NO;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[self preferredCellClass] forCellWithReuseIdentifier:NSStringFromClass([self preferredCellClass])];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handelTap:)];
  tapGesture.delegate = self;
            [_collectionView addGestureRecognizer:tapGesture];
    [self.collectionView addGestureRecognizer:tapGesture];
    if (@available(iOS 10.0, *)) {
        self.collectionView.prefetchingEnabled = NO;
    }
    if (@available(iOS 11.0, *)) {
        if ([self.collectionView respondsToSelector:@selector(setContentInsetAdjustmentBehavior:)]) {
            self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    [self addSubview:self.collectionView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)handelTap:(UITapGestureRecognizer*)tapGesture {
    UIView *v = tapGesture.view;
    if(v == nil || ![v isKindOfClass:[UICollectionView class]]) return;
    if(tapGesture.state == UIGestureRecognizerStateEnded){
        UICollectionView *collectionView = (UICollectionView *)v;
        NSIndexPath *indexPath = [collectionView indexPathForItemAtPoint: [tapGesture locationInView:collectionView]];
        if (indexPath!= nil && self.selectedIndex != indexPath.item) {
            self.collectionView.userInteractionEnabled = NO;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.collectionView.userInteractionEnabled = YES;
            });
            [self clickSelectItemAtIndex:indexPath.row];
        }
    }
}

- (void)refreshDataSource {}

- (void)refreshState {
    if (self.selectedIndex < 0 || self.selectedIndex >= self.dataSource.count) {
        self.defaultSelectedIndex = 0;
    }

    self.innerCellSpacing = self.cellSpacing;

    __block CGFloat totalItemWidth = [self getContentEdgeInsetLeft];

    CGFloat totalCellWidth = 0;
    for (int i = 0; i < self.dataSource.count; i++) {
        BDXCategoryBaseCellModel *cellModel = self.dataSource[i];
        cellModel.index = i;
        cellModel.cellWidthZoomEnabled = self.cellWidthZoomEnabled;
        cellModel.cellWidthNormalZoomScale = 1;
        cellModel.cellWidthSelectedZoomScale = self.cellWidthZoomScale;
        cellModel.selectedAnimationEnabled = self.selectedAnimationEnabled;
        cellModel.selectedAnimationDuration = self.selectedAnimationDuration;
        cellModel.cellSpacing = self.innerCellSpacing;
        if (i == self.selectedIndex) {
            cellModel.selected = YES;
            cellModel.cellWidthCurrentZoomScale = cellModel.cellWidthSelectedZoomScale;
        }else {
            cellModel.selected = NO;
            cellModel.cellWidthCurrentZoomScale = cellModel.cellWidthNormalZoomScale;
        }
        if (self.isCellWidthZoomEnabled) {
            cellModel.cellWidth = [self getCellWidthAtIndex:i]*cellModel.cellWidthCurrentZoomScale;
        }else {
            cellModel.cellWidth = [self getCellWidthAtIndex:i];
        }
        totalCellWidth += cellModel.cellWidth;
        if (i == self.dataSource.count - 1) {
            totalItemWidth += cellModel.cellWidth + [self getContentEdgeInsetRight];
        }else {
            totalItemWidth += cellModel.cellWidth + self.innerCellSpacing;
        }
        [self refreshCellModel:cellModel index:i];
    }

    if (_layoutGravity != BDXTabLayoutGravityLeft && totalItemWidth < self.bounds.size.width) {
        if (_layoutGravity == BDXTabLayoutGravityFill) {
            NSInteger cellSpacingItemCount = self.dataSource.count - 1;
            CGFloat totalCellSpacingWidth = self.bounds.size.width - totalCellWidth;
            if (self.contentEdgeInsetLeft == BDXCategoryViewAutomaticDimension) {
                cellSpacingItemCount += 1;
            }else {
                totalCellSpacingWidth -= self.contentEdgeInsetLeft;
            }
            if (self.contentEdgeInsetRight == BDXCategoryViewAutomaticDimension) {
                cellSpacingItemCount += 1;
            }else {
                totalCellSpacingWidth -= self.contentEdgeInsetRight;
            }

            CGFloat cellSpacing = 0;
            if (cellSpacingItemCount > 0) {
                cellSpacing = totalCellSpacingWidth/cellSpacingItemCount;
            }
            self.innerCellSpacing = cellSpacing;
            [self.dataSource enumerateObjectsUsingBlock:^(BDXCategoryBaseCellModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.cellSpacing = self.innerCellSpacing;
            }];
        } else if (_layoutGravity == BDXTabLayoutGravityCenter) {
            __block CGFloat totalSidesSpace = self.bounds.size.width - totalCellWidth;
            [self.dataSource enumerateObjectsUsingBlock:^(BDXCategoryBaseCellModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
              if (obj != self.dataSource.lastObject) {
                totalSidesSpace -= obj.cellSpacing;
              }
            }];
            self.contentEdgeInsetRight = totalSidesSpace/2;
            self.contentEdgeInsetLeft = totalSidesSpace/2;
        }
    }


    __block CGFloat frameXOfSelectedCell = self.innerCellSpacing;
    __block CGFloat selectedCellWidth = 0;
    totalItemWidth = [self getContentEdgeInsetLeft];
    [self.dataSource enumerateObjectsUsingBlock:^(BDXCategoryBaseCellModel * cellModel, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx < self.selectedIndex) {
            frameXOfSelectedCell += cellModel.cellWidth + self.innerCellSpacing;
        }else if (idx == self.selectedIndex) {
            selectedCellWidth = cellModel.cellWidth;
        }
        if (idx == self.dataSource.count - 1) {
            totalItemWidth += cellModel.cellWidth + [self getContentEdgeInsetRight];
        }else {
            totalItemWidth += cellModel.cellWidth + self.innerCellSpacing;
        }
    }];

    CGFloat minX = 0;
    CGFloat maxX = totalItemWidth - self.bounds.size.width;
    CGFloat targetX = frameXOfSelectedCell - self.bounds.size.width/2.0 + selectedCellWidth/2.0;
    [self.collectionView setContentOffset:CGPointMake(MAX(MIN(maxX, targetX), minX), 0) animated:NO];


    if (CGRectEqualToRect(self.contentScrollView.frame, CGRectZero) && self.contentScrollView.superview != nil) {

        UIView *parentView = self.contentScrollView.superview;
        while (parentView != nil && CGRectEqualToRect(parentView.frame, CGRectZero)) {
            parentView = parentView.superview;
        }
        [parentView setNeedsLayout];
        [parentView layoutIfNeeded];
    }
  
    [self.contentScrollView setContentOffset:CGPointMake(self.selectedIndex*self.contentScrollView.bounds.size.width, 0) animated:NO];
}

- (BOOL)selectCellAtIndex:(NSInteger)targetIndex selectedType:(BDXCategoryCellSelectedType)selectedType {
    if (targetIndex < 0 || targetIndex >= self.dataSource.count) {
        return NO;
    }

    self.needReloadByBecomeActive = NO;
    if (self.selectedIndex == targetIndex) {
        
        if (selectedType == BDXCategoryCellSelectedTypeCode) {
            [self.listContainer didClickSelectedItemAtIndex:targetIndex];
        }else if (selectedType == BDXCategoryCellSelectedTypeClick) {
            [self.listContainer didClickSelectedItemAtIndex:targetIndex];
            if (self.delegateFlags.didClickSelectedItemAtIndexFlag) {
                [self.delegate categoryView:self didClickSelectedItemAtIndex:targetIndex];
            }
        }else if (selectedType == BDXCategoryCellSelectedTypeScroll) {
            if (self.delegateFlags.didScrollSelectedItemAtIndexFlag) {
                [self.delegate categoryView:self didScrollSelectedItemAtIndex:targetIndex];
            }
        }
        if (self.delegateFlags.didSelectedItemAtIndexFlag) {
            [self.delegate categoryView:self didSelectedItemAtIndex:targetIndex];
        }
        self.scrollingTargetIndex = -1;
        return NO;
    }

    
    BDXCategoryBaseCellModel *lastCellModel = self.dataSource[self.selectedIndex];
    lastCellModel.selectedType = selectedType;
    BDXCategoryBaseCellModel *selectedCellModel = self.dataSource[targetIndex];
    selectedCellModel.selectedType = selectedType;
    [self refreshSelectedCellModel:selectedCellModel unselectedCellModel:lastCellModel];

    
    BDXCategoryBaseCell *lastCell = (BDXCategoryBaseCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0]];
    [lastCell reloadData:lastCellModel];
    BDXCategoryBaseCell *selectedCell = (BDXCategoryBaseCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0]];
    [selectedCell reloadData:selectedCellModel];

    if (self.scrollingTargetIndex != -1 && self.scrollingTargetIndex != targetIndex) {
        BDXCategoryBaseCellModel *scrollingTargetCellModel = self.dataSource[self.scrollingTargetIndex];
        scrollingTargetCellModel.selected = NO;
        scrollingTargetCellModel.selectedType = selectedType;
        [self refreshSelectedCellModel:selectedCellModel unselectedCellModel:scrollingTargetCellModel];
        BDXCategoryBaseCell *scrollingTargetCell = (BDXCategoryBaseCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.scrollingTargetIndex inSection:0]];
        [scrollingTargetCell reloadData:scrollingTargetCellModel];
    }

    if (self.isCellWidthZoomEnabled) {
        [self.collectionView.collectionViewLayout invalidateLayout];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.selectedAnimationDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        });
    } else {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }

    if (selectedType == BDXCategoryCellSelectedTypeClick ||
        selectedType == BDXCategoryCellSelectedTypeCode) {
        [self.contentScrollView setContentOffset:CGPointMake(targetIndex*self.contentScrollView.bounds.size.width, 0) animated:self.isContentScrollViewClickTransitionAnimationEnabled];
    }

    self.selectedIndex = targetIndex;
    if (selectedType == BDXCategoryCellSelectedTypeCode) {
        [self.listContainer didClickSelectedItemAtIndex:targetIndex];
    } else if (selectedType == BDXCategoryCellSelectedTypeClick) {
        [self.listContainer didClickSelectedItemAtIndex:targetIndex];
        if (self.delegateFlags.didClickSelectedItemAtIndexFlag) {
            [self.delegate categoryView:self didClickSelectedItemAtIndex:targetIndex];
        }
    } else if(selectedType == BDXCategoryCellSelectedTypeScroll) {
        if (self.delegateFlags.didScrollSelectedItemAtIndexFlag) {
            [self.delegate categoryView:self didScrollSelectedItemAtIndex:targetIndex];
        }
    }
    if (self.delegateFlags.didSelectedItemAtIndexFlag) {
        [self.delegate categoryView:self didSelectedItemAtIndex:targetIndex];
    }
    self.scrollingTargetIndex = -1;

    return YES;
}


- (void)refreshSelectedCellModel:(BDXCategoryBaseCellModel *)selectedCellModel unselectedCellModel:(BDXCategoryBaseCellModel *)unselectedCellModel {
    selectedCellModel.selected = YES;
    unselectedCellModel.selected = NO;

    if (self.isCellWidthZoomEnabled) {
        if (selectedCellModel.selectedType == BDXCategoryCellSelectedTypeCode ||
            selectedCellModel.selectedType == BDXCategoryCellSelectedTypeClick) {
            self.animator = [[BDXCategoryViewAnimator alloc] init];
            self.animator.duration = self.selectedAnimationDuration;
            __weak typeof(self) weakSelf = self;
            self.animator.progressCallback = ^(CGFloat percent) {
                selectedCellModel.transitionAnimating = YES;
                unselectedCellModel.transitionAnimating = YES;
                selectedCellModel.cellWidthCurrentZoomScale = [BDXCategoryFactory interpolationFrom:selectedCellModel.cellWidthNormalZoomScale to:selectedCellModel.cellWidthSelectedZoomScale percent:percent];
                selectedCellModel.cellWidth = [weakSelf getCellWidthAtIndex:selectedCellModel.index] * selectedCellModel.cellWidthCurrentZoomScale;
                unselectedCellModel.cellWidthCurrentZoomScale = [BDXCategoryFactory interpolationFrom:unselectedCellModel.cellWidthSelectedZoomScale to:unselectedCellModel.cellWidthNormalZoomScale percent:percent];
                unselectedCellModel.cellWidth = [weakSelf getCellWidthAtIndex:unselectedCellModel.index] * unselectedCellModel.cellWidthCurrentZoomScale;
                [weakSelf.collectionView.collectionViewLayout invalidateLayout];
            };
            self.animator.completeCallback = ^{
                selectedCellModel.transitionAnimating = NO;
                unselectedCellModel.transitionAnimating = NO;
            };
            [self.animator start];
        } else {
            selectedCellModel.cellWidthCurrentZoomScale = selectedCellModel.cellWidthSelectedZoomScale;
            selectedCellModel.cellWidth = [self getCellWidthAtIndex:selectedCellModel.index] * selectedCellModel.cellWidthCurrentZoomScale;
            unselectedCellModel.cellWidthCurrentZoomScale = unselectedCellModel.cellWidthNormalZoomScale;
            unselectedCellModel.cellWidth = [self getCellWidthAtIndex:unselectedCellModel.index] * unselectedCellModel.cellWidthCurrentZoomScale;
        }
    }
}

- (void)contentOffsetOfContentScrollViewDidChanged:(CGPoint)contentOffset {
    CGFloat ratio = contentOffset.x/self.contentScrollView.bounds.size.width;
    if (ratio > self.dataSource.count - 1 || ratio < 0) {
        return;
    }
    if (contentOffset.x == 0 && self.selectedIndex == 0 && self.lastContentViewContentOffset.x == 0) {
        return;
    }
    CGFloat maxContentOffsetX = self.contentScrollView.contentSize.width - self.contentScrollView.bounds.size.width;
    if (contentOffset.x == maxContentOffsetX && self.selectedIndex == self.dataSource.count - 1 && self.lastContentViewContentOffset.x == maxContentOffsetX) {
        return;
    }
    ratio = MAX(0, MIN(self.dataSource.count - 1, ratio));
    NSInteger baseIndex = floorf(ratio);
    CGFloat remainderRatio = ratio - baseIndex;

    if (remainderRatio == 0) {

        if (!(self.lastContentViewContentOffset.x == contentOffset.x && self.selectedIndex == baseIndex)) {
            [self scrollSelectItemAtIndex:baseIndex];
        }
    } else {
        self.needReloadByBecomeActive = YES;
        if (self.animator.isExecuting) {
            [self.animator invalid];
            
            for (BDXCategoryBaseCellModel *model in self.dataSource) {
                if (model.isSelected) {
                    model.cellWidthCurrentZoomScale = model.cellWidthSelectedZoomScale;
                    model.cellWidth = [self getCellWidthAtIndex:model.index] * model.cellWidthCurrentZoomScale;
                }else {
                    model.cellWidthCurrentZoomScale = model.cellWidthNormalZoomScale;
                    model.cellWidth = [self getCellWidthAtIndex:model.index] * model.cellWidthCurrentZoomScale;
                }
            }
        }
       
        if (fabs(ratio - self.selectedIndex) > 1) {
            NSInteger targetIndex = baseIndex;
            if (ratio < self.selectedIndex) {
                targetIndex = baseIndex + 1;
            }
            [self scrollSelectItemAtIndex:targetIndex];
        }

        if (self.selectedIndex == baseIndex) {
            self.scrollingTargetIndex = baseIndex + 1;
        } else {
            self.scrollingTargetIndex = baseIndex;
        }

        if (self.isCellWidthZoomEnabled && self.isCellWidthZoomScrollGradientEnabled) {
            BDXCategoryBaseCellModel *leftCellModel = (BDXCategoryBaseCellModel *)self.dataSource[baseIndex];
            BDXCategoryBaseCellModel *rightCellModel = (BDXCategoryBaseCellModel *)self.dataSource[baseIndex + 1];
            leftCellModel.cellWidthCurrentZoomScale = [BDXCategoryFactory interpolationFrom:leftCellModel.cellWidthSelectedZoomScale to:leftCellModel.cellWidthNormalZoomScale percent:remainderRatio];
            leftCellModel.cellWidth = [self getCellWidthAtIndex:leftCellModel.index] * leftCellModel.cellWidthCurrentZoomScale;
            rightCellModel.cellWidthCurrentZoomScale = [BDXCategoryFactory interpolationFrom:rightCellModel.cellWidthNormalZoomScale to:rightCellModel.cellWidthSelectedZoomScale percent:remainderRatio];
            rightCellModel.cellWidth = [self getCellWidthAtIndex:rightCellModel.index] * rightCellModel.cellWidthCurrentZoomScale;
            [self.collectionView.collectionViewLayout invalidateLayout];
        }

        if (self.delegateFlags.scrollingFromLeftIndexToRightIndexFlag) {
            [self.delegate categoryView:self scrollingFromLeftIndex:baseIndex toRightIndex:baseIndex + 1 ratio:remainderRatio];
        }
    }
}

- (CGFloat)preferredCellWidthAtIndex:(NSInteger)index {
    return 0;
}

- (Class)preferredCellClass {
    return BDXCategoryBaseCell.class;
}

- (void)refreshCellModel:(BDXCategoryBaseCellModel *)cellModel index:(NSInteger)index {

}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:
        (UIGestureRecognizer*)otherGestureRecognizer {
  return YES;
}
@end
