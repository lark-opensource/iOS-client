//
//  BDXPageContentView.m
//  BDXElement
//
//  Created by AKing on 2020/9/21.
//

#import "BDXPageContentView.h"
#import "BDXPageGestureCollectionView.h"
#import <Lynx/LynxUI.h>

#define kWidth self.frame.size.width

static NSString * const BDXPageContentViewCellIdentifier = @"BDXPageContentViewCellIdentifier";

@interface BDXPageContentView () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) BDXPageGestureCollectionView *collectionView;
@property (nonatomic) BOOL isManualScroll;
@property (nonatomic) CGFloat contentOffsetXWhenBeginDragging;

@end

@implementation BDXPageContentView

#pragma mark - Life Cycle

- (instancetype)init {
    if (self = [super init]) {
        if (@available(iOS 11.0, *)) {
            self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        [self addSubview:self.collectionView];
        self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *collectionViewTopConstraint = [NSLayoutConstraint constraintWithItem:self.collectionView
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                      constant:0.0];
        collectionViewTopConstraint.active = YES;

       NSLayoutConstraint *collectionViewRightConstraint = [NSLayoutConstraint constraintWithItem:self.collectionView
                                                            attribute:NSLayoutAttributeRight
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self
                                                            attribute:NSLayoutAttributeRight
                                                           multiplier:1.0
                                                              constant:0.0];
        collectionViewRightConstraint.active = YES;
        
        NSLayoutConstraint *collectionViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.collectionView
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                       constant:0.0];
        collectionViewBottomConstraint.active = YES;

        NSLayoutConstraint *collectionViewLeftConstraint = [NSLayoutConstraint constraintWithItem:self.collectionView
                                                             attribute:NSLayoutAttributeLeft
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeLeft
                                                            multiplier:1.0
                                                               constant:0.0];
        collectionViewLeftConstraint.active = YES;
    }
    
    return self;
}

#pragma mark - Public Methods

- (void)setSelectedPage:(NSInteger)selectedPage animated:(BOOL)animated {
    NSInteger rightPage = [self getRightPage:selectedPage];
    if (rightPage == _selectedPage) {
        return;
    }
   
    [self.pageItems enumerateObjectsUsingBlock:^(BDXLynxPageViewItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger delt = idx-rightPage;
        if (delt > 1 || delt < -1) {
            [obj.view removeFromSuperview];
        }
    }];
    _selectedPage = rightPage;
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:selectedPage inSection:0];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    if (cell) {
        [self.collectionView scrollToItemAtIndexPath:indexPath
        atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                animated:animated];
    } else {
        [self.collectionView setNeedsLayout];
        [self.collectionView layoutIfNeeded];
        [self.collectionView setContentOffset:CGPointMake(self.collectionView.frame.size.width * selectedPage, 0) animated:false];
    }
}

#pragma mark - Private Methods
- (NSInteger)getRightPage:(NSInteger)page {
    if (page <= 0) {
        return 0;
    } else if (page >= self.pageItems.count) {
        return self.pageItems.count - 1;
    } else {
        return page;
    }
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.pageItems.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item >= self.pageItems.count) {
        NSAssert(NO, @"BDXPageContentView cellForItemAtIndexPath out of range");
        return nil;
    }
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:BDXPageContentViewCellIdentifier forIndexPath:indexPath];
    cell.clipsToBounds = YES;
    BDXLynxPageViewItem *m = self.pageItems[indexPath.item];
    for (UIView *view in [[cell contentView] subviews]) {
        [view removeFromSuperview];
    }
    CGSize size = self.collectionView.bounds.size;
    m.view.frame = CGRectMake(0, 0, size.width, size.height);
    m.frame = m.view.frame;
    [m.view removeFromSuperview];
    if (m.view != nil) {
        [cell.contentView addSubview:m.view];
    }
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell.contentView subviews].count == 0) {
        BDXLynxPageViewItem *m = self.pageItems[indexPath.item];
        CGSize size = self.collectionView.bounds.size;
        m.view.frame = CGRectMake(0, 0, size.width, size.height);
        m.frame = m.view.frame;
        [m.view removeFromSuperview];
        if (m.view != nil) {
            [cell.contentView addSubview:m.view];
        }
    }
    if ([self.delegate respondsToSelector:@selector(pageContentViewWillTransitionToPage:)]) {
        [self.delegate pageContentViewWillTransitionToPage:indexPath.item];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.collectionView.bounds.size;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.contentOffsetXWhenBeginDragging = scrollView.contentOffset.x;
    if ([self.delegate respondsToSelector:@selector(pageContentViewWillBeginDragging)]) {
        [self.delegate pageContentViewWillBeginDragging];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if ([self.delegate respondsToSelector:@selector(pageContentViewDidEndDragging)]) {
        [self.delegate pageContentViewDidEndDragging];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([self.delegate respondsToSelector:@selector(pageContentViewDidEndDecelerating)]) {
        [self.delegate pageContentViewDidEndDecelerating];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self.delegate respondsToSelector:@selector(pageContentViewScrollingToTargetPage:sourcePage:percent:)]) {
        
        CGFloat scale = scrollView.contentOffset.x / scrollView.frame.size.width;
        NSInteger leftPage = floor(scale);
        NSInteger rightPage = ceil(scale);
        if (scrollView.contentOffset.x > self.contentOffsetXWhenBeginDragging) {
            if (leftPage == rightPage) {
                leftPage = rightPage - 1;
            }
            if (leftPage >= 0 && rightPage < self.pageItems.count) {
                [self.delegate pageContentViewScrollingToTargetPage:rightPage sourcePage:leftPage percent:scale - leftPage];
            }
        } else {
            if (leftPage == rightPage) {
                rightPage = leftPage + 1;
            }
            if (leftPage >= 0 && rightPage < self.pageItems.count) {
                [self.delegate pageContentViewScrollingToTargetPage:leftPage sourcePage:rightPage percent:1 - (scale - leftPage)];
            }
        }
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scrollViewDidEndScrollingAnimation:) object:nil];
    [self performSelector:@selector(scrollViewDidEndScrollingAnimation:) withObject:nil afterDelay:0.1];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scrollViewDidEndScrollingAnimation:) object:nil];
    
    if ([self.collectionView indexPathsForVisibleItems].count == 1) {
        _selectedPage = [[self.collectionView indexPathsForVisibleItems] firstObject].item;
        if ([self.delegate respondsToSelector:@selector(pageContentViewDidTransitionToPage:)]) {
            [self.delegate pageContentViewDidTransitionToPage: self.selectedPage];
        }
    }
}

#pragma mark - Getters
- (BDXPageGestureCollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        _collectionView = [[BDXPageGestureCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.pagingEnabled = YES;
        _collectionView.bounces = YES;
        _collectionView.alwaysBounceHorizontal = YES;
        [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:BDXPageContentViewCellIdentifier];
    }
    return _collectionView;
}

#pragma mark - Setters
- (void)setPageItems:(NSArray<BDXLynxPageViewItem *> *)pageItems {
    _pageItems = pageItems;
    [self.collectionView reloadData];
}

- (void)setOriginalPage:(NSInteger)originalPage {
    _originalPage = [self getRightPage:originalPage];
}

- (void)setSelectedPage:(NSInteger)selectedPage {
    [self setSelectedPage:selectedPage animated:self.isManualScroll && (labs(_selectedPage - selectedPage) == 1)];
}

- (BDXLynxPageViewItem *)selectedPageItem {
    return self.pageItems[self.selectedPage];
}


@end
