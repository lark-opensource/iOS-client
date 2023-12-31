//
//  BDXPagerView.m
//  BDXPagerView
//
//  Created by jiaxin on 2018/8/27.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import "BDXPagerView.h"
@class BDXPagerListContainerScrollView;
@class BDXPagerListContainerCollectionView;

@interface BDXPagerView () <UITableViewDataSource, UITableViewDelegate, BDXPagerListContainerViewDelegate>
@property (nonatomic, weak) id<BDXPagerViewDelegate> delegate;
@property (nonatomic, strong) BDXPagerMainTableView *mainTableView;
@property (nonatomic, strong) BDXPagerListContainerView *listContainerView;
@property (nonatomic, weak) UIScrollView *currentScrollingListView;
@property (nonatomic, strong) id<BDXPagerViewListViewDelegate> currentList;
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, id<BDXPagerViewListViewDelegate>> *validListDict;
@property (nonatomic, strong) UIView *tableHeaderContainerView;
@end

@implementation BDXPagerView

- (instancetype)initWithDelegate:(id<BDXPagerViewDelegate>)delegate {
    return [self initWithDelegate:delegate listContainerType:BDXPagerListContainerType_CollectionView];
}

- (instancetype)initWithDelegate:(id<BDXPagerViewDelegate>)delegate listContainerType:(BDXPagerListContainerType)type {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _delegate = delegate;
        _validListDict = [NSMutableDictionary dictionary];
        _automaticallyDisplayListVerticalScrollIndicator = YES;
        _isListHorizontalScrollEnabled = YES;
        _verticalScrollEnabled = YES;
        
        _mainTableView = [[BDXPagerMainTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        self.mainTableView.showsVerticalScrollIndicator = NO;
        self.mainTableView.showsHorizontalScrollIndicator = NO;
        self.mainTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.mainTableView.scrollsToTop = NO;
        self.mainTableView.dataSource = self;
        self.mainTableView.delegate = self;
        self.mainTableView.backgroundColor = [UIColor clearColor];
        [self.mainTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
        if (@available(iOS 11.0, *)) {
            self.mainTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        if (@available(iOS 15.0, *)) {
            [self.mainTableView setValue:@(0) forKey:@"sectionHeaderTopPadding"];
        }
        [self addSubview:self.mainTableView];

        _listContainerView = [[BDXPagerListContainerView alloc] initWithType:type delegate:self];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (!CGRectEqualToRect(self.bounds, self.mainTableView.frame)) {
        self.mainTableView.frame = self.bounds;
        [self.mainTableView reloadData];
    }
}

- (void)setDefaultSelectedIndex:(NSInteger)defaultSelectedIndex {
    _defaultSelectedIndex = defaultSelectedIndex;

    self.listContainerView.defaultSelectedIndex = defaultSelectedIndex;
}

- (void)setIsListHorizontalScrollEnabled:(BOOL)isListHorizontalScrollEnabled {
    _isListHorizontalScrollEnabled = isListHorizontalScrollEnabled;

    self.listContainerView.scrollView.scrollEnabled = isListHorizontalScrollEnabled;
}

- (void)setVerticalScrollEnabled:(BOOL)verticalScrollEnabled {
    _verticalScrollEnabled = verticalScrollEnabled;
    self.mainTableView.scrollEnabled = verticalScrollEnabled;
}

- (void)reloadData {
    self.currentList = nil;
    self.currentScrollingListView = nil;
    [_validListDict removeAllObjects];

    [self refreshTableHeaderView];
    [self.mainTableView reloadData];
    [self.listContainerView reloadData];
}

- (void)invalidatePageView {
  self.currentList = nil;
  self.currentScrollingListView = nil;
  [_validListDict removeAllObjects];
}

- (void)resizeTableHeaderViewHeightWithAnimatable:(BOOL)animatable duration:(NSTimeInterval)duration curve:(UIViewAnimationCurve)curve {
    if (animatable) {
        UIViewAnimationOptions options = UIViewAnimationOptionCurveLinear;
        switch (curve) {
            case UIViewAnimationCurveEaseIn: options = UIViewAnimationOptionCurveEaseIn; break;
            case UIViewAnimationCurveEaseOut: options = UIViewAnimationOptionCurveEaseOut; break;
            case UIViewAnimationCurveEaseInOut: options = UIViewAnimationOptionCurveEaseInOut; break;
            default: break;
        }
        [UIView animateWithDuration:duration delay:0 options:options animations:^{
            CGRect frame = self.tableHeaderContainerView.bounds;
            frame.size.height = [self.delegate tableHeaderViewHeightInPagerView:self];
            self.tableHeaderContainerView.frame = frame;
            self.mainTableView.tableHeaderView = self.tableHeaderContainerView;
            [self.mainTableView setNeedsLayout];
            [self.mainTableView layoutIfNeeded];
        } completion:^(BOOL finished) { }];
    }else {
        CGRect frame = self.tableHeaderContainerView.bounds;
        frame.size.height = [self.delegate tableHeaderViewHeightInPagerView:self];
        self.tableHeaderContainerView.frame = frame;
        self.mainTableView.tableHeaderView = self.tableHeaderContainerView;
    }
}

#pragma mark - Private

- (void)refreshTableHeaderView {
    UIView *tableHeaderView = [self.delegate tableHeaderViewInPagerView:self];
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, [self.delegate tableHeaderViewHeightInPagerView:self])];
    if (tableHeaderView == nil || containerView == nil) {
        return;
    }
    [containerView addSubview:tableHeaderView];
    tableHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:tableHeaderView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    NSLayoutConstraint *leading = [NSLayoutConstraint constraintWithItem:tableHeaderView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeLeading multiplier:1 constant:0];
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:tableHeaderView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
    NSLayoutConstraint *trailing = [NSLayoutConstraint constraintWithItem:tableHeaderView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0];
    [containerView addConstraints:@[top, leading, bottom, trailing]];
    self.tableHeaderContainerView = containerView;
    self.mainTableView.tableHeaderView = containerView;
}

- (void)adjustMainScrollViewToTargetContentInsetIfNeeded:(UIEdgeInsets)insets {
    if (UIEdgeInsetsEqualToEdgeInsets(insets, self.mainTableView.contentInset) == NO) {
        self.mainTableView.delegate = nil;
        self.mainTableView.contentInset = insets;
        self.mainTableView.delegate = self;
    }
}

- (void)listViewDidScroll:(UIScrollView *)scrollView {
    self.currentScrollingListView = scrollView;
    [self preferredProcessListViewDidScroll:scrollView];
}


- (BOOL)isSetMainScrollViewContentInsetToZeroEnabled:(UIScrollView *)scrollView {
   
    BOOL isRefreshing = scrollView.contentInset.top != 0 && scrollView.contentInset.top != self.pinSectionHeaderVerticalOffset;
    return !isRefreshing;
}

#pragma mark - UITableViewDataSource, UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return MAX(self.bounds.size.height - [self.delegate heightForPinSectionHeaderInPagerView:self] - self.pinSectionHeaderVerticalOffset, 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    if (self.listContainerView.superview != cell.contentView) {
        [cell.contentView addSubview:self.listContainerView];
    }
    if (!CGRectEqualToRect(self.listContainerView.frame, cell.bounds)) {
        self.listContainerView.frame = cell.bounds;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [self.delegate heightForPinSectionHeaderInPagerView:self];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [self.delegate viewForPinSectionHeaderInPagerView:self];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *footer = [[UIView alloc] initWithFrame:CGRectZero];
    footer.backgroundColor = [UIColor clearColor];
    return footer;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.pinSectionHeaderVerticalOffset != 0) {
        if (!(self.currentScrollingListView != nil && self.currentScrollingListView.contentOffset.y > [self minContentOffsetYInListScrollView:self.currentScrollingListView])) {
            
            if (scrollView.contentOffset.y >= self.pinSectionHeaderVerticalOffset) {
                
                [self adjustMainScrollViewToTargetContentInsetIfNeeded:UIEdgeInsetsMake(self.pinSectionHeaderVerticalOffset, 0, 0, 0)];
            }else {
                if ([self isSetMainScrollViewContentInsetToZeroEnabled:scrollView]) {
                    [self adjustMainScrollViewToTargetContentInsetIfNeeded:UIEdgeInsetsZero];
                }
            }
        }
    }
    [self preferredProcessMainTableViewDidScroll:scrollView];
    if (self.delegate && [self.delegate respondsToSelector:@selector(mainTableViewDidScroll:)]) {
        #pragma GCC diagnostic push
        #pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        [self.delegate mainTableViewDidScroll:scrollView];
        #pragma GCC diagnostic pop
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(pagerView:mainTableViewDidScroll:)]) {
        [self.delegate pagerView:self mainTableViewDidScroll:scrollView];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.listContainerView.scrollView.scrollEnabled = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(pagerView:mainTableViewWillBeginDragging:)]) {
        [self.delegate pagerView:self mainTableViewWillBeginDragging:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.isListHorizontalScrollEnabled && !decelerate) {
        self.listContainerView.scrollView.scrollEnabled = YES;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(pagerView:mainTableViewDidEndDragging:willDecelerate:)]) {
        [self.delegate pagerView:self mainTableViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.isListHorizontalScrollEnabled) {
        self.listContainerView.scrollView.scrollEnabled = YES;
    }
    if ([self isSetMainScrollViewContentInsetToZeroEnabled:scrollView]) {
        if (self.mainTableView.contentInset.top != 0 && self.pinSectionHeaderVerticalOffset != 0) {
            [self adjustMainScrollViewToTargetContentInsetIfNeeded:UIEdgeInsetsZero];
        }
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(pagerView:mainTableViewDidEndDecelerating:)]) {
        [self.delegate pagerView:self mainTableViewDidEndDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (self.isListHorizontalScrollEnabled) {
        self.listContainerView.scrollView.scrollEnabled = YES;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(pagerView:mainTableViewDidEndScrollingAnimation:)]) {
        [self.delegate pagerView:self mainTableViewDidEndScrollingAnimation:scrollView];
    }
}

#pragma mark - BDXPagerListContainerViewDelegate

- (NSInteger)numberOfListsInlistContainerView:(BDXPagerListContainerView *)listContainerView {
    return [self.delegate numberOfListsInPagerView:self];
}

- (id<BDXPagerViewListViewDelegate>)listContainerView:(BDXPagerListContainerView *)listContainerView initListForIndex:(NSInteger)index {
    id<BDXPagerViewListViewDelegate> list = self.validListDict[@(index)];
    if (list == nil) {
        list = [self.delegate pagerView:self initListAtIndex:index];
        __weak typeof(self)weakSelf = self;
        __weak typeof(id<BDXPagerViewListViewDelegate>) weakList = list;
        [list listViewDidScrollCallback:^(UIScrollView *scrollView) {
            weakSelf.currentList = weakList;
            [weakSelf listViewDidScroll:scrollView];
        }];
        _validListDict[@(index)] = list;
    }
    return list;
}


- (void)listContainerViewWillBeginDragging:(BDXPagerListContainerView *)listContainerView {
    self.mainTableView.scrollEnabled = NO;
}

- (void)listContainerViewWDidEndScroll:(BDXPagerListContainerView *)listContainerView {
    self.mainTableView.scrollEnabled = self.verticalScrollEnabled;
}

- (void)listContainerView:(BDXPagerListContainerView *)listContainerView listDidAppearAtIndex:(NSInteger)index {
    self.currentScrollingListView = [self.validListDict[@(index)] listScrollView];
    for (id<BDXPagerViewListViewDelegate> listItem in self.validListDict.allValues) {
        if (listItem == self.validListDict[@(index)]) {
            [listItem listScrollView].scrollsToTop = YES;
        }else {
            [listItem listScrollView].scrollsToTop = NO;
        }
    }
}

- (Class)scrollViewClassInlistContainerView:(BDXPagerListContainerView *)listContainerView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(scrollViewClassInlistContainerViewInPagerView:)]) {
        return [self.delegate scrollViewClassInlistContainerViewInPagerView:self];
    }
    return nil;
}

- (void)listContainerViewDidScroll:(UIScrollView *)scrollView {
    if ([self.delegate respondsToSelector:@selector(pagerView:listScrollViewDidScroll:)]) {
        [self.delegate pagerView:self listScrollViewDidScroll:scrollView];
    }
}

@end

@implementation BDXPagerView (UISubclassingGet)

- (CGFloat)mainTableViewMaxContentOffsetY {
    return [self.delegate tableHeaderViewHeightInPagerView:self] - self.pinSectionHeaderVerticalOffset;
}

@end

@implementation BDXPagerView (UISubclassingHooks)

- (void)preferredProcessListViewDidScroll:(UIScrollView *)scrollView {
    if (UIAccessibilityIsVoiceOverRunning()) {
        [self setMainTableViewToMaxContentOffsetY];
    }
    if (self.mainTableView.contentOffset.y < self.mainTableViewMaxContentOffsetY) {
        
        if (self.currentList && [self.currentList respondsToSelector:@selector(listScrollViewWillResetContentOffset)]) {
            [self.currentList listScrollViewWillResetContentOffset];
        }
        [self setListScrollViewToMinContentOffsetY:scrollView];
        if (self.automaticallyDisplayListVerticalScrollIndicator) {
            scrollView.showsVerticalScrollIndicator = NO;
        }
    }else {
        
        self.mainTableView.contentOffset = CGPointMake(0, self.mainTableViewMaxContentOffsetY);
        if (self.automaticallyDisplayListVerticalScrollIndicator) {
            scrollView.showsVerticalScrollIndicator = YES;
        }
    }
}

- (void)preferredProcessMainTableViewDidScroll:(UIScrollView *)scrollView {
    if (self.currentScrollingListView != nil && self.currentScrollingListView.contentOffset.y > [self minContentOffsetYInListScrollView:self.currentScrollingListView]) {
        [self setMainTableViewToMaxContentOffsetY];
    }

    if (scrollView.contentOffset.y < self.mainTableViewMaxContentOffsetY) {
        
        for (id<BDXPagerViewListViewDelegate> list in self.validListDict.allValues) {
            if ([list respondsToSelector:@selector(listScrollViewWillResetContentOffset)]) {
                [list listScrollViewWillResetContentOffset];
            }
            [self setListScrollViewToMinContentOffsetY:[list listScrollView]];
        }
    }

    if (scrollView.contentOffset.y > self.mainTableViewMaxContentOffsetY && self.currentScrollingListView.contentOffset.y == [self minContentOffsetYInListScrollView:self.currentScrollingListView]) {
        [self setMainTableViewToMaxContentOffsetY];
    }
}

- (void)setMainTableViewToMaxContentOffsetY {
    self.mainTableView.contentOffset = CGPointMake(0, self.mainTableViewMaxContentOffsetY);
}

- (void)setListScrollViewToMinContentOffsetY:(UIScrollView *)scrollView {
    scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, [self minContentOffsetYInListScrollView:scrollView]);
}

- (CGFloat)minContentOffsetYInListScrollView:(UIScrollView *)scrollView {
    if (@available(iOS 11.0, *)) {
        return -scrollView.adjustedContentInset.top;
    }
    return -scrollView.contentInset.top;
}


@end
